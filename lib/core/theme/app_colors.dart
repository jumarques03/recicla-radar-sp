import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/data/models/waste_material.dart';

/// Cores-base da marca: azul (água/céu) e verde (reciclagem).
abstract final class AppColors {
  static const Color blueSeed = Color(0xFF1565C0);
  static const Color greenSeed = Color(0xFF2E7D32);

  /// Cor de cada material nos gráficos. Sempre acompanhada de texto.
  static Color material(WasteMaterial material, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (material) {
      WasteMaterial.plastic => isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
      WasteMaterial.glass => isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
      WasteMaterial.paper => isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00697A),
      WasteMaterial.metal => isDark ? const Color(0xFFB0BEC5) : const Color(0xFF546E7A),
    };
  }
}

/// Escolhe preto ou branco para o conteúdo desenhado sobre [background].
Color onColorFor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF10151C);
