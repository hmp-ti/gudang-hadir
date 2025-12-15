import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/attendance_dao.dart';
import '../attendance_controller.dart';

// Use FutureProvider for history list
final attendanceHistoryProvider = FutureProvider.autoDispose((ref) async {
  final user = await ref.read(authRepositoryProvider).getCurrentUser();
  if (user == null) return [];
  return ref.read(attendanceDaoProvider).getHistory(userId: user.id);
});

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attendanceHistoryProvider);

    return Scaffold(
      body: historyAsync.when(
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('Belum ada riwayat absensi'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = list[index];
              final dateStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(DateTime.parse(item.date));
              final checkIn = item.checkInTime != null ? DateFormat('HH:mm').format(item.checkInTime!) : '-';
              final checkOut = item.checkOutTime != null ? DateFormat('HH:mm').format(item.checkOutTime!) : '-';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            item.isValid ? 'Valid' : 'Invalid',
                            style: TextStyle(color: item.isValid ? Colors.green : Colors.red),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Masuk', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(checkIn, style: const TextStyle(fontSize: 16)),
                              Text(item.checkInMethod ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Pulang', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(checkOut, style: const TextStyle(fontSize: 16)),
                              Text(item.checkOutMethod ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
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
