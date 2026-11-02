import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:treasurybox_mobile/app/controller.dart';
import 'package:treasurybox_mobile/bootstrap.dart';
import 'package:treasurybox_mobile/core/app_env.dart';
import 'package:treasurybox_mobile/core/ledger.dart';
import 'package:treasurybox_mobile/core/signer.dart';
import 'package:treasurybox_mobile/flavors/celo/celo_flavor.dart';

void main() {
  testWidgets('celo shell opens on the home tab', (tester) async {
    final signer = UnavailableSigner();
    final controller = TreasuryController(
      flavor: buildCeloFlavor(AppEnv.current, signer: signer),
      env: AppEnv.current,
      signer: signer,
      store: MemoryKv(),
    )..locale = const Locale('es');
    await tester.pumpWidget(TreasuryApp(controller: controller, showSplash: false));
    await tester.pump();
    expect(find.text('TreasuryBox · Celo'), findsOneWidget);
    expect(find.text('Caja'), findsOneWidget);
  });
}
