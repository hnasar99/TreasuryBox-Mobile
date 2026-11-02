import 'package:flutter_test/flutter_test.dart';
import 'package:treasurybox_mobile/core/amount.dart';
import 'package:treasurybox_mobile/core/evm/abi.dart';
import 'package:treasurybox_mobile/core/model.dart';
import 'package:treasurybox_mobile/flavors/celo/attribution.dart';
import 'package:treasurybox_mobile/flavors/celo/tokens.dart';
import 'package:treasurybox_mobile/flavors/twin/tokens.dart';
import 'package:treasurybox_mobile/flavors/twin/zonabank_api.dart';

void main() {
  test('local to local routes through the hub and pen/clp stay quoted as blocked', () {
    final book = CeloTokens().all();
    final wars = book.firstWhere((token) => token.symbol == 'wARS');
    final wbrl = book.firstWhere((token) => token.symbol == 'wBRL');
    final usdt = book.firstWhere((token) => token.symbol == 'USDT');
    expect(routesViaHub(wars, wbrl, 'USDT'), isTrue);
    expect(routesViaHub(wars, usdt, 'USDT'), isFalse);
    expect(wars.decimals, 18);
    expect(usdt.decimals, 6);
  });

  test('attribution appends only an encoded suffix', () {
    expect(withAttribution('0xabcdef', ''), '0xabcdef');
    expect(withAttribution('0xabcdef', '0x1234'), '0xabcdef1234');
    expect(() => withAttribution('0xabcdef', 'celo_code'), throwsFormatException);
    expect(attributionReadyForLive('celo_code'), isFalse);
    expect(attributionReadyForLive('0x1234'), isTrue);
  });

  test('vault and transfer calldata use the canonical selectors', () {
    final deposit = encodeErc4626Deposit(BigInt.one, '0x${'ab' * 20}');
    final redeem = encodeErc4626Redeem(BigInt.two, '0x${'cd' * 20}', '0x${'ef' * 20}');
    final transfer = encodeTransfer('0x${'11' * 20}', BigInt.parse('1000'));
    expect(deposit.startsWith(selector('deposit(uint256,address)')), isTrue);
    expect(redeem.startsWith(selector('redeem(uint256,address,address)')), isTrue);
    expect(transfer.startsWith(selector('transfer(address,uint256)')), isTrue);
    expect(deposit.length, 2 + 8 + 64 * 2);
    expect(selector('deposit(uint256,address)'), '0x6e553f65');
    expect(selector('redeem(uint256,address,address)'), '0xba087652');
    expect(selector('transfer(address,uint256)'), '0xa9059cbb');
  });

  test('a prepared remote step keeps chain and does not invent a signature', () {
    final api = ZonaBankApi(chains: const [arbChain, arcTestnetChain]);
    final parsed = api.parsePrepared({
      'prepared': {
        'chainId': 42161,
        'warnings': ['review'],
        'steps': [
          {'kind': 'transfer', 'to': '0x${'aa' * 20}', 'data': '0x1234', 'value': '0x0'},
        ],
      },
    });
    expect(parsed.steps.single.chain.caip2, arbChain.caip2);
    expect(parsed.steps.single.chain.testnet, isFalse);
    expect(parsed.steps.single.data, '0x1234');
  });

  test('the two box networks are different books', () {
    final testnet = TwinTokens().all().where((token) => token.chain.testnet);
    final mainnet = TwinTokens(mainnetBox: true).all().where((token) => token.symbol == 'USDC' && !token.chain.testnet && token.chain.reference == '5042');
    expect(testnet.map((token) => token.chain.caip2), contains(arcTestnetChain.caip2));
    expect(mainnet, isNotEmpty);
    final mixed = [
      BalanceRow(token: TwinTokens().bySymbol('ARGt'), amount: Amount.parse('1', 18)),
      BalanceRow(token: TwinTokens().bySymbol('USDC', chain: arcTestnetChain), amount: Amount.parse('1', 6)),
    ];
    expect(sumSameBook(mixed), isNull);
  });
}
