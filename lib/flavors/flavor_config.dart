import '../core/app_env.dart';
import '../core/model.dart';
import '../ui/theme.dart';

enum Feature {
  fxSwap,
  x402Collect,
  ripioRamp,
  cctp,
  arcUsdc,
  twinTransfer,
  twinVault,
  yieldVenues,
  bridgeOft,
  agentEve,
}

class FlavorConfig {
  const FlavorConfig({
    required this.id,
    required this.appName,
    required this.palette,
    required this.homeCurrency,
    required this.homeSymbol,
    required this.usdSymbol,
    required this.ecosystems,
    required this.features,
    required this.live,
    required this.forbiddenCoreTerms,
    required this.walletChains,
    required this.flavorHeader,
  });

  final String id;
  final String appName;
  final BrandPalette palette;
  final String homeCurrency;
  final String homeSymbol;
  final String usdSymbol;
  final List<TreasuryEcosystem> ecosystems;
  final Set<Feature> features;
  final bool live;
  final Set<String> forbiddenCoreTerms;
  final List<String> walletChains;
  final String flavorHeader;

  TreasuryEcosystem get ecosystem => ecosystems.first;
}

typedef FlavorBuilder = FlavorConfig Function(AppEnv env);
