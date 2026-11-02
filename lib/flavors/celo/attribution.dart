/// Appends an already-encoded hex suffix.
///
/// TODO(verify): the lab encodes this with `@celo/attribution-tags`. A short
/// code such as `celo_…` is not a suffix. Live sends refuse until the value
/// is hex that was produced by that package.
String withAttribution(String data, String suffixHex) {
  if (suffixHex.isEmpty) return data;
  if (!RegExp(r'^0x[0-9a-fA-F]+$').hasMatch(suffixHex)) {
    throw const FormatException('attribution-unverified');
  }
  final body = data.startsWith('0x') ? data.substring(2) : data;
  return '0x$body${suffixHex.substring(2)}';
}

bool attributionReadyForLive(String code) => RegExp(r'^0x[0-9a-fA-F]+$').hasMatch(code);
