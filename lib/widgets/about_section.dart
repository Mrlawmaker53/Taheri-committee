import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollAnimation(
      duration: const Duration(milliseconds: 800),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                // Header
                Text(
                  'About Our Service',
                  style: AppTextStyles.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Content paragraphs
                _buildContentParagraphs(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentParagraphs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        
        return Column(
          children: [
            _buildParagraph(
              'Every Sunday, the Taheri Committee from Dohad travels to Galiyat to perform khidmat at Mazar-e-Fakhri with dedication, unity, and respect. Our volunteers warmly welcome visitors and help create a peaceful and comfortable environment for everyone who comes for ziyarat.',
              isMobile,
            ),
            const SizedBox(height: 24),
            _buildParagraph(
              'With the grace of Moula, our teams continue this noble service year after year. More than 300+ members and multiple volunteer teams work together selflessly to assist visitors and support the activities at the Mazar.',
              isMobile,
            ),
            const SizedBox(height: 24),
            _buildParagraph(
              'Fresh food and refreshments are provided by Mazar-e-Fakhri for all guests and visitors. This khidmat is a symbol of care, unity, and service to humanity. Every volunteer serves with sincerity and gratitude, making each visitor feel welcomed and respected during their visit.',
              isMobile,
            ),
          ],
        );
      },
    );
  }

  Widget _buildParagraph(String text, bool isMobile) {
    return Text(
      text,
      style: AppTextStyles.aboutContent.copyWith(
        fontSize: isMobile ? 15 : 16,
      ),
      textAlign: TextAlign.center,
    );
  }
}
