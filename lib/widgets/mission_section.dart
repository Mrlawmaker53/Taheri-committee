import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/mission_item.dart';
import '../models/mission_image_item.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';

class MissionSection extends StatelessWidget {
  const MissionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          // Header
          ScrollAnimation(
            duration: const Duration(milliseconds: 800),
            child: Column(
              children: [
                const Icon(
                  Icons.card_giftcard,
                  size: 48, // 3rem
                  color: AppColors.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Our Mission',
                  style: AppTextStyles.missionTitle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Intro paragraph
          ScrollAnimation(
            duration: const Duration(milliseconds: 800),
            startOffset: const Offset(0, 0.2),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 64),
              padding: const EdgeInsets.all(32),
              child: Text(
                'Every Sunday, the Taheri Committee from Dohad travels to Galiyat to perform khidmat at Mazar-e-Fakhri with dedication, unity, and respect.',
                style: AppTextStyles.missionIntro,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Mission image cards
          _buildMissionImageCards(),
          const SizedBox(height: 40),

          // Original mission items
          _buildMissionItems(),
        ],
      ),
    );
  }

  Widget _buildMissionImageCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return _buildMobileImageCards();
        } else {
          return _buildDesktopImageCards();
        }
      },
    );
  }

  Widget _buildDesktopImageCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Row(
        children: MissionImageData.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < 2 ? 24 : 0,
                left: index > 0 ? 12 : 0,
              ),
              child: _MissionImageCard(
                item: item,
                delay: index * 200,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileImageCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: MissionImageData.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < 2 ? 20 : 0),
            child: _MissionImageCard(
              item: item,
              delay: index * 200,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMissionItems() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 64),
          child: Column(
            children: AnimationUtils.staggerAnimation(
              children: MissionData.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index < MissionData.items.length - 1 ? 16 : 0),
                  child: _MissionItemCard(
                    item: item,
                    delay: index * 100,
                  ),
                );
              }).toList(),
              animator: (child, index) {
                return AnimationUtils.slideInFromLeft(
                  duration: const Duration(milliseconds: 800),
                  delay: Duration(milliseconds: index * 100),
                  child: child,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _MissionImageCard extends StatelessWidget {
  final MissionImageItem item;
  final int delay;

  const _MissionImageCard({
    required this.item,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationUtils.scaleIn(
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: delay),
      child: HoverAnimation(
        hoverScale: 1.05,
        hoverOffset: -10,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent.withOpacity(0.3),
                            AppColors.gradientStart.withOpacity(0.2),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Placeholder for image
                          Center(
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: AppColors.accent.withOpacity(0.5),
                            ),
                          ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTextStyles.socialCardTitle.copyWith(
                            color: AppColors.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: AppTextStyles.aboutContent.copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionItemCard extends StatelessWidget {
  final MissionItem item;
  final int delay;

  const _MissionItemCard({
    required this.item,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return HoverAnimation(
      hoverScale: 1.02,
      hoverOffset: -5,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),

                // Text
                Expanded(
                  child: Text(
                    item.text,
                    style: AppTextStyles.missionItem,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
