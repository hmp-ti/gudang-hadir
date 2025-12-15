import 'package:sqflite/sqflite.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/utils/constants.dart';
import '../domain/transaction.dart';

class TransactionDao {
  final AppDatabase _appDatabase;

  TransactionDao(this._appDatabase);

  Future<List<WarehouseTransaction>> getAllTransactions({DateTime? startDate, DateTime? endDate, String? type}) async {
    final db = await _appDatabase.database;

    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (type != null) {
      whereClause += ' AND t.type = ?';
      whereArgs.add(type);
    }
    if (startDate != null && endDate != null) {
      whereClause += ' AND t.created_at BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    // Join with Items and Users to get names
    final maps = await db.rawQuery('''
      SELECT t.*, i.name as item_name, u.name as user_name
      FROM ${AppConstants.tableTransactions} t
      LEFT JOIN ${AppConstants.tableItems} i ON t.item_id = i.id
      LEFT JOIN ${AppConstants.tableUsers} u ON t.created_by = u.id
      WHERE $whereClause
      ORDER BY t.created_at DESC
    ''', whereArgs);

    return maps.map((e) => WarehouseTransaction.fromJson(e)).toList();
  }

  Future<void> insertTransaction(WarehouseTransaction transaction) async {
    final db = await _appDatabase.database;
    await db.insert(AppConstants.tableTransactions, transaction.toJson());
  }
}
