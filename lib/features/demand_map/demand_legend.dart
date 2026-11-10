import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/district.dart';

/// Legenda do mapa de demanda: cor, ícone e faixa do índice.
class DemandLegend extends StatelessWidget {
  const DemandLegend({super.key});

  static const Map<DemandLevel, String> _ranges = {
    DemandLevel.low: '0 a 39',
    DemandLevel.medium: '40 a 69',
    DemandLevel.high: '70 a 100',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Legenda: demanda baixa de 0 a 39, média de 40 a 69, alta de 70 a 100.',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Índice de demanda', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              for (final level in DemandLevel.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(level.icon, size: 18, color: level.color(context)),
                      const SizedBox(width: 6),
                      Text(
                        '${level.label}: ${_ranges[level]}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Text('Aproxime para ver o índice', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
