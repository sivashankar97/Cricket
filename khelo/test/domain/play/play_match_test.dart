import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/api/play/play_match.dart';
import 'package:flutter_test/flutter_test.dart';

PlayMatch _match({
  PlayMatchStatus status = PlayMatchStatus.live,
  String? battingFirstId = 'h',
  int currentInnings = 1,
  DateTime? createdAt,
}) =>
    PlayMatch(
      id: 'm1',
      seed: 42,
      overs: 2,
      wickets: 3,
      host: const PlayMatchPlayer(id: 'h', name: 'Host'),
      guest: const PlayMatchPlayer(id: 'g', name: 'Guest Player', image: 'x'),
      status: status,
      battingFirstId: battingFirstId,
      currentInnings: currentInnings,
      innings1: const [PlayBall('six', 12), PlayBall('dot')],
      lastSeen: {'h': DateTime(2026, 11, 9, 10)},
      createdAt: createdAt ?? DateTime(2026, 11, 9, 10),
    );

void main() {
  test('round-trips through Firestore JSON', () {
    final json = _match().toJson();
    expect(json['participant_ids'], ['h', 'g']);
    expect(json['innings_1'], [
      {'r': 'six', 'o': 12},
      {'r': 'dot', 'o': null},
    ]);
    expect(json['last_seen']['h'], isA<Timestamp>());

    final back = PlayMatch.fromJson(json);
    expect(back.guest.image, 'x');
    expect(back.innings1, const [PlayBall('six', 12), PlayBall('dot')]);
    expect(back.lastSeen['h'], DateTime(2026, 11, 9, 10));
    expect(back.status, PlayMatchStatus.live);
  });

  test('knows who bats in each innings', () {
    expect(_match().currentBatterId, 'h');
    expect(_match().battingSecondId, 'g');
    expect(_match(currentInnings: 2).currentBatterId, 'g');
    expect(_match(battingFirstId: null).currentBatterId, isNull);
  });

  test('a request expires after ten minutes', () {
    final sent = DateTime(2026, 11, 9, 10);
    final match = _match(status: PlayMatchStatus.requested, createdAt: sent);
    expect(match.isExpired(sent.add(const Duration(minutes: 9))), isFalse);
    expect(match.isExpired(sent.add(const Duration(minutes: 11))), isTrue);
    expect(
        _match(createdAt: sent).isExpired(sent.add(const Duration(hours: 1))),
        isFalse);
  });

  test('unknown status reads as cancelled; open statuses', () {
    expect(PlayMatchStatus.fromValue('weird'), PlayMatchStatus.cancelled);
    expect(PlayMatchStatus.values.where((s) => s.isOpen), [
      PlayMatchStatus.requested,
      PlayMatchStatus.toss,
      PlayMatchStatus.live
    ]);
  });

  test('presence is online for two minutes', () {
    final seen = DateTime(2026, 11, 9, 10);
    final presence = PlayPresence(userId: 'u', name: 'U', lastSeen: seen);
    expect(presence.isOnline(seen.add(const Duration(seconds: 119))), isTrue);
    expect(presence.isOnline(seen.add(const Duration(minutes: 3))), isFalse);
  });
}
