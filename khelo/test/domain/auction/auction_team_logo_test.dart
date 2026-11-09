import 'package:data/api/auction/auction_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('team logo version survives a save and load', () {
    const team = AuctionTeam(
        id: 't1', name: 'Range Kings', budget: 5000, logoVersion: 1);
    final loaded = AuctionTeam.fromJson(team.toJson());
    expect(loaded.hasLogo, isTrue);
    expect(loaded.copyWith(name: 'RK').logoVersion, 1);
  });

  test('teams saved before logos existed have none', () {
    final team =
        AuctionTeam.fromJson({'id': 't1', 'name': 'Range Kings', 'budget': 1});
    expect(team.hasLogo, isFalse);
  });

  test('logo photo id is unique per auction and team', () {
    final auction = Auction(
      id: 'a1',
      name: 'Auction',
      createdBy: 'u1',
      createdAt: DateTime(2026),
      teams: const [AuctionTeam(id: 't1', name: 'Range Kings', budget: 1)],
    );
    expect(auction.teamLogoId(auction.teams.first), 'team_a1_t1');
  });
}
