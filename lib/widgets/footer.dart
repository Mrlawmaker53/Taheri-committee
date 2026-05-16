import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
      ),
      child: Column(
        children: [
          Text(
            'Powered by Taheri Committee v1.0',
            style: AppTextStyles.footer,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '© 2026 Taheri Committee, Dohad. All rights reserved.',
            style: AppTextStyles.footer,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
