import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../widgets/abstract_background.dart';
import '../models/quran_surah.dart';
import '../providers/quran_providers.dart';

class QuranReaderTab extends ConsumerStatefulWidget {
  const QuranReaderTab({super.key});

  @override
  ConsumerState<QuranReaderTab> createState() => _QuranReaderTabState();
}

class _QuranReaderTabState extends ConsumerState<QuranReaderTab> {
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _verseKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels < 1200) {
      ref.read(quranReaderProvider.notifier).preloadNextSurah();
    }
  }

  List<Verse> _loadedVerses(List<QuranSurah> surahs) {
    return [
      for (final surah in surahs)
        for (final verse in surah.verses) verse,
    ];
  }

  Future<void> _playNextVerse(String? currentVerseKey) async {
    if (currentVerseKey == null || !mounted) return;

    var verses = _loadedVerses(ref.read(quranReaderProvider).surahs);
    var currentIndex = verses.indexWhere(
      (verse) => verse.audioKey == currentVerseKey,
    );

    if (currentIndex == -1) return;

    if (currentIndex == verses.length - 1) {
      await ref.read(quranReaderProvider.notifier).loadNextSurah();
      if (!mounted) return;
      verses = _loadedVerses(ref.read(quranReaderProvider).surahs);
      currentIndex = verses.indexWhere(
        (verse) => verse.audioKey == currentVerseKey,
      );
    }

    final nextIndex = currentIndex + 1;
    if (nextIndex >= verses.length) return;

    final nextVerse = verses[nextIndex];
    await ref.read(quranAudioProvider.notifier).toggleVerse(nextVerse);
    if (!mounted) return;
    _scrollToVerse(nextVerse.audioKey);
  }

  void _scrollToVerse(String verseKey) {
    final keyContext = _verseKeys[verseKey]?.currentContext;
    if (keyContext == null) {
      _scrollCloseToVerse(verseKey);
      return;
    }

    _ensureVerseVisible(verseKey);
  }

  void _scrollCloseToVerse(String verseKey) {
    if (!_scrollController.hasClients) return;

    final entryIndex = _entryIndexForVerse(verseKey);
    if (entryIndex == null) return;

    final targetOffset = (170 + entryIndex * 260)
        .clamp(0, _scrollController.position.maxScrollExtent)
        .toDouble();

    _scrollController
        .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        )
        .then((_) => _ensureVerseVisible(verseKey));
  }

  int? _entryIndexForVerse(String verseKey) {
    var index = 0;
    for (final surah in ref.read(quranReaderProvider).surahs) {
      index++;
      for (final verse in surah.verses) {
        if (verse.audioKey == verseKey) {
          return index;
        }
        index++;
      }
    }

    return null;
  }

  void _ensureVerseVisible(String verseKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _verseKeys[verseKey]?.currentContext;
      if (keyContext == null || !mounted) return;

      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.18,
      );
    });
  }

  Future<void> _jumpToVerse(_QuranJumpTarget target) async {
    await ref.read(quranReaderProvider.notifier).loadSurah(target.surahNumber);
    if (!mounted) return;

    final state = ref.read(quranReaderProvider);
    QuranSurah? surah;
    for (final loadedSurah in state.surahs) {
      if (loadedSurah.number == target.surahNumber) {
        surah = loadedSurah;
        break;
      }
    }
    if (surah == null || surah.verses.isEmpty) return;

    final clampedVerseNumber = target.verseNumber.clamp(1, surah.verses.length);
    _scrollToVerse('${target.surahNumber}:$clampedVerseNumber');
  }

  Future<void> _showJumpSheet() async {
    final verseController = TextEditingController(text: '1');

    final target = await showModalBottomSheet<_QuranJumpTarget>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.navigationSurface,
      builder: (context) {
        var selectedSurahNumber = firstSurahNumber;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aller a',
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<int>(
                    initialValue: selectedSurahNumber,
                    decoration: const InputDecoration(labelText: 'Sourate'),
                    items: [
                      for (
                        var surahNumber = firstSurahNumber;
                        surahNumber <= lastSurahNumber;
                        surahNumber++
                      )
                        DropdownMenuItem(
                          value: surahNumber,
                          child: Text('Sourate $surahNumber'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedSurahNumber = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: verseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ayah'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final verseNumber =
                            int.tryParse(verseController.text.trim()) ?? 1;
                        Navigator.of(context).pop(
                          _QuranJumpTarget(
                            surahNumber: selectedSurahNumber,
                            verseNumber: verseNumber,
                          ),
                        );
                      },
                      icon: const Icon(Icons.near_me),
                      label: const Text('Y aller'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    verseController.dispose();
    if (target != null) {
      await _jumpToVerse(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuranAudioState>(quranAudioProvider, (previous, next) {
      if (previous?.completionId == next.completionId || !next.autoPlay) {
        return;
      }

      _playNextVerse(next.verseKey);
    });

    final state = ref.watch(quranReaderProvider);
    final audioState = ref.watch(quranAudioProvider);
    final entries = _QuranListEntry.fromSurahs(state.surahs);

    return AbstractBackground(
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QURAN',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lecture',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 18),
                    _QuranReaderControls(
                      audioState: audioState,
                      onAutoPlayChanged: (isEnabled) {
                        ref
                            .read(quranAudioProvider.notifier)
                            .setAutoPlay(isEnabled);
                      },
                      onJumpPressed: _showJumpSheet,
                      onCurrentPressed: audioState.verseKey == null
                          ? null
                          : () => _scrollToVerse(audioState.verseKey!),
                    ),
                  ],
                ),
              ),
            ),
            if (entries.isEmpty && state.loadingSurahs.isNotEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else
              SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  if (entry.header != null) {
                    return _SurahHeader(surah: entry.header!);
                  }

                  return _VerseTile(
                    key: _verseKeys.putIfAbsent(
                      entry.verse!.audioKey,
                      GlobalKey.new,
                    ),
                    surahNumber: entry.surahNumber,
                    verse: entry.verse!,
                  );
                },
              ),
            SliverToBoxAdapter(
              child: _QuranListFooter(
                isLoading: state.loadingSurahs.isNotEmpty,
                errorMessage: state.errorMessage,
                hasReachedEnd: state.hasReachedEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranJumpTarget {
  final int surahNumber;
  final int verseNumber;

  const _QuranJumpTarget({
    required this.surahNumber,
    required this.verseNumber,
  });
}

class _QuranReaderControls extends StatelessWidget {
  final QuranAudioState audioState;
  final ValueChanged<bool> onAutoPlayChanged;
  final VoidCallback onJumpPressed;
  final VoidCallback? onCurrentPressed;

  const _QuranReaderControls({
    required this.audioState,
    required this.onAutoPlayChanged,
    required this.onJumpPressed,
    required this.onCurrentPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilterChip(
          selected: audioState.autoPlay,
          onSelected: onAutoPlayChanged,
          avatar: Icon(
            audioState.autoPlay ? Icons.repeat_on : Icons.repeat,
            size: 18,
          ),
          label: const Text('Auto'),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Aller a une ayah',
          onPressed: onJumpPressed,
          icon: const Icon(Icons.near_me_outlined),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Revenir au verset en cours',
          onPressed: onCurrentPressed,
          icon: const Icon(Icons.my_location),
        ),
      ],
    );
  }
}

class _QuranListEntry {
  final QuranSurah? header;
  final int surahNumber;
  final Verse? verse;

  _QuranListEntry.header(QuranSurah surah)
    : header = surah,
      surahNumber = surah.number,
      verse = null;

  _QuranListEntry.verse({required this.surahNumber, required this.verse})
    : header = null;

  static List<_QuranListEntry> fromSurahs(List<QuranSurah> surahs) {
    return [
      for (final surah in surahs) ...[
        _QuranListEntry.header(surah),
        for (final verse in surah.verses)
          _QuranListEntry.verse(surahNumber: surah.number, verse: verse),
      ],
    ];
  }
}

class _SurahHeader extends StatelessWidget {
  final QuranSurah surah;

  const _SurahHeader({required this.surah});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${surah.number}. ${surah.englishName}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  surah.revelationType.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            surah.name,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 24,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseTile extends ConsumerWidget {
  final int surahNumber;
  final Verse verse;

  const _VerseTile({super.key, required this.surahNumber, required this.verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(quranAudioProvider);
    final verseKey = verse.audioKey;
    final isCurrentVerse = audioState.isCurrentVerse(verseKey);
    final isLoading =
        isCurrentVerse && audioState.status == QuranAudioStatus.loading;
    final isPlaying =
        isCurrentVerse && audioState.status == QuranAudioStatus.playing;
    final isCompleted =
        isCurrentVerse && audioState.status == QuranAudioStatus.completed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$surahNumber:${verse.verseNumber}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: isPlaying ? 'Pause' : 'Play',
                onPressed: verse.audioUrl.isEmpty
                    ? null
                    : () {
                        ref
                            .read(quranAudioProvider.notifier)
                            .toggleVerse(verse);
                      },
                icon: isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause
                            : isCompleted
                            ? Icons.replay
                            : Icons.play_arrow,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                verse.arabic,
                textAlign: TextAlign.right,
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontSize: 26, height: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(verse.french, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 10),
          Text(verse.english, style: Theme.of(context).textTheme.bodyMedium),
          if (isCurrentVerse) ...[
            const SizedBox(height: 16),
            _VersePlaybackControls(audioState: audioState),
          ],
        ],
      ),
    );
  }
}

class _VersePlaybackControls extends ConsumerWidget {
  final QuranAudioState audioState;

  const _VersePlaybackControls({required this.audioState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = audioState.duration;
    final position = audioState.position > duration
        ? duration
        : audioState.position;
    final durationMs = duration.inMilliseconds;
    final positionMs = position.inMilliseconds.clamp(0, durationMs);
    final canSeek = durationMs > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: canSeek ? positionMs.toDouble() : 0,
          max: canSeek ? durationMs.toDouble() : 1,
          onChanged: canSeek
              ? (value) {
                  ref
                      .read(quranAudioProvider.notifier)
                      .seek(Duration(milliseconds: value.round()));
                }
              : null,
        ),
        Row(
          children: [
            Text(
              _formatDuration(position),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const Spacer(),
            Text(
              _statusLabel(audioState.status),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const Spacer(),
            Text(
              _formatDuration(duration),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  String _statusLabel(QuranAudioStatus status) {
    return switch (status) {
      QuranAudioStatus.loading => 'BUFFER',
      QuranAudioStatus.playing => 'LECTURE',
      QuranAudioStatus.paused => 'PAUSE',
      QuranAudioStatus.completed => 'TERMINE',
      QuranAudioStatus.idle => 'PRET',
    };
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _QuranListFooter extends ConsumerWidget {
  final bool isLoading;
  final String? errorMessage;
  final bool hasReachedEnd;

  const _QuranListFooter({
    required this.isLoading,
    required this.errorMessage,
    required this.hasReachedEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        child: OutlinedButton.icon(
          onPressed: () {
            ref.read(quranReaderProvider.notifier).loadNextSurah();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Reessayer'),
        ),
      );
    }

    if (hasReachedEnd) {
      return const SizedBox(height: 32);
    }

    if (!isLoading) {
      return const SizedBox(height: 24);
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }
}
