import '../amount.dart';
import '../model.dart';
import 'json_rpc.dart';

Future<List<BalanceRow>> readTokenBalances({
  required EvmReadClient client,
  required String rpcUrl,
  required List<TokenRef> tokens,
  required String account,
}) async {
  final rows = <BalanceRow>[];
  var failures = 0;
  for (final token in tokens) {
    if (token.kind == TokenKind.gas) {
      try {
        final raw = await client.nativeBalance(rpcUrl: rpcUrl, account: account);
        rows.add(BalanceRow(token: token, amount: Amount(raw: raw, decimals: token.decimals)));
      } catch (_) {
        failures++;
      }
      continue;
    }
    try {
      final raw = await client.balanceOf(rpcUrl: rpcUrl, token: token.address, account: account);
      rows.add(BalanceRow(token: token, amount: Amount(raw: raw, decimals: token.decimals)));
    } catch (_) {
      failures++;
    }
  }
  if (tokens.isNotEmpty && failures == tokens.length) {
    throw StateError('No se pudo leer la red.');
  }
  return rows;
}
