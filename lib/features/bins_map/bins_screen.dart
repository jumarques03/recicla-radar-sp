import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/map/boundaries_status.dart';
import 'package:recicla_radar_sp/core/map/city_layers.dart';
import 'package:recicla_radar_sp/core/map/sp_map.dart';
import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/map_attribution.dart';
import 'package:recicla_radar_sp/core/widgets/settings_action.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/disposal_point.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_card.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_map_layers.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_marker.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_preview_sheet.dart';
import 'package:recicla_radar_sp/state/bins_provider.dart';
import 'package:recicla_radar_sp/state/boundaries_provider.dart';

class BinsScreen extends StatefulWidget {
  const BinsScreen({super.key});

  @override
  State<BinsScreen> createState() => _BinsScreenState();
}

class _BinsScreenState extends State<BinsScreen> {
  // Estado local da tela: só importa aqui se mostramos mapa ou lista.
  bool _showMap = true;

  @override
  Widget build(BuildContext context) {
    final bins = context.watch<BinsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lixeiras'),
        actions: const [SettingsAction()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, icon: Icon(Icons.map_outlined), label: Text('Mapa')),
                ButtonSegment(value: false, icon: Icon(Icons.list), label: Text('Lista')),
              ],
              selected: {_showMap},
              onSelectionChanged: (values) => setState(() => _showMap = values.first),
            ),
          ),
          Expanded(
            child: LoadableView<List<Bin>>(
              notifier: bins,
              isEmpty: (list) => list.isEmpty,
              emptyTitle: 'Nenhuma lixeira cadastrada',
              emptyMessage: 'Quando houver lixeiras, elas aparecem aqui.',
              builder: (context, list) =>
                  _showMap
                  ? _BinsMap(bins: list, points: bins.points)
                  : _BinsList(bins: list),
            ),
          ),
        ],
      ),
    );
  }
}

class _BinsMap extends StatelessWidget {
  const _BinsMap({required this.bins, required this.points});

  final List<Bin> bins;
  final List<DisposalPoint> points;

  @override
  Widget build(BuildContext context) {
    final boundaries = context.watch<BoundariesProvider>().boundaries;

    return Stack(
      children: [
        FlutterMap(
          options: SpMap.options(),
          children: [
            SpMap.tileLayer(),
            if (boundaries != null) ...[
              CityLayers.dimOutside(boundaries),
              CityLayers.districtBorders(boundaries, width: 1),
              ...CityLayers.outline(boundaries),
            ],
            DisposalPointLayer(points: points),
            BinClusterLayer(
              bins: bins,
              onBinTap: (bin) => BinPreviewSheet.show(context, bin),
            ),
            const MapAttribution(),
          ],
        ),
        const Positioned(top: AppSpacing.sm, left: AppSpacing.sm, child: BinLegend()),
        const Positioned(
          bottom: AppSpacing.xl,
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Align(alignment: Alignment.bottomLeft, child: BoundariesStatus()),
        ),
      ],
    );
  }
}

class _BinsList extends StatelessWidget {
  const _BinsList({required this.bins});

  final List<Bin> bins;

  @override
  Widget build(BuildContext context) {
    // As mais cheias primeiro: são as que mais precisam de atenção.
    final sorted = [...bins]..sort((a, b) => b.fillPercent.compareTo(a.fillPercent));
    return RefreshIndicator(
      onRefresh: context.read<BinsProvider>().load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        itemCount: sorted.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm + 4),
        itemBuilder: (context, index) => BinCard(
          bin: sorted[index],
          onTap: () => context.pushNamed(AppRoutes.bin, pathParameters: {'id': sorted[index].id}),
        ),
      ),
    );
  }
}
