import '../../core/amount.dart';
import '../../core/evm/abi.dart';
import '../../core/evm/balances.dart';
import '../../core/evm/json_rpc.dart';
import '../../core/model.dart';
import '../../core/qr/qr_intent.dart';
import '../../core/signer.dart';
import 'attribution.dart';
import 'identity.dart';
import 'textile_client.dart';
import 'tokens.dart';

final class TextileSwapPayload extends QuotePayload {
  const TextileSwapPayload({
    required this.to,
    required this.data,
    required this.reactor,
    required this.takerPays,
  });

  final String to;
  final String data;
  final String reactor;
  final BigInt takerPays;

  @override
  bool get executable => true;
}

class RipioCeloEcosystem implements TreasuryEcosystem, TrackedInvoice, AgentDirectory {
  RipioCeloEcosystem({
    required this.homeCurrency,
    required this.live,
    required this.signer,
    EvmReadClient? reads,
    TextileClient? textile,
    CeloTokens? catalog,
    DateTime Function()? clock,
  })  : catalog = catalog ?? const CeloTokens(),
        _reads = reads ?? EvmReadClient(),
        _textile = textile ?? TextileClient(baseUrl: CeloTokens.textileApi),
        _clock = clock ?? DateTime.now,
        published = CeloIdentity.unpublished();

  final String homeCurrency;
  final bool live;
  final TxSigner signer;
  final CeloTokens catalog;
  final EvmReadClient _reads;
  final TextileClient _textile;
  final DateTime Function() _clock;

  @override
  AgentIdentity published;

  @override
  Future<AgentIdentity> loadIdentity() async {
    final id = catalog.agentTokenId.trim();
    if (id.isEmpty) {
      published = CeloIdentity.unpublished();
      return published;
    }
    try {
      published = await CeloIdentity(reads: _reads).read(id);
    } catch (_) {
      published = CeloIdentity.unpublished();
    }
    return published;
  }

  @override
  String get id => 'ripio-celo';

  @override
  List<ChainRef> get chains => const [celoChain];

  @override
  List<TokenRef> get tokens => _book;

  late final List<TokenRef> _book = catalog.all();

  @override
  TokenRef get homeStable => _book.firstWhere(
        (token) => token.fiat == homeCurrency && token.kind == TokenKind.localStable,
        orElse: () => _book.first,
      );

  @override
  TokenRef get usdLeg => _book.firstWhere((token) => token.symbol == 'USDT');

  TokenRef get usdc => _book.firstWhere((token) => token.symbol == 'USDC');
  TokenRef get usat => _book.firstWhere((token) => token.symbol == 'USAT');

  @override
  Set<Capability> get capabilities => const {
        Capability.balances,
        Capability.fxSwap,
        Capability.transfer,
        Capability.paymentRequest,
        Capability.ramp,
        Capability.usdValuation,
        Capability.crossBorderPay,
        Capability.crossBorderCollect,
        Capability.autoConvert,
      };

  @override
  Future<List<BalanceRow>> getBalances(Map<String, String> addresses) async {
    final account = addresses[celoChain.caip2];
    if (account == null || account.isEmpty) return const [];
    return readTokenBalances(
      client: _reads,
      rpcUrl: CeloTokens.rpc,
      tokens: _book,
      account: account,
    );
  }

  @override
  Future<FxQuote> quote(TokenRef from, TokenRef to, Amount amount) async {
    if (from.symbol == to.symbol) {
      return _quote(
        id: 'noop',
        from: from,
        to: to,
        amount: amount,
        out: amount,
        payload: const DirectPayload('same-token'),
      );
    }
    if (from.symbol == 'wPEN' || from.symbol == 'wCLP' || to.symbol == 'wPEN' || to.symbol == 'wCLP') {
      return _blocked(from, to, amount, 'no-corridor');
    }
    if (routesViaHub(from, to, 'USDT')) {
      final hub = catalog.bySymbol('USDT');
      final first = await quote(from, hub, amount);
      final second = await quote(hub, to, first.amountOut);
      return _quote(
        id: 'route-${first.id}-${second.id}',
        from: from,
        to: to,
        amount: amount,
        out: second.amountOut,
        payload: RoutePayload([first, second]),
        venue: 'route',
      );
    }
    return _direct(from, to, amount);
  }

