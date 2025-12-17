import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:gudang_hadir/core/config/appwrite_config.dart';
import 'package:gudang_hadir/core/services/appwrite_service.dart';
import 'package:gudang_hadir/features/warehouse/data/item_dao.dart';
import 'package:gudang_hadir/features/warehouse/data/transaction_dao.dart';
import 'package:gudang_hadir/features/warehouse/domain/item.dart';
import 'package:gudang_hadir/features/warehouse/domain/transaction.dart';
import 'package:gudang_hadir/features/leave/domain/leave.dart';
import 'package:gudang_hadir/features/attendance/domain/attendance.dart';

class PharmacySeeder {
  final ItemDao _itemDao;
  final TransactionDao _transactionDao;
  final AppwriteService _appwrite;

  PharmacySeeder(this._itemDao, this._transactionDao, this._appwrite);

  Future<void> seed(String userId) async {
    final dataList = _getPharmacyData();
    await _processSeeding(userId, dataList);
  }

  Future<void> seedLowStock(String userId) async {
    final dataList = _getLowStockData();
    await _processSeeding(userId, dataList);
  }

  Future<void> seedAllReports(String adminId) async {
    // 1. Seed Dummy Users (Budi & Siti) - just creating ID references for logs
    const userBudiId = 'user_budi_001';
    const userSitiId = 'user_siti_002';

    // We attempt to create them in 'users' collection if schema supports it
    // If not, reports might miss Name/Photo but will show IDs.
    await _seedUser(userBudiId, 'Budi Santoso', 'Staff');
    await _seedUser(userSitiId, 'Siti Aminah', 'Staff');

    // 2. Seed Attendance (Last 30 Days)
    await _seedAttendanceForUser(userBudiId, 'Budi Santoso');
    await _seedAttendanceForUser(userSitiId, 'Siti Aminah');

    // 3. Seed Leaves
    await _seedLeaves(userBudiId, 'Budi Santoso', adminId);
    await _seedLeaves(userSitiId, 'Siti Aminah', adminId);

    // 4. Seed Turnover Items
    await _seedTurnoverItems(adminId);
  }

  // --- Helpers ---

