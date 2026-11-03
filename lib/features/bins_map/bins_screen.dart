import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/settings_action.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_card.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_marker.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_preview_sheet.dart';
import 'package:recicla_radar_sp/state/bins_provider.dart';

const LatLng _saoPaulo = LatLng(-23.5800, -46.6400);

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
                  _showMap ? _BinsMap(bins: list) : _BinsList(bins: list),
            ),
          ),
        ],
      ),
    );
  }
}

class _BinsMap extends StatelessWidget {
  const _BinsMap({required this.bins});

  final List<Bin> bins;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: _saoPaulo,
            initialZoom: 10.6,
            minZoom: 9,
            maxZoom: 17,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.com.fiap.recicla_radar_sp',
            ),
            MarkerLayer(
              markers: [
                for (final bin in bins)
                  Marker(
                    point: bin.position,
                    width: BinMarker.size,
                    height: BinMarker.size,
                    child: BinMarker(bin: bin, onTap: () => BinPreviewSheet.show(context, bin)),
                  ),
              ],
            ),
            const SimpleAttributionWidget(source: Text('© OpenStreetMap')),
          ],
        ),
        const Positioned(top: AppSpacing.sm, left: AppSpacing.sm, child: BinLegend()),
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
