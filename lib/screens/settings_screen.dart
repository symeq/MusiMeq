import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ For Status Bar
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/design_components.dart'; // Uses GlassCard & AppColors
import '../services/download_service.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DownloadService _downloadService = DownloadService();
  bool _isSmartDownloadEnabled = false;
  String _storageUsed = "Calculating...";

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _refreshStorageInfo();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSmartDownloadEnabled = prefs.getBool('smart_download_enabled') ?? false;
    });
  }

  Future<void> _refreshStorageInfo() async {
    String usage = await _downloadService.getStorageUsage();
    if (mounted) {
      setState(() {
        _storageUsed = usage;
      });
    }
  }

  Future<void> _toggleSmartDownload(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_download_enabled', value);
    setState(() {
      _isSmartDownloadEnabled = value;
    });
  }

  // --- CUTE ACTIONS ---
  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Tidy Up? ✨", style: TextStyle(color: Colors.white)),
        content: const Text(
          "We'll sweep away the temporary songs to make room! Don't worry, your manual downloads stay safe. 💖",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nah, keep 'em", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _downloadService.clearCache();
              _refreshStorageInfo(); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All clean and shiny! ✨🧹"),
                  backgroundColor: AppColors.electricBlue,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("Yes, Sweep!", style: TextStyle(color: AppColors.electricBlue)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Start Fresh? 🌱", style: TextStyle(color: Colors.white)),
        content: const Text(
          "This will remove EVERY song from your library. Are you sure you want a blank slate?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Wait, no!", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _downloadService.clearAll();
              _refreshStorageInfo(); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Poof! Library is empty. Time to discover new tunes! 🎶"),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("Wipe Everything", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        body: Stack(
          children: [
            // --- 1. BACKGROUND GLOW ---
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonMagenta.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonMagenta.withOpacity(0.1),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // --- 2. MAIN CONTENT ---
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: GlassCard(
                            borderRadius: 50,
                            opacity: 0.1,
                            padding: const EdgeInsets.all(10),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Settings",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SCROLLABLE LIST
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // --- PREFERENCES ---
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 10),
                          child: Text("MY PREFERENCES", style: TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                        ),
                        
                        GlassCard(
                          borderRadius: 20,
                          opacity: 0.05,
                          padding: EdgeInsets.zero,
                          child: SwitchListTile(
                            activeColor: AppColors.electricBlue,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: const Text(
                              "Smart Download",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Automatically save songs you listen to 🎧",
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                            ),
                            value: _isSmartDownloadEnabled,
                            onChanged: _toggleSmartDownload,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // --- STORAGE ---
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 10),
                          child: Text("STORAGE SPACE", style: TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                        ),

                        GlassCard(
                          borderRadius: 20,
                          opacity: 0.05,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Usage Stat
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.sd_storage_rounded, color: Colors.white70),
                                      SizedBox(width: 12),
                                      Text("Space Used", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.vibrantGreen.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.vibrantGreen.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      _storageUsed, 
                                      style: const TextStyle(color: AppColors.vibrantGreen, fontWeight: FontWeight.bold, fontSize: 14)
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 30),

                              // Clear Cache Button
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("Tidy Up Cache", style: TextStyle(color: Colors.white)),
                                subtitle: const Text("Clears temporary files 🧹", style: TextStyle(color: Colors.white38, fontSize: 12)),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                                onTap: _confirmClearCache,
                              ),

                              // Delete All Button
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("Reset Library", style: TextStyle(color: Colors.redAccent)),
                                subtitle: const Text("Deletes all songs 🗑️", style: TextStyle(color: Colors.white38, fontSize: 12)),
                                trailing: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                                onTap: _confirmDeleteAll,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                        
                        // FOOTER
                        Center(
                          child: Column(
                            children: [
                              Text("MusiBoom v1.0.0", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                              const SizedBox(height: 4),
                              Text("Made with 💙", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}