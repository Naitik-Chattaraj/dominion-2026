import 'package:flutter/material.dart';
import '../widgets/liquid_glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _blurSigma = 18.0;
  double _tintOpacity = 0.308;
  double _cardRadius = 40.0;
  bool _showNoise = true;
  bool _showCaustic = true;
  bool _showShine = true;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Liquid Glass Studio',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Real-time SVG & CSS Shader Customizer',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Live Sandbox Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE MATERIAL PREVIEW',
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  // The live preview container using current slider variables
                  LiquidGlassContainer(
                    borderRadius: _cardRadius,
                    blurSigma: _blurSigma,
                    tintOpacity: _tintOpacity,
                    showNoise: _showNoise,
                    showCausticRefraction: _showCaustic,
                    showShine: _showShine,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Color(0xFF00E5FF),
                                    size: 16.0,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                const Text(
                                  'Liquid Glass Shader',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: const Color(0xFFA855F7).withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                'SVG feTurbulence',
                                style: TextStyle(
                                  color: Color(0xFFA855F7),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'Recreating .liquidGlass-tint rgba(20, 1, 31, ${_tintOpacity.toStringAsFixed(3)}), corner specular radial gradients, and blur ${_blurSigma.toInt()}px.',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20.0)),

          // Customization Controls
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LiquidGlassContainer(
                borderRadius: 26.0,
                blurSigma: 20.0,
                tintOpacity: 0.32,
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CSS & SVG Parameters',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // Blur Sigma Slider
                    _buildSliderRow(
                      'Backdrop Blur Sigma',
                      '${_blurSigma.toInt()} px',
                      _blurSigma,
                      2.0,
                      36.0,
                      (val) => setState(() => _blurSigma = val),
                    ),

                    // Tint Opacity Slider
                    _buildSliderRow(
                      'Dark Violet Tint Opacity',
                      '${(_tintOpacity * 100).toInt()}%',
                      _tintOpacity,
                      0.05,
                      0.85,
                      (val) => setState(() => _tintOpacity = val),
                    ),

                    // Card Radius Slider
                    _buildSliderRow(
                      'Corner Radius (--card-radius)',
                      '${_cardRadius.toInt()} px',
                      _cardRadius,
                      12.0,
                      50.0,
                      (val) => setState(() => _cardRadius = val),
                    ),

                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 20.0),

                    // Toggles for visual layers
                    _buildToggleRow(
                      'Specular Edge & Corner Shines',
                      '.liquidGlass-shine ::before & ::after',
                      _showShine,
                      (val) => setState(() => _showShine = val),
                    ),
                    const SizedBox(height: 10.0),
                    _buildToggleRow(
                      'Caustic Refraction Light',
                      'SVG feSpecularLighting at (-200,-200,300)',
                      _showCaustic,
                      (val) => setState(() => _showCaustic = val),
                    ),
                    const SizedBox(height: 10.0),
                    _buildToggleRow(
                      'Frosted Glass Micro-Noise',
                      'SVG feTurbulence fractalNoise 0.07 opacity',
                      _showNoise,
                      (val) => setState(() => _showNoise = val),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16.0)),

          // Platform & Architecture Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LiquidGlassContainer(
                borderRadius: 22.0,
                blurSigma: 16.0,
                tintOpacity: 0.28,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(Icons.speed_rounded, color: Color(0xFF10B981), size: 22.0),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skia / Impeller Hardware Glass',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Native GPU pipeline executing backdrop blur, specular caustics and noise shaders at 60+ FPS.',
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
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120.0)),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    String label,
    String valueText,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                valueText,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00E5FF),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              activeTrackColor: const Color(0xFF00E5FF),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
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
}
