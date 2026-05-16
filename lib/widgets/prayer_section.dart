import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';

class PrayerSection extends StatelessWidget {
  const PrayerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollAnimation(
      duration: const Duration(milliseconds: 800),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Arabic text
            Text(
              'الحمد لله الذي هدانا لهذا وما كنا لنهتدي لولا أن هدانا الله\n'
              'اللهم صل على محمد وآل محمد الطيبين الطاهرين',
              style: AppTextStyles.prayerArabic,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Organization
            Text(
              'TAHERI COMMITTEE, DOHAD',
              style: AppTextStyles.prayerOrganization,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Translation
            Text(
              'بسم رب العالمين',
              style: AppTextStyles.prayerTranslation,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
