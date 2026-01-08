import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class HistoryService {
  static const _key = 'play_history';

  // Get the list of recently played songs
  Future<List<Video>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList = prefs.getStringList(_key) ?? [];
    
    List<Video> videos = [];
    for (var item in historyList) {
      try {
        final Map<String, dynamic> data = jsonDecode(item);
        // Using the safe constructor (Same as Favorites)
        final video = Video(
          VideoId(data['id']),
          data['title'] ?? "Unknown",
          data['author'] ?? "Unknown",
          ChannelId('UCn8zNIfYAQNdrFRrr8oibKw'),
          DateTime.now(), "", DateTime.now(), "",
          Duration(seconds: data['duration'] ?? 0),
          ThumbnailSet(data['id']),
          [], Engagement(0, 0, 0), false,
        );
        videos.add(video);
      } catch (e) {
        print("Error parsing history item: $e");
      }
    }
    return videos;
  }

  // Add a song to history (Moves to top if already exists)
  Future<void> addToHistory(Video video) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyList = prefs.getStringList(_key) ?? [];

    // Create JSON map
    final Map<String, dynamic> songMap = {
      'id': video.id.value,
      'title': video.title,
      'author': video.author,
      'duration': video.duration?.inSeconds ?? 0,
    };
    final String jsonString = jsonEncode(songMap);

    // Remove duplicates (so we can move it to the front)
    historyList.removeWhere((item) {
      final data = jsonDecode(item);
      return data['id'] == video.id.value;
    });

    // Add to front (Newest first)
    historyList.insert(0, jsonString);

    // Keep limit to 10 items
    if (historyList.length > 10) {
      historyList = historyList.sublist(0, 10);
    }

    await prefs.setStringList(_key, historyList);
  }
}