  Future<FxQuote> _direct(TokenRef from, TokenRef to, Amount amount) async {
    if (signer.address == null) {
      return _blocked(from, to, amount, 'preview-needs-wallet');
    }
    final nonce = randomNonce();
    final issuedAt = _clock().millisecondsSinceEpoch;
    try {
      final signature = await signer.signTypedData(
        caip2: celoChain.caip2,
        typedDataJson: takerTypedData(taker: signer.address!, nonce: nonce, issuedAt: issuedAt),
      );
      if (!live) {
        final preview = await _textile.preview(
          sellToken: from.address,
          buyToken: to.address,
          sellAmount: amount.raw,
          taker: signer.address!,
          signature: signature,
          nonce: nonce,
          issuedAt: issuedAt,
        );
        final out = Amount(raw: preview.buyAmount, decimals: to.decimals);
        return _quote(
          id: 'preview',
          from: from,
          to: to,
          amount: amount,
          out: out,
          payload: IndicativePayload(reason: 'preview', amountOut: out),
          expiresAt: _clock().add(const Duration(seconds: 60)),
        );
      }
      final requested = await _textile.request(
        sellToken: from.address,
        buyToken: to.address,
        sellAmount: amount.raw,
        taker: signer.address!,
        signature: signature,
        nonce: nonce,
        issuedAt: issuedAt,
      );
      return _quote(
        id: requested.rfqId ?? 'rfq',
        from: from,
        to: to,
        amount: amount,
        out: Amount(raw: requested.buyAmount, decimals: to.decimals),
        payload: TextileSwapPayload(
          to: requested.swapTo!,
          data: requested.swapData!,
          reactor: requested.reactor ?? CeloTokens.reactor,
          takerPays: requested.takerPays ?? amount.raw,
        ),
        expiresAt: requested.expiresAt,
        venue: 'rfq',
      );
    } catch (_) {
      return _blocked(from, to, amount, 'uniswap-stub');
    }
  }

  @override
  Future<List<PreparedTx>> prepareExecute(FxQuote quote) async {
    if (!quote.executable) {
      throw StateError('Sin cotización ejecutable');
    }
    _guardLiveAttribution();
    final payload = quote.payload;
    if (payload is RoutePayload) {
      final steps = <PreparedTx>[];
      for (final leg in payload.legs) {
        steps.addAll(await prepareExecute(leg));
      }
      return steps;
    }
    if (payload is! TextileSwapPayload) {
      throw StateError('Sin cotización ejecutable');
    }
    return [
      _tx(
        to: quote.from.address,
        data: encodeApprove(payload.reactor, payload.takerPays),
        kind: 'approve',
      ),
      _tx(to: payload.to, data: payload.data, kind: 'swap'),
    ];
  }

  @override
  Future<List<PreparedTx>> prepareTransfer(TokenRef token, Amount amount, String to) async {
    _guardLiveAttribution();
    return [
      _tx(to: token.address, data: encodeTransfer(to, amount.raw), kind: 'transfer'),
    ];
  }

  @override
  Future<PaymentRequest> paymentRequest(Amount amount) async {
    final payTo = signer.address ?? '0x0000000000000000000000000000000000000001';
    final uri = eip681Transfer(
      token: homeStable.address,
      chainReference: celoChain.reference,
      to: payTo,
      raw: amount.raw,
    );
    return PaymentRequest(amount: amount, token: homeStable, url: uri, qrPayload: uri.toString());
  }

  @override
  PaymentRequest collectTracked() {
    final payTo = signer.address ?? '0x0000000000000000000000000000000000000001';
    final uri = eip681Transfer(
      token: usat.address,
      chainReference: celoChain.reference,
      to: payTo,
      raw: BigInt.zero,
    );
    final hosted = Uri.parse(
      '${uri.toString()}&facilitator=${Uri.encodeComponent(CeloTokens.facilitator)}',
    );
    return PaymentRequest(
      amount: Amount.zero(usat.decimals),
      token: usat,
      url: hosted,
      qrPayload: uri.toString(),
    );
  }

