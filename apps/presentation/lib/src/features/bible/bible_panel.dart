
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bible_repository.dart';
import 'bible_model.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../editor/editor_provider.dart';

class BiblePanel extends ConsumerStatefulWidget {
  const BiblePanel({super.key});

  @override
  ConsumerState<BiblePanel> createState() => _BiblePanelState();
}

class _BiblePanelState extends ConsumerState<BiblePanel> {
  BibleVersion? _selectedVersion;
  String? _selectedBook;
  int? _selectedChapter;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(bibleRepositoryProvider);
    await repo.loadBibleData();
    if (mounted) {
      setState(() {
        _isLoading = false;
        // Set defaults if available
        final versions = repo.getVersions();
        if (versions.isNotEmpty) {
           // Default to NLT if available, otherwise English or first
           final nlt = versions.where((v) => v.abbreviation == 'NLT').firstOrNull;
           final english = versions.where((v) => v.language == 'English').firstOrNull;
           _selectedVersion = nlt ?? english ?? versions.first;
        }
      });
    }
  }

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Set<String> _selectedReferences = {};
  String? _lastSelectedReference; // For Shift-click range selection

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String ref, bool isMulti, bool isRange, List<BibleVerse> currentVerses) {
     setState(() {
        if (isRange && _lastSelectedReference != null) {
           // Find indices
           final startRef = _lastSelectedReference!;
           final endRef = ref;
           
           // We need the list of visible verses to determine range
           // Fortunately we pass currentVerses
           int startIndex = currentVerses.indexWhere((v) => "${v.bookName} ${v.chapter}:${v.verse}" == startRef);
           int endIndex = currentVerses.indexWhere((v) => "${v.bookName} ${v.chapter}:${v.verse}" == endRef);
           
           if (startIndex != -1 && endIndex != -1) {
              final start = startIndex < endIndex ? startIndex : endIndex;
              final end = startIndex < endIndex ? endIndex : startIndex;
              
              _selectedReferences.clear();
              for (int i = start; i <= end; i++) {
                 final v = currentVerses[i];
                 _selectedReferences.add("${v.bookName} ${v.chapter}:${v.verse}");
              }
           }
        } else if (isMulti) {
           if (_selectedReferences.contains(ref)) {
              _selectedReferences.remove(ref);
           } else {
              _selectedReferences.add(ref);
           }
           _lastSelectedReference = ref;
        } else {
           _selectedReferences.clear();
           _selectedReferences.add(ref);
           _lastSelectedReference = ref;
        }
     });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final repo = ref.watch(bibleRepositoryProvider);
    final versions = repo.getVersions();

    if (versions.isEmpty) {
      return const Center(child: Text("No Bible data found.", style: TextStyle(color: Colors.white)));
    }

    return Column(
      children: [
        // Controls (Version, Search, Book, Chapter)
        Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF2D2D2D),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               // Version Selector
               DropdownButton<BibleVersion>(
                 isExpanded: true,
                 dropdownColor: const Color(0xFF424242),
                 value: _selectedVersion,
                 style: const TextStyle(color: Colors.white),
                 hint: const Text('Select Version', style: TextStyle(color: Colors.white70)),
                 items: versions.map((v) {
                   return DropdownMenuItem(
                     value: v,
                     child: Text("${v.abbreviation} - ${v.name}", overflow: TextOverflow.ellipsis),
                   );
                 }).toList(),
                 onChanged: (v) {
                   setState(() {
                     _selectedVersion = v;
                     _selectedBook = null;
                     _selectedChapter = null;
                   });
                 },
               ),
               const SizedBox(height: 8),

               // Search Bar
               TextField(
                 controller: _searchController,
                 style: const TextStyle(color: Colors.white),
                 decoration: InputDecoration(
                   hintText: 'Search...',
                   hintStyle: const TextStyle(color: Colors.white30),
                   prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 16),
                   isDense: true,
                   contentPadding: const EdgeInsets.all(8),
                   filled: true,
                   fillColor: Colors.black26,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                 ),
                 onChanged: (value) {
                   setState(() {
                     _searchQuery = value;
                   });
                 },
               ),
               
               if (_searchQuery.isEmpty) ...[
                 const SizedBox(height: 8),
                 Row(
                   children: [
                     // Book Selector
                     Expanded(
                       flex: 2,
                       child: DropdownButton<String>(
                         isExpanded: true,
                         dropdownColor: const Color(0xFF424242),
                         value: _selectedBook,
                         style: const TextStyle(color: Colors.white),
                         hint: const Text('Book', style: TextStyle(color: Colors.white70)),
                         items: _selectedVersion == null ? [] : repo.getBooks(_selectedVersion!.abbreviation).map((b) {
                           return DropdownMenuItem(
                             value: b,
                             child: Text(b, overflow: TextOverflow.ellipsis),
                           );
                         }).toList(),
                         onChanged: (b) {
                           setState(() {
                             _selectedBook = b;
                             _selectedChapter = 1; // Default to chap 1
                           });
                         },
                       ),
                     ),
                     const SizedBox(width: 8),
                     // Chapter Selector
                     Expanded(
                       flex: 1,
                       child: DropdownButton<int>(
                         isExpanded: true,
                         dropdownColor: const Color(0xFF424242),
                         value: _selectedChapter,
                         style: const TextStyle(color: Colors.white),
                         hint: const Text('Ch', style: TextStyle(color: Colors.white70)),
                         items: (_selectedVersion != null && _selectedBook != null) 
                           ? repo.getChapters(_selectedVersion!.abbreviation, _selectedBook!).map((c) {
                             return DropdownMenuItem(
                               value: c,
                               child: Text(c.toString()),
                             );
                           }).toList()
                           : [],
                         onChanged: (c) {
                           setState(() {
                             _selectedChapter = c;
                           });
                         },
                       ),
                     ),
                   ],
                 ),
               ],
            ],
          ),
        ),
        
        // Verses List or Search Results
        Expanded(
          child: _searchQuery.isNotEmpty 
            ? _buildSearchResults(repo)
            : _buildChapterView(repo),
        ),
        
        // Copyright Footer
        if (_selectedVersion?.copyright != null)
          Container(
             padding: const EdgeInsets.all(4),
             color: Colors.black26,
             child: Text(
               _selectedVersion!.copyright!.text,
               style: const TextStyle(color: Colors.white30, fontSize: 10),
               textAlign: TextAlign.center,
             ),
          ),
      ],
    );
  }

  Widget _buildSearchResults(BibleRepository repo) {
     final results = repo.searchVerses(_searchQuery, versionId: _selectedVersion?.id);
     
     if (results.isEmpty) {
        return const Center(child: Text("No results found.", style: TextStyle(color: Colors.white30)));
     }
     
     return ListView(
        padding: const EdgeInsets.all(8),
        children: results.map((verse) {
           return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildVerseItem(verse, showReference: true, allVerses: results),
           );
        }).toList(),
     );
  }

  Widget _buildChapterView(BibleRepository repo) {
    if (_selectedVersion != null && _selectedBook != null && _selectedChapter != null) {
       final chapterVerses = repo.getVerses(_selectedVersion!.abbreviation, _selectedBook!, _selectedChapter!);
       return ListView(
          padding: const EdgeInsets.all(8),
          children: chapterVerses.map((verse) {
             return Padding(
               padding: const EdgeInsets.symmetric(vertical: 4),
               child: _buildVerseItem(verse, allVerses: chapterVerses),
             );
          }).toList(),
       );
    }
    return const Center(child: Text("Select a book and chapter", style: TextStyle(color: Colors.white30)));
  }

  Widget _buildVerseItem(BibleVerse verse, {bool showReference = false, List<BibleVerse>? allVerses}) {
    final uniqueRef = "${verse.bookName} ${verse.chapter}:${verse.verse}";
    final isSelected = _selectedReferences.contains(uniqueRef);

    // Create a feedback widget for dragging
    Widget feedbackWidget() {
       final count = _selectedReferences.length;
       return Material(
         color: Colors.transparent,
         child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
               color: Colors.blueAccent,
               borderRadius: BorderRadius.circular(8),
               boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                  const Icon(Icons.format_quote, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                     count > 1 ? "$count Verses" : uniqueRef,
                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
               ],
            ),
         ),
       );
    }

    return Draggable<List<BibleVerse>>(
      data: _selectedReferences.contains(uniqueRef) 
          ? (allVerses?.where((v) => _selectedReferences.contains("${v.bookName} ${v.chapter}:${v.verse}")).toList() ?? [verse])
          : [verse], // If dragging unselected, just drag that one
      feedback: feedbackWidget(),
      childWhenDragging: Opacity(opacity: 0.5, child: _verseContent(verse, uniqueRef, isSelected, showReference, allVerses)),
      child: _verseContent(verse, uniqueRef, isSelected, showReference, allVerses),
    );
  }

  Widget _verseContent(BibleVerse verse, String uniqueRef, bool isSelected, bool showReference, List<BibleVerse>? allVerses) {
      return InkWell(
        onTap: () {
           final isCtrl = HardwareKeyboard.instance.isControlPressed;
           final isShift = HardwareKeyboard.instance.isShiftPressed;
           
           if (allVerses != null) {
              _toggleSelection(uniqueRef, isCtrl, isShift, allVerses);
           } else {
              // Fallback if list not provided (e.g. search results logic might need update to pass list)
              _toggleSelection(uniqueRef, isCtrl, false, []); 
           }
           
           // Auto-project on single click ONLY if not multi-selecting? 
           // Request says: "can be draggable... per verse... multi select to drag"
           // It didn't explicitly say "remove click to project", but usually multi-select UI conflicts with "click to action".
           // Let's Keep "Click" as "Select". 
           // We can add a "Double Click" to project immediately? Or just drag to project.
           // PREVIOUS BEHAVIOR: Click -> Project.
           // NEW BEHAVIOR: Click -> Select. Double Click -> Project?
           // Let's implement Double Tap to Project.
           
        },
        onDoubleTap: () {
            debugPrint("Projecting verse: $uniqueRef");
            // Project immediately
             final repo = ref.read(bibleRepositoryProvider);
             final fullBookName = repo.getBookFullName(verse.bookName);
             final projectionRef = "$fullBookName ${verse.chapter}:${verse.verse}";
             final content = "$projectionRef\n${verse.text}";
             
             ref.read(liveSlideContentProvider.notifier).state = LiveSlideData(
                content: content,
                alignment: 1,
             );
        },
        child: Container(
           padding: const EdgeInsets.all(8),
           decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3A3A3A) : Colors.black12,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.white10, 
                  width: isSelected ? 2 : 1
              ),
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               if (showReference)
                  Text(
                     "${verse.bookName} ${verse.chapter}:${verse.verse}",
                     style: const TextStyle(color: Colors.white54, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
               Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                      "${verse.verse}", 
                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                      child: Text(
                         verse.text,
                         style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                   ),
                 ],
               ),
             ],
           ),
        ),
     );
  }
}
