import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/data/models/alert.dart';

/// Guarda no aparelho a decisão que a pessoa tomou sobre cada alerta
/// (em análise, resolvido ou descartado), para ela não se perder ao fechar o app.
abstract interface class AlertStatusStore {
  /// Status salvos por id de alerta. Alertas "abertos" não são guardados.
  Map<String, AlertStatus> load();

  Future<void> save(String alertId, AlertStatus status);
}

/// Usa o `shared_preferences`, o equivalente do Flutter ao AsyncStorage.
class SharedPrefsAlertStatusStore implements AlertStatusStore {
  SharedPrefsAlertStatusStore(this._prefs);

  /// O sufixo de versão permite mudar o formato no futuro sem quebrar quem já tem dados.
  static const String storageKey = 'alertStatuses.v1';

  final SharedPreferences _prefs;

  @override
  Map<String, AlertStatus> load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      return {
        for (final entry in decoded.entries) entry.key: ?_parse(entry.value),
      };
    } catch (_) {
      // Dado corrompido: começa do zero em vez de travar o app.
      return {};
    }
  }

  @override
  Future<void> save(String alertId, AlertStatus status) async {
    final current = load();
    if (status == AlertStatus.open) {
      current.remove(alertId);
    } else {
      current[alertId] = status;
    }
    await _prefs.setString(
      storageKey,
      jsonEncode({for (final entry in current.entries) entry.key: entry.value.name}),
    );
  }

  AlertStatus? _parse(Object? name) {
    for (final status in AlertStatus.values) {
      if (status.name == name) return status;
    }
    return null;
  }
}
