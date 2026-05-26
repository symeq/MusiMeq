import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'; // ✅ Required for Notification
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'download_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  // --- 1. CONSTRUCTOR & LISTENERS ---
  AudioService._internal() {
    // ✅ CRITICAL: Listen to index changes from the player
    // This updates the UI when the song changes automatically in the background
    player.currentIndexStream.listen((index) {
      if (index != null && index < _queue.length) {
        _currentIndex = index;
        _updateCurrentSongDetails(_queue[index]);
      }
    });

    // Listen for Player State to handle LoopMode.off manually if needed
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (loopMode.value == LoopMode.off &&
            _currentIndex == _queue.length - 1) {
          player.stop();
        }
      }
    });
  }

  // --- UI Notifiers ---
  final ValueNotifier<String> currentThumbnail = ValueNotifier("");
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<bool> isShuffleMode = ValueNotifier(false);
  final ValueNotifier<LoopMode> loopMode = ValueNotifier(LoopMode.off);

  // --- Song Details Notifiers ---
  final ValueNotifier<String> currentSongTitle = ValueNotifier("Select a Song");
  final ValueNotifier<String> currentSongArtist = ValueNotifier("");
  final ValueNotifier<String> currentSongId = ValueNotifier("");
  final ValueNotifier<String> currentSongArt = ValueNotifier("");
  final ValueNotifier<String> currentSongLyrics = ValueNotifier("");
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  // ✅ Player Configured for Background
  final AudioPlayer player = AudioPlayer(
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        minBufferDuration: Duration(seconds: 15),
        maxBufferDuration: Duration(seconds: 50),
        bufferForPlaybackDuration: Duration(milliseconds: 2500),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 5),
      ),
    ),
  );

  final ValueNotifier<double> playbackSpeed = ValueNotifier(1.0);

  List<Video> _queue = [];
  int _currentIndex = 0;
  List<Video> get playlist => _queue;
  int get currentIndex => _currentIndex;

  // --- 2. CORE ACTIONS ---

  Future<void> setSpeed(double speed) async {
    playbackSpeed.value = speed;
    await player.setSpeed(speed);
  }

  // Sleep Timer
  Timer? _sleepTimer;
  final ValueNotifier<int?> sleepTimerMinutes = ValueNotifier(null);

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    sleepTimerMinutes.value = minutes;
    if (minutes != null) {
      print("💤 Sleep timer set for $minutes minutes");
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        player.pause();
        sleepTimerMinutes.value = null;
        print("💤 Sleep timer triggered.");
      });
    }
  }

  // ✅ THE NEW PLAYLIST ENGINE (Background Compatible)
  Future<void> setPlaylist(List<Video> songs, int initialIndex) async {
    _queue = songs;
    _currentIndex = initialIndex;

    try {
      isLoading.value = true;

      // 1. Update UI for the first song immediately
      _updateCurrentSongDetails(songs[initialIndex]);

      // 2. Prepare the list of Audio Sources
      // We map every video in the list to an AudioSource with Metadata
      final playlistSource = ConcatenatingAudioSource(
        children: await Future.wait(songs.map((video) async {
          return await _createAudioSource(video);
        }).toList()),
      );

      // 3. Load the entire list into the player
      await player.setAudioSource(
        playlistSource,
        initialIndex: initialIndex,
      );

      // 4. Play!
      player.play();
      isLoading.value = false;
    } catch (e) {
      print("❌ Error loading playlist: $e");
      errorMessage.value = "Failed to load playlist";
      isLoading.value = false;
    }
  }

  Future<AudioSource> _createAudioSource(Video video) async {
    String url = "";
    bool isLocal = false;

    // 1. Check Offline File first
    final directory = await getApplicationDocumentsDirectory();
    final localPath = '${directory.path}/${video.id.value}.mp3';
    final localFile = File(localPath);

    if (await localFile.exists() && (await localFile.length()) > 10000) {
      url = localPath;
      isLocal = true;
    } else {
      // 2. Fetch Online MP3 Link via your RapidAPI Endpoint
      try {
        final videoId = video.id.value;
        
        // Constructing the URL with the proper query parameter 'id'
        final apiUrl = Uri.parse('https://youtube-mp36.p.rapidapi.com/dl?id=$videoId');
        
        final response = await http.get(
          apiUrl,
          headers: {
            'X-RapidAPI-Key': 'c8db22c063mshf03809e75159f42p172ae4jsn7ebe14d1c82f',
            'X-RapidAPI-Host': 'youtube-mp36.p.rapidapi.com',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Checking the response fields based on this API's structure
          // It typically provides a direct download link under 'link' or 'url'
          if (data['link'] != null) {
            url = data['link'] as String;
          } else if (data['url'] != null) {
            url = data['url'] as String;
          }
        } else {
          print("⚠️ API Server responded with status: ${response.statusCode}");
        }
      } catch (e) {
        print("❌ MP3 API Error for ${video.title}: $e");
      }
    }

    // 3. Safety Fallback (Prevents crashes if API fails or rate limit is hit)
    if (url.isEmpty) {
        print("🚨 Fallback triggered for: ${video.title}");
        return AudioSource.uri(
            Uri.parse("https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
            tag: MediaItem(
                id: video.id.value,
                album: "Error",
                title: "${video.title} (Unavailable)",
                artist: "Stream Failed",
                artUri: Uri.parse(video.thumbnails.highResUrl),
            ),
        );
    }

    // 4. Return valid source
    return AudioSource.uri(
      isLocal ? Uri.file(url) : Uri.parse(url),
      tag: MediaItem(
        id: video.id.value,
        album: "MusiMeq Library",
        title: video.title,
        artist: video.author,
        artUri: Uri.parse(video.thumbnails.highResUrl),
      ),
    );
  }

  // Update UI & Triggers
  void _updateCurrentSongDetails(Video video) {
    currentSongTitle.value = video.title;
    currentSongArtist.value = video.author;
    currentSongId.value = video.id.value;
    currentThumbnail.value = video.thumbnails.highResUrl;
    currentSongArt.value = video.thumbnails.highResUrl;

    // Fetch Lyrics
    _fetchLyrics(video.title, video.author, video.description);

    // Smart Download Trigger
    DownloadService().autoCacheSong(video);
  }

  // --- 3. NAVIGATION (Now uses Player Queue) ---

  Future<void> jumpToSong(int index) async {
    if (index >= 0 && index < _queue.length) {
      // We seek to the specific index in the ConcatenatingAudioSource
      await player.seek(Duration.zero, index: index);
      player.play();
    }
  }

  void skipToNext() {
    if (player.hasNext) {
      player.seekToNext();
    } else {
      // Loop All Logic
      if (loopMode.value == LoopMode.all) {
        player.seek(Duration.zero, index: 0);
      }
    }
  }

  void skipToPrevious() {
    if (player.hasPrevious) {
      player.seekToPrevious();
    } else {
      player.seek(Duration.zero, index: 0);
    }
  }

  void stop() {
    player.stop();
  }

  // --- 4. LYRICS ENGINE (Unchanged) ---
  Future<void> _fetchLyrics(
      String rawTitle, String rawArtist, String description) async {
    currentSongLyrics.value =
        "Searching for lyrics...\n\n(Fallback: Description)\n$description";

    try {
      String cleanTitle = _cleanString(rawTitle);
      String cleanArtist = _cleanString(rawArtist);

      if (cleanTitle.contains("-")) {
        final parts = cleanTitle.split("-");
        cleanArtist = parts[0].trim();
        cleanTitle = parts[1].trim();
      }

      final url =
          Uri.parse('https://api.lyrics.ovh/v1/$cleanArtist/$cleanTitle');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lyrics = data['lyrics'] as String;
        if (lyrics.isNotEmpty) {
          currentSongLyrics.value = lyrics;
          return;
        }
      }
    } catch (e) {
      print("Lyrics API Error (Ignored)");
    }

    if (description.trim().isNotEmpty) {
      currentSongLyrics.value =
          "Lyrics not found.\n\nVideo Description:\n$description";
    } else {
      currentSongLyrics.value = "Lyrics not found.\n(No description available)";
    }
  }

  String _cleanString(String input) {
    var text = input.toLowerCase();
    text = text.replaceAll(RegExp(r"\(.*?\)"), "");
    text = text.replaceAll(RegExp(r"\[.*?\]"), "");
    text = text.replaceAll("official video", "");
    text = text.replaceAll("official audio", "");
    text = text.replaceAll("lyrics", "");
    text = text.replaceAll("ft.", "");
    return text.trim();
  }

  // --- 5. MODES ---
  void toggleShuffle() async {
    isShuffleMode.value = !isShuffleMode.value;
    await player.setShuffleModeEnabled(isShuffleMode.value);
  }

  void toggleLoop() async {
    if (loopMode.value == LoopMode.off) {
      loopMode.value = LoopMode.all;
      await player.setLoopMode(LoopMode.all);
    } else if (loopMode.value == LoopMode.all) {
      loopMode.value = LoopMode.one;
      await player.setLoopMode(LoopMode.one);
    } else {
      loopMode.value = LoopMode.off;
      await player.setLoopMode(LoopMode.off);
    }
  }
}
