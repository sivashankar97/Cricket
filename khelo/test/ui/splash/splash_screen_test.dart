import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/ui/flow/splash/splash_screen.dart';

void main() {
  testWidgets('starts on plain red while the artwork loads', (tester) async {
    await tester.pumpWidget(const SplashScreen());

    final box = tester.widget<ColoredBox>(find.byType(ColoredBox));
    expect(box.color, const Color(0xFFFB131A));
    expect(find.byType(CustomPaint), findsNothing);
  });

  testWidgets('paints every phase of the animation', (tester) async {
    await tester.pumpWidget(const SplashScreen());
    await tester.runAsync(() async {
      for (var i = 0;
          i < 50 && find.byType(ColoredBox).evaluate().isNotEmpty;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    expect(find.byType(ColoredBox), findsNothing);

    // Dot, ring, stroke, sweep, bars, rings, text, swoosh.
    for (var ms = 0; ms <= 5800; ms += 200) {
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: 'at ${ms}ms');
    }

    // Still loading after the hold: the loading dots appear.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Row), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  test('main waits for the animation and the hold', () {
    expect(
      SplashScreen.minVisibleDuration,
      SplashScreen.animationDuration + const Duration(milliseconds: 600),
    );
  });
}
