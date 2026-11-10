import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';

import 'fake_boundary_repository.dart';

Future<void> pumpLoggedIn(WidgetTester tester, SharedPreferences prefs) async {
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

/// Número escrito no selo da aba Alertas (ou `null` se o selo está escondido).
int? badgeCount(WidgetTester tester) {
  final badge = tester
      .widgetList<Badge>(find.byType(Badge))
      .where((b) => b.isLabelVisible)
      .toList();
  if (badge.isEmpty) return null;
  return int.parse((badge.first.label! as Text).data!);
}

void main() {
  testWidgets('o selo conta os alertas novos e some ao marcar todos como vistos', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpLoggedIn(tester, prefs);

    final before = badgeCount(tester);
    expect(before, isNotNull);
    expect(before, greaterThan(0));

    await tester.tap(find.text('Alertas').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Novo'), findsWidgets);

    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pumpAndSettle();
    expect(find.textContaining('marcados como vistos'), findsOneWidget);
    expect(badgeCount(tester), isNull);
    expect(find.text('Novo'), findsNothing);

    // Desfazer devolve o selo.
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(badgeCount(tester), before);
  });

  testWidgets('abrir um alerta o marca como visto', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpLoggedIn(tester, prefs);
    final before = badgeCount(tester)!;

    await tester.tap(find.text('Alertas').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.ensureVisible(find.textContaining('deve encher').first);
    await tester.tap(find.textContaining('deve encher').first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(badgeCount(tester), before - 1);
  });
}
