import 'package:shared_preferences/shared_preferences.dart';

/// Guarda no aparelho quais alertas a pessoa já viu, para o número de
/// alertas novos (o selo da aba Alertas) não voltar a cada vez que o app abre.
abstract interface class AlertSeenStore {
  Set<String> load();

  Future<void> save(Set<String> seenIds);
}

class SharedPrefsAlertSeenStore implements AlertSeenStore {
  SharedPrefsAlertSeenStore(this._prefs);

  /// O sufixo de versão permite mudar o formato no futuro sem quebrar quem já tem dados.
  static const String storageKey = 'alertsSeen.v1';

  final SharedPreferences _prefs;

  @override
  Set<String> load() => (_prefs.getStringList(storageKey) ?? const <String>[]).toSet();

  @override
  Future<void> save(Set<String> seenIds) => _prefs.setStringList(storageKey, seenIds.toList());
}
