import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';

/// Estrutura com a navegação principal. No celular em pé, uma barra embaixo; em
/// tela larga (celular deitado, tablet, computador), um menu na lateral.
/// Os rótulos ficam sempre visíveis.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final newAlerts = context.select<AlertsProvider, int>((p) => p.unseenCount);

    if (context.isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _select,
                extended: context.isExpandedScreen,
                labelType: context.isExpandedScreen
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                destinations: [
                  for (final item in _items(newAlerts))
                    NavigationRailDestination(
                      icon: item.icon,
                      selectedIcon: item.selectedIcon,
                      label: Text(item.label),
                    ),
                ],
              ),
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
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final item in _items(newAlerts))
            NavigationDestination(
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: item.label,
              tooltip: item.tooltip,
            ),
        ],
      ),
    );
  }

  List<_NavItem> _items(int newAlerts) => [
        const _NavItem(
          label: 'Visão geral',
          tooltip: 'Visão geral e impacto',
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
        ),
        const _NavItem(
          label: 'Demanda',
          tooltip: 'Mapa de demanda por distrito',
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
        ),
        const _NavItem(
          label: 'Lixeiras',
          tooltip: 'Lixeiras inteligentes',
          icon: Icon(Icons.recycling_outlined),
          selectedIcon: Icon(Icons.recycling),
        ),
        _NavItem(
          label: 'Alertas',
          tooltip: newAlerts > 0 ? 'Alertas, $newAlerts não lidos' : 'Alertas',
          icon: Badge.count(
            count: newAlerts,
            isLabelVisible: newAlerts > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge.count(
            count: newAlerts,
            isLabelVisible: newAlerts > 0,
            child: const Icon(Icons.notifications),
          ),
        ),
      ];
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String tooltip;
  final Widget icon;
  final Widget selectedIcon;
}
