import 'package:flutter/material.dart';

enum RiskSeverity {
  low,
  medium,
  high,
  critical,
}

extension RiskSeverityX on RiskSeverity {
  String get label {
    switch (this) {
      case RiskSeverity.low:
        return 'Low';
      case RiskSeverity.medium:
        return 'Medium';
      case RiskSeverity.high:
        return 'High';
      case RiskSeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case RiskSeverity.low:
        return const Color(0xFF10B981); // Emerald
      case RiskSeverity.medium:
        return const Color(0xFFFBBF24); // Amber
      case RiskSeverity.high:
        return const Color(0xFFF97316); // Orange
      case RiskSeverity.critical:
        return const Color(0xFFFF2A6D); // Crimson
    }
  }
}

class RiskMatrixItem {
  final String id;
  final String title;
  final String category;
  final int impact; // 1 to 4
  final int likelihood; // 1 to 4
  final RiskSeverity severity;
  final String description;
  final String mitigation;

  const RiskMatrixItem({
    required this.id,
    required this.title,
    required this.category,
    required this.impact,
    required this.likelihood,
    required this.severity,
    required this.description,
    required this.mitigation,
  });
}

class ThreatIncident {
  final String id;
  final String title;
  final String target;
  final RiskSeverity severity;
  final String timestamp;
  final String status;
  final IconData icon;
  final String details;

  const ThreatIncident({
    required this.id,
    required this.title,
    required this.target,
    required this.severity,
    required this.timestamp,
    required this.status,
    required this.icon,
    required this.details,
  });
}

class NetworkNode {
  final String name;
  final String city;
  final String region;
  final int latencyMs;
  final double uptime;
  final bool isHealthy;
  final String ipAddress;
  final int activeThreatsScrubbed;

  const NetworkNode({
    required this.name,
    required this.city,
    required this.region,
    required this.latencyMs,
    required this.uptime,
    required this.isHealthy,
    required this.ipAddress,
    required this.activeThreatsScrubbed,
  });
}

class MockData {
  static const List<RiskMatrixItem> riskItems = [
    RiskMatrixItem(
      id: 'R-101',
      title: 'DDoS Amplification Attack',
      category: 'Infrastructure',
      impact: 4,
      likelihood: 3,
      severity: RiskSeverity.critical,
      description: 'Volumetric NTP & DNS amplification targeting edge ingress routers.',
      mitigation: 'Automated anycast traffic redirection & rate limit scrubbing active.',
    ),
    RiskMatrixItem(
      id: 'R-102',
      title: 'Smart Contract Reentrancy',
      category: 'Application',
      impact: 4,
      likelihood: 1,
      severity: RiskSeverity.high,
      description: 'Potential cross-function vulnerability in liquidity settlement pool.',
      mitigation: 'Formal verification guard & nonReentrant modifier verified in v2.4.',
    ),
    RiskMatrixItem(
      id: 'R-103',
      title: 'Credential Stuffing Botnet',
      category: 'Identity',
      impact: 2,
      likelihood: 4,
      severity: RiskSeverity.medium,
      description: 'Distributed brute-force attempt against customer login gateways.',
      mitigation: 'Adaptive CAPTCHA triggered; 99.4% malicious requests blocked.',
    ),
    RiskMatrixItem(
      id: 'R-104',
      title: 'API Rate Limit Exhaustion',
      category: 'API Gateway',
      impact: 2,
      likelihood: 2,
      severity: RiskSeverity.low,
      description: 'Non-critical analytics endpoint experiencing bursts above standard quota.',
      mitigation: 'Token bucket throttler engaged; graceful degradation active.',
    ),
    RiskMatrixItem(
      id: 'R-105',
      title: 'Oracle Deviation Lag',
      category: 'DeFi/Data',
      impact: 3,
      likelihood: 2,
      severity: RiskSeverity.medium,
      description: 'High network volatility causing 1.2s delay in secondary price feed.',
      mitigation: 'Multi-source TWAP consensus fallback automatically invoked.',
    ),
  ];

  static const List<ThreatIncident> threatIncidents = [
    ThreatIncident(
      id: 'INC-8921',
      title: 'Zero-Day Exploit Probe Blocked',
      target: 'us-east.gateway.riskgrid.net',
      severity: RiskSeverity.critical,
      timestamp: '2m ago',
      status: 'Quarantined',
      icon: Icons.shield_outlined,
      details: 'WAF signature match for unauthenticated RCE probe. Source IP 185.220.101.44 isolated across all clusters.',
    ),
    ThreatIncident(
      id: 'INC-8920',
      title: 'Anomalous Transaction Volume',
      target: 'polygon.bridge.contract',
      severity: RiskSeverity.high,
      timestamp: '11m ago',
      status: 'Analyzing',
      icon: Icons.warning_amber_rounded,
      details: 'Sudden 420% spike in withdrawal velocity. Circuit breaker threshold reached; temporary 5-minute cool-off initiated.',
    ),
    ThreatIncident(
      id: 'INC-8919',
      title: 'Encrypted Tunnel Heartbeat Loss',
      target: 'singapore-sg1.node',
      severity: RiskSeverity.medium,
      timestamp: '34m ago',
      status: 'Rerouted',
      icon: Icons.sync_problem_rounded,
      details: 'Underwater fiber optic packet degradation detected. Traffic smoothly rerouted via Tokyo primary backbone.',
    ),
    ThreatIncident(
      id: 'INC-8918',
      title: 'SSH Key Rotation Enforced',
      target: 'auth.bastion-host-01',
      severity: RiskSeverity.low,
      timestamp: '1h ago',
      status: 'Completed',
      icon: Icons.verified_user_outlined,
      details: 'Scheduled 30-day credential renewal successfully finished across 14 bastion instances.',
    ),
  ];

  static const List<NetworkNode> nodes = [
    NetworkNode(
      name: 'US-East Primary',
      city: 'Virginia',
      region: 'North America',
      latencyMs: 12,
      uptime: 99.99,
      isHealthy: true,
      ipAddress: '198.51.100.22',
      activeThreatsScrubbed: 4120,
    ),
    NetworkNode(
      name: 'EU-Central Node',
      city: 'Frankfurt',
      region: 'Europe',
      latencyMs: 18,
      uptime: 99.98,
      isHealthy: true,
      ipAddress: '192.0.2.89',
      activeThreatsScrubbed: 2840,
    ),
    NetworkNode(
      name: 'Asia-Pacific Core',
      city: 'Tokyo',
      region: 'Asia',
      latencyMs: 34,
      uptime: 99.95,
      isHealthy: true,
      ipAddress: '203.0.113.45',
      activeThreatsScrubbed: 1950,
    ),
    NetworkNode(
      name: 'South America Edge',
      city: 'São Paulo',
      region: 'South America',
      latencyMs: 72,
      uptime: 99.92,
      isHealthy: true,
      ipAddress: '198.51.100.91',
      activeThreatsScrubbed: 820,
    ),
    NetworkNode(
      name: 'UK-London Gateway',
      city: 'London',
      region: 'Europe',
      latencyMs: 15,
      uptime: 99.99,
      isHealthy: true,
      ipAddress: '192.0.2.112',
      activeThreatsScrubbed: 3100,
    ),
    NetworkNode(
      name: 'Oceania Edge',
      city: 'Sydney',
      region: 'Australia',
      latencyMs: 88,
      uptime: 99.90,
      isHealthy: true,
      ipAddress: '203.0.113.199',
      activeThreatsScrubbed: 640,
    ),
  ];
}
