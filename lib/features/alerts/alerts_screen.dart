import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/settings_action.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/features/alerts/alert_card.dart';
import 'package:recicla_radar_sp/features/alerts/alert_filters.dart';
import 'package:recicla_radar_sp/features/alerts/human_decision_banner.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Filtros são estado local: só valem enquanto esta tela está aberta.
  AlertFilters _filters = const AlertFilters();

  Future<void> _markAllSeen(AlertsProvider alerts) async {
    final messenger = ScaffoldMessenger.of(context);
    final marked = await alerts.markAllSeen();
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(marked.length == 1
            ? '1 alerta marcado como visto.'
            : '${marked.length} alertas marcados como vistos.'),
        action: SnackBarAction(label: 'Desfazer', onPressed: () => alerts.markUnseen(marked)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        actions: [
          IconButton(
            tooltip: alerts.unseenCount > 0
                ? 'Marcar os ${alerts.unseenCount} alertas novos como vistos'
                : 'Nenhum alerta novo',
            icon: const Icon(Icons.done_all),
            onPressed: alerts.unseenCount > 0 ? () => _markAllSeen(alerts) : null,
          ),
          const SettingsAction(),
        ],
      ),
      body: Column(
        children: [
          const HumanDecisionBanner(),
          AlertFilterPanel(
            filters: _filters,
            onChanged: (filters) => setState(() => _filters = filters),
          ),
          Expanded(
            child: LoadableView<List<Alert>>(
              notifier: alerts,
              isEmpty: (list) => list.isEmpty,
              emptyTitle: 'Nenhum alerta por enquanto',
              emptyMessage: 'Quando o sistema perceber algo, o aviso aparece aqui.',
              builder: (context, list) {
                final visible = list.where((a) => _filters.matches(a, isSeen: alerts.isSeen)).toList();
                if (visible.isEmpty) {
                  return EmptyView(
                    title: 'Nenhum alerta com esses filtros',
                    message: 'Mude ou limpe os filtros para ver mais alertas.',
                    icon: Icons.filter_alt_off_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: alerts.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: visible.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm + 4),
                    itemBuilder: (context, index) => AlertCard(
                      alert: visible[index],
                      isNew: visible[index].status.isActive && !alerts.isSeen(visible[index].id),
                      onTap: () => context.pushNamed(
                        AppRoutes.alert,
                        pathParameters: {'id': visible[index].id},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
