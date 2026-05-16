import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 64,
            vertical: 40,
          ),
          child: Column(
            children: [
              // Stats cards
              isMobile 
                ? _buildMobileStats()
                : _buildDesktopStats(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: AnimationUtils.staggerAnimation(
        children: [
          const _StatCard(
            icon: Icons.people,
            number: '300+',
            label: 'Members',
            delay: 0,
          ),
          const _StatCard(
            icon: Icons.card_giftcard,
            number: '15+',
            label: 'Teams',
            delay: 100,
          ),
          const _StatCard(
            icon: Icons.notifications,
            number: '5+',
            label: 'Years',
            delay: 200,
          ),
        ],
        animator: (child, index) {
          return AnimationUtils.scaleIn(
            duration: const Duration(milliseconds: 600),
            delay: Duration(milliseconds: index * 100),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildMobileStats() {
    return Column(
      children: AnimationUtils.staggerAnimation(
        children: [
          const _StatCard(
            icon: Icons.people,
            number: '300+',
            label: 'Members',
            delay: 0,
          ),
          const SizedBox(height: 20),
          const _StatCard(
            icon: Icons.card_giftcard,
            number: '15+',
            label: 'Teams',
            delay: 100,
          ),
          const SizedBox(height: 20),
          const _StatCard(
            icon: Icons.notifications,
            number: '5+',
            label: 'Years',
            delay: 200,
          ),
        ],
        animator: (child, index) {
          return AnimationUtils.scaleIn(
            duration: const Duration(milliseconds: 600),
            delay: Duration(milliseconds: index * 100),
            child: child,
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return HoverAnimation(
      hoverScale: 1.1,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 48, // 3rem
                  color: AppColors.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  number,
                  style: AppTextStyles.statsNumber,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTextStyles.statsLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
