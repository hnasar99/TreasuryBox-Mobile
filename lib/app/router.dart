import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../ui/theme.dart';
import 'controller.dart';
import 'screens.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'tb-root');

GoRouter treasuryRouter(TreasuryController controller) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
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
      GoRoute(
        path: '/escanear',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => ScanPage(controller: controller),
      ),
    ],
  );
}

class TreasuryShell extends StatelessWidget {
  const TreasuryShell({super.key, required this.shell, required this.controller});

  final StatefulNavigationShell shell;
  final TreasuryController controller;

  void _goBranch(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  int _barIndex(int branch) => branch >= 2 ? branch + 1 : branch;

  Widget _scanMark(BrandPalette palette, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
        child: Icon(Icons.qr_code_scanner, color: palette.onAccent, size: 22),
      ),
    );
  }

  Widget _scanButton(BuildContext context, BrandPalette palette, String tooltip) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: () => context.push('/escanear'),
      style: IconButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        fixedSize: const Size(48, 48),
      ),
      icon: const Icon(Icons.qr_code_scanner),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = controller.flavor.palette;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _goBranch,
              labelType: NavigationRailLabelType.all,
              backgroundColor: palette.surface,
              leading: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: _scanButton(context, palette, l10n.scanAction),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: Text(l10n.navInicio),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(Icons.account_balance_wallet),
                  label: Text(l10n.navCaja),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.psychology_outlined),
                  selectedIcon: const Icon(Icons.psychology),
                  label: Text(l10n.navAgente),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.more_horiz_outlined),
                  selectedIcon: const Icon(Icons.more_horiz),
                  label: Text(l10n.navMas),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _barIndex(shell.currentIndex),
        onDestinationSelected: (index) {
          if (index == 2) {
            context.push('/escanear');
            return;
          }
          _goBranch(index > 2 ? index - 1 : index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navInicio,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.navCaja,
          ),
          NavigationDestination(
            icon: _scanMark(palette, l10n.scanAction),
            selectedIcon: _scanMark(palette, l10n.scanAction),
            label: '',
          ),
          NavigationDestination(
            icon: const Icon(Icons.psychology_outlined),
            selectedIcon: const Icon(Icons.psychology),
            label: l10n.navAgente,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_outlined),
            selectedIcon: const Icon(Icons.more_horiz),
            label: l10n.navMas,
          ),
        ],
      ),
    );
  }
}
