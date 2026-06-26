class Verse {
  final int surahNumber;
  final int verseNumber;
  final String arabic;
  final String french;
  final String english;
  final String audioUrl;

  const Verse({
    required this.surahNumber,
    required this.verseNumber,
    required this.arabic,
    required this.french,
    required this.english,
    required this.audioUrl,
  });

  String get audioKey => '$surahNumber:$verseNumber';
}

class QuranSurah {
  final int number;
  final String name;
  final String englishName;
  final String revelationType;
  final List<Verse> verses;

  const QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.verses,
  });
}
