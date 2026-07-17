enum DebtType {
  asset, // لي (مستحقات)
  liability, // علي (ديون)
}

class DebtTransaction {
  final String id;
  final double amount;
  final String currency;
  final DateTime date;

  DebtTransaction({
    required this.id,
    required this.amount,
    this.currency = 'SYP',
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'currency': currency,
    'date': date.toIso8601String(),
  };

  factory DebtTransaction.fromMap(Map<String, dynamic> map) {
    return DebtTransaction(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] ?? 'SYP',
      date: DateTime.parse(map['date']),
    );
  }
}

class DebtInstallment {
  final String id;
  final double amount;
  final DateTime dueDate;
  bool isPaid;

  DebtInstallment({
    required this.id,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': isPaid,
      };

  factory DebtInstallment.fromMap(Map<String, dynamic> map) {
    return DebtInstallment(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate']),
      isPaid: map['isPaid'] ?? false,
    );
  }
}


class DebtRecord {
  final String id;
  final String personName;
  final double totalAmount;
  final String currency;
  double paidAmount;
  final DebtType type;
  final DateTime dueDate;
  bool isSettled;
  List<DebtTransaction> transactions;
  List<DebtInstallment> installments;

  DebtRecord({
    required this.id,
    required this.personName,
    required this.totalAmount,
    this.currency = 'SYP',
    this.paidAmount = 0.0,
    required this.type,
    required this.dueDate,
    this.isSettled = false,
    List<DebtTransaction>? transactions,
    List<DebtInstallment>? installments,
  }) : transactions = transactions ?? [],
       installments = installments ?? [];

  double get remainingAmount => totalAmount - paidAmount;
  double get progress => totalAmount == 0 ? 0 : paidAmount / totalAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'totalAmount': totalAmount,
      'currency': currency,
      'paidAmount': paidAmount,
      'type': type.name,
      'dueDate': dueDate.toIso8601String(),
      'isSettled': isSettled,
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'installments': installments.map((i) => i.toMap()).toList(),
    };
  }

  factory DebtRecord.fromMap(Map<String, dynamic> map) {
    return DebtRecord(
      id: map['id'],
      personName: map['personName'],
      totalAmount: (map['totalAmount'] as num).toDouble(),
      currency: map['currency'] ?? 'SYP',
      paidAmount: (map['paidAmount'] as num).toDouble(),
      type: _stringToType(map['type']),
      dueDate: DateTime.parse(map['dueDate']),
      isSettled: map['isSettled'] ?? false,
      transactions:
          (map['transactions'] as List<dynamic>?)
              ?.map((e) => DebtTransaction.fromMap(e))
              .toList() ??
          [],
      installments:
          (map['installments'] as List<dynamic>?)
              ?.map((e) => DebtInstallment.fromMap(e))
              .toList() ??
          [],
    );
  }

  static DebtType _stringToType(String str) {
    return str == 'asset' ? DebtType.asset : DebtType.liability;
  }

  DebtRecord copyWith({
    String? id,
    String? personName,
    double? totalAmount,
    String? currency,
    double? paidAmount,
    DebtType? type,
    DateTime? dueDate,
    bool? isSettled,
    List<DebtTransaction>? transactions,
  }) {
    return DebtRecord(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      paidAmount: paidAmount ?? this.paidAmount,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
      transactions: transactions ?? this.transactions,
      installments: installments ?? this.installments,
    );
  }
}
