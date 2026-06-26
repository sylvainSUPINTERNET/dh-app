import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/quran_repository.dart';
import '../models/quran_surah.dart';

const firstSurahNumber = 1;
const lastSurahNumber = 114;

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository();
});

final quranReaderProvider =
    StateNotifierProvider<QuranReaderController, QuranReaderState>((ref) {
      return QuranReaderController(ref.watch(quranRepositoryProvider));
    });

final quranAudioProvider =
    StateNotifierProvider<QuranAudioController, QuranAudioState>((ref) {
      return QuranAudioController();
    });

class QuranReaderState {
  final List<QuranSurah> surahs;
  final Set<int> loadingSurahs;
  final String? errorMessage;
  final bool hasReachedEnd;

  const QuranReaderState({
    this.surahs = const [],
    this.loadingSurahs = const {},
    this.errorMessage,
    this.hasReachedEnd = false,
  });

  int get nextSurahNumber {
    if (surahs.isEmpty) return firstSurahNumber;
    return surahs.last.number + 1;
  }

  QuranReaderState copyWith({
    List<QuranSurah>? surahs,
    Set<int>? loadingSurahs,
    String? errorMessage,
    bool clearError = false,
    bool? hasReachedEnd,
  }) {
    return QuranReaderState(
      surahs: surahs ?? this.surahs,
      loadingSurahs: loadingSurahs ?? this.loadingSurahs,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    );
  }
}

class QuranReaderController extends StateNotifier<QuranReaderState> {
  QuranReaderController(this._repository) : super(const QuranReaderState()) {
    unawaited(loadNextSurah());
  }

  final QuranRepository _repository;

  Future<void> loadNextSurah() async {
    final surahNumber = state.nextSurahNumber;
    if (surahNumber > lastSurahNumber) {
      state = state.copyWith(hasReachedEnd: true);
      return;
    }

    await loadSurah(surahNumber);
  }

  Future<void> preloadNextSurah() async {
    final surahNumber = state.nextSurahNumber;
    final shouldPreload =
        surahNumber <= lastSurahNumber &&
        !state.loadingSurahs.contains(surahNumber);

    if (shouldPreload) {
      await loadSurah(surahNumber);
    }
  }

  Future<void> loadSurah(int surahNumber) async {
    if (state.surahs.any((surah) => surah.number == surahNumber) ||
        state.loadingSurahs.contains(surahNumber)) {
      return;
    }

    state = state.copyWith(
      loadingSurahs: {...state.loadingSurahs, surahNumber},
      clearError: true,
    );

    try {
      final surah = await _repository.fetchSurah(surahNumber);
      final surahs = [...state.surahs, surah]
        ..sort((left, right) => left.number.compareTo(right.number));

      state = state.copyWith(
        surahs: surahs,
        loadingSurahs: {...state.loadingSurahs}..remove(surahNumber),
        hasReachedEnd: surahNumber >= lastSurahNumber,
      );
    } catch (error) {
      state = state.copyWith(
        loadingSurahs: {...state.loadingSurahs}..remove(surahNumber),
        errorMessage: error.toString(),
      );
    }
  }
}

enum QuranAudioStatus { idle, loading, playing, paused, completed }

class QuranAudioState {
  final String? verseKey;
  final QuranAudioStatus status;
  final bool autoPlay;
  final Duration position;
  final Duration duration;
  final int completionId;

  const QuranAudioState({
    this.verseKey,
    this.status = QuranAudioStatus.idle,
    this.autoPlay = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.completionId = 0,
  });

  bool isCurrentVerse(String key) => verseKey == key;

  QuranAudioState copyWith({
    String? verseKey,
    bool clearVerse = false,
    QuranAudioStatus? status,
    bool? autoPlay,
    Duration? position,
    Duration? duration,
    int? completionId,
  }) {
    return QuranAudioState(
      verseKey: clearVerse ? null : verseKey ?? this.verseKey,
      status: status ?? this.status,
      autoPlay: autoPlay ?? this.autoPlay,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      completionId: completionId ?? this.completionId,
    );
  }
}

class QuranAudioController extends StateNotifier<QuranAudioState> {
  QuranAudioController() : super(const QuranAudioState()) {
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(
          status: QuranAudioStatus.completed,
          position: state.duration,
          completionId: state.completionId + 1,
        );
        return;
      }

      if (state.verseKey == null) return;

      if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        state = state.copyWith(status: QuranAudioStatus.loading);
      } else if (playerState.playing) {
        state = state.copyWith(status: QuranAudioStatus.playing);
      } else {
        state = state.copyWith(status: QuranAudioStatus.paused);
      }
    });
    _positionSubscription = _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });
    _durationSubscription = _player.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });
  }

  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;

  void setAutoPlay(bool isEnabled) {
    state = state.copyWith(autoPlay: isEnabled);
  }

  Future<void> toggleVerse(Verse verse) async {
    final key = verse.audioKey;
    if (state.verseKey == key) {
      if (_player.playing) {
        await _player.pause();
      } else if (state.status == QuranAudioStatus.completed) {
        await _player.seek(Duration.zero);
        await _player.play();
      } else {
        await _player.play();
      }
      return;
    }

    state = state.copyWith(
      verseKey: key,
      status: QuranAudioStatus.loading,
      position: Duration.zero,
      duration: Duration.zero,
    );
    await _player.stop();
    await _player.setUrl(verse.audioUrl);
    await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    state = state.copyWith(position: position);
  }

  @override
  void dispose() {
    unawaited(_playerStateSubscription.cancel());
    unawaited(_positionSubscription.cancel());
    unawaited(_durationSubscription.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
