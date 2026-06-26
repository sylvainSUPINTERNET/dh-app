import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_dhikr/main.dart';
import 'package:my_dhikr/quran/data/quran_repository.dart';
import 'package:my_dhikr/quran/models/quran_surah.dart';
import 'package:my_dhikr/quran/providers/quran_providers.dart';

void main() {
  testWidgets('shows bottom navigation and opens Quran tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quranRepositoryProvider.overrideWith((ref) => _FakeQuranRepository()),
        ],
        child: const MyApp(data: {'quote': 'سبحان الله', 'source': 'Dhikr'}),
      ),
    );

    expect(find.text('Dhikr'), findsWidgets);
    expect(find.text('Rappels'), findsOneWidget);
    expect(find.text('Quran'), findsOneWidget);

    await tester.tap(find.text('Quran'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Lecture'), findsOneWidget);
    expect(find.text('1. Al-Faatiha'), findsOneWidget);
    expect(find.text('Au nom d’Allah'), findsOneWidget);
    expect(find.text('In the name of Allah'), findsOneWidget);
  });
}

class _FakeQuranRepository extends QuranRepository {
  @override
  Future<QuranSurah> fetchSurah(int surahNumber) async {
    return const QuranSurah(
      number: 1,
      name: 'الفاتحة',
      englishName: 'Al-Faatiha',
      revelationType: 'Meccan',
      verses: [
        Verse(
          surahNumber: 1,
          verseNumber: 1,
          arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          french: 'Au nom d’Allah',
          english: 'In the name of Allah',
          audioUrl: 'https://example.com/001001.mp3',
        ),
      ],
    );
  }
}
