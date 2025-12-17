import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/attendance_dao.dart';
import '../../domain/attendance.dart';

class AdminAttendanceTab extends ConsumerStatefulWidget {
  const AdminAttendanceTab({super.key});

  @override
  ConsumerState<AdminAttendanceTab> createState() => _AdminAttendanceTabState();
}

class _AdminAttendanceTabState extends ConsumerState<AdminAttendanceTab> {
  String _filterType = 'Hari Ini';
  DateTime? _customDate;
  bool _isLoading = false;
  List<Attendance> _attendanceList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final dao = ref.read(attendanceDaoProvider);
      final now = DateTime.now();
      List<Attendance> result = [];

      if (_filterType == 'Hari Ini') {
        final today = DateFormat('yyyy-MM-dd').format(now);
        result = await dao.getAttendanceByDate(today);
      } else if (_filterType == 'Minggu Ini') {
        final start = now.subtract(const Duration(days: 7));
        result = await dao.getAttendanceByDateRange(start, now);
      } else if (_filterType == 'Bulan Ini') {
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        result = await dao.getAttendanceByDateRange(start, end);
      } else if (_filterType == 'Pilih Tanggal' && _customDate != null) {
        final target = DateFormat('yyyy-MM-dd').format(_customDate!);
        result = await dao.getAttendanceByDate(target);
      }

      if (mounted) {
        setState(() {
          _attendanceList = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAttendance(Attendance item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Absensi?'),
        content: Text('Data absensi ${item.userName} pada tanggal ${item.date} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(attendanceDaoProvider).deleteAttendance(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil dihapus')));
          _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          _fetchData();
                        }
                      } else {
                        setState(() {
                          _filterType = val!;
                        });
                        _fetchData();
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
              onRefresh: _fetchData,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _attendanceList.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Tidak ada data absensi.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _attendanceList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _attendanceList[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: item.userPhotoUrl != null ? NetworkImage(item.userPhotoUrl!) : null,
                              child: item.userPhotoUrl == null ? const Icon(Icons.person, color: Colors.blue) : null,
                            ),
                            title: Text(
                              item.userName ?? 'User ???',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      item.checkOutTime != null ? Icons.check_circle : Icons.timer,
                                      color: item.checkOutTime != null ? Colors.green : Colors.orange,
                                    ),
                                    Text(
                                      item.checkOutTime != null ? 'Done' : 'Shift',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'delete') _deleteAttendance(item);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Hapus', style: TextStyle(color: Colors.red)),
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
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
