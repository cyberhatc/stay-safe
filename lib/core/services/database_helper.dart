import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:stay_safe/core/constants/app_constants.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.contactsTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        relationship TEXT DEFAULT '',
        isEmergency INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.settingsTable}(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.locationRequestsTable}(
        id TEXT PRIMARY KEY,
        requesterId TEXT NOT NULL,
        requesterName TEXT NOT NULL,
        targetUserId TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        createdAt TEXT NOT NULL,
        respondedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.trackingSessionsTable}(
        id TEXT PRIMARY KEY,
        requesterId TEXT NOT NULL,
        targetUserId TEXT NOT NULL,
        targetUserName TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        endedAt TEXT
      )
    ''');
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
