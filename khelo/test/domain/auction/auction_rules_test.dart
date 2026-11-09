import 'package:data/api/auction/auction_models.dart';
import 'package:flutter_test/flutter_test.dart';

Auction _auction({int budget = 100, int minSquad = 0, int maxSquad = 0}) =>
    Auction(
      id: 'a1',
      name: 'GCPL Auction',
      tournamentName: 'GCPL',
      createdBy: 'admin',
      createdAt: DateTime(2026, 11, 6),
      teamBudget: budget,
      basePrice: 20,
      bidIncrement: 10,
      minSquad: minSquad,
      maxSquad: maxSquad,
      teams: [
        AuctionTeam(id: 'A', name: 'Team A', budget: budget),
        AuctionTeam(id: 'B', name: 'Team B', budget: budget),
      ],
    ).upsertPlayers([
      for (var i = 1; i <= 4; i++)
        AuctionPlayer(id: 'p$i', name: 'Player $i', basePrice: 20, number: i),
    ]).$1;

Matcher _fails(AuctionError error) => throwsA(
      isA<AuctionActionException>().having((e) => e.error, 'error', error),
    );

void main() {
  group('setup', () {
    test('players get queue order and duplicates are skipped', () {
      final auction = _auction();
      expect(auction.orderedPlayers.map((p) => p.order), [1, 2, 3, 4]);
      final (updated, skipped) = auction.upsertPlayers([
        const AuctionPlayer(id: 'x', name: 'player 1', basePrice: 20, number: 1),
        const AuctionPlayer(id: 'y', name: 'Player 1', basePrice: 20, number: 9),
      ]);
      expect(skipped, 1);
      expect(updated.players.length, 5);
    });

    test('same player ID is a duplicate', () {
      final auction = _auction().upsertPlayers([
        const AuctionPlayer(id: 'c1', name: 'Arun', basePrice: 20, code: 'P01'),
      ]).$1;
      final (_, skipped) = auction.upsertPlayers([
        const AuctionPlayer(id: 'c2', name: 'Bala', basePrice: 20, code: 'p01'),
      ]);
      expect(skipped, 1);
    });

    test('retaining deducts from budget and leaves the bidding queue', () {
      final auction = _auction().retain('p1', 'A', 30);
      final teamA = auction.teamById('A')!;
      expect(auction.remainingFor(teamA), 70);
      expect(auction.squadOf('A').single.status, AuctionPlayerStatus.retained);
      expect(auction.auctionPoolCount, 3);
      final live = auction.start();
      expect(live.currentPlayerId, 'p2');
    });

    test('retained price above budget is rejected', () {
      expect(() => _auction().retain('p1', 'A', 150), _fails(AuctionError.overBudget));
    });

    test('release returns a retained player to the pool', () {
      final auction = _auction().retain('p1', 'A', 30).release('p1');
      expect(auction.playerById('p1')!.status, AuctionPlayerStatus.available);
      expect(auction.spentBy('A'), 0);
    });

    test('publish needs two teams and players', () {
      final empty = Auction(
        id: 'e',
        name: 'Empty',
        createdBy: 'admin',
        createdAt: DateTime(2026),
      );
      expect(() => empty.publish(), _fails(AuctionError.needTeams));
      expect(_auction().publish().status, AuctionStatus.upcoming);
    });

    test('players can only be removed before the auction starts', () {
      expect(_auction().removePlayer('p4').players.length, 3);
      expect(() => _auction().start().removePlayer('p4'),
          _fails(AuctionError.notEditable),);
    });
  });

  group('live bidding', () {
    test('start shows the first player; bidding must be started', () {
      final live = _auction().start();
      expect(live.status, AuctionStatus.live);
      expect(live.currentPlayer!.status, AuctionPlayerStatus.inAuction);
      expect(() => live.placeBid('A', 20), _fails(AuctionError.biddingClosed));
    });

    test('bids go base price then increments; stale bids fail', () {
      var live = _auction().start().startBidding();
      live = live.placeBid('A', 20);
      expect(live.nextBidAmount, 30);
      expect(() => live.placeBid('B', 20), _fails(AuctionError.bidMoved));
      expect(() => live.placeBid('A', 30), _fails(AuctionError.alreadyLeading));
      live = live.placeBid('B', 30);
      expect(live.leadingTeamId, 'B');
      expect(live.undoBid().leadingTeamId, 'A');
    });

    test('sell records team and price, then shows the next player', () {
      final live = _auction().start().startBidding().placeBid('A', 20).placeBid('B', 30);
      final sold = live.sell();
      final p1 = sold.playerById('p1')!;
      expect(p1.status, AuctionPlayerStatus.sold);
      expect(p1.teamId, 'B');
      expect(p1.price, 30);
      expect(sold.remainingFor(sold.teamById('B')!), 70);
      expect(sold.currentPlayerId, 'p2');
      expect(sold.biddingOpen, isFalse);
      expect(sold.bids, isEmpty);
    });

    test('cannot exceed budget', () {
      var live = _auction(budget: 35).start().startBidding();
      live = live.placeBid('A', 20).placeBid('B', 30);
      expect(live.bidBlock('A'), AuctionError.overBudget);
    });

    test('min squad reserve keeps money for remaining players', () {
      final live = _auction(minSquad: 3).start().startBidding();
      // 100 - (3 - 0 - 1) * 20 = 60
      expect(live.maxBidFor(live.teamById('A')!), 60);
    });

    test('squad full blocks bids', () {
      var live = _auction(maxSquad: 1).retain('p1', 'A', 20).start().startBidding();
      expect(live.bidBlock('A'), AuctionError.squadFull);
      live = live.placeBid('B', 20);
      expect(live.leadingTeamId, 'B');
    });

    test('unsold only without bids; reopen brings them back', () {
      final live = _auction().start();
      final afterUnsold = live.markUnsold();
      expect(afterUnsold.playerById('p1')!.status, AuctionPlayerStatus.unsold);
      expect(afterUnsold.currentPlayerId, 'p2');
      expect(() => live.startBidding().placeBid('A', 20).markUnsold(),
          _fails(AuctionError.hasBids),);
      final reopened = afterUnsold.reopenUnsold();
      expect(reopened.playerById('p1')!.status, AuctionPlayerStatus.available);
    });

    test('next and previous skip sold players and need no bids', () {
      var live = _auction().start(); // p1
      live = live.nextPlayer(); // p2
      expect(live.currentPlayerId, 'p2');
      expect(live.playerById('p1')!.status, AuctionPlayerStatus.available);
      live = live.startBidding().placeBid('A', 20);
      expect(() => live.previousPlayer(), _fails(AuctionError.hasBids));
      live = live.sell(); // p2 sold, p3 up
      live = live.previousPlayer();
      expect(live.currentPlayerId, 'p1');
    });

    test('pause blocks actions until resumed', () {
      final paused = _auction().start().startBidding().pause();
      expect(paused.bidBlock('A'), AuctionError.paused);
      expect(() => paused.sell(), _fails(AuctionError.paused));
      expect(paused.resume().bidBlock('A'), isNull);
    });
  });

  group('completion', () {
    test('a player with bids blocks completion', () {
      final live = _auction().start().startBidding().placeBid('A', 20);
      expect(live.completionCheck.playerInAuction, isTrue);
      expect(() => live.complete(now: DateTime(2026), markRemainingUnsold: true),
          _fails(AuctionError.incomplete),);
    });

    test('remaining players must be marked unsold explicitly', () {
      final live = _auction().start().startBidding().placeBid('A', 20).sell();
      expect(live.completionCheck.availableLeft, 3);
      expect(() => live.complete(now: DateTime(2026)), _fails(AuctionError.incomplete));
      final done = live.complete(now: DateTime(2026), markRemainingUnsold: true);
      expect(done.status, AuctionStatus.completed);
      expect(done.currentPlayerId, isNull);
      expect(done.playersWith(AuctionPlayerStatus.unsold).length, 3);
      expect(done.squadOf('A').single.id, 'p1');
    });

    test('cannot complete twice', () {
      final done = _auction()
          .start()
          .complete(now: DateTime(2026), markRemainingUnsold: true);
      expect(() => done.complete(now: DateTime(2026)),
          _fails(AuctionError.alreadyCompleted),);
    });
  });

  test('json round trip keeps details, retained, bids and photos', () {
    final auction = _auction()
        .copyWith(description: 'Season 3', auctionDate: DateTime(2026, 12, 1))
        .retain('p1', 'A', 30)
        .setPhotoVersion('p2', 5)
        .start()
        .startBidding()
        .placeBid('B', 20);
    final copy = Auction.fromJson(auction.toJson());
    expect(copy.description, 'Season 3');
    expect(copy.auctionDate, DateTime(2026, 12, 1));
    expect(copy.tournamentName, 'GCPL');
    expect(copy.playerById('p1')!.status, AuctionPlayerStatus.retained);
    expect(copy.playerById('p2')!.hasPhoto, isTrue);
    expect(copy.leadingTeamId, 'B');
    expect(copy.biddingOpen, isTrue);
    expect(copy.isAdmin('admin'), isTrue);
    expect(copy.isAdmin('someone'), isFalse);
  });
}
