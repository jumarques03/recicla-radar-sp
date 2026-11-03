import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

class BinsProvider extends LoadableNotifier<List<Bin>> {
  BinsProvider(this._repository);

  final BinRepository _repository;

  @override
  Future<List<Bin>> fetch() => _repository.fetchBins();

  Bin? byId(String id) {
    for (final bin in data ?? const <Bin>[]) {
      if (bin.id == id) return bin;
    }
    return null;
  }
}
