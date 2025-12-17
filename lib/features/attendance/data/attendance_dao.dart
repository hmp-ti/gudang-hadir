import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';

import '../domain/attendance.dart';

final attendanceDaoProvider = Provider((ref) => AttendanceDao(AppwriteService.instance));

class AttendanceDao {
  final AppwriteService _appwrite;

  AttendanceDao(this._appwrite);

  Future<Attendance?> getAttendanceToday(String userId, String date) async {
    try {
      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.attendancesCollection,
        queries: [Query.equal('userId', userId), Query.equal('date', date)],
      );
      if (response.rows.isNotEmpty) {
        return Attendance.fromJson(response.rows.first.data..['id'] = response.rows.first.$id);
      }
    } catch (e) {
      // If index missing or other error, we must know.
      // But if purely "not found" (empty list), that's handled above.
      // So this catch blocks API errors. Rethrow.
      throw 'CheckIn Error: $e';
    }
    return null;
  }

  Future<List<Attendance>> getAttendanceByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      // Appwrite queries for date range
      // Assuming 'date' field is stored as 'YYYY-MM-DD' String or DateTime?
      // Domain model says 'date' is String (YYYY-MM-DD). Date filtering on Strings works if format is ISO.
      // Attendance has 'date' field (String).

      // We can also use 'createdAt' but 'date' is safer for logical day.
      // Let's use 'date' field filtering.
      // Format DateTime to YYYY-MM-DD
      String startStr = startDate.toIso8601String().split('T')[0];
      String endStr = endDate.toIso8601String().split('T')[0];

      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.attendancesCollection,
        queries: [
          Query.between('date', startStr, endStr),
          Query.limit(1000), // Max limit usually 100 on cloud, maybe 1000 on self-hosted/newer?
          // Pagination logic needed for generic reports but for MVP we take first batch or assume limit.
          // Default limit is usually 25.
          // Important: Appwrite listRows has limit.
        ],
      );

      final attendances = <Attendance>[];
      for (var row in response.rows) {
        final data = row.data;
        // Need user name for report?
        // Let's lazy load or just return ID. ReportService handles name if needed or we fetch here.
        // ReportService iterates users, so we just need counts.

        final attendanceData = Map<String, dynamic>.from(data);
        attendanceData['id'] = row.$id;
        attendances.add(Attendance.fromJson(attendanceData));
      }
      return attendances;
    } catch (e) {
      return [];
    }
  }

  Future<List<Attendance>> getHistory({String? userId, DateTime? startDate, DateTime? endDate}) async {
    try {
      List<String> queries = [Query.orderDesc('date'), Query.orderDesc('\$createdAt')];

      if (userId != null) {
        queries.add(Query.equal('userId', userId));
      }
      // Date filtering logic if needed, similar to TransactionDao

      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.attendancesCollection,
        queries: queries,
      );

      final attendances = <Attendance>[];

      for (var row in response.rows) {
        final data = row.data;
        String? userName;

        if (data['userId'] != null || data['user_id'] != null) {
          try {
            final uid = data['userId'] ?? data['user_id'];
            final userRow = await _appwrite.tables.getRow(
              databaseId: AppwriteConfig.databaseId,
              tableId: AppwriteConfig.usersCollection,
              rowId: uid,
            );
            userName = userRow.data['name'];
          } catch (_) {}
        }

        final attendanceData = Map<String, dynamic>.from(data);
        attendanceData['id'] = row.$id;
        attendanceData['user_name'] = userName;

        attendances.add(Attendance.fromJson(attendanceData));
      }

      return attendances;
    } catch (e) {
      // Return empty if just not found? No, listRows shouldn't fail if empty.
      // If error (like index missing), we want to know.
      throw 'History Error: $e';
    }
  }

  Future<void> insertAttendance(Attendance attendance) async {
    await _appwrite.tables.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.attendancesCollection,
      rowId: attendance.id,
      data: attendance.toJson()
        ..remove('id')
        ..remove('user_name')
        ..remove('createdAt'), // System attribute, cannot written manually
    );
  }

  Future<void> updateAttendance(Attendance attendance) async {
    await _appwrite.tables.updateRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.attendancesCollection,
      rowId: attendance.id,
      data: attendance.toJson()
        ..remove('id')
        ..remove('user_name')
        ..remove('createdAt'),
    );
  }
}
