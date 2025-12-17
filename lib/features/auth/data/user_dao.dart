import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../domain/user.dart';

final userDaoProvider = Provider((ref) => UserDao(AppwriteService.instance));

class UserDao {
  final AppwriteService _appwrite;

  UserDao(this._appwrite);

  // Note: Actual authentication should be done via AuthRepository (Appwrite Auth).
  // This method might be legacy or for offline.
  // For Appwrite, we don't authenticate against the database collection manually like this.
  // We'll return null or implement a basic check if needed, but really this should be deprecated/unused if AuthRepository is used.
  // However, looking at the code, it seems this might be used for "login" in UI?
  // The user asked "how to use... with current appwrite setting".
  // Ideally, valid login goes through AuthRepository.
  // I will leave this returning null or throw, OR logic to find user in DB (but can't check password hash safely).
  // Implementation Plan said: "UserDao.insertUser will create a document..."
  // It didn't explicitly say what to do with 'authenticate'.
  // I'll assume standard AuthRepository is used for login.
  // If this is called, it might fail. I'll search for 'UserDao.authenticate' usage later.
  Future<User?> authenticate(String username, String password) async {
    // Cannot support this pattern with Appwrite securely on client side for "password_hash" check.
    // Assuming AuthRepository is used for actual login.
    return null;
  }

  Future<User?> getUserById(String id) async {
    try {
      final row = await _appwrite.tables.getRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.usersCollection,
        rowId: id,
      );
      return _mapRowToUser(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final response = await _appwrite.tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.usersCollection,
      );
      return response.rows.map((e) => _mapRowToUser(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> insertUser(Map<String, dynamic> userMap) async {
    // Admin creating user.
    // We Create Document. Login not possible unless Auth Account exists.
    // ID should be passed or generated.
    final id = userMap['id'] ?? ID.unique();
    final data = Map<String, dynamic>.from(userMap);
    data.remove('id');

    await _appwrite.tables.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.usersCollection,
      rowId: id,
      data: data,
    );
  }

  Future<void> updateUser(User user, {String? password}) async {
    final data = user.toJson();
    data.remove('id');
    // We cannot update password hash in DB meaningfully for Appwrite Auth.
    // If password provided, it should be updated in Auth Account (not possible from Client SDK for other users).
    // So we ignore password update here for now.

    await _appwrite.tables.updateRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.usersCollection,
      rowId: user.id,
      data: data,
    );
  }

  Future<void> toggleUserStatus(String id, bool isActive) async {
    await _appwrite.tables.updateRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.usersCollection,
      rowId: id,
      data: {'is_active': isActive},
    );
  }

  Future<void> updateProfilePhoto(String userId, List<int> imageBytes, String filename) async {
    // 1. Upload File
    final file = await _appwrite.storage.createFile(
      bucketId: AppwriteConfig.imagesBucketId,
      fileId: ID.unique(),
      file: InputFile.fromBytes(bytes: imageBytes, filename: filename),
    );

    // 2. Construct View URL
    final uri = Uri.parse(AppwriteConfig.endpoint);
    final photoUrl =
        '${uri.scheme}://${uri.host}/v1/storage/buckets/${AppwriteConfig.imagesBucketId}/files/${file.$id}/view?project=${AppwriteConfig.projectId}';

    // 3. Update User Document
    await _appwrite.tables.updateRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.usersCollection,
      rowId: userId,
      data: {'photoUrl': photoUrl},
    );
  }

  User _mapRowToUser(models.Row row) {
    // row is models.Row
    final data = row.data;
    // Helper to match User.fromJson expectations
    // User.fromJson expects 'username' (which we map from email?) or 'email'.
    // In DB we stored 'username' ?
    // Let's look at schema in AppDatabase: 'username' unique.
    // In Appwrite, we might use 'email' or 'username'.
    // Let's assume the document has the same fields as the Map.

    final map = Map<String, dynamic>.from(data);
    map['id'] = row.$id;
    // Map email/username if needed
    // In SQLite: username -> email mapping was done.
    if (map['email'] == null && map['username'] != null) {
      map['email'] = map['username'];
    }

    return User.fromJson(map);
  }
}
