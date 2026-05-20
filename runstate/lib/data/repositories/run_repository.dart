// lib/data/repositories/run_repository.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/run_model.dart';

class RunRepository {
  static const _dbName = 'runstate.db';
  static const _tableName = 'runs';
  static const _version = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            startTime TEXT NOT NULL,
            endTime TEXT NOT NULL,
            distanceKm REAL NOT NULL,
            durationSeconds INTEGER NOT NULL,
            avgPaceMinPerKm REAL NOT NULL,
            route TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> saveRun(RunModel run) async {
    final db = await database;
    await db.insert(
      _tableName,
      run.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RunModel>> getAllRuns() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'startTime DESC',
    );
    return maps.map(RunModel.fromMap).toList();
  }

  Future<void> deleteRun(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as totalRuns,
        COALESCE(SUM(distanceKm), 0) as totalDistance,
        COALESCE(SUM(durationSeconds), 0) as totalDuration,
        COALESCE(AVG(avgPaceMinPerKm), 0) as avgPace
      FROM $_tableName
    ''');
    return result.first;
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) await db.close();
  }
}
