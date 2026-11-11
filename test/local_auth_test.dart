import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/core/utils/app_exception.dart';
import 'package:recicla_radar_sp/data/models/app_user.dart';
import 'package:recicla_radar_sp/data/repositories/local_auth_repository.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';

import 'fake_boundary_repository.dart';

Future<SharedPreferences> freshPrefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPreferences.getInstance();
}

void main() {
  test('a conta criada continua existindo depois de fechar e abrir o app', () async {
    final prefs = await freshPrefs();
    await LocalAuthRepository(prefs).register(
      name: 'Maria Lima',
      email: 'Maria@Exemplo.com ',
      password: 'minhasenha1',
      role: UserRole.manager,
    );

    // Um novo objeto sobre os mesmos dados do aparelho, como num app reaberto.
    final user = await LocalAuthRepository(prefs).signIn(email: 'maria@exemplo.com', password: 'minhasenha1');
    expect(user.name, 'Maria Lima');
    expect(user.role, UserRole.manager);
  });

  test('senha errada ou conta que não existe não entram', () async {
    final prefs = await freshPrefs();
    final repository = LocalAuthRepository(prefs);
    await repository.register(
      name: 'Maria Lima',
      email: 'maria@exemplo.com',
      password: 'minhasenha1',
      role: UserRole.manager,
    );

    await expectLater(
      repository.signIn(email: 'maria@exemplo.com', password: 'outra'),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      repository.signIn(email: 'ninguem@exemplo.com', password: 'minhasenha1'),
      throwsA(isA<AppException>()),
    );
  });

  test('e-mail repetido, ou o da conta de demonstração, não pode ser cadastrado de novo', () async {
    final repository = LocalAuthRepository(await freshPrefs());
    await repository.register(name: 'A', email: 'a@x.com', password: 'senha123', role: UserRole.inspector);

    await expectLater(
      repository.register(name: 'B', email: 'A@x.com', password: 'senha456', role: UserRole.inspector),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      repository.register(
        name: 'C',
        email: MockAuthRepository.demoEmail,
        password: 'senha456',
        role: UserRole.inspector,
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('a senha não fica guardada em texto no aparelho', () async {
    final prefs = await freshPrefs();
    await LocalAuthRepository(prefs).register(
      name: 'Maria Lima',
      email: 'maria@exemplo.com',
      password: 'minhasenha1',
      role: UserRole.manager,
    );

    expect(prefs.getString(LocalAuthRepository.storageKey), isNot(contains('minhasenha1')));
  });

  test('a conta de demonstração entra sem estar gravada, e dado estragado não derruba o app', () async {
    final prefs = await freshPrefs({LocalAuthRepository.storageKey: '{ não é json'});
    final repository = LocalAuthRepository(prefs);

    final user = await repository.signIn(
      email: MockAuthRepository.demoEmail,
      password: MockAuthRepository.demoPassword,
    );
    expect(user.name, 'Ana Souza');
    await expectLater(
      repository.signIn(email: 'maria@exemplo.com', password: 'x'),
      throwsA(isA<AppException>()),
    );
  });

  testWidgets('na tela de login, uma conta criada antes entra no app', (tester) async {
    final prefs = await freshPrefs();
    // O cadastro espera meio segundo de verdade; no teste de tela o relógio é de mentira,
    // então ele roda fora dele.
    await tester.runAsync(
      () => LocalAuthRepository(prefs).register(
        name: 'Maria Lima',
        email: 'maria@exemplo.com',
        password: 'minhasenha1',
        role: UserRole.manager,
      ),
    );
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ReciclaRadarApp(prefs: prefs, boundaryRepository: FakeBoundaryRepository()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'maria@exemplo.com');
    await tester.enterText(find.byType(TextFormField).last, 'minhasenha1');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.textContaining('Maria'), findsWidgets); // "Olá, Maria!" na visão geral
  });
}
