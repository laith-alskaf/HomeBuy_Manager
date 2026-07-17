enum SideBalanceType { deposit, withdraw }

class SideBalanceTransaction {
  final String id;
  final double amount;
  final String currency; // 'USD', 'EUR', 'SYP', etc.
  final DateTime date;
  final SideBalanceType type;
  final String note;

  SideBalanceTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.date,
    required this.type,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'type': type.name,
      'note': note,
    };
  }

  factory SideBalanceTransaction.fromMap(Map<String, dynamic> map) {
    return SideBalanceTransaction(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] ?? 'USD',
      date: DateTime.parse(map['date']),
      type: map['type'] == 'withdraw'
          ? SideBalanceType.withdraw
          : SideBalanceType.deposit,
      note: map['note'] ?? '',
    );
  }
}
