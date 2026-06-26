import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/quran_surah.dart';

class QuranRepository {
  QuranRepository({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://api.alquran.cloud/v1';
  final http.Client _client;
  final Map<int, QuranSurah> _surahCache = {};
  final Map<int, Future<QuranSurah>> _pendingSurahLoads = {};

  Future<QuranSurah> fetchSurah(int surahNumber) {
    final cachedSurah = _surahCache[surahNumber];
    if (cachedSurah != null) {
      return Future.value(cachedSurah);
    }

    return _pendingSurahLoads.putIfAbsent(surahNumber, () async {
      try {
        final surah = await _loadSurah(surahNumber);
        _surahCache[surahNumber] = surah;
        return surah;
      } finally {
        _pendingSurahLoads.remove(surahNumber);
      }
    });
  }

  Future<QuranSurah> _loadSurah(int surahNumber) async {
    final responses = await Future.wait([
      _getEdition(surahNumber, 'quran-uthmani'),
      _getEdition(surahNumber, 'fr.hamidullah'),
      _getEdition(surahNumber, 'en.sahih'),
      _getEdition(surahNumber, 'ar.alafasy'),
    ]);

    final arabic = responses[0];
    final french = responses[1];
    final english = responses[2];
    final audio = responses[3];

    final arabicAyahs = _ayahsFrom(arabic);
    final frenchAyahs = _ayahsFrom(french);
    final englishAyahs = _ayahsFrom(english);
    final audioAyahs = _ayahsFrom(audio);

    final verses = <Verse>[];
    for (var index = 0; index < arabicAyahs.length; index++) {
      verses.add(
        Verse(
          surahNumber: surahNumber,
          verseNumber: arabicAyahs[index]['numberInSurah'] as int,
          arabic: arabicAyahs[index]['text'] as String? ?? '',
          french: frenchAyahs[index]['text'] as String? ?? '',
          english: englishAyahs[index]['text'] as String? ?? '',
          audioUrl: audioAyahs[index]['audio'] as String? ?? '',
        ),
      );
    }

    final data = arabic['data'] as Map<String, dynamic>;
    return QuranSurah(
      number: data['number'] as int,
      name: data['name'] as String? ?? '',
      englishName: data['englishName'] as String? ?? '',
      revelationType: data['revelationType'] as String? ?? '',
      verses: verses,
    );
  }

  Future<Map<String, dynamic>> _getEdition(
    int surahNumber,
    String edition,
  ) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/surah/$surahNumber/$edition'),
    );

    if (response.statusCode != 200) {
      throw QuranRepositoryException(
        'Failed to load surah $surahNumber ($edition)',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _ayahsFrom(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>;
    final ayahs = data['ayahs'] as List<dynamic>;
    return ayahs.cast<Map<String, dynamic>>();
  }
}

class QuranRepositoryException implements Exception {
  final String message;

  const QuranRepositoryException(this.message);

  @override
  String toString() => message;
}
