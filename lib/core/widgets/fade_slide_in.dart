import 'package:flutter/material.dart';

/// Faz o conteúdo aparecer suavemente, subindo um pouco, ao entrar na tela.
/// Não anima quando a pessoa pede para reduzir movimento no aparelho.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
  });

  final Widget child;

  /// Espera antes de começar, para itens de uma lista entrarem em sequência.
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final total = delay + duration;
    final start = total.inMilliseconds == 0
        ? 0.0
        : delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
