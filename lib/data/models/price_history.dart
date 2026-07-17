class PriceHistory {
  String itemName;
  String category;
  double lastPrice;
  DateTime dateRecorded;

  PriceHistory({
    required this.itemName,
    required this.category,
    required this.lastPrice,
    required this.dateRecorded,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'category': category,
      'lastPrice': lastPrice,
      'dateRecorded': dateRecorded.toIso8601String(),
    };
  }

  factory PriceHistory.fromMap(Map<String, dynamic> map) {
    return PriceHistory(
      itemName: map['itemName'],
      category: map['category'],
      lastPrice: map['lastPrice'] ?? 0.0,
      dateRecorded: DateTime.parse(map['dateRecorded']),
    );
  }
}
