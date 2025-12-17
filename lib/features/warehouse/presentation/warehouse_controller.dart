import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/item_dao.dart';
import '../data/transaction_dao.dart';
import '../domain/item.dart';
import '../domain/transaction.dart';

// Providers moved to respective DAOs

final warehouseControllerProvider = StateNotifierProvider<WarehouseController, AsyncValue<List<Item>>>((ref) {
  return WarehouseController(ref.read(itemDaoProvider), ref.read(transactionDaoProvider));
});

class WarehouseController extends StateNotifier<AsyncValue<List<Item>>> {
  final ItemDao _itemDao;
  final TransactionDao _transactionDao;

  WarehouseController(this._itemDao, this._transactionDao) : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _itemDao.getAllItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem(
    String code,
    String name,
    String category,
    String unit,
    int minStock,
    String rack,
    String desc,
    double price,
    String manufacturer,
    bool discontinued,
  ) async {
    try {
      final newItem = Item(
        id: const Uuid().v4(),
        code: code,
        name: name,
        category: category,
        unit: unit,
        stock: 0, // Initial stock is 0
        minStock: minStock,
        rackLocation: rack,
        description: desc,
        price: price,
        manufacturer: manufacturer,
        discontinued: discontinued,
        updatedAt: DateTime.now(),
      );
      await _itemDao.insertItem(newItem);
      await loadItems();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateItem(Item item) async {
    try {
      await _itemDao.updateItem(item.copyWith(updatedAt: DateTime.now()));
      await loadItems();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _itemDao.deleteItem(id);
      await loadItems();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTransaction({
    required String itemId,
    required String type, // IN or OUT
    required int qty,
    required String note,
    required String userId,
  }) async {
    try {
      final item = await _itemDao.getItemById(itemId);
      if (item == null) throw Exception('Item not found');

      int newStock = item.stock;
      if (type == 'IN') {
        newStock += qty;
      } else {
        if (qty > item.stock) {
          throw Exception('Stok tidak mencukupi');
        }
        newStock -= qty;
      }

      // Update Item Stock
      await _itemDao.updateStock(itemId, newStock);

      // Record Transaction
      final transaction = WarehouseTransaction(
        id: const Uuid().v4(),
        itemId: itemId,
        type: type,
        qty: qty,
        note: note,
        createdAt: DateTime.now(),
        createdBy: userId,
      );
      await _transactionDao.insertTransaction(transaction);

      await loadItems();
    } catch (e) {
      rethrow;
    }
  }
}
