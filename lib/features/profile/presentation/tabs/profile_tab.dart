import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/auth_controller.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final user = userAsync.value;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          Text(user?.name ?? 'Nama Pengguna', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '@email', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(user?.role.toUpperCase() ?? 'ROLE', style: const TextStyle(fontSize: 14, color: Colors.blue)),

          const SizedBox(height: 48),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            icon: const Icon(Icons.logout),
            label: const Text('KELUAR (LOGOUT)'),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              // Router will auto redirect to login
            },
          ),
        ],
      ),
    );
  }
}
