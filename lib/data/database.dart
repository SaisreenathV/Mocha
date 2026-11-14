import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DataClassName('Track')
class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text().unique()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  BoolColumn get isSound => boolean().withDefault(const Constant(false))();
  BoolColumn get isLiked => boolean().withDefault(const Constant(false))();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ItemLoopConfigData')
class ItemLoopConfigs extends Table {
  TextColumn get itemId => text()();
  TextColumn get mode => text()();
  IntColumn get count => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get abStartMs => integer().nullable()();
  IntColumn get abEndMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};
}

@DataClassName('MixData')
class Mixes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get noisePreset => text()();
  RealColumn get noiseVolume => real().withDefault(const Constant(0.8))();
  TextColumn get trackId => text().nullable()();
  RealColumn get trackVolume => real().withDefault(const Constant(0.8))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SavedMix')
class SavedMixes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get noiseParamsJson => text()();
  RealColumn get noiseVolume => real().withDefault(const Constant(0.8))();
  TextColumn get soundsJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EqSettings')
class EqSettingsTable extends Table {
  TextColumn get id => text().withDefault(const Constant('global_eq'))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get presetName => text().withDefault(const Constant('Flat'))();
  TextColumn get bandsJson => text()();
  RealColumn get crossfadeSeconds => real().withDefault(const Constant(3.0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ListeningSession')
class ListeningSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text().nullable()();
  TextColumn get title => text()();
  BoolColumn get isSound => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  IntColumn get durationSeconds => integer()();
}

class SoundStat {
  final String title;
  final int totalSeconds;
  final int sessionCount;

  const SoundStat({
    required this.title,
    required this.totalSeconds,
    required this.sessionCount,
  });
}

@DriftDatabase(tables: [Tracks, ItemLoopConfigs, Mixes, SavedMixes, EqSettingsTable, ListeningSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(itemLoopConfigs);
      }
      if (from < 3) {
        await m.createTable(mixes);
      }
      if (from < 4) {
        await m.createTable(savedMixes);
      }
      if (from < 5) {
        await m.createTable(eqSettingsTable);
      }
      if (from < 6) {
        await m.createTable(listeningSessions);
      }
    },
  );

  Stream<List<Track>> watchAllTracks({String query = ''}) {
    if (query.trim().isEmpty) {
      return (select(tracks)..orderBy([(t) => OrderingTerm.asc(t.title)])).watch();
    }
    final q = '%${query.trim()}%';
    return (select(tracks)
          ..where((t) => t.title.like(q) | t.artist.like(q) | t.album.like(q))
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .watch();
  }

  Future<int> insertTrackOrIgnore(TracksCompanion track) {
    return into(tracks).insert(track, mode: InsertMode.insertOrIgnore);
  }

  Future<bool> toggleIsSound(String id, bool currentValue) async {
    final rows = await (update(tracks)..where((t) => t.id.equals(id)))
        .write(TracksCompanion(isSound: Value(!currentValue)));
    return rows > 0;
  }

  Future<ItemLoopConfigData?> getLoopConfig(String itemId) {
    return (select(itemLoopConfigs)..where((t) => t.itemId.equals(itemId))).getSingleOrNull();
  }

  Future<int> setLoopConfig(ItemLoopConfigsCompanion config) {
    return into(itemLoopConfigs).insertOnConflictUpdate(config);
  }

  Future<Track?> getTrackById(String id) {
    return (select(tracks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<MixData>> watchAllMixes() {
    return (select(mixes)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Future<int> saveMix(MixesCompanion mix) {
    return into(mixes).insertOnConflictUpdate(mix);
  }

  Future<int> deleteMix(String id) {
    return (delete(mixes)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<SavedMix>> watchAllSavedMixes() {
    return (select(savedMixes)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<SavedMix?> getSavedMixById(String id) {
    return (select(savedMixes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> saveSavedMix(SavedMixesCompanion mix) {
    return into(savedMixes).insertOnConflictUpdate(mix);
  }

  Future<int> deleteSavedMix(String id) {
    return (delete(savedMixes)..where((t) => t.id.equals(id))).go();
  }

  Future<EqSettings?> getEqSettings() {
    return (select(eqSettingsTable)..where((t) => t.id.equals('global_eq'))).getSingleOrNull();
  }

  Future<int> saveEqSettings(EqSettingsTableCompanion settings) {
    return into(eqSettingsTable).insertOnConflictUpdate(settings);
  }

  Future<int> insertListeningSession(ListeningSessionsCompanion session) {
    return into(listeningSessions).insert(session);
  }

  Stream<List<ListeningSession>> watchRecentSessions({int limit = 50}) {
    return (select(listeningSessions)
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
          ..limit(limit))
        .watch();
  }

  Future<int> getTotalSecondsThisWeek() async {
    final now = DateTime.now();
    // Start of current week (Monday at 00:00:00)
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final sessions = await (select(listeningSessions)
          ..where((t) => t.startTime.isBiggerOrEqualValue(startOfWeek)))
        .get();

    return sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  Future<int> getLongestSessionSeconds() async {
    final sessions = await select(listeningSessions).get();
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.durationSeconds).reduce((a, b) => a > b ? a : b);
  }

  Future<int> getCurrentStreakDays() async {
    final sessions = await (select(listeningSessions)
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .get();

    if (sessions.isEmpty) return 0;

    final distinctDays = sessions
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (distinctDays.first != today && distinctDays.first != yesterday) {
      return 0;
    }

    int streak = 1;
    DateTime checkDay = distinctDays.first;

    for (int i = 1; i < distinctDays.length; i++) {
      final prevDay = checkDay.subtract(const Duration(days: 1));
      if (distinctDays[i] == prevDay) {
        streak++;
        checkDay = prevDay;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<List<SoundStat>> getTopSounds({int limit = 5}) async {
    final sessions = await (select(listeningSessions)
          ..where((t) => t.isSound.equals(true)))
        .get();

    final map = <String, List<int>>{};
    for (final s in sessions) {
      map.putIfAbsent(s.title, () => []).add(s.durationSeconds);
    }

    final stats = map.entries.map((e) {
      final totalSec = e.value.reduce((a, b) => a + b);
      return SoundStat(
        title: e.key,
        totalSeconds: totalSec,
        sessionCount: e.value.length,
      );
    }).toList();

    stats.sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));
    return stats.take(limit).toList();
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'mocha.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
