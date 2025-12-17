import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../auth/data/auth_repository.dart';
import '../data/leave_dao.dart';
import '../domain/leave.dart';

final leaveDaoProvider = Provider((ref) => LeaveDao(AppwriteService.instance));

// Providers for Data
final myLeavesProvider = FutureProvider.autoDispose((ref) async {
  final user = await ref.read(authRepositoryProvider).getCurrentUser();
  if (user == null) return [];
  return ref.read(leaveDaoProvider).getLeavesByUser(user.id);
});

final pendingLeavesProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(leaveDaoProvider).getPendingLeaves();
});

final allLeavesProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(leaveDaoProvider).getAllLeaves();
});

// Controller for Actions
final leaveControllerProvider = StateNotifierProvider<LeaveController, AsyncValue<void>>((ref) {
  return LeaveController(ref.read(leaveDaoProvider), ref.read(authRepositoryProvider), ref);
});

class LeaveController extends StateNotifier<AsyncValue<void>> {
  final LeaveDao _dao;
  final AuthRepository _authRepo;
  final Ref _ref;

  LeaveController(this._dao, this._authRepo, this._ref) : super(const AsyncValue.data(null));

  Future<void> submitRequest(String reason, DateTime start, DateTime end) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      final leave = Leave(
        id: const Uuid().v4(),
        userId: user.id,
        userName: user.name,
        reason: reason,
        startDate: start.toIso8601String(),
        endDate: end.toIso8601String(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _dao.createLeave(leave);
      state = const AsyncValue.data(null);
      return _ref.refresh(myLeavesProvider.future);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> approveRequest(Leave leave) async {
    state = const AsyncValue.loading();
    try {
      final admin = await _authRepo.getCurrentUser();
      if (admin == null) throw Exception('Admin not logged in');

      // 1. Generate PDF
      final pdfBytes = await PdfGenerator.generateLeaveApproval(leave, admin.name);

      // 2. Upload to Appwrite
      final fileId = const Uuid().v4();
      await AppwriteService.instance.storage.createFile(
        bucketId: AppwriteConfig.storageBucketId,
        fileId: fileId,
        file: InputFile.fromBytes(filename: 'surat_cuti_${leave.id}.pdf', bytes: pdfBytes),
      );

      // 3. Update Status
      await _dao.updateStatus(leave.id, 'approved', adminId: admin.id, pdfFileId: fileId);

      state = const AsyncValue.data(null);
      // Refresh both pending and all
      _ref.refresh(pendingLeavesProvider.future);
      return _ref.refresh(allLeavesProvider.future);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectRequest(String leaveId) async {
    state = const AsyncValue.loading();
    try {
      final admin = await _authRepo.getCurrentUser();
      if (admin == null) throw Exception('Admin not logged in');

      await _dao.updateStatus(leaveId, 'rejected', adminId: admin.id);
      state = const AsyncValue.data(null);
      _ref.refresh(pendingLeavesProvider.future);
      return _ref.refresh(allLeavesProvider.future);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLeave(String leaveId) async {
    state = const AsyncValue.loading();
    try {
      await _dao.deleteLeave(leaveId);
      state = const AsyncValue.data(null);
      _ref.refresh(pendingLeavesProvider.future);
      _ref.refresh(allLeavesProvider.future);
      return _ref.refresh(myLeavesProvider.future);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<int>> downloadPdf(String fileId) async {
    return await AppwriteService.instance.storage.getFileDownload(
      bucketId: AppwriteConfig.storageBucketId,
      fileId: fileId,
    );
  }
}
