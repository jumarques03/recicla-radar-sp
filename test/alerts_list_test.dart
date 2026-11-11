import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/data/local/alert_status_store.dart';
import 'package:recicla_radar_sp/data/repositories/engine_alert_repository.dart';
import 'package:recicla_radar_sp/data/repositories/local_inspection_repository.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';

import 'fake_boundary_repository.dart';

Future<void> openAlertsTab(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ReciclaRadarApp(prefs: prefs, boundaryRepository: FakeBoundaryRepository()));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, MockAuthRepository.demoEmail);
  await tester.enterText(find.byType(TextFormField).last, MockAuthRepository.demoPassword);
  await tester.ensureVisible(find.text('Entrar'));
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await tester.tap(find.text('Alertas').last);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  test('os alertas vêm do mais grave para o menos grave e, na mesma gravidade, do mais antigo para o mais novo', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = EngineAlertRepository(SharedPrefsAlertStatusStore(prefs), LocalInspectionRepository(prefs));
    final alerts = await repository.fetchAlerts(fillThreshold: 60);
    expect(alerts.length, greaterThan(10));

    for (var i = 1; i < alerts.length; i++) {
      final before = alerts[i - 1];
      final current = alerts[i];
      expect(current.severity.index, lessThanOrEqualTo(before.severity.index));
      if (current.severity == before.severity) {
        expect(current.createdAt.isBefore(before.createdAt), isFalse, reason: '${before.id} antes de ${current.id}');
      }
    }
  });

  testWidgets('o aviso de "marcados como lidos" some sozinho', (tester) async {
    await openAlertsTab(tester);

    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pumpAndSettle();
    expect(find.textContaining('marcados como lidos'), findsOneWidget);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.textContaining('marcados como lidos'), findsNothing);
  });

  testWidgets('alerta resolvido sai da lista e fica numa seção que se abre e se fecha', (tester) async {
    await openAlertsTab(tester);

    // Resolve o primeiro alerta.
    await tester.tap(find.textContaining('deve encher').first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final scrollable = find.descendant(of: find.byType(ContentListView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Resolvido'), 300, scrollable: scrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolvido'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Fora da lista, com o aviso de quantos estão escondidos.
    expect(find.text('1 alerta resolvido ou descartado'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('1 alerta resolvido ou descartado'),
      300,
      scrollable: find.descendant(of: find.byType(ListView).hitTestable().first, matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Mostrar'), findsOneWidget);
    expect(find.text('Resolvido'), findsNothing); // nenhum card mostra o status "Resolvido"

    // Mostrar traz o alerta de volta; Esconder tira de novo.
    await tester.tap(find.text('Mostrar'));
    await tester.pumpAndSettle();
    expect(find.text('Esconder'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Resolvido'),
      300,
      scrollable: find.descendant(of: find.byType(ListView).hitTestable().first, matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Resolvido'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Esconder'),
      -300,
      scrollable: find.descendant(of: find.byType(ListView).hitTestable().first, matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.text('Esconder'));
    await tester.pumpAndSettle();
    expect(find.text('Mostrar'), findsOneWidget);
  });
}
