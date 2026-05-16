import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_shell.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // Background particle animation — loops forever
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();

    // Logo entrance: scale + fade in
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _logoScale = Tween(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    // Text entrance: slide up + fade
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _textFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Exit fade
    _exitFade = Tween(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1200)); // hold

    // Navigate after 5 seconds based on auth state
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        final authController = Get.find<AuthController>();
        if (authController.isLoggedIn.value) {
          Get.off(() => const AppShell(), transition: Transition.fadeIn);
        } else {
          Get.off(() => const LoginScreen(), transition: Transition.fadeIn);
        }
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.surfaceWarm,
      body: Stack(
        children: [
          // Animated background particles
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_bgController.value),
              child: const SizedBox.expand(),
            ),
          ),
          // Centered logo + text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppTokens.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTokens.primary.withOpacity(0.35),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 48),
                      // REPLACE Icon with your actual app logo:
                      // child: Image.asset('assets/logo.png', width: 48, height: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          'TAHERI COMMITTEE', // REPLACE with your app name
                          style: AppText.display(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Serving with devotion since 2019', // REPLACE with your tagline
                          style: AppText.muted(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Floating particle background painter
class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> _particles = List.generate(
    18,
    (i) => _Particle(
      x: (i * 0.137 + 0.05) % 1.0,
      y: (i * 0.193 + 0.1) % 1.0,
      radius: 3.0 + (i % 4) * 2.5,
      speed: 0.15 + (i % 3) * 0.08,
      phase: i * 0.35,
    ),
  );

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTokens.primary.withOpacity(0.07);
    for (final p in _particles) {
      final dy = math.sin((progress + p.phase) * 2 * math.pi) * 18 * p.speed;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height + dy),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, radius, speed, phase;
  const _Particle(
      {required this.x,
      required this.y,
      required this.radius,
      required this.speed,
      required this.phase});
}