  @override
  Uri? rampUrl(RampDirection direction, Amount amount, String address) {
    final path = direction == RampDirection.offRamp ? '/offramp' : '/';
    return Uri.parse(
      '${CeloTokens.rampBase}$path?country=AR&chain=42220&token=${homeStable.symbol.toUpperCase()}&amount=${amount.format()}&address=$address',
    );
  }

  @override
  Future<List<RampOption>> options(RampDirection direction, String fiat) async {
    final token = catalog.byFiat(fiat);
    return [
      RampOption(
        providerId: 'link-out',
        fiat: fiat,
        token: token,
        direction: direction,
        url: rampUrl(direction, Amount.parse('1', token.decimals), signer.address ?? token.address),
        requiresKyc: true,
        verification: 'NV',
      ),
    ];
  }

  @override
  Future<FxRate?> rate(TokenRef from, TokenRef to) async => null;

  @override
  Future<PaymentPlan> plan(PaymentIntent intent) async {
    final homeAmount = intent.token.symbol == homeStable.symbol
        ? intent.amount
        : Amount.zero(homeStable.decimals);
    final legs = <FxQuote>[];
    if (intent.token.symbol != homeStable.symbol) {
      final hub = usdLeg;
      if (intent.token.symbol != hub.symbol) {
        legs.add(await quote(homeStable, hub, homeAmount.raw == BigInt.zero ? Amount.parse('1', 18) : homeAmount));
        legs.add(await quote(hub, intent.token, legs.first.amountOut));
      } else {
        legs.add(await quote(homeStable, hub, homeAmount.raw == BigInt.zero ? Amount.parse('1', 18) : homeAmount));
      }
    }
    final steps = <PreparedTx>[];
    final executable = legs.every((leg) => leg.executable);
    if (executable && signer.address != null) {
      steps.addAll(await prepareTransfer(intent.token, intent.amount, intent.to.address));
    }
    return PaymentPlan(
      intent: intent,
      fxLegs: legs,
      steps: steps,
      totalCostHome: homeAmount,
      totalCostUsd: intent.token.kind == TokenKind.usdStable ? intent.amount : Amount.zero(6),
      expiresAt: _clock().add(const Duration(minutes: 5)),
      guardOk: true,
      now: _clock(),
    );
  }

  @override
  Future<List<PreparedTx>> prepare(PaymentPlan plan) async {
    if (!plan.executable) throw StateError('Sin cotización ejecutable');
    final steps = <PreparedTx>[];
    for (final leg in plan.fxLegs) {
      steps.addAll(await prepareExecute(leg));
    }
    steps.addAll(plan.steps);
    return steps;
  }

  @override
  Future<List<YieldVenue>> yieldVenues() async => const [];

  FxQuote _blocked(TokenRef from, TokenRef to, Amount amount, String reason) {
    return _quote(
      id: reason,
      from: from,
      to: to,
      amount: amount,
      out: Amount.zero(to.decimals),
      payload: NonExecutablePayload(reason),
    );
  }

  FxQuote _quote({
    required String id,
    required TokenRef from,
    required TokenRef to,
    required Amount amount,
    required Amount out,
    required QuotePayload payload,
    String venue = 'rfq',
    DateTime? expiresAt,
  }) {
    return FxQuote(
      id: id,
      ecosystemId: this.id,
      venue: venue,
      from: from,
      to: to,
      amountIn: amount,
      amountOut: out,
      rate: rateText(amount, out),
      payload: payload,
      dryRun: !live,
      expiresAt: expiresAt,
      clock: _clock(),
    );
  }

  PreparedTx _tx({required String to, required String data, required String kind}) {
    final code = catalog.attributionCode.trim();
    final attributed = code.isEmpty ? data : withAttribution(data, code);
    final decoded = fromDataSuffix(attributed);
    return PreparedTx(
      chain: celoChain,
      to: to,
      data: attributed,
      value: '0x0',
      kind: kind,
      attributionCode: decoded?.codes.first,
      attributionSchema: decoded?.schemaId,
      warnings: [
        if (!attributionReadyForLive(code)) 'attribution-unverified',
      ],
    );
  }

  void _guardLiveAttribution() {
    if (live && !attributionReadyForLive(catalog.attributionCode.trim())) {
      throw StateError('attribution-unverified');
    }
  }
}
