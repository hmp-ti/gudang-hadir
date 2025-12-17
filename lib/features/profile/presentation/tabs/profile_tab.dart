import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/auth_controller.dart';
import 'package:gudang_hadir/core/services/appwrite_service.dart';
import '../../../../core/utils/pharmacy_seeder.dart';
import 'package:gudang_hadir/features/warehouse/data/item_dao.dart';
import 'package:gudang_hadir/features/warehouse/data/transaction_dao.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _handleSeeding(BuildContext context, WidgetRef ref, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Data Pharmacy?'),
        content: const Text(
          'Akan menambahkan data obat-obatan dummy dan transaksi awal. Data lama tidak dihapus (duplicates mungkin terjadi jika kode sama).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lanjutkan')),
        ],
      ),
    );

    if (confirm == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding data...')));
      }

      try {
        final seeder = PharmacySeeder(
          ref.read(itemDaoProvider),
          ref.read(transactionDaoProvider),
          AppwriteService.instance, // Now required
        );
        await seeder.seed(userId);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Seeding selesai! Refresh halaman barang.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal seeding: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final user = userAsync.value;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (user?.photoUrl != null)
            CircleAvatar(radius: 60, backgroundImage: NetworkImage(user!.photoUrl!))
          else
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey,
              child: Icon(Icons.account_circle, size: 80, color: Colors.white),
            ),
          const SizedBox(height: 16),
          Text(user?.name ?? 'Nama Pengguna', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '@email', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(user?.role.toUpperCase() ?? 'ROLE', style: const TextStyle(fontSize: 14, color: Colors.blue)),

          const SizedBox(height: 48),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            icon: const Icon(Icons.logout),
            label: const Text('KELUAR (LOGOUT)'),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              // Router will auto redirect to login
            },
          ),

          if (user != null && (user.role == 'owner' || user.role == 'admin')) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.science),
              label: const Text('Seed Data (Pharmacy)'),
              onPressed: () => _handleSeeding(context, ref, user.id),
            ),
            TextButton.icon(
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Seed Low Stock'),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              onPressed: () => _handleLowStockSeeding(context, ref, user.id),
            ),
            TextButton.icon(
              icon: const Icon(Icons.people_alt),
              label: const Text('Seed All Reports (User, Att, Leave, Stock)'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              onPressed: () => _handleAllReportsSeeding(context, ref, user.id),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleLowStockSeeding(BuildContext context, WidgetRef ref, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Low Stock?'),
        content: const Text('Akan menambahkan 5 barang dengan stok sedikit/habis untuk simulasi low stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lanjutkan')),
        ],
      ),
    );

    if (confirm == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding low stock...')));
      }

      try {
        final seeder = PharmacySeeder(
          ref.read(itemDaoProvider),
          ref.read(transactionDaoProvider),
          AppwriteService.instance, // Now required
        );
        await seeder.seedLowStock(userId);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Seeding selesai! Refresh halaman barang.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal seeding: $e')));
        }
      }
    }
  }

  Future<void> _handleAllReportsSeeding(BuildContext context, WidgetRef ref, String adminId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed All Reports?'),
        content: const Text(
          'Akan membuat: User Dummy (Budi & Siti), Absensi 30 hari terakhir, Cuti, dan Barang Turnover.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lanjutkan')),
        ],
      ),
    );

    if (confirm == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding all reports...')));
      }

      try {
        final seeder = PharmacySeeder(
          ref.read(itemDaoProvider),
          ref.read(transactionDaoProvider),
          AppwriteService.instance,
        );
        await seeder.seedAllReports(adminId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding Reports selesai!')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal seeding reports: $e')));
        }
      }
    }
  }
}
