import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/map/boundaries_status.dart';
import 'package:recicla_radar_sp/core/map/city_layers.dart';
import 'package:recicla_radar_sp/core/map/map_controller_grabber.dart';
import 'package:recicla_radar_sp/core/map/sp_map.dart';
import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/map_attribution.dart';
import 'package:recicla_radar_sp/core/widgets/settings_action.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/disposal_point.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_card.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_map_layers.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_marker.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_preview_sheet.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';
import 'package:recicla_radar_sp/state/bins_provider.dart';
import 'package:recicla_radar_sp/state/boundaries_provider.dart';
import 'package:recicla_radar_sp/state/districts_provider.dart';

class BinsScreen extends StatefulWidget {
  const BinsScreen({
    super.key,
    this.districtId,
    this.focusBinId,
    this.showList = false,
  });

  /// Mostra só as lixeiras deste distrito (vem do painel do distrito).
  final String? districtId;

  /// Centraliza o mapa nesta lixeira (vem do alerta ou do detalhe).
  final String? focusBinId;

  /// Abre direto na lista, em vez do mapa.
  final bool showList;

  @override
  State<BinsScreen> createState() => _BinsScreenState();
}

class _BinsScreenState extends State<BinsScreen> {
  // Estado local da tela: mapa ou lista, e o filtro de status da lista.
  late bool _showMap = !widget.showList;
  BinStatus? _status;

  @override
  void didUpdateWidget(BinsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chegou um novo pedido de outra tela (ex.: "ver no mapa").
    if (oldWidget.showList != widget.showList) _showMap = !widget.showList;
    if (widget.focusBinId != null &&
        widget.focusBinId != oldWidget.focusBinId) {
      _showMap = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bins = context.watch<BinsProvider>();
    final districts =
        context.watch<DistrictsProvider>().data ?? const <District>[];
    District? filteredDistrict;
    for (final district in districts) {
      if (district.id == widget.districtId) filteredDistrict = district;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lixeiras'),
        actions: const [SettingsAction()],
      ),
      body: Column(
        children: [
          ContentWidth(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
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
                if (filteredDistrict != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        avatar: const Icon(Icons.filter_alt_outlined, size: 18),
                        label: Text('Distrito: ${filteredDistrict.name}'),
                        deleteButtonTooltipMessage:
                            'Tirar o filtro de distrito',
                        onDeleted: () => context.goNamed(
                          AppRoutes.bins,
                          queryParameters: {
                            if (!_showMap) AppRoutes.modeParam: 'lista',
                          },
                        ),
                      ),
                    ),
                  ),
                if (!_showMap)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: _StatusFilter(
                      selected: _status,
                      onChanged: (status) => setState(() => _status = status),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: LoadableView<List<Bin>>(
              notifier: bins,
              isEmpty: (list) => list.isEmpty,
              emptyTitle: 'Nenhuma lixeira cadastrada',
              emptyMessage: 'Quando houver lixeiras, elas aparecem aqui.',
              builder: (context, all) {
                final inDistrict = widget.districtId == null
                    ? all
                    : all
                          .where((bin) => bin.districtId == widget.districtId)
                          .toList();
                if (_showMap) {
                  return _BinsMap(
                    bins: inDistrict,
                    points: bins.points,
                    districtId: widget.districtId,
                    focusBinId: widget.focusBinId,
                  );
                }
                final visible = inDistrict
                    .where((bin) => _status == null || bin.status == _status)
                    .toList();
                if (visible.isEmpty) {
                  return const EmptyView(
                    title: 'Nenhuma lixeira com esse filtro',
                    message:
                        'Escolha outro status ou tire o filtro de distrito.',
                    icon: Icons.filter_alt_off_outlined,
                  );
                }
                return ContentWidth(child: _BinsList(bins: visible));
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Filtro por status, na lista de lixeiras.
class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.selected, required this.onChanged});

  final BinStatus? selected;
  final ValueChanged<BinStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final status in BinStatus.values)
            ChoiceChip(
              avatar: Icon(status.icon, size: 18, color: status.color(context)),
              label: Text(status.label),
              selected: selected == status,
              onSelected: (_) => onChanged(status),
            ),
        ],
      ),
    );
  }
}

class _BinsMap extends StatefulWidget {
  const _BinsMap({
    required this.bins,
    required this.points,
    required this.districtId,
    required this.focusBinId,
  });

  final List<Bin> bins;
  final List<DisposalPoint> points;
  final String? districtId;
  final String? focusBinId;

  @override
  State<_BinsMap> createState() => _BinsMapState();
}

class _BinsMapState extends State<_BinsMap> {
  MapController? _controller;
  String? _handledFocus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyRequest());
  }

  @override
  void didUpdateWidget(_BinsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusBinId != widget.focusBinId ||
        oldWidget.districtId != widget.districtId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyRequest());
    }
  }

  /// Atende o que outra tela pediu: centralizar uma lixeira ou enquadrar um distrito.
  void _applyRequest() {
    final controller = _controller;
    if (!mounted || controller == null) return;
    final focus = widget.focusBinId;
    if (focus == null) {
      _handledFocus = null;
    } else if (focus != _handledFocus) {
      for (final bin in widget.bins) {
        if (bin.id != focus) continue;
        _handledFocus = focus;
        controller.move(bin.position, 16);
        BinPreviewSheet.show(context, bin);
        return;
      }
    }

    if (widget.districtId != null && widget.bins.isNotEmpty) {
      controller.fitCamera(
        CameraFit.coordinates(
          coordinates: [for (final bin in widget.bins) bin.position],
          padding: const EdgeInsets.all(64),
          maxZoom: 15,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final boundaries = context.watch<BoundariesProvider>().boundaries;
    final districts = {
      for (final district
          in context.watch<DistrictsProvider>().data ?? const <District>[])
        district.id: district,
    };

    return Stack(
      children: [
        FlutterMap(
          options: SpMap.options(),
          children: [
            SpMap.tileLayer(),
            MapControllerGrabber(
              onController: (controller) {
                _controller = controller;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _applyRequest(),
                );
              },
            ),
            if (boundaries != null) ...[
              CityLayers.dimOutside(boundaries),
              CityLayers.districtFills(
                boundaries,
                colorFor: (id) => districts[id]?.level.color(context),
                alpha: 0.45,
                borderWidth: 1,
              ),
              ...CityLayers.outline(boundaries),
            ],
            DisposalPointLayer(points: widget.points),
            BinClusterLayer(
              bins: widget.bins,
              onBinTap: (bin) => BinPreviewSheet.show(context, bin),
            ),
            const MapAttribution(),
          ],
        ),
        const Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          child: BinLegend(),
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

class _BinsList extends StatelessWidget {
  const _BinsList({required this.bins});

  final List<Bin> bins;

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertsProvider>();
    // As mais cheias primeiro: são as que mais precisam de atenção.
    final sorted = [...bins]
      ..sort((a, b) => b.fillPercent.compareTo(a.fillPercent));
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
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm + 4),
        itemBuilder: (context, index) => BinCard(
          bin: sorted[index],
          activeAlerts: alerts.activeForBin(sorted[index].id).length,
          onTap: () => context.pushNamed(
            AppRoutes.bin,
            pathParameters: {'id': sorted[index].id},
          ),
        ),
      ),
    );
  }
}
