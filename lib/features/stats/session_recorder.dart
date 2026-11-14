import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../noise/noise_controller.dart';
import '../player/player_controller.dart';

class SessionRecorder {
  final AppDatabase _db;
  final Ref _ref;

  DateTime? _sessionStart;
  String? _sessionTitle;
  String? _trackId;
  bool _isSound = false;

  SessionRecorder(this._db, this._ref) {
    _initListeners();
  }

  void _initListeners() {
    // Listen to PlayerController
    _ref.listen<PlayerState>(playerControllerProvider, (prev, next) {
      if (next.isPlaying && (prev == null || !prev.isPlaying)) {
        final track = next.currentTrack;
        if (track != null) {
          _onPlaybackStarted(
            title: track.title,
            isSound: track.isSound,
            trackId: track.id,
          );
        }
      } else if (!next.isPlaying && prev?.isPlaying == true) {
        // If noise is also not playing, record session
        final noisePlaying = _ref.read(noiseControllerProvider).isPlaying;
        if (!noisePlaying) {
          _onPlaybackStopped();
        }
      }
    });

    // Listen to NoiseController
    _ref.listen<NoiseState>(noiseControllerProvider, (prev, next) {
      if (next.isPlaying && (prev == null || !prev.isPlaying)) {
        final playerPlaying = _ref.read(playerControllerProvider).isPlaying;
        if (!playerPlaying) {
          _onPlaybackStarted(
            title: 'Brown Noise - ${next.selectedPresetName}',
            isSound: true,
            trackId: null,
          );
        }
      } else if (!next.isPlaying && prev?.isPlaying == true) {
        final playerPlaying = _ref.read(playerControllerProvider).isPlaying;
        if (!playerPlaying) {
          _onPlaybackStopped();
        }
      }
    });
  }

  void _onPlaybackStarted({
    required String title,
    required bool isSound,
    String? trackId,
  }) {
    _sessionStart = DateTime.now();
    _sessionTitle = title;
    _isSound = isSound;
    _trackId = trackId;
  }

  Future<void> _onPlaybackStopped() async {
    final start = _sessionStart;
    final title = _sessionTitle;
    if (start == null || title == null) return;

    final end = DateTime.now();
    final durationSeconds = end.difference(start).inSeconds;

    // Minimum 5 seconds to count as a session
    if (durationSeconds >= 5) {
      await _db.insertListeningSession(ListeningSessionsCompanion(
        trackId: Value(_trackId),
        title: Value(title),
        isSound: Value(_isSound),
        startTime: Value(start),
        endTime: Value(end),
        durationSeconds: Value(durationSeconds),
      ));
    }

    _sessionStart = null;
    _sessionTitle = null;
    _trackId = null;
    _isSound = false;
  }
}

final sessionRecorderProvider = Provider<SessionRecorder>((ref) {
  final db = ref.watch(databaseProvider);
  return SessionRecorder(db, ref);
});
