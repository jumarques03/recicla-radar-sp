import 'package:recicla_radar_sp/data/models/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> requestPasswordReset(String email);

  Future<void> signOut();
}
