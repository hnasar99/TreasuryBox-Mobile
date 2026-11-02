import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/controller.dart';
import 'app/router.dart';
import 'core/app_env.dart';
import 'core/ledger.dart';
import 'core/secure_store.dart';
import 'core/signer.dart';
import 'flavors/flavor_config.dart';
import 'l10n/app_localizations.dart';
import 'ui/theme.dart';

Future<void> bootstrap({
  required FlavorConfig flavor,
  required AppEnv env,
  required TxSigner signer,
  KvStore? store,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TreasuryController(
    flavor: flavor,
    env: env,
    signer: signer,
    store: store ?? await _openStore(),
  );
  await controller.load();
  runApp(TreasuryApp(controller: controller));
}

Future<KvStore> _openStore() async {
  final secure = SecureKv();
  try {
    await secure.read('tb_treasury_day_v1');
    return secure;
  } catch (_) {
    return MemoryKv();
  }
}

class TreasuryApp extends StatefulWidget {
  const TreasuryApp({super.key, required this.controller, this.showSplash = true});

  final TreasuryController controller;
  final bool showSplash;

  @override
  State<TreasuryApp> createState() => _TreasuryAppState();
}

class _TreasuryAppState extends State<TreasuryApp> {
  late final GoRouter _router = treasuryRouter(widget.controller);

  @override
  Widget build(BuildContext context) {
    final flavor = widget.controller.flavor;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => MaterialApp.router(
        title: flavor.appName,
        theme: treasuryTheme(flavor.palette),
        routerConfig: _router,
        locale: widget.controller.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => _Splash(show: widget.showSplash, child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash({required this.show, required this.child});
  final bool show;
  final Widget child;

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  var _cover = true;

  @override
  void initState() {
    super.initState();
    if (!widget.show) {
      _cover = false;
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _cover = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_cover) return widget.child;
    return const ColoredBox(
      color: Color(0xFF071018),
      child: Center(child: Text('TreasuryBox', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
    );
  }
}
