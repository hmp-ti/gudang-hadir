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
      List<String> queries = [Query.orderDesc('createdAt')];

      if (type != null) {
        queries.add(Query.equal('type', type));
      }
      if (startDate != null && endDate != null) {
        queries.add(Query.between('createdAt', startDate.toIso8601String(), endDate.toIso8601String()));
      }

      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.transactionsCollection,
        queries: queries,
      );

      final transactions = <WarehouseTransaction>[];

      for (var row in response.rows) {
        final data = row.data;
        String? itemName;
        String? userName;

        // Fetch related Item Name
        // Optimization: In a real app, cache these or store name in transaction doc (denormalization)
        // For now, we fetch individually (N+1 prob but okay for small scale/mvp)
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

        // Fetch user name
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
            createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
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
}
