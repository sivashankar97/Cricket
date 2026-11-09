import 'dart:async';
import 'dart:math';

import 'package:data/storage/provider/preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Poses cut from the Sports Tamil tiger action sheet.
/// Files live in `assets/images/mascot/<snake_case>.webp`.
enum MascotPose {
  welcome('welcome'),
  registered('registered'),
  loginSuccess('login_success'),
  saved('saved'),
  thinking('thinking'),
  loading('loading'),
  warning('warning'),
  error('error'),
  noRecords('no_records'),
  notification('notification'),
  search('search'),
  help('help'),
  celebrate('celebrate'),
  success('success'),
  noInternet('no_internet'),
  maintenance('maintenance');

  const MascotPose(this.file);

  final String file;

  String get asset => 'assets/images/mascot/$file.webp';
}

class MascotCue {
  final int id;
  final MascotPose pose;
  final String message;

  /// Extra space kept free above the bottom of the screen (or keyboard),
  /// e.g. for tall sticky buttons.
  final double lift;

  /// Shows near the top instead, for screens with controls at the bottom
  /// (score board).
  final bool top;

  /// False for sign-in, error and warning cues: tapping the tiger must not
  /// replace them with a movie line.
  final bool allowFun;

  const MascotCue({
    required this.id,
    required this.pose,
    required this.message,
    required this.lift,
    this.top = false,
    this.allowFun = true,
  });
}

final mascotEnabledPod = createPrefProvider<bool>(
  prefKey: 'mascot_enabled',
  defaultValue: true,
);

final mascotProvider =
    StateNotifierProvider<MascotController, MascotCue?>((ref) {
  return MascotController(() => ref.read(mascotEnabledPod));
});

class MascotController extends StateNotifier<MascotCue?> {
  MascotController(this._isEnabled)
      : _movieTurn = Random().nextInt(100),
        super(null);

  static const defaultLift = 110.0;

  final bool Function() _isEnabled;
  final Set<String> _shownKeys = {};
  Timer? _hideTimer;
  Timer? _pendingTimer;
  int _nextId = 0;
  int _movieTurn;

  MascotCue? get current => state;

  /// Steps through the movie lines so the same one never shows twice in a row.
  int takeMovieTurn() => _movieTurn++;

  /// Long enough to read [message]; never shorter than [minimum].
  static Duration readingTime(String message, [Duration? minimum]) {
    final ms = (1800 + message.length * 55).clamp(2500, 8000);
    final readable = Duration(milliseconds: ms);
    return minimum != null && minimum > readable ? minimum : readable;
  }

  /// Shows [message] with [pose] and hides it after [duration] (by default,
  /// long enough to read it).
  ///
  /// [onceKey] shows the cue only once per app session.
  /// [delay] debounces: a newer call before the delay ends replaces this one.
  /// [onlyWhenIdle] skips the cue if another one is on screen.
  void show(
    MascotPose pose,
    String message, {
    Duration? duration,
    Duration delay = Duration.zero,
    String? onceKey,
    bool onlyWhenIdle = false,
    double lift = defaultLift,
    bool top = false,
    bool allowFun = true,
  }) {
    _pendingTimer?.cancel();
    if (!_isEnabled()) return;
    if (onceKey != null && _shownKeys.contains(onceKey)) return;

    void present() {
      if (!mounted || (onlyWhenIdle && state != null)) return;
      if (onceKey != null) _shownKeys.add(onceKey);
      _hideTimer?.cancel();
      state = MascotCue(
        id: _nextId++,
        pose: pose,
        message: message,
        lift: lift,
        top: top,
        allowFun: allowFun,
      );
      _hideTimer = Timer(duration ?? readingTime(message), hide);
    }

    if (delay == Duration.zero) {
      present();
    } else {
      _pendingTimer = Timer(delay, present);
    }
  }

  void hide() {
    _pendingTimer?.cancel();
    _hideTimer?.cancel();
    if (mounted) state = null;
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }
}
