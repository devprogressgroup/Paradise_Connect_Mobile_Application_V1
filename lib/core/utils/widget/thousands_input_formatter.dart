import 'package:flutter/services.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';

/// Memformat angka yang diketik jadi ribuan (1.000.000) sambil menjaga kursor tetap di akhir.
/// Nilai aslinya dibaca ulang dengan membuang semua karakter non-digit.
class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final formatted = NumberHelper.thousands(int.parse(digits));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
