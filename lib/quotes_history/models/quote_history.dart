class QuoteHistory {
  final String id;
  final String theme;
  final int surah;
  final List<int> verses;
  final List<VerseContent> contents;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuoteHistory({
    required this.id,
    required this.theme,
    required this.surah,
    required this.verses,
    required this.contents,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuoteHistory.fromJson(Map<String, dynamic> json) {
    return QuoteHistory(
      id: json['_id'] as String,
      theme: json['theme'] as String,
      surah: json['surah'] as int,
      verses: List<int>.from(json['verses'] as List),
      contents: (json['contents'] as List)
          .map((e) => VerseContent.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'theme': theme,
    'surah': surah,
    'verses': verses,
    'contents': contents.map((e) => e.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class VerseContent {
  final int verseNumber;
  final String textAr;
  final String textFr;
  final String textEn;
  final String audio;

  VerseContent({
    required this.verseNumber,
    required this.textAr,
    required this.textFr,
    required this.textEn,
    required this.audio,
  });

  factory VerseContent.fromJson(Map<String, dynamic> json) {
    return VerseContent(
      verseNumber: json['verseNumber'] as int,
      textAr: json['text_ar'] as String,
      textFr: json['text_fr'] as String,
      textEn: json['text_en'] as String,
      audio: json['audio'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'verseNumber': verseNumber,
    'text_ar': textAr,
    'text_fr': textFr,
    'text_en': textEn,
    'audio': audio,
  };
}
