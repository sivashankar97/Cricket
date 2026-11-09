import 'package:cloud_firestore/cloud_firestore.dart';

enum PlayerClaimStatus {
  pending,
  approved,
  declined,

  /// The signed-up user said the added player isn't them.
  dismissed;

  static PlayerClaimStatus fromName(String? name) =>
      PlayerClaimStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => PlayerClaimStatus.pending,
      );
}

/// A signed-up user asking to take over a player an organizer added with the
/// same mobile number. Stored in `player_claims/{playerId}_{claimantId}`.
class PlayerClaim {
  final String id;
  final String playerId;
  final String playerName;
  final String claimantId;
  final String claimantName;
  final String organizerId;
  final PlayerClaimStatus status;

  /// Hashed key of the shared number in `phone_index`, never the number.
  final String? phoneKey;
  final DateTime? createdAt;

  const PlayerClaim({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.claimantId,
    required this.claimantName,
    required this.organizerId,
    this.status = PlayerClaimStatus.pending,
    this.phoneKey,
    this.createdAt,
  });

  static String idFor(String playerId, String claimantId) =>
      '${playerId}_$claimantId';

  factory PlayerClaim.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    return PlayerClaim(
      id: json['id'] as String? ?? '',
      playerId: json['player_id'] as String? ?? '',
      playerName: json['player_name'] as String? ?? '',
      claimantId: json['claimant_id'] as String? ?? '',
      claimantName: json['claimant_name'] as String? ?? '',
      organizerId: json['organizer_id'] as String? ?? '',
      status: PlayerClaimStatus.fromName(json['status'] as String?),
      phoneKey: json['phone_key'] as String?,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'player_name': playerName,
        'claimant_id': claimantId,
        'claimant_name': claimantName,
        'organizer_id': organizerId,
        'status': status.name,
        'phone_key': phoneKey,
        'created_at': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      };
}

/// An added player whose mobile number matches the signed-in user's.
class ClaimablePlayer {
  final String playerId;
  final String playerName;
  final String? photoUrl;
  final String organizerId;
  final int teams;
  final int matches;

  const ClaimablePlayer({
    required this.playerId,
    required this.playerName,
    required this.photoUrl,
    required this.organizerId,
    required this.teams,
    required this.matches,
  });
}
