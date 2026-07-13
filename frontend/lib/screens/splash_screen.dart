import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _backgroundController;

  // Staggered animations
  late Animation<double> _loaderFadeIn;
  late Animation<double> _progress;
  late Animation<double> _exitFadeOut;
  late Animation<double> _exitScaleOut;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Main animation timeline: 4.0 seconds total
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Define timeline curves

    _loaderFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.45, curve: Curves.easeOut),
      ),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    _exitFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.9, 1.0, curve: Curves.easeInOut),
      ),
    );

    _exitScaleOut = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.9, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Trigger navigation when the timeline animation completes
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          final provider = Provider.of<ReminderProvider>(context, listen: false);
          final Widget nextScreen = provider.isAuthenticated ? const HomeScreen() : const LoginScreen();
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.05, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                    ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    });

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Animated floating particle/orb background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AnimatedBackgroundPainter(_backgroundController.value),
                );
              },
            ),
          ),
          // Centered Progress Bar Loader
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _exitFadeOut.value,
                  child: Transform.scale(
                    scale: _exitScaleOut.value,
                    child: Opacity(
                      opacity: _loaderFadeIn.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo_light.png',
                            width: 280,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 40),
                          // Progress bar
                          Container(
                            width: 180,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E3B74).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: _progress.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF40CF9A), // Teal
                                          Color(0xFF6366F1), // Indigo
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF40CF9A).withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Micro-text for loading state
                          Text(
                            'Initializing reminders...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0E3B74).withOpacity(0.85),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Footer Text at the Bottom
          Positioned(
            bottom: 30,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _exitFadeOut.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'made with ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0E3B74).withOpacity(0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        ' eazzio technology private limited',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0E3B74).withOpacity(0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Custom Painter for Floating Pastel Orbs Background
// ----------------------------------------------------
class AnimatedBackgroundPainter extends CustomPainter {
  final double animationValue;

  AnimatedBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 5 soft, floating glowing orbs
    final orbs = [
      _Orb(
        baseX: 0.2,
        baseY: 0.25,
        radius: 180,
        color: const Color(0xFF7C3AED).withOpacity(0.06), // Soft purple
        speedX: 1.2,
        speedY: 0.8,
        offsetX: 0.0,
        offsetY: 1.5,
      ),
      _Orb(
        baseX: 0.8,
        baseY: 0.15,
        radius: 220,
        color: const Color(0xFF40CF9A).withOpacity(0.05), // Soft teal
        speedX: 0.9,
        speedY: 1.1,
        offsetX: 2.0,
        offsetY: 0.5,
      ),
      _Orb(
        baseX: 0.45,
        baseY: 0.75,
        radius: 200,
        color: const Color(0xFF6366F1).withOpacity(0.06), // Soft indigo
        speedX: 1.0,
        speedY: 1.0,
        offsetX: 1.0,
        offsetY: 2.5,
      ),
      _Orb(
        baseX: 0.15,
        baseY: 0.8,
        radius: 170,
        color: const Color(0xFFEC4899).withOpacity(0.05), // Soft pink/rose
        speedX: 1.1,
        speedY: 0.9,
        offsetX: 3.0,
        offsetY: 0.0,
      ),
      _Orb(
        baseX: 0.75,
        baseY: 0.6,
        radius: 190,
        color: const Color(0xFF06B6D4).withOpacity(0.05), // Soft cyan
        speedX: 0.8,
        speedY: 1.2,
        offsetX: 0.5,
        offsetY: 1.8,
      ),
    ];

    for (final orb in orbs) {
      // Calculate animated center coordinates using sine and cosine waves
      final double angleX = animationValue * 2 * math.pi * orb.speedX + orb.offsetX;
      final double angleY = animationValue * 2 * math.pi * orb.speedY + orb.offsetY;

      // Small movement range (+/- 45 pixels)
      final double dx = math.sin(angleX) * 45;
      final double dy = math.cos(angleY) * 45;

      final double cx = size.width * orb.baseX + dx;
      final double cy = size.height * orb.baseY + dy;

      // Draw a blurred circle using radial gradient
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: orb.radius);
      paint.shader = RadialGradient(
        colors: [
          orb.color,
          orb.color.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);

      canvas.drawCircle(Offset(cx, cy), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _Orb {
  final double baseX;
  final double baseY;
  final double radius;
  final Color color;
  final double speedX;
  final double speedY;
  final double offsetX;
  final double offsetY;

  const _Orb({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.color,
    required this.speedX,
    required this.speedY,
    required this.offsetX,
    required this.offsetY,
  });
}
