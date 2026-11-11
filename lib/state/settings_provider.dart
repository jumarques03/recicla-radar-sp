import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências salvas no aparelho: tema, tamanho da fonte, limiar e consentimento.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs)
      : _themeMode = _readThemeMode(_prefs),
        _textScale = _prefs.getDouble(_textScaleKey) ?? 1.0,
        _fillThreshold = _prefs.getInt(_thresholdKey) ?? 80,
        _consent = _prefs.getBool(_consentKey) ?? false,
        _highContrast = _prefs.getBool(_highContrastKey) ?? false;

  static const String _themeKey = 'themeMode';
  static const String _textScaleKey = 'textScale';
  static const String _thresholdKey = 'fillThreshold';
  static const String _consentKey = 'consent';
  static const String _highContrastKey = 'highContrast';

  /// O texto do app é desenhado em 85% do tamanho padrão; a opção de 100% nas
  /// Configurações corresponde a esse tamanho.
  static const double baseTextScale = 0.85;

  static const double minTextScale = 0.9;
  static const double maxTextScale = 1.5;

  final SharedPreferences _prefs;
  ThemeMode _themeMode;
  double _textScale;
  int _fillThreshold;
  bool _consent;
  bool _highContrast;

  ThemeMode get themeMode => _themeMode;

  /// Multiplicador aplicado sobre o tamanho de fonte do sistema.
  double get textScale => _textScale;

  /// Enchimento (%) a partir do qual um alerta deve ser sugerido.
  int get fillThreshold => _fillThreshold;
  bool get consent => _consent;

  /// Cores mais fortes e bordas mais grossas, para ler melhor.
  bool get highContrast => _highContrast;

  static ThemeMode _readThemeMode(SharedPreferences prefs) {
    final name = prefs.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_themeKey, mode.name);
  }

  Future<void> setTextScale(double value) async {
    _textScale = value.clamp(minTextScale, maxTextScale);
    notifyListeners();
    await _prefs.setDouble(_textScaleKey, _textScale);
  }

  Future<void> setFillThreshold(int value) async {
    _fillThreshold = value;
    notifyListeners();
    await _prefs.setInt(_thresholdKey, value);
  }

  Future<void> setConsent(bool value) async {
    _consent = value;
    notifyListeners();
    await _prefs.setBool(_consentKey, value);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    await _prefs.setBool(_highContrastKey, value);
  }
}
