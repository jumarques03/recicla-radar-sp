/// Números que controlam a simulação. Tudo aqui é uma suposição do projeto,
/// não vem de nenhuma fonte oficial.
abstract final class SimulationConfig {
  /// Parte do material coletado que as cooperativas de fato reaproveitam.
  /// O restante é rejeito (material sujo ou misturado). Gera o número de
  /// "kg fora do aterro".
  static const double recoveryRate = 0.75;

  /// Pontos de descarte com intensidade a partir deste valor ganham duas lixeiras.
  static const int busyPointIntensity = 8;
}
