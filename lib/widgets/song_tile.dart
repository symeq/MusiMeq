import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'design_components.dart'; // Uses your GlassCard and AppColors

enum SongTileVariant { card, row, compact }

class SongTile extends StatelessWidget {
  final Video video;
  final SongTileVariant variant;
  final bool isLiked;
  final bool isDownloaded;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;

  const SongTile({
    super.key,
    required this.video,
    this.variant = SongTileVariant.row,
    required this.isLiked,
    this.isDownloaded = false,
    this.isPlaying = false,
    required this.onTap,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case SongTileVariant.card:
        return _buildCard(context);
      case SongTileVariant.compact:
        return _buildCompact(context);
      case SongTileVariant.row:
      // ignore: unreachable_switch_default
      default:
        return _buildRow(context);
    }
  }

  // --- VARIANT 1: CARD (Fixed Download Indicator) ---
  Widget _buildCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Art Container
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: AlbumArt(
                    url: video.thumbnails.highResUrl,
                    size: 140,
                    borderRadius: 16,
                  ),
                ),
                // Gradient Overlay (on active)
                if (isPlaying)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // --- FIX STARTS HERE ---
                // Download Indicator (Corrected Blur Logic)
                if (isDownloaded)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ClipOval( // 1. Clip the blur to a circle
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // 2. Apply blur
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          color: AppColors.vibrantGreen.withOpacity(0.2), // 3. Transparent color
                          child: const Icon(Icons.check_circle, 
                              size: 12, color: AppColors.vibrantGreen),
                        ),
                      ),
                    ),
                  ),
                // --- FIX ENDS HERE ---

                // Playing Bars (Bottom Left)
                if (isPlaying)
                  const Positioned(
                    bottom: 8,
                    left: 8,
                    child: AudioVisualizer(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Text Info
            Text(
              video.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isPlaying ? AppColors.electricBlue : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              video.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // --- VARIANT 2: COMPACT ---
  Widget _buildCompact(BuildContext context) {
    return _buildBaseTile(
      height: 60,
      imageSize: 48,
      child: Row(
        children: [
          // Album Art with Overlay
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                AlbumArt(url: video.thumbnails.lowResUrl, size: 48, borderRadius: 8),
                if (isPlaying)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: AudioVisualizer(color: AppColors.electricBlue)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isPlaying ? AppColors.electricBlue : Colors.white,
                        ),
                      ),
                    ),
                    if (isDownloaded)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.check_circle, size: 12, color: AppColors.vibrantGreen),
                      ),
                  ],
                ),
                Text(
                  video.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Heart Icon
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? AppColors.neonMagenta : Colors.white54,
              size: 18,
            ),
            onPressed: onLikeTap,
          ),
        ],
      ),
    );
  }

  // --- VARIANT 3: ROW ---
  Widget _buildRow(BuildContext context) {
    return _buildBaseTile(
      height: 80,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Larger Album Art
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              children: [
                AlbumArt(url: video.thumbnails.lowResUrl, size: 56, borderRadius: 12),
                if (isPlaying)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: AudioVisualizer(color: AppColors.electricBlue)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isPlaying ? AppColors.electricBlue : Colors.white,
                        ),
                      ),
                    ),
                    if (isDownloaded)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check_circle, size: 14, color: AppColors.vibrantGreen),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  video.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.neonMagenta : Colors.white54,
                  size: 20,
                ),
                onPressed: onLikeTap,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(video.duration),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for Glass Effect wrapper
  Widget _buildBaseTile({required Widget child, double? height, EdgeInsets? padding, double imageSize = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        opacity: isPlaying ? 0.15 : 0.05,
        borderRadius: 16,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        onTap: onTap,
        child: child,
      ),
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return "--:--";
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }
}

// --- VISUALIZER WIDGET ---
class AudioVisualizer extends StatefulWidget {
  final Color color;
  const AudioVisualizer({super.key, this.color = AppColors.electricBlue});

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double t = (_controller.value + (index * 0.2)) % 1.0;
            final double height = 4 + (8 * (0.5 + 0.5 * (1 - (2 * t - 1).abs())));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}