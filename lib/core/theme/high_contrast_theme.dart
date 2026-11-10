import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_colors.dart';
import 'package:recicla_radar_sp/core/theme/app_theme.dart';
import 'package:recicla_radar_sp/core/theme/status_colors.dart';

/// Temas de alto contraste: texto preto sobre branco (ou branco sobre preto),
/// bordas grossas e cores de status bem escuras ou bem claras. Os textos têm
/// contraste de pelo menos 7:1 (nível AAA).
///
/// Valem quando a pessoa liga "Alto contraste" nas Configurações ou quando o
/// próprio aparelho pede texto em alto contraste.
final ColorScheme highContrastLightScheme = ColorScheme.fromSeed(
  seedColor: AppColors.blueSeed,
  brightness: Brightness.light,
  contrastLevel: 1.0,
).copyWith(
  primary: const Color(0xFF002A6B),
  onPrimary: Colors.white,
  secondary: const Color(0xFF0A4A12),
  onSecondary: Colors.white,
  secondaryContainer: const Color(0xFFB9E6BE),
  onSecondaryContainer: const Color(0xFF00200A),
  error: const Color(0xFF8A0000),
  onError: Colors.white,
  errorContainer: const Color(0xFFFFD4D4),
  onErrorContainer: const Color(0xFF330000),
  surface: Colors.white,
  onSurface: Colors.black,
  onSurfaceVariant: const Color(0xFF1A1A1A),
  outline: Colors.black,
  outlineVariant: const Color(0xFF404040),
);

final ColorScheme highContrastDarkScheme = ColorScheme.fromSeed(
  seedColor: AppColors.blueSeed,
  brightness: Brightness.dark,
  contrastLevel: 1.0,
).copyWith(
  primary: const Color(0xFFB8D6FF),
  onPrimary: Colors.black,
  secondary: const Color(0xFFA8F0AF),
  onSecondary: Colors.black,
  secondaryContainer: const Color(0xFF0E4A16),
  onSecondaryContainer: Colors.white,
  error: const Color(0xFFFFB4AB),
  onError: Colors.black,
  errorContainer: const Color(0xFF8A0000),
  onErrorContainer: Colors.white,
  surface: Colors.black,
  onSurface: Colors.white,
  onSurfaceVariant: const Color(0xFFEDEDED),
  outline: Colors.white,
  outlineVariant: const Color(0xFFBDBDBD),
);

const StatusColors highContrastLightStatus = StatusColors(
  success: Color(0xFF0A4A12),
  warning: Color(0xFF5C3000),
  danger: Color(0xFF8A0000),
  info: Color(0xFF00296B),
  neutral: Color(0xFF1F1F1F),
);

const StatusColors highContrastDarkStatus = StatusColors(
  success: Color(0xFFA8F0AF),
  warning: Color(0xFFFFD699),
  danger: Color(0xFFFFB4AB),
  info: Color(0xFFB8D6FF),
  neutral: Color(0xFFEDEDED),
);

ThemeData buildHighContrastLightTheme() => buildAppTheme(
      scheme: highContrastLightScheme,
      status: highContrastLightStatus,
      cardColor: Colors.white,
      highContrast: true,
    );

ThemeData buildHighContrastDarkTheme() => buildAppTheme(
      scheme: highContrastDarkScheme,
      status: highContrastDarkStatus,
      cardColor: const Color(0xFF0A0A0A),
      highContrast: true,
    );
