import 'package:intl/intl.dart';

String getSaludoPorHora() {
  final hora = DateTime.now().hour;
  if (hora >= 6 && hora < 12) {
    return 'Buenos días'; // Mañana
  } else if (hora >= 12 && hora < 18) {
    return 'Buenas tardes'; // Tarde
  } else {
    return 'Buenas noches'; // Noche
  }
}

String formatFriendlyDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateToCompare = DateTime(date.year, date.month, date.day);

  final timeFormat = DateFormat('HH:mm');

  if (dateToCompare == today) {
    return 'Hoy, ${timeFormat.format(date)}';
  } else if (dateToCompare == yesterday) {
    return 'Ayer, ${timeFormat.format(date)}';
  } else {
    final fullDateFormat = DateFormat('dd/MM/yyyy, HH:mm');
    return fullDateFormat.format(date);
  }
}
