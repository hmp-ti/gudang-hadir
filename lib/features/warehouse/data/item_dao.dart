import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';

import '../domain/item.dart';

final itemDaoProvider = Provider((ref) => ItemDao(AppwriteService.instance));

class ItemDao {
  final AppwriteService _appwrite;

  ItemDao(this._appwrite);

  Future<List<Item>> getAllItems() async {
    try {
      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.itemsCollection,
        queries: [Query.orderAsc('name')],
      );
      return response.rows.map((e) => _mapRowToItem(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Item?> getItemById(String id) async {
    try {
      final row = await _appwrite.tables.getRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.itemsCollection,
        rowId: id,
      );
      return _mapRowToItem(row);
    } catch (_) {
      return null;
    }
  }

  Future<Item?> getItemByCode(String code) async {
    try {
      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.itemsCollection,
        queries: [Query.equal('code', code)],
      );
      if (response.rows.isNotEmpty) {
        return _mapRowToItem(response.rows.first);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> insertItem(Item item) async {
    await _appwrite.tables.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.itemsCollection,
      rowId: item.id,
      data: {
        'code': item.code,
        'name': item.name,
        'category': item.category,
        'unit': item.unit,
        'stock': item.stock,
        'minStock': item.minStock,
        'rackLocation': item.rackLocation,
        'description': item.description,
        'price': item.price,
        'discontinued': item.discontinued,
        'manufacturer': item.manufacturer,
        'updatedAt': item.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> updateItem(Item item) async {
    await _appwrite.tables.updateRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.itemsCollection,
      rowId: item.id,
      data: {
        'code': item.code,
        'name': item.name,
        'category': item.category,
        'unit': item.unit,
        'stock': item.stock,
        'minStock': item.minStock,
        'rackLocation': item.rackLocation,
        'description': item.description,
        'price': item.price,
        'discontinued': item.discontinued,
        'manufacturer': item.manufacturer,
        'updatedAt': item.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> deleteItem(String id) async {
    await _appwrite.tables.deleteRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.itemsCollection,
      rowId: id,
    );
  }

  Future<void> updateStock(String itemId, int newStock) async {
    await _appwrite.tables.updateRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.itemsCollection,
      rowId: itemId,
      data: {'stock': newStock, 'updatedAt': DateTime.now().toIso8601String()},
    );
  }

  Item _mapRowToItem(models.Row row) {
    // Actually 'import package:appwrite/appwrite.dart' might check if 'Document' is exported.
    // Usually it is models.Document. Let's check imports.
    // 'package:appwrite/appwrite.dart' exports 'src/client.dart', 'src/session.dart' etc.
    // It usually exports models via 'package:appwrite/models.dart' but the package structure might vary.
    // Standard usage: import 'package:appwrite/models.dart' as models;
    // But let's assume 'package:appwrite/appwrite.dart' DOES NOT export models directly in a way that conflicts easily or maybe it does.
    // Let's use 'as models' for safety if we can, but I can't add imports easily without replacing top.
    // I replaced the top block.
    // I'll assume 'models.Document' is correct if I import models.
    // Wait, I only imported 'package:appwrite/appwrite.dart'.
    // Let's add 'import 'package:appwrite/models.dart' as models;' to the imports.

    final data = row.data;
    // Map usage:
    // Helper to gracefully handle mixed key naming (snake vs camel)
    T? getVal<T>(String camel, String snake) {
      if (data.containsKey(camel) && data[camel] != null) return data[camel] as T?;
      if (data.containsKey(snake) && data[snake] != null) return data[snake] as T?;
      return null;
    }

    return Item(
      id: row.$id,
      code: getVal<String>('code', 'code') ?? '',
      name: getVal<String>('name', 'name') ?? '',
      category: getVal<String>('category', 'category') ?? '',
      unit: getVal<String>('unit', 'unit') ?? '',
      stock: getVal<int>('stock', 'stock') ?? 0,
      minStock: getVal<int>('minStock', 'min_stock') ?? 0,
      rackLocation: getVal<String>('rackLocation', 'rack_location') ?? '',
      description: getVal<String>('description', 'description') ?? '',
      price: (getVal<num>('price', 'price') ?? 0).toDouble(),
      discontinued: getVal<bool>('discontinued', 'discontinued') ?? false,
      manufacturer: getVal<String>('manufacturer', 'manufacturer') ?? '',
      updatedAt: DateTime.tryParse(getVal<String>('updatedAt', 'updated_at') ?? '') ?? DateTime.now(),
    );
  }
}
