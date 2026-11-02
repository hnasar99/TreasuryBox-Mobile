import '../../core/model.dart';

/// Addresses copied from `docs/zonabank/twin-arbitrum.md`, not from memory.
const arbChain = ChainRef(
  namespace: 'eip155',
  reference: '42161',
  testnet: false,
  label: '42161',
);

const arcTestnetChain = ChainRef(
  namespace: 'eip155',
  reference: '5042002',
  testnet: true,
  label: '5042002',
);

const arcMainnetChain = ChainRef(
  namespace: 'eip155',
  reference: '5042',
  testnet: false,
  label: '5042',
);

const twinForbiddenCoreTerms = {
  'twin',
  'arc',
  'arbitrum',
  'cctp',
  'zonabank',
  'ARGt',
  'BRAt',
  'MEXt',
  'USD₮0',
};

class TwinTokens {
  const TwinTokens({this.mainnetBox = false});

  final bool mainnetBox;

  static const argt = String.fromEnvironment(
    'TWIN_ARGT_ADDRESS',
    defaultValue: '0x59863989d080B22476DB95656d0C3CC18be92214',
  );
  static const brat = String.fromEnvironment(
    'TWIN_BRAT_ADDRESS',
    defaultValue: '0xC4ed6Aba5373D78E160F4df39e011F078Be54df8',
  );
  static const bolt = String.fromEnvironment(
    'TWIN_BOLT_ADDRESS',
    defaultValue: '0x1edF5E61B6a4Fe19FEf3A695328F61aAa07728eA',
  );
  static const chlt = String.fromEnvironment(
    'TWIN_CHLT_ADDRESS',
    defaultValue: '0xe8dbC4680235cCAeFf48e4C0B0EaceeBb89E5e17',
  );
  static const colt = String.fromEnvironment(
    'TWIN_COLT_ADDRESS',
    defaultValue: '0xa16d5DB80A45157E0e451750B81FF0CC0b61d558',
  );
  static const mext = String.fromEnvironment(
    'TWIN_MEXT_ADDRESS',
    defaultValue: '0xb96aA6babCcD738d6644ADd4912fE5eFbEBF5a25',
  );
  static const pert = String.fromEnvironment(
    'TWIN_PERT_ADDRESS',
    defaultValue: '0x899438713f62B04d6CD8e8709986F7256fB6E3d9',
  );
  static const usdcArb = String.fromEnvironment(
    'TWIN_USDC_ARB_ADDRESS',
    defaultValue: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
  );
  static const usdcBox = String.fromEnvironment(
    'TWIN_USDC_BOX_ADDRESS',
    defaultValue: '0x3600000000000000000000000000000000000000',
  );
  static const vault = String.fromEnvironment(
    'RAIL_ARGT_PRIME_VAULT_ADDRESS',
    defaultValue: '0x9Dd3F844747AB78d616BF76DB92756E17A064aDD',
  );

  /// Pool noted in the 2/11 plan. Not present in the Eve lab source.
  static const curvePool = String.fromEnvironment(
    'TWIN_CURVE_POOL',
    defaultValue: '0x356d349da9add7efb56a35fab939a2c6d852f853',
  );

  static const arbRpc = String.fromEnvironment(
    'ARBITRUM_RPC_URL',
    defaultValue: 'https://arb1.arbitrum.io/rpc',
  );
  static const network = String.fromEnvironment('ARC_NETWORK', defaultValue: 'testnet');
  static const configuredBoxRpc = String.fromEnvironment('ARC_RPC_URL');

  ChainRef get boxChain => mainnetBox || network == 'mainnet' ? arcMainnetChain : arcTestnetChain;

  String get boxRpc {
    if (configuredBoxRpc.isNotEmpty) return configuredBoxRpc;
    return boxChain.testnet ? 'https://rpc.testnet.arc.io' : 'https://rpc.mainnet.arc.io';
  }

  String rpcFor(ChainRef chain) => chain.caip2 == arbChain.caip2 ? arbRpc : boxRpc;

  List<TokenRef> all() => [
        _local('ARGt', argt, 'ARS'),
        _local('BRAt', brat, 'BRL'),
        _local('BOLt', bolt, 'BOB'),
        _local('CHLt', chlt, 'CLP'),
        _local('COLt', colt, 'COP'),
        _local('MEXt', mext, 'MXN'),
        _local('PERt', pert, 'PEN'),
        TokenRef(
          symbol: 'USDC',
          address: usdcArb,
          decimals: 6,
          kind: TokenKind.usdStable,
          chain: arbChain,
        ),
        TokenRef(
          symbol: 'USDC',
          address: usdcBox,
          decimals: 6,
          kind: TokenKind.usdStable,
          chain: boxChain,
        ),
        TokenRef(
          symbol: 'GAS',
          address: '0x0000000000000000000000000000000000000000',
          decimals: 18,
          kind: TokenKind.gas,
          chain: arbChain,
        ),
      ];

  TokenRef bySymbol(String symbol, {ChainRef? chain}) {
    return all().firstWhere(
      (token) => token.symbol == symbol && (chain == null || token.chain.caip2 == chain.caip2),
    );
  }

  TokenRef _local(String symbol, String address, String fiat) => TokenRef(
        symbol: symbol,
        address: address,
        decimals: 18,
        fiat: fiat,
        kind: TokenKind.localStable,
        chain: arbChain,
      );
}
