import 'package:flutter/material.dart';

import 'app/controller.dart';
import 'bootstrap.dart';
import 'core/app_env.dart';
import 'core/ledger.dart';
import 'core/signer/web_preview_signer.dart';
import 'flavors/celo/celo_flavor.dart';

/// Browser preview of the real Celo application, without native wallet imports.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const env = AppEnv.current;
  // Fail closed even if a deployment accidentally supplies live build flags.
  if (env.live) {
    throw StateError('The web preview requires TREASURY_MODE=dry-run.');
  }
  final signer = WebPreviewSigner();
  final controller = TreasuryController(
    flavor: buildCeloFlavor(env, signer: signer),
    env: env,
    signer: signer,
    // Preview state is intentionally ephemeral; no company secrets are stored.
    store: MemoryKv(),
  );
  await controller.load();
  runApp(Directionality(
    textDirection: TextDirection.ltr,
    child: Banner(
      message: 'WEB DEMO',
      location: BannerLocation.topEnd,
      child: TreasuryApp(controller: controller),
    ),
  ));
}
