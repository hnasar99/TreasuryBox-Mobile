import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class TextileQuote {
  const TextileQuote({
    required this.buyAmount,
    required this.executable,
    this.swapTo,
    this.swapData,
    this.reactor,
    this.takerPays,
    this.expiresAt,
    this.rfqId,
  });

  final BigInt buyAmount;
  final bool executable;
  final String? swapTo;
  final String? swapData;
  final String? reactor;
  final BigInt? takerPays;
  final DateTime? expiresAt;
  final String? rfqId;
}

class TextileClient {
  TextileClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<TextileQuote> preview({
    required String sellToken,
    required String buyToken,
    required BigInt sellAmount,
    required String taker,
    required String signature,
    required String nonce,
    required int issuedAt,
  }) async {
    final json = await _post('/rfq/preview', {
      'chainId': 42220,
      'sellToken': sellToken,
      'buyToken': buyToken,
      'sellAmount': sellAmount.toString(),
      'taker': taker,
      'takerProof': {'nonce': nonce, 'issuedAt': issuedAt, 'signature': signature},
    });
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;
    final buy = data['buyAmount']?.toString();
    if (buy == null || buy.isEmpty) throw StateError('textile preview: missing buyAmount');
    return TextileQuote(buyAmount: BigInt.parse(buy), executable: false);
  }

  Future<TextileQuote> request({
    required String sellToken,
    required String buyToken,
    required BigInt sellAmount,
    required String taker,
    required String signature,
    required String nonce,
    required int issuedAt,
  }) async {
    final json = await _post('/rfq/request', {
      'chainId': 42220,
      'sellToken': sellToken,
      'buyToken': buyToken,
      'sellAmount': sellAmount.toString(),
      'taker': taker,
      'takerProof': {'nonce': nonce, 'issuedAt': issuedAt, 'signature': signature},
    });
    final data = json['data'];
    if (data is! Map) throw StateError('textile request: empty data');
    final quote = Map<String, dynamic>.from(data);
    final inner = quote['quote'] is Map ? Map<String, dynamic>.from(quote['quote'] as Map) : quote;
    final tx = quote['transactions'] is Map
        ? Map<String, dynamic>.from(quote['transactions'] as Map)['swap']
        : null;
    final swap = tx is Map ? Map<String, dynamic>.from(tx) : null;
    final buy = inner['buyAmount']?.toString();
    if (buy == null || swap == null || swap['to'] == null || swap['data'] == null) {
      throw StateError('textile request: incomplete quote');
    }
    final exp = int.tryParse(inner['expiresAt']?.toString() ?? '');
    return TextileQuote(
      buyAmount: BigInt.parse(buy),
      executable: true,
      swapTo: swap['to'].toString(),
      swapData: swap['data'].toString(),
      reactor: inner['reactor']?.toString(),
      takerPays: BigInt.tryParse(inner['takerPays']?.toString() ?? ''),
      expiresAt: exp == null ? null : DateTime.fromMillisecondsSinceEpoch(exp < 1000000000000 ? exp * 1000 : exp),
      rfqId: quote['rfqId']?.toString(),
    );
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await _client
        .post(
          Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 75));
    final decoded = jsonDecode(response.body);
    final json = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
    if (response.statusCode >= 400) {
      throw StateError('textile ${response.statusCode}: ${jsonEncode(json).substring(0, 180)}');
    }
    return json;
  }
}

String randomNonce() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return '0x${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}

String takerTypedData({
  required String taker,
  required String nonce,
  required int issuedAt,
}) {
  return jsonEncode({
    'types': {
      'EIP712Domain': [
        {'name': 'name', 'type': 'string'},
        {'name': 'version', 'type': 'string'},
        {'name': 'chainId', 'type': 'uint256'},
      ],
      'TakerControl': [
        {'name': 'taker', 'type': 'address'},
        {'name': 'chainId', 'type': 'uint256'},
        {'name': 'nonce', 'type': 'bytes32'},
        {'name': 'issuedAt', 'type': 'uint256'},
      ],
    },
    'primaryType': 'TakerControl',
    'domain': {'name': 'Textile Taker Control', 'version': '1', 'chainId': 42220},
    'message': {'taker': taker, 'chainId': 42220, 'nonce': nonce, 'issuedAt': issuedAt},
  });
}
