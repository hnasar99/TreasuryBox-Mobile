import 'package:flutter_test/flutter_test.dart';
import 'package:treasurybox_mobile/core/amount.dart';
import 'package:treasurybox_mobile/core/evm/abi.dart';
import 'package:treasurybox_mobile/core/model.dart';
import 'package:treasurybox_mobile/core/signer.dart';
import 'package:treasurybox_mobile/flavors/celo/attribution.dart';
import 'package:treasurybox_mobile/flavors/celo/ecosystem.dart';
import 'package:treasurybox_mobile/flavors/celo/identity.dart';
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

  test('attribution encodes the published schema 0 vector', () {
    const vector = '0x63656c6f5f62376b33703964610d0080218021802180218021802180218021';
    expect(toDataSuffix('celo_b7k3p9da'), vector);
    expect(withAttribution('0xabcdef', ''), '0xabcdef');
    expect(withAttribution('0xabcdef', 'celo_b7k3p9da'), '0xabcdef${vector.substring(2)}');
    expect(() => withAttribution('0xabcdef', '0x1234'), throwsFormatException);
    expect(attributionReadyForLive('0x1234'), isFalse);
    expect(attributionReadyForLive('celo_b7k3p9da'), isTrue);
    expect(fromDataSuffix(vector)?.codes, ['celo_b7k3p9da']);
    expect(fromDataSuffix(vector)?.schemaId, 0);
    expect(attributionReadyForLive(CeloTokens.attribution), isTrue);
    expect(CeloTokens.attribution, 'celo_202a37e338a2');
    expect(fromDataSuffix(toDataSuffix(CeloTokens.attribution))?.codes, ['celo_202a37e338a2']);
  });

  test('an empty agent id stays on the local registration file', () async {
    final eco = RipioCeloEcosystem(
      homeCurrency: 'ARS',
      live: false,
      signer: UnavailableSigner(),
    );
    final identity = await eco.loadIdentity();
    expect(identity.onChain, isFalse);
    expect(identity.registration.containsKey('registrations'), isFalse);
  });

  test('an unpublished agent keeps the local registration file off-chain', () {
    final identity = CeloIdentity.unpublished();
    expect(identity.onChain, isFalse);
    expect(identity.agentId, isNull);
    expect(identity.registration['type'], 'https://eips.ethereum.org/EIPS/eip-8004#registration-v1');
    expect(identity.registration.containsKey('registrations'), isFalse);
    expect(
      (identity.registration['services'] as List).single,
      {'name': 'wallet', 'endpoint': 'eip155:42220'},
    );
  });

  test('dry-run transfer calldata carries a schema 0 suffix', () async {
    final eco = RipioCeloEcosystem(
      homeCurrency: 'ARS',
      live: false,
      signer: UnavailableSigner(),
      catalog: const CeloTokens(attributionCode: 'celo_b7k3p9da'),
    );
    final token = const CeloTokens().bySymbol('wARS');
    final steps = await eco.prepareTransfer(token, Amount.parse('1', 18), '0x${'11' * 20}');
    expect(steps.single.attributionCode, 'celo_b7k3p9da');
    expect(steps.single.attributionSchema, 0);
    expect(fromDataSuffix(steps.single.data)?.codes, ['celo_b7k3p9da']);
  });

  test('live transfer refuses a short hex that is not a schema 0 suffix', () async {
    final eco = RipioCeloEcosystem(
      homeCurrency: 'ARS',
      live: true,
      signer: UnavailableSigner(),
      catalog: const CeloTokens(attributionCode: '0x1234'),
    );
    final token = const CeloTokens().bySymbol('wARS');
    await expectLater(
      eco.prepareTransfer(token, Amount.parse('1', 18), '0x${'11' * 20}'),
      throwsA(isA<StateError>()),
    );
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
    expect(selector('tokenURI(uint256)'), '0xc87b56dd');
    expect(
      decodeAbiString(
        '0x'
        '0000000000000000000000000000000000000000000000000000000000000020'
        '0000000000000000000000000000000000000000000000000000000000000005'
        '68656c6c6f000000000000000000000000000000000000000000000000000000',
      ),
      'hello',
    );
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
