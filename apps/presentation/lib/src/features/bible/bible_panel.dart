
import 'package:flutter/material.dart';
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
           // Default to English or first
           _selectedVersion = versions.firstWhere((v) => v.language == 'English', orElse: () => versions.first);
        }
      });
    }
  }

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedReference;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              child: _buildVerseItem(verse, showReference: true),
           );
        }).toList(),
     );
  }

  Widget _buildChapterView(BibleRepository repo) {
    if (_selectedVersion != null && _selectedBook != null && _selectedChapter != null) {
       return ListView(
          padding: const EdgeInsets.all(8),
          children: repo.getVerses(_selectedVersion!.abbreviation, _selectedBook!, _selectedChapter!).map((verse) {
             return Padding(
               padding: const EdgeInsets.symmetric(vertical: 4),
               child: _buildVerseItem(verse),
             );
          }).toList(),
       );
    }
    return const Center(child: Text("Select a book and chapter", style: TextStyle(color: Colors.white30)));
  }

  Widget _buildVerseItem(BibleVerse verse, {bool showReference = false}) {
    final uniqueRef = "${verse.bookName} ${verse.chapter}:${verse.verse}";
    final isSelected = _selectedReference == uniqueRef;

    return InkWell(
        onTap: () {
           // Action when clicking a verse (Project it)
           debugPrint("Projecting verse: $uniqueRef");
           
           setState(() {
              _selectedReference = uniqueRef;
           });
           
            // Format content for projection
            // Use full book name for projection
            final repo = ref.read(bibleRepositoryProvider);
            final fullBookName = repo.getBookFullName(verse.bookName);
            final projectionRef = "$fullBookName ${verse.chapter}:${verse.verse}";
            
            final content = "$projectionRef\n${verse.text}";
            
            // Update the live slide content provider which triggers the projection window
            ref.read(liveSlideContentProvider.notifier).state = LiveSlideData(
               content: content,
               alignment: 1, // Default center for Bible verses
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
