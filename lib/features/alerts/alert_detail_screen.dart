import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/core/widgets/charts/chart_card.dart';
import 'package:recicla_radar_sp/core/widgets/charts/simple_line_chart.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/features/alerts/human_decision_banner.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

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
    // Abrir o alerta já conta como ter visto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AlertsProvider>().markSeen(widget.alertId);
    });
  }

  Future<void> _decide(AlertStatus status) async {
    final provider = context.read<AlertsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await provider.updateStatus(widget.alertId, status);
      messenger.showSnackBar(SnackBar(content: Text('Alerta marcado como "${status.label}".')));
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
    return ListView(
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
              _Section(
                icon: Icons.visibility_outlined,
                title: 'O que foi detectado',
                text: alert.detected,
              ),
              const SizedBox(height: AppSpacing.md),
              ChartCard(
                title: 'Evidência',
                summary: '${alert.evidenceLabel}. Começa em ${_format(alert.evidence.first)} '
                    'e termina em ${_format(alert.evidence.last)}.',
                height: 160,
                chart: SimpleLineChart(
                  labels: [for (var i = 0; i < alert.evidence.length; i++) '${i + 1}'],
                  values: alert.evidence,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _Section(icon: Icons.rule, title: 'Regra aplicada', text: alert.rule),
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
              const SizedBox(height: AppSpacing.md),
              _Section(
                icon: Icons.lightbulb_outline,
                title: 'Ação sugerida',
                text: alert.suggestedAction,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Qual é a sua decisão?', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm + 4),
              _DecisionButtons(
                current: alert.status,
                busy: _saving,
                onDecide: _decide,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }

  String _format(double value) => Formatters.decimal(value);
}

class _DecisionButtons extends StatelessWidget {
  const _DecisionButtons({required this.current, required this.busy, required this.onDecide});

  final AlertStatus current;
  final bool busy;
  final ValueChanged<AlertStatus> onDecide;

  @override
  Widget build(BuildContext context) {
    Widget button(AlertStatus status, {bool primary = false}) {
      final onPressed = busy || current == status ? null : () => onDecide(status);
      final icon = Icon(status.icon);
      final label = Text(current == status ? '${status.label} (atual)' : status.label);
      return primary
          ? FilledButton.icon(onPressed: onPressed, icon: icon, label: label)
          : OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button(AlertStatus.inAnalysis),
        const SizedBox(height: AppSpacing.sm + 4),
        button(AlertStatus.resolved, primary: true),
        const SizedBox(height: AppSpacing.sm + 4),
        button(AlertStatus.discarded),
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
