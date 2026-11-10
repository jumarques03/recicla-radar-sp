import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/data/models/inspection.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';

/// Guarda as vistorias no aparelho (`shared_preferences`), para não se
/// perderem ao fechar o app. Sem servidor: elas ficam só neste aparelho.
class LocalInspectionRepository implements InspectionRepository {
  LocalInspectionRepository(this._prefs);

  /// O sufixo de versão permite mudar o formato no futuro sem quebrar quem já tem dados.
  static const String storageKey = 'inspections.v1';

  final SharedPreferences _prefs;

  @override
  Future<void> submit(Inspection inspection) async {
    final all = [inspection, ...await fetchAll()];
    await _prefs.setString(storageKey, jsonEncode([for (final item in all) item.toJson()]));
  }

  @override
  Future<List<Inspection>> fetchAll() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = <Inspection>[];
      for (final item in decoded) {
        try {
          list.add(Inspection.fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Um registro estragado não derruba os outros.
        }
      }
      return list..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (_) {
      // Dado corrompido: começa do zero em vez de travar o app.
      return const [];
    }
  }
}
