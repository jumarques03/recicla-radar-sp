import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:recicla_radar_sp/core/utils/app_exception.dart';
import 'package:recicla_radar_sp/data/models/city_boundaries.dart';
import 'package:recicla_radar_sp/data/osm/geojson_parser.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';

/// Busca o contorno de São Paulo e os limites dos distritos no OpenStreetMap
/// (serviço Nominatim), já simplificados para o celular.
///
/// A política de uso do Nominatim pede identificação do app e no máximo uma
/// requisição por segundo. Por isso as buscas são feitas em sequência.
class OsmBoundaryRepository implements BoundaryRepository {
  OsmBoundaryRepository({
    required this.districtIds,
    this.cityRelationId = 298285,
    http.Client? client,
    this.pauseBetweenRequests = const Duration(milliseconds: 1100),
  }) : _client = client ?? http.Client();

  /// Relações do OpenStreetMap dos distritos.
  final List<int> districtIds;

  /// Relação do município de São Paulo.
  final int cityRelationId;
  final Duration pauseBetweenRequests;
  final http.Client _client;

  static const String _userAgent =
      'ReciclaRadarSP/1.0 (https://github.com/jumarques03/recicla-radar-sp)';
  static const int _batchSize = 50;
  static const Duration _timeout = Duration(seconds: 25);
  static const String _failureMessage =
      'Não foi possível carregar os limites dos distritos. Confira a internet e tente de novo.';

  @override
  Future<CityBoundaries> fetchBoundaries() async {
    final ids = [cityRelationId, ...districtIds];
    final features = <OsmFeature>[];

    try {
      for (var start = 0; start < ids.length; start += _batchSize) {
        if (start > 0) await Future<void>.delayed(pauseBetweenRequests);
        final batch = ids.sublist(start, (start + _batchSize).clamp(0, ids.length));
        features.addAll(await _lookup(batch));
      }
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(_failureMessage);
    }

    final city = features.where((f) => f.osmId == cityRelationId).expand((f) => f.polygons);
    final districts = <String, DistrictShape>{
      for (final feature in features)
        if (feature.osmId != cityRelationId)
          '${feature.osmId}': DistrictShape(
            id: '${feature.osmId}',
            name: feature.name,
            polygons: feature.polygons,
          ),
    };
    if (districts.isEmpty) throw const AppException(_failureMessage);
    return CityBoundaries(city: city.toList(), districts: districts);
  }

  Future<List<OsmFeature>> _lookup(List<int> ids) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/lookup', {
      'osm_ids': ids.map((id) => 'R$id').join(','),
      'format': 'geojson',
      'polygon_geojson': '1',
      'polygon_threshold': '0.0005',
      'accept-language': 'pt-BR',
    });
    final response = await _client.get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout);
    if (response.statusCode != 200) throw const AppException(_failureMessage);
    return GeoJsonParser.parseFeatures(jsonDecode(utf8.decode(response.bodyBytes)));
  }
}
