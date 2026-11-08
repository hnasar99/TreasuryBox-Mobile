import 'dart:convert';

/// Schema 0 marker from ERC-8021 / `@celo/attribution-tags`.
const erc8021Marker = '80218021802180218021802180218021';

class DecodedSuffix {
  const DecodedSuffix({required this.codes, required this.schemaId});

  final List<String> codes;
  final int schemaId;
}

/// Encodes one Schema 0 suffix: code ASCII, length, schema 0x00, marker.
String toDataSuffix(String code) {
  if (!_validCode(code)) {
    throw const FormatException('attribution-unverified');
  }
  final bytes = utf8.encode(code);
  return '0x${_hex(bytes)}${_hexByte(bytes.length)}00$erc8021Marker';
}

/// Appends a Schema 0 suffix for [code]. Empty code leaves calldata unchanged.
String withAttribution(String data, String code) {
  if (code.isEmpty) return data;
  if (fromDataSuffix(data) != null) return data;
  final body = _hexBody(data);
  return '0x$body${toDataSuffix(code).substring(2)}';
}

bool attributionReadyForLive(String code) => _validCode(code);

DecodedSuffix? fromDataSuffix(String data) {
  final body = _hexBody(data);
  const markerHexLen = 32;
  const schemaHexLen = 2;
  const lengthHexLen = 2;
  const tail = markerHexLen + schemaHexLen + lengthHexLen;
  if (body.length < tail) return null;
  if (body.substring(body.length - markerHexLen).toLowerCase() != erc8021Marker) {
    return null;
  }
  final schemaStart = body.length - markerHexLen - schemaHexLen;
  final schemaId = int.parse(body.substring(schemaStart, schemaStart + schemaHexLen), radix: 16);
  if (schemaId != 0) return null;
  final lengthStart = schemaStart - lengthHexLen;
  final codeLength = int.parse(body.substring(lengthStart, schemaStart), radix: 16);
  final codeStart = lengthStart - codeLength * 2;
  if (codeStart < 0 || codeLength == 0) return null;
  final codes = utf8.decode(_bytes(body.substring(codeStart, lengthStart)));
  if (codes.isEmpty) return null;
  return DecodedSuffix(codes: codes.split(','), schemaId: schemaId);
}

bool _validCode(String code) {
  if (RegExp(r'^0x[0-9a-fA-F]+$').hasMatch(code)) return false;
  return RegExp(r'^[a-z0-9_]{1,32}$').hasMatch(code);
}

String _hexBody(String data) {
  final body = data.startsWith('0x') || data.startsWith('0X') ? data.substring(2) : data;
  if (body.length.isOdd) {
    throw const FormatException('attribution-unverified');
  }
  return body;
}

String _hex(List<int> bytes) => bytes.map(_hexByte).join();

String _hexByte(int value) => value.toRadixString(16).padLeft(2, '0');

List<int> _bytes(String hex) {
  final out = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    out.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return out;
}
