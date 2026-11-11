import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/responsive/responsive.dart';
import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/utils/validators.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/inspection.dart';
import 'package:recicla_radar_sp/domain/inspection_rule.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';
import 'package:recicla_radar_sp/state/bins_provider.dart';
import 'package:recicla_radar_sp/state/inspections_provider.dart';
import 'package:recicla_radar_sp/state/session_provider.dart';
import 'package:recicla_radar_sp/state/settings_provider.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key, this.binId});

  /// Lixeira já escolhida, quando a pessoa vem da tela de detalhe.
  final String? binId;

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _binKey = GlobalKey<FormFieldState<String>>();
  final _typeKey = GlobalKey<FormFieldState<OccurrenceType>>();
  final _descriptionKey = GlobalKey<FormFieldState<String>>();
  final _dateKey = GlobalKey<FormFieldState<String>>();
  final _description = TextEditingController();
  final _dateText = TextEditingController();
  late String? _binId = widget.binId;
  OccurrenceType? _type;
  InspectionSeverity _severity = InspectionSeverity.medium;
  DateTime? _dateTime;
  bool _needsAction = false;
  bool _busy = false;

  @override
  void dispose() {
    _description.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: 'Quando aconteceu?',
      cancelText: 'Cancelar',
      confirmText: 'Escolher',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime ?? now),
      helpText: 'Que horas?',
      cancelText: 'Cancelar',
      confirmText: 'Escolher',
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dateText.text = Formatters.dateTime(_dateTime!);
    });
    _formKey.currentState?.validate();
  }

  /// Rola a tela até o primeiro campo com erro, na ordem em que aparecem.
  void _scrollToFirstError() {
    final fields = <GlobalKey<FormFieldState<dynamic>>>[
      _binKey,
      _typeKey,
      _descriptionKey,
      _dateKey,
    ];
    for (final field in fields) {
      if (field.currentState?.hasError ?? false) {
        Scrollable.ensureVisible(
          field.currentContext!,
          alignment: 0.15,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return;
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confira os campos marcados em vermelho.')),
      );
      return;
    }
    final inspections = context.read<InspectionsProvider>();
    final alerts = context.read<AlertsProvider>();
    final consent = context.read<SettingsProvider>().consent;
    final author = context.read<SessionProvider>().user?.name;

    final inspection = Inspection(
      id: 'insp-${DateTime.now().microsecondsSinceEpoch}',
      binId: _binId!,
      type: _type!,
      severity: _severity,
      description: _description.text.trim(),
      dateTime: _dateTime!,
      needsAction: _needsAction,
      // Sem consentimento para o uso dos dados pessoais, a vistoria é anônima.
      authorName: consent ? author : null,
    );

    setState(() => _busy = true);
    try {
      await inspections.submit(inspection);
      // Uma vistoria grave gera um alerta; recalcula para ele aparecer na hora.
      alerts.load();
      if (!mounted) return;
      // O botão volta ao normal antes do aviso, para a rodinha não girar atrás dele.
      setState(() => _busy = false);
      final createdAlert = const InspectionRule().evaluate(inspection, DateTime.now()) != null;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.secondary),
          title: const Text('Vistoria registrada'),
          content: Text(
            createdAlert
                ? 'Obrigado! Esta vistoria gerou um alerta para a equipe. Você o encontra na aba Alertas.'
                : 'Obrigado! Sua vistoria foi salva neste aparelho.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a vistoria. Tente de novo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Atalho para o pedido mais comum: escreve a frase pronta e marca que precisa de coleta.
  void _fillCollectRequest() {
    setState(() {
      _description.text = 'Coletar lixo da lixeira.';
      _needsAction = true;
    });
    // O campo "O que aconteceu?" só muda de valor se avisarmos o próprio campo.
    if (_type == null) _typeKey.currentState?.didChange(OccurrenceType.full);
  }

  @override
  Widget build(BuildContext context) {
    final bins = context.watch<BinsProvider>();
    final consent = context.select<SettingsProvider, bool>((s) => s.consent);
    final authorName = context.select<SessionProvider, String?>((s) => s.user?.name);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar vistoria')),
      body: bins.data == null
          ? (bins.error != null
              ? ErrorView(message: bins.error!, onRetry: bins.load)
              : const LoadingView())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ContentListView(
                  maxWidth: Breakpoints.formMax,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _ConsentNote(consent: consent, authorName: authorName),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      key: _binKey,
                      initialValue: _binId,
                      isExpanded: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: 'Lixeira',
                        prefixIcon: Icon(Icons.recycling),
                      ),
                      items: [
                        for (final Bin bin in bins.data!)
                          DropdownMenuItem(
                            value: bin.id,
                            child: Text(bin.name, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      validator: (value) => value == null ? 'Escolha a lixeira.' : null,
                      onChanged: (value) => setState(() => _binId = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<OccurrenceType>(
                      key: _typeKey,
                      initialValue: _type,
                      isExpanded: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: 'O que aconteceu?',
                        prefixIcon: Icon(Icons.report_problem_outlined),
                      ),
                      items: [
                        for (final type in OccurrenceType.values)
                          DropdownMenuItem(value: type, child: Text(type.label)),
                      ],
                      validator: (value) => value == null ? 'Escolha o tipo de ocorrência.' : null,
                      onChanged: (value) => setState(() => _type = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Gravidade', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<InspectionSeverity>(
                      segments: [
                        for (final severity in InspectionSeverity.values)
                          ButtonSegment(value: severity, label: Text(severity.label)),
                      ],
                      selected: {_severity},
                      onSelectionChanged: (values) => setState(() => _severity = values.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        onPressed: _fillCollectRequest,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Preencher: coletar lixo da lixeira'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: _descriptionKey,
                      controller: _description,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: Validators.description,
                      decoration: const InputDecoration(
                        labelText: 'Descreva o que você viu',
                        helperText: 'Escreva pelo menos 10 letras.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: _dateKey,
                      controller: _dateText,
                      readOnly: true,
                      onTap: _pickDateTime,
                      validator: (_) => Validators.notFuture(_dateTime),
                      decoration: InputDecoration(
                        labelText: 'Data e hora',
                        hintText: 'Toque para escolher',
                        prefixIcon: const Icon(Icons.event),
                        suffixIcon: IconButton(
                          tooltip: 'Escolher data e hora',
                          icon: const Icon(Icons.edit_calendar_outlined),
                          onPressed: _pickDateTime,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      value: _needsAction,
                      onChanged: (value) => setState(() => _needsAction = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Precisa de coleta ou reparo'),
                      subtitle: Text(_needsAction ? 'Sim, precisa.' : 'Não precisa por enquanto.'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Salvar vistoria'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Avisa se a vistoria vai levar o nome da pessoa ou ser anônima.
class _ConsentNote extends StatelessWidget {
  const _ConsentNote({required this.consent, required this.authorName});

  final bool consent;
  final String? authorName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(consent ? Icons.badge_outlined : Icons.visibility_off_outlined, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    consent
                        ? 'Esta vistoria será registrada com o seu nome${authorName == null ? '' : ' ($authorName)'}.'
                        : 'Esta vistoria será registrada de forma anônima, sem o seu nome.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (!consent)
                    TextButton(
                      onPressed: () => context.pushNamed(AppRoutes.settings),
                      child: const Text('Mudar nas Configurações'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
