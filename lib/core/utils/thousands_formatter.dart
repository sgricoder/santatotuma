import 'package:flutter/services.dart';

/// Formats integer amounts with '.' as thousands separator (Colombian style).
/// Typing 10000 shows as 10.000. Only allows digits.
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    final clean = digits.replaceFirst(RegExp(r'^0+'), '');
    final number = clean.isEmpty ? '0' : clean;
    final formatted = _addSeparators(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _addSeparators(String digits) {
    final buf = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// Parses a formatted string back to double. "10.000" → 10000.0
  static double? parse(String text) =>
      double.tryParse(text.replaceAll('.', ''));

  /// Formats a number for programmatic assignment to the controller.
  /// 12000.0 → "12.000"
  static String format(num value) => _addSeparators(value.toInt().toString());
}
