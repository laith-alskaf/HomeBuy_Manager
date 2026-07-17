class ShoppingItem {
  String id;
  String name;
  String category;
  double price;
  String currency;
  double? exchangeRate;
  int quantity;
  bool isBought;
  DateTime? dateBought;
  String note;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    this.price = 0.0,
    this.currency = 'SYP',
    this.exchangeRate = 0.0,
    this.quantity = 1,
    this.isBought = false,
    this.dateBought,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      'exchangeRate': exchangeRate,
      'isBought': isBought,
      'dateBought': dateBought?.toIso8601String(),
      'note': note,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'SYP',
      exchangeRate: (map['exchangeRate'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
      isBought: map['isBought'] ?? false,
      dateBought: map['dateBought'] != null
          ? DateTime.parse(map['dateBought'])
          : null,
      note: map['note'] ?? '',
    );
  }
}
