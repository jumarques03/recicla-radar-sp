import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';

Future<void> signIn(WidgetTester tester, Size size, double textScale) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(ReciclaRadarApp(prefs: prefs));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, MockAuthRepository.demoEmail);
  await tester.enterText(find.byType(TextFormField).last, MockAuthRepository.demoPassword);
  await tester.ensureVisible(find.text('Entrar'));
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// Rola a lista visível até o texto aparecer (as outras abas ficam fora da tela).
Future<void> scrollTo(WidgetTester tester, String text) {
  // A tela aberta fica por último na árvore; as outras abas ficam fora da tela.
  final list = find.descendant(
    of: find.byType(ListView, skipOffstage: true).last,
    matching: find.byType(Scrollable),
  );
  return tester.scrollUntilVisible(find.text(text), 300, scrollable: list.first);
}

void main() {
  const cases = {
    'celular (360 px, fonte 1.0)': (Size(360, 740), 1.0),
    'celular (360 px, fonte grande)': (Size(360, 800), 1.5),
    'tablet (820 px)': (Size(820, 1180), 1.0),
  };

  for (final entry in cases.entries) {
    testWidgets('percorre as telas em ${entry.key}', (tester) async {
      await signIn(tester, entry.value.$1, entry.value.$2);

      // Visão geral.
      expect(find.text('Visão geral'), findsWidgets);
      expect(find.textContaining('Olá, Ana'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Alertas.
      await tester.tap(find.text('Alertas').last);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Os alertas apoiam, mas não substituem, a decisão humana.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Detalhe do alerta.
      await tester.ensureVisible(find.textContaining('deve encher').first);
      await tester.tap(find.textContaining('deve encher').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await scrollTo(tester, 'Qual é a sua decisão?');
      expect(find.text('Qual é a sua decisão?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Lixeiras (lista) e detalhe.
      await tester.tap(find.text('Lixeiras').last);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Lixeira ').first);
      await tester.tap(find.textContaining('Lixeira ').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await scrollTo(tester, 'Registrar vistoria');
      expect(find.text('Registrar vistoria'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Formulário de vistoria abre com a lixeira já preenchida.
      await tester.tap(find.text('Registrar vistoria'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await scrollTo(tester, 'Enviar vistoria');
      expect(find.text('Enviar vistoria'), findsOneWidget);
      await tester.tap(find.text('Enviar vistoria'));
      await tester.pumpAndSettle();
      expect(find.text('Confira os campos marcados em vermelho.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
