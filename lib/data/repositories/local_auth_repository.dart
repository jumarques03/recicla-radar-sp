import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/core/utils/app_exception.dart';
import 'package:recicla_radar_sp/data/models/app_user.dart';
import 'package:recicla_radar_sp/data/repositories/auth_repository.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';

/// Contas guardadas no aparelho (`shared_preferences`), para continuarem
/// existindo depois de fechar o app. Não há servidor: é só para demonstração.
///
/// A senha não é guardada em texto: fica só um resumo (SHA-256 com um "sal"
/// aleatório por conta). A conta de demonstração já vem pronta e não é gravada.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs, {Random? random}) : _random = random ?? Random.secure();

  /// O sufixo de versão permite mudar o formato sem quebrar quem já tem contas.
  static const String storageKey = 'accounts.v1';

  final SharedPreferences _prefs;
  final Random _random;

  static const AppUser _demoUser = AppUser(
    name: 'Ana Souza',
    email: MockAuthRepository.demoEmail,
    role: UserRole.inspector,
  );

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await _wait();
    final key = _normalize(email);
    const failure = AppException('E-mail ou senha incorretos. Confira os dados e tente de novo.');

    if (key == MockAuthRepository.demoEmail) {
      if (password != MockAuthRepository.demoPassword) throw failure;
      return _demoUser;
    }

    final account = _load()[key];
    if (account == null || account['hash'] != _hash(password, account['salt'] as String)) {
      throw failure;
    }
    return AppUser(
      name: account['name'] as String,
      email: key,
      role: UserRole.values.byName(account['role'] as String),
    );
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await _wait();
    final key = _normalize(email);
    final accounts = _load();
    if (key == MockAuthRepository.demoEmail || accounts.containsKey(key)) {
      throw const AppException(
        'Já existe uma conta com este e-mail. Tente entrar ou recuperar a senha.',
      );
    }

    final salt = _newSalt();
    accounts[key] = {
      'name': name.trim(),
      'role': role.name,
      'salt': salt,
      'hash': _hash(password, salt),
    };
    await _prefs.setString(storageKey, jsonEncode(accounts));
    return AppUser(name: name.trim(), email: key, role: role);
  }

  @override
  Future<void> requestPasswordReset(String email) => _wait();

  @override
  Future<void> signOut() => _wait();

  /// Contas gravadas, por e-mail. Dado estragado vira "nenhuma conta" em vez de quebrar o app.
  Map<String, Map<String, dynamic>> _load() {
    try {
      final decoded = jsonDecode(_prefs.getString(storageKey) ?? '{}') as Map<String, dynamic>;
      return {for (final entry in decoded.entries) entry.key: entry.value as Map<String, dynamic>};
    } catch (_) {
      return {};
    }
  }

  String _normalize(String email) => email.trim().toLowerCase();

  String _newSalt() => base64UrlEncode([for (var i = 0; i < 16; i++) _random.nextInt(256)]);

  String _hash(String password, String salt) => sha256.convert(utf8.encode('$salt:$password')).toString();

  Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 500));
}
