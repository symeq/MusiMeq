import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../widgets/design_components.dart';

class WeeklyMixSection extends StatelessWidget {
  final List<Video> videos; // ✅ Reverted to simple List<Video>
  final Function(Video) onPlay;
  final Function(Video) onOption;

  const WeeklyMixSection({
    super.key,
    required this.videos,
    required this.onPlay,
    required this.onOption,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SectionHeader(title: "Weekly Mixes"),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onPlay(video),
                  onLongPress: () => onOption(video),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with Duration Badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              video.thumbnails.mediumResUrl,
                              height: 140,
                              width: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
                            ),
                          ),
                          // Duration Badge (Shows it's a long mix)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatDuration(video.duration),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return "";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${d.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}