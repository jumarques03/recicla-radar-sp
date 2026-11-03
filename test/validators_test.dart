import 'package:flutter_test/flutter_test.dart';

import 'package:recicla_radar_sp/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('aceita e-mail válido', () {
      expect(Validators.email('ana@exemplo.com'), isNull);
    });

    test('recusa vazio e formato inválido', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('ana@'), isNotNull);
      expect(Validators.email('ana exemplo.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('exige pelo menos 6 caracteres', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('confirmação precisa ser igual', () {
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
      expect(Validators.confirmPassword('abc124', 'abc123'), isNotNull);
    });
  });

  group('Validators.description', () {
    test('exige 10 caracteres e diz quantos faltam', () {
      expect(Validators.description('curta'), contains('Faltam 5'));
      expect(Validators.description('lixeira quebrada'), isNull);
    });
  });

  group('Validators.notFuture', () {
    final now = DateTime(2026, 11, 3, 12);

    test('aceita data passada', () {
      expect(Validators.notFuture(DateTime(2026, 11, 3, 8), now: now), isNull);
    });

    test('recusa data futura ou vazia', () {
      expect(Validators.notFuture(DateTime(2026, 11, 3, 13), now: now), isNotNull);
      expect(Validators.notFuture(null, now: now), isNotNull);
    });
  });
}
