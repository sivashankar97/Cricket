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

  testWidgets('overlay shows the message without blocking taps',
      (tester) async {
    var taps = 0;
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
              child: GestureDetector(onTap: () => taps++),
            ),
          ),
        ),
      ),
    ));

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
