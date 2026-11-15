import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/data/models/alert.dart';

/// Guarda no aparelho o histórico de decisões de cada alerta (quem assumiu,
/// que equipe foi alocada, como foi concluído...), para não se perder ao fechar o app.
abstract interface class AlertHistoryStore {
  /// Decisões por id de alerta, da mais antiga para a mais recente.
  Map<String, List<AlertEvent>> load();

  Future<void> add(String alertId, AlertEvent event);
}

class SharedPrefsAlertHistoryStore implements AlertHistoryStore {
  SharedPrefsAlertHistoryStore(this._prefs);

  /// O sufixo de versão permite mudar o formato no futuro sem quebrar quem já tem dados.
  static const String storageKey = 'alertHistory.v1';

  final SharedPreferences _prefs;

  @override
  Map<String, List<AlertEvent>> load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          entry.key: [
            for (final item in entry.value as List) AlertEvent.fromJson(item as Map<String, dynamic>),
          ],
      };
    } catch (_) {
      // Dado corrompido: começa do zero em vez de travar o app.
      return {};
    }
  }

  @override
  Future<void> add(String alertId, AlertEvent event) async {
    final current = load();
    current[alertId] = [...?current[alertId], event];
    await _prefs.setString(
      storageKey,
      jsonEncode({
        for (final entry in current.entries) entry.key: [for (final e in entry.value) e.toJson()],
      }),
    );
  }
}

/// Versão que não grava em lugar nenhum, para testes.
class MemoryAlertHistoryStore implements AlertHistoryStore {
  final Map<String, List<AlertEvent>> _events = {};

  @override
  Map<String, List<AlertEvent>> load() => {
        for (final entry in _events.entries) entry.key: [...entry.value],
      };

  @override
  Future<void> add(String alertId, AlertEvent event) async {
    _events[alertId] = [...?_events[alertId], event];
  }
}
