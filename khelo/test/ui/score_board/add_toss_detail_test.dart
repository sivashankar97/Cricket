import 'package:data/api/match/match_model.dart';
import 'package:data/api/team/team_model.dart';
import 'package:data/service/match/match_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/ui/flow/score_board/add_toss_detail/add_toss_detail_view_model.dart';

class _Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _MockMatchService extends _Fake implements MatchService {
  final MatchModel match;
  String? updatedTossWinnerId;
  TossDecision? updatedTossDecision;
  String? updatedCurrentPlayingTeamId;

  _MockMatchService(this.match);

  @override
  Future<MatchModel> getMatchById(String matchId) async => match;

  @override
  Future<void> updateTossDetails(
    String matchId,
    String tossWinnerId,
    TossDecision tossDecision,
    String currentPlayingTeam,
  ) async {
    updatedTossWinnerId = tossWinnerId;
    updatedTossDecision = tossDecision;
    updatedCurrentPlayingTeamId = currentPlayingTeam;
  }
}

void main() {
  group('AddTossDetailViewNotifier', () {
    late MatchModel testMatch;

    setUp(() {
      testMatch = MatchModel(
        id: 'test_match_123',
        match_type: MatchType.limitedOvers,
        number_of_over: 10,
        over_per_bowler: 2,
        city: 'Jaffna',
        ground: 'Stadium',
        start_time: DateTime.now(),
        start_at: DateTime.now(),
        ball_type: BallType.leather,
        pitch_type: PitchType.turf,
        created_by: 'creator_1',
        match_status: MatchStatus.yetToStart,
        teams: [
          MatchTeamModel(
            team_id: 'team_alpha_id',
            team: TeamModel(
              id: 'team_alpha_id',
              name: 'Alpha Titans',
              name_lowercase: 'alpha titans',
              created_at: DateTime.now(),
            ),
          ),
          MatchTeamModel(
            team_id: 'team_beta_id',
            team: TeamModel(
              id: 'team_beta_id',
              name: 'Beta Kings',
              name_lowercase: 'beta kings',
              created_at: DateTime.now(),
            ),
          ),
        ],
        updated_at: DateTime.now(),
      );
    });

    test('selecting toss winner and bat sets current playing team to winner',
        () async {
      final mock = _MockMatchService(testMatch);
      final notifier = AddTossDetailViewNotifier(mock);

      notifier.setData('test_match_123');
      await Future.delayed(Duration.zero);

      expect(notifier.state.match, isNotNull);
      expect(notifier.state.isButtonEnable, isFalse);

      // Select Team Alpha as winner
      notifier.onTossWinnerSelect('team_alpha_id');
      expect(notifier.state.tossWinnerTeamId, 'team_alpha_id');
      expect(notifier.state.isButtonEnable, isFalse);

      // Select Bat
      notifier.onOptionSelect(TossDecision.bat);
      expect(notifier.state.tossWinnerDecision, TossDecision.bat);
      expect(notifier.state.isButtonEnable, isTrue);

      // Next
      await notifier.onNextButtonTap();

      expect(mock.updatedTossWinnerId, 'team_alpha_id');
      expect(mock.updatedTossDecision, TossDecision.bat);
      expect(mock.updatedCurrentPlayingTeamId, 'team_alpha_id');
      expect(notifier.state.pushScoreBoard, isTrue);
    });

    test('selecting toss winner and bowl sets current playing team to opponent',
        () async {
      final mock = _MockMatchService(testMatch);
      final notifier = AddTossDetailViewNotifier(mock);

      notifier.setData('test_match_123');
      await Future.delayed(Duration.zero);

      // Select Team Alpha as winner
      notifier.onTossWinnerSelect('team_alpha_id');

      // Select Bowl (opponent team Beta will bat)
      notifier.onOptionSelect(TossDecision.bowl);
      expect(notifier.state.isButtonEnable, isTrue);

      // Next
      await notifier.onNextButtonTap();

      expect(mock.updatedTossWinnerId, 'team_alpha_id');
      expect(mock.updatedTossDecision, TossDecision.bowl);
      expect(mock.updatedCurrentPlayingTeamId, 'team_beta_id');
      expect(notifier.state.pushScoreBoard, isTrue);
    });
  });
}
