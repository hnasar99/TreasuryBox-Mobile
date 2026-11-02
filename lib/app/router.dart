import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'controller.dart';
import 'screens.dart';

GoRouter treasuryRouter(TreasuryController controller) {
  return GoRouter(
    initialLocation: '/inicio',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TreasuryShell(shell: shell, controller: controller),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/inicio', builder: (_, _) => HomePage(controller: controller)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/caja',
              builder: (_, _) => CajaPage(controller: controller),
              routes: [
                GoRoute(path: 'rotar', builder: (_, _) => RotatePage(controller: controller)),
                GoRoute(path: 'pagar', builder: (_, _) => PayPage(controller: controller)),
                GoRoute(path: 'cobrar', builder: (_, _) => CollectPage(controller: controller)),
                GoRoute(path: 'depositar', builder: (_, _) => DepositPage(controller: controller)),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/agente', builder: (_, _) => AgentPage(controller: controller)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/mas', builder: (_, _) => MorePage(controller: controller)),
          ]),
        ],
      ),
      GoRoute(path: '/escanear', builder: (_, _) => ScanPage(controller: controller)),
    ],
  );
}

class TreasuryShell extends StatelessWidget {
  const TreasuryShell({super.key, required this.shell, required this.controller});

  final StatefulNavigationShell shell;
  final TreasuryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = controller.flavor.palette;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: l10n.navInicio),
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), label: l10n.navCaja),
          NavigationDestination(icon: const Icon(Icons.psychology_outlined), label: l10n.navAgente),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: l10n.navMas),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        onPressed: () => context.push('/escanear'),
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
