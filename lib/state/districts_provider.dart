import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

class DistrictsProvider extends LoadableNotifier<List<District>> {
  DistrictsProvider(this._repository);

  final DistrictRepository _repository;

  @override
  Future<List<District>> fetch() => _repository.fetchDistricts();

  /// Posição (1 = maior demanda) do distrito no ranking.
  int rankOf(District district) {
    final sorted = [...?data]..sort((a, b) => b.demandIndex.compareTo(a.demandIndex));
    return sorted.indexWhere((item) => item.id == district.id) + 1;
  }
}
