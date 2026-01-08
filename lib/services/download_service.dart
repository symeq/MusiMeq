import 'dart:async';  // Add this for timeout
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadService {
  static final YoutubeExplode _yt = YoutubeExplode(); 
  static const _storageKey = 'offline_songs_data';
  static const int _maxCacheSize = 20; 

  Future<String> _getFilePath(String videoId) async {
    final directory = await getApplicationDocumentsDirectory();
    // Use .mp4 for muxed streams
    return '${directory.path}/$videoId.mp4'; 
  }

  Future<bool> isDownloaded(String videoId) async {
    final path = await _getFilePath(videoId);
    final file = File(path);
    // Check if file exists AND has valid data (> 50KB)
    return await file.exists() && (await file.length()) > 50000;
  }

  Future<void> autoCacheSong(Video video) async {
    final prefs = await SharedPreferences.getInstance();
    bool isSmartDownloadOn = prefs.getBool('smart_download_enabled') ?? false; 

    if (!isSmartDownloadOn) return; // Stop here if setting is OFF

    if (await isDownloaded(video.id.value)) return;
    await _performDownload(video, isManual: false);
    await _enforceCacheLimit();
  }

  Future<void> downloadSong(String videoId) async {
    try {
      var video = await _yt.videos.get(videoId);
      if (await isDownloaded(videoId)) {
        await _updateToManual(videoId);
        print("✅ Converted to permanent: ${video.title}");
        return;
      }
      await _performDownload(video, isManual: true);
    } catch (e) {
      print("❌ Manual Fetch Error: $e");
    }
  }

  // UPDATED: Use ONLY muxed streams for reliability, with enhanced debugging and timeout
  Future<void> _performDownload(Video video, {required bool isManual}) async {
    final savePath = await _getFilePath(video.id.value);
    final tempFile = File('$savePath.tmp');
    IOSink? fileSink;

    try {
      print("💾 START ${isManual ? 'Download' : 'Cache'}: ${video.title}...");

      var manifest = await _yt.videos.streamsClient.getManifest(video.id.value);
      
      // USE MUXED STREAMS ONLY (video + audio combined)
      var streamInfo = manifest.muxed.sortByBitrate().first;  // Lowest bitrate for smaller size
      print("ℹ️ Using MUXED stream: ${streamInfo.container.name} (${streamInfo.size.totalBytes / 1024 / 1024} MB)");

      var stream = _yt.videos.streamsClient.get(streamInfo);
      fileSink = tempFile.openWrite();

      // DOWNLOAD LOOP WITH TIMEOUT AND FORCED PROGRESS
      int totalBytes = streamInfo.size.totalBytes;
      int receivedBytes = 0;
      int lastPrint = 0;
      int chunkCount = 0;
      bool downloadComplete = false;

      // Timeout: Cancel after 5 minutes if no progress
      Timer timeout = Timer(Duration(minutes: 5), () {
        if (!downloadComplete) {
          print("⏰ Download timed out after 5 minutes.");
          throw Exception("Download timeout");
        }
      });

      // Force progress print every 5 seconds
      Timer.periodic(Duration(seconds: 5), (timer) {
        if (!downloadComplete) {
          print("🔄 Forced progress check: $chunkCount chunks, ${receivedBytes} bytes received");
        } else {
          timer.cancel();
        }
      });

      await for (var chunk in stream) {
        fileSink.add(chunk);
        receivedBytes += chunk.length;
        chunkCount++;

        // Debug: Print every 100 chunks
        if (chunkCount % 100 == 0) {
          print("🔄 Chunk $chunkCount received: ${receivedBytes} bytes so far");
        }

        if (totalBytes > 0) {
          int percentage = ((receivedBytes / totalBytes) * 100).ceil();
          if (percentage >= lastPrint + 10) {
            print(" ⬇️ Downloading: $percentage%");
            lastPrint = percentage;
          }
        }

        // Check if download is complete
        if (receivedBytes >= totalBytes && totalBytes > 0) {
          downloadComplete = true;
          break;
        }
      }

      timeout.cancel();  // Cancel timeout if successful
      print("🔚 Download loop ended. Total received: ${receivedBytes} bytes, Chunks: $chunkCount");

      await fileSink.flush();
      await fileSink.close();
      fileSink = null;

      // VALIDATE
      if (receivedBytes < 100000) {  // Less than 100KB? Failed
        print("❌ Download incomplete: Only ${receivedBytes} bytes received.");
        if (await tempFile.exists()) await tempFile.delete();
        return;
      }

      // RENAME FILE
      if (await File(savePath).exists()) {
        await File(savePath).delete();
      }
      await tempFile.rename(savePath);

      await _saveMetadata(video, isManual);
      print("✅ DOWNLOAD COMPLETE: ${video.title} (${receivedBytes / 1024 / 1024} MB) - Muxed");

    } catch (e) {
      print("❌ DOWNLOAD FAILED: $e");
      if (await tempFile.exists()) await tempFile.delete();
    } finally {
      if (fileSink != null) await fileSink.close();
    }
  }

  // --- STORAGE HELPERS ---
  Future<void> _saveMetadata(Video video, bool isManual) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineList = prefs.getStringList(_storageKey) ?? [];
    
    offlineList.removeWhere((item) => jsonDecode(item)['id'] == video.id.value);

    Map<String, dynamic> songData = {
      'id': video.id.value,
      'title': video.title,
      'author': video.author,
      'thumbnail': video.thumbnails.highResUrl,
      'duration': video.duration?.inSeconds ?? 0,
      'date': DateTime.now().toIso8601String(),
      'isManual': isManual,
    };

    offlineList.add(jsonEncode(songData));
    await prefs.setStringList(_storageKey, offlineList);
  }

  Future<void> _updateToManual(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineList = prefs.getStringList(_storageKey) ?? [];
    
    int index = offlineList.indexWhere((item) => jsonDecode(item)['id'] == videoId);
    if (index != -1) {
      var map = jsonDecode(offlineList[index]);
      map['isManual'] = true;
      offlineList[index] = jsonEncode(map);
      await prefs.setStringList(_storageKey, offlineList);
    }
  }

  Future<void> _enforceCacheLimit() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineList = prefs.getStringList(_storageKey) ?? [];
    
    List<Map<String, dynamic>> cachedSongs = [];
    for (var item in offlineList) {
      var map = jsonDecode(item);
      if (map['isManual'] == false) cachedSongs.add(map);
    }

    if (cachedSongs.length > _maxCacheSize) {
      int itemsToDelete = cachedSongs.length - _maxCacheSize;
      for (int i = 0; i < itemsToDelete; i++) {
        String idToDelete = cachedSongs[i]['id'];
        final path = await _getFilePath(idToDelete);
        final file = File(path);
        if (await file.exists()) await file.delete();
        offlineList.removeWhere((item) => jsonDecode(item)['id'] == idToDelete);
        print("🧹 Auto-Cleaned: $idToDelete");
      }
      await prefs.setStringList(_storageKey, offlineList);
    }
  }

  Future<List<Map<String, dynamic>>> getOfflineSongs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineList = prefs.getStringList(_storageKey) ?? [];
    List<Map<String, dynamic>> validSongs = [];
    
    for (var item in offlineList) {
      final map = jsonDecode(item);
      if (await isDownloaded(map['id'])) {
        validSongs.add(map);
      }
    }
    return validSongs.reversed.toList();
  }

  Future<void> removeDownload(String videoId) async {
    final path = await _getFilePath(videoId);
    final file = File(path);
    if (await file.exists()) await file.delete();

    final prefs = await SharedPreferences.getInstance();
    List<String> offlineList = prefs.getStringList(_storageKey) ?? [];
    offlineList.removeWhere((item) => jsonDecode(item)['id'] == videoId);
    await prefs.setStringList(_storageKey, offlineList);
  }

  // --- STORAGE MANAGEMENT NEW METHODS ---

  // 1. Calculate Total Usage (MB) - UPDATED: Focus on .mp4 for muxed
  Future<String> getStorageUsage() async {
    final directory = await getApplicationDocumentsDirectory();
    int totalBytes = 0;
    try {
      if (await directory.exists()) {
        final List<FileSystemEntity> files = directory.listSync();
        for (var file in files) {
          // Count only our music files (.mp4 for muxed)
          if (file is File && file.path.endsWith('.mp4')) {
            totalBytes += await file.length();
          }
        }
      }
    } catch (e) {
      print("Error calculating size: $e");
    }
    
    double mb = totalBytes / (1024 * 1024);
    if (mb < 1) return "${(totalBytes / 1024).toStringAsFixed(0)} KB";
    return "${mb.toStringAsFixed(1)} MB";
  }

  // 2. Clear Only Smart Cache (Keep Manual Downloads)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineList = prefs.getStringList(_storageKey) ?? [];
    List<String> keptList = [];

    for (var item in offlineList) {
      final map = jsonDecode(item);
      if (map['isManual'] == true) {
        keptList.add(item); // Keep this one
      } else {
        // Delete the file
        final path = await _getFilePath(map['id']);
        final file = File(path);
        if (await file.exists()) await file.delete();
        print("🧹 Cleared cache item: ${map['title']}");
      }
    }
    // Save the filtered list back
    await prefs.setStringList(_storageKey, offlineList);
  }

  // 3. Delete Everything
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineList = prefs.getStringList(_storageKey) ?? [];
    
    // Delete every file in the database
    for (var item in offlineList) {
      final map = jsonDecode(item);
      final path = await _getFilePath(map['id']);
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    
    // Wipe the database
    await prefs.remove(_storageKey);
    print("💥 All downloads wiped.");
  }
}