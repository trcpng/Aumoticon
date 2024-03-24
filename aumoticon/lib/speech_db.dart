import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SpeechDBHelper {
  static Database? _database;

  static Future<Database?> get SERdatabase async {
    if (_database != null) {
      return _database;
    }

    _database = await initDatabase();
    return _database;
  }

  static Future<Database> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'speech_recognition_database.db');
    print('Speech Database path: $path');

    Database database = await openDatabase(path, version: 1, onCreate: _createTable);
  print('Speech Database created');

    return database;
  }

  static Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS speech_recognition_result (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emotionPrediction TEXT,
        audioPath TEXT,
        captureTime TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<List<Map<String, dynamic>>?> getAllResults() async {
    final Database? db = await SERdatabase;
    return await db?.query('speech_recognition_result');
  }

  static Future<int?> saveResult({
  required String emotionPrediction,
  required String audioPath,
  required DateTime captureTime,
  bool synced = false,
}) async {
  try {
    final db = await SERdatabase;
    final result = await db?.insert('speech_recognition_result', {
      'emotionPrediction': emotionPrediction,
      'audioPath': audioPath,
      'captureTime': captureTime.toIso8601String(),
      'synced': synced ? 1 : 0,
    });

    return result;
  } catch (e) {
    print('Error saving speech recognition result: $e');
    return -1;
  }
}

  static Future<List<String>> getSavedEmotions() async {
    final Database? db = await SERdatabase;
    List<Map<String, dynamic>> results = await db?.query('speech_recognition_result') ?? [];
    return results.map((result) => result['emotionPrediction'] as String).toList();
  }

  static Future<int?> saveEmotion(String emotion) async {
    try {
      final db = await SERdatabase;
      final result = await db?.insert('speech_recognition_result', {
        'emotionPrediction': emotion,
        'synced': 0,
      });

      return result;
    } catch (e) {
      print('Error saving emotion: $e');
      return -1;
    }
  }
}
