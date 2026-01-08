import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistService {
  static const _key = 'user_playlists';

  // Structure: { "PlaylistName": [Video1, Video2, ...], "Playlist2": [...] }
  
  // 1. GET ALL PLAYLISTS
  Future<Map<String, List<Video>>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString(_key);
    if (dataString == null) return {};

    Map<String, dynamic> decodedMap = jsonDecode(dataString);
    Map<String, List<Video>> playlists = {};

    decodedMap.forEach((name, songListDynamic) {
      List<dynamic> songList = songListDynamic as List<dynamic>;
      List<Video> videos = songList.map((item) {
         // Reconstruct Video Object (Same safe logic as Favorites)
         final data = item as Map<String, dynamic>;
         return Video(
          VideoId(data['id']),
          data['title'] ?? "Unknown",
          data['author'] ?? "Unknown",
          ChannelId("UC0000000000000000000000"), 
          DateTime.now(), null, null, "",
          Duration(seconds: data['duration'] ?? 0),
          ThumbnailSet(data['id']), 
          [], Engagement(0, 0, 0), false,
        );
      }).toList();
      playlists[name] = videos;
    });

    return playlists;
  }

  // 2. CREATE NEW PLAYLIST
  Future<void> createPlaylist(String name) async {
    final playlists = await getPlaylists();
    if (playlists.containsKey(name)) return; // Don't overwrite if exists
    
    playlists[name] = []; // Empty list
    await _savePlaylists(playlists);
  }

  // 3. ADD SONG TO PLAYLIST
  Future<void> addSongToPlaylist(String playlistName, Video video) async {
    final playlists = await getPlaylists();
    if (!playlists.containsKey(playlistName)) return;

    // Check if song already exists in this specific playlist
    final songs = playlists[playlistName]!;
    bool alreadyExists = songs.any((v) => v.id.value == video.id.value);
    
    if (!alreadyExists) {
      songs.add(video);
      await _savePlaylists(playlists);
    }
  }

  // 4. DELETE PLAYLIST
  Future<void> deletePlaylist(String name) async {
    final playlists = await getPlaylists();
    playlists.remove(name);
    await _savePlaylists(playlists);
  }

  // 5. REMOVE SONG FROM PLAYLIST
  Future<void> removeSong(String playlistName, String videoId) async {
    final playlists = await getPlaylists();
    if (!playlists.containsKey(playlistName)) return;

    playlists[playlistName]!.removeWhere((v) => v.id.value == videoId);
    await _savePlaylists(playlists);
  }

  // --- INTERNAL HELPER TO SAVE TO DISK ---
  Future<void> _savePlaylists(Map<String, List<Video>> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert complex objects to JSON maps
    Map<String, dynamic> exportMap = {};
    
    playlists.forEach((name, videos) {
      exportMap[name] = videos.map((v) => {
        'id': v.id.value,
        'title': v.title,
        'author': v.author,
        'duration': v.duration?.inSeconds ?? 0,
        'thumbnail': v.thumbnails.highResUrl
      }).toList();
    });

    await prefs.setString(_key, jsonEncode(exportMap));
  }
}