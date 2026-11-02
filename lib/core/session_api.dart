import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'company_link.dart';

class SessionException implements Exception {
  const SessionException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class SessionApi {
  SessionApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<EcosystemSession> redeem(CompanyLinkPayload link) async {
    final json = await _post(link.apiBase, '/v1/link/redeem', {
      'token': link.token,
      'action': 'link_redeem',
    });
    final tokenHash = json['token_hash']?.toString() ?? '';
    final supabaseUrl = json['supabase_url']?.toString() ?? '';
    final anonKey = json['anon_key']?.toString() ?? '';
    if (tokenHash.isEmpty || !isAllowedSupabaseUrl(supabaseUrl) || anonKey.isEmpty) {
      throw const SessionException('The company QR did not open a session.');
    }
    final tokens = await _verify(supabaseUrl, anonKey, tokenHash);
    final business = json['business'] is Map
        ? Map<String, dynamic>.from(json['business'] as Map)
        : const <String, dynamic>{};
    return EcosystemSession(
      apiBase: link.apiBase,
      supabaseUrl: supabaseUrl,
      anonKey: anonKey,
      accessToken: tokens.access,
      refreshToken: tokens.refresh,
      expiresAt: tokens.expiresAt,
      businessId: business['id']?.toString() ?? link.businessId ?? '',
      businessName: business['name']?.toString() ?? link.businessName ?? '',
      email: json['email']?.toString(),
      portal: json['portal']?.toString() ?? link.portal,
    );
  }

  Future<EcosystemSession> refresh(EcosystemSession session) async {
    final uri = Uri.parse('${_trim(session.supabaseUrl)}/auth/v1/token').replace(
      queryParameters: {'grant_type': 'refresh_token'},
    );
    final response = await _client
        .post(
          uri,
          headers: {'apikey': session.anonKey, 'content-type': 'application/json'},
          body: jsonEncode({'refresh_token': session.refreshToken}),
        )
        .timeout(const Duration(seconds: 20));
    final tokens = _tokens(_decode(response));
    return session.copyWith(
      accessToken: tokens.access,
      refreshToken: tokens.refresh,
      expiresAt: tokens.expiresAt,
    );
  }

  Future<Map<String, dynamic>> me(EcosystemSession session, {String? wallet}) async {
    if (!isAllowedEcosystemBase(session.apiBase)) {
      throw const SessionException('Company API base is not allowed.');
    }
    final uri = Uri.parse('${_trim(session.apiBase)}/v1/me').replace(
      queryParameters: wallet == null ? null : {'wallet': wallet},
    );
    final response = await _client.get(uri, headers: {
      'authorization': 'Bearer ${session.accessToken}',
      'apikey': session.anonKey,
    }).timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(String base, String path, Map<String, dynamic> body) async {
    if (!isAllowedEcosystemBase(base)) {
      throw const SessionException('Company API base is not allowed.');
    }
    final response = await _client
        .post(
          Uri.parse('${_trim(base)}$path'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  Future<_Tokens> _verify(String supabaseUrl, String anonKey, String tokenHash) async {
    final response = await _client
        .post(
          Uri.parse('${_trim(supabaseUrl)}/auth/v1/verify'),
          headers: {'apikey': anonKey, 'content-type': 'application/json'},
          body: jsonEncode({'type': 'magiclink', 'token_hash': tokenHash}),
        )
        .timeout(const Duration(seconds: 20));
    return _tokens(_decode(response));
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      json = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
    } on FormatException {
      throw SessionException('Unreadable company response.', status: response.statusCode);
    }
    if (response.statusCode >= 400 || json['success'] == false) {
      throw SessionException(
        json['error']?.toString() ?? 'The company service rejected the request.',
        status: response.statusCode,
      );
    }
    return json;
  }

  _Tokens _tokens(Map<String, dynamic> json) {
    final nested = json['session'] is Map
        ? Map<String, dynamic>.from(json['session'] as Map)
        : json;
    final access = nested['access_token']?.toString() ?? '';
    final refresh = nested['refresh_token']?.toString() ?? '';
    if (access.isEmpty || refresh.isEmpty) {
      throw const SessionException('The company session did not include tokens.');
    }
    final expiresIn = int.tryParse(nested['expires_in']?.toString() ?? '') ?? 3600;
    return _Tokens(access, refresh, DateTime.now().add(Duration(seconds: expiresIn)));
  }
}

class _Tokens {
  const _Tokens(this.access, this.refresh, this.expiresAt);
  final String access;
  final String refresh;
  final DateTime expiresAt;
}

String _trim(String value) => value.endsWith('/') ? value.substring(0, value.length - 1) : value;

String newIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
