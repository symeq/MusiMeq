import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class FavoritesService {
  static const _key = 'liked_songs';

  Future<bool> isFavorite(String videoId) async {
    final favorites = await getFavorites();
    return favorites.any((video) => video.id.value == videoId);
  }

  // Save a song
  Future<void> toggleFavorite(Video video) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedSongs = prefs.getStringList(_key) ?? [];

    // Create a unique ID for the song
    final String videoId = video.id.value;

    // Check if it's already saved
    final int existingIndex = savedSongs.indexWhere((item) {
      final Map<String, dynamic> data = jsonDecode(item);
      return data['id'] == videoId;
    });

    if (existingIndex >= 0) {
      // It exists -> Remove it (Unlike)
      savedSongs.removeAt(existingIndex);
    } else {
      // It doesn't exist -> Add it (Like)
      final Map<String, dynamic> songMap = {
        'id': video.id.value,
        'title': video.title,
        'author': video.author,
        'duration': video.duration?.inSeconds ?? 0,
        // We only really need the ID to reconstruct the thumbnail, 
        // but saving the URL doesn't hurt.
        'thumbnail': video.thumbnails.lowResUrl, 
      };
      savedSongs.add(jsonEncode(songMap));
    }

    await prefs.setStringList(_key, savedSongs);
  }

  Future<List<Video>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedSongs = prefs.getStringList(_key) ?? [];
    
    List<Video> validSongs = [];

    for (var item in savedSongs) {
      try {
        final Map<String, dynamic> data = jsonDecode(item);

        // --- FIX: UPDATED SAFE CONSTRUCTOR ---
        final video = Video(
          VideoId(data['id']),                    // 1. ID
          data['title'] ?? "Unknown Title",       // 2. Title
          data['author'] ?? "Unknown Artist",     // 3. Author
          ChannelId("UCn8zNIfYAQNdrFRrr8oibKw"),  // 4. Channel ID (Valid Dummy)
          DateTime.now(),                         // 5. Upload Date (No nulls)
          "",                                     // 6. Upload Date String (No nulls)
          DateTime.now(),                         // 7. Publish Date (No nulls)
          "",                                     // 8. Description (No nulls)
          Duration(seconds: data['duration'] ?? 0), // 9. Duration
          ThumbnailSet(data['id']),               // 10. Thumbnails
          [],                                     // 11. Keywords
          Engagement(0, 0, 0),                    // 12. Engagement
          false,                                  // 13. Is Live
        );
        
        validSongs.add(video);
      } catch (e) {
        print("Skipping bad song data: $e");
      }
    }

    return validSongs;
  }

  // Check if a specific song is liked
  Future<bool> isLiked(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedSongs = prefs.getStringList(_key) ?? [];

    return savedSongs.any((item) {
      final Map<String, dynamic> data = jsonDecode(item);
      return data['id'] == videoId;
    });
  }

  // Add this temporary helper
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}