import '../../data/models/shopping_item.dart';

abstract class ShoppingRepository {
  Future<List<ShoppingItem>> getShoppingItems();
  Future<void> saveShoppingItems(List<ShoppingItem> items);
}
