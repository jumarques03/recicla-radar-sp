import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';
import 'package:recicla_radar_sp/features/alerts/alert_card.dart';

import 'fake_boundary_repository.dart';

/// Tamanhos de tela (largura, altura, fonte) que o app precisa aguentar.
const sizes = <String, (double, double, double)>{
  'celular pequeno 320x640': (320, 640, 1.0),
  'celular 360x740': (360, 740, 1.0),
  'celular grande 412x915': (412, 915, 1.0),
  'celular com fonte grande 360x740': (360, 740, 1.6),
  'celular deitado 800x360': (800, 360, 1.0),
  'tablet em pé 768x1024': (768, 1024, 1.0),
  'tablet com fonte grande 768x1024': (768, 1024, 1.5),
  'tablet deitado 1024x768': (1024, 768, 1.0),
  'computador 1366x768': (1366, 768, 1.0),
};

Future<void> signIn(WidgetTester tester, double width, double height, double textScale) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(ReciclaRadarApp(prefs: prefs, boundaryRepository: FakeBoundaryRepository()));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, MockAuthRepository.demoEmail);
  await tester.enterText(find.byType(TextFormField).last, MockAuthRepository.demoPassword);
  await tester.ensureVisible(find.text('Entrar'));
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// Texto do item do menu (barra embaixo ou menu lateral).
Finder navItem(String label) => find.descendant(
      of: find.byWidgetPredicate((w) => w is NavigationBar || w is NavigationRail),
      matching: find.text(label),
    );

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(navItem(label).last);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Rola a lista da tela aberta até o fim, em passos, conferindo se nada estoura.
Future<void> scrollThrough(WidgetTester tester) async {
  final lists = find.byType(ListView).hitTestable();
  if (lists.evaluate().isEmpty) return;
  for (var i = 0; i < 5; i++) {
    await tester.drag(lists.first, const Offset(0, -500));
    await tester.pumpAndSettle();
  }
}

void noErrors(WidgetTester tester, String where) {
  expect(tester.takeException(), isNull, reason: 'erro de layout em: $where');
}

void main() {
  for (final entry in sizes.entries) {
    final (width, height, textScale) = entry.value;

    testWidgets('percorre o app em ${entry.key}', (tester) async {
      await signIn(tester, width, height, textScale);

      // Menu: barra embaixo no celular em pé, menu lateral nas telas largas.
      final wide = width >= Breakpoints.medium;
      expect(find.byType(NavigationRail), wide ? findsOneWidget : findsNothing);
      expect(find.byType(NavigationBar), wide ? findsNothing : findsOneWidget);

      await scrollThrough(tester);
      noErrors(tester, 'visão geral');

      await openTab(tester, 'Demanda');
      noErrors(tester, 'mapa de demanda');
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      await scrollThrough(tester);
      noErrors(tester, 'lista de distritos');

      await openTab(tester, 'Lixeiras');
      noErrors(tester, 'mapa de lixeiras');
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      await scrollThrough(tester);
      noErrors(tester, 'lista de lixeiras');

      await openTab(tester, 'Alertas');
      noErrors(tester, 'lista de alertas');

      // Em tela larga os cartões não esticam de ponta a ponta.
      final cardWidth = tester.getSize(find.byType(AlertCard).first).width;
      expect(cardWidth, lessThanOrEqualTo(Breakpoints.contentMax));
      if (width <= 400) expect(cardWidth, greaterThan(width * 0.8)); // celular: usa a largura

      Scrollable.ensureVisible(tester.element(find.textContaining('deve encher').first), alignment: 0.4);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('deve encher').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      noErrors(tester, 'detalhe do alerta');
      await scrollThrough(tester);
      noErrors(tester, 'detalhe do alerta, ao rolar');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await scrollThrough(tester);
      noErrors(tester, 'lista de alertas, ao rolar');

      // Do alerta para a lixeira, e da lixeira para o formulário de vistoria.
      await tester.drag(find.byType(ListView).hitTestable().first, const Offset(0, 4000));
      await tester.pumpAndSettle();
      Scrollable.ensureVisible(tester.element(find.textContaining('deve encher').first), alignment: 0.4);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('deve encher').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.scrollUntilVisible(
        find.text('Ver a lixeira'),
        200,
        scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first,
      );
      Scrollable.ensureVisible(tester.element(find.text('Ver a lixeira')), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver a lixeira'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      noErrors(tester, 'detalhe da lixeira');
      await scrollThrough(tester);
      noErrors(tester, 'detalhe da lixeira, ao rolar');

      await tester.scrollUntilVisible(
        find.text('Registrar vistoria'),
        300,
        scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first,
      );
      Scrollable.ensureVisible(tester.element(find.text('Registrar vistoria')), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar vistoria'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      noErrors(tester, 'formulário de vistoria');
      await scrollThrough(tester);
      noErrors(tester, 'formulário de vistoria, ao rolar');

      // Configurações: volta do formulário e do detalhe da lixeira até uma aba.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Configurações').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      noErrors(tester, 'configurações');
      await scrollThrough(tester);
      noErrors(tester, 'configurações, ao rolar');
    });
  }

  testWidgets('em tela larga os dois gráficos da visão geral ficam lado a lado', (tester) async {
    await signIn(tester, 1366, 768, 1.0);
    final list = find.byType(ListView).hitTestable().first;
    for (var i = 0; i < 6; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    final bar = tester.getTopLeft(find.text('Quilos por material'));
    final pie = tester.getTopLeft(find.text('Participação de cada material'));
    expect((bar.dy - pie.dy).abs(), lessThan(4)); // mesma altura = lado a lado
    expect(pie.dx, greaterThan(bar.dx));
  });

  testWidgets('no celular em pé os gráficos ficam um embaixo do outro', (tester) async {
    await signIn(tester, 360, 740, 1.0);
    final list = find.byType(ListView).hitTestable().first;
    for (var i = 0; i < 6; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    final bar = tester.getTopLeft(find.text('Quilos por material'));
    final pie = tester.getTopLeft(find.text('Participação de cada material'));
    expect(pie.dy, greaterThan(bar.dy));
  });

  testWidgets('com letra grande a faixa de aviso e os filtros rolam junto com os alertas', (tester) async {
    await signIn(tester, 360, 740, 1.6);
    await openTab(tester, 'Alertas');
    final banner = find.text('Os alertas apoiam, mas não substituem, a decisão humana.');
    expect(banner, findsOneWidget);

    final before = tester.getTopLeft(banner).dy;
    await tester.drag(find.byType(ListView).hitTestable().first, const Offset(0, -300));
    await tester.pumpAndSettle();
    // Rolou para fora da tela (ou subiu): não fica fixo ocupando espaço.
    expect(find.text('Os alertas apoiam, mas não substituem, a decisão humana.').hitTestable().evaluate().isEmpty ||
        tester.getTopLeft(banner).dy < before, isTrue);
  });
}
