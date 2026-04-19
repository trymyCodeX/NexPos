import 'package:intl/intl.dart';

class FormatUtils {
  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String shortDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String fullDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
