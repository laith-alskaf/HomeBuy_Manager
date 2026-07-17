import 'package:flutter/services.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String newText = newValue.text.replaceAll(',', '');

    if (int.tryParse(newText) == null) {
      return oldValue;
    }

    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formattedText = newText.replaceAllMapped(
      formatter,
      (Match m) => '${m[1]},',
    );

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

String formatCurrency(double amount) {
  return amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

double parseFormattedNumber(String text) {
  return double.tryParse(text.replaceAll(',', '')) ?? 0.0;
}

String formatCompactCurrency(double amount) {
  if (amount >= 1000000000) {
    return '${(amount / 1000000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} مليار';
  } else if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} مليون';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ألف';
  }
  return formatCurrency(amount);
}
