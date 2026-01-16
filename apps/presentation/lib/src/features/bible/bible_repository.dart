
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bible_model.dart';

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository();
});

class BibleRepository {
  BibleData? _cachedData;
  bool _isLoading = false;

  Future<BibleData> loadBibleData() async {
    if (_cachedData != null) return _cachedData!;
    if (_isLoading) {
      // Simple wait loop if already loading
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_cachedData != null) return _cachedData!;
      }
    }

    _isLoading = true;
    try {
      final jsonString = await rootBundle.loadString('assets/bible/full-bible-export.json');
      // usage of compute ensures the UI doesn't freeze while parsing 150MB+ of JSON
      _cachedData = await compute(_parseBibleData, jsonString); 
      // _cachedData = _parseBibleData(jsonString); // Main thread for debugging
      
      debugPrint("--- BIBLE DATA LOADED (Background Isolate) ---");
      debugPrint("Total Versions: ${_cachedData?.versions.length}");
      for (var v in _cachedData?.versions ?? []) {
         debugPrint("Version ${v.abbreviation}: ${v.verses.length} verses");
      }
      debugPrint("-------------------------------");
      
    } catch (e, stack) {
      debugPrint('Error loading bible data: $e');
      debugPrint(stack.toString());
      // Return empty data on error to prevent crashes
      _cachedData = BibleData(versions: [], versionCount: 0, verseCount: 0, exportedAt: '');
    } finally {
      _isLoading = false;
    }
    return _cachedData!;
  }

  // Static function for isolate
  static BibleData _parseBibleData(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    debugPrint("JSON Keys: ${jsonMap.keys.toList()}");
    
    // 1. Parse Metadata & Versions
    final bibleData = BibleData.fromJson(jsonMap);
    
    // 2. Parse Verses (optimizing for speed)
    // The JSON structure has a "verses" (or similar) array at the root? 
    // Wait, let's double check the JSON structure.
    // Based on the `head` command output earlier, the verses seem to be in a separate list or mixed?
    // The output showed:
    // "versionCount": 21,
    // "verseCount": 583722,
    // "versions": [...],
    // And then the `Get-Content ... Select-Object -Skip 300` showed objects like:
    // { "bibleId": "ABTAG", "bookId": "1CH", ... }
    // This implies there is a massive "verses" array at the root level alongside "versions".
    // Let's assume jsonMap['verses'] exists.
    
    List<dynamic>? versesList;
    if (jsonMap.containsKey('verses')) {
       versesList = jsonMap['verses'] as List;
    } else if (jsonMap.containsKey('data')) {
       versesList = jsonMap['data'] as List;
    }
    
    if (versesList != null) {
       debugPrint("Parsed ${versesList.length} verses from JSON.");
       
       final verses = versesList.map((v) => BibleVerse.fromJson(v)).toList();
       
       // 3. Distribute verses to versions
       final versions = bibleData.versions;
       // Logic: verse.bibleId might differ slightly from version.abbreviation (e.g. ABTAG vs ABTAG01)
       // We use a cache to remember the mapping once resolved.
       final Map<String, BibleVersion?> resolvedVersionCache = {};
       
       int matchedCount = 0;
       int unmatchedCount = 0;
       
       for (final verse in verses) {
         final rawKey = verse.bibleId;  // Keep raw for initial check? Or trimmed.
         final key = rawKey.trim();
         
         // Check cache first
         if (resolvedVersionCache.containsKey(key)) {
            final v = resolvedVersionCache[key];
            if (v != null) {
               v.verses.add(verse);
               matchedCount++;
            } else {
               unmatchedCount++;
            }
            continue;
         }
         
         // Resolve Key
         BibleVersion? matchedVersion;
         
         // 1. Exact Match (Abbreviation)
         try {
            matchedVersion = versions.firstWhere((v) => v.abbreviation == key || v.abbreviation == rawKey);
         } catch (_) {}
         
         // 2. Fuzzy Match (Contains/Prefix)
         if (matchedVersion == null) {
            try {
               matchedVersion = versions.firstWhere((v) {
                  final vAbbr = v.abbreviation.trim(); // case sensitive usually fine for IDs
                  // Only match if abbreviations are reasonably long to avoid false positives (e.g. 'A' in 'ABTAG')
                  // But usually 3 chars. 
                  return vAbbr.startsWith(key) || key.startsWith(vAbbr) || vAbbr.contains(key);
               });
            } catch (_) {}
         }
         
         // 3. Last Resort: Name match? (Unlikely for ID)
         
         // Cache result (null or found)
         resolvedVersionCache[key] = matchedVersion;
         
         if (matchedVersion != null) {
            matchedVersion.verses.add(verse);
            matchedCount++;
            // debugPrint("Mapped verse key '$key' to version '${matchedVersion.abbreviation}'"); 
         } else {
            unmatchedCount++;
            if (unmatchedCount < 10) {
               debugPrint("Unmapped verse key: '$key'");
            }
            // If massive unmapped, stop logging
         }
       }
       debugPrint("Matched $matchedCount verses. Unmatched: $unmatchedCount");
    } else {
       debugPrint("CRITICAL: JSON does not contain 'verses' or 'data' key.");
    }
    
    return bibleData;
  }
  
  // Helper methods for UI
  List<BibleVersion> getVersions() {
    return _cachedData?.versions ?? [];
  }
  
  List<String> getBooks(String versionId) {
     final version = _cachedData?.versions.firstWhere((v) => v.id == versionId || v.abbreviation == versionId, orElse: () => BibleVersion(id: '', uuid: '', abbreviation: '', name: '', language: ''));
     if (version == null) return [];
     // Get unique book names/ids. Preserving order is important.
     // We can use a Set to filter duplicates while maintaining order if the list is sorted by book order.
     // Assuming the verses are sorted by canonical order.
     final books = <String>{};
     for (var v in version.verses) {
       books.add(v.bookName); // Using bookName for display. bookId might be better for internal tracking.
     }
     return books.toList();
  }
  
  List<int> getChapters(String versionId, String bookName) {
    final version = _cachedData?.versions.firstWhere((v) => v.id == versionId || v.abbreviation == versionId, orElse: () => BibleVersion(id: '', uuid: '', abbreviation: '', name: '', language: ''));
    if (version == null) return [];
    
    final chapters = <int>{};
    for (var v in version.verses) {
      if (v.bookName == bookName) {
        chapters.add(v.chapter);
      }
    }
    return chapters.toList();
  }
  
  List<BibleVerse> getVerses(String versionId, String bookName, int chapter) {
    final version = _cachedData?.versions.firstWhere((v) => v.id == versionId || v.abbreviation == versionId, orElse: () => BibleVersion(id: '', uuid: '', abbreviation: '', name: '', language: ''));
    if (version == null) return [];
    
    return version.verses.where((v) => v.bookName == bookName && v.chapter == chapter).toList();
  }

  static const Map<String, String> _bookNameToCode = {
    'genesis': 'GEN', 'gen': 'GEN', 'ge': 'GEN', 'gn': 'GEN',
    'exodus': 'EXO', 'ex': 'EXO', 'exo': 'EXO',
    'leviticus': 'LEV', 'lev': 'LEV', 'le': 'LEV',
    'numbers': 'NUM', 'num': 'NUM', 'nu': 'NUM',
    'deuteronomy': 'DEU', 'deut': 'DEU', 'de': 'DEU',
    'joshua': 'JOS', 'josh': 'JOS', 'jos': 'JOS',
    'judges': 'JDG', 'judg': 'JDG', 'jdg': 'JDG',
    'ruth': 'RUT', 'ru': 'RUT', 'rut': 'RUT',
    '1 samuel': '1SA', '1samuel': '1SA', '1 sam': '1SA', '1sam': '1SA', '1 sa': '1SA',
    '2 samuel': '2SA', '2samuel': '2SA', '2 sam': '2SA', '2sam': '2SA', '2 sa': '2SA',
    '1 kings': '1KI', '1kings': '1KI', '1 kgs': '1KI', '1kgs': '1KI', '1ki': '1KI',
    '2 kings': '2KI', '2kings': '2KI', '2 kgs': '2KI', '2kgs': '2KI', '2ki': '2KI',
    '1 chronicles': '1CH', '1chronicles': '1CH', '1 chron': '1CH', '1chron': '1CH', '1 ch': '1CH', '1ch': '1CH',
    '2 chronicles': '2CH', '2chronicles': '2CH', '2 chron': '2CH', '2chron': '2CH', '2 ch': '2CH', '2ch': '2CH',
    'ezra': 'EZR', 'ezr': 'EZR',
    'nehemiah': 'NEH', 'neh': 'NEH', 'ne': 'NEH',
    'esther': 'EST', 'est': 'EST',
    'job': 'JOB',
    'psalms': 'PSA', 'psalm': 'PSA', 'ps': 'PSA', 'psa': 'PSA',
    'proverbs': 'PRO', 'prov': 'PRO', 'pro': 'PRO',
    'ecclesiastes': 'ECC', 'eccl': 'ECC', 'ecc': 'ECC',
    'song of solomon': 'SNG', 'song': 'SNG', 'songs': 'SNG', 'sng': 'SNG', 'sos': 'SNG',
    'isaiah': 'ISA', 'isa': 'ISA',
    'jeremiah': 'JER', 'jer': 'JER',
    'lamentations': 'LAM', 'lam': 'LAM',
    'ezekiel': 'EZK', 'ezek': 'EZK', 'ezk': 'EZK',
    'daniel': 'DAN', 'dan': 'DAN', 'da': 'DAN',
    'hosea': 'HOS', 'hos': 'HOS',
    'joel': 'JOE', 'jol': 'JOE',
    'amos': 'AMO', 'am': 'AMO',
    'obadiah': 'OBA', 'ob': 'OBA', 'oba': 'OBA',
    'jonah': 'JON', 'jon': 'JON',
    'micah': 'MIC', 'mic': 'MIC',
    'nahum': 'NAM', 'nah': 'NAM', 'nam': 'NAM',
    'habakkuk': 'HAB', 'hab': 'HAB',
    'zephaniah': 'ZEP', 'zeph': 'ZEP', 'zep': 'ZEP',
    'haggai': 'HAG', 'hag': 'HAG',
    'zechariah': 'ZEC', 'zech': 'ZEC', 'zec': 'ZEC',
    'malachi': 'MAL', 'mal': 'MAL',
    'matthew': 'MAT', 'matt': 'MAT', 'mt': 'MAT', 'mat': 'MAT',
    'mark': 'MRK', 'mk': 'MRK', 'mrk': 'MRK',
    'luke': 'LUK', 'lk': 'LUK', 'luk': 'LUK',
    'john': 'JHN', 'jn': 'JHN', 'jhn': 'JHN',
    'acts': 'ACT', 'ac': 'ACT', 'act': 'ACT',
    'romans': 'ROM', 'rom': 'ROM', 'ro': 'ROM',
    '1 corinthians': '1CO', '1corinthians': '1CO', '1 cor': '1CO', '1cor': '1CO', '1 co': '1CO', '1co': '1CO',
    '2 corinthians': '2CO', '2corinthians': '2CO', '2 cor': '2CO', '2cor': '2CO', '2 co': '2CO', '2co': '2CO',
    'galatians': 'GAL', 'gal': 'GAL', 'ga': 'GAL',
    'ephesians': 'EPH', 'eph': 'EPH',
    'philippians': 'PHP', 'phil': 'PHP', 'php': 'PHP',
    'colossians': 'COL', 'col': 'COL',
    '1 thessalonians': '1TH', '1thessalonians': '1TH', '1 th': '1TH', '1th': '1TH', '1thess': '1TH',
    '2 thessalonians': '2TH', '2thessalonians': '2TH', '2 th': '2TH', '2th': '2TH', '2thess': '2TH',
    '1 timothy': '1TI', '1timothy': '1TI', '1 tim': '1TI', '1ti': '1TI', '1tim': '1TI',
    '2 timothy': '2TI', '2timothy': '2TI', '2 tim': '2TI', '2ti': '2TI', '2tim': '2TI',
    'titus': 'TIT', 'tit': 'TIT',
    'philemon': 'PHM', 'phm': 'PHM', 'philem': 'PHM',
    'hebrews': 'HEB', 'heb': 'HEB',
    'james': 'JAM', 'jas': 'JAM', 'jam': 'JAM',
    '1 peter': '1PE', '1peter': '1PE', '1 pet': '1PE', '1pe': '1PE', '1pet': '1PE',
    '2 peter': '2PE', '2peter': '2PE', '2 pet': '2PE', '2pe': '2PE', '2pet': '2PE',
    '1 john': '1JN', '1john': '1JN', '1 jn': '1JN', '1jn': '1JN', '1 jo': '1JN',
    '2 john': '2JN', '2john': '2JN', '2 jn': '2JN', '2jn': '2JN', '2 jo': '2JN',
    '3 john': '3JN', '3john': '3JN', '3 jn': '3JN', '3jn': '3JN', '3 jo': '3JN',
    'jude': 'JUD', 'jud': 'JUD',
    'revelation': 'REV', 'rev': 'REV', 're': 'REV',
  };

  static const Map<String, String> _codeToFullName = {
    'GEN': 'Genesis', 'EXO': 'Exodus', 'LEV': 'Leviticus', 'NUM': 'Numbers', 'DEU': 'Deuteronomy',
    'JOS': 'Joshua', 'JDG': 'Judges', 'RUT': 'Ruth',
    '1SA': '1 Samuel', '2SA': '2 Samuel', '1KI': '1 Kings', '2KI': '2 Kings',
    '1CH': '1 Chronicles', '2CH': '2 Chronicles', 'EZR': 'Ezra', 'NEH': 'Nehemiah', 'EST': 'Esther',
    'JOB': 'Job', 'PSA': 'Psalms', 'PRO': 'Proverbs', 'ECC': 'Ecclesiastes', 'SNG': 'Song of Solomon',
    'ISA': 'Isaiah', 'JER': 'Jeremiah', 'LAM': 'Lamentations', 'EZK': 'Ezekiel', 'DAN': 'Daniel',
    'HOS': 'Hosea', 'JOE': 'Joel', 'AMO': 'Amos', 'OBA': 'Obadiah', 'JON': 'Jonah', 'MIC': 'Micah',
    'NAM': 'Nahum', 'HAB': 'Habakkuk', 'ZEP': 'Zephaniah', 'HAG': 'Haggai', 'ZEC': 'Zechariah', 'MAL': 'Malachi',
    'MAT': 'Matthew', 'MRK': 'Mark', 'LUK': 'Luke', 'JHN': 'John', 'ACT': 'Acts',
    'ROM': 'Romans', '1CO': '1 Corinthians', '2CO': '2 Corinthians', 'GAL': 'Galatians', 'EPH': 'Ephesians',
    'PHP': 'Philippians', 'COL': 'Colossians', '1TH': '1 Thessalonians', '2TH': '2 Thessalonians',
    '1TI': '1 Timothy', '2TI': '2 Timothy', 'TIT': 'Titus', 'PHM': 'Philemon', 'HEB': 'Hebrews',
    'JAM': 'James', '1PE': '1 Peter', '2PE': '2 Peter', '1JN': '1 John', '2JN': '2 John', '3JN': '3 John',
    'JUD': 'Jude', 'REV': 'Revelation',
  };

  String getBookFullName(String code) {
    return _codeToFullName[code.toUpperCase()] ?? code;
  }

  List<BibleVerse> searchVerses(String query, {String? versionId}) {
     if (query.isEmpty) return [];
     
     // Normalize query
     final q = query.trim();
     debugPrint("Bible Search Query: '$q'");
     
     // 1. Try to parse as reference: Book Chapter:Verse or Number Book Chapter:Verse
     // Regex to capture: (Book Name) (Chapter)(:Verse)?
     // E.g. "Gen 1:1", "1 Kings 3:5", "John 3"
     // Improved Regex to handle "1 Kings" (Number Space Word)
     final refRegex = RegExp(r'^((?:\d\s*)?[a-zA-Z]+)\s+(\d+)(?::(\d+))?$');
     final match = refRegex.firstMatch(q);
     
     // Determine versions to search
     List<BibleVersion> versionsToSearch = [];
     if (versionId != null) {
        final v = _cachedData?.versions.firstWhere((v) => v.id == versionId || v.abbreviation == versionId, orElse: () => BibleVersion(id: '', uuid: '', abbreviation: '', name: '', language: ''));
        if (v != null && v.id.isNotEmpty) versionsToSearch.add(v);
     } else {
        versionsToSearch = _cachedData?.versions ?? [];
     }
     debugPrint("Searching in ${versionsToSearch.length} versions");
     
     List<BibleVerse> results = [];
     
     if (match != null) {
        // Reference Search
        final bookRaw = match.group(1)?.toLowerCase().trim() ?? '';
        final chapter = int.tryParse(match.group(2) ?? '') ?? 0;
        final verseNum = match.group(3) != null ? int.tryParse(match.group(3)!) : null;
        
        debugPrint("Ref parsed: Book='$bookRaw', Ch=$chapter, V=$verseNum");

        if (bookRaw.isNotEmpty) {
           // Resolve book code
           String? targetBookCode = _bookNameToCode[bookRaw];
           
           if (targetBookCode == null) {
             // Try looking for containment in keys? e.g. user typed "Genes" or "1 Ki"
             // Map keys are lowercase.
             for (final entry in _bookNameToCode.entries) {
                if (entry.key == bookRaw || entry.key.startsWith(bookRaw)) { // "gen" starts with "gen"
                   targetBookCode = entry.value;
                   debugPrint("Resolved '$bookRaw' to '$targetBookCode' via prefix match");
                   break;
                }
             }
           } else {
              debugPrint("Resolved '$bookRaw' to '$targetBookCode' via direct map");
           }
           
           // If still null, try uppercase raw as code (e.g. "GEN")
           targetBookCode ??= bookRaw.toUpperCase();
           
           for (final version in versionsToSearch) {
               // Verify if this book exists in this version
               final availableBooks = getBooks(version.abbreviation);
               debugPrint("Available books in ${version.abbreviation}: ${availableBooks.take(10)}...");

               // Try to match targetBookCode to available books (case insensitive)
               // The JSON bookNames might be "1CH" or "Gen" or "Genesis"
               // We will try finding a book that matches our code OR starts with our raw query
               
               final matchingBookNames = availableBooks.where((b) {
                  return b.toUpperCase() == targetBookCode || 
                         b.toLowerCase() == bookRaw ||
                         b.toLowerCase().startsWith(bookRaw);
               }).toList();
               
               if (matchingBookNames.isNotEmpty) {
                 debugPrint("Found matching books: $matchingBookNames");
                 for (final bName in matchingBookNames) {
                     if (verseNum != null) {
                         results.addAll(getVerses(version.abbreviation, bName, chapter).where((v) => v.verse == verseNum));
                     } else {
                         results.addAll(getVerses(version.abbreviation, bName, chapter));
                     }
                 }
               } else {
                 debugPrint("No books matched '$targetBookCode' or '$bookRaw' in version ${version.abbreviation}");
               }
           }
        }
     }
     
     // If we found reference results, return them.
     if (results.isNotEmpty) {
       debugPrint("Found ${results.length} results via Reference Search");
       return results;
     }

     // Otherwise, Text Search (fallback)
     debugPrint("Falling back to text search for '$q'");
     final qLower = q.toLowerCase();
     
     for (final version in versionsToSearch) {
        for (final verse in version.verses) {
           if (verse.text.toLowerCase().contains(qLower)) {
              results.add(verse);
              if (results.length >= 100) return results;
           }
        }
     }
     return results;
  }
}
