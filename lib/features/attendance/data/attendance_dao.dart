import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
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
        queries: [Query.between('date', startStr, endStr), Query.limit(100), Query.orderDesc('date')],
      );

      return mapRowsToAttendance(response.rows);
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
        String? userPhotoUrl;

        if (data['userId'] != null || data['user_id'] != null) {
          try {
            final uid = data['userId'] ?? data['user_id'];
            final userRow = await _appwrite.tables.getRow(
              databaseId: AppwriteConfig.databaseId,
              tableId: AppwriteConfig.usersCollection,
              rowId: uid,
            );
            userName = userRow.data['name'];
            userPhotoUrl = userRow.data['photoUrl'] ?? userRow.data['photo_url'];
          } catch (_) {}
        }

        final attendanceData = Map<String, dynamic>.from(data);
        attendanceData['id'] = row.$id;
        attendanceData['user_name'] = userName;
        attendanceData['user_photo_url'] = userPhotoUrl;

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

  Future<void> deleteAttendance(String id) async {
    await _appwrite.tables.deleteRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.attendancesCollection,
      rowId: id,
    );
  }

  Future<List<Attendance>> getAttendanceByDate(String date) async {
    try {
      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.attendancesCollection,
        queries: [
          Query.equal('date', date),
          Query.orderDesc('\$createdAt'),
          Query.limit(100), // Ensure we get enough for a day
        ],
      );

      return mapRowsToAttendance(response.rows);
    } catch (e) {
      return [];
    }
  }

  Future<List<Attendance>> mapRowsToAttendance(List<models.Row> rows) async {
    final attendances = <Attendance>[];
    for (var row in rows) {
      final data = row.data;
      String? userName;
      String? userPhotoUrl;

      if (data['userId'] != null || data['user_id'] != null) {
        try {
          final uid = data['userId'] ?? data['user_id'];
          final userRow = await _appwrite.tables.getRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: AppwriteConfig.usersCollection,
            rowId: uid,
          );
          userName = userRow.data['name'];
          userPhotoUrl = userRow.data['photoUrl'] ?? userRow.data['photo_url'];
        } catch (_) {}
      }

      final attendanceData = Map<String, dynamic>.from(data);
      attendanceData['id'] = row.$id;
      attendanceData['user_name'] = userName;
      attendanceData['user_photo_url'] = userPhotoUrl;

      attendances.add(Attendance.fromJson(attendanceData));
    }
    return attendances;
  }

  Future<int> getAttendanceCountBefore(String userId, String date) async {
    try {
      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.attendancesCollection,
        queries: [
          Query.equal('userId', userId),
          Query.lessThan('date', date),
          Query.limit(1), // We only need the total count
        ],
      );
      return response.total;
    } catch (e) {
      return 0;
    }
  }
}
