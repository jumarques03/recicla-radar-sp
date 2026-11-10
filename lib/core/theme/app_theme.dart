import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/theme/app_typography.dart';
import 'package:recicla_radar_sp/core/theme/status_colors.dart';

/// Monta o tema a partir de um [ColorScheme]. Claro e escuro compartilham
/// exatamente os mesmos componentes; só mudam as cores.
ThemeData buildAppTheme({
  required ColorScheme scheme,
  required StatusColors status,
  required Color cardColor,
}) {
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final textTheme = AppTypography.build(base.textTheme);
  const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.control);
  const buttonSize = Size(AppSpacing.minTouch, 56);

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [status],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        side: BorderSide(color: scheme.outline),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch),
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch),
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: AppRadius.control,
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.control,
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.control,
        borderSide: BorderSide(color: scheme.primary, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.control,
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.control,
        borderSide: BorderSide(color: scheme.error, width: 3),
      ),
      errorMaxLines: 3,
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: textTheme.labelLarge,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      side: BorderSide(color: scheme.outline),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 80,
      backgroundColor: cardColor,
      indicatorColor: scheme.secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      showDragHandle: true,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
  );
}
