import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../extensions/string_extensions.dart';
import '../tournament_team/tournament_team_model.dart';

enum AuctionStatus {
  /// Being prepared; only admins can see it.
  draft('draft'),

  /// Published, not started yet.
  upcoming('upcoming'),
  live('live'),
  paused('paused'),
  completed('completed');

  final String value;

  const AuctionStatus(this.value);

  static AuctionStatus fromValue(Object? value) => AuctionStatus.values
      .firstWhere((s) => s.value == value, orElse: () => AuctionStatus.draft);

  /// Statuses anyone can see, signed in or not.
  static List<AuctionStatus> get published => const [
        AuctionStatus.upcoming,
        AuctionStatus.live,
        AuctionStatus.paused,
        AuctionStatus.completed,
      ];

  bool get isSetup =>
      this == AuctionStatus.draft || this == AuctionStatus.upcoming;

  bool get isRunning =>
      this == AuctionStatus.live || this == AuctionStatus.paused;
}

enum AuctionPlayerStatus {
  available('available'),
  retained('retained'),
  inAuction('in_auction'),
  sold('sold'),
  unsold('unsold');

  final String value;

  const AuctionPlayerStatus(this.value);

  static AuctionPlayerStatus fromValue(Object? value) =>
      AuctionPlayerStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => AuctionPlayerStatus.available,
      );

  /// The player belongs to a team (bought or retained).
  bool get isOnTeam =>
      this == AuctionPlayerStatus.sold || this == AuctionPlayerStatus.retained;
}

/// Why an auction action was rejected.
enum AuctionError {
  notEditable,
  notLive,
  paused,
  noPlayer,
  biddingClosed,
  alreadyLeading,
  squadFull,
  overBudget,
  bidMoved,
  hasBids,
  noBid,
  playerUnavailable,
  noPlayersLeft,
  noPreviousPlayer,
  needTeams,
  needPlayers,
  duplicatePlayer,
  invalidTeam,
  notAdmin,
  alreadyCompleted,
  incomplete,
  tooManyPlayers,
}

class AuctionActionException implements Exception {
  final AuctionError error;

  const AuctionActionException(this.error);

  @override
  String toString() => 'AuctionActionException(${error.name})';
}

class AuctionPlayer {
  final String id;
  final String name;

  /// Organizer's own player ID, e.g. "P001". Unique within the auction.
  final String? code;
  final int? number;
  final TournamentPlayerRole? role;
  final int basePrice;
  final AuctionPlayerStatus status;

  /// Buying or retaining team.
  final String? teamId;

  /// Sold price, or retained cost.
  final int? price;

  /// Queue position; the auction goes through players in this order.
  final int order;

  /// Bumped on every photo upload; 0 = no photo. The photo is the `photos`
  /// document with this player's [id].
  final int photoVersion;

  const AuctionPlayer({
    required this.id,
    required this.name,
    required this.basePrice,
    this.code,
    this.number,
    this.role,
    this.status = AuctionPlayerStatus.available,
    this.teamId,
    this.price,
    this.order = 0,
    this.photoVersion = 0,
  });

  bool get hasPhoto => photoVersion > 0;

  String get nameInitial => name.isEmpty ? '?' : name[0].toUpperCase();

