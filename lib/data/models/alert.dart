enum AlertType {
  fillPrediction('Previsão de enchimento'),
  anomaly('Leitura fora do padrão'),
  offline('Sem sinal'),
  lowCollection('Coleta abaixo do esperado'),
  lowCoverage('Demanda sem cobertura'),
  inspection('Vistoria de campo');

  const AlertType(this.label);
  final String label;
}

enum AlertSeverity {
  low('Baixa'),
  medium('Média'),
  high('Alta'),
  critical('Crítica');

  const AlertSeverity(this.label);
  final String label;
}

enum AlertStatus {
  open('Aberto'),
  inAnalysis('Em análise'),
  teamAssigned('Equipe alocada'),
  resolved('Resolvido'),
  discarded('Descartado');

  const AlertStatus(this.label);
  final String label;

  bool get isActive => this == open || this == inAnalysis || this == teamAssigned;
}

enum Confidence {
  high('alta'),
  medium('média'),
  low('baixa');

  const Confidence(this.label);
  final String label;
}

/// Uma condição da regra que gerou o alerta, com o valor encontrado.
/// [met] diz se ela foi atendida: é o que explica "por que este alerta apareceu".
class AlertCondition {
  const AlertCondition(this.text, this.met);

  final String text;
  final bool met;
}

/// Uma decisão que uma pessoa tomou sobre o alerta (assumir, alocar equipe,
/// concluir, descartar ou reabrir). O conjunto delas forma o histórico do alerta.
class AlertEvent {
  const AlertEvent({
    required this.status,
    required this.action,
    required this.at,
    this.detail,
    this.by,
  });

  factory AlertEvent.fromJson(Map<String, dynamic> json) {
    return AlertEvent(
      status: AlertStatus.values.byName(json['status'] as String),
      action: json['action'] as String,
      detail: json['detail'] as String?,
      by: json['by'] as String?,
      at: DateTime.parse(json['at'] as String),
    );
  }

  /// Situação do alerta depois desta decisão.
  final AlertStatus status;

  /// O que a pessoa fez, em uma frase ("Alocou a Equipe de coleta Centro").
  final String action;

  /// Prazo, resultado ou observação.
  final String? detail;

  /// Nome de quem decidiu. Vazio quando não há consentimento para o uso dos dados pessoais.
  final String? by;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'action': action,
        'detail': detail,
        'by': by,
        'at': at.toIso8601String(),
      };
}

/// Alerta preditivo. Ele sugere; a decisão é sempre de uma pessoa.
class Alert {
  const Alert({
    required this.id,
    required this.title,
    required this.type,
    required this.severity,
    required this.status,
    required this.confidence,
    required this.createdAt,
    required this.location,
    required this.detected,
    required this.evidence,
    required this.evidenceLabel,
    required this.rule,
    required this.confidenceReason,
    required this.limitations,
    required this.suggestedAction,
    this.binId,
    this.districtId,
    this.conditions = const [],
    this.history = const [],
  });

  final String id;
  final String title;
  final AlertType type;
  final AlertSeverity severity;
  final AlertStatus status;
  final Confidence confidence;
  final DateTime createdAt;
  final String location;
  final String? binId;

  /// Distrito do alerta, para ligar o alerta ao mapa de demanda e às lixeiras.
  final String? districtId;
  final String detected;

  /// Série curta usada no mini gráfico de evidência.
  final List<double> evidence;
  final String evidenceLabel;
  final String rule;
  final String confidenceReason;
  final String limitations;
  final String suggestedAction;

  /// Condições da regra, com o valor encontrado em cada uma.
  final List<AlertCondition> conditions;

  /// Decisões já tomadas por pessoas, da mais antiga para a mais recente.
  final List<AlertEvent> history;

  Alert copyWith({AlertStatus? status, List<AlertEvent>? history}) {
    return Alert(
      id: id,
      title: title,
      type: type,
      severity: severity,
      status: status ?? this.status,
      confidence: confidence,
      createdAt: createdAt,
      location: location,
      binId: binId,
      districtId: districtId,
      detected: detected,
      evidence: evidence,
      evidenceLabel: evidenceLabel,
      rule: rule,
      confidenceReason: confidenceReason,
      limitations: limitations,
      suggestedAction: suggestedAction,
      conditions: conditions,
      history: history ?? this.history,
    );
  }
}
