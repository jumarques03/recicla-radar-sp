import 'package:recicla_radar_sp/data/models/city_boundaries.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

/// Contorno de São Paulo e limites dos distritos. Os mapas funcionam mesmo
/// sem ele; quando chega, o contorno aparece por cima.
class BoundariesProvider extends LoadableNotifier<CityBoundaries> {
  BoundariesProvider(this._repository);

  final BoundaryRepository _repository;

  @override
  Future<CityBoundaries> fetch() => _repository.fetchBoundaries();

  /// Limites prontos para desenhar, ou `null` enquanto carrega ou se falhou.
  CityBoundaries? get boundaries => status == LoadStatus.ready ? data : null;
}
