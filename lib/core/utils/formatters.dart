import 'package:intl/intl.dart';

/// Formatação de números e datas em português do Brasil.
abstract final class Formatters {
  static final NumberFormat _kg = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 0,
  );
  static final NumberFormat _decimal = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 1,
  );
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _shortDate = DateFormat('dd/MM');

  static String kg(double value) => '${_kg.format(value)} kg';

  static String decimal(double value) => _decimal.format(value);

  static String percent(num value) => '${value.round()}%';

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
