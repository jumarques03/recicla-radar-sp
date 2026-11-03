/// Validadores de formulário. Retornam `null` quando o valor é válido ou uma
/// mensagem curta que diz o que fazer.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value, {String field = 'este campo'}) {
    if (value == null || value.trim().isEmpty) return 'Preencha $field.';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().length < 3) {
      return 'Digite seu nome completo.';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Digite seu e-mail.';
    if (!_email.hasMatch(text)) {
      return 'E-mail inválido. Use o formato nome@exemplo.com.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Digite sua senha.';
    if (value.length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Repita a senha.';
    if (value != original) return 'As senhas não são iguais. Digite de novo.';
    return null;
  }

  static String? description(String? value, {int minLength = 10}) {
    final length = value?.trim().length ?? 0;
    if (length == 0) return 'Descreva o que você viu.';
    if (length < minLength) {
      return 'Escreva pelo menos $minLength letras. Faltam ${minLength - length}.';
    }
    return null;
  }

  static String? notFuture(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Escolha a data e a hora.';
    if (value.isAfter(now ?? DateTime.now())) {
      return 'A data e a hora não podem ser no futuro.';
    }
    return null;
  }
}
