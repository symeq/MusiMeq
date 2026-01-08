import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../services/playlist_service.dart';
import 'playlist_detail_screen.dart';
import '../widgets/design_components.dart';
import 'offline_library_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final PlaylistService _playlistService = PlaylistService();
  Map<String, List<dynamic>> _playlists = {};

  // ✅ NEW: Random Gradients Collection
  final List<List<Color>> _cardGradients = [
    [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)], // Purple -> Blue
    [const Color(0xFFFF512F), const Color(0xFFDD2476)], // Orange -> Pink
    [const Color(0xFF00b09b), const Color(0xFF96c93d)], // Teal -> Green
    [const Color(0xFFC33764), const Color(0xFF1D2671)], // Pink -> Deep Blue
    [const Color(0xFFFC466B), const Color(0xFF3F5EFB)], // Red -> Blue
    [const Color(0xFF11998e), const Color(0xFF38ef7d)], // Green -> Lime
    [const Color(0xFFf12711), const Color(0xFFf5af19)], // Red -> Orange
  ];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final data = await _playlistService.getPlaylists();
    if (mounted) {
      setState(() {
        _playlists = data;
      });
    }
  }

  // --- ACTIONS (Dialogs) ---
  Future<void> _createPlaylistDialog() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: GlassCard(
          borderRadius: 24, opacity: 0.15, padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("New Playlist", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: AppColors.electricBlue,
                decoration: InputDecoration(
                  hintText: "Enter name (e.g. Gym Vibes)",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricBlue)),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.white.withOpacity(0.6)))),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 40,
                    child: NeonButton(
                      text: "Create", icon: Icons.check,
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          await _playlistService.createPlaylist(controller.text);
                          _loadPlaylists();
                          if (mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlaylist(String name) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistName: name))).then((_) => _loadPlaylists());
  }

  Future<void> _showDeleteDialog(String name) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          borderRadius: 24, opacity: 0.15, padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 16),
              Text("Delete '$name'?", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("This action cannot be undone.", style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent),
                    onPressed: () async {
                      await _playlistService.deletePlaylist(name);
                      _loadPlaylists();
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text("Delete"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistNames = _playlists.keys.toList();
    final itemCount = 1 + playlistNames.length + 1; // Offline + Playlists + New

    return Column(
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Playlists", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1)),
              GestureDetector(
                onTap: _createPlaylistDialog,
                child: GlassCard(
                  borderRadius: 30, opacity: 0.1, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.add_rounded, color: AppColors.electricBlue, size: 18),
                      SizedBox(width: 4),
                      Text("New", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- GRID ---
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              
              // 1. OFFLINE CARD
              if (index == 0) {
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfflineLibraryScreen())),
                  child: GlassCard(
                    borderRadius: 20, opacity: 0.1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [const Color(0xFF004d40).withOpacity(0.5), const Color(0xFF009688).withOpacity(0.2)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          const Center(child: Icon(Icons.download_done_rounded, size: 50, color: Colors.white24)),
                          Positioned(
                            bottom: 12, left: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("Offline Mode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Downloaded songs", style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Positioned(top: 12, right: 12, child: Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 20)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // 2. NEW PLAYLIST CARD (Last)
              if (index == itemCount - 1) {
                return GestureDetector(
                  onTap: _createPlaylistDialog,
                  child: GlassCard(
                    borderRadius: 20, opacity: 0.05,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                          child: const Icon(Icons.add_rounded, color: AppColors.electricBlue, size: 30),
                        ),
                        const SizedBox(height: 12),
                        const Text("New Playlist", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }

              // 3. ACTUAL PLAYLISTS (Random Colors)
              final playlistIndex = index - 1;
              final name = playlistNames[playlistIndex];
              final songs = _playlists[name] ?? [];
              final songCount = songs.length;
              
              // ✅ NEW: Pick a random gradient based on index (Stable color per card)
              final gradient = _cardGradients[playlistIndex % _cardGradients.length];

              String? coverArtUrl;
              if (songs.isNotEmpty) {
                 final firstSong = songs.first;
                 if (firstSong is Video) coverArtUrl = firstSong.thumbnails.highResUrl;
                 else if (firstSong is Map) coverArtUrl = firstSong['thumbnail'] ?? "";
              }

              return GestureDetector(
                onTap: () => _openPlaylist(name),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          // ✅ NEW: Background is now the Random Gradient
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  gradient[0].withOpacity(0.8), // Vibrant top
                                  gradient[1].withOpacity(0.4), // Darker bottom
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: gradient[0].withOpacity(0.2), // Soft glow matching the card
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            // Only show art if it exists, otherwise show gradient icon
                            child: coverArtUrl != null && coverArtUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(coverArtUrl, fit: BoxFit.cover),
                                  )
                                : Center(child: Icon(Icons.music_note, color: Colors.white.withOpacity(0.3), size: 50)),
                          ),
                          
                          // Overlay Gradient for text readability
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                ),
                              ),
                            ),
                          ),

                          // Count Badge
                          Positioned(
                            bottom: 8, left: 8,
                            child: GlassCard(
                              borderRadius: 12, opacity: 0.2, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.music_note_rounded, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text("$songCount", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),

                          // Menu Button
                          Positioned(
                            top: 4, right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white70),
                              onPressed: () => _showDeleteDialog(name),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}