import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/utils/app_exception.dart';
import 'package:recicla_radar_sp/core/utils/validators.dart';
import 'package:recicla_radar_sp/data/models/app_user.dart';
import 'package:recicla_radar_sp/features/auth/auth_scaffold.dart';
import 'package:recicla_radar_sp/state/session_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole _role = UserRole.inspector;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = context.read<SessionProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      );
      // O roteador leva sozinho para a tela inicial quando a sessão começa.
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthScaffold(
      showBack: true,
      title: 'Criar conta',
      subtitle: 'Preencha os dados abaixo. Leva menos de um minuto.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              MessageBanner(message: _error!, isError: true),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: Validators.name,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: Validators.email,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PasswordField(
              controller: _password,
              label: 'Senha',
              validator: Validators.password,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: AppSpacing.md),
            PasswordField(
              controller: _confirm,
              label: 'Repetir a senha',
              validator: (value) => Validators.confirmPassword(value, _password.text),
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Qual é o seu cargo?', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<UserRole>(
              segments: [
                for (final role in UserRole.values)
                  ButtonSegment(value: role, label: Text(role.label)),
              ],
              selected: {_role},
              onSelectionChanged: (values) => setState(() => _role = values.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            FormField<bool>(
              initialValue: false,
              validator: (accepted) => accepted == true
                  ? null
                  : 'Para criar a conta, aceite o uso dos seus dados.',
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: field.value,
                    onChanged: field.didChange,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Concordo com o uso dos meus dados pessoais'),
                    subtitle: const Text(
                      'Usamos seu nome e e-mail só para identificar quem registra '
                      'vistorias. Não compartilhamos com terceiros.',
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Text(
                        field.errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
