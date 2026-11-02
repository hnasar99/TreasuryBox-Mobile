import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/company_link.dart';
import '../../core/model.dart';
import '../../core/session_api.dart';

class PreparedRemote {
  const PreparedRemote({required this.steps, required this.warnings});
  final List<PreparedTx> steps;
  final List<String> warnings;
}

class ZonaBankApi {
  ZonaBankApi({http.Client? client, this.chains = const []}) : _client = client ?? http.Client();

  final http.Client _client;
  final List<ChainRef> chains;

  Future<PreparedRemote> prepareBoxTransfer(
    EcosystemSession session, {
    required String from,
    required String to,
    required String amount,
  }) {
    return _prepare(session, '/v1/rails/arc/prepare', {
      'idempotency_key': newIdempotencyKey(),
      'from_address': from,
      'to_address': to,
      'amount': amount,
    });
  }

  Future<PreparedRemote> prepareBridge(
    EcosystemSession session, {
    required String from,
    required String amount,
  }) {
    return _prepare(session, '/v1/rails/cctp/prepare', {
      'idempotency_key': newIdempotencyKey(),
      'from_address': from,
      'amount': amount,
    });
  }

  Future<Map<String, dynamic>> bridgeStatus(EcosystemSession session, String burnTx) async {
    final uri = Uri.parse('${_trim(session.apiBase)}/v1/rails/cctp/status').replace(
      queryParameters: {'burn_tx': burnTx},
    );
    final response = await _client.get(uri, headers: _headers(session)).timeout(const Duration(seconds: 20));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw StateError('Unreadable bridge status.');
    return Map<String, dynamic>.from(decoded);
  }

  Future<PreparedRemote> _prepare(
    EcosystemSession session,
    String path,
    Map<String, dynamic> body,
  ) async {
    if (!isAllowedEcosystemBase(session.apiBase)) {
      throw StateError('Company API base is not allowed.');
    }
    final response = await _client
        .post(
          Uri.parse('${_trim(session.apiBase)}$path'),
          headers: _headers(session),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400 || decoded is! Map) {
      throw StateError('Prepare was rejected.');
    }
    return parsePrepared(Map<String, dynamic>.from(decoded));
  }

  PreparedRemote parsePrepared(Map<String, dynamic> json) {
    final prepared = json['prepared'] is Map
        ? Map<String, dynamic>.from(json['prepared'] as Map)
        : json;
    final chainId = prepared['chainId']?.toString() ?? '';
    ChainRef chain = ChainRef(
      namespace: 'eip155',
      reference: chainId,
      testnet: chainId == '5042002' || chainId == '421614',
      label: chainId,
    );
    for (final item in chains) {
      if (item.reference == chainId) chain = item;
    }
    final warnings = prepared['warnings'] is List
        ? (prepared['warnings'] as List).map((item) => item.toString()).toList()
        : <String>[];
    final steps = <PreparedTx>[];
    if (prepared['steps'] is List) {
      for (final row in prepared['steps'] as List) {
        if (row is! Map) continue;
        final to = row['to']?.toString() ?? '';
        if (!to.startsWith('0x')) continue;
        steps.add(
          PreparedTx(
            chain: chain,
            to: to,
            data: row['data']?.toString() ?? '0x',
            value: row['value']?.toString() ?? '0x0',
            kind: row['kind']?.toString() ?? 'transfer',
            warnings: warnings,
          ),
        );
      }
    }
    return PreparedRemote(steps: steps, warnings: warnings);
  }

  Map<String, String> _headers(EcosystemSession session) => {
        'authorization': 'Bearer ${session.accessToken}',
        'apikey': session.anonKey,
        'content-type': 'application/json',
      };
}

String _trim(String value) => value.endsWith('/') ? value.substring(0, value.length - 1) : value;
