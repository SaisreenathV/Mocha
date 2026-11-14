import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/audio_engine.dart';
import '../platform/mocha_audio_handler.dart';
import 'providers.dart';

enum PomodoroPhase { idle, work, breakTime }

class VolumeState {
  final double userVolume;
  final double sleepFade;
  final double breakDuck;
  final Duration? sleepTimerRemaining;
  final bool isSleepTimerActive;
  final bool isEndOfTrackSleep;
  final PomodoroPhase pomodoroPhase;
  final Duration? pomodoroRemaining;

  const VolumeState({
    this.userVolume = 1.0,
    this.sleepFade = 1.0,
    this.breakDuck = 1.0,
    this.sleepTimerRemaining,
    this.isSleepTimerActive = false,
    this.isEndOfTrackSleep = false,
    this.pomodoroPhase = PomodoroPhase.idle,
    this.pomodoroRemaining,
  });

  double get finalVolume => (userVolume * sleepFade * breakDuck).clamp(0.0, 1.0);

  VolumeState copyWith({
    double? userVolume,
    double? sleepFade,
    double? breakDuck,
    Duration? sleepTimerRemaining,
    bool? isSleepTimerActive,
    bool? isEndOfTrackSleep,
    PomodoroPhase? pomodoroPhase,
    Duration? pomodoroRemaining,
    bool clearSleepTimer = false,
    bool clearPomodoro = false,
  }) {
    return VolumeState(
      userVolume: userVolume ?? this.userVolume,
      sleepFade: sleepFade ?? this.sleepFade,
      breakDuck: breakDuck ?? this.breakDuck,
      sleepTimerRemaining:
          clearSleepTimer ? null : (sleepTimerRemaining ?? this.sleepTimerRemaining),
      isSleepTimerActive: isSleepTimerActive ?? this.isSleepTimerActive,
      isEndOfTrackSleep: isEndOfTrackSleep ?? this.isEndOfTrackSleep,
      pomodoroPhase: pomodoroPhase ?? this.pomodoroPhase,
      pomodoroRemaining:
          clearPomodoro ? null : (pomodoroRemaining ?? this.pomodoroRemaining),
    );
  }
}

class VolumeController extends StateNotifier<VolumeState> {
  final MochaAudioHandler _audioHandler;
  final AudioEngine _engine;

  Timer? _sleepTimer;
  Timer? _sleepFadeTimer;
  StreamSubscription<Duration>? _endOfTrackSub;
  Timer? _pomodoroTimer;

  VolumeController(this._audioHandler, this._engine) : super(const VolumeState());

  void _applyVolume() {
    _audioHandler.setVolume(state.finalVolume);
  }

  void setUserVolume(double volume) {
    state = state.copyWith(userVolume: volume.clamp(0.0, 1.0));
    _applyVolume();
  }

  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    state = state.copyWith(
      isSleepTimerActive: true,
      isEndOfTrackSleep: false,
      sleepTimerRemaining: duration,
      sleepFade: 1.0,
    );

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final rem = state.sleepTimerRemaining;
      if (rem == null || rem <= const Duration(seconds: 1)) {
        timer.cancel();
        _finishSleepTimer();
      } else {
        final next = rem - const Duration(seconds: 1);
        if (next <= const Duration(seconds: 30)) {
          final fade = (next.inMilliseconds / 30000.0).clamp(0.0, 1.0);
          state = state.copyWith(sleepTimerRemaining: next, sleepFade: fade);
          _applyVolume();
        } else {
          state = state.copyWith(sleepTimerRemaining: next);
        }
      }
    });
  }

  void startEndOfTrackSleepTimer() {
    cancelSleepTimer();
    state = state.copyWith(
      isSleepTimerActive: true,
      isEndOfTrackSleep: true,
      sleepFade: 1.0,
    );

    _endOfTrackSub = _engine.filePositionStream.listen((pos) {
      final dur = _engine.fileDuration;
      if (dur > Duration.zero) {
        final rem = dur - pos;
        if (rem <= const Duration(seconds: 30) && rem > Duration.zero) {
          final fade = (rem.inMilliseconds / 30000.0).clamp(0.0, 1.0);
          state = state.copyWith(sleepTimerRemaining: rem, sleepFade: fade);
          _applyVolume();
        } else if (rem <= Duration.zero) {
          _finishSleepTimer();
        }
      }
    });
  }

  void _finishSleepTimer() async {
    cancelSleepTimer();
    await _audioHandler.pause();
    state = state.copyWith(sleepFade: 1.0);
    _applyVolume();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepFadeTimer?.cancel();
    _endOfTrackSub?.cancel();
    _sleepTimer = null;
    _sleepFadeTimer = null;
    _endOfTrackSub = null;
    state = state.copyWith(
      isSleepTimerActive: false,
      isEndOfTrackSleep: false,
      sleepFade: 1.0,
      clearSleepTimer: true,
    );
    _applyVolume();
  }

  void startPomodoro() {
    stopPomodoro();
    state = state.copyWith(
      pomodoroPhase: PomodoroPhase.work,
      pomodoroRemaining: const Duration(minutes: 25),
      breakDuck: 1.0,
    );
    _applyVolume();

    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final rem = state.pomodoroRemaining;
      if (rem == null || rem <= const Duration(seconds: 1)) {
        if (state.pomodoroPhase == PomodoroPhase.work) {
          state = state.copyWith(
            pomodoroPhase: PomodoroPhase.breakTime,
            pomodoroRemaining: const Duration(minutes: 5),
            breakDuck: 0.15,
          );
        } else {
          state = state.copyWith(
            pomodoroPhase: PomodoroPhase.work,
            pomodoroRemaining: const Duration(minutes: 25),
            breakDuck: 1.0,
          );
        }
        _applyVolume();
      } else {
        state = state.copyWith(
          pomodoroRemaining: rem - const Duration(seconds: 1),
        );
      }
    });
  }

  void stopPomodoro() {
    _pomodoroTimer?.cancel();
    _pomodoroTimer = null;
    state = state.copyWith(
      pomodoroPhase: PomodoroPhase.idle,
      breakDuck: 1.0,
      clearPomodoro: true,
    );
    _applyVolume();
  }

  @override
  void dispose() {
    cancelSleepTimer();
    _pomodoroTimer?.cancel();
    super.dispose();
  }
}

final volumeControllerProvider =
    StateNotifierProvider<VolumeController, VolumeState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  final engine = ref.watch(audioEngineProvider);
  return VolumeController(handler, engine);
});
