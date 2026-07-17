import 'dart:convert';

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  double currentAmount;
  final String currency;
  final int colorValue;
  final String iconName;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.currency = 'SYP',
    required this.colorValue,
    required this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'currency': currency,
      'colorValue': colorValue,
      'iconName': iconName,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'SYP',
      colorValue: map['colorValue'] ?? 0xFF4CAF50,
      iconName: map['iconName'] ?? 'savings',
    );
  }

  String toJson() => json.encode(toMap());

  factory SavingsGoal.fromJson(String source) =>
      SavingsGoal.fromMap(json.decode(source));

  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? currency,
    int? colorValue,
    String? iconName,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currency: currency ?? this.currency,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
    );
  }
}
