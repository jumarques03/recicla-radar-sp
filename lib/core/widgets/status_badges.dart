import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/status_colors.dart';
import 'package:recicla_radar_sp/core/widgets/status_chip.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/district.dart';

/// Ícone e cor de cada status, em um só lugar.
extension BinStatusVisuals on BinStatus {
  IconData get icon => switch (this) {
        BinStatus.operating => Icons.check_circle_outline,
        BinStatus.almostFull => Icons.warning_amber_rounded,
        BinStatus.full => Icons.error_outline,
        BinStatus.maintenance => Icons.build_outlined,
        BinStatus.offline => Icons.wifi_off,
      };

  Color color(BuildContext context) {
    final colors = context.statusColors;
    return switch (this) {
      BinStatus.operating => colors.success,
      BinStatus.almostFull => colors.warning,
      BinStatus.full => colors.danger,
      BinStatus.maintenance || BinStatus.offline => colors.neutral,
    };
  }
}

extension AlertSeverityVisuals on AlertSeverity {
  IconData get icon => switch (this) {
        AlertSeverity.low => Icons.info_outline,
        AlertSeverity.medium => Icons.warning_amber_rounded,
        AlertSeverity.high => Icons.priority_high,
        AlertSeverity.critical => Icons.report_outlined,
      };

  Color color(BuildContext context) {
    final colors = context.statusColors;
    return switch (this) {
      AlertSeverity.low => colors.neutral,
      AlertSeverity.medium => colors.warning,
      AlertSeverity.high || AlertSeverity.critical => colors.danger,
    };
  }
}

extension DemandLevelVisuals on DemandLevel {
  IconData get icon => switch (this) {
        DemandLevel.low => Icons.trending_down,
        DemandLevel.medium => Icons.trending_flat,
        DemandLevel.high => Icons.trending_up,
      };

  Color color(BuildContext context) {
    final colors = context.statusColors;
    return switch (this) {
      DemandLevel.low => colors.success,
      DemandLevel.medium => colors.warning,
      DemandLevel.high => colors.danger,
    };
  }
}

extension AlertStatusVisuals on AlertStatus {
  IconData get icon => switch (this) {
        AlertStatus.open => Icons.notifications_active_outlined,
        AlertStatus.inAnalysis => Icons.search,
        AlertStatus.resolved => Icons.check_circle_outline,
        AlertStatus.discarded => Icons.block,
      };

  Color color(BuildContext context) {
    final colors = context.statusColors;
    return switch (this) {
      AlertStatus.open => colors.warning,
      AlertStatus.inAnalysis => colors.info,
      AlertStatus.resolved => colors.success,
      AlertStatus.discarded => colors.neutral,
    };
  }
}

extension ConfidenceVisuals on Confidence {
  IconData get icon => switch (this) {
        Confidence.high => Icons.verified_outlined,
        Confidence.medium => Icons.rule,
        Confidence.low => Icons.help_outline,
      };

  Color color(BuildContext context) {
    final colors = context.statusColors;
    return switch (this) {
      Confidence.high => colors.success,
      Confidence.medium => colors.warning,
      Confidence.low => colors.neutral,
    };
  }
}

class BinStatusChip extends StatelessWidget {
  const BinStatusChip(this.status, {super.key});

  final BinStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusChip(icon: status.icon, label: status.label, color: status.color(context));
}

class SeverityChip extends StatelessWidget {
  const SeverityChip(this.severity, {super.key});

  final AlertSeverity severity;

  @override
  Widget build(BuildContext context) => StatusChip(
        icon: severity.icon,
        label: 'Gravidade ${severity.label.toLowerCase()}',
        color: severity.color(context),
      );
}

class ConfidenceChip extends StatelessWidget {
  const ConfidenceChip(this.confidence, {super.key});

  final Confidence confidence;

  @override
  Widget build(BuildContext context) => StatusChip(
        icon: confidence.icon,
        label: 'Confiança ${confidence.label}',
        color: confidence.color(context),
      );
}

class AlertStatusChip extends StatelessWidget {
  const AlertStatusChip(this.status, {super.key});

  final AlertStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusChip(icon: status.icon, label: status.label, color: status.color(context));
}

class DemandLevelChip extends StatelessWidget {
  const DemandLevelChip(this.level, {super.key});

  final DemandLevel level;

  @override
  Widget build(BuildContext context) => StatusChip(
        icon: level.icon,
        label: 'Demanda ${level.label.toLowerCase()}',
        color: level.color(context),
      );
}
