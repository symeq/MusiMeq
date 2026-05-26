import 'dart:ui';
import 'package:flutter/material.dart';

// --- 1. THE NEON COLOR PALETTE ---
class AppColors {
  static const Color background = Color(0xFF0A0A12); // Deepest Dark
  static const Color electricBlue = Color(0xFF00D4FF);
  static const Color neonMagenta = Color(0xFFFF2D92);
  static const Color vibrantGreen = Color(0xFF00FF7F);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [electricBlue, neonMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// --- 2. THE ANIMATED BACKGROUND WRAPPER ---
class MusiMeqBackground extends StatelessWidget {
  final Widget child;
  const MusiMeqBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.background),
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.electricBlue.withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withOpacity(0.4),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonMagenta.withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonMagenta.withOpacity(0.4),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.transparent),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

// --- 3. THE GLASS CARD ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.opacity = 0.1,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// --- 4. NEON BUTTON ---
class NeonButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;

  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.electricBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5. SECTION HEADER ---
class SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText = "See All",
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText,
                style: const TextStyle(
                  color: AppColors.electricBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- 6. ANIMATED BACKGROUND (Drifting Orbs) ---
class AnimatedMusiMeqBackground extends StatefulWidget {
  final Widget child;
  const AnimatedMusiMeqBackground({super.key, required this.child});

  @override
  State<AnimatedMusiMeqBackground> createState() =>
      _AnimatedMusiMeqBackgroundState();
}

class _AnimatedMusiMeqBackgroundState extends State<AnimatedMusiMeqBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.background),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              top: -100 + (_controller.value * 150),
              left: -100 + (_controller.value * 100),
              child: child!,
            );
          },
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.electricBlue.withOpacity(0.25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withOpacity(0.3),
                  blurRadius: 120,
                  spreadRadius: 60,
                ),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              bottom: -100 + (_controller.value * 100),
              right: -100 + (_controller.value * 150),
              child: child!,
            );
          },
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonMagenta.withOpacity(0.25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonMagenta.withOpacity(0.3),
                  blurRadius: 120,
                  spreadRadius: 60,
                ),
              ],
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(color: Colors.transparent),
        ),
        SafeArea(child: widget.child),
      ],
    );
  }
}

// --- 7. GLASS BOTTOM NAVIGATION BAR ---
class GlassBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const GlassBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      opacity: 0.2,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, "Home", 0),
          _buildNavItem(Icons.search_rounded, "Search", 1),
          _buildNavItem(Icons.favorite_rounded, "Library", 2),
          _buildNavItem(Icons.queue_music_rounded, "Playlists", 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    final primaryColor = AppColors.electricBlue;
    final mutedColor = Colors.white.withOpacity(0.5);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? primaryColor : mutedColor,
              shadows: isSelected
                  ? [
                      Shadow(
                          color: primaryColor.withOpacity(0.6), blurRadius: 8)
                    ]
                  : [],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? primaryColor : mutedColor,
              ),
            ),
            const SizedBox(height: 4),
            isSelected
                ? Container(
                    width: 20,
                    height: 2,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                : const SizedBox(height: 2, width: 20),
          ],
        ),
      ),
    );
  }
}

// --- 8. GLASS SEARCH BAR ---
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onSubmitted;
  final VoidCallback? onSuffixTap;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      opacity: 0.1,
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        cursorColor: AppColors.electricBlue,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: AppColors.electricBlue),
          suffixIcon: onSuffixTap != null
              ? IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: onSuffixTap,
                )
              : null,
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

// --- 9. SMART ALBUM ART ---
class AlbumArt extends StatelessWidget {
  final String url;
  final double size;
  final double borderRadius;

  const AlbumArt({
    super.key,
    required this.url,
    this.size = 50,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Colors.white.withOpacity(0.1),
          child: Icon(Icons.music_note,
              color: Colors.white.withOpacity(0.5), size: size * 0.5),
        ),
      ),
    );
  }
}

// --- 10. NEON IGNITION ANIMATION (Added!) ---
class NeonFlickerRoute extends PageRouteBuilder {
  final Widget page;

  NeonFlickerRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration:
              const Duration(milliseconds: 700), // Time to "ignite"
          reverseTransitionDuration:
              const Duration(milliseconds: 300), // Faster exit
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // This sequence mimics a cold neon tube starting up:
            // Off -> Flash -> Dim -> Flash -> Stabilize
            var flickerTween = TweenSequence<double>([
              TweenSequenceItem(
                  tween: Tween(begin: 0.0, end: 0.0), weight: 1), // Start Black
              TweenSequenceItem(
                  tween: Tween(begin: 0.0, end: 0.8), weight: 5), // ⚡ FLASH 1
              TweenSequenceItem(
                  tween: Tween(begin: 0.8, end: 0.2), weight: 10), // Dim out
              TweenSequenceItem(
                  tween: Tween(begin: 0.2, end: 1.0), weight: 15), // ⚡ FLASH 2
              TweenSequenceItem(
                  tween: Tween(begin: 1.0, end: 0.6),
                  weight: 10), // Flicker dim
              TweenSequenceItem(
                  tween: Tween(begin: 0.6, end: 1.0),
                  weight: 60), // Stabilize ON
            ]);

            return FadeTransition(
              opacity: flickerTween.animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            );
          },
        );
}
