import 'package:intl/intl.dart';

class NumberHelper {
  static String thousands(num value) {
    return NumberFormat.decimalPattern('id_ID').format(value);
  }
}
