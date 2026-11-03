import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/theme/status_colors.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

/// Destaque no topo da visão geral com os alertas críticos ainda abertos.
class CriticalAlertsCard extends StatelessWidget {
  const CriticalAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertsProvider>();
    if (alerts.status != LoadStatus.ready) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = context.statusColors;
    final critical = alerts.critical;

    if (critical.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: colors.success),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Text(
                'Nenhum alerta crítico agora. Tudo sob controle.',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_outlined, color: colors.danger),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    critical.length == 1
                        ? '1 alerta crítico precisa de atenção'
                        : '${critical.length} alertas críticos precisam de atenção',
                    style: theme.textTheme.titleMedium?.copyWith(color: colors.danger),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final alert in critical.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: AppSpacing.sm,
              title: Text(alert.title),
              subtitle: Text('${alert.location} · ${Formatters.timeAgo(alert.createdAt)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.goNamed(AppRoutes.alert, pathParameters: {'id': alert.id}),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.goNamed(AppRoutes.alerts),
              child: const Text('Ver todos os alertas'),
            ),
          ),
        ],
      ),
    );
  }
}
