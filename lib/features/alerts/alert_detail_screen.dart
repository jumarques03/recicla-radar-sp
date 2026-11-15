import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/core/router/app_navigation.dart';
import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/theme/status_colors.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/core/widgets/charts/chart_card.dart';
import 'package:recicla_radar_sp/core/widgets/charts/simple_line_chart.dart';
import 'package:recicla_radar_sp/core/widgets/section_title.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/inspection.dart';
import 'package:recicla_radar_sp/features/alerts/alert_decision.dart';
import 'package:recicla_radar_sp/features/alerts/alert_decision_sheet.dart';
import 'package:recicla_radar_sp/features/alerts/human_decision_banner.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';
import 'package:recicla_radar_sp/state/inspections_provider.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';
import 'package:recicla_radar_sp/state/session_provider.dart';
import 'package:recicla_radar_sp/state/settings_provider.dart';

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Abrir o alerta já conta como lido.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AlertsProvider>().markSeen(widget.alertId);
    });
  }

  /// Abre a folha de confirmação e, se a pessoa confirmar, registra a decisão.
  Future<void> _decide(Alert alert, DecisionKind kind) async {
    final provider = context.read<AlertsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    // Sem consentimento para o uso dos dados pessoais, a decisão fica sem o nome.
    final consent = context.read<SettingsProvider>().consent;
    final name = context.read<SessionProvider>().user?.name;

    final event = await showAlertDecisionSheet(
      context,
      alert: alert,
      kind: kind,
      by: consent ? name : null,
    );
    if (event == null || !mounted) return;

    setState(() => _saving = true);
    try {
      await provider.decide(alert.id, event);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Registrado: ${event.action}.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar. Tente de novo.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertsProvider>();
    final alert = alerts.byId(widget.alertId);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: alerts.status != LoadStatus.ready
          ? LoadableView<List<Alert>>(
              notifier: alerts,
              isEmpty: (_) => false,
              builder: (_, _) => const SizedBox(),
            )
          : alert == null
              ? const EmptyView(
                  title: 'Alerta não encontrado',
                  message: 'Ele pode ter sido removido. Volte e escolha outro.',
                  icon: Icons.search_off,
                )
              : _content(context, alert),
    );
  }

  Widget _content(BuildContext context, Alert alert) {
    final theme = Theme.of(context);
    final inspections = context.watch<InspectionsProvider>();

    return ContentListView(
      padding: EdgeInsets.zero,
      children: [
        const HumanDecisionBanner(),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(alert.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm + 4),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SeverityChip(alert.severity),
                  ConfidenceChip(alert.confidence),
                  AlertStatusChip(alert.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              Text(
                '${alert.location} · ${Formatters.timeAgo(alert.createdAt)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _RelatedLinks(alert: alert),
              const SizedBox(height: AppSpacing.md),
              _WhyCard(alert: alert, fieldCheck: inspections.latestCheck(alert.id)),
              const SizedBox(height: AppSpacing.md),
              ChartCard(
                title: 'Dados que justificam o alerta',
                summary: '${alert.evidenceLabel}. Começa em ${_format(alert.evidence.first)} '
                    'e termina em ${_format(alert.evidence.last)}.',
                height: 160,
                chart: SimpleLineChart(
                  labels: [for (var i = 0; i < alert.evidence.length; i++) '${i + 1}'],
                  values: alert.evidence,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _Section(
                icon: alert.confidence.icon,
                title: 'Confiança ${alert.confidence.label}',
                text: alert.confidenceReason,
              ),
              const SizedBox(height: AppSpacing.md),
              _Section(
                icon: Icons.warning_amber_rounded,
                title: 'Limitações',
                text: alert.limitations,
              ),
              if (alert.binId != null) ...[
                const SectionTitle('Vistorias desta lixeira'),
                _FieldChecks(alert: alert),
              ],
              const SectionTitle('O que você vai fazer?'),
              _DecisionCard(alert: alert, busy: _saving, onDecide: (kind) => _decide(alert, kind)),
              const SectionTitle('Histórico do alerta'),
              _Timeline(alert: alert),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }

  String _format(double value) => Formatters.decimal(value);
}

/// "Por que este alerta apareceu?": o que o sistema viu, quais condições da regra
/// foram atendidas e a conclusão, em três passos.
class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.alert, required this.fieldCheck});

  final Alert alert;

  /// Vistoria mais recente que respondeu se confirma este alerta.
  final Inspection? fieldCheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;

    Widget step(int number, String title, List<Widget> body) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text('$number. $title', style: theme.textTheme.titleSmall),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            ...body,
          ],
        );

    Widget line(IconData icon, Color color, String text, {String? semanticPrefix}) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Semantics(
            label: '${semanticPrefix ?? ''}$text',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        );

    final check = fieldCheck;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Por que este alerta apareceu?', style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          step(1, 'O que o sistema viu', [Text(alert.detected, style: theme.textTheme.bodyLarge)]),
          const SizedBox(height: AppSpacing.md),
          step(2, 'Condições da regra', [
            for (final condition in alert.conditions)
              line(
                condition.met ? Icons.check_circle : Icons.info_outline,
                condition.met ? colors.success : colors.warning,
                condition.text,
                semanticPrefix: condition.met ? 'Atendida: ' : 'Não atendida: ',
              ),
            Text(
              'Regra: ${alert.rule}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          step(3, 'Conclusão', [
            Text(
              'Por isso o alerta tem gravidade ${alert.severity.label.toLowerCase()} e '
              'confiança ${alert.confidence.label}. ${alert.suggestedAction}',
              style: theme.textTheme.bodyLarge,
            ),
            if (check != null) ...[
              const SizedBox(height: AppSpacing.sm),
              line(
                switch (check.check!) {
                  AlertCheck.confirms => Icons.verified_outlined,
                  AlertCheck.denies => Icons.report_gmailerrorred_outlined,
                  AlertCheck.inconclusive => Icons.help_outline,
                },
                switch (check.check!) {
                  AlertCheck.confirms => colors.success,
                  AlertCheck.denies => colors.danger,
                  AlertCheck.inconclusive => colors.neutral,
                },
                switch (check.check!) {
                  AlertCheck.confirms =>
                    'Confirmado em campo pela vistoria de ${Formatters.shortDate(check.dateTime)}.',
                  AlertCheck.denies =>
                    'A vistoria de ${Formatters.shortDate(check.dateTime)} não confirmou este alerta. '
                        'Considere descartá-lo.',
                  AlertCheck.inconclusive =>
                    'A vistoria de ${Formatters.shortDate(check.dateTime)} foi inconclusiva. '
                        'Considere uma nova vistoria.',
                },
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

/// Vistorias da lixeira do alerta e o botão para conferir o alerta em campo.
class _FieldChecks extends StatelessWidget {
  const _FieldChecks({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final binId = alert.binId!;
    final items = context.watch<InspectionsProvider>().forBin(binId).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty) ...[
          const AppCard(child: Text('Ainda não há vistorias para esta lixeira.')),
          const SizedBox(height: AppSpacing.sm + 4),
        ] else
          for (final item in items) ...[
            AppCard(
              semanticLabel: '${item.type.label}, ${Formatters.dateTime(item.dateTime)}. '
                  '${item.description}. ${item.alertId == alert.id ? (item.check?.label ?? '') : ''}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.type.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${Formatters.dateTime(item.dateTime)} · gravidade ${item.severity.label.toLowerCase()}'
                    ' · ${item.authorName ?? 'anônima'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(item.description, style: theme.textTheme.bodyMedium),
                  if (item.alertId == alert.id && item.check != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Resposta sobre este alerta: ${item.check!.label}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
          ],
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_note),
          label: const Text('Verificar em campo (registrar vistoria)'),
          onPressed: () => context.pushNamed(
            AppRoutes.inspection,
            queryParameters: {'binId': binId, AppRoutes.alertParam: alert.id},
          ),
        ),
      ],
    );
  }
}

/// As decisões possíveis, cada uma com o que ela faz.
class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.alert, required this.busy, required this.onDecide});

  final Alert alert;
  final bool busy;
  final ValueChanged<DecisionKind> onDecide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = primaryDecision(alert);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(alert.status.icon, color: alert.status.color(context)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Situação atual: ${alert.status.label}', style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Escolha o que fazer. O app só registra a decisão: quem age é a sua equipe.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          for (final kind in decisionsFor(alert)) ...[
            const SizedBox(height: AppSpacing.sm + 4),
            _decisionButton(kind, kind == primary),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                kind.hint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _decisionButton(DecisionKind kind, bool primary) {
    final onPressed = busy ? null : () => onDecide(kind);
    final icon = Icon(kind.icon);
    final label = Text(kind.label(alert.type));
    return primary
        ? FilledButton.icon(onPressed: onPressed, icon: icon, label: label)
        : OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}

/// Linha do tempo: quando o sistema gerou o alerta e cada decisão tomada depois.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget row(IconData icon, Color color, String title, String when, {String? detail}) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Semantics(
            label: '$title. ${detail ?? ''} $when',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.bodyLarge),
                      if (detail != null) Text(detail, style: theme.textTheme.bodyMedium),
                      Text(when, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(
            AlertStatus.open.icon,
            AlertStatus.open.color(context),
            'Alerta gerado pelo sistema',
            Formatters.timeAgo(alert.createdAt),
          ),
          for (final event in alert.history)
            row(
              event.status.icon,
              event.status.color(context),
              event.action,
              'por ${event.by ?? 'usuário anônimo'} · ${Formatters.dateTime(event.at)}',
              detail: event.detail,
            ),
          if (alert.history.isEmpty)
            Text(
              'Nenhuma decisão registrada ainda.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// Atalhos do alerta para a lixeira, o mapa e o distrito dele.
class _RelatedLinks extends StatelessWidget {
  const _RelatedLinks({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final binId = alert.binId;
    final districtId = alert.districtId;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (binId != null)
          OutlinedButton.icon(
            onPressed: () => context.openBin(binId),
            icon: const Icon(Icons.recycling),
            label: const Text('Ver a lixeira'),
          ),
        if (binId != null)
          OutlinedButton.icon(
            onPressed: () => context.showBinOnMap(binId),
            icon: const Icon(Icons.place_outlined),
            label: const Text('Ver no mapa'),
          ),
        if (districtId != null)
          OutlinedButton.icon(
            onPressed: () => context.showDistrict(districtId),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ver o distrito'),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
                const SizedBox(height: AppSpacing.xs),
                Text(text, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
