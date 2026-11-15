import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';

/// Abre a explicação de como os alertas são gerados, para quem quer entender
/// as regras sem abrir um alerta.
Future<void> showAlertsExplainer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    // Fora da aba atual, para a barra de navegação não cobrir o fim do texto.
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (context) => const _Explainer(),
  );
}

class _Rule {
  const _Rule(this.title, this.when, this.severity);

  final String title;
  final String when;
  final String severity;
}

const _rules = [
  _Rule(
    'Previsão de enchimento',
    'O enchimento passa do limite das Configurações (padrão 80%) ou a previsão é de lotação em menos de 24 h. '
        'O ritmo vem das leituras desde a última coleta; com menos de 4 leituras o app não prevê o tempo.',
    'Crítica até 4 h, alta até 12 h, média até 24 h.',
  ),
  _Rule(
    'Sem sinal',
    'A lixeira não envia leituras há mais de 12 h. Lixeira em manutenção não gera alerta.',
    'Alta; crítica acima de 48 h.',
  ),
  _Rule(
    'Leitura fora do padrão',
    'Um material passa de 2 vezes a média de 30 dias, por 2 dias seguidos ou mais.',
    'Média; alta a partir de 3 vezes a média.',
  ),
  _Rule(
    'Coleta abaixo do esperado',
    'O volume do distrito nos últimos 7 dias cai mais de 15% em relação à média das 4 semanas anteriores.',
    'Média; alta acima de 30% de queda.',
  ),
  _Rule(
    'Demanda sem cobertura',
    'O índice de demanda do distrito é 85 ou mais, e há no máximo 2 lixeiras funcionando.',
    'Média; alta se nenhuma lixeira funciona.',
  ),
  _Rule(
    'Vistoria de campo',
    'Uma vistoria dos últimos 7 dias tem gravidade alta ou aponta lixeira danificada ou vandalismo.',
    'Crítica (gravidade alta com pedido de coleta), alta ou média.',
  ),
];

class _Explainer extends StatelessWidget {
  const _Explainer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        children: [
          Semantics(
            header: true,
            child: Text('Como os alertas são gerados', style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'O app lê as leituras das lixeiras, aplica estas regras e sugere alertas. '
            'Cada alerta mostra o que foi visto, quais condições foram atendidas, '
            'a confiança e as limitações. Quem decide o que fazer é sempre uma pessoa.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final rule in _rules) ...[
            Semantics(
              container: true,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 4),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Aparece quando: ${rule.when}', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Gravidade: ${rule.severity}', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
          Text('Confiança', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Alta, média ou baixa, conforme a quantidade de leituras, a regularidade dos dados e '
            'quantas lixeiras mostram o mesmo problema. O motivo aparece escrito em cada alerta.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Vistorias', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ao registrar uma vistoria de uma lixeira com alerta ativo, você pode dizer se ela '
            'confirma o alerta. A resposta aparece no alerta, e a Visão geral mostra quantos '
            'alertas conferidos em campo foram confirmados.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendi')),
        ],
      ),
    );
  }
}
