import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/core/router/app_navigation.dart';
import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/status_colors.dart';
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
import 'package:recicla_radar_sp/features/alerts/alert_card.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_card.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';
import 'package:recicla_radar_sp/state/bins_provider.dart';
import 'package:recicla_radar_sp/state/inspections_provider.dart';
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

    return ContentListView(
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
              _InfoRow(icon: Icons.place_outlined, label: 'Local', value: bin.address),
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
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.showBinOnMap(bin.id),
              icon: const Icon(Icons.place_outlined),
              label: const Text('Ver no mapa'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.showDistrict(bin.districtId),
              icon: const Icon(Icons.map_outlined),
              label: Text('Distrito ${bin.districtName}'),
            ),
          ],
        ),
        const SectionTitle('Alertas desta lixeira'),
        _BinAlerts(binId: bin.id),
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
                formatTooltip: (v) => '${v.round()}%',
              ),
            );
          },
        ),
        const SectionTitle('Vistorias registradas'),
        _BinInspections(binId: bin.id),
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

/// Alertas ativos desta lixeira, ligados à tela de alertas.
class _BinAlerts extends StatelessWidget {
  const _BinAlerts({required this.binId});

  final String binId;

  static const int _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertsProvider>();
    final active = alerts.activeForBin(binId);

    if (alerts.status != LoadStatus.ready) {
      return const SizedBox(height: 80, child: LoadingView());
    }
    if (active.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: context.statusColors.success),
            const SizedBox(width: AppSpacing.sm + 4),
            const Expanded(child: Text('Nenhum alerta ativo para esta lixeira.')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final alert in active.take(_maxShown)) ...[
          AlertCard(
            alert: alert,
            isNew: !alerts.isSeen(alert.id),
            onTap: () => context.openAlert(alert.id),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
        ],
        if (active.length > _maxShown)
          TextButton(
            onPressed: () => context.showBinAlerts(binId),
            child: Text('Ver os ${active.length} alertas desta lixeira'),
          ),
      ],
    );
  }
}

/// Vistorias salvas no aparelho para esta lixeira.
class _BinInspections extends StatelessWidget {
  const _BinInspections({required this.binId});

  final String binId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = context.watch<InspectionsProvider>().forBin(binId);

    if (items.isEmpty) {
      return const AppCard(child: Text('Ainda não há vistorias registradas para esta lixeira.'));
    }
    return Column(
      children: [
        for (final item in items.take(5)) ...[
          AppCard(
            semanticLabel: '${item.type.label}, gravidade ${item.severity.label.toLowerCase()}, '
                '${Formatters.dateTime(item.dateTime)}. ${item.description}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.type.label, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${Formatters.dateTime(item.dateTime)} · gravidade ${item.severity.label.toLowerCase()}'
                  '${item.needsAction ? ' · precisa de coleta ou reparo' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(item.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.authorName == null ? 'Registrada de forma anônima' : 'Por ${item.authorName}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
        ],
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
