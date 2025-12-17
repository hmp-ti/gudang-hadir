import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../auth/data/user_dao.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/domain/user.dart';

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

  Future<void> _pickAndUploadImage(User user) async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

    // Check permissions
    if (currentUser.role == 'admin') {
      if (user.role == 'admin' || user.role == 'owner') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Admin tidak dapat mengubah akun Admin/Owner.')));
        return;
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);

    if (pickedFile != null) {
      try {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading photo...')));

        final bytes = await pickedFile.readAsBytes();
        await ref
            .read(userDaoProvider)
            .updateProfilePhoto(user.id, bytes, 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diupdate')));
          ref.refresh(userListProvider);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: _showAddUserDialog, child: const Icon(Icons.add)),
      body: usersAsync.when(
        data: (users) {
          final currentUser = ref.watch(authControllerProvider).valueOrNull;
          var filteredUsers = users;

          if (currentUser?.role == 'admin') {
            filteredUsers = users.where((u) => u.role == 'karyawan').toList();
          }

          if (filteredUsers.isEmpty) {
            return const Center(child: Text('Tidak ada user.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null ? Text(user.role[0].toUpperCase()) : null,
                  ),
                  title: Text(user.name),
                  subtitle: Text('${user.email} | ${user.role}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: user.isActive,
                        onChanged: (val) async {
                          final currentUser = ref.read(authControllerProvider).valueOrNull;
                          if (currentUser == null) return;

                          if (currentUser.role == 'admin') {
                            // Admin cannot touch Owner or other Admins
                            if (user.role == 'admin' || user.role == 'owner') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Admin tidak dapat mengubah akun Admin/Owner.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }

                          // If Owner, allowed to do anything (or if Admin touching employee)
                          await ref.read(userDaoProvider).toggleUserStatus(user.id, val);
                          return ref.refresh(userListProvider);
                        },
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit_photo') {
                            _pickAndUploadImage(user);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit_photo',
                            child: Row(
                              children: [
                                Icon(Icons.camera_alt, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Update Foto'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
