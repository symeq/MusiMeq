import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/design_components.dart';
import '../widgets/skeleton_loaders.dart';

// SECTIONS
import '../sections/recent_section.dart';
import '../sections/recommendation_section.dart';
import '../sections/weekly_mix_section.dart'; // ✅ Using the reverted simpler version
import '../sections/news_section.dart';

// SERVICES
import '../services/audio_service.dart';
import '../services/favorites_service.dart';
import '../services/playlist_service.dart';
import '../services/download_service.dart';
import '../services/history_service.dart';
import '../services/news_service.dart';
import 'settings_screen.dart';
import 'dart:math'; // ✅ Needed for Random() in Weekly Mixes

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Services
  final YoutubeExplode _yt = YoutubeExplode();
  final AudioService _audioService = AudioService();
  final FavoritesService _favService = FavoritesService();
  final DownloadService _downloadService = DownloadService();
  final HistoryService _historyService = HistoryService();
  final NewsService _newsService = NewsService();

  // Data
  List<Video> _recentlyPlayed = [];
  List<Video> _recommendations = [];
  List<Video> _weeklyPicks = [];
  List<Map<String, String>> _musicNews = [];

  // UI State
  String _recommendationTitle = "Recommended For You";
  Set<String> _likedIds = {};
  Set<String> _downloadedIds = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var history = await _historyService.getHistory();
    final favs = await _favService.getFavorites();
    final downloads = await _downloadService.getOfflineSongs();

    if (mounted) {
      setState(() {
        _recentlyPlayed = history;
        _likedIds = favs.map((e) => e.id.value).toSet();
        _downloadedIds = downloads.map((s) => s['id'] as String).toSet();
      });
    }

    _fetchSmartRecommendations();
    _fetchWeeklyPicks();
    _fetchNews();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isStrictlyMusic(Video v) {
    final title = v.title.toLowerCase();
    final author = v.author.toLowerCase();

    if (v.duration != null) {
      if (v.duration!.inSeconds < 90) return false; // Too short (TikTok/Intro)
      if (v.duration!.inMinutes > 7) return false; // Too long (Mix/Podcast)
    }

    if (title.contains("full album") ||
        title.contains("compilation") ||
        title.contains("tiktok") ||
        title.contains("shorts") ||
        title.contains("reels") ||
        title.contains("interview") ||
        title.contains("podcast") ||
        title.contains("news") ||
        title.contains("reaction") ||
        title.contains("review") ||
        title.contains("1 hour")) {
      return false;
    }

    bool isOfficial = author.endsWith(" - topic") ||
        author.contains("vevo") ||
        author.contains("official");

    if (!isOfficial) {
      if (!title.contains("official audio") &&
          !title.contains("lyrics") &&
          !title.contains("official video")) {
        return false;
      }
    }
    return true;
  }

  // --- 🕒 LONG MIX FILTER (For Weekly Mixes) ---
  bool _isLongMix(Video v) {
    if (v.duration == null) return false;

    // ✅ MUST be longer than 10 minutes to be considered a "Mix"
    if (v.duration!.inMinutes < 10) return false;

    // Optional: Filter out super long videos (e.g. > 3 hours) if you want
    if (v.duration!.inHours > 3) return false;

    return true;
  }

  // --- 🧠 SMART RECOMMENDATIONS (Guaranteed 15 Songs) ---
  Future<void> _fetchSmartRecommendations() async {
    // 1. FALLBACK FOR EMPTY HISTORY
    if (_recentlyPlayed.isEmpty) {
      try {
        var result =
            await _yt.search.search("Global Top 20 Songs Official Audio");
        var fallbackRecs = <Video>[];

        for (var v in result.whereType<Video>()) {
          if (fallbackRecs.length >= 15) {
            break;
          }
          if (_isStrictlyMusic(v)) {
            fallbackRecs.add(v);
          }
        }

        if (mounted) {
          setState(() {
            _recommendations = fallbackRecs;
            _recommendationTitle = "Recommended For You";
          });
        }
      } catch (e) {
        print("Fallback Error: $e");
      }
      return;
    }

    try {
      final seedVideo = _recentlyPlayed.first;
      var validRecs = <Video>[];
      Set<String> addedIds = {};

      // --- PHASE 1: Related Videos (The best matches) ---
      var relatedVideos = await _yt.videos.getRelatedVideos(seedVideo);

      for (var v in relatedVideos ?? []) {
        if (validRecs.length >= 15) {
          break;
        }
        // Filter out seed video and duplicates
        if (v.id.value == seedVideo.id.value || addedIds.contains(v.id.value)) {
          continue;
        }

        if (_isStrictlyMusic(v)) {
          validRecs.add(v);
          addedIds.add(v.id.value);
        }
      }

      // --- PHASE 2: Artist Search (Deep Search) ---
      if (validRecs.length < 15) {
        var searchList =
            await _yt.search.search("${seedVideo.author} official audio");
        int pageCount = 0;

        // Dig up to 5 pages deep
        while (validRecs.length < 15 && pageCount < 5) {
          for (var v in searchList.whereType<Video>()) {
            if (validRecs.length >= 15) {
              break;
            }
            if (v.id.value == seedVideo.id.value ||
                addedIds.contains(v.id.value)) {
              continue;
            }

            if (_isStrictlyMusic(v)) {
              validRecs.add(v);
              addedIds.add(v.id.value);
            }
          }

          if (validRecs.length < 15) {
            pageCount++;
            var nextBatch = await searchList.nextPage();
            if (nextBatch == null || nextBatch.isEmpty) {
              break;
            }
            searchList = nextBatch;
          }
        }
      }

      // --- PHASE 3: Broad Genre Search (Emergency Fill) ---
      if (validRecs.length < 15) {
        var searchList =
            await _yt.search.search("Best Songs Like ${seedVideo.title}");
        int pageCount = 0;

        while (validRecs.length < 15 && pageCount < 3) {
          for (var v in searchList.whereType<Video>()) {
            if (validRecs.length >= 15) {
              break;
            }
            if (v.id.value == seedVideo.id.value ||
                addedIds.contains(v.id.value)) {
              continue;
            }

            if (_isStrictlyMusic(v)) {
              validRecs.add(v);
              addedIds.add(v.id.value);
            }
          }

          if (validRecs.length < 15) {
            pageCount++;
            var nextBatch = await searchList.nextPage();
            if (nextBatch == null || nextBatch.isEmpty) {
              break;
            }
            searchList = nextBatch;
          }
        }
      }

      // --- PHASE 4: Global Hits (Last Resort) ---
      if (validRecs.length < 15) {
        var searchList = await _yt.search.search("Global Hits Official Audio");
        for (var v in searchList.whereType<Video>()) {
          if (validRecs.length >= 15) {
            break;
          }
          if (v.id.value == seedVideo.id.value ||
              addedIds.contains(v.id.value)) {
            continue;
          }
          if (_isStrictlyMusic(v)) {
            validRecs.add(v);
            addedIds.add(v.id.value);
          }
        }
      }

      if (mounted && validRecs.isNotEmpty) {
        setState(() {
          _recommendations = validRecs;
          _recommendationTitle = "Recommended For You";
        });
      }
    } catch (e) {
      print("Rec Error: $e");
    }
  }

  // --- 🎵 WEEKLY MIXES ENGINE (Guaranteed 7 Long Compilations) ---
  Future<void> _fetchWeeklyPicks() async {
    try {
      final List<String> queries = [
        "Best Pop Songs 2026 Mix",
        "Chill R&B Mix 2026",
        "Workout Hip Hop Mix 2026",
        "Top Rock Hits 2026 Compilation",
        "Focus Study Music Mix 2026",
        "Jazz Relaxing Mix 2026",
        "Top Hits 2026 Full Album",
        "Electronic Dance Music Mix 2026",
        "Malaysian Hits Mix 2026",
      ];

      final query = queries[Random().nextInt(queries.length)];
      print("🔎 Searching Mixes: $query");

      var validMixes = <Video>[];
      int targetCount = 7; // ✅ We want exactly 7

      // --- PHASE 1: Primary Search (Specific Genre) ---
      var searchList = await _yt.search.search(query);
      int pageCount = 0;

      // Dig deeper (up to 5 pages) to find long videos
      while (validMixes.length < targetCount && pageCount < 5) {
        for (var v in searchList) {
          if (validMixes.length >= targetCount) break;

          // Avoid duplicates
          if (validMixes.any((m) => m.id.value == v.id.value)) continue;

          // ✅ USE THE LONG MIX FILTER
          if (_isLongMix(v)) {
            validMixes.add(v);
          }
        }

        // Load next page if needed
        if (validMixes.length < targetCount) {
          pageCount++;
          var nextBatch = await searchList.nextPage();
          if (nextBatch == null || nextBatch.isEmpty) break;
          searchList = nextBatch;
        }
      }

      // --- PHASE 2: Fallback Backfill (Crucial Fix) ---
      // If we found some (e.g. 2), but not enough (7), we switch to a broader query.
      if (validMixes.length < targetCount) {
        print(
            "⚠️ Only found ${validMixes.length} mixes. Switching to Global Fallback...");

        var fallbackList =
            await _yt.search.search("Best Music Mix 2026 Long Playlist");
        int fallbackPage = 0;

        while (validMixes.length < targetCount && fallbackPage < 5) {
          for (var v in fallbackList) {
            if (validMixes.length >= targetCount) break;
            if (validMixes.any((m) => m.id.value == v.id.value)) continue;

            if (_isLongMix(v)) {
              validMixes.add(v);
            }
          }

          if (validMixes.length < targetCount) {
            fallbackPage++;
            var nextBatch = await fallbackList.nextPage();
            if (nextBatch == null || nextBatch.isEmpty) break;
            fallbackList = nextBatch;
          }
        }
      }

      if (mounted) {
        setState(() {
          _weeklyPicks = validMixes;
        });
      }
    } catch (e) {
      print("Weekly Mix Error: $e");
    }
  }

  Future<void> _fetchNews() async {
    try {
      var news = await _newsService.getMusicNews();
      if (mounted) setState(() => _musicNews = news);
    } catch (e) {
      if (mounted) setState(() => _musicNews = []);
    }
  }

  // --- PLAYBACK ---
  void _playAndSave(List<Video> playlist, int index) {
    _audioService.setPlaylist(playlist, index);
    final video = playlist[index];
    _historyService.addToHistory(video);
    setState(() {
      _recentlyPlayed.removeWhere((v) => v.id.value == video.id.value);
      _recentlyPlayed.insert(0, video);
    });
    // We don't refresh recs here to keep UI stable
  }

  // --- UI ACTIONS ---
  Future<void> _toggleLike(Video video) async {
    setState(() {
      if (_likedIds.contains(video.id.value))
        _likedIds.remove(video.id.value);
      else
        _likedIds.add(video.id.value);
    });
    await _favService.toggleFavorite(video);
  }

  void _showSongOptions(Video video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(video.thumbnails.lowResUrl,
                      width: 50, height: 50, fit: BoxFit.cover)),
              title: Text(video.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(video.author,
                  style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: Icon(
                  _likedIds.contains(video.id.value)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _likedIds.contains(video.id.value)
                      ? Colors.redAccent
                      : Colors.white),
              title: Text(
                  _likedIds.contains(video.id.value)
                      ? "Remove from Favorites"
                      : "Add to Favorites",
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _toggleLike(video);
              },
            ),
            ListTile(
              leading: Icon(
                  _downloadedIds.contains(video.id.value)
                      ? Icons.check_circle
                      : Icons.download_rounded,
                  color: AppColors.electricBlue),
              title: Text(
                  _downloadedIds.contains(video.id.value)
                      ? "Downloaded"
                      : "Download Offline",
                  style: const TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Downloading ${video.title}...")));
                await _downloadService.downloadSong(video.id.value);
                _loadData();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.playlist_add_rounded, color: Colors.white),
              title: const Text("Add to Playlist",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _addToPlaylist(video);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToPlaylist(Video video) async {
    final playlists = await PlaylistService().getPlaylists();
    if (!mounted) return;
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Create a playlist first!")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Add to Playlist",
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: playlists.keys
              .map((name) => ListTile(
                    title:
                        Text(name, style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      await PlaylistService().addSongToPlaylist(name, video);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Added to $name")));
                      }
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  // --- HELPER FOR GREETING ---
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 18) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top + 20;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, 
        statusBarIconBrightness: Brightness.light, 
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        body: Column(
          children: [
            // --- HEADER (Kept Static) ---
            Container(
              padding: EdgeInsets.fromLTRB(16, topPadding, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(), // You have this method in your code
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            shadows: [
                              const Shadow(
                                  color: AppColors.electricBlue, blurRadius: 15),
                              Shadow(
                                  color: AppColors.electricBlue.withOpacity(0.5),
                                  blurRadius: 40)
                            ]),
                      ),
                      const Text(
                        "Ready to play?",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: const Icon(Icons.settings,
                          color: Colors.white, size: 24),
                    ),
                  )
                ],
              ),
            ),

            // --- DASHBOARD (GHOST vs REAL) ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: _isLoading 
                  ? _buildSkeletonLoader() // 👻 SHOW GHOSTS
                  : _buildRealContent(),   // 🎵 SHOW MUSIC
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 1. THE GHOST SCREEN
  Widget _buildSkeletonLoader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent Skeleton (Cards)
        SkeletonLoaders.header(),
        SizedBox(
          height: 190, // Matches height of card + text
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3, // Show 3 fake cards
            itemBuilder: (context, index) => SkeletonLoaders.card(),
          ),
        ),

        // Recommendation Skeleton (Rows)
        SkeletonLoaders.header(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(4, (index) => SkeletonLoaders.row()),
          ),
        ),

        // Weekly Mix Skeleton (Rows)
        SkeletonLoaders.header(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(3, (index) => SkeletonLoaders.row()),
          ),
        ),
      ],
    );
  }

  // ✅ 2. THE REAL CONTENT (Your existing code)
  Widget _buildRealContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. RECENT SECTION
        if (_recentlyPlayed.isNotEmpty)
          RecentSection(
            videos: _recentlyPlayed,
            onPlay: (index) => _playAndSave(_recentlyPlayed, index),
            onOption: _showSongOptions,
          ),

        const SizedBox(height: 5),

        // 2. RECOMMENDATIONS
        if (_recommendations.isNotEmpty)
          RecommendationSection(
            title: _recommendationTitle,
            videos: _recommendations,
            onPlay: (video) {
              int index = _recommendations.indexOf(video);
              _playAndSave(_recommendations, index);
            },
            onOption: _showSongOptions,
          ),

        // 3. WEEKLY MIXES
        if (_weeklyPicks.isNotEmpty)
          WeeklyMixSection(
            videos: _weeklyPicks,
            onPlay: (video) => _playAndSave([video], 0),
            onOption: _showSongOptions,
          ),

        // 4. NEWS SECTION
        if (_musicNews.isNotEmpty)
          NewsSection(
            newsList: _musicNews,
            onNewsTap: (url) async {
              final uri = Uri.parse(url);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                throw 'Could not launch $url';
              }
            },
          ),
      ],
    );
  }
}
