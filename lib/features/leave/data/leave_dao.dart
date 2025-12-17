import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../domain/leave.dart';

final leaveDaoProvider = Provider((ref) => LeaveDao(AppwriteService.instance));

class LeaveDao {
  final AppwriteService _service;

  LeaveDao(this._service);

  Future<void> createLeave(Leave leave) async {
    await _service.tables.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.leavesCollection,
      rowId: leave.id,
      data: leave.toJson(),
    );
  }

  Future<List<Leave>> getLeavesByUser(String userId) async {
    final response = await _service.tables.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.leavesCollection,
      queries: [Query.equal('userId', userId), Query.orderDesc('\$createdAt')],
    );
    return response.rows.map((e) => Leave.fromJson(e.data)).toList();
  }

  Future<List<Leave>> getPendingLeaves() async {
    final response = await _service.tables.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.leavesCollection,
      queries: [Query.equal('status', 'pending'), Query.orderAsc('\$createdAt')],
    );
    return response.rows.map((e) => Leave.fromJson(e.data)).toList();
  }

  Future<List<Leave>> getAllLeaves() async {
    final response = await _service.tables.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.leavesCollection,
      queries: [Query.orderDesc('\$createdAt')],
    );
    return response.rows.map((e) => Leave.fromJson(e.data)).toList();
  }

  Future<void> updateStatus(String leaveId, String status, {String? adminId, String? pdfFileId}) async {
    final data = <String, dynamic>{'status': status};
    if (adminId != null) data['adminId'] = adminId;
    if (pdfFileId != null) data['pdfFileId'] = pdfFileId;

    await _service.tables.updateRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.leavesCollection,
      rowId: leaveId,
      data: data,
    );
  }
}
