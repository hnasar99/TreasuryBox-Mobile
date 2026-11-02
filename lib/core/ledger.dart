enum LedgerKind {
  quote,
  propose,
  approve,
  reject,
  sign,
  receipt,
  collect,
  report,
  guardBlock,
}

class LedgerEvent {
  const LedgerEvent({
    required this.at,
    required this.kind,
    required this.flavor,
    required this.ecosystemId,
    required this.dryRun,
    this.caip2,
    this.raw,
    this.decimals,
    this.rate,
    this.venue,
    this.txHash,
    this.markPriceHome,
    this.reason,
    this.guardResult,
  });

  final DateTime at;
  final LedgerKind kind;
  final String flavor;
  final String ecosystemId;
  final String? caip2;
  final BigInt? raw;
  final int? decimals;
  final String? rate;
  final String? venue;
  final bool dryRun;
  final String? txHash;
  final String? markPriceHome;
  final String? reason;
  final String? guardResult;

  Map<String, Object?> toJson() => {
        'at': at.toIso8601String(),
        'kind': kind.name,
        'flavor': flavor,
        'ecosystemId': ecosystemId,
        'caip2': caip2,
        'raw': raw?.toString(),
        'decimals': decimals,
        'rate': rate,
        'venue': venue,
        'dryRun': dryRun,
        'txHash': txHash,
        'markPriceHome': markPriceHome,
        'reason': reason,
        'guardResult': guardResult,
      };
}

class Ledger {
  Ledger([List<LedgerEvent>? events]) : events = [...?events];

  final List<LedgerEvent> events;

  void add(LedgerEvent event) => events.add(event);

  String toCsv() {
    const header =
        'at,kind,flavor,ecosystemId,caip2,raw,decimals,rate,venue,dryRun,txHash,markPriceHome,reason,guardResult';
    final lines = events.map((event) {
      final json = event.toJson();
      return [
        json['at'],
        json['kind'],
        json['flavor'],
        json['ecosystemId'],
        json['caip2'],
        json['raw'],
        json['decimals'],
        json['rate'],
        json['venue'],
        json['dryRun'],
        json['txHash'],
        json['markPriceHome'],
        json['reason'],
        json['guardResult'],
      ].map(_csv).join(',');
    });
    return [header, ...lines].join('\n');
  }
}

String _csv(Object? value) {
  final text = value?.toString() ?? '';
  if (text.contains(',') || text.contains('"') || text.contains('\n')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

abstract interface class KvStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class MemoryKv implements KvStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
