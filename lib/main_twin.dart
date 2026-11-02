import 'bootstrap.dart';
import 'core/app_env.dart';
import 'core/signer/walletconnect_signer.dart';
import 'flavors/twin/twin_flavor.dart';

Future<void> main() {
  final signer = WalletConnectSigner();
  return bootstrap(
    flavor: buildTwinFlavor(AppEnv.current, signer: signer),
    env: AppEnv.current,
    signer: signer,
  );
}
