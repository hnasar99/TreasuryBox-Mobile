import 'amount.dart';
import 'decimal.dart';

class FlowPoint {
  const FlowPoint({required this.at, required this.amount});
  final DateTime at;
  final Amount amount;
}

class TreasuryReport {
  const TreasuryReport._({
    required this.sufficient,
    this.vEnd,
    this.netFlows,
    this.vsHold,
    this.vsInflation,
    this.dietz,
  });

  const TreasuryReport.insufficient() : this._(sufficient: false);

  final bool sufficient;
  final Amount? vEnd;
  final Amount? netFlows;
  final Amount? vsHold;
  final Amount? vsInflation;
  final Decimal? dietz;

  static TreasuryReport build({
    required Amount? vStart,
    required Amount? vEnd,
    required List<FlowPoint> flows,
    required Decimal inflationMonthlyPct,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    if (vStart == null || vEnd == null) return const TreasuryReport.insufficient();
    if (vStart.decimals != vEnd.decimals) return const TreasuryReport.insufficient();
    var net = BigInt.zero;
    var weighted = BigInt.zero;
    final span = periodEnd.difference(periodStart).inSeconds;
    for (final flow in flows) {
      if (flow.amount.decimals != vStart.decimals) return const TreasuryReport.insufficient();
      net += flow.amount.raw;
      if (span > 0) {
        final elapsed = flow.at.difference(periodStart).inSeconds.clamp(0, span);
        final weight = BigInt.from(span - elapsed);
        weighted += flow.amount.raw * weight;
      }
    }
    final decimals = vStart.decimals;
    final flowsAmount = Amount(raw: net, decimals: decimals);
    final hold = Amount(raw: vEnd.raw - (vStart.raw + net), decimals: decimals);
    final fraction = Decimal.fromUnits(inflationMonthlyPct.units, inflationMonthlyPct.scale + 2);
    final infl = Decimal.parse('1') + fraction;
    final base = Amount(raw: vStart.raw + net, decimals: decimals);
    final inflated = convertAtRate(amount: base, rate: infl, quoteDecimals: decimals);
    final vsInflation = Amount(raw: vEnd.raw - inflated.raw, decimals: decimals);
    Decimal? dietz;
    if (span > 0) {
      final denominator = vStart.raw * BigInt.from(span) + weighted;
      if (denominator != BigInt.zero) {
        final scaled = hold.raw * BigInt.from(10).pow(8) * BigInt.from(span) ~/ denominator;
        dietz = Decimal.fromUnits(scaled, 8);
      }
    }
    return TreasuryReport._(
      sufficient: true,
      vEnd: vEnd,
      netFlows: flowsAmount,
      vsHold: hold,
      vsInflation: vsInflation,
      dietz: dietz,
    );
  }
}
