import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: AppConstants.dbVersion, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const boolType = 'INTEGER';
    const integerType = 'INTEGER';
    const realType = 'REAL';
    const uuid = Uuid();

    // 1. Users Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableUsers} (
        id $idType,
        name $textType,
        username $textType UNIQUE,
        password_hash $textType,
        role $textType CHECK(role IN ('admin','karyawan')),
        is_active $boolType,
        created_at $textType
      )
    ''');

    // 2. Items Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableItems} (
        id $idType,
        code $textType UNIQUE,
        name $textType,
        category $textType,
        unit $textType,
        stock $integerType,
        min_stock $integerType,
        rack_location $textType,
        description $textType,
        updated_at $textType
      )
    ''');

    // 3. Warehouse Transactions Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTransactions} (
        id $idType,
        item_id $textType,
        type $textType CHECK(type IN ('IN','OUT')),
        qty $integerType,
        note $textType,
        created_at $textType,
        created_by $textType,
        FOREIGN KEY (item_id) REFERENCES ${AppConstants.tableItems} (id),
        FOREIGN KEY (created_by) REFERENCES ${AppConstants.tableUsers} (id)
      )
    ''');

    // 4. Attendances Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableAttendances} (
        id $idType,
        user_id $textType,
        date $textType,
        check_in_time $textType,
        check_out_time $textType,
        check_in_method $textType CHECK(check_in_method IN ('QR','GPS')),
        check_out_method $textType CHECK(check_out_method IN ('QR','GPS')),
        lat $realType,
        lng $realType,
        is_valid $boolType,
        created_at $textType,
        FOREIGN KEY (user_id) REFERENCES ${AppConstants.tableUsers} (id)
      )
    ''');

    // 5. App Settings Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableAppSettings} (
        key $textType PRIMARY KEY,
        value $textType
      )
    ''');

    // Seed Data
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now().toIso8601String();
    const uuid = Uuid();

    // Admin
    await db.insert(AppConstants.tableUsers, {
      'id': uuid.v4(),
      'name': 'Administrator',
      'username': 'admin',
      'password_hash': '123456', // In real app, hash this!
      'role': 'admin',
      'is_active': 1,
      'created_at': now,
    });

    // Karyawan 1
    await db.insert(AppConstants.tableUsers, {
      'id': uuid.v4(),
      'name': 'Karyawan Satu',
      'username': 'user1',
      'password_hash': '123456',
      'role': 'karyawan',
      'is_active': 1,
      'created_at': now,
    });

    // Karyawan 2
    await db.insert(AppConstants.tableUsers, {
      'id': uuid.v4(),
      'name': 'Karyawan Dua',
      'username': 'user2',
      'password_hash': '123456',
      'role': 'karyawan',
      'is_active': 1,
      'created_at': now,
    });

    // Settings
    await db.insert(AppConstants.tableAppSettings, {
      'key': AppConstants.keyAttendanceRadius,
      'value': AppConstants.defaultAttendanceRadius.toString(),
    });

    await db.insert(AppConstants.tableAppSettings, {'key': AppConstants.keyQrSecretToken, 'value': uuid.v4()});

    // Warehouse Lat/Lng null by default, no insert needed or insert null
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
