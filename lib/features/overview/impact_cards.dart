import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/router/app_navigation.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/theme/status_colors.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/core/widgets/stat_card.dart';
import 'package:recicla_radar_sp/data/models/overview_summary.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';

/// Quatro indicadores principais. Muda o número de colunas conforme o espaço
/// e o tamanho da fonte, para nada ficar espremido.
class ImpactStatGrid extends StatelessWidget {
  const ImpactStatGrid({super.key, required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final activeAlerts = context.select<AlertsProvider, int>((p) => p.activeCount);
    final cards = [
      StatCard(
        icon: Icons.scale_outlined,
        label: 'Total coletado',
        value: Formatters.kg(summary.totalKg),
        footnote: 'nos últimos ${summary.days} dias',
        onTap: context.showAllBins,
      ),
      StatCard(
        icon: Icons.power_settings_new,
        label: 'Lixeiras operando',
        value: Formatters.percent(summary.operatingPercent),
        footnote: 'enviando dados agora',
        onTap: context.showAllBins,
      ),
      StatCard(
        icon: Icons.notifications_active_outlined,
        label: 'Alertas ativos',
        value: '$activeAlerts',
        footnote: 'aguardando decisão',
        onTap: context.showAllAlerts,
      ),
      StatCard(
        icon: Icons.eco_outlined,
        label: 'Desviado do aterro',
        value: Formatters.kg(summary.divertedKg),
        footnote: 'estimativa de reciclagem',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final fontScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final columns = fontScale > 1.3 ? 1 : (constraints.maxWidth >= 640 ? 4 : 2);

        // Uma linha de cada vez, para os cards da mesma linha terem a mesma altura.
        final rows = <Widget>[];
        for (var start = 0; start < cards.length; start += columns) {
          final end = (start + columns).clamp(0, cards.length);
          rows.add(IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start) const SizedBox(width: AppSpacing.md),
                  Expanded(child: i < end ? cards[i] : const SizedBox.shrink()),
                ],
              ],
            ),
          ));
        }
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

/// Bloco de benefício social com a variação em relação ao período anterior.
class SocialBenefitCard extends StatelessWidget {
  const SocialBenefitCard({super.key, required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variation = summary.variationPercent;
    final isUp = variation >= 0;
    final color = isUp ? context.statusColors.success : context.statusColors.danger;
    final trendText = '${Formatters.signedPercent(variation)} em relação aos '
        '${summary.days} dias anteriores';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.diversity_3_outlined, color: theme.colorScheme.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Material enviado a cooperativas de reciclagem',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(Formatters.kg(summary.divertedKg), style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(isUp ? Icons.trending_up : Icons.trending_down, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isUp ? 'Aumentou: $trendText' : 'Diminuiu: $trendText',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Estimamos que ${Formatters.percent(summary.recoveryRate * 100)} do material '
            'coletado é reaproveitado pelas cooperativas.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
