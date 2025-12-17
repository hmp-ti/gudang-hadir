import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../auth/data/user_dao.dart';
// import '../../../auth/domain/user.dart';

final userDaoProvider = Provider((ref) => UserDao(AppwriteService.instance));
final userListProvider = FutureProvider.autoDispose((ref) => ref.read(userDaoProvider).getAllUsers());

class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({super.key});

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  // Simple Add User Dialog
  Future<void> _showAddUserDialog() async {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'karyawan';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama'),
                  ),
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  DropdownButton<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: 'karyawan', child: Text('Karyawan')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => setState(() => role = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                TextButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || userCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                    try {
                      final newUser = {
                        'id': const Uuid().v4(),
                        'name': nameCtrl.text,
                        'username': userCtrl.text,
                        'password_hash': passCtrl.text,
                        'role': role,
                        'is_active': 1,
                        'created_at': DateTime.now().toIso8601String(),
                      };
                      await ref.read(userDaoProvider).insertUser(newUser);
                      if (context.mounted) {
                        Navigator.pop(context);
                        return ref.refresh(userListProvider);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: _showAddUserDialog, child: const Icon(Icons.add)),
      body: usersAsync.when(
        data: (users) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(user.role[0].toUpperCase())),
                  title: Text(user.name),
                  subtitle: Text('${user.email} | ${user.role}'),
                  trailing: Switch(
                    value: user.isActive,
                    onChanged: (val) async {
                      await ref.read(userDaoProvider).toggleUserStatus(user.id, val);
                      return ref.refresh(userListProvider);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
