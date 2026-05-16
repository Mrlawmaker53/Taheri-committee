import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/widgets/glass_card.dart';
import '../core/controllers/auth_controller.dart';
import '../core/controllers/theme_controller.dart';
import '../features/auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _starCtrl;
  late AnimationController _scrollAnimCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _starAnim;
  late ScrollController _scrollController;

  final List<Star> _stars = [];
  bool _showAppBar = false;

  @override
  void initState() {
    super.initState();

    // Check authentication
    final authController = Get.find<AuthController>();
    if (!authController.isLoggedIn.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.off(() => const LoginScreen(), transition: Transition.fadeIn);
      });
      return;
    }

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _scrollAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _starAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_starCtrl);

    // Initialize stars
    _initializeStars();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_showAppBar) {
      setState(() => _showAppBar = true);
      _scrollAnimCtrl.forward();
    } else if (_scrollController.offset <= 100 && _showAppBar) {
      setState(() => _showAppBar = false);
      _scrollAnimCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _entryCtrl.dispose();
    _starCtrl.dispose();
    _scrollAnimCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeStars() {
    final random = Random();
    for (int i = 0; i < 100; i++) {
      _stars.add(
        Star(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 2 + 0.5,
          speed: random.nextDouble() * 0.5 + 0.1,
          opacity: random.nextDouble() * 0.8 + 0.2,
        ),
      );
    }
  }

  void _goToLogin() {
    Get.to(
      () => const LoginScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _launchUrl(String url) {
    // In a real app, you would use url_launcher package
    print('Launching: $url');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 700;
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0A09) : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.4,
                  colors: [
                    Color(0xFF047857),
                    Color(0xFF0C0A09),
                    Color(0xFF1C1917)
                  ],
                  stops: [0.0, 0.55, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF047857),
                    Color(0xFF047857),
                    Color(0xFF0D47A1),
                  ],
                ),
        ),
        child: Stack(
          children: [
            // Fixed background elements (only in dark mode)
            if (isDark) ...[
              _buildAnimatedStars(size),
              _buildOrbs(size),
            ],

            // Animated AppBar on scroll
            _buildAnimatedAppBar(),

            SafeArea(
              child: Column(
                children: [
                  // Static top nav when not scrolled
                  if (!_showAppBar) _buildTopBar(),

                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: _buildMainContent(isWide, size),
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

  Widget _buildAnimatedAppBar() {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return AnimatedBuilder(
      animation: _scrollAnimCtrl,
      builder: (context, child) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: _showAppBar ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF0C0A09).withOpacity(0.95),
                          const Color(0xFF0C0A09).withOpacity(0.8),
                        ]
                      : [
                          const Color(0xFF047857).withOpacity(0.95),
                          const Color(0xFF047857).withOpacity(0.8),
                        ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.mosque,
                        color: Color(0xFF059669),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'TAHERI COMMITTEE',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      _buildLoginButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.mosque,
            color: Color(0xFF059669),
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            'TAHERI COMMITTEE',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const Spacer(),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    if (isDark) {
      return GlassButton(
        width: 100,
        height: 38,
        accentColor: const Color(0xFF059669),
        onTap: _goToLogin,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.rightToBracket,
              color: Colors.white,
              size: 13,
            ),
            SizedBox(width: 6),
            Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: _goToLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.rightToBracket,
              color: Colors.white,
              size: 13,
            ),
            SizedBox(width: 6),
            Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMainContent(bool isWide, Size size) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 32.0 : 16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              _buildHeroSection(size, isWide),
              const SizedBox(height: 40),
              _buildStatsSection(isWide),
              const SizedBox(height: 40),
              _buildAboutUsSection(),
              const SizedBox(height: 40),
              _buildSocialSection(),
              const SizedBox(height: 40),
              _buildMissionSection(),
              const SizedBox(height: 40),
              _buildFooter(),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(Size size, bool isWide) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Column(
      children: [
        // Main hero content
        if (isDark)
          GlassCard(
            padding: EdgeInsets.all(isWide ? 40 : 24),
            opacity: 0.08,
            child: _buildHeroContent(),
          )
        else
          Container(
            padding: EdgeInsets.all(isWide ? 40 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildHeroContent(),
          ),
      ],
    );
  }

  Widget _buildHeroContent() {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Mosque icon with glow
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF059669).withOpacity(0.2),
                const Color(0xFF047857).withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF059669).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.mosque,
              color: Color(0xFF059669),
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Mazar-e-Fakhri',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle
        const Text(
          'Taheri Committee, Dohad',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF059669),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Tagline
        Text(
          'Serving with dedication and unity every Sunday',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.white.withOpacity(0.9),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // Sign In Button
        _buildLoginButton(),
      ],
    );
  }

  Widget _buildStatsSection(bool isWide) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    if (isWide) {
      return Row(
        children: [
          Expanded(child: _buildStatsCard()),
          const SizedBox(width: 16),
          Expanded(child: _buildPrayerBlock()),
        ],
      );
    } else {
      return Column(
        children: [
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildPrayerBlock(),
        ],
      );
    }
  }

  Widget _buildAboutUsSection() {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return isDark
        ? const GlassCard(
            padding: EdgeInsets.all(24),
            opacity: 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _AboutCard(
                        imagePath: 'assets/images/community_service.jpg',
                        title: 'Community Service',
                        description:
                            'Our dedicated volunteers serving visitors with warmth and hospitality every Sunday',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _AboutCard(
                        imagePath: 'assets/images/unity_dedication.jpg',
                        title: 'Unity & Dedication',
                        description:
                            'Working together as one team with dedication and commitment to serve humanity',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _AboutCard(
                        imagePath: 'assets/images/spiritual_journey.jpg',
                        title: 'Spiritual Journey',
                        description:
                            'Creating a peaceful atmosphere for visitors on their spiritual journey to Mazar-e-Fakhri',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        : Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _AboutCard(
                        imagePath: 'assets/images/community_service.jpg',
                        title: 'Community Service',
                        description:
                            'Our dedicated volunteers serving visitors with warmth and hospitality every Sunday',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _AboutCard(
                        imagePath: 'assets/images/unity_dedication.jpg',
                        title: 'Unity & Dedication',
                        description:
                            'Working together as one team with dedication and commitment to serve humanity',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _AboutCard(
                        imagePath: 'assets/images/spiritual_journey.jpg',
                        title: 'Spiritual Journey',
                        description:
                            'Creating a peaceful atmosphere for visitors on their spiritual journey to Mazar-e-Fakhri',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  Widget _buildSocialSection() {
    final themeController = Get.find<ThemeController>();

    return themeController.isDark
        ? GlassCard(
            padding: const EdgeInsets.all(24),
            opacity: 0.08,
            child: _buildSocialContent(),
          )
        : Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSocialContent(),
          );
  }

  Widget _buildSocialContent() {
    return Column(
      children: [
        const Text(
          'Connect With Us',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF059669),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SocialImageCard(
              title: 'Instagram',
              text: 'Follow our journey',
              imagePath: 'assets/images/instagram_card.jpg',
              onTap: () => _launchUrl('https://instagram.com/taheri_committee'),
            ),
            _SocialImageCard(
              title: 'WhatsApp',
              text: 'Stay connected',
              imagePath: 'assets/images/whatsapp_card.jpg',
              onTap: () => _launchUrl('https://wa.me/919999999999'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Follow us for updates and announcements',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionSection() {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(24),
            opacity: 0.08,
            child: _buildMissionContent(),
          )
        : Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildMissionContent(),
          );
  }

  Widget _buildMissionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.mosque,
                  color: Color(0xFF059669),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Our Mission',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Every Sunday, the Taheri Committee from Dohad travels to Galiyat to perform khidmat at Mazar-e-Fakhri with dedication, unity, and respect.',
          style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
        ),
        const SizedBox(height: 20),
        _MissionItem(
          icon: FontAwesomeIcons.calendarDay,
          text: 'Serving visitors every Sunday with dedication and respect',
        ),
        _MissionItem(
          icon: FontAwesomeIcons.handsPraying,
          text: 'Performing khidmat during Ashara Mubarak and Urs Mubarak',
        ),
        _MissionItem(
          icon: FontAwesomeIcons.peopleGroup,
          text: 'Assisting guests and families during their visit',
        ),
      ],
    );
  }

  Widget _buildAnimatedStars(Size size) {
    return AnimatedBuilder(
      animation: _starAnim,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: StarPainter(_stars, _starAnim.value),
        );
      },
    );
  }

  Widget _buildOrbs(Size size) {
    return Stack(
      children: [
        const Positioned(
          top: -80,
          left: -60,
          child: _Orb(220, Color(0xFF047857), 0.25),
        ),
        Positioned(
          bottom: size.height * 0.15,
          right: -70,
          child: const _Orb(180, Color(0xFF00BCD4), 0.18),
        ),
        Positioned(
          top: size.height * 0.4,
          left: -40,
          child: const _Orb(120, Color(0xFF059669), 0.12),
        ),
      ],
    );
  }

  Widget _MissionItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: FaIcon(icon, color: const Color(0xFF059669), size: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return isDark
        ? GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            opacity: 0.10,
            child: _buildStatsContent(),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildStatsContent(),
          );
  }

  Widget _buildStatsContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const _StatPill(
              icon: FontAwesomeIcons.users,
              value: '300+',
              label: 'Members',
              color: Color(0xFF059669),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withOpacity(0.12),
            ),
            const _StatPill(
              icon: FontAwesomeIcons.peopleGroup,
              value: '15+',
              label: 'Teams',
              color: Color(0xFFD97706),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withOpacity(0.12),
            ),
            const _StatPill(
              icon: FontAwesomeIcons.handsPraying,
              value: '5+',
              label: 'Years',
              color: Color(0xFF4CAF50),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: Colors.white.withOpacity(0.08)),
        const SizedBox(height: 14),
        const Text(
          'Moula, ek nazar karam farmaiye.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF059669),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Abd-e-Syedna ni khidmat qubool farmaiye, Moula',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildPrayerBlock() {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return isDark
        ? GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            opacity: 0.08,
            child: _buildPrayerContent(),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildPrayerContent(),
          );
  }

  Widget _buildPrayerContent() {
    return const Column(
      children: [
        Text(
          'الحمد لله الذي هدانا لهذا وما كنا لنهتدي لولا أن هدانا الله',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.6),
        ),
        SizedBox(height: 4),
        Text(
          'اللهم صل على محمد وآل محمد الطيبين الطاهرين',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.6),
        ),
        SizedBox(height: 8),
        Text(
          'TAHERI COMMITTEE, DOHAD',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF059669),
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'بسم رب العالمين',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Text(
      'Powered by Taheri Committee v1.0',
      style: TextStyle(
        fontSize: 11,
        color: isDark ? Colors.white30 : Colors.black54,
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Orb(this.size, this.color, this.opacity);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FaIcon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class StarPainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  StarPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final star in stars) {
      final x = star.x * size.width;
      final y = (star.y + animationValue * star.speed) % 1.0 * size.height;
      final opacity = star.opacity * (0.5 + 0.5 * sin(animationValue * 2 * pi));

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AboutCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _AboutCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF059669).withOpacity(0.3),
                      const Color(0xFF047857).withOpacity(0.2),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
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
    );
  }
}

class _SocialImageCard extends StatelessWidget {
  final String title;
  final String text;
  final String imagePath;
  final VoidCallback onTap;

  const _SocialImageCard({
    required this.title,
    required this.text,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF059669).withOpacity(0.3),
                        const Color(0xFF047857).withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 32,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
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
    );
  }
}
