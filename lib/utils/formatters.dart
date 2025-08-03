// core/utils/formatters.dart
import 'package:intl/intl.dart';

class AppFormatters {
  // Formateo de moneda (extendido)
  static String formatCurrency(
    double value, {
    String symbol = r'$',
    int decimalDigits = 2,
    String locale = 'es_MX',
  }) {
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
      locale: locale,
    ).format(value);
  }

  // Formateo de fechas (versión completa)
  static String formatDate(
    DateTime date, {
    String format = 'dd/MM/yyyy',
    String locale = 'es',
    bool longMonth = false,
  }) {
    final pattern = longMonth ? 'dd \'de\' MMMM \'de\' yyyy' : format;
    return DateFormat(pattern, locale).format(date);
  }

  // Formateo de fechas con días adicionales (como en tu caso de vencimiento)
  static String formatDateFromToday({
    required int daysToAdd,
    bool includeYear = true,
  }) {
    final date = DateTime.now().add(Duration(days: daysToAdd));
    final pattern = includeYear ? 'dd/MM/yyyy' : 'dd/MM';
    return formatDate(date, format: pattern);
  }

  // Formateo de porcentajes
  static String formatPercentage(double value, {int decimalDigits = 2}) {
    return NumberFormat.decimalPercentPattern(
      decimalDigits: decimalDigits,
    ).format(value / 100);
  }

  // Formateo de números grandes (ej: 1,000, 1K, 1M)
  static String compactNumber(double value) {
    return NumberFormat.compact().format(value);
  }

  // Formateo de plazos (días a texto)
  static String formatTermDays(int days) {
    if (days >= 30) {
      final months = (days / 30).floor();
      return '$months ${months == 1 ? 'mes' : 'meses'}';
    }
    return '$days ${days == 1 ? 'día' : 'días'}';
  }
}
