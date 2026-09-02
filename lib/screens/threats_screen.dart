import 'package:flutter/material.dart';
import '../models/risk_models.dart';
import '../widgets/liquid_glass_container.dart';

class ThreatsScreen extends StatefulWidget {
  const ThreatsScreen({super.key});

  @override
  State<ThreatsScreen> createState() => _ThreatsScreenState();
}

class _ThreatsScreenState extends State<ThreatsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Critical', 'High', 'Medium', 'Low'];

  List<ThreatIncident> get _filteredIncidents {
    if (_selectedFilter == 'All') return MockData.threatIncidents;
    return MockData.threatIncidents.where(
      (inc) => inc.severity.label.toLowerCase() == _selectedFilter.toLowerCase(),
    ).toList();
  }

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
                            'Threat Stream',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Active Interceptions & Logs',
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
                          Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF2A6D),
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          const Text(
                            '3 ACTIVE',
                            style: TextStyle(
                              color: Color(0xFFFF2A6D),
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

          // Filter Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 36.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8.0),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.12),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16.0)),

          // Incident Cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final incident = _filteredIncidents[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildIncidentCard(incident),
                  );
                },
                childCount: _filteredIncidents.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120.0)),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(ThreatIncident incident) {
    return LiquidGlassContainer(
      borderRadius: 22.0,
      blurSigma: 18.0,
      tintOpacity: 0.30,
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: incident.severity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.0),
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
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          incident.id,
                          style: TextStyle(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.85),
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          incident.timestamp,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      incident.title,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      incident.target,
                      style: TextStyle(
                        fontSize: 11.0,
                        color: Colors.white.withValues(alpha: 0.55),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            incident.details,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12.0),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: incident.severity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: incident.severity.color.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${incident.severity.label.toUpperCase()} • ${incident.status}',
                  style: TextStyle(
                    color: incident.severity.color,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniAction('Inspect', Icons.search_rounded, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Inspecting packets for ${incident.id}')),
                    );
                  }),
                  const SizedBox(width: 6.0),
                  _buildMiniAction('Remediate', Icons.auto_fix_high_rounded, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Remediation playbook initiated for ${incident.id}')),
                    );
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.0, color: Colors.white),
            const SizedBox(width: 3.0),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.0,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
