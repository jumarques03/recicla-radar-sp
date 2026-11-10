import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/widgets/charts/chart_card.dart';
import 'package:recicla_radar_sp/core/widgets/charts/material_charts.dart';
import 'package:recicla_radar_sp/core/widgets/charts/simple_line_chart.dart';
import 'package:recicla_radar_sp/core/widgets/filter_controls.dart';
import 'package:recicla_radar_sp/core/widgets/section_title.dart';
import 'package:recicla_radar_sp/core/widgets/settings_action.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/data/models/overview_summary.dart';
import 'package:recicla_radar_sp/features/overview/critical_alerts_card.dart';
import 'package:recicla_radar_sp/features/overview/impact_cards.dart';
import 'package:recicla_radar_sp/state/filters_provider.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';
import 'package:recicla_radar_sp/state/overview_provider.dart';
import 'package:recicla_radar_sp/state/session_provider.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final overview = context.watch<OverviewProvider>();
    final filters = context.watch<FiltersProvider>();
    final name = context.select<SessionProvider, String?>((s) => s.user?.name.split(' ').first);

    final showsContent =
        overview.status == LoadStatus.ready && (overview.data?.totalKg ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão geral'),
        actions: const [SettingsAction()],
      ),
      body: RefreshIndicator(
        onRefresh: overview.load,
        child: ContentListView(
          maxWidth: Breakpoints.dashboardMax,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (name != null)
              Text('Olá, $name!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              container: true,
              label: 'Filtros de período e material',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PeriodSelector(
                    selected: filters.periodDays,
                    onChanged: filters.setPeriod,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MaterialFilter(
                    selected: filters.material,
                    onChanged: filters.setMaterial,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const CriticalAlertsCard(),
            const SizedBox(height: AppSpacing.md),
            // Carregando, erro e vazio precisam de altura própria dentro da lista.
            SizedBox(
              height: showsContent ? null : 320,
              child: LoadableView<OverviewSummary>(
                notifier: overview,
                isEmpty: (summary) => summary.totalKg == 0,
                emptyTitle: 'Sem coletas neste período',
                emptyMessage: 'Tente um período maior ou outro material.',
                builder: (context, summary) => _SummaryContent(summary: summary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final materials = summary.byMaterial;
    final seriesName = summary.seriesUnit == 'dia' ? 'por dia' : 'por semana';
    final series = summary.series;
    final peak = series.reduce((a, b) => a.value >= b.value ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImpactStatGrid(summary: summary),
        const SectionTitle('Como a coleta evoluiu'),
        ChartCard(
          title: 'Quilos coletados $seriesName',
          summary: 'Total de ${Formatters.kg(summary.totalKg)} nos últimos '
              '${summary.days} dias. O maior valor foi ${Formatters.kg(peak.value)}, '
              'na semana de ${peak.label}.',
          chart: SimpleLineChart(
            labels: [for (final point in series) point.label],
            values: [for (final point in series) point.value],
            formatY: Formatters.compactKg,
            formatTooltip: Formatters.kg,
          ),
        ),
        const SectionTitle('Por tipo de material'),
        LayoutBuilder(
          builder: (context, constraints) {
            final barCard = ChartCard(
              title: 'Quilos por material',
              summary: describeMaterials(materials),
              chart: MaterialBarChart(kgByMaterial: materials),
              legend: MaterialLegend(kgByMaterial: materials),
            );
            final pieCard = ChartCard(
              title: 'Participação de cada material',
              summary: 'Cada fatia mostra quanto do total cada material representa.',
              height: 200,
              chart: MaterialPieChart(kgByMaterial: materials),
            );
            // Em tela larga, os dois gráficos ficam lado a lado, com a mesma altura.
            if (constraints.maxWidth >= 760) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: barCard),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: pieCard),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [barCard, const SizedBox(height: AppSpacing.md), pieCard],
            );
          },
        ),
        const SectionTitle('Benefício social'),
        SocialBenefitCard(summary: summary),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
