import 'dart:convert';

import 'package:http/http.dart' as http;

import 'amount.dart';
import 'model.dart';

class LocalMode implements Exception {
  const LocalMode(this.reason);
  final String reason;
  @override
  String toString() => reason;
}

class PanelSnapshot {
  const PanelSnapshot({required this.rows, required this.localMode});
  final List<BalanceRow> rows;
  final bool localMode;
}

/// Reads the panel when it answers with exact decimal strings.
/// The mocked P&L route is intentionally not called.
class TreasuryPanel {
  TreasuryPanel({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<PanelSnapshot> balances(List<TokenRef> known) async {
    if (baseUrl.isEmpty) return const PanelSnapshot(rows: [], localMode: true);
    try {
      final response = await _client
          .get(Uri.parse('${_trim(baseUrl)}/api/balances'))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 400) throw const LocalMode('panel');
      final json = jsonDecode(response.body);
      if (json is! Map || json['rails'] is! List) throw const LocalMode('panel');
      final rows = <BalanceRow>[];
      for (final rail in json['rails'] as List) {
        if (rail is! Map || rail['balances'] is! List) continue;
        for (final row in rail['balances'] as List) {
          if (row is! Map) continue;
          final address = row['address']?.toString().toLowerCase();
          final formatted = row['formatted']?.toString();
          if (address == null || formatted == null) continue;
          TokenRef? token;
          for (final candidate in known) {
            if (candidate.address.toLowerCase() == address) token = candidate;
          }
          if (token == null) continue;
          final human = formatted.split(' ').first;
          rows.add(BalanceRow(token: token, amount: Amount.parse(human, token.decimals)));
        }
      }
      return PanelSnapshot(rows: rows, localMode: false);
    } catch (_) {
      return const PanelSnapshot(rows: [], localMode: true);
    }
  }
}

String _trim(String value) => value.endsWith('/') ? value.substring(0, value.length - 1) : value;
