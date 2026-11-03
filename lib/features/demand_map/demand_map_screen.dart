import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/settings_action.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/features/demand_map/demand_bubble.dart';
import 'package:recicla_radar_sp/features/demand_map/demand_legend.dart';
import 'package:recicla_radar_sp/features/demand_map/district_sheet.dart';
import 'package:recicla_radar_sp/state/districts_provider.dart';

const LatLng _saoPaulo = LatLng(-23.5800, -46.6400);

class DemandMapScreen extends StatelessWidget {
  const DemandMapScreen({super.key});

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline),
        title: const Text('Sobre o índice de demanda'),
        content: const SingleChildScrollView(
          child: Text(
            'O índice vai de 0 a 100 e é uma estimativa de quanto lixo deve ser '
            'descartado em cada distrito.\n\n'
            'Limitações:\n'
            '• Usa dados simulados nesta versão.\n'
            '• O ponto no mapa marca o centro aproximado do distrito, não o limite exato.\n'
            '• Não considera eventos, feriados ou obras.\n\n'
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
            onPressed: () => _showInfo(context),
          ),
          const SettingsAction(),
        ],
      ),
      body: LoadableView<List<District>>(
        notifier: districts,
        isEmpty: (list) => list.isEmpty,
        emptyTitle: 'Nenhum distrito encontrado',
        emptyMessage: 'Ainda não há dados de demanda para mostrar.',
        builder: (context, list) => Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: _saoPaulo,
                initialZoom: 10.6,
                minZoom: 9,
                maxZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'br.com.fiap.recicla_radar_sp',
                ),
                MarkerLayer(
                  markers: [
                    for (final district in list)
                      Marker(
                        point: district.position,
                        width: DemandBubble.sizeFor(district),
                        height: DemandBubble.sizeFor(district),
                        child: DemandBubble(
                          district: district,
                          onTap: () => DistrictSheet.show(context, district),
                        ),
                      ),
                  ],
                ),
                const SimpleAttributionWidget(source: Text('© OpenStreetMap')),
              ],
            ),
            const Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: DemandLegend(),
            ),
          ],
        ),
      ),
    );
  }
}
