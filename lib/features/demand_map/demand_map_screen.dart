import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/map/boundaries_status.dart';
import 'package:recicla_radar_sp/core/map/city_layers.dart';
import 'package:recicla_radar_sp/core/map/map_controller_grabber.dart';
import 'package:recicla_radar_sp/core/map/sp_map.dart';
import 'package:recicla_radar_sp/core/responsive/responsive.dart';
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
  const DemandMapScreen({super.key, this.districtId});

  /// Distrito que outra tela pediu para mostrar (abre o painel dele e enquadra o mapa).
  final String? districtId;

  @override
  State<DemandMapScreen> createState() => _DemandMapScreenState();
}

class _DemandMapScreenState extends State<DemandMapScreen> {
  // Estado local da tela: mapa ou lista, e o distrito aberto no painel.
  bool _showMap = true;
  String? _selectedId;
  String? _handledDistrictId;

  @override
  void didUpdateWidget(DemandMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.districtId != widget.districtId) _showMap = true;
  }

  /// Abre o painel do distrito pedido por outra tela, uma vez por pedido.
  void _applyRequest(List<District> districts) {
    final id = widget.districtId;
    if (id == null) {
      _handledDistrictId = null;
      return;
    }
    if (id == _handledDistrictId) return;
    _handledDistrictId = id;
    for (final district in districts) {
      if (district.id == id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openDistrict(district);
        });
        return;
      }
    }
  }

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
          ContentWidth(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.map_outlined),
                        label: Text('Mapa'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.list),
                        label: Text('Lista'),
                      ),
                    ],
                    selected: {_showMap},
                    onSelectionChanged: (values) =>
                        setState(() => _showMap = values.first),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LoadableView<List<District>>(
              notifier: districts,
              isEmpty: (list) => list.isEmpty,
              emptyTitle: 'Nenhum distrito encontrado',
              emptyMessage: 'Ainda não há dados de demanda para mostrar.',
              builder: (context, list) {
                _applyRequest(list);
                return _showMap
                    ? _DemandMap(
                        districts: list,
                        selectedId: _selectedId,
                        focusDistrictId: widget.districtId,
                        onOpen: _openDistrict,
                      )
                    : ContentWidth(
                        child: DemandDistrictList(
                          districts: list,
                          rankOf: districts.rankOf,
                          onTap: _openDistrict,
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DemandMap extends StatefulWidget {
  const _DemandMap({
    required this.districts,
    required this.selectedId,
    required this.focusDistrictId,
    required this.onOpen,
  });

  final List<District> districts;
  final String? selectedId;

  /// Distrito para enquadrar no mapa (pedido por outra tela).
  final String? focusDistrictId;
  final ValueChanged<District> onOpen;

  @override
  State<_DemandMap> createState() => _DemandMapState();
}

class _DemandMapState extends State<_DemandMap> {
  final LayerHitNotifier<String> _hit = ValueNotifier<LayerHitResult<String>?>(
    null,
  );
  MapController? _controller;
  String? _framedDistrictId;

  /// Com o mapa mais afastado que isso, os distritos são bolinhas pequenas;
  /// a partir daqui elas crescem e mostram o número do índice.
  static const double _fullDotsZoom = 11.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _frameRequestedDistrict(),
    );
  }

  @override
  void didUpdateWidget(_DemandMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _frameRequestedDistrict(),
    );
  }

  /// Enquadra no mapa o distrito pedido por outra tela. Se os limites ainda não
  /// chegaram, usa o ponto central do distrito.
  void _frameRequestedDistrict() {
    final controller = _controller;
    if (!mounted || controller == null) return;
    final id = widget.focusDistrictId;
    if (id == null) {
      _framedDistrictId = null;
      return;
    }
    final shape = context.read<BoundariesProvider>().boundaries?.districts[id];
    if (id == _framedDistrictId && shape == null) return;

    if (shape != null) {
      _framedDistrictId = id;
      controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([
            for (final polygon in shape.polygons) ...polygon.outer,
          ]),
          padding: const EdgeInsets.all(48),
          maxZoom: 13.5,
        ),
      );
    } else if (id != _framedDistrictId) {
      for (final district in widget.districts) {
        if (district.id != id) continue;
        _framedDistrictId = id;
        controller.move(district.position, 12.5);
      }
    }
  }

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

  List<Polygon<String>> _polygons(
    BuildContext context,
    CityBoundaries boundaries,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    final polygons = <Polygon<String>>[];
    // O distrito selecionado vai por último, para a borda dele ficar por cima.
    final ordered = [...widget.districts]
      ..sort(
        (a, b) => (a.id == widget.selectedId ? 1 : 0).compareTo(
          b.id == widget.selectedId ? 1 : 0,
        ),
      );

    for (final district in ordered) {
      final shape = boundaries.districts[district.id];
      if (shape == null) continue;
      final selected = district.id == widget.selectedId;
      for (final polygon in shape.polygons) {
        polygons.add(
          Polygon<String>(
            points: polygon.outer,
            holePointsList: polygon.holes,
            color: district.level
                .color(context)
                .withValues(alpha: selected ? 0.75 : 0.5),
            borderStrokeWidth: selected ? 4 : 1.4,
            borderColor: selected ? primary : CityLayers.districtBorder,
            hitValue: district.id,
          ),
        );
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
            MapControllerGrabber(
              onController: (controller) {
                _controller = controller;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _frameRequestedDistrict(),
                );
              },
            ),
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
              fullZoom: _fullDotsZoom,
              onTap: widget.onOpen,
            ),
            const MapAttribution(),
          ],
        ),
        const Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          child: DemandLegend(),
        ),
        const Positioned(
          bottom: AppSpacing.xl,
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: BoundariesStatus(),
          ),
        ),
      ],
    );
  }
}

/// Pontos dos distritos. Sempre aparecem; o tamanho e o texto dependem do zoom.
class _DistrictLabels extends StatelessWidget {
  const _DistrictLabels({
    required this.districts,
    required this.fullZoom,
    required this.onTap,
  });

  final List<District> districts;

  /// A partir deste zoom os pontos ficam maiores e mostram o índice.
  final double fullZoom;
  final ValueChanged<District> onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MapCamera.of(context).zoom < fullZoom;
    final size = DemandBubble.markerSize(compact: compact);

    return MarkerLayer(
      markers: [
        for (final district in districts)
          Marker(
            point: district.position,
            width: size,
            height: size,
            child: DemandBubble(
              district: district,
              compact: compact,
              onTap: () => onTap(district),
            ),
          ),
      ],
    );
  }
}
