import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_colors.dart';
import 'package:recicla_radar_sp/core/theme/app_theme.dart';
import 'package:recicla_radar_sp/core/theme/status_colors.dart';

/// Esquema de cores claro: azul como cor principal e verde como secundária.
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.blueSeed,
  brightness: Brightness.light,
).copyWith(
  secondary: AppColors.greenSeed,
  onSecondary: Colors.white,
  secondaryContainer: const Color(0xFFC8E6C9),
  onSecondaryContainer: const Color(0xFF0B3D0F),
  surface: const Color(0xFFF5F9FC),
  onSurface: const Color(0xFF10151C),
  onSurfaceVariant: const Color(0xFF3A4651),
  outline: const Color(0xFF6B7885),
);

ThemeData buildLightTheme() => buildAppTheme(
      scheme: lightColorScheme,
      status: StatusColors.light,
      cardColor: Colors.white,
    );
