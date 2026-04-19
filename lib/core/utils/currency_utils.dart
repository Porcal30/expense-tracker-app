import 'package:intl/intl.dart';

/// Philippine Peso (₱) formatting for budget and expense UI.
///
/// Uses [intl] with two decimal places and no grouping, e.g. `₱20000.00`.
abstract final class CurrencyUtils {
  static final NumberFormat _twoDecimals = NumberFormat('#0.00', 'en_US');

  static String format(double amount) => '₱${_twoDecimals.format(amount)}';
}
