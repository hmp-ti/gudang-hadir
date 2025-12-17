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
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(dashboardStatsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Admin',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 16),
              statsAsync.when(
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total\nBarang',
                        stats['totalItems'].toString(),
                        Colors.blue,
                        Icons.inventory_2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Stok\nMenipis',
                        stats['lowStock'].toString(),
                        Colors.orange,
                        Icons.warning_amber,
                        isWarning: true,
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              ),
              const SizedBox(height: 32),
              const Text(
                'Aksi Cepat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildActionButton(context, 'Kelola\nBarang', Icons.list_alt, Colors.teal, () {
                    // Navigate to Items Tab (index 1) handled by Main Page logic or separate check
                    // For now just show info
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buka Tab Gudang')));
                  }),
                  const SizedBox(width: 16),
                  _buildActionButton(context, 'Scan\nMasuk', Icons.qr_code_scanner, Colors.purple, () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Fitur Scan Admin (Segera)')));
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.1), foregroundColor: color, child: Icon(icon)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
