import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../models/quote_history.dart';

const _backendBaseUrl = 'http://10.0.2.2:3000';

// Global map to store all active audio players
final _activePlayers = <String, AudioPlayer>{};

final quotesHistoryProvider =
    FutureProvider.family<List<QuoteHistory>, ({int year, int month})>((
      ref,
      params,
    ) async {
      final year = params.year;
      final month = params.month;

      // Ensure month is zero-padded
      final monthStr = month.toString().padLeft(2, '0');

      final url = '$_backendBaseUrl/quotes-history/$year/$monthStr';

      try {
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          return jsonList
              .map(
                (json) => QuoteHistory.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        } else {
          throw Exception('Failed to fetch quotes history');
        }
      } catch (e) {
        throw Exception('Error fetching quotes history: $e');
      }
    });

// Provider to get current year and month for default display
final currentMonthProvider = Provider<({int year, int month})>((ref) {
  final now = DateTime.now();
  return (year: now.year, month: now.month);
});

// Provider to manage selected display language (fr or en)
final displayLanguageProvider = StateProvider<String>((ref) => 'fr');

// Provider to track which audio is currently playing
final currentPlayingAudioProvider = StateProvider<String?>((ref) => null);

// Audio player state for a specific audio URL
class AudioState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  const AudioState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  AudioState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return AudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioState> {
  final AudioPlayer _player = AudioPlayer();
  final String audioUrl;
  final Ref ref;

  AudioPlayerNotifier(this.audioUrl, this.ref) : super(const AudioState()) {
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Register this player globally
      _activePlayers[audioUrl] = _player;

      await _player.setUrl(audioUrl);

      _player.durationStream.listen((duration) {
        state = state.copyWith(duration: duration ?? Duration.zero);
      });

      _player.positionStream.listen((position) {
        state = state.copyWith(position: position);
      });

      _player.playerStateStream.listen((playerState) {
        state = state.copyWith(isPlaying: playerState.playing);
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  Future<void> togglePlayPause() async {
    try {
      final currentPlaying = ref.read(currentPlayingAudioProvider);

      if (state.isPlaying) {
        // Pause current audio
        await _player.pause();
        if (currentPlaying == audioUrl) {
          ref.read(currentPlayingAudioProvider.notifier).state = null;
        }
      } else {
        // Stop all other players first
        if (currentPlaying != null && currentPlaying != audioUrl) {
          _activePlayers[currentPlaying]?.pause();
        }

        // Update global player state
        ref.read(currentPlayingAudioProvider.notifier).state = audioUrl;

        // Stop and reset position before playing to avoid multiple instances
        try {
          await _player.stop();
        } catch (_) {}

        // Only play if not already playing
        if (!state.isPlaying) {
          await _player.play();
        }
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  @override
  void dispose() {
    _activePlayers.remove(audioUrl);
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerProvider =
    StateNotifierProvider.family<AudioPlayerNotifier, AudioState, String>((
      ref,
      audioUrl,
    ) {
      return AudioPlayerNotifier(audioUrl, ref);
    });
