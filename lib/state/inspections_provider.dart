import 'package:recicla_radar_sp/data/models/inspection.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

/// Vistorias registradas neste aparelho.
class InspectionsProvider extends LoadableNotifier<List<Inspection>> {
  InspectionsProvider(this._repository);

  final InspectionRepository _repository;

  @override
  Future<List<Inspection>> fetch() => _repository.fetchAll();

  /// Vistorias de uma lixeira, da mais recente para a mais antiga.
  List<Inspection> forBin(String binId) =>
      (data ?? const <Inspection>[]).where((item) => item.binId == binId).toList();

  Future<void> submit(Inspection inspection) async {
    await _repository.submit(inspection);
    replaceData([inspection, ...data ?? const <Inspection>[]]);
  }
}
