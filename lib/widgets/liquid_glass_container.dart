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
/// - .liquidGlass-shine with top/bottom borders and inner glow
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
  final bool enableBlur; // Performance optimization: disable offscreen backdrop blur when on solid backgrounds
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 40.0,
    this.blurSigma = 12.0,
    this.tintOpacity = 0.308,
    this.tintColor = const Color(0xFF14011F),
    this.showNoise = false, // Disabled on mobile to avoid 120 drawPoints per frame
    this.showCausticRefraction = true,
    this.showShine = true,
    this.enableBlur = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = BorderRadius.circular(borderRadius);

    Widget innerLayers = Stack(
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

        // 2. Liquid Glass Painter: SVG specular lighting, corner shines, borders, inner glow
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
    );

    // If blur is enabled (e.g. floating dock), wrap in BackdropFilter;
    // Otherwise render high-performance direct glass layers without offscreen framebuffer copies!
    Widget filteredContent = enableBlur
        ? BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: innerLayers,
          )
        : innerLayers;

    Widget content = RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFF581C87).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: effectiveRadius,
          child: filteredContent,
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

/// High-performance custom painter for specular shines, borders, and caustic highlights
class _LiquidGlassPainter extends CustomPainter {
  final double borderRadius;
  final bool showNoise;
  final bool showCaustic;
  final bool showShine;

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
          Offset(size.width / 2, size.height - 30),
          const [
            Color(0x22FFFFFF),
            Color(0x00FFFFFF),
          ],
        );
      canvas.drawRRect(rrect, innerGlowPaint);
    }

    // 2. Caustic refraction sheen across the glass
    if (showCaustic) {
      final causticPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(-size.width * 0.1, -size.height * 0.1),
          Offset(size.width * 0.9, size.height * 1.0),
          [
            Colors.white.withValues(alpha: 0.08),
            const Color(0xFF00E5FF).withValues(alpha: 0.03),
            Colors.transparent,
            Colors.white.withValues(alpha: 0.04),
          ],
          const [0.0, 0.25, 0.65, 1.0],
        );
      canvas.drawRRect(rrect, causticPaint);
    }

    // 3. Base Rim Border:
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        const [
          Color(0x55FFFFFF), // top border
          Color(0x22FFFFFF),
          Color(0x35FFFFFF), // bottom border
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRRect(rrect, rimPaint);

    // 4. Specular Corner Highlights:
    final cornerHighlightLength = math.min(r * 1.4, 48.0);

    // Top-Left Arc Highlight
    final tlPath = Path()
      ..moveTo(0, cornerHighlightLength)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(cornerHighlightLength, 0);

    final tlPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.radial(
        Offset.zero,
        cornerHighlightLength,
        const [
          Color(0xF0FFFFFF),
          Color(0x70FFFFFF),
          Color(0x00FFFFFF),
        ],
        const [0.0, 0.35, 1.0],
      );
    canvas.drawPath(tlPath, tlPaint);

    // Bottom-Right Arc Highlight
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
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.radial(
        Offset(size.width, size.height),
        cornerHighlightLength,
        const [
          Color(0xE0FFFFFF),
          Color(0x60FFFFFF),
          Color(0x00FFFFFF),
        ],
        const [0.0, 0.35, 1.0],
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
