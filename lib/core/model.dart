import 'amount.dart';
import 'decimal.dart';

class ChainRef {
  const ChainRef({
    required this.namespace,
    required this.reference,
    required this.testnet,
    required this.label,
  });

  final String namespace;
  final String reference;
  final bool testnet;
  final String label;

  String get caip2 => '$namespace:$reference';

  @override
  bool operator ==(Object other) => other is ChainRef && other.caip2 == caip2 && other.testnet == testnet;

  @override
  int get hashCode => Object.hash(caip2, testnet);
}

enum TokenKind { localStable, usdStable, yieldShare, gas }

class TokenRef {
  const TokenRef({
    required this.symbol,
    required this.address,
    required this.decimals,
    required this.kind,
    required this.chain,
    this.fiat,
  });

  final String symbol;
  final String address;
  final int decimals;
  final String? fiat;
  final TokenKind kind;
  final ChainRef chain;

  String get key => '${chain.caip2}:${address.toLowerCase()}:${kind.name}';
}

class BalanceRow {
  const BalanceRow({required this.token, required this.amount});

  final TokenRef token;
  final Amount amount;
}

/// Same-chain, same-network totals only. Anything else stays unmerged.
Amount? sumSameBook(List<BalanceRow> rows) {
  if (rows.isEmpty) return null;
  final chain = rows.first.token.chain;
  if (rows.any((row) => row.token.chain.caip2 != chain.caip2 || row.token.chain.testnet != chain.testnet)) {
    return null;
  }
  if (rows.map((row) => row.token.symbol).toSet().length != 1) return null;
  if (rows.map((row) => row.amount.decimals).toSet().length != 1) return null;
  var raw = BigInt.zero;
  for (final row in rows) {
    raw += row.amount.raw;
  }
  return Amount(raw: raw, decimals: rows.first.amount.decimals);
}

abstract class QuotePayload {
  const QuotePayload();
  bool get executable;
}

final class NonExecutablePayload extends QuotePayload {
  const NonExecutablePayload(this.reason);
  final String reason;
  @override
  bool get executable => false;
}

/// Indicative number the user can read. It never authorizes a signature.
final class IndicativePayload extends QuotePayload {
  const IndicativePayload({required this.reason, required this.amountOut});
  final String reason;
  final Amount amountOut;
  @override
  bool get executable => false;
}

/// USD caps for a small on-venue swap. Names of venues stay outside this file.
final class CappedSwapPayload extends QuotePayload {
  const CappedSwapPayload({
    required this.notionalUsd,
    required this.spentTodayUsd,
    required this.slippageBps,
    required this.poolTvlUsd,
  });

  final Amount notionalUsd;
  final Amount spentTodayUsd;
  final int slippageBps;
  final Amount poolTvlUsd;

  static final opCap = Amount.parse('500', 6);
  static final hardCap = Amount.parse('1000', 6);
  static final dailyCap = Amount.parse('2000', 6);
  static final minTvl = Amount.parse('15000', 6);
  static const maxSlippageBps = 150;

  @override
  bool get executable {
    if (notionalUsd.decimals != 6 || spentTodayUsd.decimals != 6 || poolTvlUsd.decimals != 6) {
      return false;
    }
    if (notionalUsd > opCap || notionalUsd > hardCap) return false;
    if (spentTodayUsd + notionalUsd > dailyCap) return false;
    if (slippageBps > maxSlippageBps) return false;
    if (poolTvlUsd < minTvl) return false;
    return true;
  }
}

final class DirectPayload extends QuotePayload {
  const DirectPayload(this.kind);
  final String kind;
  @override
  bool get executable => true;
}

final class RoutePayload extends QuotePayload {
  const RoutePayload(this.legs);
  final List<FxQuote> legs;
  @override
  bool get executable => legs.isNotEmpty && legs.every((leg) => leg.executable);
}

class FxQuote {
  const FxQuote({
    required this.id,
    required this.ecosystemId,
    required this.venue,
    required this.from,
    required this.to,
    required this.amountIn,
    required this.amountOut,
    required this.rate,
    required this.payload,
    required this.dryRun,
    this.expiresAt,
    this.clock,
  });

  final String id;
  final String ecosystemId;
  final String venue;
  final TokenRef from;
  final TokenRef to;
  final Amount amountIn;
  final Amount amountOut;
  final String rate;
  final DateTime? expiresAt;
  final QuotePayload payload;
  final bool dryRun;
  final DateTime? clock;

