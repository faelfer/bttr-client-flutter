import 'package:intl/intl.dart';

String durationLabel(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return hours > 0 ? '${hours}h${rest > 0 ? ' ${rest}min' : ''}' : '${rest}min';
}

String dateLabel(DateTime date) =>
    DateFormat('dd/MM/yyyy · HH:mm', 'pt_BR').format(date.toLocal());
