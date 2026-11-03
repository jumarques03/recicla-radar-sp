import 'dart:async';

import 'package:recicla_radar_sp/data/models/overview_summary.dart';
import 'package:recicla_radar_sp/data/models/waste_material.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/filters_provider.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

/// Resumo da visão geral. Recarrega sozinho quando os filtros mudam.
class OverviewProvider extends LoadableNotifier<OverviewSummary> {
  OverviewProvider(this._repository);

  final OverviewRepository _repository;
  int _days = 30;
  WasteMaterial? _material;
  bool _started = false;

  void applyFilters(FiltersProvider filters) {
    final changed = filters.periodDays != _days || filters.material != _material;
    if (_started && !changed) return;
    _started = true;
    _days = filters.periodDays;
    _material = filters.material;
    // Adiado para não notificar durante a construção da árvore de widgets.
    scheduleMicrotask(load);
  }

  @override
  Future<OverviewSummary> fetch() => _repository.fetchSummary(days: _days, material: _material);
}
