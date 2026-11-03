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
    required this.binId,
    required this.type,
    required this.severity,
    required this.description,
    required this.dateTime,
    required this.needsAction,
  });

  final String binId;
  final OccurrenceType type;
  final InspectionSeverity severity;
  final String description;
  final DateTime dateTime;

  /// Precisa de coleta ou reparo.
  final bool needsAction;
}
