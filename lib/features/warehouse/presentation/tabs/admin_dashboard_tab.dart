import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../warehouse/presentation/warehouse_controller.dart'; // Reuse ItemDao

// A generic dashboard provider could fetch various counts
final dashboardStatsProvider = FutureProvider.autoDispose((ref) async {
  final items = await ref.read(itemDaoProvider).getAllItems();

  // Minimal stats for now
  int totalItems = items.length;
  int lowStock = items.where((i) => i.stock <= i.minStock).length;

  return {'totalItems': totalItems, 'lowStock': lowStock};
});

class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  _buildStatCard('Total Barang', stats['totalItems'].toString(), Colors.blue),
                  const SizedBox(height: 16),
                  _buildStatCard('Stok Menipis', stats['lowStock'].toString(), Colors.red, isWarning: true),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),
            const Text('Quick Action', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Just some shortcuts logic could be here
            const Text('Gunakan Tab Gudang untuk kelola barang.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, {bool isWarning = false}) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
