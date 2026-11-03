import 'package:flutter/foundation.dart';

import 'package:recicla_radar_sp/core/utils/app_exception.dart';

enum LoadStatus { idle, loading, error, ready }

/// Base para estados que carregam dados e precisam mostrar na tela
/// três situações: carregando, erro e pronto (com lista vazia ou não).
abstract class LoadableNotifier<T> extends ChangeNotifier {
  LoadStatus _status = LoadStatus.idle;
  T? _data;
  String? _error;
  bool _disposed = false;

  LoadStatus get status => _status;
  T? get data => _data;
  String? get error => _error;

  @protected
  Future<T> fetch();

  Future<void> load() async {
    if (_data == null) {
      _status = LoadStatus.loading;
      _error = null;
      _notify();
    }
    try {
      _data = await fetch();
      _status = LoadStatus.ready;
      _error = null;
    } on AppException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Não foi possível carregar agora. Confira sua internet e tente de novo.');
    }
    _notify();
  }

  @protected
  void replaceData(T value) {
    _data = value;
    _status = LoadStatus.ready;
    _notify();
  }

  void _fail(String message) {
    _error = message;
    if (_data == null) _status = LoadStatus.error;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
