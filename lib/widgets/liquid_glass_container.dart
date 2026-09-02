import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Cubic transition curve defined in liquid-glass.txt:
/// transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 2.2);
const Curve kLiquidGlassCurve = Cubic(0.175, 0.885, 0.32, 2.2);

/// Recreates the Liquid Glass effect defined in assets/liquid-glass.txt and assets/svg.txt:
/// - .liquid-glass container box-shadows and spring dynamics
/// - .liquidGlass-effect backdrop-filter blur and refraction
/// - .liquidGlass-tint rgba(20, 1, 31, 0.308)
/// - .liquidGlass-shine with top/bottom borders and inner glow (0 -30px 40px -20px rgba(255,255,255,0.15))
/// - .liquidGlass-shine::before top-left corner specular highlight
/// - .liquidGlass-shine::after bottom-right corner specular highlight
/// - .glass-noise frosted grain texture
/// - SVG feSpecularLighting & feDisplacement caustic sheen
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final double tintOpacity;
  final Color tintColor;
  final bool showNoise;
  final bool showCausticRefraction;
  final bool showShine;
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 40.0,
    this.blurSigma = 16.0,
    this.tintOpacity = 0.308,
    this.tintColor = const Color(0xFF14011F),
    this.showNoise = true,
    this.showCausticRefraction = true,
    this.showShine = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = BorderRadius.circular(borderRadius);

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: [
          // 0 6px 6px rgba(0, 0, 0, 0.2)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 6,
            offset: const Offset(0, 6),
          ),
          // 0 0 20px rgba(0, 0, 0, 0.1)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: Offset.zero,
          ),
          // Ambient deep violet bounce shadow
          BoxShadow(
            color: const Color(0xFF581C87).withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              // 1. .liquidGlass-tint: background: rgba(20, 1, 31, 0.308);
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: effectiveRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tintColor.withValues(alpha: tintOpacity * 1.15),
                        tintColor.withValues(alpha: tintOpacity),
                        const Color(0xFF090314).withValues(alpha: tintOpacity * 1.25),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Liquid Glass Painter: SVG specular lighting, corner shines, borders, inner glow, noise
              Positioned.fill(
                child: CustomPaint(
                  painter: _LiquidGlassPainter(
                    borderRadius: borderRadius,
                    showNoise: showNoise,
                    showCaustic: showCausticRefraction,
                    showShine: showShine,
                  ),
                ),
              ),

              // 3. Main Child Content
              Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

/// Custom painter that replicates the SVG filter and CSS pseudo-elements:
/// - Top-left specular highlight (radial gradient fade, #fff 1.2px/2px)
/// - Bottom-right specular highlight (radial gradient fade, #fff 1.5px)
/// - Top border 0.7px solid rgba(255, 255, 255, 0.356)
/// - Bottom border 0.1px solid rgba(255, 255, 255, 0.3)
/// - Inset upward glow: 0 -30px 40px -20px rgba(255, 255, 255, 0.15) inset
/// - Caustic displacement shimmer from feSpecularLighting / feDisplacementMap
/// - Micro-noise frosted grain overlay
class _LiquidGlassPainter extends CustomPainter {
  final double borderRadius;
  final bool showNoise;
  final bool showCaustic;
  final bool showShine;

  // Precomputed deterministic pseudo-random points for the frosted noise overlay
  static final List<Offset> _noisePoints = List.generate(120, (i) {
    final x = (math.sin(i * 12.9898 + 78.233) * 43758.5453).abs() % 1.0;
    final y = (math.cos(i * 4.898 + 33.123) * 23421.631).abs() % 1.0;
    return Offset(x, y);
  });

  _LiquidGlassPainter({
    required this.borderRadius,
    required this.showNoise,
    required this.showCaustic,
    required this.showShine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final r = math.min(borderRadius, math.min(size.width, size.height) / 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // 1. Inset glow from CSS: box-shadow: 0 -30px 40px -20px rgba(255, 255, 255, 0.15) inset;
    if (showShine) {
      final innerGlowPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, size.height),
          Offset(size.width / 2, size.height - 35),
          [
            const Color(0x26FFFFFF), // 0.15 white
            const Color(0x00FFFFFF),
          ],
        );
      canvas.drawRRect(rrect, innerGlowPaint);
    }

    // 2. SVG feSpecularLighting & feDisplacementMap caustic refraction:
    // Light source at (-200, -200, 300) creates a subtle diagonal refraction sheen across the glass
    if (showCaustic) {
      final causticPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(-size.width * 0.2, -size.height * 0.2),
          Offset(size.width * 0.9, size.height * 1.1),
          [
            Colors.white.withValues(alpha: 0.09),
            const Color(0xFF00E5FF).withValues(alpha: 0.04), // Subtle chromatic cyan edge
            Colors.transparent,
            const Color(0xFFA855F7).withValues(alpha: 0.03), // Subtle chromatic violet edge
            Colors.white.withValues(alpha: 0.05),
          ],
          [0.0, 0.25, 0.55, 0.8, 1.0],
        );
      canvas.drawRRect(rrect, causticPaint);
    }

    // 3. Frosted noise texture: .glass-noise opacity 0.07
    if (showNoise) {
      final noisePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;

      for (final pt in _noisePoints) {
        final px = pt.dx * size.width;
        final py = pt.dy * size.height;
        canvas.drawPoints(ui.PointMode.points, [Offset(px, py)], noisePaint);
      }
    }

    // 4. Subtle Base Rim Border:
    // border-top: 0.7px solid rgba(255, 255, 255, 0.356)
    // border-bottom: 0.1px solid rgba(255, 255, 255, 0.3)
    // border-left/right: 0.2-0.3 rgba(255, 255, 255)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        [
          const Color(0x5EFFFFFF), // 0.37 white at top
          const Color(0x28FFFFFF), // 0.16 white at mid
          const Color(0x40FFFFFF), // 0.25 white at bottom
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRRect(rrect, rimPaint);

    // 5. Specular Corner Highlights:
    // .liquidGlass-shine::before (Top-Left corner highlight)
    // border-top: 1.2px solid #fff, border-left: 2px solid #fff
    // radial-gradient fading from (0,0) outward to 20px
    final cornerHighlightLength = math.min(r * 1.5, 55.0);

    // Top-Left Arc Highlight
    final tlPath = Path()
      ..moveTo(0, cornerHighlightLength)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(cornerHighlightLength, 0);

    final tlPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.radial(
        Offset.zero,
        cornerHighlightLength,
        [
          const Color(0xF5FFFFFF), // crisp white highlight
          const Color(0x80FFFFFF),
          const Color(0x00FFFFFF), // fades out outward
        ],
        [0.0, 0.35, 1.0],
      );
    canvas.drawPath(tlPath, tlPaint);

    // Bottom-Right Arc Highlight
    // .liquidGlass-shine::after (Bottom-Right corner highlight)
    // border-bottom: 1.5px solid #fff, border-right: 1.5px solid #fff
    // Sweeps clockwise along the outer rounded corner from right edge to bottom edge
    final brPath = Path()
      ..moveTo(size.width, size.height - cornerHighlightLength)
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(size.width - cornerHighlightLength, size.height);

    final brPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.radial(
        Offset(size.width, size.height),
        cornerHighlightLength,
        [
          const Color(0xE8FFFFFF),
          const Color(0x70FFFFFF),
          const Color(0x00FFFFFF),
        ],
        [0.0, 0.35, 1.0],
      );
    canvas.drawPath(brPath, brPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.showNoise != showNoise ||
        oldDelegate.showCaustic != showCaustic ||
        oldDelegate.showShine != showShine;
  }
}
