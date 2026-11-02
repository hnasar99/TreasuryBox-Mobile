import '../../core/amount.dart';
import '../../core/company_link.dart';
import '../../core/decimal.dart';
import '../../core/evm/abi.dart';
import '../../core/evm/balances.dart';
import '../../core/evm/json_rpc.dart';
import '../../core/model.dart';
import '../../core/qr/qr_intent.dart';
import '../../core/signer.dart';
import 'tokens.dart';
import 'zonabank_api.dart';

final class CurveSwapPayload extends QuotePayload {
  const CurveSwapPayload({
    required this.cap,
    required this.pool,
    required this.sellToken,
    required this.sellAmount,
    required this.data,
  });

  final CappedSwapPayload cap;
  final String pool;
  final String sellToken;
  final BigInt sellAmount;
  final String data;

  @override
  bool get executable => cap.executable;
}

class TwinArcEcosystem implements TreasuryEcosystem, YieldActions, CompanyBound {
  TwinArcEcosystem({
    required this.homeCurrency,
    required this.live,
    required this.fxEnabled,
    required this.signer,
    TwinTokens? book,
    EvmReadClient? reads,
    ZonaBankApi? remote,
    DateTime Function()? clock,
  })  : book = book ?? TwinTokens(mainnetBox: TwinTokens.network == 'mainnet'),
        _reads = reads ?? EvmReadClient(),
        _clock = clock ?? DateTime.now {
    _remote = remote ?? ZonaBankApi(chains: [arbChain, this.book.boxChain]);
  }

  final String homeCurrency;
  final bool live;
  final bool fxEnabled;
  final TxSigner signer;
  final TwinTokens book;
  final EvmReadClient _reads;
  late final ZonaBankApi _remote;
  final DateTime Function() _clock;
  EcosystemSession? session;

  @override
  set companySession(EcosystemSession? value) => session = value;

  @override
  String get id => 'twin-arc';

  @override
  List<ChainRef> get chains => [arbChain, book.boxChain];

  late final List<TokenRef> _tokens = book.all();

  @override
  List<TokenRef> get tokens => _tokens;

  @override
  TokenRef get homeStable => _tokens.firstWhere(
        (token) => token.symbol == 'ARGt' && token.kind == TokenKind.localStable,
      );

  @override
  TokenRef get usdLeg => _tokens.firstWhere(
        (token) => token.symbol == 'USDC' && token.chain.caip2 == book.boxChain.caip2,
      );

  TokenRef get usdcOnArb => _tokens.firstWhere(
        (token) => token.symbol == 'USDC' && token.chain.caip2 == arbChain.caip2,
      );

  @override
  Set<Capability> get capabilities => {
        Capability.balances,
        Capability.fxSwap,
        Capability.transfer,
        Capability.paymentRequest,
        Capability.ramp,
        Capability.bridge,
        Capability.yieldVenues,
        Capability.usdValuation,
        Capability.crossBorderPay,
        Capability.crossBorderCollect,
      };

  @override
  Future<List<BalanceRow>> getBalances(Map<String, String> addresses) async {
    final rows = <BalanceRow>[];
    for (final chain in chains) {
      final account = addresses[chain.caip2];
      if (account == null || account.isEmpty) continue;
      final slice = _tokens.where((token) => token.chain.caip2 == chain.caip2).toList();
      rows.addAll(
        await readTokenBalances(
          client: _reads,
          rpcUrl: book.rpcFor(chain),
          tokens: slice,
          account: account,
        ),
      );
    }
    rows.addAll(await _vaultRow(addresses[arbChain.caip2]));
    return rows;
  }

