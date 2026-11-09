import '../match/match_model.dart';

/// Extra fields on a `tournaments` doc, kept outside the freezed
/// `TournamentModel` (written with a separate update, merged on save).
class TournamentDetails {
  static const cityKey = 'city';
  static const groundKey = 'ground';
  static const ballTypeKey = 'ball_type';
  static const oversPerMatchKey = 'overs_per_match';

  static const maxOvers = 50;

  final String? city;
  final String? ground;

  /// Stored as [BallType.value], same as on matches.
  final BallType? ballType;
  final int? oversPerMatch;

  const TournamentDetails({
    this.city,
    this.ground,
    this.ballType,
    this.oversPerMatch,
  });

  factory TournamentDetails.fromJson(Map<String, dynamic>? json) =>
      TournamentDetails(
        city: json?[cityKey] as String?,
        ground: json?[groundKey] as String?,
        ballType: BallType.values
            .where((type) => type.value == json?[ballTypeKey])
            .firstOrNull,
        oversPerMatch: (json?[oversPerMatchKey] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        cityKey: city,
        groundKey: ground,
        ballTypeKey: ballType?.value,
        oversPerMatchKey: oversPerMatch,
      };

  bool get isComplete =>
      (city?.trim().isNotEmpty ?? false) &&
      (ground?.trim().isNotEmpty ?? false) &&
      ballType != null &&
      oversPerMatch != null &&
      oversPerMatch! >= 1 &&
      oversPerMatch! <= maxOvers;

  bool get isEmpty =>
      city == null &&
      ground == null &&
      ballType == null &&
      oversPerMatch == null;

  @override
  bool operator ==(Object other) =>
      other is TournamentDetails &&
      other.city == city &&
      other.ground == ground &&
      other.ballType == ballType &&
      other.oversPerMatch == oversPerMatch;

  @override
  int get hashCode => Object.hash(city, ground, ballType, oversPerMatch);
}
