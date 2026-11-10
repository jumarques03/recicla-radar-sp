import 'package:flutter/material.dart';

/// Larguras (em dp) onde o layout muda.
abstract final class Breakpoints {
  /// A partir daqui a barra de navegação vai para o lado (celular deitado, tablet).
  static const double medium = 720;

  /// A partir daqui o menu lateral mostra os nomes ao lado dos ícones.
  static const double expanded = 1100;

  /// Largura máxima do conteúdo de listas, formulários e detalhes.
  static const double contentMax = 760;

  /// Largura máxima de telas com painéis e gráficos (visão geral).
  static const double dashboardMax = 1100;

  /// Largura máxima de formulários e configurações.
  static const double formMax = 640;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Celular deitado ou tablet: usa o menu lateral.
  bool get isWideScreen => screenWidth >= Breakpoints.medium;

  /// Tela grande (ex.: janela de computador): menu lateral com nomes.
  bool get isExpandedScreen => screenWidth >= Breakpoints.expanded;

  /// Quantas vezes o texto está aumentado (sistema + Configurações).
  double get textScale => MediaQuery.textScalerOf(this).scale(16) / 16;

  /// Texto muito aumentado: o app libera espaço na tela.
  bool get isLargeText => textScale > 1.3;
}

/// Centraliza o conteúdo e limita a largura, para nada ficar esticado em tela larga.
/// Em tela estreita não muda nada.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = Breakpoints.contentMax});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// `ListView` com o conteúdo centralizado e de largura limitada.
class ContentListView extends StatelessWidget {
  const ContentListView({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth = Breakpoints.contentMax,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      maxWidth: maxWidth,
      child: ListView(padding: padding, children: children),
    );
  }
}
