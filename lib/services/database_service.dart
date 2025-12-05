import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'magtapp.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE saved_pages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          url TEXT UNIQUE,
          title TEXT,
          path TEXT,
          timestamp INTEGER
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Downloads table
    await db.execute('''
      CREATE TABLE downloads(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT,
        name TEXT,
        type TEXT,
        size INTEGER,
        timestamp INTEGER
      )
    ''');

    // History table
    await db.execute('''
      CREATE TABLE history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT,
        title TEXT,
        timestamp INTEGER
      )
    ''');

    // AI Cache table
    await db.execute('''
      CREATE TABLE ai_cache(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE,
        content TEXT,
        timestamp INTEGER
      )
    ''');

    // Saved Pages table
    await db.execute('''
      CREATE TABLE saved_pages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT UNIQUE,
        title TEXT,
        path TEXT,
        timestamp INTEGER
      )
    ''');
  }

  // --- Downloads Operations ---
  Future<int> insertDownload(Map<String, dynamic> download) async {
    final db = await database;
    return await db.insert('downloads', download);
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    final db = await database;
    return await db.query('downloads', orderBy: 'timestamp DESC');
  }

  Future<int> deleteDownload(int id) async {
    final db = await database;
    return await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  // --- History Operations ---
  Future<int> insertHistory(Map<String, dynamic> history) async {
    final db = await database;
    return await db.insert('history', history);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    return await db.query('history', orderBy: 'timestamp DESC');
  }

  Future<int> deleteHistory(int id) async {
    final db = await database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearHistory() async {
    final db = await database;
    return await db.delete('history');
  }

  // --- Saved Pages Operations ---
  Future<int> insertSavedPage(Map<String, dynamic> page) async {
    final db = await database;
    return await db.insert(
      'saved_pages',
      page,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSavedPages() async {
    final db = await database;
    return await db.query('saved_pages', orderBy: 'timestamp DESC');
  }

  Future<int> deleteSavedPage(int id) async {
    final db = await database;
    return await db.delete('saved_pages', where: 'id = ?', whereArgs: [id]);
  }

  // --- AI Cache Operations ---
  Future<int> insertAICache(String key, String content) async {
    final db = await database;
    return await db.insert('ai_cache', {
      'key': key,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getAICache(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_cache',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['content'] as String;
    }
    return null;
  }
}
