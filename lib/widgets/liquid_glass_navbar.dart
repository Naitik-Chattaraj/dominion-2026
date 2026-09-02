import 'dart:math' as math;
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

/// Floating Mac Dock-style Circular Bottom Navigation Bar with Liquid Glass styling.
/// Features:
/// - Floating pill above the base (not touching the bottom)
/// - Circular radius on both sides (stadium capsule)
/// - Exact SVG/CSS liquid glass layers (frosted blur, specular shines, corner arcs, deep tint)
/// - macOS Dock magnification effect on hover and drag
/// - macOS active indicator dot underneath the selected item
/// - Spring bounce animation (Cubic(0.175, 0.885, 0.32, 2.2))
/// - Floating liquid glass tooltips on hover
/// - Badges and Mac-style dock separator
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
    this.showSeparator = true,
  });

  @override
  State<LiquidGlassDockNavBar> createState() => _LiquidGlassDockNavBarState();
}

class _LiquidGlassDockNavBarState extends State<LiquidGlassDockNavBar>
    with TickerProviderStateMixin {
  int? _hoveredIndex;
  late List<AnimationController> _bounceControllers;

  @override
  void initState() {
    super.initState();
    _bounceControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _bounceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    widget.onTap(index);

    // Mac Dock bounce effect on tap
    final controller = _bounceControllers[index];
    controller.forward(from: 0.0).then((_) => controller.reverse());
  }

  double _getScaleForIndex(int index) {
    if (_hoveredIndex == null) {
      return widget.currentIndex == index ? 1.06 : 1.0;
    }

    final distance = (index - _hoveredIndex!).abs();
    if (distance == 0) return 1.25; // Direct hover: 1.25x magnification
    if (distance == 1) return 1.12; // Adjacent neighbor: 1.12x magnification
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalBottom = widget.bottomOffset + (bottomPadding > 0 ? bottomPadding * 0.5 : 0.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: totalBottom,
          left: 12.0,
          right: 12.0,
        ),
        child: MouseRegion(
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: IntrinsicWidth(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Floating Dock Container with Liquid Glass Material
                LiquidGlassContainer(
                  borderRadius: 50.0, // Circular ends (Mac Dock capsule)
                  blurSigma: 20.0,
                  tintOpacity: 0.32,
                  tintColor: const Color(0xFF14011F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (int i = 0; i < widget.items.length; i++) ...[
                        // Mac dock separator before the last item (Settings/Studio)
                        if (widget.showSeparator && i == widget.items.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Container(
                              width: 1.2,
                              height: 26.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1.0),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.05),
                                    Colors.white.withValues(alpha: 0.35),
                                    Colors.white.withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        _buildDockItem(
                          item: widget.items[i],
                          index: i,
                          isSelected: widget.currentIndex == i,
                          scale: _getScaleForIndex(i),
                        ),
                      ],
                    ],
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
    );
  }

  Widget _buildDockItem({
    required DockItem item,
    required int index,
    required bool isSelected,
    required double scale,
  }) {
    final activeColor = item.activeColor ?? const Color(0xFF00E5FF);
    final bounceAnimation = _bounceControllers[index];

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() {
        if (_hoveredIndex == index) _hoveredIndex = null;
      }),
      child: GestureDetector(
        onTap: () => _handleTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: bounceAnimation,
          builder: (context, child) {
            // Mac Dock jump curve: jump up on click and spring back down
            final jumpY = -math.sin(bounceAnimation.value * math.pi) * 12.0;
            return Transform.translate(
              offset: Offset(0, jumpY),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: kLiquidGlassCurve, // Spring transition from liquid-glass.txt!
            transform: Matrix4.diagonal3Values(scale, scale, 1.0),
            transformAlignment: Alignment.bottomCenter,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Glowing subtle backing for selected icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isSelected
                            ? RadialGradient(
                                colors: [
                                  activeColor.withValues(alpha: 0.28),
                                  activeColor.withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                              )
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                          size: 26.0,
                          color: isSelected
                              ? activeColor
                              : Colors.white.withValues(alpha: 0.72),
                          shadows: isSelected
                              ? [
                                  Shadow(
                                    color: activeColor.withValues(alpha: 0.6),
                                    blurRadius: 10.0,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),

                    // Notification Badge (like Mac Dock Mail/Messages unread count)
                    if (item.badgeCount != null && item.badgeCount! > 0)
                      Positioned(
                        top: -1,
                        right: -1,
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

                const SizedBox(height: 3.0),

                // macOS Dock active app indicator dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 4.0 : 0.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.9),
                              blurRadius: 4.0,
                              spreadRadius: 1.0,
                            ),
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.8),
                              blurRadius: 7.0,
                              spreadRadius: 1.2,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Frosted glass tooltip bubble matching macOS Dock
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
            blurRadius: 12.0,
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
