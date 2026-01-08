import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_service.dart';
import '../screens/player_screen.dart';
import 'design_components.dart'; // Uses your GlassCard, AppColors, and AlbumArt
import 'song_tile.dart'; // Uses AudioVisualizer from here

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    // --- LISTEN FOR ERRORS ---
    _audioService.errorMessage.addListener(_onError);
  }

  @override
  void dispose() {
    _audioService.errorMessage.removeListener(_onError);
    super.dispose();
  }

  // --- SHOW SNACKBAR FUNCTION ---
  void _onError() {
    final error = _audioService.errorMessage.value;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(error, style: const TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      _audioService.errorMessage.value = null; 
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen to loading state
    return ValueListenableBuilder<bool>(
      valueListenable: _audioService.isLoading,
      builder: (context, isLoading, _) {
        
        // 2. Listen to player state
        return StreamBuilder<PlayerState>(
          stream: _audioService.player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing ?? false;
            
            // Show loading spinner if fetching URL or Buffering
            final isBuffering = isLoading || 
                processingState == ProcessingState.loading || 
                processingState == ProcessingState.buffering;

            // Hide if idle (nothing selected)
            if (processingState == ProcessingState.idle && !isLoading) {
              return const SizedBox.shrink();
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlayerScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: GlassCard(
                  borderRadius: 16,
                  opacity: 0.2,
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // MAIN CONTENT ROW
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            // 1. ALBUM ART with Visualizer & Hero Animation
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Stack(
                                children: [
                                  ValueListenableBuilder<String>(
                                    valueListenable: _audioService.currentSongArt,
                                    builder: (context, artUrl, _) {
                                      // ✅ HERO WIDGET ADDED HERE
                                      return Hero(
                                        tag: 'album_art', // Must match PlayerScreen tag
                                        child: AlbumArt(
                                          url: artUrl,
                                          size: 44,
                                          borderRadius: 10,
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  if (playing)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Center(
                                        child: AudioVisualizer(
                                          color: AppColors.electricBlue,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 12),

                            // 2. SONG INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ValueListenableBuilder<String>(
                                    valueListenable: _audioService.currentSongTitle,
                                    builder: (context, title, _) {
                                      return Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                  ValueListenableBuilder<String>(
                                    valueListenable: _audioService.currentSongArtist,
                                    builder: (context, artist, _) {
                                      return Text(
                                        artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // 3. CONTROLS
                            Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: isBuffering 
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2, 
                                          color: AppColors.electricBlue
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: () {
                                          if (playing) {
                                            _audioService.player.pause();
                                          } else {
                                            _audioService.player.play();
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.electricBlue, 
                                            boxShadow: playing ? [
                                              BoxShadow(
                                                color: AppColors.electricBlue.withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              )
                                            ] : [],
                                          ),
                                          child: Icon(
                                            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                ),
                                
                                const SizedBox(width: 4),

                                IconButton(
                                  icon: Icon(
                                    Icons.skip_next_rounded,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    _audioService.skipToNext();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 4. PROGRESS BAR
                      StreamBuilder<Duration>(
                        stream: _audioService.player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = _audioService.player.duration ?? Duration.zero;
                          
                          double progress = 0.0;
                          if (duration.inMilliseconds > 0) {
                            progress = position.inMilliseconds / duration.inMilliseconds;
                            if (progress > 1.0) progress = 1.0;
                          }

                          return Container(
                            height: 2,
                            width: double.infinity,
                            color: Colors.white.withOpacity(0.1),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: constraints.maxWidth * progress,
                                    height: 2,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.electricBlue,
                                          AppColors.neonMagenta,
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}