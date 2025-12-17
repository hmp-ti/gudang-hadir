import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';

import '../domain/attendance.dart';

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
