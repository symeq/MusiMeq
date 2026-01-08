import 'package:flutter/material.dart';
import '../widgets/design_components.dart'; // Uses AppColors, GlassBottomBar
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'playlists_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const PlaylistsScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MusiBoomBackground(
        child: Stack(
          children: [
            // --- MAIN CONTENT WITH NEON FLICKER ---
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600), // Total flicker time
                reverseDuration: const Duration(milliseconds: 200), // Exit speed
                switchInCurve: Curves.linear,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {

                  
                  final flicker = TweenSequence<double>([
                    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 10),
                    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
                    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 10),
                    TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 20),
                    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 10),
                    TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.0), weight: 30),
                  ]);

                  return FadeTransition(
                    opacity: flicker.animate(animation),
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex), // Critical for animation
                  child: _screens[_selectedIndex],
                ),
              ),
            ),

            // --- BOTTOM BAR ---
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GlassBottomBar(
                selectedIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            ),

            // --- MINI PLAYER ---
             const Positioned(
               left: 16,
               right: 16,
               bottom: 90, // Above the bottom bar
               child: MiniPlayer(),
             ),
          ],
        ),
      ),
    );
  }
}