import 'package:flutter/material.dart';
import '../models/risk_models.dart';
import '../widgets/liquid_glass_container.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  bool _quantumSafe = true;
  bool _ddosScrubbing = true;
  bool _aiAnomalyDetection = true;

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
                            'Sentinel Mesh',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Distributed Global Edge Infrastructure',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    LiquidGlassContainer(
                      borderRadius: 14.0,
                      blurSigma: 12.0,
                      tintOpacity: 0.25,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hub_rounded, size: 13.0, color: Color(0xFF10B981)),
                          const SizedBox(width: 5.0),
                          Text(
                            '${MockData.nodes.length} NODES',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Security Defense Switches
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildDefenseSwitchesCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 18.0)),

          // Nodes Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Sentinel Clusters',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Avg 32ms Latency',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10.0)),

          // Node List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final node = MockData.nodes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildNodeCard(node),
                  );
                },
                childCount: MockData.nodes.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120.0)),
        ],
      ),
    );
  }

  Widget _buildDefenseSwitchesCard() {
    return LiquidGlassContainer(
      borderRadius: 24.0,
      blurSigma: 20.0,
      tintOpacity: 0.32,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Autonomous Safeguards',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          _buildSwitchRow(
            'Quantum-Safe TLS 1.3',
            'Kyber-1024 hybrid encapsulation',
            _quantumSafe,
            (val) => setState(() => _quantumSafe = val),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 16.0),
          _buildSwitchRow(
            'Volumetric DDoS Scrubbing',
            'Anycast network with 40Tbps capacity',
            _ddosScrubbing,
            (val) => setState(() => _ddosScrubbing = val),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 16.0),
          _buildSwitchRow(
            'Neural Anomaly Patrol',
            'Real-time behavioral classification',
            _aiAnomalyDetection,
            (val) => setState(() => _aiAnomalyDetection = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeColor: const Color(0xFF00E5FF),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNodeCard(NetworkNode node) {
    final latencyColor = node.latencyMs < 30
        ? const Color(0xFF10B981)
        : node.latencyMs < 60
            ? const Color(0xFFFBBF24)
            : const Color(0xFFFF2A6D);

    return LiquidGlassContainer(
      borderRadius: 20.0,
      blurSigma: 16.0,
      tintOpacity: 0.28,
      padding: const EdgeInsets.all(14.0),
      child: Row(
        children: [
          Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.8,
              ),
            ),
            child: const Center(
              child: Icon(Icons.dns_rounded, color: Color(0xFF00E5FF), size: 18.0),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        node.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    Container(
                      width: 5.0,
                      height: 5.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  '${node.city} • ${node.ipAddress}',
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 13.0, color: latencyColor),
                  Text(
                    '${node.latencyMs}ms',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: latencyColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2.0),
              Text(
                '${node.uptime}% Up',
                style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
