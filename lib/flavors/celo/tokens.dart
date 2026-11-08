import '../../core/model.dart';

const celoChain = ChainRef(
  namespace: 'eip155',
  reference: '42220',
  testnet: false,
  label: '42220',
);

const celoForbiddenCoreTerms = {
  'celo',
  'ripio',
  'textile',
  'x402',
  'wARS',
  'wBRL',
  'wMXN',
  'wCOP',
  'wPEN',
  'wCLP',
  'USDT',
  'USAT',
};

class CeloTokens {
  static const wars = String.fromEnvironment(
    'RAIL_WARS_ADDRESS',
    defaultValue: '0x0dc4f92879b7670e5f4e4e6e3c801d229129d90d',
  );
  static const wbrl = String.fromEnvironment(
    'RAIL_WBRL_ADDRESS',
    defaultValue: '0xd76f5faf6888e24d9f04bf92a0c8b921fe4390e0',
  );
  static const wmxn = String.fromEnvironment(
    'RAIL_WMXN_ADDRESS',
    defaultValue: '0x337e7456b420bd3481e7fa61fa9850343d610d34',
  );
  static const wcop = String.fromEnvironment(
    'RAIL_WCOP_ADDRESS',
    defaultValue: '0x8a1d45e102e886510e891d2ec656a708991e2d76',
  );
  static const wpen = String.fromEnvironment(
    'RAIL_WPEN_ADDRESS',
    defaultValue: '0x4F34c8b3b5FB6D98Da888F0feA543d4d9C9F2eBE',
  );
  static const wclp = String.fromEnvironment(
    'RAIL_WCLP_ADDRESS',
    defaultValue: '0x61D450a098b6a7f69fC4b98CE68198fe59768651',
  );
  static const usdt = String.fromEnvironment(
    'RAIL_USDT_ADDRESS',
    defaultValue: '0x48065fbBE25f71C9282ddf5e1cD6D6A887483D5e',
  );

  /// TODO(verify): not in the Eve lab token list. Taken from the 2/11 plan's
  /// Celo docs note until checked against the chain.
  static const usdc = String.fromEnvironment(
    'RAIL_USDC_ADDRESS',
    defaultValue: '0xcebA9300f2b948710d2653dD7B07f33A8B32118C',
  );

  /// TODO(verify): same as USDC above.
  static const usat = String.fromEnvironment(
    'RAIL_USAT_ADDRESS',
    defaultValue: '0xD2ab3C9A02DBBAB236BfEC45D1d755DF4267F771',
  );

  static const reactor = String.fromEnvironment(
    'RAIL_TEXTILE_LIMIT_ORDER_REACTOR_ADDRESS',
    defaultValue: '0xa9AA0a64769cBed4d3B1Ceb4Df01CdE915C235b3',
  );

  static const rpc = String.fromEnvironment(
    'CELO_RPC_URL',
    defaultValue: 'https://forno.celo.org',
  );
  static const textileApi = String.fromEnvironment(
    'TEXTILE_API_URL',
    defaultValue: 'https://api.textilecredit.com/v2',
  );
  static const facilitator = String.fromEnvironment(
    'X402_FACILITATOR_URL',
    defaultValue: 'https://api.x402.celo.org',
  );
  static const rampBase = String.fromEnvironment(
    'RIPIO_RAMP_BASE',
    defaultValue: 'https://ramp.ripio.com',
  );
  static const attribution = String.fromEnvironment(
    'CELO_ATTRIBUTION_CODE',
    defaultValue: 'celo_202a37e338a2',
  );
  static const agentId = String.fromEnvironment('CELO_AGENT_ID');
  static const identityRegistry = String.fromEnvironment(
    'CELO_IDENTITY_REGISTRY',
    defaultValue: '0x8004A169FB4a3325136EB29fA0ceB6D2e539a432',
  );

  const CeloTokens({this.attributionCode = attribution, this.agentTokenId = agentId});

  final String attributionCode;
  final String agentTokenId;

  List<TokenRef> all() => [
        _local('wARS', wars, 'ARS'),
        _local('wBRL', wbrl, 'BRL'),
        _local('wMXN', wmxn, 'MXN'),
        _local('wCOP', wcop, 'COP'),
        _local('wPEN', wpen, 'PEN'),
        _local('wCLP', wclp, 'CLP'),
        _usd('USDT', usdt, 6),
        _usd('USDC', usdc, 6),
        _usd('USAT', usat, 6),
      ];

  TokenRef byFiat(String fiat) {
    for (final token in all()) {
      if (token.fiat == fiat && token.kind == TokenKind.localStable) return token;
    }
    return bySymbol('wARS');
  }

  TokenRef bySymbol(String symbol) => all().firstWhere((token) => token.symbol == symbol);

  TokenRef _local(String symbol, String address, String fiat) => TokenRef(
        symbol: symbol,
        address: address,
        decimals: 18,
        fiat: fiat,
        kind: TokenKind.localStable,
        chain: celoChain,
      );

  TokenRef _usd(String symbol, String address, int decimals) => TokenRef(
        symbol: symbol,
        address: address,
        decimals: decimals,
        kind: TokenKind.usdStable,
        chain: celoChain,
      );
}

bool routesViaHub(TokenRef from, TokenRef to, String hubSymbol) {
  if (from.symbol == to.symbol) return false;
  if (from.symbol == hubSymbol || to.symbol == hubSymbol) return false;
  return from.kind == TokenKind.localStable && to.kind == TokenKind.localStable;
}
