import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';

/// Card de gráfico com um resumo em texto. O gráfico em si é ignorado por
/// leitores de tela; quem lê ouve o [summary].
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.summary,
    required this.chart,
    this.height = 220,
    this.legend,
  });

  final String title;
  final String summary;
  final Widget chart;
  final double height;
  final Widget? legend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: '$title. $summary',
            image: true,
            excludeSemantics: true,
            child: SizedBox(height: height, child: chart),
          ),
          if (legend != null) ...[const SizedBox(height: AppSpacing.md), legend!],
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
