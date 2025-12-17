import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gudang_hadir/features/auth/presentation/auth_controller.dart';
import '../../data/item_dao.dart';
import '../../../reports/domain/report_service.dart';
import '../../../reports/presentation/report_selection_page.dart';

// Consolidated dashboard stats provider
final dashboardStatsProvider = FutureProvider.autoDispose((ref) async {
  final reportService = ref.read(reportServiceProvider);
  final itemDao = ref.read(itemDaoProvider);

  // 1. Basic Counts
  final items = await itemDao.getAllItems();
  int totalItems = items.length;
  int lowStock = items.where((i) => i.stock <= i.minStock && !i.discontinued).length;

  // 2. Pie Chart Data (Stock by Category)
  final valuationReport = await reportService.getStockValuation();
  // Using 'byCategory' map: { 'Electronics': 5000000, 'Furniture': 2000000 }
  final categoryValue = valuationReport['byCategory'] as Map<String, double>;

  // 3. Bar Chart Data (Transactions last 7 days - Placeholder logic as DAO doesn't aggregate yet)
  // For MVP, we'll just mock or fetch last 7 days and count manually?
  // Let's rely on ReportService or manual fetch.
  // We can add getDailyTransactionCounts to ReportService later.
  // For now return basic stats + pie data.

  return {'totalItems': totalItems, 'lowStock': lowStock, 'pieData': categoryValue};
});

class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),

              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    // KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Items',
                            stats['totalItems'].toString(),
                            Colors.blue,
                            Icons.inventory_2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Low Stock',
                            stats['lowStock'].toString(),
                            Colors.orange,
                            Icons.warning_amber,
                            isWarning: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Asset Value Distribution Chart (Pie)
                    _buildPieChartSection(stats['pieData'] as Map<String, double>),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              ),

              const SizedBox(height: 32),
              const Text(
                'Aksi & Laporan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  _buildActionButton(context, 'Laporan\nLengkap', Icons.analytics, Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportSelectionPage()));
                  }),
                  const SizedBox(width: 16),
                  if (ref.watch(authControllerProvider).valueOrNull?.role != 'owner')
                    _buildActionButton(context, 'Scan\nMasuk', Icons.qr_code_scanner, Colors.teal, () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Scan Feature Coming Soon')));
                    })
                  else
                    const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
        ),
        Text('Ringkasan Gudang & Aset', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(Map<String, double> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sections = data.entries.map((e) {
      final index = data.keys.toList().indexOf(e.key);
      final color = Colors.primaries[index % Colors.primaries.length];

      // Simple logic to show percentage or value?
      // Just showing sections.
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${e.key}\n${(e.value / 1000000).toStringAsFixed(1)}M', // Simplified label
        radius: 60,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('Distribusi Nilai Aset (per Kategori)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2)),
          ),
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
              CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), foregroundColor: color, child: Icon(icon)),
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
