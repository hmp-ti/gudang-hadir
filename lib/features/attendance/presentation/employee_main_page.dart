import 'package:flutter/material.dart';
import 'tabs/employee_home_tab.dart';
import 'tabs/history_tab.dart';
import '../../profile/presentation/tabs/profile_tab.dart';

class EmployeeMainPage extends StatefulWidget {
  const EmployeeMainPage({super.key});

  @override
  State<EmployeeMainPage> createState() => _EmployeeMainPageState();
}

class _EmployeeMainPageState extends State<EmployeeMainPage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [EmployeeHomeTab(), HistoryTab(), ProfileTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GudangHadir')),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
