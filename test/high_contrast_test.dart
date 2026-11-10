import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/core/theme/high_contrast_theme.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';
import 'package:recicla_radar_sp/state/settings_provider.dart';

import 'fake_boundary_repository.dart';

void main() {
  test('o alto contraste fica salvo no aparelho, e começa desligado', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(SettingsProvider(prefs).highContrast, isFalse);

    await SettingsProvider(prefs).setHighContrast(true);
    expect(SettingsProvider(prefs).highContrast, isTrue);
  });

  test('o tema de alto contraste tem bordas mais grossas e texto preto ou branco', () {
    final light = buildHighContrastLightTheme();
    final dark = buildHighContrastDarkTheme();
    expect(light.colorScheme.onSurface, Colors.black);
    expect(light.colorScheme.surface, Colors.white);
    expect(dark.colorScheme.onSurface, Colors.white);
    expect(dark.colorScheme.surface, Colors.black);

    final cardBorder = (light.cardTheme.shape! as RoundedRectangleBorder).side;
    expect(cardBorder.width, 2);
    expect(cardBorder.color, Colors.black);
  });

  testWidgets('ligar "Alto contraste" nas Configurações troca o tema na hora', (tester) async {
    SharedPreferences.setMockInitialValues({'themeMode': 'light'});
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

    Color outline() => Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme.outline;
    final before = outline();
    expect(before, isNot(Colors.black));

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Alto contraste'));
    await tester.pumpAndSettle();

    expect(outline(), Colors.black);
    expect(prefs.getBool('highContrast'), isTrue);

    // Desligar volta ao tema normal.
    await tester.tap(find.text('Alto contraste'));
    await tester.pumpAndSettle();
    expect(outline(), before);
  });
}
