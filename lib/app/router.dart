import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/user.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/warehouse/presentation/admin_main_page.dart';
import '../features/attendance/presentation/employee_main_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/admin', builder: (context, state) => const AdminMainPage()),
      GoRoute(path: '/employee', builder: (context, state) => const EmployeeMainPage()),
    ],
    redirect: (context, state) {
      if (authState.isLoading) return '/splash';

      final isAuthenticated = authState.value != null;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';

      if (!isAuthenticated) {
        return isLogin ? null : '/login';
      }

      // Authenticated
      if (isSplash || isLogin) {
        final user = authState.value!;
        if (user.role == 'admin') {
          return '/admin';
        } else {
          return '/employee';
        }
      }

      return null;
    },
  );
});
