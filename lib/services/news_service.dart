import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class NewsService {
  // ✅ Switch to Billboard (often has better images) or keep NME
  static const String _rssUrl = 'https://www.nme.com/feed';

  // 🎨 Random Placeholders (so it never looks boring)
  final List<String> _placeholders = [
    'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=600&auto=format&fit=crop', // Surfer/Vibe
    'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=600&auto=format&fit=crop', // Microphone
    'https://images.unsplash.com/photo-1514525253440-b393452e8d26?q=80&w=600&auto=format&fit=crop', // DJ
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=600&auto=format&fit=crop', // Turntable
    'https://images.unsplash.com/photo-1511379938547-c1f69419868d?q=80&w=600&auto=format&fit=crop', // Instruments
  ];

  Future<List<Map<String, String>>> getMusicNews() async {
    try {
      final response = await http.get(Uri.parse(_rssUrl));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        return items.map((node) {
          // 1. Extract Basic Info
          final title = node.findElements('title').single.innerText;
          final link = node.findElements('link').single.innerText;
          final description = node.findElements('description').isNotEmpty 
              ? node.findElements('description').single.innerText 
              : '';

          // 2. Extract Image (Improved Logic)
          String imageUrl = '';

          // Check standard media tags
          final media = node.findElements('media:content');
          if (media.isNotEmpty) {
            imageUrl = media.first.getAttribute('url') ?? '';
          } 
          
          // 🕵️‍♂️ Check inside HTML Description (Regex)
          // Many feeds hide the image in an <img src="..."> tag inside the description
          if (imageUrl.isEmpty && description.isNotEmpty) {
            final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
            final match = imgRegex.firstMatch(description);
            if (match != null) {
              imageUrl = match.group(1) ?? '';
            }
          }

          // 🎲 Fallback: Randomize if still empty
          if (imageUrl.isEmpty) {
            imageUrl = _placeholders[Random().nextInt(_placeholders.length)];
          }

          return {
            'title': title,
            'image': imageUrl,
            'source': 'NME', 
            'url': link,
          };
        }).take(10).toList(); 
      } else {
        return [];
      }
    } catch (e) {
      print("RSS Error: $e");
      return [];
    }
  }
}