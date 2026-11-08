import '../../core/app_env.dart';
import '../../core/signer.dart';
import '../flavor_config.dart';
import 'ecosystem.dart';
import 'palette.dart';
import 'tokens.dart';

FlavorConfig buildCeloFlavor(AppEnv env, {TxSigner? signer}) {
  final wallet = signer ?? UnavailableSigner();
  final catalog = CeloTokens();
  return FlavorConfig(
    id: 'celo',
    appName: 'TreasuryBox · Celo',
    palette: celoPalette,
    homeCurrency: env.homeCurrency,
    homeSymbol: catalog.byFiat(env.homeCurrency).symbol,
    usdSymbol: 'USDT',
    ecosystems: [
      RipioCeloEcosystem(homeCurrency: env.homeCurrency, live: env.live, signer: wallet, catalog: catalog),
    ],
    features: const {Feature.fxSwap, Feature.x402Collect, Feature.ripioRamp, Feature.agentEve},
    live: env.live,
    forbiddenCoreTerms: celoForbiddenCoreTerms,
    walletChains: [celoChain.caip2],
    flavorHeader: 'ripio',
    attributionCode: catalog.attributionCode,
  );
}
