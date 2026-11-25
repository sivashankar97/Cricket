/// PocketBase backend (Sports Tamil VPS) — escapes Firestore Spark 429s for live scoring.
class PocketBaseConfig {
  PocketBaseConfig._();

  static const url = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'https://pb.sportstamil.network',
  );

  /// When true, Home merges live matches from PocketBase.
  /// Build with: `--dart-define=USE_POCKETBASE_SCORING=true` (default true).
  static const scoringEnabled = bool.fromEnvironment(
    'USE_POCKETBASE_SCORING',
    defaultValue: true,
  );
}
