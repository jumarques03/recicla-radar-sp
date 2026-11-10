import 'package:flutter_test/flutter_test.dart';

import 'package:recicla_radar_sp/core/utils/formatters.dart';

void main() {
  group('duas casas decimais', () {
    test('kg sempre com duas casas e separador brasileiro', () {
      expect(Formatters.kg(1234.5), '1.234,50 kg');
      expect(Formatters.kg(0.1), '0,10 kg');
      expect(Formatters.kg(103599.4876), '103.599,49 kg');
      expect(Formatters.kg(2), '2,00 kg');
    });

    test('arredonda para duas casas, nunca mais que isso', () {
      expect(Formatters.decimal(3.14159), '3,14');
      expect(Formatters.decimal(2.999), '3,00');
    });

    test('variação percentual com sinal e duas casas', () {
      expect(Formatters.signedPercent(8.2), '+8,20%');
      expect(Formatters.signedPercent(-3.456), '-3,46%');
    });

    test('participação em porcentagem com duas casas', () {
      expect(Formatters.percentDecimal(45.1234), '45,12%');
    });

    test('enchimento continua inteiro, pois já é um número inteiro', () {
      expect(Formatters.percent(88), '88%');
    });
  });

  group('rótulos de eixo de gráfico', () {
    test('abreviam milhares sem zeros sobrando', () {
      expect(Formatters.compactKg(850), '850');
      expect(Formatters.compactKg(1500), '1,5 mil');
      expect(Formatters.compactKg(10000), '10 mil');
    });
  });
}
