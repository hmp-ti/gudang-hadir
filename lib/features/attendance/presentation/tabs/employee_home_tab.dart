import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../attendance_controller.dart';
import '../qr_scan_page.dart';

class EmployeeHomeTab extends ConsumerWidget {
  const EmployeeHomeTab({super.key});

  Future<void> _handleScan(BuildContext context, WidgetRef ref, bool isCheckIn) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScanPage()));
    if (result != null && result is String) {
      try {
        if (isCheckIn) {
          await ref.read(attendanceControllerProvider.notifier).checkInQR(result);
        } else {
          await ref.read(attendanceControllerProvider.notifier).checkOutQR(result);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sukses Absen via QR'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _handleGPS(BuildContext context, WidgetRef ref, bool isCheckIn) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Expanded(child: Text(isCheckIn ? 'Memproses Lokasi...' : 'Memproses Checkout...')),
          ],
        ),
      ),
    );

    try {
      if (isCheckIn) {
        await ref.read(attendanceControllerProvider.notifier).checkInGPS();
      } else {
        await ref.read(attendanceControllerProvider.notifier).checkOutGPS();
      }

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sukses Absen via GPS'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attAsync = ref.watch(attendanceControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(attendanceControllerProvider.notifier).loadTodayAttendance();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: attAsync.when(
            loading: () => const Center(heightFactor: 10, child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
            data: (attendance) {
              final todayStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
              final bool isCheckedIn = attendance?.checkInTime != null;
              final bool isCheckedOut = attendance?.checkOutTime != null;

              String statusTitle = 'Selamat Pagi!';
              String statusSubtitle = 'Jangan lupa absen hari ini.';
              Color statusColor = const Color(0xFF0D47A1); // Deep Blue

              if (isCheckedIn && !isCheckedOut) {
                statusTitle = 'Selamat Bekerja';
                statusSubtitle = 'Anda sudah absen masuk.';
                statusColor = const Color(0xFF00695C); // Teal
              } else if (isCheckedOut) {
                statusTitle = 'Terima Kasih';
                statusSubtitle = 'Anda sudah selesai bekerja hari ini.';
                statusColor = Colors.orange.shade800;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [statusColor, statusColor.withValues(alpha: 0.8)]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(todayStr, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          statusTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(statusSubtitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 16),
                        if (isCheckedIn)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              'Masuk: ${DateFormat('HH:mm').format(attendance!.checkInTime!)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Menu Absensi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                  ),
                  const SizedBox(height: 16),
                  if (!isCheckedIn) ...[
                    _buildActionCard(
                      context,
                      title: 'Absen Masuk (SCAN QR)',
                      subtitle: 'Scan QR Code di lokasi gudang',
                      icon: Icons.qr_code_scanner,
                      color: Colors.blue,
                      onTap: () => _handleScan(context, ref, true),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context,
                      title: 'Absen Masuk (GPS)',
                      subtitle: 'Gunakan lokasi saat ini',
                      icon: Icons.gps_fixed,
                      color: Colors.blueAccent,
                      onTap: () => _handleGPS(context, ref, true),
                    ),
                  ] else if (!isCheckedOut) ...[
                    _buildActionCard(
                      context,
                      title: 'Absen Pulang (SCAN QR)',
                      subtitle: 'Scan untuk mengakhiri hari',
                      icon: Icons.qr_code,
                      color: Colors.orange,
                      onTap: () => _handleScan(context, ref, false),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context,
                      title: 'Absen Pulang (GPS)',
                      subtitle: 'Checkout dengan lokasi',
                      icon: Icons.gps_fixed,
                      color: Colors.orangeAccent,
                      onTap: () => _handleGPS(context, ref, false),
                    ),
                  ] else ...[
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                          const SizedBox(height: 16),
                          Text('Sampai jumpa besok!', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
