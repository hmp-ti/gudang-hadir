import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import 'leave_controller.dart';

class EmployeeLeaveTab extends ConsumerStatefulWidget {
  const EmployeeLeaveTab({super.key});

  @override
  ConsumerState<EmployeeLeaveTab> createState() => _EmployeeLeaveTabState();
}

class _EmployeeLeaveTabState extends ConsumerState<EmployeeLeaveTab> {
  @override
  Widget build(BuildContext context) {
    final leavesAsync = ref.watch(myLeavesProvider);
    // final actionState = ref.watch(leaveControllerProvider);

    ref.listen(leaveControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, st) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))),
        data: (_) {
          if (prev?.hasValue == false && next.hasValue) {
            // Rough check for completion
            // Success handled in dialog usually
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Cuti Saya')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRequestDialog(context),
        child: const Icon(Icons.add),
      ),
      body: leavesAsync.when(
        data: (leaves) {
          if (leaves.isEmpty) return const Center(child: Text('Belum ada riwayat cuti.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = leaves[index];
              final start = DateFormat('d MMM').format(DateTime.parse(item.startDate));
              final end = DateFormat('d MMM yyyy').format(DateTime.parse(item.endDate));
              Color color = Colors.orange;
              if (item.status == 'approved') color = Colors.green;
              if (item.status == 'rejected') color = Colors.red;

              return Card(
                child: ListTile(
                  title: Text(item.reason, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$start - $end\nStatus: ${item.status.toUpperCase()}'),
                  isThreeLine: true,
                  trailing: item.status == 'approved' && item.pdfFileId != null
                      ? IconButton(
                          icon: const Icon(Icons.download),
                          color: Colors.blue,
                          onPressed: () => _downloadFile(item.pdfFileId!),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color),
                          ),
                          child: Text(item.status, style: TextStyle(color: color, fontSize: 12)),
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

  Future<void> _showRequestDialog(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    DateTime start = DateTime.now();
    DateTime end = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajukan Cuti'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(labelText: 'Alasan Cuti'),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Dari Tanggal'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(start)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: start,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => start = d);
                    },
                  ),
                  ListTile(
                    title: const Text('Sampai Tanggal'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(end)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: end,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => end = d);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (reasonCtrl.text.isEmpty) return;
                          setState(() => isLoading = true);
                          await ref.read(leaveControllerProvider.notifier).submitRequest(reasonCtrl.text, start, end);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Ajukan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _downloadFile(String fileId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengunduh surat...')));
      final bytes = await AppwriteService.instance.storage.getFileDownload(
        bucketId: AppwriteConfig.storageBucketId,
        fileId: fileId,
      );

      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/surat_cuti_$fileId.pdf');
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      OpenFilex.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal download: $e')));
    }
  }
}
