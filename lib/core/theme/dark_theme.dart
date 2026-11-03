import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_colors.dart';
import 'package:recicla_radar_sp/core/theme/app_theme.dart';
import 'package:recicla_radar_sp/core/theme/status_colors.dart';

/// Esquema de cores escuro: tons mais claros de azul e verde sobre fundo grafite.
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.blueSeed,
  brightness: Brightness.dark,
).copyWith(
  secondary: const Color(0xFF81C784),
  onSecondary: const Color(0xFF0B2D0E),
  secondaryContainer: const Color(0xFF1B5E20),
  onSecondaryContainer: const Color(0xFFC8E6C9),
  surface: const Color(0xFF0F151D),
  onSurface: const Color(0xFFE6EBF0),
  onSurfaceVariant: const Color(0xFFBFC8D1),
  outline: const Color(0xFF8D99A6),
);

ThemeData buildDarkTheme() => buildAppTheme(
      scheme: darkColorScheme,
      status: StatusColors.dark,
      cardColor: const Color(0xFF18212C),
    );
