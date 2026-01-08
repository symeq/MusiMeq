import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../services/download_service.dart';
import '../services/audio_service.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/design_components.dart'; // Uses AppColors, GlassCard

class OfflineLibraryScreen extends StatefulWidget {
  const OfflineLibraryScreen({super.key});

  @override
  State<OfflineLibraryScreen> createState() => _OfflineLibraryScreenState();
}

class _OfflineLibraryScreenState extends State<OfflineLibraryScreen> {
  final DownloadService _downloadService = DownloadService();
  final AudioService _audioService = AudioService();
  List<Video> _offlineSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineSongs();
  }

  Future<void> _loadOfflineSongs() async {
    final downloads = await _downloadService.getOfflineSongs();
    
    final List<Video> songs = downloads.map((data) {
      return Video(
        VideoId(data['id']),           
        data['title'] ?? "Unknown",    
        data['artist'] ?? "Unknown",   
        ChannelId('UCn8zNIfYAQNdrFRrr8oibKw'),                 
        DateTime.now(),                
        '',                                    
        DateTime.now(),                
        '',                                    
        Duration.zero,                 
        ThumbnailSet(data['id']),      
        [],                            
        Engagement(0, 0, 0),           
        false,                         
      );
    }).toList();

    if (mounted) {
      setState(() {
        _offlineSongs = songs;
        _isLoading = false;
      });
    }
  }

  // --- 1. DELETE LOGIC ---
  Future<void> _deleteSong(String videoId) async {
    // 1. Remove from Storage
    await _downloadService.removeDownload(videoId);
    
    // 2. Show Feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Removed from Device 🗑️"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ),
      );
    }

    // 3. Reload List (if not handled by Dismissible)
    _loadOfflineSongs(); 
  }

  // --- 2. LONG PRESS MENU ---
  void _showDeleteOption(Video video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(video.thumbnails.lowResUrl, width: 50, height: 50, fit: BoxFit.cover),
              ),
              title: Text(
                video.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Downloaded Song", style: TextStyle(color: Colors.white54)),
            ),
            const Divider(color: Colors.white12),

            // Delete Option
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text("Delete from Device", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context); // Close menu
                _deleteSong(video.id.value);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Stack(
        children: [
          // --- BACKGROUND GLOW ---
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.vibrantGreen.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.vibrantGreen.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // --- CONTENT ---
          SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Offline Library",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "Play without internet",
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // LIST
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.vibrantGreen))
                      : _offlineSongs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_off_rounded, size: 60, color: Colors.white.withOpacity(0.1)),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No downloads yet",
                                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: _offlineSongs.length,
                              itemBuilder: (context, index) {
                                final video = _offlineSongs[index];
                                
                                return Dismissible(
                                  key: Key(video.id.value),
                                  direction: DismissDirection.endToStart, // Swipe Left to Delete
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                                  ),
                                  onDismissed: (direction) {
                                    // 1. Remove from UI immediately for smooth animation
                                    setState(() {
                                      _offlineSongs.removeAt(index);
                                    });
                                    // 2. Delete from Storage
                                    _deleteSong(video.id.value);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: GestureDetector(
                                      // --- ADDED LONG PRESS ---
                                      onLongPress: () => _showDeleteOption(video), 
                                      child: SongTile(
                                        video: video,
                                        variant: SongTileVariant.row,
                                        isLiked: false, 
                                        isDownloaded: true,
                                        onLikeTap: () {}, 
                                        onTap: () {
                                          _audioService.setPlaylist(_offlineSongs, index);
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // --- MINI PLAYER ---
          const Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}