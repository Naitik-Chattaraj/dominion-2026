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
      version: 3,
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
  isHistorical $boolType,
  isSuppressed $boolType,
  suppressedZoneId TEXT
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
    
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE danger_zones ADD COLUMN isSuppressed INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE danger_zones ADD COLUMN suppressedZoneId TEXT');
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
      // Times Square, NY
      DangerZone(
        id: 'hist_nyc_1',
        latitude: 40.7580,
        longitude: -73.9855,
        radiusMeters: 250.0,
        level: 'amber',
        category: 'Pickpocketing Hotspot',
        description: 'AI Historical Analysis: Elevated petty theft incidents during peak tourist hours.',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        isHistorical: true,
      ),
      // London (Trafalgar Square)
      DangerZone(
        id: 'hist_london_1',
        latitude: 51.5080,
        longitude: -0.1281,
        radiusMeters: 180.0,
        level: 'amber',
        category: 'Late Night Disruptions',
        description: 'AI Historical Analysis: Recurrent public disturbances post-midnight.',
        timestamp: DateTime.now().subtract(const Duration(days: 15)),
        isHistorical: true,
      ),
      // Mumbai (Dharavi Outskirts)
      DangerZone(
        id: 'hist_mumbai_1',
        latitude: 19.0380,
        longitude: 72.8538,
        radiusMeters: 200.0,
        level: 'amber',
        category: 'Hazardous Construction',
        description: 'AI Historical Analysis: Open debris and unbarricaded road works.',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
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
    
    // Return permanent AI historical zones OR user-flagged zones under 6 hours old, if not suppressed
    final maps = await db.query(
      'danger_zones',
      where: '(isHistorical = 1 OR timestamp > ?) AND isSuppressed = 0',
      whereArgs: [sixHoursAgo],
    );
    
    return maps.map((map) => DangerZone.fromMap(map)).toList();
  }

  // Clean up user-flagged zones older than 6 hours (never prune permanent AI historical zones)
  Future<void> deleteExpiredDangerZones() async {
    final db = await instance.database;
    final sixHoursAgo = DateTime.now().subtract(const Duration(hours: 6)).toIso8601String();
    
    await db.transaction((txn) async {
      final toDelete = await txn.query(
        'danger_zones',
        where: 'isHistorical = 0 AND timestamp <= ?',
        whereArgs: [sixHoursAgo],
      );
      
      for (var zone in toDelete) {
        if (zone['suppressedZoneId'] != null) {
          await txn.update(
            'danger_zones',
            {'isSuppressed': 0},
            where: 'id = ?',
            whereArgs: [zone['suppressedZoneId']],
          );
        }
      }

      await txn.delete(
        'danger_zones',
        where: 'isHistorical = 0 AND timestamp <= ?',
        whereArgs: [sixHoursAgo],
      );
    });
  }

  // Developer Tool: wipe all non-historical zones
  Future<void> deleteAllUserZones() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final toDelete = await txn.query(
        'danger_zones',
        where: 'isHistorical = 0',
      );
      
      for (var zone in toDelete) {
        if (zone['suppressedZoneId'] != null) {
          await txn.update(
            'danger_zones',
            {'isSuppressed': 0},
            where: 'id = ?',
            whereArgs: [zone['suppressedZoneId']],
          );
        }
      }

      await txn.delete(
        'danger_zones',
        where: 'isHistorical = 0',
      );
    });
  }

  // Elevate a suspicious zone to danger (suspicion suppressed, danger enabled)
  Future<void> elevateZoneToDanger({
    required String oldZoneId,
    required DangerZone elevatedZone,
  }) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'danger_zones',
        {'isSuppressed': 1},
        where: 'id = ?',
        whereArgs: [oldZoneId],
      );
      
      final newZoneMap = elevatedZone.toMap();
      newZoneMap['suppressedZoneId'] = oldZoneId;
      
      await txn.insert(
        'danger_zones',
        newZoneMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
