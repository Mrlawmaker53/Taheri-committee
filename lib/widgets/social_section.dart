import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';

class SocialSection extends StatelessWidget {
  const SocialSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollAnimation(
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            // Title
            Text(
              'Connect With Us',
              style: AppTextStyles.socialTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Subtitle
            Text(
              'Follow us for updates and announcements',
              style: AppTextStyles.sectionSubtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Social cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;

                if (isMobile) {
                  return _buildMobileCards();
                } else {
                  return _buildDesktopCards();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCards() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 64),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 32),
              child: _SocialCard(
                title: 'Instagram',
                text: 'Follow our journey',
                imagePath: 'assets/images/instagram_card.jpg',
                gradient: AppGradients.instagram,
                url: 'https://instagram.com/taheri_committee',
                delay: 0,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 32),
              child: _SocialCard(
                title: 'WhatsApp',
                text: 'Stay connected',
                imagePath: 'assets/images/whatsapp_card.jpg',
                gradient: AppGradients.whatsapp,
                url: 'https://wa.me/919999999999',
                delay: 200,
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
          _SocialCard(
            title: 'Instagram',
            text: 'Follow our journey',
            imagePath: 'assets/images/instagram_card.jpg',
            gradient: AppGradients.instagram,
            url: 'https://instagram.com/taheri_committee',
            delay: 0,
          ),
          SizedBox(height: 20),
          _SocialCard(
            title: 'WhatsApp',
            text: 'Stay connected',
            imagePath: 'assets/images/whatsapp_card.jpg',
            gradient: AppGradients.whatsapp,
            url: 'https://wa.me/919999999999',
            delay: 200,
          ),
        ],
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  final String title;
  final String text;
  final String imagePath;
  final Gradient gradient;
  final String url;
  final int delay;

  const _SocialCard({
    required this.title,
    required this.text,
    required this.imagePath,
    required this.gradient,
    required this.url,
    required this.delay,
  });

  void _launchUrl() {
    // In a real app, you would use url_launcher package
    print('Launching: $url');
  }

  @override
  Widget build(BuildContext context) {
    return AnimationUtils.scaleIn(
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: delay),
      child: HoverAnimation(
        hoverScale: 1.05,
        hoverOffset: -10,
        child: InkWell(
          onTap: _launchUrl,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Image section
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          gradient.colors.first.withOpacity(0.8),
                          gradient.colors.last.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Placeholder for image
                        Center(
                          child: Icon(
                            title == 'Instagram'
                                ? FontAwesomeIcons.instagram
                                : FontAwesomeIcons.whatsapp,
                            size: 48,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: AppTextStyles.socialCardTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: AppTextStyles.socialCardText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
