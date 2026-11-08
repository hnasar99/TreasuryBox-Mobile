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
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TreasuryApp(controller: controller, showSplash: false));
    await tester.pump();
    expect(find.text('TreasuryBox · Celo'), findsOneWidget);
    expect(find.text('Pagar'), findsOneWidget);
    expect(find.text('Cobrar'), findsOneWidget);
    expect(find.byTooltip('Escanear'), findsOneWidget);
    await tester.tap(find.text('Caja'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar a un beneficiario'), findsOneWidget);
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    expect(find.text('Identidad del agente: Sin registrar en cadena'), findsWidgets);
    expect(find.text('ERC-8021 celo_202a37e338a2'), findsWidgets);
    expect(find.textContaining('TODO(verify)'), findsNothing);
  });
}
