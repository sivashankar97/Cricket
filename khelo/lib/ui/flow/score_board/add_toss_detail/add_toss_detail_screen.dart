import 'package:data/api/match/match_model.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:khelo/domain/permissions/match_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:khelo/domain/extensions/widget_extension.dart';
import 'package:khelo/gen/assets.gen.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/score_board/add_toss_detail/add_toss_detail_view_model.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/button/bottom_sticky_overlay.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_style.dart';

class AddTossDetailScreen extends ConsumerStatefulWidget {
  final String matchId;

  const AddTossDetailScreen({super.key, required this.matchId});

  @override
  ConsumerState createState() => _AddTossDetailScreenState();
}

class _AddTossDetailScreenState extends ConsumerState<AddTossDetailScreen> {
  late AddTossDetailViewNotifier notifier;

  @override
  void initState() {
    super.initState();
    notifier = ref.read(addTossDetailStateProvider.notifier);
    runPostFrame(() => notifier.setData(widget.matchId));
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(matchPermissionsProvider(widget.matchId));
    final state = ref.watch(addTossDetailStateProvider);
    final currentUserId = ref.watch(currentUserPod)?.id;

    final hasScoringAccess = access.valueOrNull?.score == true ||
        (state.match != null && state.match!.canScore(currentUserId));

    if (access.isLoading && state.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Toss')),
        body: const Center(child: AppProgressIndicator()),
      );
    }

    if (!hasScoringAccess && !access.isLoading && !state.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Toss')),
        body: const Center(child: Text('You do not have scoring access.')),
      );
    }

    _observeActionError(context, ref);
    _observePushScoreBoard();
    return AppPage(
      title: context.l10n.add_toss_detail_screen_title,
      body: Builder(builder: (context) {
        return _body(context, state);
      }),
    );
  }

  Widget _body(BuildContext context, AddTossDetailState state) {
    if (state.loading) {
      return const Center(child: AppProgressIndicator());
    }
    if (state.error != null) {
      return ErrorScreen(
        error: state.error,
        onRetryTap: notifier.getMatchById,
      );
    }

    return Stack(
      children: [
        ListView(
          padding: context.mediaQueryPadding +
              const EdgeInsets.only(left: 16) +
              BottomStickyOverlay.padding,
          children: [
            _whoWonTossView(
              context,
              state.match?.teams,
              state.tossWinnerTeamId,
            ),
            _electedToView(context, state.tossWinnerDecision),
          ],
        ),
        _stickyButton(context, state)
      ],
    );
  }

  Widget _whoWonTossView(
    BuildContext context,
    List<MatchTeamModel>? teams,
    String? tossWinnerTeamId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, context.l10n.add_toss_detail_who_won_toss_text),
        IntrinsicHeight(
          child: Row(
              children: teams
                      ?.map(
                        (team) {
                          final teamId = team.team_id.isNotEmpty
                              ? team.team_id
                              : team.team.id;
                          final teamName = team.team.name.isNotEmpty
                              ? team.team.name
                              : (team.team_id.isNotEmpty ? 'Team' : 'Unknown');
                          final teamInitial = (team.team.name_initial != null &&
                                  team.team.name_initial!.isNotEmpty)
                              ? team.team.name_initial
                              : teamName.initials(limit: 1);
                          return _tossCellView(
                            context: context,
                            imageUrl: team.team.profile_img_url,
                            initial: teamInitial,
                            title: teamName,
                            isSelected: tossWinnerTeamId != null &&
                                tossWinnerTeamId.isNotEmpty &&
                                tossWinnerTeamId == teamId,
                            onTap: () {
                              if (teamId.isNotEmpty) {
                                notifier.onTossWinnerSelect(teamId);
                              }
                            },
                          );
                        },
                      )
                      .toList() ??
                  []),
        )
      ],
    );
  }

  Widget _electedToView(
    BuildContext context,
    TossDecision? tossWinnerDecision,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
            context, context.l10n.add_toss_detail_winner_elected_to_text),
        IntrinsicHeight(
          child: Row(
            children: (TossDecision.values)
                .map((decision) => _tossCellView(
                      context: context,
                      image: getTossDecisionImage(decision),
                      title: decision.getString(context),
                      isSelected: tossWinnerDecision == decision,
                      onTap: () => notifier.onOptionSelect(decision),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: AppTextStyle.subtitle1
              .copyWith(color: context.colorScheme.textPrimary),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _tossCellView({
    required BuildContext context,
    String? image,
    String? imageUrl,
    String? initial,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = context.colorScheme;
    return Expanded(
      child: OnTapScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 164),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? cs.primary : Colors.transparent,
              width: 2,
            ),
            color: isSelected
                ? cs.primary.withValues(alpha: 0.08)
                : cs.containerLow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _cellImageView(image, imageUrl, initial),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyle.subtitle1.copyWith(
                  color: isSelected ? cs.primary : cs.textPrimary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _cellImageView(String? image, String? imageUrl, String? initial) {
    if (image != null) {
      return SvgPicture.asset(
        image,
        fit: BoxFit.fitHeight,
        colorFilter:
            ColorFilter.mode(context.colorScheme.textPrimary, BlendMode.srcIn),
      );
    } else if (initial != null) {
      return ImageAvatar(
        initial: initial,
        imageUrl: imageUrl,
        size: 80,
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _stickyButton(
    BuildContext context,
    AddTossDetailState state,
  ) {
    return BottomStickyOverlay(
      child: PrimaryButton(
        context.l10n.common_next_title,
        enabled: state.isButtonEnable,
        progress: state.isTossDetailUpdateInProgress,
        onPressed: notifier.onNextButtonTap,
      ),
    );
  }

  String getTossDecisionImage(TossDecision decision) {
    switch (decision) {
      case TossDecision.bat:
        return Assets.images.batsman;
      case TossDecision.bowl:
        return Assets.images.bowler;
    }
  }

  void _observeActionError(BuildContext context, WidgetRef ref) {
    ref.listen(addTossDetailStateProvider.select((value) => value.actionError),
        (previous, next) {
      if (next != null) {
        showErrorSnackBar(context: context, error: next);
      }
    });
  }

  void _observePushScoreBoard() {
    ref.listen(
        addTossDetailStateProvider.select((value) => value.pushScoreBoard),
        (previous, next) {
      if (next != null && next) {
        AppRoute.scoreBoard(matchId: notifier.matchId!)
            .pushReplacement(context);
      }
    });
  }
}
