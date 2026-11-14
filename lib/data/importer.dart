import 'dart:io';
import 'dart:isolate';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';

class _ScannedMetadata {
  final String filePath;
  final String title;
  final String? artist;
  final String? album;
  final int? durationMs;

  _ScannedMetadata({
    required this.filePath,
    required this.title,
    this.artist,
    this.album,
    this.durationMs,
  });
}

List<_ScannedMetadata> _scanMetadataIsolate(List<String> paths) {
  final results = <_ScannedMetadata>[];
  for (final path in paths) {
    final file = File(path);
    String title = p.basenameWithoutExtension(path);
    String? artist;
    String? album;
    int? durationMs;

    try {
      final meta = readMetadata(file, getImage: false);
      if (meta.title != null && meta.title!.trim().isNotEmpty) {
        title = meta.title!.trim();
      }
      if (meta.artist != null && meta.artist!.trim().isNotEmpty) {
        artist = meta.artist!.trim();
      }
      if (meta.album != null && meta.album!.trim().isNotEmpty) {
        album = meta.album!.trim();
      }
      if (meta.duration != null) {
        durationMs = meta.duration!.inMilliseconds;
      }
    } catch (_) {
      // Fallback to filename
    }

    results.add(
      _ScannedMetadata(
        filePath: path,
        title: title,
        artist: artist,
        album: album,
        durationMs: durationMs,
      ),
    );
  }
  return results;
}

class TrackImporter {
  final AppDatabase _db;
  final _uuid = const Uuid();

  TrackImporter(this._db);

  static const supportedExtensions = ['mp3', 'wav', 'flac', 'ogg', 'm4a', 'aac'];

  Future<int> pickAndImportFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );

    if (result == null || result.paths.isEmpty) return 0;
    final validPaths = result.paths.whereType<String>().toList();
    return _processAndInsertPaths(validPaths);
  }

  Future<int> pickAndImportDirectory() async {
    if (!Platform.isLinux) return 0;

    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null) return 0;

    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;

    final filePaths = <String>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase().replaceAll('.', '');
        if (supportedExtensions.contains(ext)) {
          filePaths.add(entity.path);
        }
      }
    }

    return _processAndInsertPaths(filePaths);
  }

  Future<int> _processAndInsertPaths(List<String> rawPaths) async {
    final processedPaths = <String>[];

    // Android: copy cached files into app documents library/
    if (Platform.isAndroid) {
      final docs = await getApplicationDocumentsDirectory();
      final libDir = Directory(p.join(docs.path, 'library'));
      if (!await libDir.exists()) {
        await libDir.create(recursive: true);
      }

      for (final rawPath in rawPaths) {
        final destPath = p.join(libDir.path, p.basename(rawPath));
        if (destPath != rawPath) {
          final file = File(rawPath);
          if (await file.exists()) {
            await file.copy(destPath);
            processedPaths.add(destPath);
          }
        } else {
          processedPaths.add(rawPath);
        }
      }
    } else {
      processedPaths.addAll(rawPaths);
    }

    if (processedPaths.isEmpty) return 0;

    // Scan tags in background isolate
    final scanned = await Isolate.run(() => _scanMetadataIsolate(processedPaths));

    int insertedCount = 0;
    for (final item in scanned) {
      final companion = TracksCompanion(
        id: Value(_uuid.v4()),
        filePath: Value(item.filePath),
        title: Value(item.title),
        artist: Value(item.artist),
        album: Value(item.album),
        durationMs: Value(item.durationMs),
      );
      final id = await _db.insertTrackOrIgnore(companion);
      if (id > 0) insertedCount++;
    }

    return insertedCount;
  }
}
