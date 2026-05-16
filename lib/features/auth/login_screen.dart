import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  Worker? _authWorker;

  // Animation controllers
  late AnimationController _bgController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();

    // EXISTING auth logic stays exactly the same
    final auth = Get.find<AuthController>();
    if (auth.isLoggedIn.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.off(() => const AppShell(), transition: Transition.fadeIn);
      });
    } else {
      _authWorker = ever(auth.isLoggedIn, (bool loggedIn) {
        if (loggedIn) {
          Get.off(() => const AppShell(), transition: Transition.fadeIn);
        }
      });
    }

    // NEW: Animation setup
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();

    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut));
    _slideAnimation = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceController, curve: Curves.easeOut));
    _entranceAnimation = _entranceController;

    // Start entrance after a short delay
    Future.delayed(
        const Duration(milliseconds: 100), () => _entranceController.forward());
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _bgController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // EXISTING methods stay exactly the same
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Get.find<AuthController>();
    await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter your email address first',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    final auth = Get.find<AuthController>();
    await auth.sendPasswordReset(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.surfaceBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTokens.heroGradient,
        ),
        child: Stack(
          children: [
            // 1. Animated background
            AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(_bgController.value),
                child: const SizedBox.expand(),
              ),
            ),

            // 2. Centered login card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.sp24),
                child: AnimatedBuilder(
                  animation: _entranceAnimation,
                  builder: (context, child) => SlideTransition(
                    position: _slideAnimation,
                    child:
                        FadeTransition(opacity: _fadeAnimation, child: child),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(AppTokens.sp40),
                      decoration: BoxDecoration(
                        color: AppTokens.surfaceWhite,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusModal),
                        boxShadow: AppTokens.modalShadow,
                        border: Border.all(
                            color: AppTokens.borderLight, width: 0.5),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: AppTokens.accentGradient,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: AppTokens.blueShadow,
                                ),
                                child: const Icon(Icons.mosque,
                                    color: Colors.white, size: 36),
                              ),
                            ),
                            const SizedBox(height: AppTokens.sp20),

                            // Title
                            Text('Taheri Committee',
                                style: AppText.display(),
                                textAlign: TextAlign.center),
                            const SizedBox(height: AppTokens.sp8),
                            Text('Community Management',
                                style: AppText.muted(),
                                textAlign: TextAlign.center),
                            const SizedBox(height: AppTokens.sp32),

                            // Email field — use your existing controller
                            _buildStaggerField(
                              0,
                              AppInput(
                                label: 'Email',
                                controller:
                                    _emailCtrl, // YOUR existing controller
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.email_outlined,
                                    color: AppTokens.textMuted, size: 20),
                                validator: (v) => // YOUR existing validator
                                    v == null || v.isEmpty
                                        ? 'Enter email'
                                        : !v.contains('@')
                                            ? 'Enter a valid email'
                                            : null,
                                isDark:
                                    true, // Login screen has dark background
                              ),
                            ),
                            const SizedBox(height: AppTokens.sp16),

                            // Password field — use your existing controller
                            _buildStaggerField(
                              1,
                              AppInput(
                                label: 'Password',
                                controller:
                                    _passwordCtrl, // YOUR existing controller
                                obscureText: _obscurePassword,
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: AppTokens.textMuted, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppTokens.textMuted,
                                      size: 20),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) => // YOUR existing validator
                                    v == null || v.isEmpty
                                        ? 'Enter password'
                                        : v.length < 6
                                            ? 'Password too short'
                                            : null,
                                isDark:
                                    true, // Login screen has dark background
                              ),
                            ),
                            const SizedBox(height: AppTokens.sp8),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style:
                                      AppText.small(color: AppTokens.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTokens.sp24),

                            // Sign In button — calls YOUR existing signIn()
                            _buildStaggerField(
                              2,
                              _buildSignInButton(),
                            ),

                            const SizedBox(height: AppTokens.sp16),

                            // Google Sign-In button
                            _buildStaggerField(
                              3,
                              _buildGoogleSignInButton(),
                            ),

                            // Error message — YOUR existing error display
                            Obx(() {
                              final auth = Get.find<AuthController>();
                              final errorMessage = auth.errorMessage.value;
                              return Padding(
                                      padding: const EdgeInsets.only(
                                          top: AppTokens.sp16),
                                      child: _ShakeWidget(
                                        key: ValueKey(errorMessage),
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                              AppTokens.sp12),
                                          decoration: BoxDecoration(
                                            color: AppTokens.danger
                                                .withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                                AppTokens.radiusInput),
                                            border: Border.all(
                                                color: AppTokens.danger
                                                    .withOpacity(0.3)),
                                          ),
                                          child: Text(errorMessage,
                                              style: AppText.small(
                                                  color: AppTokens.danger),
                                              textAlign: TextAlign.center),
                                        ),
                                      ),
                                    );
                            }),

                            const SizedBox(height: AppTokens.sp20),
                            Center(
                              child: Text(
                                'Powered by Taheri Committee v1.0',
                                style:
                                    AppText.small(color: AppTokens.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stagger helper — wraps each field with its own delayed animation
  Widget _buildStaggerField(int index, Widget child) {
    final delay = index * 0.08;
    return AnimatedBuilder(
      animation: _entranceAnimation,
      builder: (_, __) {
        final t = ((_entranceAnimation.value - delay) / (1.0 - delay))
            .clamp(0.0, 1.0);
        final curve = Curves.easeOut.transform(t);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
              offset: Offset(0, 16 * (1 - curve)), child: child),
        );
      },
    );
  }

  // EXACT same sign in button logic, just using AppPrimaryButton
  Widget _buildSignInButton() {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final loading = auth.isLoading.value;
      return AppPrimaryButton(
        label: 'Sign In',
        isLoading: loading, // YOUR existing loading state
        onTap: loading ? null : _signIn, // YOUR existing method
        isDark: true, // Login screen has dark background
      );
    });
  }

  // Google Sign-In button
  Widget _buildGoogleSignInButton() {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final loading = auth.isLoading.value;
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          border: Border.all(color: AppTokens.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
            onTap: loading ? null : _signInWithGoogle,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTokens.primary),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTokens.borderLight),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.google,
                              size: 16,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: AppTokens.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }

  Future<void> _signInWithGoogle() async {
    final auth = Get.find<AuthController>();
    await auth.signInWithGoogle();
  }
}

// Shake widget for error animation
class _ShakeWidget extends StatefulWidget {
  final Widget child;
  const _ShakeWidget({super.key, required this.child});

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shake = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) {
        final offset = math.sin(_shake.value * math.pi * 4) * 6;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
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
    final paint = Paint()..color = AppTokens.accent.withOpacity(0.08);
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
