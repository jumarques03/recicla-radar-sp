import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/data/local/alert_history_store.dart';
import 'package:recicla_radar_sp/data/local/alert_status_store.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/inspection.dart';
import 'package:recicla_radar_sp/data/repositories/engine_alert_repository.dart';
import 'package:recicla_radar_sp/data/repositories/local_inspection_repository.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';
import 'package:recicla_radar_sp/features/alerts/alert_decision.dart';
import 'package:recicla_radar_sp/state/inspections_provider.dart';

import 'fake_boundary_repository.dart';

Future<SharedPreferences> freshPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

EngineAlertRepository repositoryOn(SharedPreferences prefs) => EngineAlertRepository(
  SharedPrefsAlertStatusStore(prefs),
  LocalInspectionRepository(prefs),
  history: SharedPrefsAlertHistoryStore(prefs),
);

Future<SharedPreferences> openAlertDetail(WidgetTester tester) async {
  final prefs = await freshPrefs();
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
  await tester.tap(find.textContaining('deve encher').first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
  return prefs;
}

Future<void> scrollDetailTo(WidgetTester tester, Finder target) async {
  final scrollable = find.descendant(of: find.byType(ContentListView), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(target, 300, scrollable: scrollable);
  await tester.pumpAndSettle();
}

void main() {
  group('por que o alerta apareceu', () {
    test('todo alerta traz as condições da regra, e pelo menos uma foi atendida', () async {
      final prefs = await freshPrefs();
      final alerts = await repositoryOn(prefs).fetchAlerts(fillThreshold: 60);

      expect(alerts, isNotEmpty);
      for (final alert in alerts) {
        expect(alert.conditions, isNotEmpty, reason: alert.id);
        expect(alert.conditions.any((c) => c.met), isTrue, reason: alert.id);
      }
      // Os seis tipos de regra aparecem entre os alertas de teste.
      expect(alerts.map((a) => a.type).toSet().length, greaterThanOrEqualTo(5));
    });

    test('o alerta de enchimento mostra o valor encontrado e o limite das Configurações', () async {
      final prefs = await freshPrefs();
      final alerts = await repositoryOn(prefs).fetchAlerts(fillThreshold: 70);
      final fill = alerts.firstWhere((a) => a.type == AlertType.fillPrediction);

      expect(fill.conditions.first.text, contains('(o alerta vale a partir de 70%)'));
      expect(fill.conditions.first.met, isTrue);
    });
  });

  group('decisões', () {
    test('alocar equipe vira o status "Equipe alocada", que ainda é ativo, e entra no histórico', () async {
      final prefs = await freshPrefs();
      final repository = repositoryOn(prefs);
      final alert = (await repository.fetchAlerts(fillThreshold: 80)).first;
      final now = DateTime(2026, 11, 15, 10, 30);

      final event = buildDecisionEvent(
        kind: DecisionKind.assignTeam,
        choice: 'Equipe de coleta Centro',
        note: 'Levar caminhão menor',
        deadline: DecisionDeadline.tomorrow,
        by: 'Ana Souza',
        now: now,
      );
      expect(event.action, 'Alocou: Equipe de coleta Centro');
      expect(event.detail, 'Prazo: amanhã (16/11) · Observação: Levar caminhão menor');
      expect(event.status, AlertStatus.teamAssigned);

      final updated = await repository.decide(alert.id, event);
      expect(updated.status.isActive, isTrue);
      expect(updated.history, hasLength(1));

      // Um novo repositório sobre os mesmos dados do aparelho, como num app reaberto.
      final reopened = (await repositoryOn(prefs).fetchAlerts(fillThreshold: 80)).firstWhere(
        (a) => a.id == alert.id,
      );
      expect(reopened.status, AlertStatus.teamAssigned);
      expect(reopened.history.single.action, 'Alocou: Equipe de coleta Centro');
      expect(reopened.history.single.by, 'Ana Souza');
    });

    test('o histórico guarda a ordem das decisões, e concluir tira o alerta dos ativos', () async {
      final prefs = await freshPrefs();
      final repository = repositoryOn(prefs);
      final alert = (await repository.fetchAlerts(fillThreshold: 80)).first;
      final now = DateTime(2026, 11, 15, 10, 30);

      AlertEvent event(DecisionKind kind, String? choice) => buildDecisionEvent(
        kind: kind,
        choice: choice,
        note: '',
        deadline: DecisionDeadline.today,
        by: null,
        now: now,
      );
      await repository.decide(alert.id, event(DecisionKind.investigate, null));
      await repository.decide(alert.id, event(DecisionKind.complete, 'Coleta realizada'));

      final stored = (await repositoryOn(prefs).fetchAlerts(fillThreshold: 80)).firstWhere(
        (a) => a.id == alert.id,
      );
      expect(stored.status, AlertStatus.resolved);
      expect(stored.status.isActive, isFalse);
      expect(stored.history.map((e) => e.status), [AlertStatus.inAnalysis, AlertStatus.resolved]);
      expect(stored.history.last.by, isNull); // sem consentimento, fica anônimo
    });

    test('cada tipo de alerta tem equipes, resultados e motivos próprios', () {
      expect(DecisionKind.assignTeam.choices(AlertType.offline), contains('Equipe de manutenção de sensores'));
      expect(DecisionKind.assignTeam.choices(AlertType.fillPrediction), contains('Equipe de coleta Centro'));
      expect(DecisionKind.complete.choices(AlertType.offline), contains('Equipamento reparado'));
      expect(DecisionKind.discard.choices(AlertType.anomaly), contains('Falso alarme'));
      expect(DecisionKind.assignTeam.label(AlertType.offline), 'Enviar fiscal conferir');
    });

    testWidgets('na tela do alerta, alocar equipe pede a escolha, mostra a frase e registra no histórico', (tester) async {
      await openAlertDetail(tester);
      expect(find.text('Por que este alerta apareceu?'), findsOneWidget);
      expect(find.textContaining('Enchimento atual de'), findsOneWidget);

      await scrollDetailTo(tester, find.text('Alocar equipe de coleta'));
      await tester.tap(find.text('Alocar equipe de coleta'));
      await tester.pumpAndSettle();

      // A folha mostra, em uma frase, o que vai acontecer.
      expect(find.textContaining('Você vai alocar "Equipe de coleta Centro"'), findsOneWidget);
      await tester.tap(find.text('Equipe de coleta Zona Sul'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Você vai alocar "Equipe de coleta Zona Sul"'), findsOneWidget);

      await tester.tap(find.text('Amanhã'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar: alocar equipe de coleta'));
      await tester.pumpAndSettle();

      // O cartão de decisão fica acima dos botões em que a tela estava rolada: sobe até ele.
      final scrollable = find.descendant(of: find.byType(ContentListView), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(find.text('Situação atual: Equipe alocada'), -300, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(find.text('Situação atual: Equipe alocada'), findsOneWidget);
      await scrollDetailTo(tester, find.text('Alocou: Equipe de coleta Zona Sul'));
      expect(find.text('Alocou: Equipe de coleta Zona Sul'), findsOneWidget);
      // Sem consentimento, a decisão fica sem o nome de quem decidiu.
      expect(find.textContaining('por usuário anônimo'), findsOneWidget);
    });

    testWidgets('cancelar a folha não muda nada', (tester) async {
      await openAlertDetail(tester);
      await scrollDetailTo(tester, find.text('Descartar alerta'));
      await tester.tap(find.text('Descartar alerta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Situação atual: Aberto'), findsOneWidget);
      expect(find.text('Nenhuma decisão registrada ainda.'), findsOneWidget);
    });
  });

  group('vistoria ligada ao alerta', () {
    test('as respostas de campo contam só o último resultado de cada alerta', () async {
      final prefs = await freshPrefs();
      final repository = LocalInspectionRepository(prefs);
      final provider = InspectionsProvider(repository);

      Inspection item(String id, String alertId, AlertCheck? check, int minutes) => Inspection(
        id: id,
        binId: 'bin-1',
        type: OccurrenceType.full,
        severity: InspectionSeverity.medium,
        description: 'Descrição de teste da vistoria',
        dateTime: DateTime(2026, 11, 10, 10, minutes),
        needsAction: false,
        alertId: alertId,
        check: check,
      );

      await provider.load();
      await provider.submit(item('a', 'alerta-1', AlertCheck.denies, 0));
      await provider.submit(item('b', 'alerta-1', AlertCheck.confirms, 5)); // mais recente do alerta-1
      await provider.submit(item('c', 'alerta-2', AlertCheck.denies, 10));
      await provider.submit(item('d', 'alerta-3', null, 15)); // sem resposta: não conta

      expect(provider.checkStats, (checked: 2, confirmed: 1));
      expect(provider.latestCheck('alerta-1')?.check, AlertCheck.confirms);
      expect(provider.latestCheck('alerta-3'), isNull);

      // As respostas continuam depois de fechar e abrir o app.
      final reopened = InspectionsProvider(LocalInspectionRepository(prefs));
      await reopened.load();
      expect(reopened.checkStats, (checked: 2, confirmed: 1));
    });

    testWidgets('do alerta ao formulário: já vem preenchido, e a resposta "confirma" aparece no alerta e na Visão geral', (tester) async {
      await openAlertDetail(tester);

      await scrollDetailTo(tester, find.text('Verificar em campo (registrar vistoria)'));
      await tester.tap(find.text('Verificar em campo (registrar vistoria)'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Lixeira e tipo vêm do alerta, e a pergunta sobre o alerta aparece.
      expect(find.text('Lixeira Praça da Sé 01'), findsWidgets);
      expect(find.text('Lixeira cheia'), findsOneWidget);
      final formScrollable = find.descendant(of: find.byType(ContentListView), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(find.text('Esta vistoria confirma o alerta?'), 300, scrollable: formScrollable);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirma'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Preencher: coletar lixo da lixeira'), -300, scrollable: formScrollable);
      await tester.tap(find.text('Preencher: coletar lixo da lixeira'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Data e hora'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolher'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolher'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Salvar vistoria'), 300, scrollable: formScrollable);
      await tester.ensureVisible(find.text('Salvar vistoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar vistoria'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('ficou registrada no alerta'), findsOneWidget);
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // De volta ao alerta: a conclusão mostra que foi confirmado em campo.
      expect(find.textContaining('Confirmado em campo pela vistoria de'), findsOneWidget);

      // E a Visão geral conta o alerta conferido.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visão geral').last);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Alertas conferidos em campo'), findsOneWidget);
      expect(find.textContaining('1 de 1 alerta conferido em campo foi confirmado (100%)'), findsOneWidget);
    });
  });

  testWidgets('a lista de alertas explica como os alertas são gerados', (tester) async {
    await openAlertDetail(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Como os alertas são gerados'));
    await tester.pumpAndSettle();
    expect(find.text('Como os alertas são gerados'), findsWidgets);
    expect(find.text('Previsão de enchimento'), findsOneWidget);
    expect(find.textContaining('Quem decide o que fazer é sempre uma pessoa'), findsOneWidget);
  });
}
