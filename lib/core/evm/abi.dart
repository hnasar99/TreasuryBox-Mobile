import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/keccak.dart';

Uint8List keccak256(List<int> bytes) => KeccakDigest(256).process(Uint8List.fromList(bytes));

String selector(String signature) {
  final digest = keccak256(utf8.encode(signature));
  return '0x${_hex(digest.sublist(0, 4))}';
}

String padUint(BigInt value) {
  if (value.isNegative || value.bitLength > 256) {
    throw ArgumentError('uint256 out of range');
  }
  return value.toRadixString(16).padLeft(64, '0');
}

String padAddress(String address) {
  final body = _addressBody(address);
  return body.padLeft(64, '0');
}

String validateAddress(String input) {
  final address = input.trim();
  if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address)) {
    throw const FormatException('Use a complete 0x address (40 hex digits).');
  }
  final body = address.substring(2);
  if (body != body.toLowerCase() && body != body.toUpperCase()) {
    final digest = keccak256(utf8.encode(body.toLowerCase()));
    final checksum = _hex(digest);
    for (var i = 0; i < body.length; i++) {
      final letter = body[i];
      if (RegExp(r'[a-fA-F]').hasMatch(letter)) {
        final expected = int.parse(checksum[i], radix: 16) >= 8
            ? letter.toUpperCase()
            : letter.toLowerCase();
        if (letter != expected) {
          throw const FormatException('The mixed-case address has an invalid checksum.');
        }
      }
    }
  }
  return address;
}

bool isZeroAddress(String address) =>
    BigInt.parse(_addressBody(address), radix: 16) == BigInt.zero;

String encodeCall(String signature, List<String> words) =>
    selector(signature) + words.join();

String encodeTransfer(String recipient, BigInt units) {
  final address = validateAddress(recipient);
  if (isZeroAddress(address)) {
    throw const FormatException('The zero address cannot receive this transfer.');
  }
  return encodeCall('transfer(address,uint256)', [padAddress(address), padUint(units)]);
}

String encodeApprove(String spender, BigInt units) =>
    encodeCall('approve(address,uint256)', [padAddress(validateAddress(spender)), padUint(units)]);

String encodeBalanceOf(String account) =>
    encodeCall('balanceOf(address)', [padAddress(validateAddress(account))]);

String encodeErc4626Deposit(BigInt assets, String receiver) => encodeCall(
      'deposit(uint256,address)',
      [padUint(assets), padAddress(validateAddress(receiver))],
    );

String encodeErc4626Redeem(BigInt shares, String receiver, String owner) => encodeCall(
      'redeem(uint256,address,address)',
      [
        padUint(shares),
        padAddress(validateAddress(receiver)),
        padAddress(validateAddress(owner)),
      ],
    );

String encodeConvertToAssets(BigInt shares) =>
    encodeCall('convertToAssets(uint256)', [padUint(shares)]);

String encodeTokenUri(BigInt tokenId) => encodeCall('tokenURI(uint256)', [padUint(tokenId)]);

String encodeOwnerOf(BigInt tokenId) => encodeCall('ownerOf(uint256)', [padUint(tokenId)]);

String decodeAbiString(String hexWord) {
  final body = (hexWord.startsWith('0x') ? hexWord.substring(2) : hexWord).toLowerCase();
  if (body.length < 128) {
    throw const FormatException('The node returned an unreadable string.');
  }
  final offset = int.parse(body.substring(0, 64), radix: 16);
  final start = offset * 2;
  if (start < 0 || start + 64 > body.length) {
    throw const FormatException('The node returned an unreadable string.');
  }
  final length = int.parse(body.substring(start, start + 64), radix: 16);
  final dataStart = start + 64;
  final dataEnd = dataStart + length * 2;
  if (dataEnd > body.length) {
    throw const FormatException('The node returned an unreadable string.');
  }
  final bytes = <int>[];
  for (var i = dataStart; i < dataEnd; i += 2) {
    bytes.add(int.parse(body.substring(i, i + 2), radix: 16));
  }
  return utf8.decode(bytes);
}

BigInt decodeUint(String hexWord) {
  final body = hexWord.startsWith('0x') ? hexWord.substring(2) : hexWord;
  if (body.isEmpty) return BigInt.zero;
  return BigInt.parse(body, radix: 16);
}

String decodeAddressWord(String hexWord) {
  final body = (hexWord.startsWith('0x') ? hexWord.substring(2) : hexWord).padLeft(64, '0');
  return '0x${body.substring(body.length - 40)}';
}

String _addressBody(String address) => validateAddress(address).substring(2).toLowerCase();

String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
