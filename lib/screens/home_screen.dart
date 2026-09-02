import 'package:flutter/material.dart';
import '../models/risk_models.dart';
import '../widgets/liquid_glass_container.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToThreats;

  const HomeScreen({super.key, this.onNavigateToThreats});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  double _stressSimulation = 0.18; // 0.0 to 1.0
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int get _calculatedScore {
    return (96 - (_stressSimulation * 38)).round();
  }

  Color get _scoreColor {
    final score = _calculatedScore;
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 70) return const Color(0xFFFBBF24);
    return const Color(0xFFFF2A6D);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Header
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 14.0),
                child: _buildHeader(),
              ),
            ),
          ),

          // Hero Score Gauge with Liquid Glass Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildHeroScoreCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 18.0)),

          // Quick Action Pills (Mac-style floating pills)
          SliverToBoxAdapter(
            child: _buildQuickActions(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20.0)),

          // Interactive Risk Matrix Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildRiskMatrixSection(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20.0)),

          // Interactive Stress Simulation Slider
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSimulationCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20.0)),

          // Recent Threat Interceptions (Liquid Glass Cards)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildRecentThreatsSection(),
            ),
          ),

          // Extra spacing at bottom so floating dock doesn't obscure content
          const SliverToBoxAdapter(child: SizedBox(height: 120.0)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 38.0,
          height: 38.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00E5FF), Color(0xFFA855F7)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                blurRadius: 10.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 20.0,
            ),
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'RiskGrid',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return Container(
                              width: 5.0,
                              height: 5.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF10B981),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: _pulseController.value),
                                    blurRadius: 4.0,
                                    spreadRadius: 1.0,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 3.0),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                'Defensive Mesh Protocol v2.4',
                style: TextStyle(
                  fontSize: 11.0,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        LiquidGlassContainer(
          borderRadius: 14.0,
          blurSigma: 12.0,
          tintOpacity: 0.25,
          padding: const EdgeInsets.all(8.0),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search filter activated'),
                duration: Duration(milliseconds: 1000),
              ),
            );
          },
          child: const Icon(
            Icons.search_rounded,
            size: 18.0,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroScoreCard() {
    final score = _calculatedScore;
    final color = _scoreColor;

    return LiquidGlassContainer(
      borderRadius: 28.0,
      blurSigma: 24.0,
      tintOpacity: 0.35,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECURITY HEALTH INDEX',
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 38.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.0,
                            shadows: [
                              Shadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 18.0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(
                              color: color.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            score >= 85
                                ? 'OPTIMAL'
                                : score >= 70
                                    ? 'ELEVATED'
                                    : 'CRITICAL',
                            style: TextStyle(
                              color: color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 52.0,
                height: 52.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 4.5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Icon(
                      score >= 85 ? Icons.lock_outline_rounded : Icons.shield_outlined,
                      color: color,
                      size: 20.0,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),
          Container(
            height: 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10.0),

          Row(
            children: [
              Expanded(child: _buildStatChip('Protected', '1,420', Icons.dns_rounded)),
              Expanded(child: _buildStatChip('Blocked', '14.8k', Icons.block_rounded)),
              Expanded(child: _buildStatChip('Latency', '14ms', Icons.speed_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String title, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.0, color: const Color(0xFF00E5FF)),
        const SizedBox(width: 4.0),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'title': 'Full Scan', 'icon': Icons.radar_rounded, 'color': const Color(0xFF00E5FF)},
      {'title': 'Lockdown', 'icon': Icons.lock_person_rounded, 'color': const Color(0xFFFF2A6D)},
      {'title': 'Audit Trail', 'icon': Icons.receipt_long_rounded, 'color': const Color(0xFFA855F7)},
      {'title': 'Firewall', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFBBF24)},
    ];

    return SizedBox(
      height: 38.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final action = actions[index];
          final color = action['color'] as Color;

          return LiquidGlassContainer(
            borderRadius: 20.0,
            blurSigma: 14.0,
            tintOpacity: 0.28,
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${action['title']} executed successfully'),
                  duration: const Duration(milliseconds: 1200),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action['icon'] as IconData, size: 14.0, color: color),
                const SizedBox(width: 6.0),
                Text(
                  action['title'] as String,
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRiskMatrixSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Risk Matrix Grid',
                    style: TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Likelihood vs Impact Heatmap',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Text(
                '4x4 Grid',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00E5FF),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12.0),

        LiquidGlassContainer(
          borderRadius: 24.0,
          blurSigma: 18.0,
          tintOpacity: 0.30,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Column(
                children: List.generate(4, (row) {
                  final impact = 4 - row;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Row(
                      children: List.generate(4, (col) {
                        final likelihood = col + 1;
                        final matchingItems = MockData.riskItems.where(
                          (item) => item.impact == impact && item.likelihood == likelihood,
                        ).toList();

                        final severity = _calculateSeverity(impact, likelihood);
                        final hasItems = matchingItems.isNotEmpty;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: GestureDetector(
                              onTap: () {
                                if (hasItems) {
                                  _showRiskDetailModal(matchingItems.first);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Sector Impact:$impact Likelihood:$likelihood • 0 active threats',
                                      ),
                                      duration: const Duration(milliseconds: 1000),
                                    ),
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 42.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: severity.color.withValues(
                                    alpha: hasItems ? 0.35 : 0.08,
                                  ),
                                  border: Border.all(
                                    color: severity.color.withValues(
                                      alpha: hasItems ? 0.8 : 0.2,
                                    ),
                                    width: hasItems ? 1.4 : 0.7,
                                  ),
                                  boxShadow: hasItems
                                      ? [
                                          BoxShadow(
                                            color: severity.color.withValues(alpha: 0.35),
                                            blurRadius: 6.0,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: hasItems
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              size: 11.0,
                                              color: severity.color,
                                            ),
                                            const SizedBox(width: 2.0),
                                            Text(
                                              '${matchingItems.length}',
                                              style: TextStyle(
                                                color: severity.color,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          '${impact}x$likelihood',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 6.0),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('Low', RiskSeverity.low.color),
                  _buildLegendItem('Med', RiskSeverity.medium.color),
                  _buildLegendItem('High', RiskSeverity.high.color),
                  _buildLegendItem('Crit', RiskSeverity.critical.color),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  RiskSeverity _calculateSeverity(int impact, int likelihood) {
    final score = impact * likelihood;
    if (score >= 12) return RiskSeverity.critical;
    if (score >= 8) return RiskSeverity.high;
    if (score >= 4) return RiskSeverity.medium;
    return RiskSeverity.low;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6.0,
          height: 6.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 3.0,
              ),
            ],
          ),
        ),
        const SizedBox(width: 3.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.0,
            color: Colors.white.withValues(alpha: 0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationCard() {
    return LiquidGlassContainer(
      borderRadius: 24.0,
      blurSigma: 18.0,
      tintOpacity: 0.28,
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 15.0,
                      color: Color(0xFF00E5FF),
                    ),
                    SizedBox(width: 5.0),
                    Flexible(
                      child: Text(
                        'Stress Simulator',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(_stressSimulation * 100).toInt()}% LOAD',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00E5FF),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Simulate botnet pressure to test real-time grid resilience',
            style: TextStyle(
              fontSize: 11.0,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6.0),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              activeTrackColor: const Color(0xFF00E5FF),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
            ),
            child: Slider(
              value: _stressSimulation,
              min: 0.0,
              max: 1.0,
              onChanged: (val) => setState(() => _stressSimulation = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentThreatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Live Threat Interceptions',
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            GestureDetector(
              onTap: widget.onNavigateToThreats,
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00E5FF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        Column(
          children: MockData.threatIncidents.take(3).map((incident) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: LiquidGlassContainer(
                borderRadius: 20.0,
                blurSigma: 16.0,
                tintOpacity: 0.28,
                padding: const EdgeInsets.all(14.0),
                onTap: () => _showThreatDetailModal(incident),
                child: Row(
                  children: [
                    Container(
                      width: 36.0,
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: incident.severity.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: incident.severity.color.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          incident.icon,
                          color: incident.severity.color,
                          size: 18.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            incident.target,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: incident.severity.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            incident.status,
                            style: TextStyle(
                              color: incident.severity.color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          incident.timestamp,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showRiskDetailModal(RiskMatrixItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: LiquidGlassContainer(
            borderRadius: 32.0,
            blurSigma: 24.0,
            tintOpacity: 0.5,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: item.severity.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: item.severity.color, width: 1.0),
                      ),
                      child: Text(
                        '${item.id} • ${item.severity.label.toUpperCase()}',
                        style: TextStyle(
                          color: item.severity.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.0,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20.0),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Sector: ${item.category} | Impact: ${item.impact}/4 | Likelihood: ${item.likelihood}/4',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 13.0, color: Colors.white, height: 1.35),
                ),
                const SizedBox(height: 12.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16.0),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          item.mitigation,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mitigation playbook queued for ${item.id}')),
                      );
                    },
                    child: const Text(
                      'Dispatch Auto-Mitigation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThreatDetailModal(ThreatIncident incident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: LiquidGlassContainer(
            borderRadius: 32.0,
            blurSigma: 24.0,
            tintOpacity: 0.5,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      incident.id,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 12.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20.0),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  incident.title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Target: ${incident.target}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  incident.details,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.35),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Dismiss', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF2A6D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Target node isolated: ${incident.target}')),
                          );
                        },
                        child: const Text('Isolate Node', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
