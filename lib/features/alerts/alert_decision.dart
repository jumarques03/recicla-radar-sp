import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';

/// As decisões que uma pessoa pode tomar sobre um alerta. Cada uma diz o que
/// vai acontecer, em vez de só mudar um status.
enum DecisionKind {
  investigate(AlertStatus.inAnalysis, Icons.search),
  assignTeam(AlertStatus.teamAssigned, Icons.groups_outlined),
  complete(AlertStatus.resolved, Icons.check_circle_outline),
  discard(AlertStatus.discarded, Icons.block),
  reopen(AlertStatus.open, Icons.replay);

  const DecisionKind(this.resultingStatus, this.icon);

  /// Situação do alerta depois desta decisão.
  final AlertStatus resultingStatus;
  final IconData icon;

  /// Texto do botão. O de alocar equipe muda conforme o tipo de alerta.
  String label(AlertType type) => switch (this) {
        investigate => 'Assumir e investigar',
        assignTeam => switch (type) {
            AlertType.fillPrediction => 'Alocar equipe de coleta',
            AlertType.offline => 'Enviar fiscal conferir',
            AlertType.inspection => 'Alocar equipe de coleta ou reparo',
            _ => 'Designar responsável',
          },
        complete => 'Concluir alerta',
        discard => 'Descartar alerta',
        reopen => 'Reabrir alerta',
      };

  /// Frase curta explicando o que o botão faz.
  String get hint => switch (this) {
        investigate => 'Marca como "Em análise".',
        assignTeam => 'Escolha quem vai agir e o prazo.',
        complete => 'Informe o resultado.',
        discard => 'Informe o motivo.',
        reopen => 'O alerta volta para "Aberto".',
      };

  /// Opções de escolha da decisão (equipe, resultado ou motivo). Vazio quando não há.
  List<String> choices(AlertType type) => switch (this) {
        assignTeam => switch (type) {
            AlertType.fillPrediction || AlertType.inspection => const [
                'Equipe de coleta Centro',
                'Equipe de coleta Zona Sul',
                'Equipe de coleta Zona Leste',
                'Equipe de coleta Zona Norte',
                'Equipe de reparo',
              ],
            AlertType.offline => const [
                'Fiscal de campo Centro',
                'Fiscal de campo Zona Sul',
                'Equipe de manutenção de sensores',
              ],
            _ => const ['Fiscal de campo', 'Planejamento e expansão', 'Gestão do distrito'],
          },
        complete => switch (type) {
            AlertType.fillPrediction => const ['Coleta realizada', 'Já estava coletada', 'Outro resultado'],
            AlertType.offline => const ['Equipamento reparado', 'Equipamento substituído', 'Nada encontrado'],
            AlertType.inspection => const ['Coleta realizada', 'Reparo feito', 'Nada encontrado'],
            _ => const ['Providência tomada', 'Nada encontrado', 'Outro resultado'],
          },
        discard => const ['Falso alarme', 'Já resolvido', 'Dado incorreto', 'Outro motivo'],
        _ => const [],
      };

  /// Título da pergunta que aparece na folha de confirmação.
  String? get choiceTitle => switch (this) {
        assignTeam => 'Quem vai agir?',
        complete => 'Qual foi o resultado?',
        discard => 'Por que descartar?',
        _ => null,
      };
}

/// Prazos que a pessoa pode dar à equipe alocada.
enum DecisionDeadline {
  today('Hoje', 0),
  tomorrow('Amanhã', 1),
  threeDays('Em 3 dias', 3);

  const DecisionDeadline(this.label, this.days);
  final String label;
  final int days;

  DateTime date(DateTime now) => now.add(Duration(days: days));
}

/// Quais decisões aparecem para o alerta, conforme a situação dele.
List<DecisionKind> decisionsFor(Alert alert) {
  return switch (alert.status) {
    AlertStatus.open => const [
        DecisionKind.investigate,
        DecisionKind.assignTeam,
        DecisionKind.complete,
        DecisionKind.discard,
      ],
    AlertStatus.inAnalysis => const [DecisionKind.assignTeam, DecisionKind.complete, DecisionKind.discard],
    AlertStatus.teamAssigned => const [DecisionKind.complete, DecisionKind.assignTeam, DecisionKind.discard],
    AlertStatus.resolved || AlertStatus.discarded => const [DecisionKind.reopen],
  };
}

/// A decisão que mais provavelmente vem a seguir, destacada com o botão cheio.
DecisionKind primaryDecision(Alert alert) {
  return switch (alert.status) {
    AlertStatus.open => switch (alert.type) {
        AlertType.fillPrediction || AlertType.offline || AlertType.inspection => DecisionKind.assignTeam,
        _ => DecisionKind.investigate,
      },
    AlertStatus.inAnalysis => DecisionKind.assignTeam,
    AlertStatus.teamAssigned => DecisionKind.complete,
    AlertStatus.resolved || AlertStatus.discarded => DecisionKind.reopen,
  };
}

/// Monta o registro da decisão. [choice] é a equipe, o resultado ou o motivo;
/// [note] é a observação opcional.
AlertEvent buildDecisionEvent({
  required DecisionKind kind,
  required String? choice,
  required String note,
  required DecisionDeadline deadline,
  required String? by,
  required DateTime now,
}) {
  final action = switch (kind) {
    DecisionKind.investigate => 'Assumiu o alerta e começou a investigar',
    DecisionKind.assignTeam => 'Alocou: $choice',
    DecisionKind.complete => 'Concluiu o alerta: $choice',
    DecisionKind.discard => 'Descartou o alerta: $choice',
    DecisionKind.reopen => 'Reabriu o alerta',
  };
  final parts = [
    if (kind == DecisionKind.assignTeam)
      'Prazo: ${deadline.label.toLowerCase()} (${Formatters.shortDate(deadline.date(now))})',
    if (note.trim().isNotEmpty) 'Observação: ${note.trim()}',
  ];
  return AlertEvent(
    status: kind.resultingStatus,
    action: action,
    detail: parts.isEmpty ? null : parts.join(' · '),
    by: by,
    at: now,
  );
}
