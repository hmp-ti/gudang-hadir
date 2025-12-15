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
    try {
      if (isCheckIn) {
        await ref.read(attendanceControllerProvider.notifier).checkInGPS();
      } else {
        await ref.read(attendanceControllerProvider.notifier).checkOutGPS();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sukses Absen via GPS'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attAsync = ref.watch(attendanceControllerProvider);

    return Center(
      // Center content
      child: attAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (e, st) => Text('Error: $e'),
        data: (attendance) {
          final todayStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(DateTime.now());

          final bool isCheckedIn = attendance?.checkInTime != null;
          final bool isCheckedOut = attendance?.checkOutTime != null;

          String statusText = 'Belum Absen Hari Ini';
          if (isCheckedIn && !isCheckedOut) statusText = 'Sudah Masuk (Belum Pulang)';
          if (isCheckedOut) statusText = 'Sudah Selesai (Pulang)';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(todayStr, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 16),
                Text(
                  statusText,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                if (!isCheckedIn) ...[
                  _buildActionButton(
                    icon: Icons.qr_code,
                    label: 'Absen Masuk (QR)',
                    color: Colors.blue,
                    onPressed: () => _handleScan(context, ref, true),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.gps_fixed,
                    label: 'Absen Masuk (GPS)',
                    color: Colors.blueAccent,
                    onPressed: () => _handleGPS(context, ref, true),
                  ),
                ] else if (!isCheckedOut) ...[
                  _buildActionButton(
                    icon: Icons.qr_code,
                    label: 'Absen Pulang (QR)',
                    color: Colors.orange,
                    onPressed: () => _handleScan(context, ref, false),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.gps_fixed,
                    label: 'Absen Pulang (GPS)',
                    color: Colors.orangeAccent,
                    onPressed: () => _handleGPS(context, ref, false),
                  ),
                ] else ...[
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('Jaga kesehatan! Sampai jumpa besok.'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        onPressed: onPressed,
      ),
    );
  }
}
