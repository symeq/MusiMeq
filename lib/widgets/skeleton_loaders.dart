import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'design_components.dart'; // To match your AppColors and GlassCard

class SkeletonLoaders {
  // 1. THE SHIMMER EFFECT WRAPPER
  // Uses your dark theme colors: Dark Glass -> Lighter Glass
  static Widget _shimmer(Widget child) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.15),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }

  // 2. SKELETON CARD (Matches SongTile.card)
  // Geometry: Width 140, Image 140x140 (R16)
  static Widget card() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmer(
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _shimmer(
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _shimmer(
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. SKELETON ROW (Matches SongTile.row)
  // Geometry: Height 80, Image 56x56 (R12)
  static Widget row() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        opacity: 0.05, // Matches your idle state opacity
        borderRadius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _shimmer(
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _shimmer(
                    Container(
                      width: double.infinity,
                      height: 14,
                      margin: const EdgeInsets.only(right: 60),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _shimmer(
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
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

  // 4. HEADER SKELETON (Replaces SectionHeader)
  static Widget header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _shimmer(
            Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          _shimmer(
            Container(
              width: 50,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}