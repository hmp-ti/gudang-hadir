import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/validators.dart';
import '../settings_controller.dart';
import '../../../auth/presentation/auth_controller.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _radiusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill fields is handled by watching state below
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengaturan Absensi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
            data: (settings) {
              final lat = settings[AppConstants.keyWarehouseLat];
              final lng = settings[AppConstants.keyWarehouseLng];
              final token = settings[AppConstants.keyQrSecretToken] ?? 'unknown';

              // Update radius controller only once if needed, but setState logic is tricky in build.
              // Just simpler to use a "Update" dialog or button for radius.
              final radius = settings[AppConstants.keyAttendanceRadius] ?? '100';
              _radiusController.text = radius;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Lokasi Gudang'),
                  Text(lat != null ? 'Lat: $lat, Lng: $lng' : 'Belum diset'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: const Text('Set Lokasi Saat Ini (Sebagai Gudang)'),
                    onPressed: () => _updateLocation(context, ref),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Radius Absensi (meter)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _radiusController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(suffixText: 'meter'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        child: const Text('Simpan'),
                        onPressed: () {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .updateSetting(AppConstants.keyAttendanceRadius, _radiusController.text);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersimpan')));
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  _buildSectionTitle('QR Code Absensi'),
                  const Text('Print QR ini dan tempel di lokasi absen.'),
                  const SizedBox(height: 16),
                  Center(child: _buildQrCode(token)),
                  const SizedBox(height: 32),
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      icon: const Icon(Icons.logout),
                      label: const Text('KELUAR (LOGOUT)'),
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).logout();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQrCode(String token) {
    final payload = jsonEncode({"app": "Gudang Hadir", "type": "ATTENDANCE_POINT", "token": token});

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          QrImageView(data: payload, version: QrVersions.auto, size: 200.0),
          const SizedBox(height: 8),
          const Text('Scan pakai App Gudang Hadir', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _updateLocation(BuildContext context, WidgetRef ref) async {
    // Permission check
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin lokasi permanen ditolak. Cek setelan HP.')));
      return;
    }

    // Get Location
    try {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mendaptkan lokasi...')));

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      await ref.read(settingsControllerProvider.notifier).setWarehouseLocation(position.latitude, position.longitude);

      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lokasi Gudang Diperbarui')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
