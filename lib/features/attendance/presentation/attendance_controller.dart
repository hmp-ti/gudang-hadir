import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/utils/constants.dart';
import '../../auth/data/auth_repository.dart';
import '../../settings/data/settings_dao.dart';
import '../data/attendance_dao.dart';
import '../domain/attendance.dart';

final attendanceDaoProvider = Provider((ref) => AttendanceDao(AppwriteService.instance));
final settingsDaoProvider = Provider((ref) => SettingsDao(AppwriteService.instance));

final attendanceControllerProvider = StateNotifierProvider<AttendanceController, AsyncValue<Attendance?>>((ref) {
  return AttendanceController(
    ref.read(attendanceDaoProvider),
    ref.read(settingsDaoProvider),
    ref.read(authRepositoryProvider),
  );
});

class AttendanceController extends StateNotifier<AsyncValue<Attendance?>> {
  final AttendanceDao _attendanceDao;
  final SettingsDao _settingsDao;
  final AuthRepository _authRepository;

  AttendanceController(this._attendanceDao, this._settingsDao, this._authRepository)
    : super(const AsyncValue.loading()) {
    loadTodayAttendance();
  }

  Future<void> loadTodayAttendance() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final att = await _attendanceDao.getAttendanceToday(user.id, today);
      state = AsyncValue.data(att);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _performCheck(bool isCheckIn, String method, {String? qrPayload}) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) throw Exception('Session expired');

      // 1. Validate Method
      if (method == 'QR') {
        if (qrPayload == null) throw Exception('QR Payload empty');
        try {
          final data = jsonDecode(qrPayload);
          if (data['app'] != 'GudangHadir') throw Exception('QR tidak valid');

          final token = await _settingsDao.getSetting(AppConstants.keyQrSecretToken);
          if (data['token'] != token) throw Exception('Token QR salah!');
        } catch (e) {
          throw Exception('QR Invalid: $e');
        }
      } else if (method == 'GPS') {
        // GPS Validation
        final latStr = await _settingsDao.getSetting(AppConstants.keyWarehouseLat);
        final lngStr = await _settingsDao.getSetting(AppConstants.keyWarehouseLng);
        if (latStr == null || lngStr == null) throw Exception('Lokasi gudang belum diset admin');

        final whLat = double.parse(latStr);
        final whLng = double.parse(lngStr);
        final radius = double.parse(await _settingsDao.getSetting(AppConstants.keyAttendanceRadius) ?? '100');

        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final dist = Geolocator.distanceBetween(whLat, whLng, pos.latitude, pos.longitude);

        if (dist > radius) {
          throw Exception('Anda di luar jangkauan ($dist meter). Max: $radius m.');
        }
      }

      // 2. Perform Action
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final now = DateTime.now();

      if (isCheckIn) {
        // Create new
        final newAtt = Attendance(
          id: const Uuid().v4(),
          userId: user.id,
          date: today,
          checkInTime: now,
          checkInMethod: method,
          isValid: true,
          createdAt: now,
          lat: 0, // Simplified, ideal: capture current lat/lng always
          lng: 0,
        );
        await _attendanceDao.insertAttendance(newAtt);
      } else {
        // Update check out
        final current = state.value;
        if (current == null) throw Exception('Belum absen masuk');

        final updatedAtt = Attendance(
          id: current.id,
          userId: current.userId,
          date: current.date,
          checkInTime: current.checkInTime,
          checkInMethod: current.checkInMethod,
          checkOutTime: now,
          checkOutMethod: method,
          isValid: true,
          createdAt: current.createdAt,
          lat: current.lat,
          lng: current.lng,
        );
        await _attendanceDao.updateAttendance(updatedAtt);
      }

      await loadTodayAttendance();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkInQR(String rawResult) async {
    await _performCheck(true, 'QR', qrPayload: rawResult);
  }

  Future<void> checkInGPS() async {
    await _performCheck(true, 'GPS');
  }

  Future<void> checkOutQR(String rawResult) async {
    await _performCheck(false, 'QR', qrPayload: rawResult);
  }

  Future<void> checkOutGPS() async {
    await _performCheck(false, 'GPS');
  }
}
