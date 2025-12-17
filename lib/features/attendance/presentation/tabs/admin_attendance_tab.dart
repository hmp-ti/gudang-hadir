import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/attendance_dao.dart';
import '../../presentation/attendance_controller.dart'; // To reuse DAO provider

// Provider to fetch ALL attendance for today
final adminAttendanceTodayProvider = FutureProvider.autoDispose((ref) async {
  final dao = ref.read(attendanceDaoProvider);
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  // Reuse getHistory but without userId filter to get everyone
  // Wait, getHistory implementation in Step 37 handled userId optional.
  return dao.getHistory(); // We might need to filter by date in DAO or here.
  // Step 37 DAO `getHistory` does NOT have date filter yet (it had placeholders).
  // I should update DAO or just fetch all and filter in memory (not efficient but okay for offline/small).
  // Let's rely on memory filter for now given constraints.
});

class AdminAttendanceTab extends ConsumerWidget {
  const AdminAttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(adminAttendanceTodayProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(adminAttendanceTodayProvider.future);
        },
        child: listAsync.when(
          data: (list) {
            // Filter for today
            final todayList = list.where((a) => a.date == todayStr).toList();

            if (todayList.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const Center(child: Text('Belum ada absensi hari ini')),
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: todayList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = todayList[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(item.userName ?? 'User ???'),
                    subtitle: Text(
                      'Masuk: ${item.checkInTime != null ? DateFormat('HH:mm').format(item.checkInTime!) : '-'} | Plg: ${item.checkOutTime != null ? DateFormat('HH:mm').format(item.checkOutTime!) : '-'}',
                    ),
                    trailing: Icon(
                      item.checkOutTime != null ? Icons.check_circle : Icons.timer,
                      color: item.checkOutTime != null ? Colors.green : Colors.orange,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ),
    );
  }
}
