import 'package:recicla_radar_sp/core/utils/app_exception.dart';
import 'package:recicla_radar_sp/data/models/app_user.dart';
import 'package:recicla_radar_sp/data/repositories/auth_repository.dart';

/// Login simulado, só para demonstração. Não há servidor nem segurança real.
class MockAuthRepository implements AuthRepository {
  /// Conta de demonstração.
  static const String demoEmail = 'fiscal@reciclaradar.sp';
  static const String demoPassword = 'senha123';

  final Map<String, ({AppUser user, String password})> _accounts = {
    demoEmail: (
      user: const AppUser(
        name: 'Ana Souza',
        email: demoEmail,
        role: UserRole.inspector,
      ),
      password: demoPassword,
    ),
  };

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await _wait();
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AppException(
        'E-mail ou senha incorretos. Confira os dados e tente de novo.',
      );
    }
    return account.user;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await _wait();
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AppException(
        'Já existe uma conta com este e-mail. Tente entrar ou recuperar a senha.',
      );
    }
    final user = AppUser(name: name.trim(), email: key, role: role);
    _accounts[key] = (user: user, password: password);
    return user;
  }

  @override
  Future<void> requestPasswordReset(String email) => _wait();

  @override
  Future<void> signOut() => _wait();

  Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 500));
}
