/// Local database service using sqflite on mobile and in-memory cache on web.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// ── Provider ──────────────────────────────────────────────────────────
final localDatabaseProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseServiceImpl();
});

// ── Interface ────────────────────────────────────────────────────────
abstract class LocalDatabaseService {
  Future<void> init();
  Future<Database?> get database;

  // Customers
  Future<void> saveCustomer(Map<String, dynamic> customer);
  Future<void> updateCustomer(Map<String, dynamic> customer);
  Future<void> deleteCustomer(String id);
  Future<List<Map<String, dynamic>>> getCustomers();
  Future<Map<String, dynamic>?> getCustomerById(String id);

  // Sync Queue
  Future<void> addSyncJob(
    String action,
    String entityType,
    Map<String, dynamic> payload,
  );
  Future<List<Map<String, dynamic>>> getPendingSyncJobs();
  Future<void> updateSyncJobStatus(int id, String status);
  Future<void> removeSyncJob(int id);
}

// ── Implementation ───────────────────────────────────────────────────
class LocalDatabaseServiceImpl implements LocalDatabaseService {
  Database? _database;
  final Map<String, Map<String, dynamic>> _webCustomers = {};
  final List<Map<String, dynamic>> _webSyncJobs = [];

  @override
  Future<void> init() async {
    if (kIsWeb) return;
    if (_database != null) return;
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'sidad.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          // Customers table
          await db.execute('''
            CREATE TABLE customers (
              id TEXT PRIMARY KEY,
              user_id TEXT,
              full_name TEXT NOT NULL,
              phone TEXT NOT NULL,
              email TEXT,
              national_id TEXT,
              address TEXT,
              notes TEXT,
              total_debt REAL,
              paid_amount REAL,
              debt_count INTEGER,
              created_at TEXT,
              is_synced INTEGER DEFAULT 1,
              offline_id TEXT
            )
          ''');

          // Sync Queue table
          await db.execute('''
            CREATE TABLE sync_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              action TEXT NOT NULL,
              entity_type TEXT NOT NULL,
              payload TEXT NOT NULL,
              status TEXT DEFAULT 'pending',
              created_at TEXT NOT NULL
            )
          ''');
        },
      );
    } catch (_) {
      // Fallback gracefully if sqflite is unavailable
    }
  }

  @override
  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database == null) await init();
    return _database;
  }

  // ── Customers ──────────────────────────────────────────────────────

  @override
  Future<void> saveCustomer(Map<String, dynamic> customer) async {
    if (kIsWeb) {
      final id = customer['id']?.toString() ?? customer['offline_id']?.toString() ?? '';
      if (id.isNotEmpty) _webCustomers[id] = customer;
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert(
      'customers',
      customer,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCustomer(Map<String, dynamic> customer) async {
    if (kIsWeb) {
      final id = customer['id']?.toString() ?? '';
      if (id.isNotEmpty) _webCustomers[id] = customer;
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.update(
      'customers',
      customer,
      where: 'id = ?',
      whereArgs: [customer['id']],
    );
  }

  @override
  Future<void> deleteCustomer(String id) async {
    if (kIsWeb) {
      _webCustomers.remove(id);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomers() async {
    if (kIsWeb) {
      return _webCustomers.values.toList();
    }
    final db = await database;
    if (db == null) return [];
    return await db.query('customers', orderBy: 'created_at DESC');
  }

  @override
  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    if (kIsWeb) {
      return _webCustomers[id] ?? _webCustomers.values.where((c) => c['offline_id'] == id).firstOrNull;
    }
    final db = await database;
    if (db == null) return null;
    final results = await db.query(
      'customers',
      where: 'id = ? OR offline_id = ?',
      whereArgs: [id, id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // ── Sync Queue ──────────────────────────────────────────────────────

  @override
  Future<void> addSyncJob(
    String action,
    String entityType,
    Map<String, dynamic> payload,
  ) async {
    if (kIsWeb) {
      _webSyncJobs.add({
        'id': _webSyncJobs.length + 1,
        'action': action,
        'entity_type': entityType,
        'payload': jsonEncode(payload),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert('sync_queue', {
      'action': action,
      'entity_type': entityType,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSyncJobs() async {
    if (kIsWeb) {
      return _webSyncJobs.where((j) => j['status'] == 'pending').toList();
    }
    final db = await database;
    if (db == null) return [];
    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  @override
  Future<void> updateSyncJobStatus(int id, String status) async {
    if (kIsWeb) {
      final job = _webSyncJobs.where((j) => j['id'] == id).firstOrNull;
      if (job != null) job['status'] = status;
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.update(
      'sync_queue',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> removeSyncJob(int id) async {
    if (kIsWeb) {
      _webSyncJobs.removeWhere((j) => j['id'] == id);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }
}
