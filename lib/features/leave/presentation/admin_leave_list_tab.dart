import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'leave_controller.dart';
import '../domain/leave.dart';

class AdminLeaveListTab extends ConsumerStatefulWidget {
  const AdminLeaveListTab({super.key});

  @override
  ConsumerState<AdminLeaveListTab> createState() => _AdminLeaveListState();
}

class _AdminLeaveListState extends ConsumerState<AdminLeaveListTab> {
  bool _showHistory = false;

  Future<void> _handleDownload(Leave leave) async {
    if (leave.pdfFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File PDF tidak tersedia.')));
      return;
    }

    try {
      final bytes = await ref.read(leaveControllerProvider.notifier).downloadPdf(leave.pdfFileId!);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/surat_cuti_${leave.userName}_${leave.startDate}.pdf');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal download: $e')));
    }
  }

  Future<void> _handleDelete(Leave leave) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengajuan?'),
        content: Text('Pengajuan cuti ${leave.userName} akan dihapus permanen.'),
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
      ref.read(leaveControllerProvider.notifier).deleteLeave(leave.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(leaveControllerProvider);

    // Error listener
    ref.listen(leaveControllerProvider, (prev, next) {
      if (next.hasError) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${next.error}')));
      } else if (!next.isLoading && !next.hasError && prev?.isLoading == true) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Berhasil!'), backgroundColor: Colors.green));
      }
    });

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(value: false, label: Text('Pending'), icon: Icon(Icons.pending_actions)),
                    ButtonSegment<bool>(value: true, label: Text('Riwayat'), icon: Icon(Icons.history)),
                  ],
                  selected: {_showHistory},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _showHistory = newSelection.first;
                    });
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.orange.shade100;
                      }
                      return null; // Use default
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.deepOrange;
                      }
                      return Colors.grey;
                    }),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _showHistory
                  ? _LeaveList(
                      provider: allLeavesProvider,
                      isHistory: true,
                      onDelete: _handleDelete,
                      onDownload: _handleDownload,
                    )
                  : _LeaveList(
                      provider: pendingLeavesProvider,
                      isHistory: false,
                      onDelete: _handleDelete,
                      onDownload: _handleDownload,
                    ),
            ),
          ],
        ),
        if (actionState.isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _LeaveList extends ConsumerWidget {
  final AutoDisposeFutureProvider<List<Leave>> provider;
  final bool isHistory;
  final Function(Leave) onDelete;
  final Function(Leave) onDownload;

  const _LeaveList({required this.provider, required this.isHistory, required this.onDelete, required this.onDownload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(provider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(provider.future),
      child: listAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Tidak ada data.'));
          }
          // Sort Pending? usually API sorts.
          // History: Sort by date desc
          final sorted = List<Leave>.from(list)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = sorted[index];
              final start = DateFormat('d MMM').format(DateTime.parse(item.startDate));
              final end = DateFormat('d MMM yyyy').format(DateTime.parse(item.endDate));

              Color statusColor = Colors.orange;
              if (item.status == 'approved') statusColor = Colors.green;
              if (item.status == 'rejected') statusColor = Colors.red;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${item.reason} ($start - $end)'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isHistory) ...[
                            OutlinedButton(
                              onPressed: () {
                                ref.read(leaveControllerProvider.notifier).rejectRequest(item.id);
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Tolak'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(leaveControllerProvider.notifier).approveRequest(item);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Setujui & PDF'),
                            ),
                          ] else ...[
                            // History Actions
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'delete') onDelete(item);
                                if (val == 'download') onDownload(item);
                              },
                              itemBuilder: (context) => [
                                if (item.status == 'approved' && item.pdfFileId != null)
                                  const PopupMenuItem(
                                    value: 'download',
                                    child: Row(
                                      children: [
                                        Icon(Icons.download, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Download PDF'),
                                      ],
                                    ),
                                  ),
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
