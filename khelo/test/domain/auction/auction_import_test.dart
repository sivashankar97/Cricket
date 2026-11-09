import 'package:data/api/auction/auction_models.dart';
import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/domain/auction/auction_import.dart';

void main() {
  test('parses name, ID, number, role and price; skips blank lines', () {
    var id = 0;
    final players = parsePlayerLines(
      'Arun Kumar, P001, 7, bat, 50\n\nBala\nKarthik,,12,wk\nDev\tP004\t\tall rounder',
      defaultBasePrice: 20,
      newId: () => 'id${id++}',
    );
    expect(players.map((p) => p.name), ['Arun Kumar', 'Bala', 'Karthik', 'Dev']);
    expect(players[0].code, 'P001');
    expect(players[0].number, 7);
    expect(players[0].role, TournamentPlayerRole.batsman);
    expect(players[0].basePrice, 50);
    expect(players[1].basePrice, 20);
    expect(players[2].code, isNull);
    expect(players[2].role, TournamentPlayerRole.wicketKeeper);
    expect(players[3].code, 'P004');
    expect(players[3].role, TournamentPlayerRole.allRounder);
  });

  group('photo matching', () {
    const players = [
      AuctionPlayer(id: 'a', name: 'Arun Kumar', basePrice: 20, code: 'P001', number: 7),
      AuctionPlayer(id: 'b', name: 'Bala', basePrice: 20, code: 'P002', number: 12),
      AuctionPlayer(id: 'c', name: 'Bala', basePrice: 20, number: 30),
    ];

    test('by player ID, number and name', () {
      expect(matchPhotoToPlayer('p001.jpg', players)?.id, 'a');
      expect(matchPhotoToPlayer('12.png', players)?.id, 'b');
      expect(matchPhotoToPlayer('arun_kumar.JPG', players)?.id, 'a');
      expect(matchPhotoToPlayer('Arun Kumar.jpeg', players)?.id, 'a');
    });

    test('combined names match on any part', () {
      expect(matchPhotoToPlayer('P002 - Bala.jpg', players)?.id, 'b');
      expect(matchPhotoToPlayer('30_Bala.jpg', players)?.id, 'c');
    });

    test('ambiguous or unknown names do not match', () {
      expect(matchPhotoToPlayer('Bala.jpg', players), isNull);
      expect(matchPhotoToPlayer('Someone.jpg', players), isNull);
    });
  });
}
