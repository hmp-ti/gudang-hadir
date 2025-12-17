import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(locale: 'en_AU', symbol: '\$ ');

  static String format(double value) {
    return _formatter.format(value);
  }

  // Parse formatted string back to double
  static double parse(String value) {
    String cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
