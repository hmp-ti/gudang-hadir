import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../domain/leave.dart';

class LeaveDao {
  final AppwriteService _service;

  LeaveDao(this._service);

  Future<void> createLeave(Leave leave) async {
    await _service.databases.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.leavesCollection,
      documentId: leave.id,
      data: leave.toJson(),
    );
  }

  Future<List<Leave>> getLeavesByUser(String userId) async {
    final response = await _service.databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.leavesCollection,
      queries: [Query.equal('userId', userId), Query.orderDesc('\$createdAt')],
    );
    return response.documents.map((e) => Leave.fromJson(e.data)).toList();
  }

  Future<List<Leave>> getPendingLeaves() async {
    final response = await _service.databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.leavesCollection,
      queries: [Query.equal('status', 'pending'), Query.orderAsc('\$createdAt')],
    );
    return response.documents.map((e) => Leave.fromJson(e.data)).toList();
  }

  Future<void> updateStatus(String leaveId, String status, {String? adminId, String? pdfFileId}) async {
    final data = <String, dynamic>{'status': status};
    if (adminId != null) data['adminId'] = adminId;
    if (pdfFileId != null) data['pdfFileId'] = pdfFileId;

    await _service.databases.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.leavesCollection,
      documentId: leaveId,
      data: data,
    );
  }
}
