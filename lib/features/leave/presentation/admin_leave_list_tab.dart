import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'leave_controller.dart';

class AdminLeaveListTab extends ConsumerWidget {
  const AdminLeaveListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(pendingLeavesProvider);
    final actionState = ref.watch(leaveControllerProvider); // To watch loading state

    // Listen for errors/success if needed, or just rely on loading overlay
    ref.listen(leaveControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${next.error}')));
      } else if (!next.isLoading && !next.hasError && prev?.isLoading == true) {
        // value is null because repository returns void/null on success, but we check if it finished loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil disetujui & PDF dibuat!'), backgroundColor: Colors.green),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Approval Cuti')),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => ref.refresh(pendingLeavesProvider.future),
            child: listAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('Tidak ada pengajuan pending.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final start = DateFormat('d MMM').format(DateTime.parse(item.startDate));
                    final end = DateFormat('d MMM yyyy').format(DateTime.parse(item.endDate));

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${item.reason} ($start - $end)'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
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
          ),
          if (actionState.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
