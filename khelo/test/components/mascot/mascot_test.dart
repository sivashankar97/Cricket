import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/components/mascot/mascot_overlay.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/theme.dart';

void main() {
  group('MascotController', () {
    test('shows a cue and hides it after the duration', () async {
      final mascot = MascotController(() => true);
      mascot.show(MascotPose.welcome, 'Hi',
          duration: const Duration(milliseconds: 20));
      expect(mascot.state?.message, 'Hi');
      await Future.delayed(const Duration(milliseconds: 40));
      expect(mascot.state, isNull);
      mascot.dispose();
    });

    test('does nothing when turned off', () {
      final mascot = MascotController(() => false);
      mascot.show(MascotPose.welcome, 'Hi');
      expect(mascot.state, isNull);
      mascot.dispose();
    });

    test('onceKey shows only once', () {
      final mascot = MascotController(() => true);
      mascot.show(MascotPose.welcome, 'First', onceKey: 'k');
      mascot.hide();
      mascot.show(MascotPose.welcome, 'Again', onceKey: 'k');
      expect(mascot.state, isNull);
      mascot.dispose();
    });

    test('delay keeps only the latest call', () async {
      final mascot = MascotController(() => true);
      mascot.show(MascotPose.welcome, 'A',
          delay: const Duration(milliseconds: 20));
      mascot.show(MascotPose.welcome, 'AB',
          delay: const Duration(milliseconds: 20));
      expect(mascot.state, isNull);
      await Future.delayed(const Duration(milliseconds: 40));
      expect(mascot.state?.message, 'AB');
      mascot.dispose();
    });

    test('onlyWhenIdle does not interrupt, and keeps its onceKey', () {
      final mascot = MascotController(() => true);
      mascot.show(MascotPose.celebrate, 'Saved');
      mascot.show(MascotPose.welcome, 'Hi', onlyWhenIdle: true, onceKey: 'k');
      expect(mascot.state?.message, 'Saved');
      mascot.hide();
      mascot.show(MascotPose.welcome, 'Hi', onlyWhenIdle: true, onceKey: 'k');
      expect(mascot.state?.message, 'Hi');
      mascot.dispose();
    });

    test('every pose has an asset path', () {
      for (final pose in MascotPose.values) {
        expect(pose.asset, startsWith('assets/images/mascot/'));
      }
    });
  });

  Future<ProviderContainer> pumpOverlay(
    WidgetTester tester, {
    VoidCallback? onTap,
  }) async {
    final container = ProviderContainer(overrides: [
      mascotProvider.overrideWith((ref) => MascotController(() => true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: AppTheme(
        colorScheme: appColorSchemeLight,
        child: MaterialApp(
          builder: (context, child) => MascotOverlay(child: child!),
          home: Scaffold(
            body: SizedBox.expand(
              child: GestureDetector(onTap: onTap),
            ),
          ),
        ),
      ),
    ));
    return container;
  }

  testWidgets('tiger peeks in from the right edge', (tester) async {
    final container = await pumpOverlay(tester);
    container
        .read(mascotProvider.notifier)
        .show(MascotPose.welcome, 'Hi!', duration: const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final tiger = tester.getRect(find.byType(Image));
    final bubble = tester.getRect(find.text('Hi!'));
    expect(tiger.center.dx, greaterThan(screenWidth / 2));
    expect(bubble.right, lessThan(tiger.right));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'a tap right after it appears keeps the tiger; a later tap or '
      'scroll sends it away', (tester) async {
    var taps = 0;
    final container = await pumpOverlay(tester, onTap: () => taps++);
    final mascot = container.read(mascotProvider.notifier);

    mascot.show(MascotPose.welcome, 'Hi!',
        duration: const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(const Offset(20, 20));
    expect(container.read(mascotProvider), isNotNull);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.tapAt(const Offset(20, 20));
    expect(taps, 2);
    expect(container.read(mascotProvider), isNull);
    await tester.pumpAndSettle();

    mascot.show(MascotPose.welcome, 'Again',
        duration: const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 900));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    pointer.hover(const Offset(20, 20));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
    expect(container.read(mascotProvider), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('overlay shows the message without blocking taps',
      (tester) async {
    var taps = 0;
    final container = await pumpOverlay(tester, onTap: () => taps++);

    container.read(mascotProvider.notifier).show(MascotPose.welcome, 'Hi Anu!',
        duration: const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Hi Anu!'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.text('Hi Anu!')));
    expect(taps, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Hi Anu!'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });
}
