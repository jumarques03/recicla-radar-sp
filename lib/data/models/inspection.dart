enum OccurrenceType {
  full('Lixeira cheia'),
  damaged('Lixeira danificada'),
  vandalized('Vandalismo'),
  other('Outro');

  const OccurrenceType(this.label);
  final String label;
}

enum InspectionSeverity {
  low('Baixa'),
  medium('Média'),
  high('Alta');

  const InspectionSeverity(this.label);
  final String label;
}

/// Vistoria registrada por um fiscal.
class Inspection {
  const Inspection({
    required this.id,
    required this.binId,
    required this.type,
    required this.severity,
    required this.description,
    required this.dateTime,
    required this.needsAction,
    this.authorName,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'] as String,
      binId: json['binId'] as String,
      type: OccurrenceType.values.byName(json['type'] as String),
      severity: InspectionSeverity.values.byName(json['severity'] as String),
      description: json['description'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      needsAction: json['needsAction'] as bool,
      authorName: json['authorName'] as String?,
    );
  }

  final String id;
  final String binId;
  final OccurrenceType type;
  final InspectionSeverity severity;
  final String description;

  /// Quando a ocorrência aconteceu.
  final DateTime dateTime;

  /// Precisa de coleta ou reparo.
  final bool needsAction;

  /// Nome de quem registrou. Fica vazio quando a pessoa não deu consentimento
  /// para o uso dos dados pessoais: a vistoria é anônima.
  final String? authorName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'binId': binId,
        'type': type.name,
        'severity': severity.name,
        'description': description,
        'dateTime': dateTime.toIso8601String(),
        'needsAction': needsAction,
        'authorName': authorName,
      };
}
