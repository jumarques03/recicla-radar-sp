import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/state/session_provider.dart';
import 'package:recicla_radar_sp/state/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final session = context.read<SessionProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você vai precisar entrar de novo para usar o app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true) await session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final user = context.select<SessionProvider, String?>((s) => s.user?.name);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ContentListView(
        maxWidth: Breakpoints.formMax,
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (user != null) ...[
            Text('Conta: $user', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
          ],
          _SettingsGroup(
            title: 'Aparência',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Em telas muito estreitas os ícones tiram o espaço do texto: ficam só os nomes.
                    final showIcons = constraints.maxWidth >= 270;
                    ButtonSegment<ThemeMode> segment(ThemeMode mode, IconData icon, String label) =>
                        ButtonSegment(
                          value: mode,
                          icon: showIcons ? Icon(icon) : null,
                          label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
                        );

                    return SegmentedButton<ThemeMode>(
                      segments: [
                        segment(ThemeMode.system, Icons.brightness_auto, 'Sistema'),
                        segment(ThemeMode.light, Icons.light_mode_outlined, 'Claro'),
                        segment(ThemeMode.dark, Icons.dark_mode_outlined, 'Escuro'),
                      ],
                      // Sem o "visto" e com menos margem, o texto cabe numa linha só.
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      selected: {settings.themeMode},
                      onSelectionChanged: (values) => settings.setThemeMode(values.first),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.highContrast,
                  onChanged: settings.setHighContrast,
                  title: const Text('Alto contraste'),
                  subtitle: const Text('Cores mais fortes e bordas mais grossas, para ler melhor.'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Tamanho da letra', style: theme.textTheme.titleSmall),
                Slider(
                  value: settings.textScale,
                  min: SettingsProvider.minTextScale,
                  max: SettingsProvider.maxTextScale,
                  divisions: 6,
                  label: '${(settings.textScale * 100).round()}%',
                  semanticFormatterCallback: (value) => 'Tamanho da letra ${(value * 100).round()}%',
                  onChanged: settings.setTextScale,
                ),
                Text(
                  'Este texto de exemplo mostra o tamanho escolhido. Vale para o app todo.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsGroup(
            title: 'Alertas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avisar quando a lixeira passar de ${settings.fillThreshold}% cheia',
                  style: theme.textTheme.bodyLarge,
                ),
                Slider(
                  value: settings.fillThreshold.toDouble(),
                  min: 50,
                  max: 95,
                  divisions: 9,
                  label: '${settings.fillThreshold}%',
                  semanticFormatterCallback: (value) => 'Avisar acima de ${value.round()}% de enchimento',
                  onChanged: (value) => settings.setFillThreshold(value.round()),
                ),
                Text(
                  'Quanto menor o valor, mais alertas aparecem.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsGroup(
            title: 'Privacidade',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.consent,
              onChanged: settings.setConsent,
              title: const Text('Permito o uso dos meus dados pessoais'),
              subtitle: const Text(
                'Ligado, as vistorias levam o seu nome. Desligado, elas são registradas '
                'de forma anônima.',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          child,
        ],
      ),
    );
  }
}
