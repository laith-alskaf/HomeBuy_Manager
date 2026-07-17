enum VaultTransactionType { autoSave, manualDeposit, manualWithdraw }

class VaultTransaction {
  final String id;
  final double amount;
  final String currency;
  final String? toCurrency; // للحركات التي تتضمن تحويل عملة
  final DateTime date;
  final VaultTransactionType type;
  final String note;

  VaultTransaction({
    required this.id,
    required this.amount,
    this.currency = 'SYP',
    this.toCurrency,
    required this.date,
    required this.type,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'toCurrency': toCurrency,
      'date': date.toIso8601String(),
      'type': type.name,
      'note': note,
    };
  }

  factory VaultTransaction.fromMap(Map<String, dynamic> map) {
    return VaultTransaction(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] ?? 'SYP',
      toCurrency: map['toCurrency'] as String?,
      date: DateTime.parse(map['date']),
      type: _stringToType(map['type']),
      note: map['note'] ?? '',
    );
  }

  // دالة مساعدة لتحويل النص إلى Enum بأمان
  static VaultTransactionType _stringToType(String typeStr) {
    switch (typeStr) {
      case 'autoSave':
        return VaultTransactionType.autoSave;
      case 'manualDeposit':
        return VaultTransactionType.manualDeposit;
      case 'manualWithdraw':
        return VaultTransactionType.manualWithdraw;
      default:
        return VaultTransactionType.manualDeposit; // قيمة افتراضية آمنة
    }
  }
}