  factory AuctionPlayer.fromJson(Map<String, dynamic> json) => AuctionPlayer(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        code: json['code'] as String?,
        number: (json['number'] as num?)?.toInt(),
        role: TournamentPlayerRole.values
            .where((r) => r.name == json['role'])
            .firstOrNull,
        basePrice: (json['base_price'] as num?)?.toInt() ?? 0,
        status: AuctionPlayerStatus.fromValue(json['status']),
        teamId: json['team_id'] as String?,
        price: (json['price'] as num?)?.toInt(),
        order: (json['order'] as num?)?.toInt() ?? 0,
        photoVersion: (json['photo_version'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'number': number,
        'role': role?.name,
        'base_price': basePrice,
        'status': status.value,
        'team_id': teamId,
        'price': price,
        'order': order,
        'photo_version': photoVersion,
      };

  AuctionPlayer copyWith({
    String? name,
    Object? code = _unset,
    Object? number = _unset,
    Object? role = _unset,
    int? basePrice,
    AuctionPlayerStatus? status,
    Object? teamId = _unset,
    Object? price = _unset,
    int? order,
    int? photoVersion,
  }) =>
      AuctionPlayer(
        id: id,
        name: name ?? this.name,
        code: code == _unset ? this.code : code as String?,
        number: number == _unset ? this.number : number as int?,
        role: role == _unset ? this.role : role as TournamentPlayerRole?,
        basePrice: basePrice ?? this.basePrice,
        status: status ?? this.status,
        teamId: teamId == _unset ? this.teamId : teamId as String?,
        price: price == _unset ? this.price : price as int?,
        order: order ?? this.order,
        photoVersion: photoVersion ?? this.photoVersion,
      );

  /// Back to the bidding pool, keeping the player's details.
  AuctionPlayer released() => copyWith(
        status: AuctionPlayerStatus.available,
        teamId: null,
        price: null,
      );
}

class AuctionTeam {
  final String id;
  final String name;
  final String? shortName;
  final int budget;

  /// Bumped on every logo upload; 0 = no logo. The logo is the `photos`
  /// document [Auction.teamLogoId].
  final int logoVersion;

  const AuctionTeam({
    required this.id,
    required this.name,
    required this.budget,
    this.shortName,
    this.logoVersion = 0,
  });

  bool get hasLogo => logoVersion > 0;

  String get initials {
    if (shortName?.trim().isNotEmpty ?? false) return shortName!.trim();
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length > 1) {
      return words.take(3).map((w) => w.isEmpty ? '' : w[0]).join();
    }
    return name.length <= 3 ? name : name.substring(0, 3);
  }

  factory AuctionTeam.fromJson(Map<String, dynamic> json) => AuctionTeam(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        shortName: json['short_name'] as String?,
        budget: (json['budget'] as num?)?.toInt() ?? 0,
        logoVersion: (json['logo_version'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'budget': budget,
        'logo_version': logoVersion,
      };

  AuctionTeam copyWith({
    String? name,
    Object? shortName = _unset,
    int? budget,
    int? logoVersion,
  }) =>
      AuctionTeam(
        id: id,
        name: name ?? this.name,
        shortName: shortName == _unset ? this.shortName : shortName as String?,
        budget: budget ?? this.budget,
        logoVersion: logoVersion ?? this.logoVersion,
      );
}

/// One bid on the player currently up, kept so a mistaken bid can be undone.
class AuctionBid {
  final String teamId;
  final int amount;

  const AuctionBid({required this.teamId, required this.amount});

  factory AuctionBid.fromJson(Map<String, dynamic> json) => AuctionBid(
        teamId: (json['team_id'] as String?) ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'team_id': teamId, 'amount': amount};
}

enum AuctionLogType {
  created,
  published,
  started,
  paused,
  resumed,
  shown,
  biddingStarted,
  bid,
  bidUndone,
  sold,
  unsold,
  reopened,
  retained,
  released,
  completed;

  static AuctionLogType fromName(Object? name) => AuctionLogType.values
      .firstWhere((t) => t.name == name, orElse: () => AuctionLogType.bid);
}

/// Append-only history entry in `auctions/{id}/log`.
class AuctionLogEntry {
  final String id;
  final AuctionLogType type;
  final String? playerId;
  final String? teamId;
  final int? amount;
  final String byUserId;
  final DateTime createdAt;

  const AuctionLogEntry({
    required this.id,
    required this.type,
    required this.byUserId,
    required this.createdAt,
    this.playerId,
    this.teamId,
    this.amount,
  });

  factory AuctionLogEntry.fromJson(Map<String, dynamic> json) =>
      AuctionLogEntry(
        id: (json['id'] as String?) ?? '',
        type: AuctionLogType.fromName(json['type']),
        playerId: json['player_id'] as String?,
        teamId: json['team_id'] as String?,
        amount: (json['amount'] as num?)?.toInt(),
        byUserId: (json['by'] as String?) ?? '',
        createdAt: parseFirestoreDate(json['created_at']) ?? DateTime(2000),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'player_id': playerId,
        'team_id': teamId,
        'amount': amount,
        'by': byUserId,
        'created_at': Timestamp.fromDate(createdAt),
      };
}

/// What still blocks completing the auction.
class AuctionCompletionCheck {
  final bool playerInAuction;
  final int availableLeft;
  final List<String> overBudgetTeamIds;
  final List<String> playersWithoutTeam;

  const AuctionCompletionCheck({
    this.playerInAuction = false,
    this.availableLeft = 0,
    this.overBudgetTeamIds = const [],
    this.playersWithoutTeam = const [],
  });

  /// Problems that marking the remaining players unsold can't fix.
  bool get hasBlockingIssues =>
      playerInAuction ||
      overBudgetTeamIds.isNotEmpty ||
      playersWithoutTeam.isNotEmpty;

  bool get isClear => !hasBlockingIssues && availableLeft == 0;
}

/// A player auction held before a tournament exists. Teams with budgets buy
/// players one at a time; on completion a tournament is generated with the
/// auction's teams and squads.
///
/// Stored as one `auctions` document so every action runs in a single
/// transaction; history lives in `auctions/{id}/log`, photos in `photos`.
class Auction {
  final String id;
  final String name;
  final String tournamentName;
  final String? description;
  final DateTime? auctionDate;

  /// Bumped on banner upload; the banner is the `photos` doc [bannerPhotoId].
  final int bannerVersion;
  final String createdBy;
  final List<String> adminIds;
  final DateTime createdAt;
  final AuctionStatus status;
  final int teamBudget;
  final int basePrice;
  final int bidIncrement;

  /// 0 = no minimum. Teams keep enough budget to reach it at base price.
  final int minSquad;

  /// 0 = no limit.
  final int maxSquad;

  /// Show team budgets on the public screen.
  final bool showBudgets;
  final List<AuctionTeam> teams;
  final List<AuctionPlayer> players;
  final String? currentPlayerId;
  final bool biddingOpen;
  final List<AuctionBid> bids;
  final String? tournamentId;
  final DateTime? completedAt;

  const Auction({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    String? tournamentName,
    this.description,
    this.auctionDate,
    this.bannerVersion = 0,
    List<String>? adminIds,
    this.status = AuctionStatus.draft,
    this.teamBudget = 1000,
    this.basePrice = 20,
    this.bidIncrement = 10,
    this.minSquad = 0,
    this.maxSquad = 0,
    this.showBudgets = true,
    this.teams = const [],
    this.players = const [],
    this.currentPlayerId,
    this.biddingOpen = false,
    this.bids = const [],
    this.tournamentId,
    this.completedAt,
  })  : tournamentName = tournamentName ?? name,
        adminIds = adminIds ?? const [];

  static const maxPlayers = 400;

  String get bannerPhotoId => 'banner_$id';

  /// `photos` doc holding [team]'s logo.
  String teamLogoId(AuctionTeam team) => 'team_${id}_${team.id}';

  bool get hasBanner => bannerVersion > 0;

  bool isAdmin(String? userId) =>
      userId != null && (userId == createdBy || adminIds.contains(userId));

  AuctionTeam? teamById(String? id) =>
      teams.where((t) => t.id == id).firstOrNull;

  AuctionPlayer? playerById(String? id) =>
      players.where((p) => p.id == id).firstOrNull;

  AuctionPlayer? get currentPlayer => playerById(currentPlayerId);

  AuctionBid? get leadingBid => bids.lastOrNull;

  int? get currentBid => leadingBid?.amount;

  String? get leadingTeamId => leadingBid?.teamId;

  AuctionTeam? get leadingTeam => teamById(leadingTeamId);

  List<AuctionPlayer> get orderedPlayers =>
      [...players]..sort((a, b) => a.order.compareTo(b.order));

  List<AuctionPlayer> playersWith(AuctionPlayerStatus status) =>
      orderedPlayers.where((p) => p.status == status).toList();

  /// Bought and retained players of the team.
  List<AuctionPlayer> squadOf(String teamId) => orderedPlayers
      .where((p) => p.teamId == teamId && p.status.isOnTeam)
      .toList();

  int spentBy(String teamId) =>
      squadOf(teamId).fold(0, (total, p) => total + (p.price ?? 0));

  int remainingFor(AuctionTeam team) => team.budget - spentBy(team.id);

  /// Players going through bidding (everyone except retained).
  int get auctionPoolCount =>
      players.where((p) => p.status != AuctionPlayerStatus.retained).length;

  int get processedCount => players
      .where((p) =>
          p.status == AuctionPlayerStatus.sold ||
          p.status == AuctionPlayerStatus.unsold,)
      .length;

  int get nextOrder =>
      players.isEmpty ? 1 : players.map((p) => p.order).reduce(max) + 1;

  int? get nextBidAmount {
    final player = currentPlayer;
    if (player == null) return null;
    return currentBid == null ? player.basePrice : currentBid! + bidIncrement;
  }

  /// Highest bid the team can make while still affording base price for
  /// the players it needs to reach [minSquad].
  int maxBidFor(AuctionTeam team) {
    final stillNeeded = max(0, minSquad - squadOf(team.id).length - 1);
    return remainingFor(team) - stillNeeded * basePrice;
  }

  bool squadFull(String teamId) =>
      maxSquad > 0 && squadOf(teamId).length >= maxSquad;

  AuctionError? bidBlock(String teamId) {
    if (status == AuctionStatus.paused) return AuctionError.paused;
    if (status != AuctionStatus.live) return AuctionError.notLive;
    final amount = nextBidAmount;
    if (amount == null) return AuctionError.noPlayer;
    if (!biddingOpen) return AuctionError.biddingClosed;
    final team = teamById(teamId);
    if (team == null) return AuctionError.invalidTeam;
    if (leadingTeamId == teamId) return AuctionError.alreadyLeading;
    if (squadFull(teamId)) return AuctionError.squadFull;
    if (amount > maxBidFor(team)) return AuctionError.overBudget;
    return null;
  }

  // ── Setup ────────────────────────────────────────────────────────────────

  void _requireSetup() {
    if (!status.isSetup) throw const AuctionActionException(AuctionError.notEditable);
  }

  void _requireNotCompleted() {
    if (status == AuctionStatus.completed) {
      throw const AuctionActionException(AuctionError.alreadyCompleted);
    }
  }

  /// The existing player that [candidate] would duplicate: same player ID,
  /// or same name and number.
  AuctionPlayer? duplicateOf(AuctionPlayer candidate) {
    final code = candidate.code?.trim().toLowerCase();
    final name = candidate.name.caseAndSpaceInsensitive;
    return players.where((p) {
      if (p.id == candidate.id) return false;
      if (code != null && code.isNotEmpty && p.code?.trim().toLowerCase() == code) {
        return true;
      }
      return p.name.caseAndSpaceInsensitive == name &&
          p.number == candidate.number;
    }).firstOrNull;
  }

  /// Adds new players (skipping duplicates) or updates existing ones by id.
  /// Returns the auction and how many were skipped as duplicates.
  (Auction, int) upsertPlayers(List<AuctionPlayer> incoming) {
    _requireNotCompleted();
    var auction = this;
    var skipped = 0;
    for (final player in incoming) {
      final existing = auction.playerById(player.id);
      if (auction.duplicateOf(player) != null) {
        if (existing != null) {
          throw const AuctionActionException(AuctionError.duplicatePlayer);
        }
        skipped++;
        continue;
      }
      if (existing == null) {
        if (auction.players.length >= maxPlayers) {
          throw const AuctionActionException(AuctionError.tooManyPlayers);
        }
        auction = auction._copy(players: [
          ...auction.players,
          player.copyWith(
            order: auction.nextOrder,
            status: AuctionPlayerStatus.available,
            teamId: null,
            price: null,
          ),
        ],);
      } else {
        // Status, team and price only change through auction actions.
        auction = auction._copy(
          players: auction._replacePlayer(player.copyWith(
            status: existing.status,
            teamId: existing.teamId,
            price: existing.price,
            order: existing.order,
            photoVersion: max(existing.photoVersion, player.photoVersion),
          ),),
        );
      }
    }
    return (auction, skipped);
  }

  Auction removePlayer(String playerId) {
    _requireSetup();
    final player = playerById(playerId);
    if (player == null) return this;
    if (player.status != AuctionPlayerStatus.available) {
      throw const AuctionActionException(AuctionError.playerUnavailable);
    }
    return _copy(players: players.where((p) => p.id != playerId).toList());
  }

  Auction setPhotoVersion(String playerId, int version) {
    final player = playerById(playerId);
    if (player == null) return this;
    return _copy(players: _replacePlayer(player.copyWith(photoVersion: version)));
  }

  Auction setTeams(List<AuctionTeam> teams) {
    _requireSetup();
    final ids = teams.map((t) => t.id).toSet();
    final orphaned = players.any((p) => p.teamId != null && !ids.contains(p.teamId));
    if (orphaned) throw const AuctionActionException(AuctionError.invalidTeam);
    return _copy(teams: teams);
  }

  Auction retain(String playerId, String teamId, int price) {
    _requireSetup();
    final player = playerById(playerId);
    final team = teamById(teamId);
    if (team == null) throw const AuctionActionException(AuctionError.invalidTeam);
    if (player == null || player.status != AuctionPlayerStatus.available) {
      throw const AuctionActionException(AuctionError.playerUnavailable);
    }
    if (squadFull(teamId)) throw const AuctionActionException(AuctionError.squadFull);
    if (price < 0 || price > remainingFor(team)) {
      throw const AuctionActionException(AuctionError.overBudget);
    }
    return _copy(
      players: _replacePlayer(player.copyWith(
        status: AuctionPlayerStatus.retained,
        teamId: teamId,
        price: price,
      ),),
    );
  }

  Auction release(String playerId) {
    _requireSetup();
    final player = playerById(playerId);
    if (player == null || player.status != AuctionPlayerStatus.retained) {
      throw const AuctionActionException(AuctionError.playerUnavailable);
    }
    return _copy(players: _replacePlayer(player.released()));
  }

  void _requireReady() {
    if (teams.length < 2) throw const AuctionActionException(AuctionError.needTeams);
    if (playersWith(AuctionPlayerStatus.available).isEmpty) {
      throw const AuctionActionException(AuctionError.needPlayers);
    }
  }

  Auction publish() {
    if (status != AuctionStatus.draft) {
      throw const AuctionActionException(AuctionError.notEditable);
    }
    _requireReady();
    return _copy(status: AuctionStatus.upcoming);
  }

  Auction unpublish() {
    if (status != AuctionStatus.upcoming) {
      throw const AuctionActionException(AuctionError.notEditable);
    }
    return _copy(status: AuctionStatus.draft);
  }

  // ── Running ──────────────────────────────────────────────────────────────

  Auction start() {
    _requireSetup();
    _requireReady();
    return _copy(status: AuctionStatus.live)._showNext();
  }

  Auction pause() {
    if (status != AuctionStatus.live) {
      throw const AuctionActionException(AuctionError.notLive);
    }
    return _copy(status: AuctionStatus.paused);
  }

  Auction resume() {
    if (status != AuctionStatus.paused) {
      throw const AuctionActionException(AuctionError.notLive);
    }
    return _copy(status: AuctionStatus.live);
  }

  void _requireLive() {
    if (status == AuctionStatus.paused) {
      throw const AuctionActionException(AuctionError.paused);
    }
    if (status != AuctionStatus.live) {
      throw const AuctionActionException(AuctionError.notLive);
    }
  }

  /// Puts [playerId] up for bidding. The current player, if any, goes back
  /// to the pool — only allowed before anyone has bid on them.
  Auction showPlayer(String playerId) {
    _requireLive();
    if (bids.isNotEmpty) throw const AuctionActionException(AuctionError.hasBids);
    final target = playerById(playerId);
    if (target == null ||
        !(target.status == AuctionPlayerStatus.available ||
            target.status == AuctionPlayerStatus.unsold)) {
      throw const AuctionActionException(AuctionError.playerUnavailable);
    }
    return _withCurrentReturned()._putUp(target);
  }

  /// Next available player after the current one, in queue order.
  Auction nextPlayer() {
    _requireLive();
    if (bids.isNotEmpty) throw const AuctionActionException(AuctionError.hasBids);
    final afterOrder = currentPlayer?.order ?? 0;
    final pool = _withCurrentReturned()
        .playersWith(AuctionPlayerStatus.available)
        .where((p) => p.id != currentPlayerId)
        .toList();
    if (pool.isEmpty) {
      throw const AuctionActionException(AuctionError.noPlayersLeft);
    }
    final next = pool.where((p) => p.order > afterOrder).firstOrNull ?? pool.first;
    return showPlayer(next.id);
  }

  /// The closest earlier player that hasn't been sold, so it is safe to
  /// bring back. Only before any bid on the current player.
  Auction previousPlayer() {
    _requireLive();
    if (bids.isNotEmpty) throw const AuctionActionException(AuctionError.hasBids);
    final beforeOrder = currentPlayer?.order ?? nextOrder;
    final candidates = orderedPlayers
        .where((p) =>
            p.order < beforeOrder &&
            (p.status == AuctionPlayerStatus.available ||
                p.status == AuctionPlayerStatus.unsold),)
        .toList();
    if (candidates.isEmpty) {
      throw const AuctionActionException(AuctionError.noPreviousPlayer);
    }
    return showPlayer(candidates.last.id);
  }

  Auction startBidding() {
    _requireLive();
    if (currentPlayer == null) {
      throw const AuctionActionException(AuctionError.noPlayer);
    }
    return _copy(biddingOpen: true);
  }

  /// Records a bid for [teamId]. [expectedAmount] guards against two admins
  /// bidding on a stale screen.
  Auction placeBid(String teamId, int expectedAmount) {
    final block = bidBlock(teamId);
    if (block != null) throw AuctionActionException(block);
    if (nextBidAmount != expectedAmount) {
      throw const AuctionActionException(AuctionError.bidMoved);
    }
    return _copy(bids: [...bids, AuctionBid(teamId: teamId, amount: expectedAmount)]);
  }

  Auction undoBid() {
    _requireLive();
    if (bids.isEmpty) throw const AuctionActionException(AuctionError.noBid);
    return _copy(bids: bids.sublist(0, bids.length - 1));
  }

  /// Sells the current player to the leading team, then shows the next one.
  Auction sell() {
    _requireLive();
    final player = currentPlayer;
    final team = leadingTeam;
    final amount = currentBid;
    if (player == null) throw const AuctionActionException(AuctionError.noPlayer);
    if (team == null || amount == null) {
      throw const AuctionActionException(AuctionError.noBid);
    }
    if (amount > remainingFor(team)) {
      throw const AuctionActionException(AuctionError.overBudget);
    }
    return _copy(
      players: _replacePlayer(player.copyWith(
        status: AuctionPlayerStatus.sold,
        teamId: team.id,
        price: amount,
      ),),
    )._clearCurrent()._showNext(afterOrder: player.order);
  }

  Auction markUnsold() {
    _requireLive();
    final player = currentPlayer;
    if (player == null) throw const AuctionActionException(AuctionError.noPlayer);
    if (bids.isNotEmpty) throw const AuctionActionException(AuctionError.hasBids);
    return _copy(
      players: _replacePlayer(player.copyWith(status: AuctionPlayerStatus.unsold)),
    )._clearCurrent()._showNext(afterOrder: player.order);
  }

  /// Puts every unsold player back in the pool for another round.
  Auction reopenUnsold() {
    _requireLive();
    final reopened = _copy(players: [
      for (final p in players)
        p.status == AuctionPlayerStatus.unsold
            ? p.copyWith(status: AuctionPlayerStatus.available)
            : p,
    ],);
    return reopened.currentPlayerId == null ? reopened._showNext() : reopened;
  }

  // ── Completion ───────────────────────────────────────────────────────────

  AuctionCompletionCheck get completionCheck => AuctionCompletionCheck(
        playerInAuction: currentPlayerId != null && bids.isNotEmpty,
        availableLeft: players
            .where((p) =>
                p.status == AuctionPlayerStatus.available ||
                p.status == AuctionPlayerStatus.inAuction,)
            .length,
        overBudgetTeamIds:
            teams.where((t) => remainingFor(t) < 0).map((t) => t.id).toList(),
        playersWithoutTeam: players
            .where((p) => p.status.isOnTeam && teamById(p.teamId) == null)
            .map((p) => p.id)
            .toList(),
      );

  /// Validated final state: optionally marks players never auctioned as
  /// unsold. Throws if anything else is inconsistent.
  Auction complete({required DateTime now, bool markRemainingUnsold = false}) {
    _requireNotCompleted();
    if (status.isSetup) throw const AuctionActionException(AuctionError.notLive);
    final check = completionCheck;
    if (check.hasBlockingIssues ||
        (check.availableLeft > 0 && !markRemainingUnsold)) {
      throw const AuctionActionException(AuctionError.incomplete);
    }
    return _copy(
      status: AuctionStatus.completed,
      players: [
        for (final p in players)
          p.status == AuctionPlayerStatus.available ||
                  p.status == AuctionPlayerStatus.inAuction
              ? p.copyWith(status: AuctionPlayerStatus.unsold)
              : p,
      ],
      completedAt: now,
    )._clearCurrent();
  }

  Auction withTournament(String tournamentId) =>
      _copy(tournamentId: tournamentId);

  // ── Helpers ──────────────────────────────────────────────────────────────

  Auction _putUp(AuctionPlayer player) => _copy(
        players: _replacePlayer(player.copyWith(status: AuctionPlayerStatus.inAuction)),
        currentPlayerId: player.id,
        biddingOpen: false,
        bids: const [],
      );

  Auction _withCurrentReturned() {
    final player = currentPlayer;
    if (player == null) return this;
    return _copy(
      players: _replacePlayer(player.copyWith(status: AuctionPlayerStatus.available)),
    )._clearCurrent();
  }

  Auction _clearCurrent() => _copy(
        currentPlayerId: null,
        biddingOpen: false,
        bids: const [],
      );

  /// Shows the next available player after [afterOrder], wrapping around.
  Auction _showNext({int afterOrder = 0}) {
    final pool = playersWith(AuctionPlayerStatus.available);
    if (pool.isEmpty) return this;
    return _putUp(pool.where((p) => p.order > afterOrder).firstOrNull ?? pool.first);
  }

  List<AuctionPlayer> _replacePlayer(AuctionPlayer player) =>
      [for (final p in players) p.id == player.id ? player : p];

  factory Auction.fromJson(Map<String, dynamic> json) => Auction(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        tournamentName: json['tournament_name'] as String?,
        description: json['description'] as String?,
        auctionDate: parseFirestoreDate(json['auction_date']),
        bannerVersion: (json['banner_version'] as num?)?.toInt() ?? 0,
        createdBy: (json['created_by'] as String?) ?? '',
        adminIds: ((json['admin_ids'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
        createdAt: parseFirestoreDate(json['created_at']) ?? DateTime(2000),
        status: AuctionStatus.fromValue(json['status']),
        teamBudget: (json['team_budget'] as num?)?.toInt() ?? 1000,
        basePrice: (json['base_price'] as num?)?.toInt() ?? 20,
        bidIncrement: (json['bid_increment'] as num?)?.toInt() ?? 10,
        minSquad: (json['min_squad'] as num?)?.toInt() ?? 0,
        maxSquad: (json['max_squad'] as num?)?.toInt() ?? 0,
        showBudgets: (json['show_budgets'] as bool?) ?? true,
        teams: ((json['teams'] as List?) ?? const [])
            .whereType<Map>()
            .map((t) => AuctionTeam.fromJson(Map<String, dynamic>.from(t)))
            .toList(),
        players: ((json['players'] as List?) ?? const [])
            .whereType<Map>()
            .map((p) => AuctionPlayer.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
        currentPlayerId: json['current_player_id'] as String?,
        biddingOpen: (json['bidding_open'] as bool?) ?? false,
        bids: ((json['bids'] as List?) ?? const [])
            .whereType<Map>()
            .map((b) => AuctionBid.fromJson(Map<String, dynamic>.from(b)))
            .toList(),
        tournamentId: json['tournament_id'] as String?,
        completedAt: parseFirestoreDate(json['completed_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tournament_name': tournamentName,
        'description': description,
        'auction_date':
            auctionDate == null ? null : Timestamp.fromDate(auctionDate!),
        'banner_version': bannerVersion,
        'created_by': createdBy,
        'admin_ids': {createdBy, ...adminIds}.toList(),
        'created_at': Timestamp.fromDate(createdAt),
        'status': status.value,
        'team_budget': teamBudget,
        'base_price': basePrice,
        'bid_increment': bidIncrement,
        'min_squad': minSquad,
        'max_squad': maxSquad,
        'show_budgets': showBudgets,
        'teams': teams.map((t) => t.toJson()).toList(),
        'players': players.map((p) => p.toJson()).toList(),
        'current_player_id': currentPlayerId,
        'bidding_open': biddingOpen,
        'bids': bids.map((b) => b.toJson()).toList(),
        'tournament_id': tournamentId,
        'completed_at':
            completedAt == null ? null : Timestamp.fromDate(completedAt!),
      };

  /// Details editable from the create / edit form.
  Auction copyWith({
    String? name,
    String? tournamentName,
    Object? description = _unset,
    Object? auctionDate = _unset,
    int? bannerVersion,
    List<String>? adminIds,
    int? teamBudget,
    int? basePrice,
    int? bidIncrement,
    int? minSquad,
    int? maxSquad,
    bool? showBudgets,
  }) =>
      _copy(
        name: name,
        tournamentName: tournamentName,
        description: description,
        auctionDate: auctionDate,
        bannerVersion: bannerVersion,
        adminIds: adminIds,
        teamBudget: teamBudget,
        basePrice: basePrice,
        bidIncrement: bidIncrement,
        minSquad: minSquad,
        maxSquad: maxSquad,
        showBudgets: showBudgets,
      );

  Auction _copy({
    String? name,
    String? tournamentName,
    Object? description = _unset,
    Object? auctionDate = _unset,
    int? bannerVersion,
    List<String>? adminIds,
    AuctionStatus? status,
    int? teamBudget,
    int? basePrice,
    int? bidIncrement,
    int? minSquad,
    int? maxSquad,
    bool? showBudgets,
    List<AuctionTeam>? teams,
    List<AuctionPlayer>? players,
    Object? currentPlayerId = _unset,
    bool? biddingOpen,
    List<AuctionBid>? bids,
    Object? tournamentId = _unset,
    Object? completedAt = _unset,
  }) =>
      Auction(
        id: id,
        name: name ?? this.name,
        tournamentName: tournamentName ?? this.tournamentName,
        description:
            description == _unset ? this.description : description as String?,
        auctionDate:
            auctionDate == _unset ? this.auctionDate : auctionDate as DateTime?,
        bannerVersion: bannerVersion ?? this.bannerVersion,
        createdBy: createdBy,
        adminIds: adminIds ?? this.adminIds,
        createdAt: createdAt,
        status: status ?? this.status,
        teamBudget: teamBudget ?? this.teamBudget,
        basePrice: basePrice ?? this.basePrice,
        bidIncrement: bidIncrement ?? this.bidIncrement,
        minSquad: minSquad ?? this.minSquad,
        maxSquad: maxSquad ?? this.maxSquad,
        showBudgets: showBudgets ?? this.showBudgets,
        teams: teams ?? this.teams,
        players: players ?? this.players,
        currentPlayerId: currentPlayerId == _unset
            ? this.currentPlayerId
            : currentPlayerId as String?,
        biddingOpen: biddingOpen ?? this.biddingOpen,
        bids: bids ?? this.bids,
        tournamentId: tournamentId == _unset
            ? this.tournamentId
            : tournamentId as String?,
        completedAt:
            completedAt == _unset ? this.completedAt : completedAt as DateTime?,
      );
}

const _unset = Object();
