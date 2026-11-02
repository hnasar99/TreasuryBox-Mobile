import '../../core/app_env.dart';
import '../../core/signer.dart';
import '../flavor_config.dart';
import 'ecosystem.dart';
import 'palette.dart';
import 'tokens.dart';

FlavorConfig buildTwinFlavor(AppEnv env, {TxSigner? signer}) {
  final wallet = signer ?? UnavailableSigner();
  final book = TwinTokens(mainnetBox: TwinTokens.network == 'mainnet');
  return FlavorConfig(
    id: 'twin',
    appName: 'TreasuryBox · Twin × Arc',
    palette: twinPalette,
    homeCurrency: env.homeCurrency,
    homeSymbol: 'ARGt',
    usdSymbol: 'USDC',
    ecosystems: [
      TwinArcEcosystem(
        homeCurrency: env.homeCurrency,
        live: env.live,
        fxEnabled: false,
        signer: wallet,
        book: book,
      ),
    ],
    features: const {
      Feature.twinTransfer,
      Feature.arcUsdc,
      Feature.cctp,
      Feature.twinVault,
      Feature.yieldVenues,
      Feature.agentEve,
    },
    live: env.live,
    forbiddenCoreTerms: twinForbiddenCoreTerms,
    walletChains: [arbChain.caip2, book.boxChain.caip2],
    flavorHeader: 'twin',
  );
}
