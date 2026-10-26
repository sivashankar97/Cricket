import 'package:flutter/foundation.dart';

/// Mobile iOS. Web and desktop keep the Material UI path.
bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Mobile Android.
bool get isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
