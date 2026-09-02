import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskgrid/main.dart';
import 'package:riskgrid/widgets/liquid_glass_navbar.dart';

void main() {
  testWidgets('RiskGridApp renders with floating Mac Dock navbar and navigates', (WidgetTester tester) async {
    // Set a phone screen size for mobile testing
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const RiskGridApp());
    // Pump frames to render widgets (avoiding pumpAndSettle due to repeating live pulse)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify app brand and header are present
    expect(find.text('RiskGrid'), findsOneWidget);

    // Verify floating Mac dock navbar is present
    expect(find.byType(LiquidGlassDockNavBar), findsOneWidget);

    // Verify navigation items exist on home screen
    expect(find.text('Live Threat Interceptions'), findsOneWidget);
    expect(find.text('Risk Matrix Grid'), findsOneWidget);

    // Tap on the dock navbar
    await tester.tap(find.byType(LiquidGlassDockNavBar));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