  bool get expired {
    final expiry = expiresAt;
    if (expiry == null) return false;
    return !(clock ?? DateTime.now()).isBefore(expiry);
  }

  bool get executable => payload.executable && !expired;
}

class PreparedTx {
  const PreparedTx({
    required this.chain,
    required this.to,
    required this.data,
    required this.value,
    required this.kind,
    this.warnings = const [],
    this.attributionCode,
    this.attributionSchema,
  });

  final ChainRef chain;
  final String to;
  final String data;
  final String value;
  final String kind;
  final List<String> warnings;
  final String? attributionCode;
  final int? attributionSchema;

  Map<String, String> transaction(String from) => {
        'from': from,
        'to': to,
        'data': data.isEmpty ? '0x' : data,
        'value': value.isEmpty ? '0x0' : value,
        'chainId': '0x${int.parse(chain.reference).toRadixString(16)}',
        'type': '0x2',
      };
}

enum ValuationView { home, usd }

enum Capability {
  balances,
  fxSwap,
  transfer,
  paymentRequest,
  ramp,
  bridge,
  yieldVenues,
  usdValuation,
  crossBorderPay,
  crossBorderCollect,
  autoConvert,
  offRamp,
  batchPayout,
}

enum RampDirection { onRamp, offRamp }

class RampOption {
  const RampOption({
    required this.providerId,
    required this.fiat,
    required this.token,
    required this.direction,
    required this.requiresKyc,
    required this.verification,
    this.url,
  });

  final String providerId;
  final String fiat;
  final TokenRef token;
  final RampDirection direction;
  final Uri? url;
  final bool requiresKyc;
  final String verification;
}

abstract interface class RampProvider {
  Future<List<RampOption>> options(RampDirection direction, String fiat);
}

class DepositInstructions {
  const DepositInstructions({
    required this.token,
    required this.address,
    required this.qr,
  });

  final TokenRef token;
  final String address;
  final Uri qr;
}

class FxRate {
  const FxRate({
    required this.base,
    required this.quote,
    required this.rate,
    required this.source,
    required this.at,
  });

  final String base;
  final String quote;
  final Decimal rate;
  final String source;
  final DateTime at;

  static FxRate? shown({
    required String base,
    required String quote,
    required Decimal? rate,
    required String? source,
    required DateTime? at,
  }) {
    if (rate == null || source == null || source.isEmpty || at == null) return null;
    return FxRate(base: base, quote: quote, rate: rate, source: source, at: at);
  }
}

abstract interface class FxRateSource {
  Future<FxRate?> rate(TokenRef from, TokenRef to);
}

class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.name,
    required this.chain,
    required this.address,
    required this.preferredToken,
    required this.verified,
    this.country,
    this.confirmations = 0,
  });

  final String id;
  final String name;
  final String? country;
  final ChainRef chain;
  final String address;
  final TokenRef preferredToken;
  final bool verified;
  final int confirmations;

  Beneficiary copyWith({int? confirmations, bool? verified}) => Beneficiary(
        id: id,
        name: name,
        country: country,
        chain: chain,
        address: address,
        preferredToken: preferredToken,
        verified: verified ?? this.verified,
        confirmations: confirmations ?? this.confirmations,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'caip2': chain.caip2,
        'testnet': chain.testnet,
        'label': chain.label,
        'namespace': chain.namespace,
        'reference': chain.reference,
        'address': address,
        'symbol': preferredToken.symbol,
        'token': preferredToken.address,
        'decimals': preferredToken.decimals,
        'kind': preferredToken.kind.name,
        'fiat': preferredToken.fiat,
        'verified': verified,
        'confirmations': confirmations,
      };
}

class PaymentIntent {
  const PaymentIntent({
    required this.to,
    required this.amount,
    required this.token,
    this.memo,
    this.invoiceRef,
  });

  final Beneficiary to;
  final Amount amount;
  final TokenRef token;
  final String? memo;
  final String? invoiceRef;
}

class PaymentPlan {
  const PaymentPlan({
    required this.intent,
    required this.fxLegs,
    required this.steps,
    required this.totalCostHome,
    required this.totalCostUsd,
    required this.expiresAt,
    required this.guardOk,
    this.now,
  });

