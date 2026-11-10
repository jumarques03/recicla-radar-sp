import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 6;
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 32;
  static const double xl = 40;

  /// Tamanho mínimo de qualquer alvo de toque (WCAG / Material).
  static const double minTouch = 48;
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius control = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(lg));
}
