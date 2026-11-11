import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/data/local/alert_status_store.dart';
import 'package:recicla_radar_sp/data/mock/mock_data.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/inspection.dart';
import 'package:recicla_radar_sp/data/repositories/engine_alert_repository.dart';
import 'package:recicla_radar_sp/data/repositories/local_inspection_repository.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';
import 'package:recicla_radar_sp/domain/alert_engine.dart';
import 'package:recicla_radar_sp/domain/inspection_rule.dart';

import 'fake_boundary_repository.dart';

Inspection inspection({
  String id = 'i1',
  String binId = 'bin-01',
  OccurrenceType type = OccurrenceType.full,
  InspectionSeverity severity = InspectionSeverity.medium,
  bool needsAction = false,
  String? author,
  DateTime? at,
}) =>
    Inspection(
      id: id,
      binId: binId,
      type: type,
      severity: severity,
      description: 'Descrição de teste da vistoria',
      dateTime: at ?? MockData.now.subtract(const Duration(hours: 3)),
      needsAction: needsAction,
      authorName: author,
    );

Future<SharedPreferences> freshPrefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPreferences.getInstance();
}

void main() {
  group('LocalInspectionRepository', () {
    test('guarda as vistorias e devolve depois de "fechar e abrir" o app, da mais recente para a mais antiga', () async {
      final prefs = await freshPrefs();
      final first = LocalInspectionRepository(prefs);
      final older = inspection(id: 'a', at: DateTime(2026, 11, 1, 10));
      final newer = inspection(id: 'b', at: DateTime(2026, 11, 5, 10), author: 'Ana Souza');
      await first.submit(older);
      await first.submit(newer);

      final reopened = await LocalInspectionRepository(prefs).fetchAll();
      expect(reopened.map((i) => i.id), ['b', 'a']);
      expect(reopened.first.authorName, 'Ana Souza');
      expect(reopened.last.authorName, isNull);
      expect(reopened.first.type, OccurrenceType.full);
    });

    test('dado corrompido ou um registro estragado não derrubam o app', () async {
      final broken = await freshPrefs({LocalInspectionRepository.storageKey: 'não é json'});
      expect(await LocalInspectionRepository(broken).fetchAll(), isEmpty);

      final good = inspection(id: 'ok').toJson();
      final mixed = await freshPrefs({
        LocalInspectionRepository.storageKey: jsonEncode([good, {'id': 'quebrado'}]),
      });
      expect((await LocalInspectionRepository(mixed).fetchAll()).map((i) => i.id), ['ok']);
    });
  });

  group('InspectionRule', () {
    const rule = InspectionRule();
    final now = MockData.now;

    test('gravidade alta com pedido de coleta ou reparo é crítica; sem pedido é alta', () {
      expect(
        rule.evaluate(inspection(severity: InspectionSeverity.high, needsAction: true), now)!.severity,
        AlertSeverity.critical,
      );
      expect(
        rule.evaluate(inspection(severity: InspectionSeverity.high), now)!.severity,
        AlertSeverity.high,
      );
    });

    test('lixeira danificada ou vandalizada gera alerta médio, mesmo com gravidade baixa', () {
      for (final type in [OccurrenceType.damaged, OccurrenceType.vandalized]) {
        final hit = rule.evaluate(inspection(type: type, severity: InspectionSeverity.low), now);
        expect(hit!.severity, AlertSeverity.medium);
      }
    });

    test('vistoria comum, ou com mais de 7 dias, não gera alerta', () {
      expect(rule.evaluate(inspection(), now), isNull);
      expect(
        rule.evaluate(
          inspection(severity: InspectionSeverity.high, at: now.subtract(const Duration(days: 8))),
          now,
        ),
        isNull,
      );
    });
  });

  group('alerta gerado pela vistoria', () {
    List<Alert> alertsWith(List<Inspection> inspections) => const AlertEngine()
        .run(AlertEngineInput(
          now: MockData.now,
          bins: MockData.bins,
          readingsByBin: MockData.readingsByBin,
          districts: MockData.districts,
          fillThreshold: 80,
          inspections: inspections,
        ))
        .where((a) => a.type == AlertType.inspection)
        .toList();

    test('vistoria grave vira alerta ligado à lixeira e ao distrito dela', () {
      final bin = MockData.bins.first;
      final alerts = alertsWith([
        inspection(
          binId: bin.id,
          type: OccurrenceType.damaged,
          severity: InspectionSeverity.high,
          needsAction: true,
        ),
      ]);

      expect(alerts, hasLength(1));
      final alert = alerts.single;
      expect(alert.id, 'inspection:i1');
      expect(alert.severity, AlertSeverity.critical);
      expect(alert.confidence, Confidence.high);
      expect(alert.binId, bin.id);
      expect(alert.districtId, bin.districtId);
      expect(alert.title, contains(bin.name));
    });

    test('vistoria anônima não mostra nome; com consentimento mostra', () {
      final anonymous = alertsWith([inspection(type: OccurrenceType.damaged)]).single;
      final named = alertsWith([inspection(type: OccurrenceType.damaged, author: 'Ana Souza')]).single;
      expect(anonymous.detected, startsWith('Um fiscal registrou'));
      expect(anonymous.detected, isNot(contains('Ana')));
      expect(named.detected, startsWith('Ana Souza registrou'));
    });

    test('vistoria sem problema não gera alerta, e o repositório inclui as vistorias salvas', () async {
      expect(alertsWith([inspection()]), isEmpty);

      final prefs = await freshPrefs();
      final inspections = LocalInspectionRepository(prefs);
      final repository = EngineAlertRepository(SharedPrefsAlertStatusStore(prefs), inspections);
      expect((await repository.fetchAlerts(fillThreshold: 80)).any((a) => a.type == AlertType.inspection), isFalse);

      await inspections.submit(inspection(id: 'grave', type: OccurrenceType.vandalized));
      final alerts = await repository.fetchAlerts(fillThreshold: 80);
      expect(alerts.where((a) => a.id == 'inspection:grave'), hasLength(1));
    });
  });

  group('tela de vistoria', () {
    Future<SharedPreferences> openInspectionForm(WidgetTester tester, {bool consent = false}) async {
      final prefs = await freshPrefs({if (consent) 'consent': true});
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

      await tester.tap(find.text('Lixeiras').last);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Lixeira ').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.scrollUntilVisible(
        find.text('Registrar vistoria'),
        300,
        scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first,
      );
      await tester.ensureVisible(find.text('Registrar vistoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar vistoria'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      return prefs;
    }

    Future<void> fillAndSave(WidgetTester tester) async {
      await tester.tap(find.text('O que aconteceu?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lixeira danificada').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Tampa quebrada e lixo espalhado');
      // Ao digitar, a tela rola até o campo; espera terminar antes de tocar no próximo.
      await tester.pumpAndSettle();
      await tester.tap(find.text('Data e hora'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolher'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolher'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Salvar vistoria'),
        300,
        scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first,
      );
      await tester.ensureVisible(find.text('Salvar vistoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar vistoria'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    testWidgets('salva a vistoria no aparelho, anônima quando não há consentimento, e avisa do alerta', (tester) async {
      final prefs = await openInspectionForm(tester);
      expect(find.textContaining('de forma anônima'), findsOneWidget);

      await fillAndSave(tester);
      expect(find.textContaining('gerou um alerta'), findsOneWidget);
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();

      final saved = await LocalInspectionRepository(prefs).fetchAll();
      expect(saved, hasLength(1));
      expect(saved.single.type, OccurrenceType.damaged);
      expect(saved.single.authorName, isNull);
    });

    testWidgets('com consentimento, a vistoria leva o nome de quem registrou', (tester) async {
      final prefs = await openInspectionForm(tester, consent: true);
      expect(find.textContaining('com o seu nome (Ana Souza)'), findsOneWidget);

      await fillAndSave(tester);
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();

      expect((await LocalInspectionRepository(prefs).fetchAll()).single.authorName, 'Ana Souza');
    });

    testWidgets('com erro no formulário, a tela rola até o primeiro campo com erro', (tester) async {
      await openInspectionForm(tester);
      await tester.scrollUntilVisible(
        find.text('Salvar vistoria'),
        300,
        scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first,
      );
      await tester.ensureVisible(find.text('Salvar vistoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar vistoria'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // O primeiro erro (tipo de ocorrência) fica visível, mesmo com o botão lá embaixo.
      expect(find.text('Escolha o tipo de ocorrência.').hitTestable(), findsOneWidget);
    });
  });
}
