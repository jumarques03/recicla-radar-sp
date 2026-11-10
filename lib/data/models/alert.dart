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
  resolved('Resolvido'),
  discarded('Descartado');

  const AlertStatus(this.label);
  final String label;

  bool get isActive => this == open || this == inAnalysis;
}

enum Confidence {
  high('alta'),
  medium('média'),
  low('baixa');

  const Confidence(this.label);
  final String label;
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

  Alert copyWith({AlertStatus? status}) {
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
    );
  }
}
