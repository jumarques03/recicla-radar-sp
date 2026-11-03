import 'package:flutter/material.dart';

/// Tipografia um pouco maior que o padrão, pensada para leitura fácil.
abstract final class AppTypography {
  static TextTheme build(TextTheme base) {
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 18, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 16, height: 1.45),
      bodySmall: base.bodySmall?.copyWith(fontSize: 14, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: base.labelSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}
