import 'package:aura/app.dart';
import 'package:aura/aura.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Shows the light with no visible controls', (tester) async {
    await tester.pumpWidget(const AuraApp());
    await tester.pumpAndSettle();

    expect(find.byType(AuraPage), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('Vertical drag shows the intensity, then fades', (
    tester,
  ) async {
    await tester.pumpWidget(const AuraApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(AuraPage), const Offset(0, 200));
    await tester.pump();
    expect(find.textContaining(RegExp(r'^\d+$')), findsOneWidget);

    // Let the indicator fade out and the hide timer complete.
    await tester.pump(const Duration(seconds: 2));
  });

  test('Warm light is warmer than cool light', () {
    final warm = kelvinToColor(2000);
    final cool = kelvinToColor(8000);
    expect(warm.b, lessThan(cool.b));
  });
}
