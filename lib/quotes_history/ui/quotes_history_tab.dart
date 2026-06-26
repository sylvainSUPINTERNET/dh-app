import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../widgets/abstract_background.dart';
import '../models/quote_history.dart';
import '../providers/quotes_history_providers.dart';

class QuotesHistoryTab extends ConsumerStatefulWidget {
  const QuotesHistoryTab({super.key});

  @override
  ConsumerState<QuotesHistoryTab> createState() => _QuotesHistoryTabState();
}

class _QuotesHistoryTabState extends ConsumerState<QuotesHistoryTab> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(
      quotesHistoryProvider((year: _selectedYear, month: _selectedMonth)),
    );

    return AbstractBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HISTORIQUE',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quotes Journalières',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 18),
                    _LanguageSelector(),
                    const SizedBox(height: 12),
                    _MonthYearSelector(
                      year: _selectedYear,
                      month: _selectedMonth,
                      onYearChanged: (year) {
                        setState(() => _selectedYear = year);
                      },
                      onMonthChanged: (month) {
                        setState(() => _selectedMonth = month);
                      },
                    ),
                  ],
                ),
              ),
            ),
            quotesAsync.when(
              data: (quotes) {
                if (quotes.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Aucune quote pour ce mois',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                return SliverList.builder(
                  itemCount: quotes.length,
                  itemBuilder: (context, index) {
                    return _QuoteCard(quote: quotes[index]);
                  },
                );
              },
              loading: () => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (error, stackTrace) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Erreur: ${error.toString()}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(displayLanguageProvider);

    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<String>(
        segments: const <ButtonSegment<String>>[
          ButtonSegment<String>(value: 'fr', label: Text('Français')),
          ButtonSegment<String>(value: 'en', label: Text('English')),
        ],
        selected: <String>{language},
        onSelectionChanged: (Set<String> newSelection) {
          ref.read(displayLanguageProvider.notifier).state = newSelection.first;
        },
      ),
    );
  }
}

class _MonthYearSelector extends StatelessWidget {
  final int year;
  final int month;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;

  const _MonthYearSelector({
    required this.year,
    required this.month,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: month,
            decoration: const InputDecoration(labelText: 'Mois', isDense: true),
            items: List.generate(
              12,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(monthNames[index]),
              ),
            ),
            onChanged: (value) {
              if (value != null) onMonthChanged(value);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: year,
            decoration: const InputDecoration(
              labelText: 'Année',
              isDense: true,
            ),
            items: List.generate(5, (index) {
              final y = DateTime.now().year - 2 + index;
              return DropdownMenuItem(value: y, child: Text(y.toString()));
            }),
            onChanged: (value) {
              if (value != null) onYearChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _QuoteCard extends ConsumerWidget {
  final QuoteHistory quote;

  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(displayLanguageProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thème: ${quote.theme}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sourate ${quote.surah} - Versets ${quote.verses.join(", ")}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...quote.contents.map(
            (content) =>
                _VerseContentDisplay(content: content, language: language),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Ajouté le ${_formatDate(quote.createdAt)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _VerseContentDisplay extends ConsumerWidget {
  final VerseContent content;
  final String language;

  const _VerseContentDisplay({required this.content, required this.language});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider(content.audio));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arabic text (always shown)
        Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              content.textAr,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 22, height: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Translation based on selected language
        if (language == 'fr')
          Text(content.textFr, style: Theme.of(context).textTheme.bodyLarge)
        else
          Text(content.textEn, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        // Audio player
        if (content.audio.isNotEmpty)
          _AudioPlayerWidget(audioState: audioState, audioUrl: content.audio),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _AudioPlayerWidget extends ConsumerWidget {
  final dynamic audioState;
  final String audioUrl;

  const _AudioPlayerWidget({required this.audioState, required this.audioUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = audioState as AudioState;
    final duration = state.duration;
    final position = state.position > duration ? duration : state.position;
    final durationMs = duration.inMilliseconds;
    final positionMs = position.inMilliseconds.clamp(0, durationMs);
    final canSeek = durationMs > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: state.isPlaying ? 'Pause' : 'Play',
                onPressed: () {
                  ref
                      .read(audioPlayerProvider(audioUrl).notifier)
                      .togglePlayPause();
                },
                icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: canSeek ? positionMs.toDouble() : 0,
                  max: canSeek ? durationMs.toDouble() : 1,
                  onChanged: canSeek
                      ? (value) {
                          ref
                              .read(audioPlayerProvider(audioUrl).notifier)
                              .seek(Duration(milliseconds: value.round()));
                        }
                      : null,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  _formatDuration(position),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const Spacer(),
                Text(
                  _formatDuration(duration),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