  final PaymentIntent intent;
  final List<FxQuote> fxLegs;
  final List<PreparedTx> steps;
  final Amount totalCostHome;
  final Amount totalCostUsd;
  final DateTime expiresAt;
  final bool guardOk;
  final DateTime? now;

  bool get executable {
    final clock = now ?? DateTime.now();
    if (!guardOk || !clock.isBefore(expiresAt)) return false;
    if (fxLegs.any((leg) => !leg.executable)) return false;
    final known = intent.to.verified || intent.to.confirmations >= 2;
    return known;
  }
}

abstract interface class CrossBorderRail {
  Future<PaymentPlan> plan(PaymentIntent intent);
  Future<List<PreparedTx>> prepare(PaymentPlan plan);
}

class AutoConvertRule {
  const AutoConvertRule({required this.pctBps, this.minHome});
  final int pctBps;
  final Amount? minHome;
}

class Invoice {
  const Invoice({
    required this.id,
    required this.amount,
    required this.token,
    required this.link,
    required this.qr,
    this.due,
  });

  final String id;
  final Amount amount;
  final TokenRef token;
  final Uri link;
  final Uri qr;
  final DateTime? due;
}

class AgentProposal {
  const AgentProposal({
    required this.id,
    required this.summary,
    this.rule,
    this.invoice,
  });

  final String id;
  final String summary;
  final AutoConvertRule? rule;
  final Invoice? invoice;
}

/// A collection rule becomes a proposal. It never builds a signed transaction.
AgentProposal proposeAutoConvert({
  required Invoice invoice,
  required AutoConvertRule rule,
}) {
  final whole = rule.pctBps ~/ 100;
  final rest = rule.pctBps % 100;
  final pct = rest == 0 ? '$whole%' : '$whole.${rest.toString().padLeft(2, '0')}%';
  return AgentProposal(
    id: 'collect-${invoice.id}',
    summary: 'Propuesta: convertir $pct del cobro a moneda local. No se firma.',
    rule: rule,
    invoice: invoice,
  );
}

class PaymentRequest {
  const PaymentRequest({
    required this.amount,
    required this.token,
    required this.url,
    required this.qrPayload,
    this.expiresAt,
  });

  final Amount amount;
  final TokenRef token;
  final Uri url;
  final String qrPayload;
  final DateTime? expiresAt;
}

class YieldVenue {
  const YieldVenue({
    required this.id,
    required this.chain,
    required this.kind,
    required this.asset,
    required this.withdrawalLatency,
    required this.risks,
    this.share,
    this.lockup,
    this.apyLabel,
  });

  final String id;
  final ChainRef chain;
  final String kind;
  final TokenRef asset;
  final TokenRef? share;
  final Duration withdrawalLatency;
  final Duration? lockup;
  final String? apyLabel;
  final List<String> risks;
}

abstract interface class TreasuryEcosystem implements FxRateSource, RampProvider, CrossBorderRail {
  String get id;
  List<ChainRef> get chains;
  List<TokenRef> get tokens;
  TokenRef get homeStable;
  TokenRef get usdLeg;
  Set<Capability> get capabilities;

  Future<List<BalanceRow>> getBalances(Map<String, String> addresses);
  Future<FxQuote> quote(TokenRef from, TokenRef to, Amount amount);
  Future<List<PreparedTx>> prepareExecute(FxQuote quote);
  Future<List<PreparedTx>> prepareTransfer(TokenRef token, Amount amount, String to);
  Future<PaymentRequest> paymentRequest(Amount amount);
  Uri? rampUrl(RampDirection direction, Amount amount, String address);
  Future<List<YieldVenue>> yieldVenues() async => const [];
}

abstract interface class YieldActions {
  Future<List<PreparedTx>> prepareVaultDeposit(Amount assets, String receiver);
  Future<List<PreparedTx>> prepareVaultRedeem(Amount shares, String receiver, String owner);
}

abstract interface class TrackedInvoice {
  PaymentRequest collectTracked();
}

class AgentIdentity {
  const AgentIdentity({
    required this.name,
    required this.description,
    required this.registration,
    this.agentId,
    this.agentUri,
    this.owner,
    this.registry,
  });

  final String name;
  final String description;
  final Map<String, Object?> registration;
  final String? agentId;
  final String? agentUri;
  final String? owner;
  final String? registry;

  bool get onChain => agentId != null && agentId!.isNotEmpty;
}

abstract interface class AgentDirectory {
  AgentIdentity get published;
  Future<AgentIdentity> loadIdentity();
}