  Future<List<BalanceRow>> _vaultRow(String? account) async {
    if (account == null || account.isEmpty) return const [];
    try {
      final shares = await _reads.balanceOf(
        rpcUrl: TwinTokens.arbRpc,
        token: TwinTokens.vault,
        account: account,
      );
      if (shares == BigInt.zero) return const [];
      final assets = await _reads.readUint(
        rpcUrl: TwinTokens.arbRpc,
        to: TwinTokens.vault,
        data: encodeConvertToAssets(shares),
      );
      return [
        BalanceRow(
          token: TokenRef(
            symbol: 'ARGt',
            address: TwinTokens.vault,
            decimals: 18,
            fiat: 'ARS',
            kind: TokenKind.yieldShare,
            chain: arbChain,
          ),
          amount: Amount(raw: assets, decimals: 18),
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<FxQuote> quote(TokenRef from, TokenRef to, Amount amount) async {
    try {
      final dy = await _dy(from, to, amount.raw);
      final out = Amount(raw: dy.out, decimals: to.decimals);
      if (to.address.toLowerCase() != usdcOnArb.address.toLowerCase() ||
          from.address.toLowerCase() != homeStable.address.toLowerCase()) {
        return _plain(from, to, amount, IndicativePayload(reason: 'hop-unverified', amountOut: out), out);
      }
      final tvl = await _usdSide();
      final notional = _asUsd6(out);
      final cap = CappedSwapPayload(
        notionalUsd: notional,
        spentTodayUsd: Amount.zero(6),
        slippageBps: 100,
        poolTvlUsd: tvl,
      );
      if (!fxEnabled || !cap.executable) {
        return _plain(
          from,
          to,
          amount,
          IndicativePayload(reason: fxEnabled ? 'twin-fx-otc' : 'feature-off', amountOut: out),
          out,
        );
      }
      final minOut = dy.out * BigInt.from(99) ~/ BigInt.from(100);
      final data = encodeCall('exchange(uint256,uint256,uint256,uint256)', [
        padUint(dy.i),
        padUint(dy.j),
        padUint(amount.raw),
        padUint(minOut),
      ]);
      return _plain(
        from,
        to,
        amount,
        CurveSwapPayload(
          cap: cap,
          pool: TwinTokens.curvePool,
          sellToken: from.address,
          sellAmount: amount.raw,
          data: data,
        ),
        out,
        venue: 'pool',
      );
    } catch (_) {
      return _plain(from, to, amount, const NonExecutablePayload('pool-unread'), Amount.zero(to.decimals));
    }
  }

  Future<({BigInt i, BigInt j, BigInt out})> _dy(TokenRef from, TokenRef to, BigInt dx) async {
    final coin0 = await _coin(BigInt.zero);
    final coin1 = await _coin(BigInt.one);
    final i = _index(from.address, coin0, coin1);
    final j = _index(to.address, coin0, coin1);
    final out = await _reads.readUint(
      rpcUrl: TwinTokens.arbRpc,
      to: TwinTokens.curvePool,
      data: encodeCall('get_dy(uint256,uint256,uint256)', [padUint(i), padUint(j), padUint(dx)]),
    );
    return (i: i, j: j, out: out);
  }

  Future<String> _coin(BigInt index) async {
    final word = await _reads.call(TwinTokens.arbRpc, 'eth_call', [
      {
        'to': TwinTokens.curvePool,
        'data': encodeCall('coins(uint256)', [padUint(index)]),
      },
      'latest',
    ]);
    return decodeAddressWord(word);
  }

  BigInt _index(String token, String coin0, String coin1) {
    final want = token.toLowerCase();
    if (coin0.toLowerCase() == want) return BigInt.zero;
    if (coin1.toLowerCase() == want) return BigInt.one;
    throw StateError('token-not-in-pool');
  }

  Future<Amount> _usdSide() async {
    final raw = await _reads.balanceOf(
      rpcUrl: TwinTokens.arbRpc,
      token: usdcOnArb.address,
      account: TwinTokens.curvePool,
    );
    return Amount(raw: raw, decimals: 6);
  }

  Amount _asUsd6(Amount amount) {
    if (amount.decimals == 6) return amount;
    if (amount.decimals > 6) {
      return Amount(raw: amount.raw ~/ pow10(amount.decimals - 6), decimals: 6);
    }
    return Amount(raw: amount.raw * pow10(6 - amount.decimals), decimals: 6);
  }

  @override
  Future<List<PreparedTx>> prepareExecute(FxQuote quote) async {
    if (!fxEnabled || !quote.executable) throw StateError('Sin cotización ejecutable');
    final payload = quote.payload;
    if (payload is! CurveSwapPayload) throw StateError('Sin cotización ejecutable');
    return [
      PreparedTx(
        chain: arbChain,
        to: payload.sellToken,
        data: encodeApprove(payload.pool, payload.sellAmount),
        value: '0x0',
        kind: 'approve',
      ),
      PreparedTx(
        chain: arbChain,
        to: payload.pool,
        data: payload.data,
        value: '0x0',
        kind: 'swap',
      ),
    ];
  }

  @override
  Future<List<PreparedTx>> prepareTransfer(TokenRef token, Amount amount, String to) async {
    if (token.kind == TokenKind.gas) throw StateError('El gas no es saldo.');
    return [
      PreparedTx(
        chain: token.chain,
        to: token.address,
        data: encodeTransfer(to, amount.raw),
        value: '0x0',
        kind: 'transfer',
      ),
    ];
  }

  @override
  Future<List<PreparedTx>> prepareVaultDeposit(Amount assets, String receiver) async {
    return [
      PreparedTx(
        chain: arbChain,
        to: homeStable.address,
        data: encodeApprove(TwinTokens.vault, assets.raw),
        value: '0x0',
        kind: 'approve',
      ),
      PreparedTx(
        chain: arbChain,
        to: TwinTokens.vault,
        data: encodeErc4626Deposit(assets.raw, receiver),
        value: '0x0',
        kind: 'deposit',
      ),
    ];
  }

  @override
  Future<List<PreparedTx>> prepareVaultRedeem(Amount shares, String receiver, String owner) async {
    return [
      PreparedTx(
        chain: arbChain,
        to: TwinTokens.vault,
        data: encodeErc4626Redeem(shares.raw, receiver, owner),
        value: '0x0',
        kind: 'redeem',
      ),
    ];
  }

  @override
  Future<PaymentRequest> paymentRequest(Amount amount) async {
    final payTo = signer.address ?? '0x0000000000000000000000000000000000000001';
    final uri = eip681Transfer(
      token: homeStable.address,
      chainReference: arbChain.reference,
      to: payTo,
      raw: amount.raw,
    );
    return PaymentRequest(amount: amount, token: homeStable, url: uri, qrPayload: uri.toString());
  }

  @override
  Uri? rampUrl(RampDirection direction, Amount amount, String address) => null;

  @override
  Future<List<RampOption>> options(RampDirection direction, String fiat) async {
    return [
      RampOption(
        providerId: 'operator',
        fiat: fiat,
        token: homeStable,
        direction: direction,
        requiresKyc: true,
        verification: 'NV',
      ),
    ];
  }

  @override
  Future<FxRate?> rate(TokenRef from, TokenRef to) async {
    try {
      final word = await _reads.readUint(
        rpcUrl: TwinTokens.arbRpc,
        to: TwinTokens.curvePool,
        data: selector('price_oracle()'),
      );
      final at = await _reads.latestBlockTime(TwinTokens.arbRpc);
      return FxRate.shown(
        base: from.symbol,
        quote: to.symbol,
        rate: Decimal.fromUnits(word, 18),
        source: 'curve-pool',
        at: at,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<YieldVenue>> yieldVenues() async => [
        YieldVenue(
          id: 'local-prime',
          chain: arbChain,
          kind: 'vault',
          asset: homeStable,
          share: TokenRef(
            symbol: homeStable.symbol,
            address: TwinTokens.vault,
            decimals: 18,
            kind: TokenKind.yieldShare,
            chain: arbChain,
            fiat: homeStable.fiat,
          ),
          withdrawalLatency: Duration.zero,
          risks: const ['Rendimiento sobre el activo local. Sin tasa verificada.'],
        ),
      ];

  @override
  Future<PaymentPlan> plan(PaymentIntent intent) async {
    final sameChain = intent.to.chain.caip2 == intent.token.chain.caip2;
    final steps = <PreparedTx>[];
    if (sameChain) {
      steps.addAll(await prepareTransfer(intent.token, intent.amount, intent.to.address));
    } else if (session != null && signer.address != null) {
      final remote = await _remote.prepareBridge(
        session!,
        from: signer.address!,
        amount: intent.amount.format(),
      );
      steps.addAll(remote.steps);
    }
    return PaymentPlan(
      intent: intent,
      fxLegs: const [],
      steps: steps,
      totalCostHome: intent.token.symbol == homeStable.symbol ? intent.amount : Amount.zero(18),
      totalCostUsd: intent.token.kind == TokenKind.usdStable ? intent.amount : Amount.zero(6),
      expiresAt: _clock().add(const Duration(minutes: 5)),
      guardOk: steps.isNotEmpty,
      now: _clock(),
    );
  }

  @override
  Future<List<PreparedTx>> prepare(PaymentPlan plan) async {
    if (!plan.executable) throw StateError('Sin cotización ejecutable');
    return plan.steps;
  }

  FxQuote _plain(
    TokenRef from,
    TokenRef to,
    Amount amount,
    QuotePayload payload,
    Amount out, {
    String venue = 'pool',
  }) {
    return FxQuote(
      id: payload is NonExecutablePayload ? payload.reason : 'pool',
      ecosystemId: id,
      venue: venue,
      from: from,
      to: to,
      amountIn: amount,
      amountOut: out,
      rate: rateText(amount, out),
      payload: payload,
      dryRun: !live,
      clock: _clock(),
    );
  }
}
