import 'package:sqflite/sqflite.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/utils/constants.dart';
import '../domain/user.dart';

class UserDao {
  final AppDatabase _appDatabase;

  UserDao(this._appDatabase);

  Future<User?> authenticate(String username, String password) async {
    final db = await _appDatabase.database;
    final maps = await db.query(
      AppConstants.tableUsers,
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(String id) async {
    final db = await _appDatabase.database;
    final maps = await db.query(AppConstants.tableUsers, where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await _appDatabase.database;
    final maps = await db.query(AppConstants.tableUsers);
    return maps.map((e) => User.fromJson(e)).toList();
  }

  Future<void> insertUser(Map<String, dynamic> userMap) async {
    final db = await _appDatabase.database;
    await db.insert(AppConstants.tableUsers, userMap);
  }

  Future<void> updateUser(User user, {String? password}) async {
    final db = await _appDatabase.database;
    final Map<String, dynamic> values = user.toJson();
    if (password != null) {
      values['password_hash'] = password;
    }
    // Remove read-only fields if necessary, but here we replace mostly everything
    await db.update(AppConstants.tableUsers, values, where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> toggleUserStatus(String id, bool isActive) async {
    final db = await _appDatabase.database;
    await db.update(AppConstants.tableUsers, {'is_active': isActive ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }
}
