import 'amount.dart';
import 'guards.dart';
import 'ledger.dart';

class DailyReview {
  const DailyReview({required this.notes, required this.proposal});
  final List<String> notes;
  final LedgerEvent proposal;
}

DailyReview runDailyReview({
  required String flavor,
  required String ecosystemId,
  required Amount homeBalance,
  required List<ScheduledPayment> scheduled,
  required TreasuryPolicy policy,
  required DateTime nowUtc,
  required bool liveMode,
}) {
  final buffer = bufferOf(
    scheduled: scheduled,
    bufferDays: policy.liquidityBufferDays,
    nowUtc: nowUtc,
    homeDecimals: homeBalance.decimals,
  );
  final spare = homeBalance.raw - buffer.raw;
  final rotable = Amount(
    raw: spare > BigInt.zero ? spare : BigInt.zero,
    decimals: homeBalance.decimals,
  );
  final notes = <String>[
    'Saldo local ${homeBalance.format()}',
    'Reserva ${buffer.format()} por ${policy.liquidityBufferDays} días',
    'Rotable ${rotable.format()}',
    if (scheduled.isEmpty) 'No hay pagos agendados',
    if (liveMode) 'Modo en vivo: igual hace falta firma humana',
  ];
  return DailyReview(
    notes: notes,
    proposal: LedgerEvent(
      at: nowUtc,
      kind: LedgerKind.propose,
      flavor: flavor,
      ecosystemId: ecosystemId,
      dryRun: !liveMode,
      raw: rotable.raw,
      decimals: rotable.decimals,
      reason: notes.join(' · '),
      guardResult: rotable.raw == BigInt.zero ? 'buffer' : 'ok',
    ),
  );
}
