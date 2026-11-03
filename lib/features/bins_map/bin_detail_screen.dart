import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/core/widgets/charts/chart_card.dart';
import 'package:recicla_radar_sp/core/widgets/charts/material_charts.dart';
import 'package:recicla_radar_sp/core/widgets/charts/simple_line_chart.dart';
import 'package:recicla_radar_sp/core/widgets/section_title.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/reading.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_card.dart';
import 'package:recicla_radar_sp/state/bins_provider.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

class BinDetailScreen extends StatefulWidget {
  const BinDetailScreen({super.key, required this.binId});

  final String binId;

  @override
  State<BinDetailScreen> createState() => _BinDetailScreenState();
}

class _BinDetailScreenState extends State<BinDetailScreen> {
  // Estado local: as leituras só interessam a esta tela.
  late Future<List<Reading>> _readings;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  void _loadReadings() {
    _readings = context.read<BinRepository>().fetchReadings(widget.binId, days: 7);
  }

  @override
  Widget build(BuildContext context) {
    final bins = context.watch<BinsProvider>();
    final bin = bins.byId(widget.binId);

    return Scaffold(
      appBar: AppBar(title: Text(bin?.name ?? 'Lixeira')),
      body: bins.status != LoadStatus.ready
          ? LoadableView<List<Bin>>(notifier: bins, isEmpty: (_) => false, builder: (_, _) => const SizedBox())
          : bin == null
              ? const EmptyView(
                  title: 'Lixeira não encontrada',
                  message: 'Ela pode ter sido removida. Volte e escolha outra.',
                  icon: Icons.search_off,
                )
              : _content(context, bin),
    );
  }

  Widget _content(BuildContext context, Bin bin) {
    final theme = Theme.of(context);
    final statusColor = bin.status.color(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enchimento agora', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm + 4),
              FillBar(percent: bin.fillPercent, color: statusColor, height: 20),
              const SizedBox(height: AppSpacing.md),
              BinStatusChip(bin.status),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(icon: Icons.place_outlined, label: 'Endereço', value: bin.address),
              _InfoRow(
                icon: Icons.schedule,
                label: 'Última coleta',
                value: '${Formatters.timeAgo(bin.lastCollection)} '
                    '(${Formatters.dateTime(bin.lastCollection)})',
              ),
              _InfoRow(
                icon: Icons.scale_outlined,
                label: 'Total coletado em 30 dias',
                value: Formatters.kg(bin.totalKg),
              ),
            ],
          ),
        ),
        const SectionTitle('Material coletado'),
        ChartCard(
          title: 'Quilos por material (30 dias)',
          summary: describeMaterials(bin.kgByMaterial),
          chart: MaterialBarChart(kgByMaterial: bin.kgByMaterial),
          legend: MaterialLegend(kgByMaterial: bin.kgByMaterial),
        ),
        const SectionTitle('Últimos 7 dias'),
        FutureBuilder<List<Reading>>(
          future: _readings,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 200, child: LoadingView());
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 260,
                child: ErrorView(
                  message: 'Não foi possível carregar o histórico. Tente de novo.',
                  onRetry: () => setState(_loadReadings),
                ),
              );
            }
            final readings = snapshot.data!.reversed.toList();
            if (readings.isEmpty) {
              return const SizedBox(
                height: 200,
                child: EmptyView(
                  title: 'Sem histórico',
                  message: 'Esta lixeira ainda não enviou leituras.',
                ),
              );
            }
            final values = [for (final r in readings) r.fillPercent.toDouble()];
            return ChartCard(
              title: 'Enchimento por dia (%)',
              summary: 'Hoje a lixeira está com ${values.last.round()}%. '
                  'Há 7 dias estava com ${values.first.round()}%. '
                  'Quedas no gráfico indicam que houve coleta.',
              height: 180,
              chart: SimpleLineChart(
                labels: [for (final r in readings) Formatters.shortDate(r.date)],
                values: values,
                maxY: 100,
                formatY: (v) => '${v.round()}%',
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          icon: const Icon(Icons.edit_note),
          label: const Text('Registrar vistoria'),
          onPressed: () => context.pushNamed(
            AppRoutes.inspection,
            queryParameters: {'binId': bin.id},
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  Text(value, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
