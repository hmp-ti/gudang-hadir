import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gudang_hadir/features/auth/presentation/auth_controller.dart';
import '../../users/presentation/tabs/users_tab.dart';
import '../../settings/presentation/tabs/settings_tab.dart';
import '../../attendance/presentation/tabs/employee_home_tab.dart';
import 'tabs/admin_recap_tab.dart';
import 'tabs/items_tab.dart';
import 'tabs/admin_dashboard_tab.dart';

class AdminMainPage extends ConsumerStatefulWidget {
  const AdminMainPage({super.key});

  @override
  ConsumerState<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends ConsumerState<AdminMainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final isOwner = currentUser?.role == 'owner';

    final List<Widget> tabs = [
      isOwner ? const AdminDashboardTab() : const EmployeeHomeTab(), // Beranda
      const ItemsTab(), // Gudang
      const AdminRecapTab(), // Rekap
      const UsersTab(), // Karyawan
      const SettingsTab(), // Setting
      // const ProfileTab(), // Profile
    ];

    return Scaffold(
      appBar: AppBar(title: Text(isOwner ? 'Owner Gudang Hadir' : 'Admin Gudang Hadir')),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Gudang'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Rekap'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Karyawan'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
          // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
