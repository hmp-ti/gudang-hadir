import 'package:sqflite/sqflite.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/utils/constants.dart';
import '../domain/item.dart';

class ItemDao {
  final AppDatabase _appDatabase;

  ItemDao(this._appDatabase);

  Future<List<Item>> getAllItems() async {
    final db = await _appDatabase.database;
    final maps = await db.query(AppConstants.tableItems, orderBy: 'name ASC');
    return maps.map((e) => Item.fromJson(e)).toList();
  }

  Future<Item?> getItemById(String id) async {
    final db = await _appDatabase.database;
    final maps = await db.query(AppConstants.tableItems, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Item.fromJson(maps.first);
    return null;
  }

  Future<Item?> getItemByCode(String code) async {
    final db = await _appDatabase.database;
    final maps = await db.query(AppConstants.tableItems, where: 'code = ?', whereArgs: [code]);
    if (maps.isNotEmpty) return Item.fromJson(maps.first);
    return null;
  }

  Future<void> insertItem(Item item) async {
    final db = await _appDatabase.database;
    await db.insert(AppConstants.tableItems, item.toJson());
  }

  Future<void> updateItem(Item item) async {
    final db = await _appDatabase.database;
    await db.update(AppConstants.tableItems, item.toJson(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(String id) async {
    final db = await _appDatabase.database;
    await db.delete(AppConstants.tableItems, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStock(String itemId, int newStock) async {
    final db = await _appDatabase.database;
    await db.update(
      AppConstants.tableItems,
      {'stock': newStock, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
}
