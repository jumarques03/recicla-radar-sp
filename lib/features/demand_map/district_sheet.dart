import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/router/app_navigation.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/charts/chart_card.dart';
import 'package:recicla_radar_sp/core/widgets/charts/simple_line_chart.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';
import 'package:recicla_radar_sp/state/districts_provider.dart';

/// Painel inferior com os detalhes de um distrito.
class DistrictSheet extends StatelessWidget {
  const DistrictSheet({
    super.key,
    required this.district,
    required this.rank,
    required this.total,
    required this.activeAlerts,
    required this.onShowBins,
    required this.onShowAlerts,
  });

  final District district;
  final int rank;
  final int total;

  /// Alertas ativos do distrito.
  final int activeAlerts;

  /// Levam para as outras telas já filtradas por este distrito.
  final VoidCallback onShowBins;
  final VoidCallback onShowAlerts;

  static Future<void> show(BuildContext context, District district) {
    final provider = context.read<DistrictsProvider>();
    final activeAlerts = context.read<AlertsProvider>().activeForDistrict(district.id).length;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Por cima do app todo; senão a barra de navegação esconde a parte de baixo do painel.
      useRootNavigator: true,
      // Em tela larga o painel não estica de ponta a ponta.
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) => DistrictSheet(
        district: district,
        rank: provider.rankOf(district),
        total: provider.data?.length ?? 0,
        activeAlerts: activeAlerts,
        // Fecha o painel e abre a outra tela, usando o contexto da tela que abriu o painel.
        onShowBins: () {
          Navigator.of(sheetContext).pop();
          context.showDistrictBins(district.id);
        },
        onShowAlerts: () {
          Navigator.of(sheetContext).pop();
          context.showDistrictAlerts(district.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeks = district.history.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(header: true, child: Text(district.name, style: theme.textTheme.headlineSmall)),
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerLeft, child: DemandLevelChip(district.level)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.md,
              children: [
                _Fact(label: 'Índice de demanda', value: '${district.demandIndex} de 100'),
                _Fact(label: 'Ranking', value: '$rankº de $total'),
                _Fact(label: 'Lixeiras no distrito', value: '${district.binCount}'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ChartCard(
              title: 'Histórico do índice',
              summary: 'Nas últimas $weeks semanas o índice foi de '
                  '${district.history.first} para ${district.history.last}. '
                  'É uma estimativa, não uma medição exata.',
              height: 160,
              chart: SimpleLineChart(
                labels: [for (var i = 0; i < weeks; i++) 'S${i + 1}'],
                values: [for (final value in district.history) value.toDouble()],
                maxY: 100,
                formatTooltip: (v) => 'Índice ${v.round()}',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onShowBins,
              icon: const Icon(Icons.recycling),
              label: Text(district.binCount == 1
                  ? 'Ver a lixeira do distrito'
                  : 'Ver as ${district.binCount} lixeiras do distrito'),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            OutlinedButton.icon(
              onPressed: onShowAlerts,
              icon: const Icon(Icons.notifications_outlined),
              label: Text(switch (activeAlerts) {
                0 => 'Ver alertas do distrito (nenhum ativo)',
                1 => 'Ver o alerta ativo do distrito',
                _ => 'Ver os $activeAlerts alertas ativos do distrito',
              }),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}
