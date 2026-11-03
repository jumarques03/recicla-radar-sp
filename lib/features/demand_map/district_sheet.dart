import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/charts/chart_card.dart';
import 'package:recicla_radar_sp/core/widgets/charts/simple_line_chart.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/state/districts_provider.dart';

/// Painel inferior com os detalhes de um distrito.
class DistrictSheet extends StatelessWidget {
  const DistrictSheet({super.key, required this.district, required this.rank, required this.total});

  final District district;
  final int rank;
  final int total;

  static void show(BuildContext context, District district) {
    final provider = context.read<DistrictsProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DistrictSheet(
        district: district,
        rank: provider.rankOf(district),
        total: provider.data?.length ?? 0,
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
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
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
