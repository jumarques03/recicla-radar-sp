import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/disposal_point.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

/// Lixeiras e os pontos de descarte onde elas estão instaladas.
class BinsProvider extends LoadableNotifier<List<Bin>> {
  BinsProvider(this._repository);

  final BinRepository _repository;
  List<DisposalPoint> _points = const [];

  List<DisposalPoint> get points => _points;

  @override
  Future<List<Bin>> fetch() async {
    final bins = await _repository.fetchBins();
    _points = await _repository.fetchDisposalPoints();
    return bins;
  }

  Bin? byId(String id) {
    for (final bin in data ?? const <Bin>[]) {
      if (bin.id == id) return bin;
    }
    return null;
  }
}
