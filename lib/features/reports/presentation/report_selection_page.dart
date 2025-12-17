import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../reports/domain/report_service.dart';
import '../../reports/data/report_history_dao.dart';
import '../domain/generated_report.dart';
import '../../auth/presentation/auth_controller.dart';

class ReportSelectionPage extends ConsumerStatefulWidget {
  const ReportSelectionPage({super.key});

  @override
  ConsumerState<ReportSelectionPage> createState() => _ReportSelectionPageState();
}

class _ReportSelectionPageState extends ConsumerState<ReportSelectionPage> {
  bool _isLoading = false;

  // --- Filtering & Generation ---

  void _showReportCreationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final reportService = ref.read(reportServiceProvider);
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Pilih Jenis Laporan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionHeader('Keuangan & Stok'),
                      _buildReportCard(
                        'Valuasi Stok',
                        'Total nilai aset barang.',
                        Icons.monetization_on,
                        Colors.green,
                        () => _showFilterAndDownloadDialog(
                          'Stock Valuation',
                          'stock_valuation',
                          ({start, end}) => reportService.getStockValuation(),
                        ),
                      ),
                      _buildReportCard(
                        'Rencana Reorder',
                        'Barang stok menipis.',
                        Icons.shopping_cart_checkout,
                        Colors.orange,
                        () => _showFilterAndDownloadDialog(
                          'Reorder Plan',
                          'reorder_plan',
                          ({start, end}) => reportService.getReorderPlan(),
                        ),
                      ),
                      _buildReportCard(
                        'Item Turnover',
                        'Barang Fast Moving.',
                        Icons.trending_up,
                        Colors.blue,
                        () => _showFilterAndDownloadDialog(
                          'Item Turnover',
                          'item_turnover',
                          ({start, end}) => reportService.getItemTurnover(start: start, end: end),
                          supportsDateFilter: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionHeader('Karyawan'),
                      _buildReportCard(
                        'Kinerja Karyawan',
                        'Skor produktivitas.',
                        Icons.people,
                        Colors.purple,
                        () => _showFilterAndDownloadDialog(
                          'Employee Performance',
                          'employee_performance',
                          ({start, end}) => reportService.getEmployeePerformance(start: start, end: end),
                          supportsDateFilter: true,
                        ),
                      ),
                      _buildReportCard(
                        'Laporan Absensi',
                        'Detail kehadiran.',
                        Icons.access_time,
                        Colors.teal,
                        () => _showFilterAndDownloadDialog(
                          'Attendance Report',
                          'attendance_report',
                          ({start, end}) => reportService.getAttendanceReport(start: start, end: end),
                          supportsDateFilter: true,
                        ),
                      ),
                      _buildReportCard(
                        'Laporan Cuti',
                        'Histori cuti.',
                        Icons.event_note,
                        Colors.amber,
                        () => _showFilterAndDownloadDialog(
                          'Leave Report',
                          'leave_report',
                          ({start, end}) => reportService.getLeaveReport(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFilterAndDownloadDialog(
    String title,
    String reportType,
    Future<Map<String, dynamic>> Function({DateTime? start, DateTime? end}) dataFetcher, {
    bool supportsDateFilter = false,
  }) {
    // Default to 'This Month'
    DateTime? start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime? end = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    String filterLabel = 'This Month';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Download $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),

                  if (supportsDateFilter) ...[
                    const Text('Periode:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _FilterChip(
                          label: 'Bulan Ini',
                          selected: filterLabel == 'This Month',
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                filterLabel = 'This Month';
                                final now = DateTime.now();
                                start = DateTime(now.year, now.month, 1);
                                end = DateTime(now.year, now.month + 1, 0);
                              });
                            }
                          },
                        ),
                        _FilterChip(
                          label: '30 Hari Terakhir',
                          selected: filterLabel == 'Last 30 Days',
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                filterLabel = 'Last 30 Days';
                                end = DateTime.now();
                                start = end!.subtract(const Duration(days: 30));
                              });
                            }
                          },
                        ),
                        // Add more if needed (Custom not implemented for brevity, can add later)
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text('Format File:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          label: const Text('PDF'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () =>
                              _handleGenerate(title, reportType, dataFetcher, false, start, end, filterLabel),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.table_view, color: Colors.green),
                          label: const Text('Excel'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () =>
                              _handleGenerate(title, reportType, dataFetcher, true, start, end, filterLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleGenerate(
    String title,
    String reportType,
    Future<Map<String, dynamic>> Function({DateTime? start, DateTime? end}) dataFetcher, // Updated signature
    bool isExcel,
    DateTime? start,
    DateTime? end,
    String filterType,
  ) async {
    // Close both modals
    Navigator.pop(context); // Filter Dialog
    Navigator.pop(context); // Selection Sheet

    setState(() => _isLoading = true);

    try {
      final userState = ref.read(authControllerProvider);
      final userId = userState.value?.id ?? 'unknown';

      // Need to adapt the dataFetcher to match the signature if it doesn't take args?
      // Only some reports take args. We can wrap them.

      final report = await ref
          .read(reportServiceProvider)
          .generateAndSaveReport(
            title: title,
            reportType: reportType,
            dataFetcher: () => dataFetcher(start: start, end: end),
            isExcel: isExcel,
            userId: userId,
            startDate: start,
            endDate: end,
            filterType: filterType,
          );

      if (mounted) {
        // Refresh list automatically via riverpod logic?
        // We're using FutureBuilder, so we need to trigger rebuild or invalidate provider if we used one.
        // But here we just use FutureBuilder on `getHistory`.
        // To refresh, we should switch to a Stream or invalidate a provider.
        setState(() {}); // Simple rebuild to trigger FutureBuilder again

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Laporan berhasil disimpan!'),
            action: SnackBarAction(label: 'BUKA', onPressed: () => _handleOpenReport(report)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Gagal membuat laporan: $e';
        if (e.toString().contains('Schema Mismatch')) {
          // Example check for specific error
          errorMessage = 'Gagal membuat laporan: Terjadi ketidakcocokan skema data. Mohon periksa kembali data Anda.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOpenReport(GeneratedReport report) async {
    setState(() => _isLoading = true);
    try {
      // 1. Download via Authenticated SDK
      final bytes = await ref.read(reportHistoryDaoProvider).downloadFile(report.fileId);

      // 2. Save to Temp File
      final dir = await getTemporaryDirectory();
      // Clean filename
      final safeTitle = report.title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final extension = report.format == 'excel' ? 'xlsx' : 'pdf';
      final file = File('${dir.path}/${safeTitle}_${report.fileId}.$extension');

      await file.writeAsBytes(bytes);

      // 3. Open File
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: ${result.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka file: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: () => _handleOpenReport(report)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    final reportService = ref.read(reportServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Laporan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<GeneratedReport>>(
              future: reportService.getHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Belum ada riwayat laporan.', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        const Text('Tekan tombol + untuk membuat laporan baru.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return Card(
                      elevation: 0,
                      color: Colors.grey[50],
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (report.format == 'pdf' ? Colors.red : Colors.green).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            report.format == 'pdf' ? Icons.picture_as_pdf : Icons.table_view,
                            color: report.format == 'pdf' ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${report.filterType} • ${report.createdAt.toLocal().toString().split('.')[0]}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'open') {
                              _handleOpenReport(report);
                            } else if (value == 'copy') {
                              Clipboard.setData(ClipboardData(text: report.fileUrl));
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('Link download berhasil disalin')));
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'open',
                              child: Row(
                                children: [
                                  Icon(Icons.open_in_new, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text('Buka Laporan'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy',
                              child: Row(
                                children: [
                                  Icon(Icons.copy, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text('Salin Link Download'),
                                ],
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert),
                        ),
                        onTap: () => _handleOpenReport(report),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportCreationSheet,
        icon: const Icon(Icons.add),
        label: const Text('Buat Laporan'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          radius: 24,
          child: Icon(icon, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const _FilterChip({required this.label, required this.selected, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
