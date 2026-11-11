import 'package:recicla_radar_sp/data/local/boundary_cache.dart';
import 'package:recicla_radar_sp/data/models/city_boundaries.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';

/// Usa o contorno guardado no aparelho e só vai à internet na primeira vez
/// (ou se o arquivo sumiu). Os limites dos distritos quase nunca mudam, e assim
/// o mapa abre rápido, funciona sem internet e o Nominatim recebe menos pedidos.
class CachedBoundaryRepository implements BoundaryRepository {
  CachedBoundaryRepository({required this.source, required this.cache});

  final BoundaryRepository source;
  final BoundaryCache cache;

  @override
  Future<CityBoundaries> fetchBoundaries() async {
    final saved = await cache.read();
    if (saved != null) return saved;

    final fresh = await source.fetchBoundaries();
    await cache.write(fresh);
    return fresh;
  }
}
