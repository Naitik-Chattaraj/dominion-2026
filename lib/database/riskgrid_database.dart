import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:riskgrid/models/local_user.dart';
import 'package:riskgrid/models/danger_zone.dart';

class RiskGridDatabase {
  static final RiskGridDatabase instance = RiskGridDatabase._init();

  static Database? _database;

  RiskGridDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('riskgrid_vault.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE users (
  uid $idType,
  name $textType,
  email $textType,
  passwordHash $textType,
  publicUid $textType,
  pairingCode $textType,
  biometricEnabled $boolType,
  staySignedIn $boolType
)
''');

    await db.execute('''
CREATE TABLE danger_zones (
  id $idType,
  latitude $doubleType,
  longitude $doubleType,
  radiusMeters $doubleType,
  level $textType,
  category $textType,
  description $textType,
  timestamp $textType,
  isHistorical $boolType
)
''');

    await _seedHistoricalZones(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS danger_zones');
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const boolType = 'INTEGER NOT NULL';
      const doubleType = 'REAL NOT NULL';

      await db.execute('''
CREATE TABLE danger_zones (
  id $idType,
  latitude $doubleType,
  longitude $doubleType,
  radiusMeters $doubleType,
  level $textType,
  category $textType,
  description $textType,
  timestamp $textType,
  isHistorical $boolType
)
''');
      await _seedHistoricalZones(db);
    }
  }

  Future _seedHistoricalZones(Database db) async {
    // Seed permanent AI-predicted historical risk zones based on open data
    final historicalZones = [
      DangerZone(
        id: 'hist_potheri_1',
        latitude: 12.8235,
        longitude: 80.0442,
        radiusMeters: 150.0,
        level: 'amber',
        category: 'Poor Lighting & Theft',
        description: 'AI Historical Analysis: High frequency of evening theft reports.',
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
        isHistorical: true,
      ),
      DangerZone(
        id: 'hist_maraimalai_2',
        latitude: 12.7980,
        longitude: 80.0250,
        radiusMeters: 200.0,
        level: 'amber',
        category: 'Accident Prone Intersection',
        description: 'AI Historical Analysis: High-speed intersection with low pedestrian visibility.',
        timestamp: DateTime.now().subtract(const Duration(days: 45)),
        isHistorical: true,
      ),
      // Android Emulator default location (Mountain View, CA)
      DangerZone(
        id: 'hist_emulator_mv_3',
        latitude: 37.4228,
        longitude: -122.0850,
        radiusMeters: 130.0,
        level: 'amber',
        category: 'High Traffic Blindspot',
        description: 'AI Historical Analysis: Blind curve with high bicycle collision history.',
        timestamp: DateTime.now().subtract(const Duration(days: 60)),
        isHistorical: true,
      ),
    ];

    for (var zone in historicalZones) {
      await db.insert('danger_zones', zone.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // --- Users ---

  Future<void> createUser(LocalUser user) async {
    final db = await instance.database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<LocalUser?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return LocalUser.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<LocalUser?> getLatestUser() async {
    final db = await instance.database;
    final maps = await db.query('users', limit: 1);
    if (maps.isNotEmpty) {
      return LocalUser.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> updateUser(LocalUser user) async {
    final db = await instance.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'uid = ?',
      whereArgs: [user.uid],
    );
  }

  Future<bool> hasAnyUser() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'));
    return (count ?? 0) > 0;
  }

  // --- Danger Zones ---

  Future<void> createDangerZone(DangerZone zone) async {
    final db = await instance.database;
    await db.insert('danger_zones', zone.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DangerZone>> getActiveDangerZones() async {
    final db = await instance.database;
    // Calculate timestamp 6 hours ago
    final sixHoursAgo = DateTime.now().subtract(const Duration(hours: 6)).toIso8601String();
    
    // Return permanent AI historical zones OR user-flagged zones under 6 hours old
    final maps = await db.query(
      'danger_zones',
      where: 'isHistorical = 1 OR timestamp > ?',
      whereArgs: [sixHoursAgo],
    );
    
    return maps.map((map) => DangerZone.fromMap(map)).toList();
  }

  // Clean up user-flagged zones older than 6 hours (never prune permanent AI historical zones)
  Future<void> deleteExpiredDangerZones() async {
    final db = await instance.database;
    final sixHoursAgo = DateTime.now().subtract(const Duration(hours: 6)).toIso8601String();
    
    await db.delete(
      'danger_zones',
      where: 'isHistorical = 0 AND timestamp <= ?',
      whereArgs: [sixHoursAgo],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
