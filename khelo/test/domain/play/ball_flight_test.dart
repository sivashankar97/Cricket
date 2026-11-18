import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/domain/play/ball_flight.dart';

void main() {
  group('BallFlight', () {
    test('advances in fixed 1/60s steps', () {
      final flight = BallFlight();
      flight.advance(1 / 60);
      expect(flight.elapsedSec, closeTo(1 / 60, 1e-9));
      flight.advance(1 / 120);
      expect(flight.elapsedSec, closeTo(1 / 60, 1e-9));
      flight.advance(1 / 120);
      expect(flight.elapsedSec, closeTo(2 / 60, 1e-9));
    });

    test('caps catch-up so a hitch does not dump seconds of simulation', () {
      final flight = BallFlight();
      flight.advance(5);
      expect(flight.elapsedSec, closeTo(BallFlight.maxCatchUpSec, 1e-6));
    });

    test('progress is travel-time normalized and FPS-independent', () {
      final a = BallFlight();
      final b = BallFlight();
      // 30 FPS-ish frames for 0.5s
      for (var i = 0; i < 15; i++) {
        a.advance(1 / 30);
      }
      // 60 FPS frames for 0.5s
      for (var i = 0; i < 30; i++) {
        b.advance(1 / 60);
      }
      expect(a.progress(1000), closeTo(b.progress(1000), 0.02));
      expect(a.progress(1000), closeTo(0.5, 0.02));
    });

    test('reset clears elapsed time', () {
      final flight = BallFlight()..advance(0.2);
      flight.reset();
      expect(flight.elapsedSec, 0);
      expect(flight.progress(1200), 0);
    });
  });
}
