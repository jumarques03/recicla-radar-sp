import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';
import 'package:recicla_radar_sp/state/settings_provider.dart';

import 'fake_boundary_repository.dart';

/// "Abre o app": monta tudo do zero sobre os mesmos dados do aparelho e faz login.
Future<void> openApp(WidgetTester tester, SharedPreferences prefs) async {
  tester.view.physicalSize = const Size(390, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ReciclaRadarApp(prefs: prefs, boundaryRepository: FakeBoundaryRepository()));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, MockAuthRepository.demoEmail);
  await tester.enterText(find.byType(TextFormField).last, MockAuthRepository.demoPassword);
  await tester.ensureVisible(find.text('Entrar'));
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// "Fecha o app": descarta toda a árvore de widgets. Só o que está no aparelho sobrevive.
Future<void> closeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}

int? badgeCount(WidgetTester tester) {
  final badge = tester.widgetList<Badge>(find.byType(Badge)).where((b) => b.isLabelVisible).toList();
  return badge.isEmpty ? null : int.parse((badge.first.label! as Text).data!);
}

/// Rola o detalhe do alerta até [target] aparecer.
Future<void> scrollDetailTo(WidgetTester tester, Finder target) async {
  final scrollable = find.descendant(of: find.byType(ContentListView), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(target, 300, scrollable: scrollable);
  await tester.pumpAndSettle();
}

Future<void> openFirstAlert(WidgetTester tester) async {
  await tester.tap(find.text('Alertas').last);
  await tester.pumpAndSettle(const Duration(seconds: 1));
  await tester.tap(find.textContaining('deve encher').first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  testWidgets('o status de um alerta continua depois de fechar e abrir o app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await openApp(tester, prefs);
    await openFirstAlert(tester);

    await scrollDetailTo(tester, find.text('Em análise'));
    await tester.tap(find.text('Em análise'));
    await tester.pumpAndSettle();
    expect(find.text('Em análise (atual)'), findsOneWidget);

    await closeApp(tester);
    await openApp(tester, prefs);
    await openFirstAlert(tester);
    await scrollDetailTo(tester, find.text('Em análise (atual)'));
    expect(find.text('Em análise (atual)'), findsOneWidget);
  });

  testWidgets('alertas lidos e as configurações continuam depois de reabrir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await openApp(tester, prefs);
    final before = badgeCount(tester)!;

    // Marca um alerta como lido pelo botão do card.
    await tester.tap(find.text('Alertas').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Marcar como lido').first);
    await tester.pumpAndSettle();
    expect(badgeCount(tester), before - 1);

    // Muda configurações, como a tela de Configurações faz.
    final settings = SettingsProvider(prefs);
    await settings.setTextScale(1.2);
    await settings.setHighContrast(true);

    await closeApp(tester);
    await openApp(tester, prefs);

    expect(badgeCount(tester), before - 1);
    final reopened = SettingsProvider(prefs);
    expect(reopened.textScale, 1.2);
    expect(reopened.highContrast, isTrue);
  });

  test('o 100% das Configurações corresponde a 85% da fonte padrão', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider(await SharedPreferences.getInstance());
    expect(settings.textScale, 1.0);
    expect(SettingsProvider.baseTextScale, 0.85);
  });
}
