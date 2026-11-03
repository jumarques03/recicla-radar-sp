import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/utils/validators.dart';
import 'package:recicla_radar_sp/core/widgets/state_views.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/inspection.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/bins_provider.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key, this.binId});

  /// Lixeira já escolhida, quando a pessoa vem da tela de detalhe.
  final String? binId;

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confira os campos marcados em vermelho.')),
      );
      return;
    }
    final repository = context.read<InspectionRepository>();
    setState(() => _busy = true);
    try {
      await repository.submit(Inspection(
        binId: _binId!,
        type: _type!,
        severity: _severity,
        description: _description.text.trim(),
        dateTime: _dateTime!,
        needsAction: _needsAction,
      ));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.secondary),
          title: const Text('Vistoria enviada'),
          content: Text(
            _needsAction
                ? 'Obrigado! Avisamos que esta lixeira precisa de coleta ou reparo.'
                : 'Obrigado! Sua vistoria foi registrada.',
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
          const SnackBar(content: Text('Não foi possível enviar. Confira a internet e tente de novo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bins = context.watch<BinsProvider>();
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
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    DropdownButtonFormField<String>(
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
                    TextFormField(
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
                          : const Icon(Icons.send),
                      label: const Text('Enviar vistoria'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
