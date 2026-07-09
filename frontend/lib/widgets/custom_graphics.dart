import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// 1. Animated pulsing active dot indicating system status
class AnimatedPulseDot extends StatefulWidget {
  final Color color;
  final double size;

  const AnimatedPulseDot({
    super.key,
    this.color = const Color(0xFF10B981), // Emerald green
    this.size = 12.0,
  });

  @override
  State<AnimatedPulseDot> createState() => _AnimatedPulseDotState();
}

class _AnimatedPulseDotState extends State<AnimatedPulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse wave 2
            Transform.scale(
              scale: 1.0 + (_controller.value * 1.5),
              child: Opacity(
                opacity: (1.0 - _controller.value) * 0.35,
                child: Container(
                  width: widget.size * 2,
                  height: widget.size * 2,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Outer pulse wave 1
            Transform.scale(
              scale: 1.0 + (((_controller.value + 0.5) % 1.0) * 1.2),
              child: Opacity(
                opacity: (1.0 - ((_controller.value + 0.5) % 1.0)) * 0.5,
                child: Container(
                  width: widget.size * 1.8,
                  height: widget.size * 1.8,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Core solid dot
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 2. Custom EKG heartbeat line custom painter widget
class EkgWaveWidget extends StatefulWidget {
  final Color color;
  final double height;
  final double width;

  const EkgWaveWidget({
    super.key,
    this.color = const Color(0xFF10B981), // Emerald
    this.height = 36.0,
    this.width = 120.0,
  });

  @override
  State<EkgWaveWidget> createState() => _EkgWaveWidgetState();
}

class _EkgWaveWidgetState extends State<EkgWaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _EkgPainter(
            color: widget.color,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _EkgPainter extends CustomPainter {
  final Color color;
  final double progress;

  _EkgPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Create neon glow shadow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double midY = size.height / 2;
    final double width = size.width;

    path.moveTo(0, midY);

    // Draw repeating EKG segments across width
    // Every segment has a small P wave, QRS spike, and T wave
    final double segmentWidth = 60.0;
    final int segments = (width / segmentWidth).ceil() + 1;
    
    // Shift pattern based on animation progress
    final double shiftX = -progress * segmentWidth;

    for (int i = -1; i < segments; i++) {
      final double startX = i * segmentWidth + shiftX;
      
      // Points relative to startX
      // Baseline
      path.lineTo(startX + 10, midY);
      
      // P wave (small bump)
      path.quadraticBezierTo(
        startX + 13,
        midY - 4,
        startX + 16,
        midY,
      );
      
      // Baseline to Q
      path.lineTo(startX + 22, midY);
      
      // Q (dip down)
      path.lineTo(startX + 24, midY + 4);
      
      // R (sharp peak)
      path.lineTo(startX + 27, midY - 14);
      
      // S (sharp dip)
      path.lineTo(startX + 30, midY + 8);
      
      // Baseline to T
      path.lineTo(startX + 33, midY);
      
      // T wave (medium bump)
      path.quadraticBezierTo(
        startX + 38,
        midY - 6,
        startX + 43,
        midY,
      );
      
      // End of segment
      path.lineTo(startX + segmentWidth, midY);
    }

    // Clip to widget bounding box
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, width, size.height));
    
    // Draw EKG path with glow first, then solid stroke
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EkgPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// 3. Beautiful premium box/checklist illustration for empty state
class NoApprovalsIllustration extends StatefulWidget {
  const NoApprovalsIllustration({super.key});

  @override
  State<NoApprovalsIllustration> createState() => _NoApprovalsIllustrationState();
}

class _NoApprovalsIllustrationState extends State<NoApprovalsIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Floating offsets
        final floatOffset = math.sin(_controller.value * math.pi) * 8.0;
        final planeOffset = math.cos(_controller.value * math.pi) * 10.0;
        final rotateAngle = math.sin(_controller.value * math.pi) * 0.05;

        return SizedBox(
          height: 180,
          width: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Sparkles/Stars in background
              Positioned(
                top: 25 + floatOffset * 0.2,
                left: 30,
                child: Icon(
                  Icons.star_rounded,
                  color: AppTheme.secondary.withOpacity(isDark ? 0.3 : 0.4),
                  size: 16,
                ),
              ),
              Positioned(
                top: 40 - floatOffset * 0.3,
                right: 35,
                child: Icon(
                  Icons.star_rounded,
                  color: AppTheme.primary.withOpacity(isDark ? 0.3 : 0.4),
                  size: 20,
                ),
              ),
              Positioned(
                bottom: 50,
                left: 20,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // 2. Rising Checklist/Paper (Animated Floating Up)
              Positioned(
                top: 35 + floatOffset,
                child: Transform.rotate(
                  angle: -0.06 + rotateAngle * 0.5,
                  child: Container(
                    width: 70,
                    height: 85,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? const Color(0x22FFFFFF) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox rows
                        _buildPaperRow(isDark, true),
                        const SizedBox(height: 6),
                        _buildPaperRow(isDark, true),
                        const SizedBox(height: 6),
                        _buildPaperRow(isDark, false),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Front Box (Static, overlapping the paper)
              Positioned(
                bottom: 25,
                child: Container(
                  width: 95,
                  height: 75,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.85),
                        AppTheme.primary.withOpacity(0.65),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Inner box shading
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      // Arrow indicator in middle of box
                      Center(
                        child: Icon(
                          Icons.inbox_rounded,
                          color: Colors.white.withOpacity(0.85),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Flying Paper Plane (Top Right, Animated Floating)
              Positioned(
                top: 20 - planeOffset * 0.7,
                right: 35 + planeOffset * 0.5,
                child: Transform.rotate(
                  angle: 0.15 + rotateAngle * 0.3,
                  child: Icon(
                    Icons.send_rounded,
                    color: AppTheme.secondary.withOpacity(0.9),
                    size: 28,
                  ),
                ),
              ),

              // 5. Floating Badge: Checkmark Circle (Bottom Right of Box)
              Positioned(
                bottom: 18 + floatOffset * 0.3,
                right: 48,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // Emerald Success
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? const Color(0xFF090D16) : Colors.white,
                      width: 2.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaperRow(bool isDark, bool isChecked) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isChecked
                ? const Color(0xFF10B981).withOpacity(0.15)
                : Colors.transparent,
            border: Border.all(
              color: isChecked ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: isChecked
              ? const Icon(Icons.check, size: 8, color: Color(0xFF10B981))
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.black12,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                height: 4,
                width: 24,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
