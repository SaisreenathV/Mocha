import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import 'importer.dart';

late final AppDatabase globalAppDatabase;

final databaseProvider = Provider<AppDatabase>((ref) {
  return globalAppDatabase;
});

final importerProvider = Provider<TrackImporter>((ref) {
  final db = ref.watch(databaseProvider);
  return TrackImporter(db);
});

final tracksStreamProvider = StreamProvider.family<List<Track>, String>((ref, query) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTracks(query: query);
});
