import 'dart:async';

import 'package:expense_tracker/models/chartdata.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._init();
  static DBHelper get instance => _instance;
  static Database? _dataBase;

  DBHelper._init();

  Future<Database> get database async {
    if (_dataBase != null) {
      return _dataBase!;
    }
    _dataBase = await _initDB("Expense_tracker");
    return _dataBase!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  FutureOr<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        purpose TEXT,
        amount REAL,
        currencySymbol TEXT,
        isExpense INTEGER,
        date TEXT,
        user_id TEXT,
        is_deleted INTEGER DEFAULT 0,
        updated_at TEXT,
        synced_at TEXT
      )
    ''');
  }

  FutureOr<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS transactions');
      await _createDB(db, newVersion);
      return;
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN user_id TEXT');
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN is_deleted INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE transactions ADD COLUMN updated_at TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN synced_at TEXT');
    }
  }

  // INSERT
  Future<String> insertData(Chartdata data) async {
    final db = await instance.database;
    await db.insert('transactions', data.toMap());
    return data.id!;
  }

  // READ ALL
  Future<List<Chartdata>> getAllData({String? userId}) async {
    final db = await instance.database;
    final where = userId != null ? 'is_deleted = 0 AND user_id = ?' : 'is_deleted = 0';
    final result = await db.query(
      'transactions',
      where: where,
      whereArgs: userId != null ? [userId] : null,
    );
    return result.map((e) => Chartdata.fromMap(e)).toList();
  }

  /// Read data by exact date — excludes soft-deleted records
  Future<List<Chartdata>> searchByDate(String date, {String? userId}) async {
    final db = await instance.database;
    final where = userId != null
        ? 'date = ? AND is_deleted = 0 AND user_id = ?'
        : 'date = ? AND is_deleted = 0';
    final result = await db.query(
      'transactions',
      where: where,
      whereArgs: userId != null ? [date, userId] : [date],
    );
    return result.map((e) => Chartdata.fromMap(e)).toList();
  }

  /// Read data by month (yyyy-MM) — excludes soft-deleted records
  Future<List<Chartdata>> searchByMonth(String month, {String? userId}) async {
    final db = await instance.database;
    final where = userId != null
        ? 'date LIKE ? AND is_deleted = 0 AND user_id = ?'
        : 'date LIKE ? AND is_deleted = 0';
    final result = await db.query(
      'transactions',
      where: where,
      whereArgs: userId != null ? ['$month%', userId] : ['$month%'],
    );
    return result.map((e) => Chartdata.fromMap(e)).toList();
  }

  // UPDATE
  Future<int> updateData(Chartdata data) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  // SOFT DELETE
  Future<int> deleteData(String id) async {
    final db = await instance.database;
    final n = DateTime.now();
    final now =
        '${n.year}-${_pad(n.month)}-${_pad(n.day)} ${_pad(n.hour)}:${_pad(n.minute)}:${_pad(n.second)}';
    return await db.update(
      'transactions',
      {'is_deleted': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  // ── Sync Helpers ──────────────────────────────────────────────────────────

  Future<List<Chartdata>> getModifiedSince(String since, {String? userId}) async {
    final db = await instance.database;
    final where = userId != null
        ? '(updated_at > ? OR synced_at IS NULL) AND user_id = ?'
        : 'updated_at > ? OR synced_at IS NULL';
    final result = await db.query(
      'transactions',
      where: where,
      whereArgs: userId != null ? [since, userId] : [since],
    );
    return result.map((e) => Chartdata.fromMap(e)).toList();
  }

  Future<void> markSynced(List<String> ids, String syncedAt) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        'transactions',
        {'synced_at': syncedAt},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  // HARD DELETE BY ID
  Future<int> hardDelete(String id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // HARD DELETE: clean up soft-deleted records after sync confirmed
  Future<int> purgeDeleted() async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'is_deleted = 1 AND synced_at IS NOT NULL',
    );
  }

  /// Upsert a record from the server.
  /// Preserves the local [currencySymbol] if the server sends an empty string,
  /// since the server does not store currency symbols.
  Future<void> upsertFromServer(Chartdata data) async {
    final db = await instance.database;
    final existing = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [data.id],
    );
    if (existing.isNotEmpty) {
      final map = Map<String, dynamic>.from(data.toMap());
      // Keep the locally-stored symbol if the incoming one is empty
      final incomingSymbol = (map['currencySymbol'] as String? ?? '').trim();
      if (incomingSymbol.isEmpty) {
        map['currencySymbol'] = existing.first['currencySymbol'] ?? '';
      }
      await db.update(
        'transactions',
        map,
        where: 'id = ?',
        whereArgs: [data.id],
      );
    } else {
      await db.insert('transactions', data.toMap());
    }
  }

  // CLEAR ALL DATA ON LOGOUT
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('transactions');
  }
}
