import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/data/mock/mock_data.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';

import 'fake_boundary_repository.dart';

Future<void> signIn(WidgetTester tester, {Size size = const Size(390, 900)}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
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

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Abre o primeiro alerta de lixeira da lista (o mais grave).
Future<void> openFirstAlert(WidgetTester tester) async {
  await openTab(tester, 'Alertas');
  await tester.tap(find.textContaining('deve encher').first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Future<void> scrollTo(WidgetTester tester, String text) async {
  final list = find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable));
  await tester.scrollUntilVisible(find.text(text), 300, scrollable: list.first);
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  final fullest = [...MockData.bins]..sort((a, b) => b.fillPercent.compareTo(a.fillPercent));
  final sampleBin = fullest.first;
  final sampleDistrict = MockData.districts.firstWhere((d) => d.id == sampleBin.districtId);

  testWidgets('o cartão "Alertas ativos" da visão geral leva para os alertas', (tester) async {
    await signIn(tester);
    await scrollTo(tester, 'Alertas ativos');
    await tester.tap(find.text('Alertas ativos'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Os alertas apoiam, mas não substituem, a decisão humana.'), findsOneWidget);
  });

  testWidgets('o cartão "Lixeiras operando" leva para a lista de lixeiras', (tester) async {
    await signIn(tester);
    await scrollTo(tester, 'Lixeiras operando');
    await tester.tap(find.text('Lixeiras operando'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Todas'), findsOneWidget); // filtro de status da lista
  });

  testWidgets('do alerta para a lixeira: abre o detalhe e mostra os alertas dela', (tester) async {
    await signIn(tester);
    await openFirstAlert(tester);
    await tester.tap(find.text('Ver a lixeira'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(sampleBin.name), findsWidgets);
    await scrollTo(tester, 'Alertas desta lixeira');
    // O alerta que levou até aqui aparece na seção da lixeira.
    expect(find.textContaining('deve encher'), findsWidgets);
  });

  testWidgets('do alerta para o mapa: centraliza a lixeira e abre o resumo dela', (tester) async {
    await signIn(tester);
    await openFirstAlert(tester);
    await tester.tap(find.text('Ver no mapa'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Ver detalhes'), findsOneWidget);
    expect(find.text(sampleBin.name), findsWidgets);
  });

  testWidgets('do alerta para o distrito: abre o painel do distrito no mapa de demanda', (tester) async {
    await signIn(tester);
    await openFirstAlert(tester);
    await tester.tap(find.text('Ver o distrito'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text(sampleDistrict.name), findsWidgets);
    expect(find.textContaining('lixeiras do distrito'), findsOneWidget);
  });

  testWidgets('do distrito para as lixeiras dele, com filtro que dá para tirar', (tester) async {
    await signIn(tester);
    await openFirstAlert(tester);
    await tester.tap(find.text('Ver o distrito'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.textContaining('lixeiras do distrito'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Distrito: ${sampleDistrict.name}'), findsOneWidget);
    expect(find.text('Lista'), findsOneWidget);
    // A lista só tem lixeiras do distrito.
    final inDistrict = MockData.bins.where((b) => b.districtId == sampleDistrict.id).toList();
    for (final bin in MockData.bins.where((b) => b.districtId != sampleDistrict.id).take(10)) {
      expect(find.text(bin.name), findsNothing);
    }
    expect(find.text(inDistrict.first.name), findsWidgets);

    // Tirar o filtro volta a mostrar as outras.
    await tester.tap(find.byTooltip('Tirar o filtro de distrito'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Distrito: ${sampleDistrict.name}'), findsNothing);
  });

  testWidgets('do distrito para os alertas dele', (tester) async {
    await signIn(tester);
    await openFirstAlert(tester);
    await tester.tap(find.text('Ver o distrito'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.textContaining('alertas ativos do distrito'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Distrito: ${sampleDistrict.name}'), findsOneWidget);
    expect(find.textContaining('deve encher'), findsWidgets);
  });

  testWidgets('a lista de lixeiras mostra quantos alertas cada uma tem e filtra por status', (tester) async {
    await signIn(tester);
    await openTab(tester, 'Lixeiras');
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();

    // A lixeira mais cheia aparece primeiro, com o número de alertas dela.
    expect(find.text(sampleBin.name), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d* ?alertas?$')), findsWidgets);

    // Filtrando por "Sem sinal", a lixeira cheia some e as sem sinal aparecem.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sem sinal'));
    await tester.pumpAndSettle();
    expect(find.text(sampleBin.name), findsNothing);
    // A lista vai da mais cheia para a menos cheia; a primeira sem sinal aparece no alto.
    final offline = MockData.bins.where((b) => b.status.label == 'Sem sinal').toList()
      ..sort((a, b) => b.fillPercent.compareTo(a.fillPercent));
    expect(find.text(offline.first.name), findsOneWidget);
  });
}
