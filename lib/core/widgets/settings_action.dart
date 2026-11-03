import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:recicla_radar_sp/core/router/app_routes.dart';

/// Botão de engrenagem usado na barra superior das telas principais.
class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Configurações',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.pushNamed(AppRoutes.settings),
    );
  }
}
