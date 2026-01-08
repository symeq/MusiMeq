import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../services/playlist_service.dart';
import '../services/audio_service.dart';
import '../services/history_service.dart'; // ✅ NEW IMPORT
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/design_components.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistName;
  const PlaylistDetailScreen({super.key, required this.playlistName});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistService _playlistService = PlaylistService();
  final AudioService _audioService = AudioService();
  final HistoryService _historyService = HistoryService(); // ✅ NEW INSTANCE
  
  List<Video> _songs = [];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final playlists = await _playlistService.getPlaylists();
    if (mounted) {
      setState(() {
        _songs = playlists[widget.playlistName] ?? [];
      });
    }
  }

  Future<void> _removeSong(String videoId) async {
    // Optimistic Update: Remove from UI immediately for speed
    final index = _songs.indexWhere((s) => s.id.value == videoId);
    final removedSong = _songs[index];
    
    setState(() {
      _songs.removeAt(index);
    });

    await _playlistService.removeSong(widget.playlistName, videoId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Removed '${removedSong.title}'"),
          backgroundColor: AppColors.electricBlue,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: "UNDO",
            textColor: Colors.black,
            onPressed: () async {
              await _playlistService.addSongToPlaylist(widget.playlistName, removedSong);
              _loadSongs(); // Reload to restore
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12), 
      body: Stack(
        children: [
          // --- 1. BACKGROUND GLOW ---
          Positioned(
            top: -100, left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.electricBlue.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricBlue.withOpacity(0.15),
                    blurRadius: 100, spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // --- 2. MAIN CONTENT ---
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: GlassCard(
                          borderRadius: 50, opacity: 0.1, padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.playlistName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text("${_songs.length} Songs", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                          ],
                        ),
                      ),
                      if (_songs.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _audioService.setPlaylist(_songs, 0);
                            // Also add first song to history
                            _historyService.addToHistory(_songs[0]); 
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.electricBlue, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.electricBlue, blurRadius: 15, spreadRadius: 1)],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                          ),
                        ),
                    ],
                  ),
                ),

                // LIST
                Expanded(
                  child: _songs.isEmpty
                      ? Center(
                          child: Text("Empty Playlist", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), // ✅ Fix: Space for MiniPlayer
                          itemCount: _songs.length,
                          itemBuilder: (context, index) {
                            final video = _songs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Dismissible(
                                key: Key(video.id.value),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                ),
                                onDismissed: (_) => _removeSong(video.id.value),
                                child: SongTile(
                                  video: video,
                                  variant: SongTileVariant.row, 
                                  isLiked: false, 
                                  onLikeTap: () {}, 
                                  onTap: () {
                                    // ✅ 1. Add to History
                                    _historyService.addToHistory(video);
                                    
                                    // ✅ 2. Play
                                    _audioService.setPlaylist(_songs, index);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // --- 3. MINI PLAYER ---
          const Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayer(), // ✅ Uses your existing MiniPlayer
          ),
        ],
      ),
    );
  }
}