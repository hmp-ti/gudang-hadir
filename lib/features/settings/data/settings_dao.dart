import '../../../core/config/appwrite_config.dart';
import '../../../core/services/appwrite_service.dart';

class SettingsDao {
  final AppwriteService _appwrite;
  // Assuming a collection for settings exists or we use one.
  // Using 'app_settings' as collection ID.
  static const String tableId = 'app_settings'; // renamed for consistency

  SettingsDao(this._appwrite);

  Future<String?> getSetting(String key) async {
    try {
      // Try to get document with ID = key
      final row = await _appwrite.tables.getRow(databaseId: AppwriteConfig.databaseId, tableId: tableId, rowId: key);
      return row.data['value'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> setSetting(String key, String value) async {
    try {
      // Try to update first
      await _appwrite.tables.updateRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: tableId,
        rowId: key,
        data: {'value': value},
      );
    } catch (e) {
      // If fails (e.g. not found), create
      await _appwrite.tables.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: tableId,
        rowId: key,
        data: {'value': value},
      );
    }
  }

  Future<Map<String, String>> getAllSettings() async {
    try {
      final response = await _appwrite.tables.listRows(databaseId: AppwriteConfig.databaseId, tableId: tableId);
      final Map<String, String> settings = {};
      for (var row in response.rows) {
        // Assuming doc ID is key
        settings[row.$id] = row.data['value'] as String? ?? '';
      }
      return settings;
    } catch (e) {
      return {};
    }
  }
}
