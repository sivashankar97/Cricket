import 'dart:math';

/// Fixed-timestep ball clock (seconds), independent of display FPS.
///
/// Simulation time advances in [stepSec] slices with a catch-up cap.
/// Render / judgment time includes the leftover partial step so progress
/// stays smooth and matches wall time fed through [advance].
class BallFlight {
  static const stepSec = 1 / 60;
  /// Long enough for one full delivery + late window (~1.73s) so a single
  /// long frame (or widget-test pump) can finish the ball instead of stalling.
  static const maxCatchUpSec = 2.0;

  /// Committed simulation time (whole steps only).
  double elapsedSec = 0;
  double _accumulator = 0;

  void reset() {
    elapsedSec = 0;
    _accumulator = 0;
  }

  /// Advance by [dt] seconds (capped). Call once per frame from a ticker.
  void advance(double dt) {
    _accumulator += min(max(dt, 0), maxCatchUpSec);
    while (_accumulator >= stepSec) {
      elapsedSec += stepSec;
      _accumulator -= stepSec;
    }
  }

  /// Wall-clock time including the partial step (for drawing + tap timing).
  double get renderElapsedSec => elapsedSec + _accumulator;

  /// 0 at release, 1 at bat; may exceed 1 during the late window.
  double progress(int travelMs) {
    if (travelMs <= 0) return 0;
    return renderElapsedSec * 1000 / travelMs;
  }

  int elapsedMs() => (renderElapsedSec * 1000).round();
}
