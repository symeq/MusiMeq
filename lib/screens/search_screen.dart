import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // ✅ NEW IMPORT
import '../widgets/design_components.dart';
import '../widgets/song_tile.dart';
import '../services/audio_service.dart';
import '../services/favorites_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../services/history_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // --- Controllers ---
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // --- Services ---
  final YoutubeExplode _yt = YoutubeExplode();
  final AudioService _audioService = AudioService();
  final FavoritesService _favService = FavoritesService();
  final DownloadService _downloadService = DownloadService();
  final HistoryService _historyService = HistoryService();
  final stt.SpeechToText _speech = stt.SpeechToText(); // ✅ Speech Object

  // --- Data State ---
  List<Video> _searchResults = [];
  VideoSearchList? _currentSearchList;
  List<String> _searchSuggestions = [];
  List<String> _recentSearches = [];
  
  Set<String> _likedIds = {};
  Set<String> _downloadedIds = {};
  
  // --- UI State ---
  bool _isLoading = false;      
  bool _isLoadingMore = false;  
  bool _isTyping = false; 
  bool _isListening = false; // ✅ Track Mic Status

  // --- Genre Data ---
  final List<Map<String, dynamic>> _browseCategories = [
    {"name": "Pop", "color": Colors.pinkAccent},
    {"name": "Hip Hop", "color": Colors.orange},
    {"name": "Rock", "color": Colors.redAccent},
    {"name": "Electronic", "color": Colors.blueAccent},
    {"name": "Indie", "color": Colors.purpleAccent},
    {"name": "Chill", "color": Colors.teal},
    {"name": "Workout", "color": Colors.green},
    {"name": "R&B", "color": Colors.indigo},
    {"name": "Jazz", "color": Colors.brown},
    {"name": "Classical", "color": Colors.amber},
    {"name": "Metal", "color": Colors.deepPurple},
    {"name": "K-Pop", "color": Colors.pink},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreResults();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final favs = await _favService.getFavorites();
    final downloads = await _downloadService.getOfflineSongs();
    if (mounted) {
      setState(() {
        _likedIds = favs.map((e) => e.id.value).toSet();
        _downloadedIds = downloads.map((s) => s['id'] as String).toSet();
      });
    }
  }

  // --- 🎙️ VOICE SEARCH LOGIC ---
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Mic Status: $status');
          if (status == 'done' || status == 'notListening') {
             setState(() => _isListening = false);
             // Auto-search if text was captured
             if (_searchController.text.isNotEmpty) {
               searchYoutube(_searchController.text);
             }
          }
        },
        onError: (error) => print('Mic Error: $error'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _searchController.text = val.recognizedWords;
              // Trigger suggestions while speaking
              if (val.recognizedWords.isNotEmpty) {
                _isTyping = true; 
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // --- 🕒 HISTORY LOGIC ---
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _recentSearches = prefs.getStringList('search_history') ?? []);
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) history = history.sublist(0, 10);
    await prefs.setStringList('search_history', history);
    if (mounted) setState(() => _recentSearches = history);
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('search_history', history);
    if (mounted) setState(() => _recentSearches = history);
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    if (mounted) setState(() => _recentSearches = []);
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Clear History?", style: TextStyle(color: Colors.white)),
        content: const Text("This will remove all your recent searches.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () { Navigator.pop(context); _clearAllHistory(); }, child: const Text("Clear All", style: TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // --- ⌨️ AUTO-COMPLETE LOGIC ---
  Future<void> _onSearchChanged() async {
    final text = _searchController.text;
    if (text.isEmpty) {
      if (mounted) setState(() { _isTyping = false; _searchSuggestions = []; });
      return;
    }
    setState(() => _isTyping = true);
    try {
      final suggestions = await _yt.search.getQuerySuggestions(text);
      final musicSuggestions = suggestions.where((s) {
        final lower = s.toLowerCase();
        if (lower.contains("interview") || lower.contains("reaction") || lower.contains("review") || lower.contains("funny") || lower.contains("shorts") || lower.contains("tiktok")) return false;
        return true;
      }).toList();
      if (mounted) setState(() => _searchSuggestions = musicSuggestions);
    } catch (e) { /* Ignore */ }
  }

  // --- 🛡️ STRICT FILTER ---
  bool _isStrictlyMusic(Video v) {
    final title = v.title.toLowerCase();
    final author = v.author.toLowerCase();
    if (v.duration != null) {
      if (v.duration!.inSeconds < 90) return false; 
      if (v.duration!.inMinutes > 15) return false;  
    }
    if (title.contains("full album") || title.contains("tiktok") || title.contains("shorts") || title.contains("reels") || title.contains("interview") || title.contains("podcast") || title.contains("news") || title.contains("reaction") || title.contains("review") || title.contains("trailer")) return false;
    bool isOfficial = author.endsWith(" - topic") || author.contains("vevo") || author.contains("official");
    if (!isOfficial) {
       if (!title.contains("official audio") && !title.contains("lyrics") && !title.contains("video") && !title.contains("audio")) return false;
    }
    return true;
  }

  // --- 🔍 MAIN SEARCH ---
  Future<void> searchYoutube(String query) async {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    _addToHistory(query); 
    if (_searchController.text != query) _searchController.text = query;
    setState(() { _isLoading = true; _searchResults = []; _currentSearchList = null; _isTyping = false; _searchSuggestions = []; });
    try {
      var searchTerms = query.toLowerCase().contains("audio") ? query : "$query Official Audio";
      VideoSearchList results = await _yt.search.search(searchTerms);
      if (!mounted) return; 
      var filteredList = <Video>[];
      for (var v in results) { if (_isStrictlyMusic(v)) filteredList.add(v); }
      setState(() { _currentSearchList = results; _searchResults = filteredList; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  // --- 🔄 INFINITE SCROLL ---
  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || _currentSearchList == null || _searchResults.isEmpty) return;
    setState(() => _isLoadingMore = true);
    try {
      var nextBatch = await _currentSearchList!.nextPage();
      if (nextBatch == null || nextBatch.isEmpty) { setState(() => _isLoadingMore = false); return; }
      var validNewSongs = <Video>[];
      for (var v in nextBatch) {
        if (_searchResults.any((existing) => existing.id.value == v.id.value)) continue;
        if (_isStrictlyMusic(v)) validNewSongs.add(v);
      }
      if (!mounted) return;
      setState(() { _searchResults.addAll(validNewSongs); _currentSearchList = nextBatch; _isLoadingMore = false; });
    } catch (e) { if (mounted) setState(() => _isLoadingMore = false); }
  }

  void _playAndSave(int index) { _audioService.setPlaylist(_searchResults, index); _historyService.addToHistory(_searchResults[index]); }
  
  Future<void> _toggleLike(Video video) async {
    setState(() { if (_likedIds.contains(video.id.value)) _likedIds.remove(video.id.value); else _likedIds.add(video.id.value); });
    await _favService.toggleFavorite(video);
  }

  // --- OPTIONS MENU ---
  void _showSongOptions(Video video) {
    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(video.thumbnails.lowResUrl, width: 50, height: 50, fit: BoxFit.cover)), title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text(video.author, style: TextStyle(color: Colors.white.withOpacity(0.7)))),
            const Divider(color: Colors.white12),
            ListTile(leading: const Icon(Icons.download_rounded, color: AppColors.electricBlue), title: const Text("Download Offline", style: TextStyle(color: Colors.white)), onTap: () async { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Downloading ${video.title}..."))); await _downloadService.downloadSong(video.id.value); if (mounted) _loadData(); }),
            ListTile(leading: const Icon(Icons.playlist_add_rounded, color: Colors.white), title: const Text("Add to Playlist", style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _addToPlaylist(video); }),
          ],
        ),
      ),
    );
  }

  Future<void> _addToPlaylist(Video video) async {
    final playlists = await PlaylistService().getPlaylists();
    if (!mounted) return;
    if (playlists.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Create a playlist first!"))); return; }
    showDialog(
      context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: const Text("Add to Playlist", style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: playlists.keys.map((name) => ListTile(title: Text(name, style: const TextStyle(color: Colors.white)), onTap: () async { await PlaylistService().addSongToPlaylist(name, video); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to $name"))); }})).toList())),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isBrowseMode = _searchController.text.isEmpty && _searchResults.isEmpty;
    return CustomScrollView(
      controller: _scrollController, 
      slivers: [
        // 1. HEADER WITH MIC
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Find Music", style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                // ✅ Search Bar with Mic
                Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white54),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: "What do you want to listen to?", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none),
                          onSubmitted: searchYoutube,
                        ),
                      ),
                      // ✅ Mic Button
                      GestureDetector(
                        onTap: _listen,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _isListening ? Colors.redAccent : Colors.transparent),
                          child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.white : Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. CONTENT SWITCHER
        if (_isLoading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.electricBlue)))
        else if (_isTyping)
           _buildSuggestionsSliver()
        else if (isBrowseMode)
          _buildBrowseModeSliver()
        else
          _buildSearchResultsSliver(),

        if (_isLoadingMore)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))),

        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildSuggestionsSliver() {
    return SliverList(delegate: SliverChildBuilderDelegate((context, index) {
      final suggestion = _searchSuggestions[index];
      return ListTile(leading: const Icon(Icons.search, color: Colors.white54, size: 20), title: Text(suggestion, style: const TextStyle(color: Colors.white, fontSize: 16)), onTap: () => searchYoutube(suggestion));
    }, childCount: _searchSuggestions.length));
  }

  Widget _buildBrowseModeSliver() {
    return SliverList(delegate: SliverChildListDelegate([
      if (_recentSearches.isNotEmpty) ...[
        Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Jump Back In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), GestureDetector(onTap: _confirmClearHistory, child: const Text("Clear", style: TextStyle(color: AppColors.electricBlue, fontSize: 12, fontWeight: FontWeight.bold)))])) ,
        SizedBox(height: 45, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _recentSearches.length, itemBuilder: (context, index) { final term = _recentSearches[index]; return Padding(padding: const EdgeInsets.only(right: 10), child: InputChip(label: Text(term, style: const TextStyle(color: Colors.white, fontSize: 13)), backgroundColor: const Color(0xFF2A2A2A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))), onPressed: () => searchYoutube(term), deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white54), onDeleted: () => _removeFromHistory(term))); })),
        const SizedBox(height: 20),
      ],
      const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 15), child: Text("Browse Genres", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Wrap(spacing: 12, runSpacing: 12, children: _browseCategories.map((category) { final double itemWidth = (MediaQuery.of(context).size.width - 44) / 2; return GestureDetector(onTap: () => searchYoutube(category["name"]), child: Container(width: itemWidth, height: itemWidth / 1.7, decoration: BoxDecoration(color: category["color"], borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [category["color"].withOpacity(0.9), category["color"].withOpacity(0.5)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: category["color"].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]), child: Stack(children: [Padding(padding: const EdgeInsets.all(14.0), child: Text(category["name"], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black26, blurRadius: 4)]))), Positioned(right: -15, bottom: -15, child: Transform.rotate(angle: 0.4, child: Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15))))) ]))); }).toList())),
    ]));
  }

  Widget _buildSearchResultsSliver() {
    if (_searchResults.isEmpty) return SliverFillRemaining(child: Center(child: Text("No results found", style: TextStyle(color: Colors.white.withOpacity(0.5)))));
    return SliverList(delegate: SliverChildBuilderDelegate((context, index) {
      final video = _searchResults[index];
      return TweenAnimationBuilder<double>(duration: const Duration(milliseconds: 400), curve: Curves.easeOut, tween: Tween(begin: 0.0, end: 1.0), builder: (context, value, child) { return Transform.translate(offset: Offset(0, 20 * (1 - value)), child: Opacity(opacity: value, child: child)); }, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: GestureDetector(onLongPress: () => _showSongOptions(video), child: SongTile(video: video, isLiked: _likedIds.contains(video.id.value), isDownloaded: _downloadedIds.contains(video.id.value), onLikeTap: () => _toggleLike(video), onTap: () => _playAndSave(index)))));
    }, childCount: _searchResults.length));
  }
}