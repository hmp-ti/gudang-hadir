import 'package:flutter/material.dart';
import '../../users/presentation/tabs/users_tab.dart';
import '../../settings/presentation/tabs/settings_tab.dart';
import '../../attendance/presentation/tabs/admin_attendance_tab.dart';
import '../../leave/presentation/admin_leave_list_tab.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/items_tab.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    AdminDashboardTab(),
    ItemsTab(),
    AdminAttendanceTab(),
    AdminLeaveListTab(),
    UsersTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Gudang Hadir')),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Gudang'),
          BottomNavigationBarItem(
            icon: Icon(Icons.co_present), // Attendance
            label: 'Absensi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in), label: 'Approval'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
    );
  }
}
