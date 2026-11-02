import 'bootstrap.dart';
import 'core/app_env.dart';
import 'core/signer/walletconnect_signer.dart';
import 'flavors/celo/celo_flavor.dart';

Future<void> main() {
  final signer = WalletConnectSigner();
  return bootstrap(
    flavor: buildCeloFlavor(AppEnv.current, signer: signer),
    env: AppEnv.current,
    signer: signer,
  );
}
