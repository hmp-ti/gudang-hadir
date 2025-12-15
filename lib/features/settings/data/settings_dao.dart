import 'package:sqflite/sqflite.dart';
import '../../../core/db/app_database.dart';
import '../../../core/utils/constants.dart';

class SettingsDao {
  final AppDatabase _appDatabase;

  SettingsDao(this._appDatabase);

  Future<String?> getSetting(String key) async {
    final db = await _appDatabase.database;
    final maps = await db.query(AppConstants.tableAppSettings, where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _appDatabase.database;
    await db.insert(AppConstants.tableAppSettings, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await _appDatabase.database;
    final maps = await db.query(AppConstants.tableAppSettings);
    final Map<String, String> settings = {};
    for (var row in maps) {
      settings[row['key'] as String] = row['value'] as String;
    }
    return settings;
  }
}
