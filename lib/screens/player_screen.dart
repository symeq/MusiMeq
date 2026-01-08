import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:rxdart/rxdart.dart'; 
import 'package:palette_generator/palette_generator.dart';
import '../services/audio_service.dart';
import '../services/favorites_service.dart';
import '../services/download_service.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  PositionData(this.position, this.bufferedPosition, this.duration);
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // Services
  final AudioService _audioService = AudioService();
  final FavoritesService _favService = FavoritesService();
  final DownloadService _downloadService = DownloadService();
  
  // State
  bool _isLiked = false;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  Color _backgroundColor = const Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _audioService.currentSongId.addListener(_checkStatus);
    _audioService.currentThumbnail.addListener(_updatePalette);
  }

  @override
  void dispose() {
    _audioService.currentSongId.removeListener(_checkStatus);
    _audioService.currentThumbnail.removeListener(_updatePalette);
    super.dispose();
  }

  // --- 🛠️ LOGIC METHODS ---

  Future<void> _updatePalette() async {
    final url = _audioService.currentThumbnail.value;
    if (url.isEmpty) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(url), maximumColorCount: 20,
      );
      if (mounted) {
        setState(() {
          _backgroundColor = palette.mutedColor?.color ?? 
                             palette.dominantColor?.color ?? 
                             const Color(0xFF1E1E1E);
        });
      }
    } catch (e) { print("Palette Error: $e"); }
  }

  Future<void> _checkStatus() async {
    final videoId = _audioService.currentSongId.value;
    if (videoId.isEmpty) return;
    final isFav = await _favService.isFavorite(videoId);
    final isDown = await _downloadService.isDownloaded(videoId);
    if (mounted) setState(() { _isLiked = isFav; _isDownloaded = isDown; });
  }

  Future<void> _handleDownload() async {
    final videoId = _audioService.currentSongId.value;
    if (videoId.isEmpty || _isDownloaded) return;
    setState(() => _isDownloading = true);
    try {
      await _downloadService.downloadSong(videoId);
      if (mounted) setState(() { _isDownloading = false; _isDownloaded = true; });
    } catch (e) {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _toggleLike() async {
    final videoId = _audioService.currentSongId.value;
    if (videoId.isEmpty) return;

    setState(() => _isLiked = !_isLiked);

    try {
      final currentList = _audioService.playlist;
      final index = _audioService.currentIndex;

      if (index >= 0 && index < currentList.length) {
        final realVideo = currentList[index];
        
        await _favService.toggleFavorite(realVideo);
      } else {
        print("⚠️ Could not find video in playlist");
      }
    } catch (e) {
      print("❌ Like Error: $e");
      setState(() => _isLiked = !_isLiked); 
    }
  }

  // --- 📱 MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          _buildDynamicBackground(), // 1. Background
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildHeader(),       // 2. Top Bar
                  const Spacer(flex: 1),
                  _buildAlbumArt(),     // 3. Image
                  const Spacer(flex: 1),
                  _buildSongInfo(),     // 4. Title & Like
                  const SizedBox(height: 20),
                  _buildProgressBar(),  // 5. Slider
                  const SizedBox(height: 10),
                  _buildControls(),     // 6. Play/Pause Buttons
                  const Spacer(flex: 2),
                  _buildBottomTools(),  // 7. Lyrics/Queue
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 🧩 UI HELPER METHODS (Call Methods) ---

  Widget _buildDynamicBackground() {
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 800), 
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_backgroundColor.withOpacity(0.8), Colors.black],
            ),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.3)), // Noise overlay
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        const Text("NOW PLAYING", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2)),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white, size: 30),
          onPressed: _showOptionsMenu,
        ),
      ],
    );
  }

  Widget _buildAlbumArt() {
    return ValueListenableBuilder<String>(
      valueListenable: _audioService.currentThumbnail,
      builder: (context, artworkUrl, _) {
        return Hero(
          tag: 'album_art',
          child: Container(
            height: 320, width: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _backgroundColor.withOpacity(0.6), blurRadius: 40, spreadRadius: -5, offset: const Offset(0, 20))],
              image: artworkUrl.isNotEmpty ? DecorationImage(image: NetworkImage(artworkUrl), fit: BoxFit.cover) : null,
              color: Colors.grey[900],
            ),
            child: artworkUrl.isEmpty ? const Icon(Icons.music_note, size: 80, color: Colors.white54) : null,
          ),
        );
      },
    );
  }

  Widget _buildSongInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: _audioService.currentSongTitle,
                builder: (_, title, __) => Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              ValueListenableBuilder<String>(
                valueListenable: _audioService.currentSongArtist,
                builder: (_, artist, __) => Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _isDownloading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : IconButton(icon: Icon(_isDownloaded ? Icons.check_circle : Icons.download_rounded, color: _isDownloaded ? Colors.greenAccent : Colors.white, size: 26), onPressed: _handleDownload),
            IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.redAccent : Colors.white, size: 28), onPressed: _toggleLike),
          ],
        )
      ],
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<PositionData>(
      stream: Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioService.player.positionStream,
        _audioService.player.bufferedPositionStream,
        _audioService.player.durationStream,
        (position, bufferedPosition, duration) => PositionData(position, bufferedPosition, duration ?? Duration.zero),
      ),
      builder: (context, snapshot) {
        final positionData = snapshot.data ?? PositionData(Duration.zero, Duration.zero, Duration.zero);
        return ProgressBar(
          progress: positionData.position,
          buffered: positionData.bufferedPosition,
          total: positionData.duration,
          onSeek: _audioService.player.seek,
          baseBarColor: Colors.white12,
          bufferedBarColor: Colors.white24,
          progressBarColor: Colors.white,
          thumbColor: Colors.white,
          thumbRadius: 6,
          timeLabelTextStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _audioService.isShuffleMode,
          builder: (context, isShuffle, _) => IconButton(icon: Icon(Icons.shuffle, color: isShuffle ? Colors.greenAccent : Colors.white38, size: 24), onPressed: _audioService.toggleShuffle),
        ),
        IconButton(icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 35), onPressed: _audioService.skipToPrevious),
        StreamBuilder<PlayerState>(
          stream: _audioService.player.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return Container(
              height: 70, width: 70,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: IconButton(
                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 38),
                onPressed: () => playing ? _audioService.player.pause() : _audioService.player.play(),
              ),
            );
          },
        ),
        IconButton(icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 35), onPressed: _audioService.skipToNext),
        ValueListenableBuilder<LoopMode>(
          valueListenable: _audioService.loopMode,
          builder: (context, mode, _) => IconButton(
            icon: Icon(mode == LoopMode.one ? Icons.repeat_one : Icons.repeat, color: mode == LoopMode.off ? Colors.white38 : Colors.greenAccent, size: 24),
            onPressed: _audioService.toggleLoop,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomTools() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(icon: const Icon(Icons.lyrics_outlined, color: Colors.white70), onPressed: _showLyrics),
        IconButton(icon: const Icon(Icons.queue_music_rounded, color: Colors.white70), onPressed: _showQueue),
      ],
    );
  }

  // --- ⚙️ OPTIONS MENU ---
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Options", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // 1. Playback Speed Control
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.white70),
                title: const Text("Playback Speed", style: TextStyle(color: Colors.white)),
                trailing: ValueListenableBuilder<double>(
                  valueListenable: _audioService.playbackSpeed,
                  builder: (context, speed, _) => Text("${speed}x", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSpeedPicker();
                },
              ),

              // 2. Sleep Timer Control
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.white70),
                title: const Text("Sleep Timer", style: TextStyle(color: Colors.white)),
                trailing: ValueListenableBuilder<int?>(
                  valueListenable: _audioService.sleepTimerMinutes,
                  builder: (context, mins, _) => Text(
                    mins == null ? "Off" : "${mins}m", 
                    style: TextStyle(color: mins == null ? Colors.white54 : Colors.greenAccent, fontWeight: FontWeight.bold)
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSleepTimerPicker();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return ListTile(
              title: Text("${speed}x", style: const TextStyle(color: Colors.white)),
              onTap: () {
                _audioService.setSpeed(speed);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showSleepTimerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text("Off", style: TextStyle(color: Colors.redAccent)), onTap: () { _audioService.setSleepTimer(null); Navigator.pop(context); }),
            ListTile(title: const Text("15 Minutes", style: TextStyle(color: Colors.white)), onTap: () { _audioService.setSleepTimer(15); Navigator.pop(context); }),
            ListTile(title: const Text("30 Minutes", style: TextStyle(color: Colors.white)), onTap: () { _audioService.setSleepTimer(30); Navigator.pop(context); }),
            ListTile(title: const Text("60 Minutes", style: TextStyle(color: Colors.white)), onTap: () { _audioService.setSleepTimer(60); Navigator.pop(context); }),
          ],
        );
      },
    );
  }

  void _showQueue() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E).withOpacity(0.95), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.symmetric(vertical: 15), width: 40, height: 4, color: Colors.white30),
          const Text("Up Next", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(child: ValueListenableBuilder<String>(
            valueListenable: _audioService.currentSongId,
            builder: (context, currentId, _) => ListView.builder(
              itemCount: _audioService.playlist.length,
              itemBuilder: (context, index) {
                final video = _audioService.playlist[index];
                final isPlaying = video.id.value == currentId;
                return ListTile(
                  leading: Image.network(video.thumbnails.lowResUrl, width: 40),
                  title: Text(video.title, style: TextStyle(color: isPlaying ? Colors.greenAccent : Colors.white)),
                  onTap: () { Navigator.pop(context); if (!isPlaying) _audioService.jumpToSong(index); },
                );
              },
            ),
          ))
        ]),
      ),
    );
  }

  // --- 🎤 LYRICS SHEET (Fixed Width) ---
  void _showLyrics() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          width: double.infinity, // ✅ FIX: Forces the box to be full width
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)]
          ),
          child: Column(
            children: [
              // Handle Bar
              Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 15), width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)))),
              
              const Text("Lyrics", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Content
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _audioService.currentSongLyrics, 
                  builder: (context, text, _) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity, // ✅ FIX: Ensures text uses full width
                        child: Text(
                          text.isEmpty ? "Lyrics not found." : text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}