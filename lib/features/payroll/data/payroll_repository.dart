import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import '../../../core/config/appwrite_config.dart';
import '../../../core/services/appwrite_service.dart';
import '../domain/payroll.dart';
import '../domain/payroll_config.dart';

class PayrollRepository {
  final AppwriteService _appwrite;
  // Collection IDs (Ensure these exist or are created)
  static const String payrollConfigCollection = 'payroll_configs';
  static const String payrollCollection = 'payrolls';

  PayrollRepository(this._appwrite);

  /// Fetch Payroll Config for a user
  Future<PayrollConfig> getPayrollConfig(String userId) async {
    try {
      // Assuming userId is the Document ID for config to enforce 1:1
      // Or we filter by userId. Let's try fetching by ID first if we key it by userID,
      // but Appwrite IDs are usually their own things. Best to query.
      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: payrollConfigCollection,
        queries: [Query.equal('userId', userId)],
      );

      if (response.rows.isNotEmpty) {
        return PayrollConfig.fromJson(response.rows.first.data);
      }
    } catch (_) {
      // Fallback
    }
    // Return default 0 config if not found
    return PayrollConfig(userId: userId);
  }

  /// Save or Update Payroll Config
  Future<void> savePayrollConfig(PayrollConfig config) async {
    try {
      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: payrollConfigCollection,
        queries: [Query.equal('userId', config.userId)],
      );

      if (response.rows.isNotEmpty) {
        // Update
        final docId = response.rows.first.$id;
        await _appwrite.tables.updateRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: payrollConfigCollection,
          rowId: docId,
          data: config.toJson(),
        );
      } else {
        // Create
        await _appwrite.tables.createRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: payrollConfigCollection,
          rowId: ID.unique(),
          data: config.toJson(),
        );
      }
    } catch (e) {
      throw Exception('Failed to save payroll config: $e');
    }
  }

  /// Fetch All Payrolls (Global History)
  Future<List<Payroll>> getAllPayrolls() async {
    try {
      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: payrollCollection,
        queries: [],
      );
      return response.rows.map((e) => Payroll.fromJson(e.data)).toList();
    } catch (e) {
      debugPrint('Error fetching payrolls: $e');
      return [];
    }
  }

  /// Fetch Payroll History for a user
  Future<List<Payroll>> getPayrolls(String userId) async {
    try {
      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: payrollCollection,
        queries: [Query.equal('userId', userId), Query.orderDesc('\$createdAt')],
      );
      return response.rows.map((e) => Payroll.fromJson(e.data)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save generated payroll
  Future<void> savePayroll(Payroll payroll) async {
    try {
      // Ensure detail map is encoded if needed, but Appwrite supports stringifying
      // or we can store as string attribute. For simplicity, we assume 'detail' attribute is a string in DB
      // but in Model it is Map. We might need partial update here in repo to stringify.
      // Sanitize data
      final data = Map<String, dynamic>.from(payroll.toJson());
      data.remove('createdAt');
      data.remove('id');
      data.remove('\$id');
      data.remove('\$createdAt');
      data.remove('\$updatedAt');

      if (data['detail'] is Map) {
        data['detail'] = jsonEncode(data['detail']);
      }

      await _appwrite.tables.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: payrollCollection,
        rowId: ID.unique(),
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to save payroll: $e');
    }
  }
}
