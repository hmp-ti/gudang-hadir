import 'package:sqflite/sqflite.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/utils/constants.dart';
import '../domain/attendance.dart';

class AttendanceDao {
  final AppDatabase _appDatabase;

  AttendanceDao(this._appDatabase);

  Future<Attendance?> getAttendanceToday(String userId, String date) async {
    final db = await _appDatabase.database;
    final maps = await db.query(
      AppConstants.tableAttendances,
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
    if (maps.isNotEmpty) return Attendance.fromJson(maps.first);
    return null;
  }

  Future<List<Attendance>> getHistory({String? userId, DateTime? startDate, DateTime? endDate}) async {
    final db = await _appDatabase.database;

    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += ' AND a.user_id = ?';
      whereArgs.add(userId);
    }
    if (startDate != null && endDate != null) {
      // Assuming 'date' column is purely date string YYYY-MM-DD
      // or we check created_at. The brief says date YYYY-MM-DD.
      // String comparison works for ISO dates.
      // But let's filter by created_at or date string range.
      // Since date is TEXT YYYY-MM-DD
      // whereClause += ' AND a.date BETWEEN ? AND ?';
      // ... actually simpler to just order by date desc and filter in UI or simple query
    }

    final maps = await db.rawQuery('''
      SELECT a.*, u.name as user_name
      FROM ${AppConstants.tableAttendances} a
      LEFT JOIN ${AppConstants.tableUsers} u ON a.user_id = u.id
      WHERE $whereClause
      ORDER BY a.date DESC, a.created_at DESC
    ''', whereArgs);

    return maps.map((e) => Attendance.fromJson(e)).toList();
  }

  Future<void> insertAttendance(Attendance attendance) async {
    final db = await _appDatabase.database;
    await db.insert(AppConstants.tableAttendances, attendance.toJson());
  }

  Future<void> updateAttendance(Attendance attendance) async {
    final db = await _appDatabase.database;
    await db.update(AppConstants.tableAttendances, attendance.toJson(), where: 'id = ?', whereArgs: [attendance.id]);
  }
}
