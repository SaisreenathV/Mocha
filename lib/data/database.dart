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

@DriftDatabase(tables: [Tracks, ItemLoopConfigs, Mixes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

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

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'mocha.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
