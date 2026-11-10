import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recicla_radar_sp/core/theme/dark_theme.dart';
import 'package:recicla_radar_sp/core/theme/high_contrast_theme.dart';
import 'package:recicla_radar_sp/core/theme/light_theme.dart';
import 'package:recicla_radar_sp/core/theme/status_colors.dart';

/// Razão de contraste WCAG entre duas cores (1 a 21).
double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Cor de [foreground] aplicada com 14% de opacidade sobre [background]
/// (o fundo das etiquetas de status).
Color tint(Color foreground, Color background) =>
    Color.alphaBlend(foreground.withValues(alpha: 0.14), background);

void main() {
  void checkTheme(
    String name,
    ColorScheme scheme,
    StatusColors status,
    Color card, {
    double minimum = 4.5, // WCAG AA para texto normal.
    String level = 'AA',
  }) {
    group('contraste $level no tema $name', () {
      final pairs = <String, (Color, Color)>{
        'texto sobre fundo': (scheme.onSurface, scheme.surface),
        'texto secundário sobre fundo': (scheme.onSurfaceVariant, scheme.surface),
        'texto sobre card': (scheme.onSurface, card),
        'botão principal': (scheme.onPrimary, scheme.primary),
        'botão secundário': (scheme.onSecondary, scheme.secondary),
        'container secundário': (scheme.onSecondaryContainer, scheme.secondaryContainer),
        'erro': (scheme.onError, scheme.error),
        'container de erro': (scheme.onErrorContainer, scheme.errorContainer),
        'link/ação sobre fundo': (scheme.primary, scheme.surface),
      };
      pairs.forEach((label, colors) {
        test(label, () {
          expect(contrast(colors.$1, colors.$2), greaterThanOrEqualTo(minimum));
        });
      });

      final statuses = {
        'sucesso': status.success,
        'aviso': status.warning,
        'perigo': status.danger,
        'info': status.info,
        'neutro': status.neutral,
      };
      statuses.forEach((label, color) {
        test('etiqueta de status: $label', () {
          expect(contrast(color, tint(color, card)), greaterThanOrEqualTo(minimum));
          expect(contrast(color, tint(color, scheme.surface)), greaterThanOrEqualTo(minimum));
        });
      });

      test('borda dos campos tem contraste mínimo 3:1', () {
        expect(contrast(scheme.outline, card), greaterThanOrEqualTo(3));
      });
    });
  }

  checkTheme('claro', lightColorScheme, StatusColors.light, Colors.white);
  checkTheme('escuro', darkColorScheme, StatusColors.dark, const Color(0xFF18212C));

  // Alto contraste: nível AAA (7:1), o mais exigente da WCAG para texto.
  checkTheme('claro de alto contraste', highContrastLightScheme, highContrastLightStatus, Colors.white,
      minimum: 7, level: 'AAA');
  checkTheme('escuro de alto contraste', highContrastDarkScheme, highContrastDarkStatus,
      const Color(0xFF0A0A0A),
      minimum: 7, level: 'AAA');
}
