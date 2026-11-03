import 'package:flutter/foundation.dart';

import 'package:recicla_radar_sp/data/models/app_user.dart';
import 'package:recicla_radar_sp/data/repositories/auth_repository.dart';

/// Sessão da pessoa usuária. Erros de [AuthRepository] sobem para a tela.
class SessionProvider extends ChangeNotifier {
  SessionProvider(this._repository);

  final AuthRepository _repository;
  AppUser? _user;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> signIn({required String email, required String password}) async {
    _user = await _repository.signIn(email: email, password: password);
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _user = await _repository.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    notifyListeners();
  }

  Future<void> requestPasswordReset(String email) => _repository.requestPasswordReset(email);

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    notifyListeners();
  }
}
