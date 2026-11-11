import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/core/widgets/fade_slide_in.dart';
import 'package:recicla_radar_sp/core/widgets/settings_action.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/features/alerts/alert_card.dart';
import 'package:recicla_radar_sp/features/alerts/alert_filters.dart';
import 'package:recicla_radar_sp/features/alerts/human_decision_banner.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';
import 'package:recicla_radar_sp/state/bins_provider.dart';
import 'package:recicla_radar_sp/state/districts_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, this.districtId, this.binId});

  /// Mostra só os alertas deste distrito (vem do painel do distrito).
  final String? districtId;

  /// Mostra só os alertas desta lixeira (vem do detalhe da lixeira).
  final String? binId;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Filtros são estado local: só valem enquanto esta tela está aberta.
  AlertFilters _filters = const AlertFilters();

  // Se a seção de alertas resolvidos e descartados está aberta.
  bool _showArchived = false;

  Future<void> _markAllSeen(AlertsProvider alerts) async {
    final messenger = ScaffoldMessenger.of(context);
    final marked = await alerts.markAllSeen();
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            marked.length == 1
                ? '1 alerta marcado como lido.'
                : '${marked.length} alertas marcados como lidos.',
          ),
          // Avisos com botão ficam na tela até alguém fechar; este some sozinho em 5 s.
          persist: false,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => alerts.markUnseen(marked),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        actions: [
          IconButton(
            tooltip: alerts.unseenCount > 0
                ? 'Marcar os ${alerts.unseenCount} alertas não lidos como lidos'
                : 'Todos os alertas já foram lidos',
            icon: const Icon(Icons.done_all),
            onPressed: alerts.unseenCount > 0
                ? () => _markAllSeen(alerts)
                : null,
          ),
          const SettingsAction(),
        ],
      ),
      body: LoadableView<List<Alert>>(
        notifier: alerts,
        isEmpty: (list) => list.isEmpty,
        emptyTitle: 'Nenhum alerta por enquanto',
        emptyMessage: 'Quando o sistema perceber algo, o aviso aparece aqui.',
        builder: (context, list) {
          final visible = list
              .where(
                (a) =>
                    (widget.districtId == null ||
                        a.districtId == widget.districtId) &&
                    (widget.binId == null || a.binId == widget.binId) &&
                    _filters.matches(a, isSeen: alerts.isSeen),
              )
              .toList();

          // A faixa de aviso e os filtros ficam fixos no topo. Com letra muito
          // grande eles ocupariam quase metade da tela, então rolam junto com a lista.
          final headers = <Widget>[
            const HumanDecisionBanner(),
            ContentWidth(
              child: Column(
                children: [
                  if (widget.districtId != null || widget.binId != null)
                    _LinkedFilterChip(
                      districtId: widget.districtId,
                      binId: widget.binId,
                    ),
                  AlertFilterPanel(
                    filters: _filters,
                    onChanged: (filters) => setState(() => _filters = filters),
                  ),
                ],
              ),
            ),
          ];
          final scrollHeaders = context.isLargeText;

          // Alertas resolvidos ou descartados saem da lista e ficam numa seção própria,
          // fechada. Se a pessoa filtra por "Resolvido" ou "Descartado", ela abre sozinha.
          final active = visible.where((a) => a.status.isActive).toList();
          final archived = visible.where((a) => !a.status.isActive).toList();
          final archivedOpen = _showArchived || _filters.status?.isActive == false;

          Widget padded(Widget child) => ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm + 4,
              ),
              child: child,
            ),
          );

          final cards = <Widget>[
            if (active.isEmpty)
              EmptyView(
                title: archived.isEmpty
                    ? 'Nenhum alerta com esses filtros'
                    : 'Nenhum alerta ativo',
                message: archived.isEmpty
                    ? 'Mude ou limpe os filtros para ver mais alertas.'
                    : 'Os alertas resolvidos e descartados estão na seção abaixo.',
                icon: archived.isEmpty
                    ? Icons.filter_alt_off_outlined
                    : Icons.check_circle_outline,
              ),
            for (final (index, alert) in active.indexed)
              padded(
                // Os primeiros cards entram em sequência; os demais já aparecem prontos.
                FadeSlideIn(
                  delay: Duration(milliseconds: 40 * (index < 6 ? index : 6)),
                  child: AlertCard(
                    alert: alert,
                    isNew: !alerts.isSeen(alert.id),
                    onToggleRead: () => alerts.toggleSeen(alert.id),
                    onTap: () => context.pushNamed(
                      AppRoutes.alert,
                      pathParameters: {'id': alert.id},
                    ),
                  ),
                ),
              ),
            if (archived.isNotEmpty) ...[
              padded(
                _ArchivedHeader(
                  count: archived.length,
                  open: archivedOpen,
                  // Com o filtro de status escolhido a seção fica aberta, sem botão para fechar.
                  onToggle: _filters.status?.isActive == false
                      ? null
                      : () => setState(() => _showArchived = !_showArchived),
                ),
              ),
              if (archivedOpen)
                for (final alert in archived)
                  padded(
                    AlertCard(
                      alert: alert,
                      onTap: () => context.pushNamed(
                        AppRoutes.alert,
                        pathParameters: {'id': alert.id},
                      ),
                    ),
                  ),
            ],
          ];

          final headerCount = scrollHeaders ? headers.length : 0;
          final listView = RefreshIndicator(
            onRefresh: alerts.load,
            child: ListView.builder(
              padding: EdgeInsets.only(
                top: scrollHeaders ? 0 : AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              itemCount: headerCount + cards.length,
              itemBuilder: (context, index) => index < headerCount
                  ? headers[index]
                  : cards[index - headerCount],
            ),
          );

          if (scrollHeaders) return listView;
          return Column(
            children: [
              ...headers,
              Expanded(child: listView),
            ],
          );
        },
      ),
    );
  }
}

/// Mostra de onde veio o filtro (distrito ou lixeira) e deixa tirar.
class _LinkedFilterChip extends StatelessWidget {
  const _LinkedFilterChip({this.districtId, this.binId});

  final String? districtId;
  final String? binId;

  @override
  Widget build(BuildContext context) {
    String? label;
    if (binId != null) {
      label =
          'Lixeira: ${context.read<BinsProvider>().byId(binId!)?.name ?? 'desconhecida'}';
    } else {
      for (final district
          in context.read<DistrictsProvider>().data ?? const <District>[]) {
        if (district.id == districtId) label = 'Distrito: ${district.name}';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          avatar: const Icon(Icons.filter_alt_outlined, size: 18),
          label: Text(label ?? 'Filtro ativo'),
          deleteButtonTooltipMessage: 'Tirar este filtro',
          onDeleted: () => context.goNamed(AppRoutes.alerts),
        ),
      ),
    );
  }
}

/// Cabeçalho da seção fechada com os alertas resolvidos e descartados.
class _ArchivedHeader extends StatelessWidget {
  const _ArchivedHeader({
    required this.count,
    required this.open,
    required this.onToggle,
  });

  final int count;
  final bool open;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final label = count == 1
        ? '1 alerta resolvido ou descartado'
        : '$count alertas resolvidos ou descartados';
    return AppCard(
      onTap: onToggle,
      semanticLabel: '$label. ${open ? 'Mostrando.' : 'Escondidos.'}',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(child: Text(label)),
          Text(
            open ? 'Esconder' : 'Mostrar',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (onToggle != null) Icon(open ? Icons.expand_less : Icons.expand_more),
        ],
      ),
    );
  }
}
