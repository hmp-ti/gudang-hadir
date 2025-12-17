import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(AppwriteService.instance);
});

class AuthRepository {
  final AppwriteService _appwrite;

  AuthRepository(this._appwrite);

  Future<User?> login(String email, String password) async {
    try {
      // 1. Create session
      await _appwrite.account.createEmailPasswordSession(email: email, password: password);

      // 2. Verify User Document & Role
      try {
        final user = await getCurrentUser(strict: true);
        if (user == null) throw 'User data not found.'; // Should be caught by strict mode usually
        return user;
      } catch (e) {
        // If verification fails (no profile, inactive, etc),
        // destroy the session we just created so user isn't stuck "logged in" appwrite-side.
        await logout();
        rethrow;
      }
    } catch (e) {
      if (e is AppwriteException) {
        // Map common Appwrite errors if needed, or just message
        throw e.message ?? 'Login failed';
      }
      // Handle our custom errors
      if (e.toString().contains('User Profile not found')) {
        throw 'Akun tidak ditemukan atau belum aktif. Hubungi Admin.';
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _appwrite.account.deleteSession(sessionId: 'current');
    } catch (_) {}
  }

  Future<User?> getCurrentUser({bool strict = false}) async {
    try {
      // 1. Get Account
      final account = await _appwrite.account.get();

      // 2. Get User Profile from Database
      try {
        final row = await _appwrite.tables.getRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.usersCollection,
          rowId: account.$id,
        );

        final data = row.data;

        // CHECK ROLE & STATUS
        final isActive = data['is_active'] ?? false; // Default false if missing?
        // SQLite had 1/0 for boolean. Appwrite boolean is bool.
        // Let's assume bool. If int, handle it.
        bool active = false;
        if (isActive is bool) active = isActive;
        if (isActive is int) active = isActive == 1;

        if (!active) {
          throw 'Account is inactive.';
        }

        // Check Role if needed. User "only specific account... with roles".
        // If doc exists, they have a role (it's required in model).
        // So presence of doc implies "created and with roles".

        data['\$id'] = row.$id;
        data['email'] = account.email;
        data['\$createdAt'] = row.$createdAt;

        return User.fromJson(data);
      } catch (e) {
        // If getRow fails (doc not found), then user is NOT authorized in our system
        // even if they have an Appwrite account.

        // If this was during login, we want to fail.
        // If this is app start check, we return null (logged out state effectively, or partial state).

        // Since we want to ENFORCE "only specific account that already created... can login",
        // we should treat missing DB doc as "not logged in" or "unauthorized".

        if (e.toString().contains('Account is inactive')) {
          rethrow;
        }

        if (strict) {
          // Simplified user-friendly message
          throw 'User Profile not found.';
        }

        // If we are just checking session (auto-login), returning null logs them out usually.
        return null;
      }
    } catch (e) {
      if (strict) rethrow; // If getAccount fails
      // No active session or inactive
      return null;
    }
  }
}
