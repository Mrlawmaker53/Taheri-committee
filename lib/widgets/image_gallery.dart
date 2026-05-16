import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/gallery_item.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';

class ImageGallery extends StatelessWidget {
  const ImageGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          // Gallery grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;
              final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
              
              if (isMobile) {
                return _buildMobileGallery();
              } else if (isTablet) {
                return _buildTabletGallery();
              } else {
                return _buildDesktopGallery();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGallery() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Row(
        children: AnimationUtils.staggerAnimation(
          children: GalleryData.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < 2 ? 16 : 0,
                ),
                child: _GalleryCard(
                  item: item,
                  animationType: index == 0 ? 'left' : (index == 1 ? 'bottom' : 'right'),
                ),
              ),
            );
          }).toList(),
          animator: (child, index) {
            return AnimationUtils.fadeInFromBottom(
              duration: const Duration(milliseconds: 800),
              delay: Duration(milliseconds: index * 200),
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabletGallery() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: AnimationUtils.staggerAnimation(
          children: GalleryData.items.asMap().entries.map((entry) {
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key < 2 ? 16 : 0,
              ),
              child: _GalleryCard(
                item: item,
                animationType: 'bottom',
                isWide: true,
              ),
            );
          }).toList(),
          animator: (child, index) {
            return AnimationUtils.fadeInFromBottom(
              duration: const Duration(milliseconds: 800),
              delay: Duration(milliseconds: index * 200),
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileGallery() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: AnimationUtils.staggerAnimation(
          children: GalleryData.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GalleryCard(
                item: item,
                animationType: 'bottom',
              ),
            );
          }).toList(),
          animator: (child, index) {
            return AnimationUtils.fadeInFromBottom(
              duration: const Duration(milliseconds: 800),
              delay: Duration(milliseconds: index * 200),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final GalleryItem item;
  final String animationType;
  final bool isWide;

  const _GalleryCard({
    required this.item,
    required this.animationType,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return HoverAnimation(
      hoverScale: 1.02,
      hoverOffset: -10,
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: _buildImage(),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.galleryTitle,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.description,
                        style: AppTextStyles.galleryDescription,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.assetPath != null) {
      return Image.asset(
        item.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.3),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.image,
                size: 48,
                color: Colors.white54,
              ),
            ),
          );
        },
      );
    } else if (item.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withOpacity(0.3),
                AppColors.accent.withOpacity(0.1),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.accent,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withOpacity(0.3),
                AppColors.accent.withOpacity(0.1),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }
    
    // Fallback placeholder
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.3),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image,
          size: 48,
          color: Colors.white54,
        ),
      ),
    );
  }
}
