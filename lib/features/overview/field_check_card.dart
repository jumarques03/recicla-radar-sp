import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/state/inspections_provider.dart';

/// Quantos alertas conferidos em campo foram confirmados pelas vistorias.
/// Liga o desempenho dos alertas a um resultado concreto.
class FieldCheckCard extends StatelessWidget {
  const FieldCheckCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = context.select<InspectionsProvider, ({int checked, int confirmed})>((p) => p.checkStats);

    final summary = stats.checked == 0
        ? 'Nenhum alerta foi conferido em campo ainda. Ao registrar uma vistoria, diga se ela confirma o alerta.'
        : '${stats.confirmed} de ${stats.checked} '
            '${stats.checked == 1 ? 'alerta conferido' : 'alertas conferidos'} em campo '
            '${stats.confirmed == 1 ? 'foi confirmado' : 'foram confirmados'} '
            '(${Formatters.percent(stats.confirmed / stats.checked * 100)}).';

    return AppCard(
      semanticLabel: 'Alertas conferidos em campo. $summary',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fact_check_outlined, color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alertas conferidos em campo', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(summary, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
