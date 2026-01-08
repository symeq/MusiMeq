import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../widgets/design_components.dart'; 

class RecommendationSection extends StatelessWidget {
  final String title;
  final List<Video> videos;
  final Function(Video) onPlay; // 1. Changed from Function(int)
  final Function(Video) onOption;

  const RecommendationSection({
    super.key,
    required this.title,
    required this.videos,
    required this.onPlay,
    required this.onOption,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  // 2. Pass the 'video' directly, not the index
                  onTap: () => onPlay(video), 
                  onLongPress: () => onOption(video),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              video.thumbnails.highResUrl,
                              height: 140,
                              width: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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
}