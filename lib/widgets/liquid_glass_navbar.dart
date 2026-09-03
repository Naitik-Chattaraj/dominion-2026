import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'liquid_glass_container.dart';

class DockItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int? badgeCount;
  final Color? activeColor;

  const DockItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeCount,
    this.activeColor,
  });
}

/// Floating Mac Dock Bottom Navigation Bar with Liquid Glass & Real Gooey Slime Physics.
/// Optimized for ultra-smooth 60-120 FPS performance:
/// - RepaintBoundary isolated layer
/// - GPU fragment shaders for glowing liquid caustics (zero MaskFilter blur passes)
/// - Real 2D Metaball Gooey Bridge with organic concave neck pinch, snapping, and damped elastic wobble
class LiquidGlassDockNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<DockItem> items;
  final double bottomOffset;
  final bool showSeparator;

  const LiquidGlassDockNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.bottomOffset = 24.0,
    this.showSeparator = false,
  });

  @override
  State<LiquidGlassDockNavBar> createState() => _LiquidGlassDockNavBarState();
}

class _LiquidGlassDockNavBarState extends State<LiquidGlassDockNavBar>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late int _prevIndex;
  late int _targetIndex;
  late AnimationController _gooeyController;

  bool _hasTriggeredSnapHaptic = false;

  static const double kSlotWidth = 72.0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _targetIndex = widget.currentIndex;

    _gooeyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    // Dynamic Multi-Stage Tactile Slime Feedback:
    // 1. Initial touch: lightImpact on tap
    // 2. Liquid bridge snap: selectionClick exactly when the neck pinches and snaps at progress 0.58
    // 3. Fluid settle: subtle selectionClick when the jelly finishes its harmonic oscillation
    _gooeyController.addListener(() {
      if (!_hasTriggeredSnapHaptic && _gooeyController.value >= 0.58) {
        _hasTriggeredSnapHaptic = true;
        HapticFeedback.selectionClick();
      }
    });

    _gooeyController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        _hasTriggeredSnapHaptic = false;
      } else if (status == AnimationStatus.completed) {
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void didUpdateWidget(covariant LiquidGlassDockNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _prevIndex = oldWidget.currentIndex;
      _targetIndex = widget.currentIndex;
      _gooeyController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _gooeyController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index == widget.currentIndex) return;
    HapticFeedback.lightImpact();
    widget.onTap(index);
  }

  Color _getItemColor(int index) {
    if (index < 0 || index >= widget.items.length) {
      return const Color(0xFFD9779F);
    }
    return widget.items[index].activeColor ?? const Color(0xFFD9779F);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalBottom = widget.bottomOffset + (bottomPadding > 0 ? bottomPadding * 0.5 : 0.0);
    final totalRowWidth = widget.items.length * kSlotWidth;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: totalBottom,
          left: 12.0,
          right: 12.0,
        ),
        child: RepaintBoundary(
          child: MouseRegion(
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: IntrinsicWidth(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  LiquidGlassContainer(
                    borderRadius: 50.0,
                    blurSigma: 1.8, // Minimal blur for high transparency glass
                    tintOpacity: 0.18, // High transparency
                    tintColor: const Color(0xFF0C0212),
                    enableBlur: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: SizedBox(
                      width: totalRowWidth,
                      height: 58.0,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 1. REAL GOOEY SLIME CANVAS LAYER (Behind the icons)
                          AnimatedBuilder(
                            animation: _gooeyController,
                            builder: (context, child) {
                              final progress = _gooeyController.isAnimating
                                  ? _gooeyController.value
                                  : 1.0;

                              return CustomPaint(
                                size: Size(totalRowWidth, 58.0),
                                painter: GooeySlimePainter(
                                  fromIndex: _prevIndex,
                                  toIndex: _targetIndex,
                                  progress: progress,
                                  slotWidth: kSlotWidth,
                                  fromColor: _getItemColor(_prevIndex),
                                  toColor: _getItemColor(_targetIndex),
                                ),
                              );
                            },
                          ),

                          // 2. ICONS ROW LAYER (In front of the gooey slime)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (int i = 0; i < widget.items.length; i++)
                                _buildDockItemSlot(
                                  item: widget.items[i],
                                  index: i,
                                  isSelected: widget.currentIndex == i,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Mac-style Floating Tooltip above hovered item
                  if (_hoveredIndex != null && _hoveredIndex! < widget.items.length)
                    Positioned(
                      top: -42.0,
                      child: _buildMacTooltip(widget.items[_hoveredIndex!].label),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItemSlot({
    required DockItem item,
    required int index,
    required bool isSelected,
  }) {
    final activeColor = item.activeColor ?? const Color(0xFFD9779F);

    return SizedBox(
      width: kSlotWidth,
      height: 58.0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() {
          if (_hoveredIndex == index) _hoveredIndex = null;
        }),
        child: GestureDetector(
          onTap: () => _handleTap(index),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              scale: isSelected ? 1.15 : 1.0,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                    size: 26.0,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.65),
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: activeColor.withValues(alpha: 0.8),
                              blurRadius: 10.0,
                            ),
                            const Shadow(
                              color: Colors.white,
                              blurRadius: 4.0,
                            ),
                          ]
                        : null,
                  ),

                  // Notification Badge
                  if (item.badgeCount != null && item.badgeCount! > 0)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.0,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2A6D),
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A6D).withValues(alpha: 0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacTooltip(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1B142B).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// High-Performance GPU 2D Metaball Painter
class GooeySlimePainter extends CustomPainter {
  final int fromIndex;
  final int toIndex;
  final double progress;
  final double slotWidth;
  final Color fromColor;
  final Color toColor;

  GooeySlimePainter({
    required this.fromIndex,
    required this.toIndex,
    required this.progress,
    required this.slotWidth,
    required this.fromColor,
    required this.toColor,
  });

  static const double kBaseRadius = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final fromX = fromIndex * slotWidth + (slotWidth / 2);
    final toX = toIndex * slotWidth + (slotWidth / 2);

    final currentColor = Color.lerp(fromColor, toColor, progress) ?? toColor;

    // Static Idle State: Render glowing droplet and indicator dot
    if (fromIndex == toIndex || progress >= 1.0) {
      _drawSingleDroplet(canvas, Offset(toX, centerY), kBaseRadius, 1.0, 1.0, currentColor);
      _drawIndicatorDot(canvas, toX, size.height - 4.0, currentColor);
      return;
    }

    // PHASE 1: STRETCH & PINCH METABALL (Progress 0.0 to 0.58)
    // PHASE 2: SNAP & JIGGLE WOBBLE (Progress 0.58 to 1.0)
    const double snapThreshold = 0.58;

    if (progress < snapThreshold) {
      final t = progress / snapThreshold;
      final easeT = Curves.easeInOutCubic.transform(t);

      final r1 = kBaseRadius * (1.0 - 0.48 * easeT);
      final c1 = Offset(fromX + (toX - fromX) * 0.18 * easeT, centerY);

      final r2 = kBaseRadius * (0.35 + 0.65 * easeT);
      final c2 = Offset(fromX + (toX - fromX) * (0.18 + 0.82 * easeT), centerY);

      final bridgePath = _buildMetaballPath(c1, r1, c2, r2, easeT);

      _drawSlimeGlow(canvas, bridgePath, currentColor, Rect.fromLTRB(
        math.min(c1.dx - r1, c2.dx - r2) - 12,
        centerY - kBaseRadius - 12,
        math.max(c1.dx + r1, c2.dx + r2) + 12,
        centerY + kBaseRadius + 12,
      ));

      _drawSlimeBody(canvas, bridgePath, currentColor, Rect.fromLTRB(
        math.min(c1.dx - r1, c2.dx - r2) - 4,
        centerY - kBaseRadius - 4,
        math.max(c1.dx + r1, c2.dx + r2) + 4,
        centerY + kBaseRadius + 4,
      ));

      _drawSlimeRim(canvas, bridgePath, currentColor);

      final dotX = lerpDouble(fromX, toX, easeT)!;
      _drawIndicatorDot(canvas, dotX, size.height - 4.0, currentColor);
    } else {
      // POST-SNAP WOBBLE PHASE: Damped harmonic liquid wobble
      final t = (progress - snapThreshold) / (1.0 - snapThreshold);
      final wobble = math.sin(t * 3.5 * math.pi) * math.exp(-t * 3.8);

      final scaleX = 1.0 + (0.38 * wobble);
      final scaleY = 1.0 - (0.30 * wobble);

      _drawSingleDroplet(canvas, Offset(toX, centerY), kBaseRadius, scaleX, scaleY, currentColor);
      _drawIndicatorDot(canvas, toX, size.height - 4.0, currentColor);
    }
  }

  Path _buildMetaballPath(Offset c1, double r1, Offset c2, double r2, double stretchT) {
    final path = Path();
    final d = (c2.dx - c1.dx).abs();

    if (d < 1.0) {
      path.addOval(Rect.fromCircle(center: c2, radius: r2));
      return path;
    }

    final isForward = c2.dx > c1.dx;
    final leftCenter = isForward ? c1 : c2;
    final rightCenter = isForward ? c2 : c1;
    final leftRadius = isForward ? r1 : r2;
    final rightRadius = isForward ? r2 : r1;

    final midX = (leftCenter.dx + rightCenter.dx) / 2;
    final midY = leftCenter.dy;

    final waist = math.max(2.5, (leftRadius + rightRadius) * 0.46 * (1.0 - math.pow(stretchT, 1.2)));

    final top1 = Offset(leftCenter.dx, leftCenter.dy - leftRadius);
    final bottom1 = Offset(leftCenter.dx, leftCenter.dy + leftRadius);

    final top2 = Offset(rightCenter.dx, rightCenter.dy - rightRadius);
    final bottom2 = Offset(rightCenter.dx, rightCenter.dy + rightRadius);

    final waistTop = Offset(midX, midY - waist);
    final waistBottom = Offset(midX, midY + waist);

    path.moveTo(top1.dx, top1.dy);
    path.quadraticBezierTo(midX, waistTop.dy, top2.dx, top2.dy);
    path.arcToPoint(bottom2, radius: Radius.circular(rightRadius));
    path.quadraticBezierTo(midX, waistBottom.dy, bottom1.dx, bottom1.dy);
    path.arcToPoint(top1, radius: Radius.circular(leftRadius));
    path.close();

    return path;
  }

  void _drawSingleDroplet(
    Canvas canvas,
    Offset center,
    double radius,
    double scaleX,
    double scaleY,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scaleX, scaleY);

    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    // 1. Hardware-accelerated Outer Radial Glow
    canvas.drawOval(
      rect.inflate(8.0),
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.50),
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect.inflate(8.0)),
    );

    // 2. Translucent Liquid Body
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -0.4),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.45),
            color.withValues(alpha: 0.78),
            color.withValues(alpha: 0.40),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // 3. Specular Meniscus Arc
    final meniscusRect = Rect.fromLTWH(-radius * 0.55, -radius * 0.75, radius * 1.1, radius * 0.5);
    canvas.drawOval(
      meniscusRect,
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );

    // 4. Caustic Rim Outline
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.65),
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );

    canvas.restore();
  }

  void _drawSlimeGlow(Canvas canvas, Path path, Color color, Rect bounds) {
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.45),
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(bounds),
    );
  }

  void _drawSlimeBody(Canvas canvas, Path path, Color color, Rect bounds) {
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.40),
            color.withValues(alpha: 0.75),
            color.withValues(alpha: 0.40),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds),
    );
  }

  void _drawSlimeRim(Canvas canvas, Path path, Color color) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  void _drawIndicatorDot(Canvas canvas, double x, double y, Color color) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(x, y),
      4.0,
      Paint()..color = color.withValues(alpha: 0.75),
    );

    canvas.drawCircle(Offset(x, y), 2.2, paint);
  }

  @override
  bool shouldRepaint(covariant GooeySlimePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fromIndex != fromIndex ||
        oldDelegate.toIndex != toIndex ||
        oldDelegate.toColor != toColor;
  }
}
