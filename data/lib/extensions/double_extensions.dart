import 'int_extensions.dart';

extension OverExtensionOnDouble on double {
  double add(int ballsToAdd, {int ballsPerOver = 6}) {
    final int totalBalls = toBalls(ballsPerOver: ballsPerOver) + ballsToAdd;
    return totalBalls.toOvers(ballsPerOver: ballsPerOver);
  }

  double remove(int ballsToRemove, {int ballsPerOver = 6}) {
    int totalBalls = toBalls(ballsPerOver: ballsPerOver) - ballsToRemove;
    if (totalBalls < 0) totalBalls = 0;
    return totalBalls.toOvers(ballsPerOver: ballsPerOver);
  }

  int getBallNumberFromOver() {
    final String valueString = toString();

    final List<String> parts = valueString.split('.');

    if (parts.length > 1) {
      return int.parse(parts[1]);
    } else {
      return 0;
    }
  }

  int getOverNumberFromOver() {
    return toInt();
  }

  int toBalls({int ballsPerOver = 6}) {
    return (getOverNumberFromOver() * ballsPerOver) + getBallNumberFromOver();
  }
}