  Future<void> _seedUser(String uid, String name, String role) async {
    try {
      // Trying to insert into 'users' collection directly for report joins
      await _appwrite.tables.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.usersCollection,
        rowId: uid,
        data: {
          'name': name,
          'email': '$uid@example.com',
          'role': role,
          'photoUrl': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random',
          // 'createdAt': ... system handled
        },
      );
    } catch (e) {
      if (kDebugMode) print('User $name might already exist or error: $e');
    }
  }

  Future<void> _seedAttendanceForUser(String userId, String userName) async {
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) continue;

      final checkIn = DateTime(date.year, date.month, date.day, 7 + (i % 2), 30 + (i % 30));
      final checkOut = DateTime(date.year, date.month, date.day, 16 + (i % 2), 0 + (i % 30));

      final attendance = Attendance(
        id: const Uuid().v4(),
        userId: userId,
        date: "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        checkInTime: checkIn,
        checkOutTime: checkOut,
        checkInMethod: 'QR',
        checkOutMethod: 'QR',
        lat: -6.200000,
        lng: 106.816666,
        isValid: true,
        note: 'Hadir (Seeded)',
        totalDuration: checkOut.difference(checkIn).inHours.toDouble(),
        overtimeHours: 0,
        createdAt: checkIn,
        userName: userName,
      );

      try {
        await _appwrite.tables.createRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.attendancesCollection,
          rowId: attendance.id,
          data: attendance.toJson()
            ..remove('id')
            ..remove('user_name')
            ..remove('createdAt'),
        );
      } catch (e) {
        if (kDebugMode) print('Skip attendance: $e');
      }
    }
  }

  Future<void> _seedLeaves(String userId, String userName, String adminId) async {
    try {
      final leave1 = Leave(
        id: const Uuid().v4(),
        userId: userId,
        userName: userName,
        reason: 'Sakit Demam',
        startDate: '2025-12-20',
        endDate: '2025-12-22',
        status: 'pending',
        createdAt: DateTime.now(),
      );
      await _appwrite.tables.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.leavesCollection,
        rowId: leave1.id,
        data: leave1.toJson(),
      );
    } catch (_) {}

    try {
      final leave2 = Leave(
        id: const Uuid().v4(),
        userId: userId,
        userName: userName,
        reason: 'Cuti Tahunan',
        startDate: '2025-11-10',
        endDate: '2025-11-12',
        status: 'approved',
        adminId: adminId,
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      );
      await _appwrite.tables.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.leavesCollection,
        rowId: leave2.id,
        data: leave2.toJson(),
      );
    } catch (_) {}
  }

  Future<void> _seedTurnoverItems(String userId) async {
    final items = [
      _ItemData(
        code: 'ALK70',
        name: 'Alkohol 70% 1L',
        category: 'Cairan',
        unit: 'Botol',
        stock: 50,
        minStock: 10,
        rack: 'X-1',
        desc: 'Alkohol',
        price: 25000,
        manufacturer: 'Generic',
      ),
      _ItemData(
        code: 'PLESTER',
        name: 'Plester Rol',
        category: 'Alkes',
        unit: 'Roll',
        stock: 100,
        minStock: 20,
        rack: 'X-2',
        desc: 'Plester',
        price: 5000,
        manufacturer: 'Generic',
      ),
    ];

    for (final data in items) {
      final itemId = const Uuid().v4();
      try {
        await _itemDao.insertItem(
          Item(
            id: itemId,
            code: data.code,
            name: data.name,
            category: data.category,
            unit: data.unit,
            stock: data.stock,
            minStock: data.minStock,
            rackLocation: data.rack,
            description: data.desc,
            price: data.price,
            manufacturer: data.manufacturer,
            discontinued: false,
            updatedAt: DateTime.now(),
          ),
        );
      } catch (_) {}

      final types = ['IN', 'OUT', 'OUT', 'IN', 'OUT'];
      for (int i = 0; i < types.length; i++) {
        try {
          await _transactionDao.insertTransaction(
            WarehouseTransaction(
              id: const Uuid().v4(),
              itemId: itemId,
              type: types[i],
              qty: 5 + i * 2,
              note: 'Turnover simulation',
              createdAt: DateTime.now().subtract(Duration(days: 10 - i)),
              createdBy: userId,
            ),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _processSeeding(String userId, List<_ItemData> dataList) async {
    for (final data in dataList) {
      if (kDebugMode) print('Seeding item: ${data.name}');

      final itemId = const Uuid().v4();
      final item = Item(
        id: itemId,
        code: data.code,
        name: data.name,
        category: data.category,
        unit: data.unit,
        stock: data.stock,
        minStock: data.minStock,
        rackLocation: data.rack,
        description: data.desc,
        price: data.price,
        manufacturer: data.manufacturer,
        discontinued: false,
        updatedAt: DateTime.now(),
      );

      try {
        await _itemDao.insertItem(item);
      } catch (e) {
        if (kDebugMode) print('Error seeding item ${data.name}: $e');
        continue;
      }

      if (data.stock > 0) {
        try {
          final transaction = WarehouseTransaction(
            id: const Uuid().v4(),
            itemId: itemId,
            type: 'IN',
            qty: data.stock,
            note: data.stock == 0 ? 'Initial Data (Out of Stock)' : 'Initial Seeding Data',
            createdAt: DateTime.now(),
            createdBy: userId,
          );
          await _transactionDao.insertTransaction(transaction);
        } catch (e) {
          if (kDebugMode) print('Error seeding transaction for ${data.name}: $e');
        }
      }
    }
  }

  List<_ItemData> _getPharmacyData() {
    return [
      _ItemData(
        code: 'PCT500',
        name: 'Paracetamol 500mg',
        category: 'Analgesik',
        unit: 'Box',
        stock: 100,
        minStock: 20,
        rack: 'Rak A-01',
        desc: 'Obat pereda nyeri',
        price: 25000,
        manufacturer: 'Kimia Farma',
      ),
      _ItemData(
        code: 'AMX500',
        name: 'Amoxicillin 500mg',
        category: 'Antibiotik',
        unit: 'Strip',
        stock: 50,
        minStock: 10,
        rack: 'Rak A-02',
        desc: 'Antibiotik',
        price: 8000,
        manufacturer: 'Dexa Medica',
      ),
      _ItemData(
        code: 'VITC500',
        name: 'Vitamin C 500mg IPI',
        category: 'Vitamin',
        unit: 'Botol',
        stock: 200,
        minStock: 50,
        rack: 'Rak B-01',
        desc: 'Suplemen',
        price: 15000,
        manufacturer: 'Supra Ferbindo',
      ),
      _ItemData(
        code: 'OBH001',
        name: 'OBH Combi Batuk Berdahak',
        category: 'Sirup',
        unit: 'Botol',
        stock: 75,
        minStock: 15,
        rack: 'Rak B-02',
        desc: 'Obat batuk',
        price: 22000,
        manufacturer: 'Combiphar',
      ),
      _ItemData(
        code: 'BET001',
        name: 'Betadine Antiseptic 15ml',
        category: 'Antiseptik',
        unit: 'Botol',
        stock: 40,
        minStock: 10,
        rack: 'Rak C-01',
        desc: 'Obat luka',
        price: 18000,
        manufacturer: 'Mundipharma',
      ),
      _ItemData(
        code: 'SNG001',
        name: 'Sangobion Kapsul',
        category: 'Vitamin',
        unit: 'Strip',
        stock: 60,
        minStock: 20,
        rack: 'Rak C-02',
        desc: 'Penambah darah',
        price: 21000,
        manufacturer: 'Merck',
      ),
      _ItemData(
        code: 'PRO001',
        name: 'Promag Tablet',
        category: 'Antasida',
        unit: 'Blister',
        stock: 150,
        minStock: 30,
        rack: 'Rak D-01',
        desc: 'Obat maag',
        price: 9000,
        manufacturer: 'Kalbe Farma',
      ),
      _ItemData(
        code: 'MYL001',
        name: 'Mylanta Cair 50ml',
        category: 'Antasida',
        unit: 'Botol',
        stock: 30,
        minStock: 5,
        rack: 'Rak D-02',
        desc: 'Obat maag cair',
        price: 18500,
        manufacturer: 'Johnson & Johnson',
      ),
      _ItemData(
        code: 'INS001',
        name: 'Insto Regular 7.5ml',
        category: 'Obat Mata',
        unit: 'Botol',
        stock: 80,
        minStock: 10,
        rack: 'Rak E-01',
        desc: 'Tetes mata',
        price: 16000,
        manufacturer: 'Combiphar',
      ),
      _ItemData(
        code: 'TMS001',
        name: 'Tempra Syrup Anggur',
        category: 'Analgesik Anak',
        unit: 'Botol',
        stock: 45,
        minStock: 10,
        rack: 'Rak E-02',
        desc: 'Paracetamol sirup',
        price: 55000,
        manufacturer: 'Taisho',
      ),
    ];
  }

  List<_ItemData> _getLowStockData() {
    return [
      _ItemData(
        code: 'GAUZE01',
        name: 'Kain Kasa Steril 16x16',
        category: 'Alkes',
        unit: 'Box',
        stock: 2,
        minStock: 10,
        rack: 'Rak Z-01',
        desc: 'Kain kasa steril',
        price: 12000,
        manufacturer: 'OneMed',
      ),
      _ItemData(
        code: 'BETSLP',
        name: 'Betadine Salep 10gr',
        category: 'Antiseptik',
        unit: 'Tube',
        stock: 1,
        minStock: 5,
        rack: 'Rak C-03',
        desc: 'Salep antiseptik',
        price: 20000,
        manufacturer: 'Mundipharma',
      ),
      _ItemData(
        code: 'MSK001',
        name: 'Masker Medis 3-Ply',
        category: 'Alkes',
        unit: 'Box',
        stock: 5,
        minStock: 50,
        rack: 'Rak Z-02',
        desc: 'Masker medis',
        price: 35000,
        manufacturer: 'Sensi',
      ),
      _ItemData(
        code: 'HANDSAN',
        name: 'Hand Sanitizer 500ml',
        category: 'Kebersihan',
        unit: 'Botol',
        stock: 0,
        minStock: 20,
        rack: 'Rak Z-03',
        desc: 'Cairan pembersih',
        price: 45000,
        manufacturer: 'Antis',
      ),
      _ItemData(
        code: 'THERMO',
        name: 'Termometer Digital',
        category: 'Alat Medis',
        unit: 'Pcs',
        stock: 2,
        minStock: 5,
        rack: 'Rak Y-01',
        desc: 'Alat pengukur suhu',
        price: 75000,
        manufacturer: 'Omron',
      ),
    ];
  }
}

class _ItemData {
  final String code;
  final String name;
  final String category;
  final String unit;
  final int stock;
  final int minStock;
  final String rack;
  final String desc;
  final double price;
  final String manufacturer;

  _ItemData({
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.stock,
    required this.minStock,
    required this.rack,
    required this.desc,
    required this.price,
    required this.manufacturer,
  });
}
