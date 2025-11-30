import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,  // VERSÃO COM sync_queue E pending
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE tasks (
        id $idType,
        title $textType,
        description $textType,
        priority $textType,
        completed $intType,
        createdAt $textType,
        pending INTEGER NOT NULL DEFAULT 0,
        photoPath TEXT,
        completedAt TEXT,
        completedBy TEXT,
        latitude REAL,
        longitude REAL,
        locationName TEXT
      )
    ''');

    // Tabela de fila de sincronização
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL, -- create | update | delete
        taskId INTEGER,       -- id local (may be null for create until inserted)
        payload TEXT NOT NULL, -- JSON payload with task data or {id: ...}
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migração incremental para cada versão
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN photoPath TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN completedAt TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN completedBy TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tasks ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE tasks ADD COLUMN longitude REAL');
      await db.execute('ALTER TABLE tasks ADD COLUMN locationName TEXT');
    }
    if (oldVersion < 5) {
      // add pending flag
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN pending INTEGER NOT NULL DEFAULT 0');
      } catch (_) {
        // ignore if exists
      }

      // create sync_queue if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action TEXT NOT NULL,
          taskId INTEGER,
          payload TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
    }
    print('✅ Banco migrado de v$oldVersion para v$newVersion');
  }

  // CRUD Methods
  Future<Task> create(Task task) async {
    final db = await instance.database;
    // Mark as pending locally and insert
    final taskMap = task.copyWith(pending: true).toMap();
    final id = await db.insert('tasks', taskMap);

    final inserted = task.copyWith(id: id, pending: true);
    // Enfileira para sincronização
    await enqueueSync('create', inserted);

    return inserted;
  }

  Future<Task?> read(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> readAll() async {
    final db = await instance.database;
    const orderBy = 'createdAt DESC';
    final result = await db.query('tasks', orderBy: orderBy);
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> update(Task task) async {
    final db = await instance.database;
    // mark pending and update locally
    final pendingMap = task.copyWith(pending: true).toMap();
    final rows = await db.update(
      'tasks',
      pendingMap,
      where: 'id = ?',
      whereArgs: [task.id],
    );

    // enqueue sync
    await enqueueSync('update', task.copyWith(pending: true));
    return rows;
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    // enqueue delete action so server can be informed
    final payload = jsonEncode({'id': id});
    await db.insert('sync_queue', {
      'action': 'delete',
      'taskId': id,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // remove locally
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Enqueue helper
  Future<void> enqueueSync(String action, Task task) async {
    final db = await instance.database;
    final payload = jsonEncode(task.toMap());
    await db.insert('sync_queue', {
      'action': action,
      'taskId': task.id,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Read queued sync entries (small helper for sync worker)
  Future<List<Map<String, dynamic>>> readSyncQueue() async {
    final db = await instance.database;
    return await db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  Future<int> removeSyncEntry(int id) async {
    final db = await instance.database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // Método especial: buscar tarefas por proximidade
  Future<List<Task>> getTasksNearLocation({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  }) async {
    final allTasks = await readAll();
    
    return allTasks.where((task) {
      if (!task.hasLocation) return false;
      
      // Cálculo de distância usando fórmula de Haversine (simplificada)
      final latDiff = (task.latitude! - latitude).abs();
      final lonDiff = (task.longitude! - longitude).abs();
      final distance = ((latDiff * 111000) + (lonDiff * 111000)) / 2;
      
      return distance <= radiusInMeters;
    }).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}