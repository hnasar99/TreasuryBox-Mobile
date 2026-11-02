/// Base-10 decimal kept as an integer. No binary floating point.
class Decimal implements Comparable<Decimal> {
  Decimal._(this.units, this.scale);

  final BigInt units;
  final int scale;

  static final zero = Decimal._(BigInt.zero, 0);

  factory Decimal.fromUnits(BigInt units, int scale) => Decimal._(units, scale);

  static Decimal parse(String input) {
    final text = input.trim();
    if (!RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]+)?$').hasMatch(text)) {
      throw FormatException('Invalid decimal $input');
    }
    final parts = text.split('.');
    final fraction = parts.length == 2 ? parts[1] : '';
    final digits = parts[0] + fraction;
    return Decimal._(BigInt.parse(digits), fraction.length);
  }

  Decimal align(int newScale) {
    if (newScale == scale) return this;
    if (newScale > scale) {
      return Decimal._(units * pow10(newScale - scale), newScale);
    }
    return Decimal._(units ~/ pow10(scale - newScale), newScale);
  }

  Decimal operator +(Decimal other) {
    final next = scale > other.scale ? scale : other.scale;
    return Decimal._(align(next).units + other.align(next).units, next);
  }

  Decimal operator -(Decimal other) {
    final next = scale > other.scale ? scale : other.scale;
    return Decimal._(align(next).units - other.align(next).units, next);
  }

  Decimal operator *(Decimal other) {
    return Decimal._(units * other.units, scale + other.scale);
  }

  bool operator >(Decimal other) => compareTo(other) > 0;
  bool operator >=(Decimal other) => compareTo(other) >= 0;
  bool operator <(Decimal other) => compareTo(other) < 0;
  bool operator <=(Decimal other) => compareTo(other) <= 0;

  @override
  int compareTo(Decimal other) {
    final next = scale > other.scale ? scale : other.scale;
    return align(next).units.compareTo(other.align(next).units);
  }

  @override
  String toString() {
    if (scale == 0) return units.toString();
    final negative = units.isNegative;
    final digits = units.abs().toString().padLeft(scale + 1, '0');
    final whole = digits.substring(0, digits.length - scale);
    final fraction = digits.substring(digits.length - scale).replaceFirst(RegExp(r'0+$'), '');
    final body = fraction.isEmpty ? whole : '$whole.$fraction';
    return negative ? '-$body' : body;
  }

  @override
  bool operator ==(Object other) => other is Decimal && compareTo(other) == 0;

  @override
  int get hashCode => align(18).units.hashCode;
}

BigInt pow10(int n) {
  if (n < 0) throw ArgumentError('Negative scale');
  return BigInt.from(10).pow(n);
}
