import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';

class AboutUsSection extends StatelessWidget {
  const AboutUsSection({super.key});

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
                  Icons.info_outline,
                  size: 48,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  'About Us',
                  style: AppTextStyles.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Learn more about our community and mission',
                  style: AppTextStyles.sectionSubtitle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // About cards
          _buildAboutCards(),
        ],
      ),
    );
  }

  Widget _buildAboutCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return _buildMobileCards();
        } else {
          return _buildDesktopCards();
        }
      },
    );
  }

  Widget _buildDesktopCards() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 64),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 24),
              child: _AboutCard(
                imagePath: 'assets/images/community_service.jpg',
                title: 'Community Service',
                description:
                    'Our dedicated volunteers serving visitors with warmth and hospitality every Sunday',
                delay: 0,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: _AboutCard(
                imagePath: 'assets/images/unity_dedication.jpg',
                title: 'Unity & Dedication',
                description:
                    'Working together as one team with dedication and commitment to serve humanity',
                delay: 200,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 24),
              child: _AboutCard(
                imagePath: 'assets/images/spiritual_journey.jpg',
                title: 'Spiritual Journey',
                description:
                    'Creating a peaceful atmosphere for visitors on their spiritual journey to Mazar-e-Fakhri',
                delay: 400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCards() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _AboutCard(
            imagePath: 'assets/images/community_service.jpg',
            title: 'Community Service',
            description:
                'Our dedicated volunteers serving visitors with warmth and hospitality every Sunday',
            delay: 0,
          ),
          SizedBox(height: 20),
          _AboutCard(
            imagePath: 'assets/images/unity_dedication.jpg',
            title: 'Unity & Dedication',
            description:
                'Working together as one team with dedication and commitment to serve humanity',
            delay: 200,
          ),
          SizedBox(height: 20),
          _AboutCard(
            imagePath: 'assets/images/spiritual_journey.jpg',
            title: 'Spiritual Journey',
            description:
                'Creating a peaceful atmosphere for visitors on their spiritual journey to Mazar-e-Fakhri',
            delay: 400,
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final int delay;

  const _AboutCard({
    required this.imagePath,
    required this.title,
    required this.description,
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
                      height: 200,
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
                              size: 64,
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.socialCardTitle.copyWith(
                            color: AppColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: AppTextStyles.aboutContent.copyWith(
                            fontSize: 14,
                            height: 1.5,
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
