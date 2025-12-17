import 'package:flutter/material.dart';
import '../../../attendance/presentation/tabs/admin_attendance_tab.dart';
import '../../../leave/presentation/admin_leave_list_tab.dart';

class AdminRecapTab extends StatelessWidget {
  const AdminRecapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.deepOrange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepOrange,
              tabs: [
                Tab(text: 'Log Absensi', icon: Icon(Icons.history)),
                Tab(text: 'Approval Cuti', icon: Icon(Icons.assignment_turned_in)),
              ],
            ),
          ),
          const Expanded(child: TabBarView(children: [AdminAttendanceTab(), AdminLeaveListTab()])),
        ],
      ),
    );
  }
}
