import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../presentation/attendance_controller.dart'; // To reuse DAO provider

// Provider to fetch ALL attendance for today
final adminAttendanceTodayProvider = FutureProvider.autoDispose((ref) async {
  final dao = ref.read(attendanceDaoProvider);
  // final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  // Reuse getHistory but without userId filter to get everyone
  // Wait, getHistory implementation in Step 37 handled userId optional.
  return dao.getHistory(); // We might need to filter by date in DAO or here.
  // Step 37 DAO `getHistory` does NOT have date filter yet (it had placeholders).
  // I should update DAO or just fetch all and filter in memory (not efficient but okay for offline/small).
  // Let's rely on memory filter for now given constraints.
});

class AdminAttendanceTab extends ConsumerStatefulWidget {
  const AdminAttendanceTab({super.key});

  @override
  ConsumerState<AdminAttendanceTab> createState() => _AdminAttendanceTabState();
}

class _AdminAttendanceTabState extends ConsumerState<AdminAttendanceTab> {
  String _filterType = 'Hari Ini';
  DateTime? _customDate;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(adminAttendanceTodayProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _filterType,
                    isExpanded: true,
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
                      DropdownMenuItem(value: 'Minggu Ini', child: Text('Minggu Ini')),
                      DropdownMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
                      DropdownMenuItem(value: 'Pilih Tanggal', child: Text('Pilih Tanggal...')),
                    ],
                    onChanged: (val) async {
                      if (val == 'Pilih Tanggal') {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _customDate = picked;
                            _filterType = 'Pilih Tanggal';
                          });
                        }
                      } else {
                        setState(() {
                          _filterType = val!;
                        });
                      }
                    },
                  ),
                ),
                if (_filterType == 'Pilih Tanggal' && _customDate != null)
                  Text(DateFormat('dd MMM').format(_customDate!)),
              ],
            ),
          ),
          // List Section
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(adminAttendanceTodayProvider.future),
              child: listAsync.when(
                data: (list) {
                  // Filter Logic
                  List<dynamic> filteredList = [];
                  final now = DateTime.now();
                  final todayStr = DateFormat('yyyy-MM-dd').format(now);

                  if (_filterType == 'Hari Ini') {
                    filteredList = list.where((a) => a.date == todayStr).toList();
                  } else if (_filterType == 'Minggu Ini') {
                    // Last 7 days
                    final start = now.subtract(const Duration(days: 7));
                    filteredList = list.where((a) {
                      final d = DateTime.parse(a.date);
                      return d.isAfter(start) && d.isBefore(now.add(const Duration(days: 1)));
                    }).toList();
                  } else if (_filterType == 'Bulan Ini') {
                    final start = DateTime(now.year, now.month, 1);
                    filteredList = list.where((a) {
                      final d = DateTime.parse(a.date);
                      return d.isAfter(start.subtract(const Duration(days: 1)));
                    }).toList();
                  } else if (_filterType == 'Pilih Tanggal' && _customDate != null) {
                    final target = DateFormat('yyyy-MM-dd').format(_customDate!);
                    filteredList = list.where((a) => a.date == target).toList();
                  } else {
                    filteredList = list;
                  }

                  if (filteredList.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Tidak ada data absensi.')),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: item.userPhotoUrl != null ? NetworkImage(item.userPhotoUrl!) : null,
                            child: item.userPhotoUrl == null ? const Icon(Icons.person, color: Colors.blue) : null,
                          ),
                          title: Text(item.userName ?? 'User ???', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('d MMM yyyy').format(DateTime.parse(item.date))),
                              Text(
                                'Masuk: ${item.checkInTime != null ? DateFormat('HH:mm').format(item.checkInTime!) : '-'}  |  Plg: ${item.checkOutTime != null ? DateFormat('HH:mm').format(item.checkOutTime!) : '-'}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.checkOutTime != null ? Icons.check_circle : Icons.timer,
                                color: item.checkOutTime != null ? Colors.green : Colors.orange,
                              ),
                              Text(item.checkOutTime != null ? 'Done' : 'Shift', style: const TextStyle(fontSize: 10)),
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
            ),
          ),
        ],
      ),
    );
  }
}
