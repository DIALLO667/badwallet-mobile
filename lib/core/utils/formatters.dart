import 'package:intl/intl.dart';

class Formatters {
  static final _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  static String formatAmount(double amount) {
    final n = amount.round();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA';
  }

  static String formatDate(DateTime date) => _dateFormatter.format(date);

  static String formatPhone(String phone) {
    if (phone.length == 9) {
      return '${phone.substring(0, 2)} ${phone.substring(2, 5)} '
          '${phone.substring(5, 7)} ${phone.substring(7, 9)}';
    }
    return phone;
  }
}
