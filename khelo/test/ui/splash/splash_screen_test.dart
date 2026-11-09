import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/ui/flow/splash/splash_screen.dart';

void main() {
  testWidgets('static splash shows every logo layer', (tester) async {
    await tester.pumpWidget(const SplashScreen(animate: false));

    expect(find.byType(SvgPicture), findsNWidgets(6));
  });

  testWidgets('animated splash finishes with every logo layer', (tester) async {
    await tester.pumpWidget(const SplashScreen(animate: true));
    expect(find.byType(SvgPicture), findsOneWidget);

    await tester.pump(SplashScreen.animationDuration);
    expect(find.byType(SvgPicture), findsNWidgets(6));

    await tester.pumpWidget(const SizedBox());
  });

  test('main waits for the animation on mobile', () {
    expect(SplashScreen.minVisibleDuration, SplashScreen.animationDuration);
  });
}
