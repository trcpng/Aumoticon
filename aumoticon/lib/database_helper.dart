import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static Database? _database;

  static Future<Database?> get database async {
    if (_database != null) {
      return _database;
    }

    _database = await initDatabase();
    return _database;
  }

  static Future<Database> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'classification_database.db');
    print('Database path: $path');

    return openDatabase(path, version: 2, onCreate: _createTable);
  }

  static Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS classification_result (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prediction TEXT,
        imagePath TEXT,
        captureTime TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<List<Map<String, dynamic>>?> getAllResults() async {
    final Database? db = await database;
    return await db?.query('classification_result');
  }

  static Future<int?> saveResult({
    required String prediction,
    required String imagePath,
    required DateTime captureTime,
    bool synced = false,
  }) async {
    try {
      final db = await database;
      final result = await db?.insert('classification_result', {
        'prediction': prediction,
        'imagePath': imagePath,
        'captureTime': captureTime.toIso8601String(),
        'synced': synced ? 1 : 0,
      });

      return result;
    } catch (e) {
      print('Error saving result: $e');
      return -1;
    }
  }
}
