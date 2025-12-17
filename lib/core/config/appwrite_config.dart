class AppwriteConfig {
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '6941243a0017ce239184';
  static const String projectName = 'gudang_hadir';
  static const String databaseId = 'gudang_hadir_db';

  // Collections
  static const String usersCollection = 'users';
  static const String itemsCollection = 'items';
  static const String transactionsCollection = 'transactions';
  static const String attendancesCollection = 'attendances';
  static const String leavesCollection = 'leaves';
  static const String storageBucketId = 'general_storage';
}

class AppRoles {
  static const String admin = 'admin';
  static const String owner = 'owner';
  static const String employee = 'karyawan';
}
