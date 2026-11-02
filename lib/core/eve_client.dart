import 'dart:convert';

import 'package:http/http.dart' as http;

class EveEvent {
  const EveEvent({required this.raw, this.type, this.interactionId, this.text});

  final Map<String, dynamic> raw;
  final String? type;
  final String? interactionId;
  final String? text;

  factory EveEvent.fromJson(Map<String, dynamic> json) {
    return EveEvent(
      raw: json,
      type: json['type']?.toString(),
      interactionId: json['interactionId']?.toString() ?? json['interaction_id']?.toString(),
      text: json['text']?.toString() ?? json['delta']?.toString() ?? json['message']?.toString(),
    );
  }
}

List<EveEvent> parseNdjson(String body) {
  final events = <EveEvent>[];
  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) {
      events.add(EveEvent.fromJson(Map<String, dynamic>.from(decoded)));
    }
  }
  return events;
}

class EveClient {
  EveClient({required this.baseUrl, http.Client? client, this.flavorHeader})
      : _client = client ?? http.Client();

  final String baseUrl;
  final String? flavorHeader;
  final http.Client _client;

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (flavorHeader != null && flavorHeader!.isNotEmpty) 'X-Treasury-Flavor': flavorHeader!,
      };

  Future<String> openSession(String prompt) async {
    final response = await _client
        .post(
          Uri.parse('${_trim(baseUrl)}/eve/v1/session'),
          headers: _headers,
          body: jsonEncode({'input': prompt}),
        )
        .timeout(const Duration(seconds: 30));
    final json = jsonDecode(response.body);
    if (response.statusCode >= 400 || json is! Map || json['id'] == null) {
      throw StateError('Eve session was not opened.');
    }
    return json['id'].toString();
  }

  Future<List<EveEvent>> readStream(String id) async {
    final response = await _client
        .get(Uri.parse('${_trim(baseUrl)}/eve/v1/session/$id/stream'), headers: _headers)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) throw StateError('Eve stream failed.');
    return parseNdjson(response.body);
  }

  Future<void> answer(String id, String interactionId, String optionId) async {
    final response = await _client
        .post(
          Uri.parse('${_trim(baseUrl)}/eve/v1/session/$id'),
          headers: _headers,
          body: jsonEncode({
            'answers': [
              {'interactionId': interactionId, 'optionId': optionId},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) throw StateError('Eve did not accept the answer.');
  }
}

String _trim(String value) => value.endsWith('/') ? value.substring(0, value.length - 1) : value;
