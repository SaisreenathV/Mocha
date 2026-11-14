import 'dart:io';

class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  @override
  String toString() => '[${timestamp.inMilliseconds}ms] $text';
}

class LrcDocument {
  final String? title;
  final String? artist;
  final String? album;
  final int offsetMs;
  final List<LyricLine> lines;

  const LrcDocument({
    this.title,
    this.artist,
    this.album,
    this.offsetMs = 0,
    required this.lines,
  });

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  /// Returns the index of the line that should be active at [position].
  /// Returns -1 if position is before the first lyric line.
  int getActiveIndex(Duration position) {
    if (lines.isEmpty || position < lines.first.timestamp) {
      return -1;
    }

    int low = 0;
    int high = lines.length - 1;
    int result = 0;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (lines[mid].timestamp <= position) {
        result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return result;
  }
}

class LrcParser {
  static final RegExp _tagRegex = RegExp(r'^\[([a-zA-Z]+):([^\]]*)\]');
  static final RegExp _timeRegex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]');

  /// Parse the raw string content of an LRC file.
  static LrcDocument parse(String content) {
    String? title;
    String? artist;
    String? album;
    int offsetMs = 0;
    final List<LyricLine> parsedLines = [];

    final rawLines = content.split(RegExp(r'\r?\n'));

    for (final line in rawLines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check metadata tag e.g. [ti:Song Title]
      final tagMatch = _tagRegex.firstMatch(trimmed);
      if (tagMatch != null) {
        final key = tagMatch.group(1)!.toLowerCase();
        final value = tagMatch.group(2)!.trim();
        switch (key) {
          case 'ti':
            title = value;
            break;
          case 'ar':
            artist = value;
            break;
          case 'al':
            album = value;
            break;
          case 'offset':
            offsetMs = int.tryParse(value) ?? 0;
            break;
        }
      }

      // Check timestamp tags (may have multiple per line e.g. [01:23.45][02:34.56] Chorus)
      final timeMatches = _timeRegex.allMatches(trimmed).toList();
      if (timeMatches.isNotEmpty) {
        final lastMatch = timeMatches.last;
        final text = trimmed.substring(lastMatch.end).trim();

        for (final match in timeMatches) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final fracStr = match.group(3) ?? '0';
          int millis = 0;
          if (fracStr.length == 1) {
            millis = int.parse(fracStr) * 100;
          } else if (fracStr.length == 2) {
            millis = int.parse(fracStr) * 10;
          } else {
            millis = int.parse(fracStr.padRight(3, '0').substring(0, 3));
          }

          final totalMs = (minutes * 60 * 1000) + (seconds * 1000) + millis;
          parsedLines.add(LyricLine(
            timestamp: Duration(milliseconds: totalMs),
            text: text,
          ));
        }
      }
    }

    // Apply offset if specified
    List<LyricLine> finalLines = parsedLines;
    if (offsetMs != 0) {
      finalLines = parsedLines.map((l) {
        final adjusted = l.timestamp.inMilliseconds + offsetMs;
        return LyricLine(
          timestamp: Duration(milliseconds: adjusted > 0 ? adjusted : 0),
          text: l.text,
        );
      }).toList();
    }

    // Sort chronologically
    finalLines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return LrcDocument(
      title: title,
      artist: artist,
      album: album,
      offsetMs: offsetMs,
      lines: finalLines,
    );
  }

  /// Locate a sidecar .lrc file next to the audio file at [audioFilePath].
  static Future<LrcDocument?> findSidecar(String audioFilePath) async {
    final dotIndex = audioFilePath.lastIndexOf('.');
    if (dotIndex == -1) return null;

    final basePath = audioFilePath.substring(0, dotIndex);
    final candidatePath = '$basePath.lrc';
    final candidateFile = File(candidatePath);

    if (await candidateFile.exists()) {
      final content = await candidateFile.readAsString();
      return parse(content);
    }

    // Also check case-insensitive match in parent directory
    final parentDir = candidateFile.parent;
    if (await parentDir.exists()) {
      final baseName = basePath.split(Platform.pathSeparator).last.toLowerCase();
      try {
        final files = parentDir.listSync();
        for (final entity in files) {
          if (entity is File && entity.path.toLowerCase().endsWith('.lrc')) {
            final entityBase = entity.path
                .substring(0, entity.path.lastIndexOf('.'))
                .split(Platform.pathSeparator)
                .last
                .toLowerCase();
            if (entityBase == baseName) {
              final content = await entity.readAsString();
              return parse(content);
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }
}
