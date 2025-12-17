import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../domain/generated_report.dart';

final reportHistoryDaoProvider = Provider((ref) => ReportHistoryDao(AppwriteService.instance));

class ReportHistoryDao {
  final AppwriteService _service;

  ReportHistoryDao(this._service);

  Future<void> saveReport(GeneratedReport report) async {
    await _service.tables.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.generatedReportsCollection,
      rowId: ID.unique(),
      data: report.toJson(),
    );
  }

  Future<List<GeneratedReport>> getHistory() async {
    final response = await _service.tables.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.generatedReportsCollection,
      queries: [Query.orderDesc('\$createdAt')],
    );
    return response.rows.map((e) => GeneratedReport.fromJson(e.data)).toList();
  }

  Future<String> uploadFile(List<int> bytes, String filename) async {
    final file = await _service.storage.createFile(
      bucketId: AppwriteConfig.storageBucketId,
      fileId: ID.unique(),
      file: InputFile.fromBytes(bytes: bytes, filename: filename),
    );
    return file.$id;
  }

  Future<List<int>> downloadFile(String fileId) async {
    return await _service.storage.getFileDownload(bucketId: AppwriteConfig.storageBucketId, fileId: fileId);
  }

  Future<void> deleteReport(String documentId, String fileId) async {
    // 1. Delete file from Storage
    try {
      await _service.storage.deleteFile(bucketId: AppwriteConfig.storageBucketId, fileId: fileId);
    } catch (e) {
      // Ignore if file not found (maybe already deleted manually)
      // but log it if we had a logger
    }

    // 2. Delete document from Database
    await _service.tables.deleteRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.generatedReportsCollection,
      rowId: documentId,
    );
  }

  String getFileView(String fileId) {
    // We return the file ID mostly, but full URL is useful if public.
    // For now, return constructed URL as fallback.
    final uri = Uri.parse(AppwriteConfig.endpoint);
    // Use IP/Domain if needed, but endpoint is usually correct.
    return '${uri.scheme}://${uri.host}/v1/storage/buckets/${AppwriteConfig.storageBucketId}/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }
}
