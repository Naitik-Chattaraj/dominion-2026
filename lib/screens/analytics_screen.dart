import 'package:flutter/material.dart';
import '../widgets/liquid_glass_container.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTimeframe = 1; // 0: 24H, 1: 7D, 2: 30D, 3: 1Y
  final List<String> _timeframes = ['24H', '7D', '30D', '1Y'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 14.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Risk Analytics',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Real-time Telemetry & Vectors',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Timeframe switcher in liquid glass pill
                    LiquidGlassContainer(
                      borderRadius: 18.0,
                      blurSigma: 14.0,
                      tintOpacity: 0.3,
                      padding: const EdgeInsets.all(3.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_timeframes.length, (index) {
                          final isSelected = _selectedTimeframe == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTimeframe = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14.0),
                                border: isSelected
                                    ? Border.all(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                                        width: 0.8,
                                      )
                                    : null,
                              ),
                              child: Text(
                                _timeframes[index],
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Incident Volume Sparkline Chart (Custom Painted in Liquid Glass Card)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildTrendChartCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16.0)),

          // Two-column Stat summary tiles
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'Scrubbed',
                      '184.2 GB',
                      '+12.4%',
                      true,
                      Icons.cleaning_services_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _buildMetricTile(
                      'Response',
                      '840 ms',
                      '-18.2%',
                      true,
                      Icons.bolt_rounded,
                      const Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16.0)),

          // Attack Vectors Breakdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildVectorsBreakdownCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16.0)),

          // Vulnerability Surface Distribution
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSurfaceCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120.0)),
        ],
      ),
    );
  }

  Widget _buildTrendChartCard() {
    return LiquidGlassContainer(
      borderRadius: 26.0,
      blurSigma: 20.0,
      tintOpacity: 0.32,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THREAT MITIGATION VELOCITY',
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  const Text(
                    '2,419 Scrubbed',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  '+23.8%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // Custom Painted Smooth Chart with Gradient Fill
          SizedBox(
            height: 110.0,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklineChartPainter(),
            ),
          ),

          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Text(
                      day,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    String change,
    bool isPositive,
    IconData icon,
    Color accentColor,
  ) {
    return LiquidGlassContainer(
      borderRadius: 22.0,
      blurSigma: 16.0,
      tintOpacity: 0.28,
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18.0, color: accentColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.0,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVectorsBreakdownCard() {
    final vectors = [
      {'name': 'Denial of Service (DDoS)', 'percent': 48, 'color': const Color(0xFFFF2A6D)},
      {'name': 'Credential Replay Attacks', 'percent': 24, 'color': const Color(0xFFFBBF24)},
      {'name': 'Smart Contract State Spoofing', 'percent': 16, 'color': const Color(0xFFA855F7)},
      {'name': 'Cross-Site API Injections', 'percent': 12, 'color': const Color(0xFF00E5FF)},
    ];

    return LiquidGlassContainer(
      borderRadius: 26.0,
      blurSigma: 18.0,
      tintOpacity: 0.30,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Targeted Attack Vectors',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14.0),
          Column(
            children: vectors.map((v) {
              final color = v['color'] as Color;
              final percent = v['percent'] as int;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            v['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    Stack(
                      children: [
                        Container(
                          height: 5.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(3.0),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percent / 100,
                          child: Container(
                            height: 5.0,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withValues(alpha: 0.7), color],
                              ),
                              borderRadius: BorderRadius.circular(3.0),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 5.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceCard() {
    return LiquidGlassContainer(
      borderRadius: 22.0,
      blurSigma: 16.0,
      tintOpacity: 0.28,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: const Icon(Icons.shield_moon_rounded, color: Color(0xFFA855F7), size: 24.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zero-Trust Boundary',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'All perimeter clusters operating under mutual TLS 1.3 encryption.',
                  style: TextStyle(
                    fontSize: 11.0,
                    color: Colors.white.withValues(alpha: 0.55),
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

class _SparklineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.16, size.height * 0.60),
      Offset(size.width * 0.33, size.height * 0.70),
      Offset(size.width * 0.50, size.height * 0.25),
      Offset(size.width * 0.66, size.height * 0.40),
      Offset(size.width * 0.83, size.height * 0.15),
      Offset(size.width, size.height * 0.30),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.35),
          const Color(0xFF00E5FF).withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotGlow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    for (final pt in [points[3], points[5]]) {
      canvas.drawCircle(pt, 5.0, dotGlow);
      canvas.drawCircle(pt, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
