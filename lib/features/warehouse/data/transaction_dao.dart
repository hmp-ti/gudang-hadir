import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';

import '../domain/transaction.dart';

final transactionDaoProvider = Provider((ref) => TransactionDao(AppwriteService.instance));

class TransactionDao {
  final AppwriteService _appwrite;

  TransactionDao(this._appwrite);

  Future<List<WarehouseTransaction>> getAllTransactions({DateTime? startDate, DateTime? endDate, String? type}) async {
    try {
      // Use system creation time for sorting to avoid "Missing Index" error on custom 'createdAt'
      List<String> queries = [Query.orderDesc('\$createdAt')];

      if (type != null) {
        queries.add(Query.equal('type', type));
      }
      // Note: We removed Query.between on 'createdAt' to prevent errors if index is missing.
      // We will filter in memory below.
      queries.add(Query.limit(500)); // Fetch reasonable amount

      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.transactionsCollection,
        queries: queries,
      );

      final transactions = <WarehouseTransaction>[];

      for (var row in response.rows) {
        final data = row.data;
        final createdAt = DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now();

        // Manual Filtering
        if (startDate != null && createdAt.isBefore(startDate)) continue;
        if (endDate != null && createdAt.isAfter(endDate.add(const Duration(days: 1)))) continue; // End of day buffer

        String? itemName;
        String? userName;

        if (data['itemId'] != null) {
          try {
            final itemRow = await _appwrite.tables.getRow(
              databaseId: AppwriteConfig.databaseId,
              tableId: AppwriteConfig.itemsCollection,
              rowId: data['itemId'],
            );
            itemName = itemRow.data['name'];
          } catch (_) {}
        }

        if (data['createdBy'] != null) {
          try {
            final userRow = await _appwrite.tables.getRow(
              databaseId: AppwriteConfig.databaseId,
              tableId: AppwriteConfig.usersCollection,
              rowId: data['createdBy'],
            );
            userName = userRow.data['name'];
          } catch (_) {}
        }

        transactions.add(
          WarehouseTransaction(
            id: row.$id,
            itemId: data['itemId'] ?? '',
            type: data['type'] ?? '',
            qty: data['qty'] ?? 0,
            note: data['note'] ?? '',
            createdAt: createdAt,
            createdBy: data['createdBy'] ?? '',
            itemName: itemName,
            userName: userName,
          ),
        );
      }

      return transactions;
    } catch (e) {
      return [];
    }
  }

  Future<void> insertTransaction(WarehouseTransaction transaction) async {
    await _appwrite.tables.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.transactionsCollection,
      rowId: transaction.id,
      data: {
        'itemId': transaction.itemId,
        'type': transaction.type,
        'qty': transaction.qty,
        'note': transaction.note,
        'createdAt': transaction.createdAt.toIso8601String(),
        'createdBy': transaction.createdBy,
      },
    );
  }

  Future<void> deleteTransaction(String id) async {
    await _appwrite.tables.deleteRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.transactionsCollection,
      rowId: id,
    );
  }
}
