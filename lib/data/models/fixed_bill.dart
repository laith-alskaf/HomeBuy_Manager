import 'dart:convert';

class FixedBill {
  final String id;
  final String name;
  final double amount;
  final String currency;
  final String frequency; // 'weekly', 'monthly', 'quarterly', 'yearly'
  final String category;
  final Map<String, String> statusHistory;
  final bool isAutoPay;

  FixedBill({
    required this.id,
    required this.name,
    required this.amount,
    this.currency = 'SYP',
    this.frequency = 'monthly',
    required this.category,
    this.isAutoPay = false,
    Map<String, String>? statusHistory,
  }) : statusHistory = statusHistory ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
      'frequency': frequency,
      'category': category,
      'statusHistory': statusHistory,
      'isAutoPay': isAutoPay,
    };
  }

  factory FixedBill.fromMap(Map<String, dynamic> map) {
    return FixedBill(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'SYP',
      frequency: map['frequency'] ?? 'monthly',
      category: map['category'] ?? 'other',
      statusHistory: Map<String, String>.from(map['statusHistory'] ?? {}),
      isAutoPay: map['isAutoPay'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory FixedBill.fromJson(String source) =>
      FixedBill.fromMap(json.decode(source));

  FixedBill copyWith({
    String? id,
    String? name,
    double? amount,
    String? currency,
    String? frequency,
    String? category,
    Map<String, String>? statusHistory,
  }) {
    return FixedBill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      statusHistory: statusHistory ?? this.statusHistory,
      isAutoPay: isAutoPay,
    );
  }
}
