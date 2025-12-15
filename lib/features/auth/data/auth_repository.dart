import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/utils/constants.dart';
import '../domain/user.dart';
import 'user_dao.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(UserDao(AppDatabase.instance));
});

class AuthRepository {
  final UserDao _userDao;

  AuthRepository(this._userDao);

  Future<User?> login(String username, String password) async {
    final user = await _userDao.authenticate(username, password);
    if (user != null) {
      await _saveSession(user.id);
    }
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyCurrentUserId);
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.keyCurrentUserId);
    if (userId != null) {
      return await _userDao.getUserById(userId);
    }
    return null;
  }

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCurrentUserId, userId);
  }
}
