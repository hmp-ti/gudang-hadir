import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/utils/constants.dart';
import '../data/settings_dao.dart';

final settingsDaoProvider = Provider((ref) => SettingsDao(AppwriteService.instance));

final settingsControllerProvider = StateNotifierProvider<SettingsController, AsyncValue<Map<String, String>>>((ref) {
  return SettingsController(ref.read(settingsDaoProvider));
});

class SettingsController extends StateNotifier<AsyncValue<Map<String, String>>> {
  final SettingsDao _settingsDao;

  SettingsController(this._settingsDao) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _settingsDao.getAllSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSetting(String key, String value) async {
    try {
      await _settingsDao.setSetting(key, value);
      await loadSettings();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setWarehouseLocation(double lat, double lng) async {
    await updateSetting(AppConstants.keyWarehouseLat, lat.toString());
    await updateSetting(AppConstants.keyWarehouseLng, lng.toString());
  }

  Future<void> regenerateQrToken() async {
    final newToken = const Uuid().v4();
    await updateSetting(AppConstants.keyQrSecretToken, newToken);
  }
}
