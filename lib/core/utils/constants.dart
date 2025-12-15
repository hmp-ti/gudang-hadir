class AppConstants {
  static const String appName = 'GudangHadir';
  static const String dbName = 'gudang_hadir.db';
  static const int dbVersion = 1;

  // Tables
  static const String tableUsers = 'users';
  static const String tableItems = 'items';
  static const String tableTransactions = 'warehouse_transactions';
  static const String tableAttendances = 'attendances';
  static const String tableAppSettings = 'app_settings';

  // Shared Preferences Keys
  static const String keyCurrentUserId = 'current_user_id';

  // App Settings Keys
  static const String keyWarehouseLat = 'warehouse_lat';
  static const String keyWarehouseLng = 'warehouse_lng';
  static const String keyAttendanceRadius = 'attendance_radius_m';
  static const String keyQrSecretToken = 'qr_secret_token';

  // Defaults
  static const double defaultAttendanceRadius = 100.0;
}
