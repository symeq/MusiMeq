import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Required for Status Bar Fix
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../widgets/design_components.dart';
import '../widgets/song_tile.dart';
import '../services/audio_service.dart';
import '../services/favorites_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../services/history_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final AudioService _audioService = AudioService();
  final FavoritesService _favService = FavoritesService();
  final DownloadService _downloadService = DownloadService();
  final HistoryService _historyService = HistoryService();
  final TextEditingController _searchController = TextEditingController();

  List<Video> _allSongs = []; // Store all favorites here
  List<Video> _filteredSongs = []; // Store the search results here
  Set<String> _likedIds = {};
  Set<String> _downloadedIds = {};
  
  bool _isLoading = true;
  bool _showDownloadedOnly = false; // Toggle state

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterSongs); // Listen for typing
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ UPDATED: Load Data
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _favService.getFavorites(),
      _downloadService.getOfflineSongs(),
    ]);

    final favs = results[0] as List<Video>;
    final downloads = results[1] as List<Map<String, dynamic>>;

    if (mounted) {
      setState(() {
        _likedIds = favs.map((e) => e.id.value).toSet();
        _downloadedIds = downloads.map((s) => s['id'] as String).toSet();
        
        _allSongs = favs; // Keep a copy of all songs
        _filterSongs();   // Apply initial filter
        _isLoading = false;
      });
    }
  }

  // ✅ NEW: Filter Logic
  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSongs = _allSongs.where((song) {
        final matchesSearch = song.title.toLowerCase().contains(query) || 
                              song.author.toLowerCase().contains(query);
        final matchesDownload = !_showDownloadedOnly || _downloadedIds.contains(song.id.value);
        return matchesSearch && matchesDownload;
      }).toList();
    });
  }

  Future<void> _toggleLike(Video video) async {
    setState(() {
      if (_likedIds.contains(video.id.value)) {
        _likedIds.remove(video.id.value);
        _allSongs.removeWhere((v) => v.id.value == video.id.value);
        _filterSongs();
      }
    });
    await _favService.toggleFavorite(video);
  }

  Future<void> _addToPlaylist(Video video) async {
    final playlists = await PlaylistService().getPlaylists();
    if (!mounted) return;
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Create a playlist first!")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Add to Playlist", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: playlists.keys.map((name) {
            return ListTile(
              title: Text(name, style: const TextStyle(color: Colors.white)),
              onTap: () async {
                await PlaylistService().addSongToPlaylist(name, video);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to $name")));
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Force Transparent Status Bar
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // This makes the gradient show through
        statusBarIconBrightness: Brightness.light, 
      ),
      child: Column(
        children: [
          // --- 1. HEADER & SEARCH ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16), // Increased top padding for status bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Library",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34, // Slightly bigger for modern look
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // ✅ NEW: Filter Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showDownloadedOnly = !_showDownloadedOnly;
                          _filterSongs();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _showDownloadedOnly ? AppColors.electricBlue : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _showDownloadedOnly ? AppColors.electricBlue : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.download_done, size: 16, color: _showDownloadedOnly ? Colors.black : Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              "Downloaded", 
                              style: TextStyle(
                                color: _showDownloadedOnly ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),

                // ✅ NEW: Search Bar
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.white54),
                      hintText: "Search your songs...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Shuffle Button (Only show if songs exist)
                if (_filteredSongs.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      text: "Shuffle Play (${_filteredSongs.length})",
                      icon: Icons.shuffle,
                      onPressed: () {
                        _audioService.isShuffleMode.value = true;
                        _audioService.setPlaylist(_filteredSongs, 0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Shuffling... 🎲")),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // --- 2. SONG LIST ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
                : _filteredSongs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.music_off, size: 60, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty 
                                  ? "No songs found" 
                                  : "No result for '${_searchController.text}'",
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _filteredSongs.length,
                        itemBuilder: (context, index) {
                          final video = _filteredSongs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: GestureDetector(
                              onLongPress: () => _addToPlaylist(video),
                              child: SongTile(
                                video: video,
                                isLiked: true,
                                isDownloaded: _downloadedIds.contains(video.id.value),
                                onLikeTap: () => _toggleLike(video),
                                onTap: () {
                                  _historyService.addToHistory(video);
                                  _audioService.setPlaylist(_filteredSongs, index);
                                }
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}