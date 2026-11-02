import 'decimal.dart';

/// Converts [amount] into [quoteDecimals] at [rate] quote-units per 1 human unit.
/// [ceil] rounds away from zero so a cap check does not understate the cost.
Amount convertAtRate({
  required Amount amount,
  required Decimal rate,
  required int quoteDecimals,
  bool ceil = false,
}) {
  if (amount.decimals < 0 || quoteDecimals < 0) {
    throw ArgumentError('Invalid decimals');
  }
  final negative = amount.raw.isNegative;
  final magnitude = amount.raw.abs();
  final numerator = magnitude * rate.units.abs() * pow10(quoteDecimals);
  final denominator = pow10(amount.decimals) * pow10(rate.scale);
  if (denominator == BigInt.zero) {
    throw ArgumentError('Invalid rate scale');
  }
  var raw = numerator ~/ denominator;
  if (ceil && numerator != BigInt.zero && numerator % denominator != BigInt.zero) {
    raw += BigInt.one;
  }
  final signed = negative == rate.units.isNegative || raw == BigInt.zero;
  return Amount(raw: signed ? raw : -raw, decimals: quoteDecimals);
}

/// Smallest-unit amount. Parsing and formatting never go through binary floats.
class Amount {
  const Amount({required this.raw, required this.decimals});

  final BigInt raw;
  final int decimals;

  static Amount zero(int decimals) => Amount(raw: BigInt.zero, decimals: decimals);

  static Amount parse(String input, int decimals) {
    if (decimals < 0 || decimals > 77) {
      throw ArgumentError('Invalid decimals');
    }
    final amount = input.trim();
    final pattern = '^((?:0|[1-9][0-9]*)(?:\\.[0-9]{1,$decimals})?)\$';
    if (amount.length > 80 || !RegExp(pattern).hasMatch(amount)) {
      throw FormatException(
        'Use a decimal amount with up to $decimals places. '
        'Commas, signs and exponents are not accepted.',
      );
    }
    final parts = amount.split('.');
    final whole = BigInt.parse(parts[0]) * pow10(decimals);
    final fraction = parts.length == 2
        ? BigInt.parse(parts[1].padRight(decimals, '0'))
        : BigInt.zero;
    return Amount(raw: whole + fraction, decimals: decimals);
  }

  String format({int? places}) {
    if (decimals < 0 || decimals > 77) {
      throw ArgumentError('Invalid decimals');
    }
    final negative = raw.isNegative;
    final value = raw.abs();
    final shown = (places ?? decimals).clamp(0, decimals);
    final base = pow10(decimals);
    final whole = value ~/ base;
    final fraction = (value % base)
        .toString()
        .padLeft(decimals, '0')
        .substring(0, shown)
        .replaceFirst(RegExp(r'0+$'), '');
    final body = fraction.isEmpty ? '$whole' : '$whole.$fraction';
    return negative ? '-$body' : body;
  }

  Amount operator +(Amount other) => _same(other, raw + other.raw);
  Amount operator -(Amount other) => _same(other, raw - other.raw);

  bool operator >(Amount other) => _cmp(other) > 0;
  bool operator >=(Amount other) => _cmp(other) >= 0;
  bool operator <(Amount other) => _cmp(other) < 0;
  bool operator <=(Amount other) => _cmp(other) <= 0;

  Amount _same(Amount other, BigInt next) {
    if (decimals != other.decimals) {
      throw ArgumentError('Refusing to mix $decimals and ${other.decimals} places');
    }
    return Amount(raw: next, decimals: decimals);
  }

  int _cmp(Amount other) {
    if (decimals != other.decimals) {
      throw ArgumentError('Refusing to mix $decimals and ${other.decimals} places');
    }
    return raw.compareTo(other.raw);
  }

  @override
  bool operator ==(Object other) =>
      other is Amount && other.decimals == decimals && other.raw == raw;

  @override
  int get hashCode => Object.hash(raw, decimals);
}

String rateText(Amount input, Amount output) {
  if (input.raw == BigInt.zero) return '0';
  final scaled = output.raw * pow10(input.decimals + 8) ~/ (input.raw * pow10(output.decimals));
  return Decimal.fromUnits(scaled, 8).toString();
}
