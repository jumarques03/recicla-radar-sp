import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/map/boundaries_status.dart';
import 'package:recicla_radar_sp/core/map/city_layers.dart';
import 'package:recicla_radar_sp/core/map/sp_map.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/map_attribution.dart';
import 'package:recicla_radar_sp/core/widgets/settings_action.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/city_boundaries.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/features/demand_map/demand_bubble.dart';
import 'package:recicla_radar_sp/features/demand_map/demand_legend.dart';
import 'package:recicla_radar_sp/features/demand_map/demand_list.dart';
import 'package:recicla_radar_sp/features/demand_map/district_sheet.dart';
import 'package:recicla_radar_sp/state/boundaries_provider.dart';
import 'package:recicla_radar_sp/state/districts_provider.dart';

class DemandMapScreen extends StatefulWidget {
  const DemandMapScreen({super.key});

  @override
  State<DemandMapScreen> createState() => _DemandMapScreenState();
}

class _DemandMapScreenState extends State<DemandMapScreen> {
  // Estado local da tela: mapa ou lista, e o distrito aberto no painel.
  bool _showMap = true;
  String? _selectedId;

  Future<void> _openDistrict(District district) async {
    setState(() => _selectedId = district.id);
    await DistrictSheet.show(context, district);
    if (mounted) setState(() => _selectedId = null);
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline),
        title: const Text('Sobre o índice de demanda'),
        content: const SingleChildScrollView(
          child: Text(
            'O índice vai de 0 a 100 e é uma estimativa de quanto lixo é descartado em '
            'cada distrito. Quanto maior o número, maior o descarte.\n\n'
            'Cores: verde é demanda baixa, amarelo é média e vermelho é alta.\n\n'
            'Limitações:\n'
            '• É uma estimativa, não uma medição exata.\n'
            '• Não considera eventos, feriados ou obras.\n'
            '• Os limites dos distritos vêm do OpenStreetMap.\n\n'
            'Use como apoio. A decisão final é sempre de uma pessoa.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districts = context.watch<DistrictsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de demanda'),
        actions: [
          IconButton(
            tooltip: 'Como funciona o índice de demanda',
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
          const SettingsAction(),
        ],
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
            child: LoadableView<List<District>>(
              notifier: districts,
              isEmpty: (list) => list.isEmpty,
              emptyTitle: 'Nenhum distrito encontrado',
              emptyMessage: 'Ainda não há dados de demanda para mostrar.',
              builder: (context, list) => _showMap
                  ? _DemandMap(districts: list, selectedId: _selectedId, onOpen: _openDistrict)
                  : DemandDistrictList(
                      districts: list,
                      rankOf: districts.rankOf,
                      onTap: _openDistrict,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemandMap extends StatefulWidget {
  const _DemandMap({required this.districts, required this.selectedId, required this.onOpen});

  final List<District> districts;
  final String? selectedId;
  final ValueChanged<District> onOpen;

  @override
  State<_DemandMap> createState() => _DemandMapState();
}

class _DemandMapState extends State<_DemandMap> {
  final LayerHitNotifier<String> _hit = ValueNotifier<LayerHitResult<String>?>(null);

  /// Com o mapa mais afastado que isso, só as cores aparecem; os números dos
  /// distritos entram ao aproximar, para o mapa não ficar poluído.
  static const double _labelsMinZoom = 12.5;

  @override
  void dispose() {
    _hit.dispose();
    super.dispose();
  }

  void _onTap() {
    final hit = _hit.value;
    if (hit == null || hit.hitValues.isEmpty) return;
    for (final district in widget.districts) {
      if (district.id == hit.hitValues.first) {
        widget.onOpen(district);
        return;
      }
    }
  }

  List<Polygon<String>> _polygons(BuildContext context, CityBoundaries boundaries) {
    final primary = Theme.of(context).colorScheme.primary;
    final polygons = <Polygon<String>>[];
    // O distrito selecionado vai por último, para a borda dele ficar por cima.
    final ordered = [...widget.districts]
      ..sort((a, b) => (a.id == widget.selectedId ? 1 : 0).compareTo(b.id == widget.selectedId ? 1 : 0));

    for (final district in ordered) {
      final shape = boundaries.districts[district.id];
      if (shape == null) continue;
      final selected = district.id == widget.selectedId;
      for (final polygon in shape.polygons) {
        polygons.add(Polygon<String>(
          points: polygon.outer,
          holePointsList: polygon.holes,
          color: district.level.color(context).withValues(alpha: selected ? 0.75 : 0.5),
          borderStrokeWidth: selected ? 4 : 1.4,
          borderColor: selected ? primary : CityLayers.districtBorder,
          hitValue: district.id,
        ));
      }
    }
    return polygons;
  }

  @override
  Widget build(BuildContext context) {
    final boundaries = context.watch<BoundariesProvider>().boundaries;

    return Stack(
      children: [
        FlutterMap(
          options: SpMap.options(maxZoom: 16),
          children: [
            SpMap.tileLayer(),
            if (boundaries != null) ...[
              CityLayers.dimOutside(boundaries),
              GestureDetector(
                onTap: _onTap,
                child: PolygonLayer<String>(
                  hitNotifier: _hit,
                  polygons: _polygons(context, boundaries),
                ),
              ),
              ...CityLayers.outline(boundaries),
            ],
            _DistrictLabels(
              districts: widget.districts,
              // Sem os limites no mapa, os círculos são a única forma de tocar nos distritos.
              alwaysVisible: boundaries == null,
              minZoom: _labelsMinZoom,
              onTap: widget.onOpen,
            ),
            const MapAttribution(),
          ],
        ),
        const Positioned(top: AppSpacing.sm, left: AppSpacing.sm, child: DemandLegend()),
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

class _DistrictLabels extends StatelessWidget {
  const _DistrictLabels({
    required this.districts,
    required this.alwaysVisible,
    required this.minZoom,
    required this.onTap,
  });

  final List<District> districts;
  final bool alwaysVisible;
  final double minZoom;
  final ValueChanged<District> onTap;

  @override
  Widget build(BuildContext context) {
    if (!alwaysVisible && MapCamera.of(context).zoom < minZoom) return const SizedBox.shrink();

    return MarkerLayer(
      markers: [
        for (final district in districts)
          Marker(
            point: district.position,
            width: DemandBubble.size,
            height: DemandBubble.size,
            child: DemandBubble(district: district, onTap: () => onTap(district)),
          ),
      ],
    );
  }
}
