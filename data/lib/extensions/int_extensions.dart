extension OverExtensionOnInt on int {
  double toOvers({int ballsPerOver = 6}) {
    final int overs = this ~/ ballsPerOver;
    final int additionalBalls = this % ballsPerOver;
    return double.parse("$overs.$additionalBalls");
  }
}
