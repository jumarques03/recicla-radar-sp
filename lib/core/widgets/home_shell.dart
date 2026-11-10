import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/state/alerts_provider.dart';

/// Estrutura com a barra inferior. Os rótulos ficam sempre visíveis.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final newAlerts = context.select<AlertsProvider, int>((p) => p.unseenCount);

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Visão geral',
            tooltip: 'Visão geral e impacto',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Demanda',
            tooltip: 'Mapa de demanda por distrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.recycling_outlined),
            selectedIcon: Icon(Icons.recycling),
            label: 'Lixeiras',
            tooltip: 'Lixeiras inteligentes',
          ),
          NavigationDestination(
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
            label: 'Alertas',
            tooltip: newAlerts > 0 ? 'Alertas, $newAlerts novos' : 'Alertas',
          ),
        ],
      ),
    );
  }
}
