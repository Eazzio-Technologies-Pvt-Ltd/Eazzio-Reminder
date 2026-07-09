import 'package:flutter/material.dart';


class AppTheme {
  // Vibrant, harmonious HSL-tailored colors
  static const Color primary = Color(0xFF7C3AED); // Vibrant Purple
  static const Color secondary = Color(0xFFEC4899); // Rose Pink
  static const Color accent = Color(0xFF8B5CF6); // Bright Purple
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF06B6D4); // Cyan

  // Deep slate/dark background colors
  static const Color bgDark = Color(0xFF090D16); // Slate 955 (darker)
  static const Color bgCard = Color(0xFF131A26); // Slate 900 (darker)
  static const Color bgCardLight = Color(0xFF1F293A); // Slate 800 (darker)
  static const Color textPrimary = Color(0xFFF8FAFC); // White/Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400

  // Premium Light theme background and text colors
  static const Color bgLight = Color(0xFFF4F5FC); // Clean light lavender-gray background
  static const Color bgCardLightMode = Color(0xFFFFFFFF); // Crisp white card background
  static const Color bgCardLightModeAlt = Color(0xFFEEEDF8); // Light gray-lavender for inputs/navigation
  static const Color textPrimaryLightMode = Color(0xFF1E1B4B); // Deep Indigo
  static const Color textSecondaryLightMode = Color(0xFF4A457E); // Medium Purple-Slate

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)], // Indigo to Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondary, Color(0xFFF43F5E)], // Pink to Rose
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> getCardShadow({
    required Color color,
    required bool isDark,
    bool isHovered = false,
  }) {
    if (isHovered) {
      return [
        BoxShadow(
          color: isDark ? color.withOpacity(0.25) : color.withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: isDark ? color.withOpacity(0.18) : color.withOpacity(0.08),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: isDark ? color.withOpacity(0.08) : color.withOpacity(0.02),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x22FFFFFF),
      Color(0x08FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Modern Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: bgCardLightMode,
        error: danger,
      ),
      cardTheme: CardThemeData(
        color: bgCardLightMode,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEEEDF8), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCardLightMode,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFEEEDF8), width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimaryLightMode),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimaryLightMode),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryLightMode),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimaryLightMode),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondaryLightMode),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCardLightModeAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEDF8), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondaryLightMode),
        floatingLabelStyle: const TextStyle(color: primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Modern Dark Theme Configuration matching mockup 1
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: bgCard,
        error: danger,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x15FFFFFF), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x15FFFFFF), width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x11FFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        floatingLabelStyle: const TextStyle(color: primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class HoverContainer extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final BoxBorder? hoverBorder;
  final BoxBorder? defaultBorder;
  final List<BoxShadow>? hoverShadow;
  final List<BoxShadow>? defaultShadow;
  final double translationY;
  final bool drawBorder;

  const HoverContainer({
    super.key,
    required this.child,
    this.scale = 1.015,
    this.duration = const Duration(milliseconds: 200),
    this.hoverBorder,
    this.defaultBorder,
    this.hoverShadow,
    this.defaultShadow,
    this.translationY = -3.0,
    this.drawBorder = true,
  });

  @override
  State<HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final double activeScale = _isHovered ? widget.scale : 1.0;
    final double activeTransY = _isHovered ? widget.translationY : 0.0;
    
    final border = widget.drawBorder
        ? (_isHovered 
            ? (widget.hoverBorder ?? Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.5))
            : (widget.defaultBorder ?? Border.all(color: isDark ? const Color(0x11FFFFFF) : Colors.black.withOpacity(0.05), width: 1)))
        : null;

    final shadow = _isHovered
        ? (widget.hoverShadow ?? [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.4) 
                  : theme.colorScheme.primary.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.2) 
                  : theme.colorScheme.primary.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ])
        : (widget.defaultShadow ?? [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.15) 
                  : Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ]);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..translate(0.0, activeTransY, 0.0)
          ..scale(activeScale, activeScale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: border,
              borderRadius: BorderRadius.circular(16),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class LogoArrowPainter extends CustomPainter {
  final Color color;
  LogoArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Left side of the arrow (lighter mint-green/teal)
    final paintLeft = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Right side of the arrow (darker emerald-green/teal)
    // We derive a matching darker shade using HSV color space
    final hsv = HSVColor.fromColor(color);
    final paintRight = Paint()
      ..color = hsv.withValue(hsv.value * 0.85).toColor()
      ..style = PaintingStyle.fill;

    // Left Path: from top peak, to bottom left, to inner peak, back to top peak
    final pathLeft = Path();
    pathLeft.moveTo(size.width / 2, 0);
    pathLeft.lineTo(0, size.height);
    pathLeft.lineTo(size.width / 2, size.height * 0.55);
    pathLeft.close();

    // Right Path: from top peak, to inner peak, to bottom right, back to top peak
    final pathRight = Path();
    pathRight.moveTo(size.width / 2, 0);
    pathRight.lineTo(size.width / 2, size.height * 0.55);
    pathRight.lineTo(size.width, size.height);
    pathRight.close();

    canvas.drawPath(pathLeft, paintLeft);
    canvas.drawPath(pathRight, paintRight);
  }

  @override
  bool shouldRepaint(covariant LogoArrowPainter oldDelegate) => oldDelegate.color != color;
}

class AppLogo extends StatelessWidget {
  final double fontSize;
  final double? arrowWidth;
  final double? arrowHeight;
  final Color? textColor;

  const AppLogo({
    super.key,
    this.fontSize = 24,
    this.arrowWidth,
    this.arrowHeight,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Scale logo height based on font size (height ~1.15 times the font size for perfect visual balance)
    final double logoHeight = fontSize * 1.15;
    
    return Image.asset(
      isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_light.png',
      height: logoHeight,
      fit: BoxFit.contain,
    );
  }
}

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.offset = const Offset(0.0, 20.0),
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _slideAnimation = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
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
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

