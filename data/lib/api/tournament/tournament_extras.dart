/// Optional match fields that the generated [MatchModel] doesn't carry
/// (`build_runner` can't regenerate it). Missing on matches made in the app.
class MatchExtras {
  static const numberKey = 'match_number';
  static const stageKey = 'stage';
  static const walkoverWinnerKey = 'walkover_winner_id';

  final int? number;

  /// e.g. "League", "Qualifier 1", "Eliminator", "Final".
  final String? stage;

  /// Set when the match was not played and this team got the win.
  final String? walkoverWinnerId;

  const MatchExtras({this.number, this.stage, this.walkoverWinnerId});

  factory MatchExtras.fromJson(Map<String, dynamic>? json) => MatchExtras(
        number: (json?[numberKey] as num?)?.toInt(),
        stage: json?[stageKey] as String?,
        walkoverWinnerId: json?[walkoverWinnerKey] as String?,
      );
}

/// Optional team fields not on the generated [TeamModel].
class TeamExtras {
  static const ownerNameKey = 'owner_name';
  static const colorKey = 'color';

  final String? ownerName;

  /// Hex colour like `#ffff05`.
  final String? color;

  const TeamExtras({this.ownerName, this.color});

  factory TeamExtras.fromJson(Map<String, dynamic>? json) => TeamExtras(
        ownerName: json?[ownerNameKey] as String?,
        color: json?[colorKey] as String?,
      );
}
