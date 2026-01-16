
class BibleData {
  final List<BibleVersion> versions;
  final int versionCount;
  final int verseCount;
  final String exportedAt;

  BibleData({
    required this.versions,
    required this.versionCount,
    required this.verseCount,
    required this.exportedAt,
  });

  factory BibleData.fromJson(Map<String, dynamic> json) {
    var list = json['versions'] as List;
    List<BibleVersion> versionsList = list.map((i) => BibleVersion.fromJson(i)).toList();

    return BibleData(
      versions: versionsList,
      versionCount: json['versionCount'] ?? 0,
      verseCount: json['verseCount'] ?? 0,
      exportedAt: json['exportedAt'] ?? '',
    );
  }
}

class BibleCopyright {
  final String text;
  final String link;

  BibleCopyright({required this.text, required this.link});

  factory BibleCopyright.fromJson(Map<String, dynamic> json) {
    return BibleCopyright(
      text: json['text'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

class BibleVersion {
  final String id;
  final String uuid;
  final String abbreviation;
  final String name;
  final String language;
  final BibleCopyright? copyright;
  // We will inject verses here after parsing the main array
  List<BibleVerse> verses = []; 

  BibleVersion({
    required this.id,
    required this.uuid,
    required this.abbreviation,
    required this.name,
    required this.language,
    this.copyright,
  });

  factory BibleVersion.fromJson(Map<String, dynamic> json) {
    return BibleVersion(
      id: json['_id'] ?? '',
      uuid: json['uuid'] ?? '',
      abbreviation: json['abbreviation'] ?? '',
      name: json['name'] ?? '',
      language: json['language'] ?? '',
      copyright: json['copyright'] != null ? BibleCopyright.fromJson(json['copyright']) : null,
    );
  }
}

class BibleVerse {
  final String bibleId; // Maps to BibleVersion.abbreviation usually
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;

  BibleVerse({
    required this.bibleId,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      bibleId: json['bibleId'] ?? '',
      bookId: json['bookId'] ?? '',
      bookName: json['bookName'] ?? '',
      chapter: json['chapter'] ?? 0,
      verse: json['verse'] ?? 0,
      text: json['text'] ?? '',
    );
  }
}
