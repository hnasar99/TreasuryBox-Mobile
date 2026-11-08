import 'dart:convert';

import 'package:http/http.dart' as http;

import 'abi.dart';

class EvmReadClient {
  EvmReadClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Object?> rpc(String rpcUrl, String method, List<Object?> params) async {
    final response = await _client
        .post(
          Uri.parse(rpcUrl),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('The node returned an unreadable response.');
    }
    if (decoded['error'] != null) {
      throw StateError(decoded['error'].toString());
    }
    return decoded['result'];
  }

  Future<String> call(String rpcUrl, String method, List<Object?> params) async {
    final result = await rpc(rpcUrl, method, params);
    if (result is! String) {
      throw const FormatException('The node returned an unexpected result.');
    }
    return result;
  }

  Future<BigInt> balanceOf({
    required String rpcUrl,
    required String token,
    required String account,
  }) async {
    final result = await call(rpcUrl, 'eth_call', [
      {'to': validateAddress(token), 'data': encodeBalanceOf(account)},
      'latest',
    ]);
    return decodeUint(result);
  }

  Future<BigInt> nativeBalance({required String rpcUrl, required String account}) async {
    final result = await call(rpcUrl, 'eth_getBalance', [validateAddress(account), 'latest']);
    return decodeUint(result);
  }

  Future<BigInt> readUint({
    required String rpcUrl,
    required String to,
    required String data,
  }) async {
    final result = await call(rpcUrl, 'eth_call', [
      {'to': validateAddress(to), 'data': data},
      'latest',
    ]);
    return decodeUint(result);
  }

  Future<String> readString({
    required String rpcUrl,
    required String to,
    required String data,
  }) async {
    final result = await call(rpcUrl, 'eth_call', [
      {'to': validateAddress(to), 'data': data},
      'latest',
    ]);
    return decodeAbiString(result);
  }

  Future<DateTime> latestBlockTime(String rpcUrl) async {
    final result = await rpc(rpcUrl, 'eth_getBlockByNumber', ['latest', false]);
    if (result is! Map || result['timestamp'] is! String) {
      throw const FormatException('The node returned a block without a timestamp.');
    }
    final seconds = decodeUint(result['timestamp'] as String);
    return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000, isUtc: true);
  }
}
