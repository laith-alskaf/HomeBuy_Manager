class WalletTransaction {
  String id;
  double amount;
  String currency;
  DateTime date;
  String note;

  WalletTransaction({
    required this.id,
    required this.amount,
    this.currency = 'SYP',
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] ?? 'SYP',
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }

  WalletTransaction copyWith({
    String? id,
    double? amount,
    String? currency,
    DateTime? date,
    String? note,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
