abstract final class CurrencyFormatter {
  /// Formatea un número como precio colombiano: $26.000
  static String format(num amount) {
    final int value = amount.round();
    final String str = value.toString();
    final buffer = StringBuffer('\$');
    final int start = str.length % 3;

    if (start > 0) buffer.write(str.substring(0, start));

    for (int i = start; i < str.length; i += 3) {
      if (i > 0) buffer.write('.');
      buffer.write(str.substring(i, i + 3));
    }

    return buffer.toString();
  }

  /// Parsea un string "$26.000" a número 26000.0
  static double parse(String price) {
    final clean = price.replaceAll('\$', '').replaceAll('.', '').trim();
    return double.tryParse(clean) ?? 0;
  }
}
