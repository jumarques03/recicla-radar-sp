import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(ReciclaRadarApp(prefs: prefs));
  await tester.pumpAndSettle();
}

void main() {
  const sizes = {
    'celular estreito': Size(360, 740),
    'tablet': Size(820, 1180),
  };

  for (final entry in sizes.entries) {
    testWidgets('login funciona em ${entry.key} com fonte grande', (tester) async {
      await pumpApp(tester, size: entry.value, textScale: 1.6);

      expect(find.text('Entrar'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Campos vazios mostram mensagens claras. Com fonte grande a tela rola.
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Digite seu e-mail.'), findsOneWidget);
      expect(find.text('Digite sua senha.'), findsOneWidget);
    });
  }

  testWidgets('senha errada mostra erro que diz o que fazer', (tester) async {
    await pumpApp(tester, size: sizes['celular estreito']!);

    await tester.enterText(find.byType(TextFormField).first, MockAuthRepository.demoEmail);
    await tester.enterText(find.byType(TextFormField).last, 'senha-errada');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.textContaining('E-mail ou senha incorretos'), findsOneWidget);
  });
}
