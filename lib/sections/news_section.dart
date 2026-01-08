import 'package:flutter/material.dart';
import '../widgets/design_components.dart'; // ✅ Correct path to widgets

class NewsSection extends StatelessWidget {
  final List<Map<String, String>> newsList;
  final Function(String) onNewsTap;

  const NewsSection({
    super.key,
    required this.newsList,
    required this.onNewsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: "Music Buzz & Gossip"),
        if (newsList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text("Loading latest news...",
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => onNewsTap(news['url']!),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(16)),
                          child: Image.network(
                            news['image']!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Container(color: Colors.grey[900], width: 100),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  news['source']?.toUpperCase() ?? "NEWS",
                                  style: const TextStyle(
                                      color: AppColors.electricBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  news['title']!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}