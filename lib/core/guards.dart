import 'amount.dart';
import 'decimal.dart';

class TreasuryPolicy {
  const TreasuryPolicy({
    required this.homeCurrency,
    required this.maxOpHome,
    required this.maxDailyHome,
    required this.liquidityBufferDays,
    required this.timeZone,
    required this.inflationMonthlyPct,
  });

  final String homeCurrency;
  final Decimal maxOpHome;
  final Decimal maxDailyHome;
  final int liquidityBufferDays;
  final String timeZone;
  final Decimal inflationMonthlyPct;

  Amount maxOpRaw(int homeDecimals) => _toRaw(maxOpHome, homeDecimals);
  Amount maxDailyRaw(int homeDecimals) => _toRaw(maxDailyHome, homeDecimals);

  Amount _toRaw(Decimal human, int decimals) {
    return convertAtRate(
      amount: Amount(raw: BigInt.one, decimals: 0),
      rate: human,
      quoteDecimals: decimals,
      ceil: true,
    );
  }
}

class ScheduledPayment {
  const ScheduledPayment({
    required this.id,
    required this.supplier,
    required this.amountHome,
    required this.due,
  });

  final String id;
  final String supplier;
  final Amount amountHome;
  final DateTime due;
}

class DayLedger {
  const DayLedger({
    required this.day,
    required this.liveSpent,
    required this.dryRunIntended,
    required this.liveKeys,
  });

  final String day;
  final BigInt liveSpent;
  final BigInt dryRunIntended;
  final Set<String> liveKeys;

  static const storageKey = 'tb_treasury_day_v1';

  factory DayLedger.empty(String day) => DayLedger(
        day: day,
        liveSpent: BigInt.zero,
        dryRunIntended: BigInt.zero,
        liveKeys: const {},
      );

  DayLedger forDay(String today) => day == today ? this : DayLedger.empty(today);

  DayLedger recordLive({
    required String dayKey,
    required String caip2,
    required String txHash,
    required BigInt raw,
  }) {
    final current = forDay(dayKey);
    final key = '$caip2:${txHash.toLowerCase()}';
    if (current.liveKeys.contains(key) || raw <= BigInt.zero) return current;
    return DayLedger(
      day: current.day,
      liveSpent: current.liveSpent + raw,
      dryRunIntended: current.dryRunIntended,
      liveKeys: {...current.liveKeys, key},
    );
  }

  DayLedger recordDryRun({required String dayKey, required BigInt raw}) {
    final current = forDay(dayKey);
    if (raw <= BigInt.zero) return current;
    return DayLedger(
      day: current.day,
      liveSpent: current.liveSpent,
      dryRunIntended: current.dryRunIntended + raw,
      liveKeys: current.liveKeys,
    );
  }

  Map<String, Object> toJson() => {
        'day': day,
        'liveSpent': liveSpent.toString(),
        'dryRunIntended': dryRunIntended.toString(),
        'liveKeys': liveKeys.toList()..sort(),
      };

  factory DayLedger.fromJson(Map<String, dynamic> json) {
    final keys = json['liveKeys'];
    return DayLedger(
      day: json['day'] as String,
      liveSpent: BigInt.parse(json['liveSpent'] as String),
      dryRunIntended: BigInt.parse(json['dryRunIntended'] as String),
      liveKeys: keys is List ? keys.map((key) => key.toString()).toSet() : const {},
    );
  }
}

class GuardResult {
  const GuardResult._(this.ok, this.code, this.buffer, this.rotable);
  const GuardResult.blocked(String code, {required Amount buffer, required Amount rotable})
      : this._(false, code, buffer, rotable);
  const GuardResult.ok({required Amount buffer, required Amount rotable})
      : this._(true, 'ok', buffer, rotable);

  final bool ok;
  final String code;
  final Amount buffer;
  final Amount rotable;
}

/// Calendar day in America/Argentina/Buenos_Aires (fixed UTC-3, no DST).
DateTime artMoment(DateTime utc) => utc.toUtc().add(const Duration(hours: -3));

String artDayKey(DateTime utc) {
  final local = artMoment(utc);
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

DateTime _dateOnly(DateTime value) => DateTime.utc(value.year, value.month, value.day);

Amount bufferOf({
  required List<ScheduledPayment> scheduled,
  required int bufferDays,
  required DateTime nowUtc,
  required int homeDecimals,
}) {
  final today = _dateOnly(artMoment(nowUtc));
  final horizon = today.add(Duration(days: bufferDays));
  var raw = BigInt.zero;
  for (final payment in scheduled) {
    final due = _dateOnly(payment.due);
    if (!due.isAfter(horizon)) raw += payment.amountHome.raw;
  }
  return Amount(raw: raw, decimals: homeDecimals);
}

GuardResult evaluateMovement({
  required TreasuryPolicy policy,
  required Amount homeBalance,
  required Amount amountHome,
  required List<ScheduledPayment> scheduled,
  required DayLedger ledger,
  required DateTime nowUtc,
  required bool liveMode,
  required bool quoteExecutable,
  required bool humanConfirmed,
}) {
  final decimals = homeBalance.decimals;
  if (amountHome.decimals != decimals) {
    throw ArgumentError('Home amounts must share decimals');
  }
  final buffer = bufferOf(
    scheduled: scheduled,
    bufferDays: policy.liquidityBufferDays,
    nowUtc: nowUtc,
    homeDecimals: decimals,
  );
  final spare = homeBalance.raw - buffer.raw;
  final rotable = Amount(raw: spare > BigInt.zero ? spare : BigInt.zero, decimals: decimals);
  GuardResult block(String code) => GuardResult.blocked(code, buffer: buffer, rotable: rotable);

  if (amountHome.raw > rotable.raw) return block('buffer');
  if (amountHome.raw > policy.maxOpRaw(decimals).raw) return block('cap_op');
  final day = ledger.forDay(artDayKey(nowUtc));
  final spent = liveMode ? day.liveSpent : day.dryRunIntended;
  if (spent + amountHome.raw > policy.maxDailyRaw(decimals).raw) return block('cap_day');
  if (liveMode && !quoteExecutable) return block('not_executable');
  if (liveMode && !humanConfirmed) return block('needs_signature');
  return GuardResult.ok(buffer: buffer, rotable: rotable);
}
