import 'package:flutter/foundation.dart';

import 'package:recicla_radar_sp/data/models/waste_material.dart';

/// Filtros globais da visão geral: período e material.
class FiltersProvider extends ChangeNotifier {
  static const List<int> periods = [7, 30, 90];

  int _periodDays = 30;
  WasteMaterial? _material;

  int get periodDays => _periodDays;

  /// `null` significa todos os materiais.
  WasteMaterial? get material => _material;

  void setPeriod(int days) {
    if (days == _periodDays) return;
    _periodDays = days;
    notifyListeners();
  }

  void setMaterial(WasteMaterial? material) {
    if (material == _material) return;
    _material = material;
    notifyListeners();
  }
}
