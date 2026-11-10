import 'package:intl/intl.dart';

/// Formatação de números e datas em português do Brasil.
abstract final class Formatters {
  /// Sempre com duas casas decimais, como em "1.234,50".
  static final NumberFormat _decimal = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 2,
  );

  /// Para eixos de gráfico: até duas casas, sem zeros sobrando ("1,5", "10").
  static final NumberFormat _axis = NumberFormat('#,##0.##', 'pt_BR');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _shortDate = DateFormat('dd/MM');

  static String kg(double value) => '${_decimal.format(value)} kg';

  /// Versão curta para eixos de gráfico: "850", "1,5 mil", "10 mil".
  static String compactKg(double value) {
    if (value >= 1000) return '${_axis.format(value / 1000)} mil';
    return _axis.format(value.round());
  }

  static String decimal(double value) => _decimal.format(value);

  /// Porcentagem inteira, para valores que já são inteiros (ex.: enchimento).
  static String percent(num value) => '${value.round()}%';

  /// Porcentagem com duas casas decimais, para participações e variações.
  static String percentDecimal(num value) => '${_decimal.format(value)}%';

  /// Ex.: "+8,2%" ou "-3,1%".
  static String signedPercent(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${_decimal.format(value)}%';
  }

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String shortDate(DateTime value) => _shortDate.format(value);

  /// Ex.: "há 5 min", "há 3 h", "há 2 dias".
  static String timeAgo(DateTime value, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(value);
    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    final days = diff.inDays;
    return days == 1 ? 'há 1 dia' : 'há $days dias';
  }
}
