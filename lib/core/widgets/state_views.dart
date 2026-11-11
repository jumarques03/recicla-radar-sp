import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Carregando...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: Icons.cloud_off_outlined,
      title: 'Algo deu errado',
      message: message,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Tentar de novo'),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _MessageView(icon: icon, title: title, message: message);
  }
}

/// Mostra os três estados de um [LoadableNotifier]: carregando, erro e vazio.
/// Quando há dados, chama [builder].
class LoadableView<T> extends StatelessWidget {
  const LoadableView({
    super.key,
    required this.notifier,
    required this.builder,
    required this.isEmpty,
    this.emptyTitle = 'Nada por aqui',
    this.emptyMessage = 'Ainda não há nada para mostrar.',
  });

  final LoadableNotifier<T> notifier;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data) isEmpty;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    // A chave muda só quando muda o tipo de tela (carregando, erro, vazio, conteúdo),
    // então atualizar os dados não reinicia a animação.
    final (key, child) = switch (notifier.status) {
      LoadStatus.idle ||
      LoadStatus.loading => ('loading', const LoadingView() as Widget),
      LoadStatus.error => (
        'error',
        ErrorView(
          message:
              notifier.error ?? 'Não foi possível carregar. Tente de novo.',
          onRetry: notifier.load,
        ),
      ),
      LoadStatus.ready => _ready(context),
    };
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }

  (String, Widget) _ready(BuildContext context) {
    final data = notifier.data as T;
    if (isEmpty(data)) {
      return ('empty', EmptyView(title: emptyTitle, message: emptyMessage));
    }
    return ('content', builder(context, data));
  }
}
