import 'package:flutter/material.dart';

/// Cores semânticas de status. Usadas sempre junto de ícone e texto.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.neutral,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color neutral;

  static const StatusColors light = StatusColors(
    success: Color(0xFF1B5E20),
    warning: Color(0xFF8A4B00),
    danger: Color(0xFFB3261E),
    info: Color(0xFF0D47A1),
    neutral: Color(0xFF44505C),
  );

  static const StatusColors dark = StatusColors(
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    danger: Color(0xFFFF8A80),
    info: Color(0xFF90CAF9),
    neutral: Color(0xFFB0BEC5),
  );

  @override
  StatusColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? neutral,
  }) {
    return StatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

extension StatusColorsContext on BuildContext {
  StatusColors get statusColors => Theme.of(this).extension<StatusColors>()!;
}
