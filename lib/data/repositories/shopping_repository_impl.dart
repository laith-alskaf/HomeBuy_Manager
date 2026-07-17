import '../../domain/repositories/shopping_repository.dart';
import '../models/shopping_item.dart';
import '../services/local_storage_service.dart';

class ShoppingRepositoryImpl implements ShoppingRepository {
  final LocalStorageService _storageService;

  ShoppingRepositoryImpl(this._storageService);

  @override
  Future<List<ShoppingItem>> getShoppingItems() async {
    return _storageService.loadShoppingList();
  }

  @override
  Future<void> saveShoppingItems(List<ShoppingItem> items) async {
    await _storageService.saveShoppingList(items);
  }
}

