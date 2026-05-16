import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';

class HeroSection extends StatelessWidget {
  final String logoPath;
  final VoidCallback? onSignInPressed;

  const HeroSection({
    super.key,
    this.logoPath = 'assets/home_page_right_side.png',
    this.onSignInPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationUtils.fadeInFromBottom(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        padding: const EdgeInsets.all(64),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;

            if (isMobile) {
              return _buildMobileLayout();
            } else {
              return _buildDesktopLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Logo image
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              logoPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.2),
                      AppColors.accent.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.mosque,
                    color: AppColors.accent,
                    size: 80,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Text content
        _buildTextContent(isCentered: true),
        const SizedBox(height: 40),

        // Sign In Button
        _buildSignInButton(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo image
        Expanded(
          flex: 1,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                logoPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.2),
                        AppColors.accent.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.mosque,
                      color: AppColors.accent,
                      size: 80,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 64),

        // Text content and button
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextContent(isCentered: false),
              const SizedBox(height: 40),
              _buildSignInButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextContent({required bool isCentered}) {
    return Column(
      children: [
        // Title
        Text(
          'Mazar-e-Fakhri',
          style: AppTextStyles.heroTitle,
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 16),

        // Subtitle
        Text(
          'Taheri Committee, Dohad',
          style: AppTextStyles.heroSubtitle,
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 16),

        // Tagline
        Text(
          'Serving with dedication and unity every Sunday',
          style: AppTextStyles.heroTagline,
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return HoverAnimation(
      hoverScale: 1.05,
      hoverOffset: -5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onSignInPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: 48,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.rightToBracket,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Sign In',
                style: AppTextStyles.buttonText.copyWith(
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
