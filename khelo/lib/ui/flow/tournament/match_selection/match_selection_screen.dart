import 'package:data/api/match/match_model.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/action_bottom_sheet.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/empty_screen.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:khelo/domain/extensions/widget_extension.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/tournament/match_selection/match_selection_view_model.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/button/action_button.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/pickers/date_and_time_picker.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/text/search_text_field.dart';
import 'package:style/widgets/adaptive_outlined_tile.dart';

import '../../../../domain/formatter/date_formatter.dart';
import '../../../../gen/assets.gen.dart';

class MatchSelectionScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const MatchSelectionScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState createState() => _MatchSelectionScreenState();
}

class _MatchSelectionScreenState extends ConsumerState<MatchSelectionScreen> {
  late MatchSelectionViewNotifier notifier;

  @override
  void initState() {
    super.initState();
    notifier = ref.read(matchSelectionStateProvider.notifier);
    runPostFrame(() => notifier.setData(widget.tournamentId));
  }

  int _getUnscheduledCount(GroupedMatchMap matches) {
    int count = 0;
    for (final group in matches.values) {
      for (final round in group.values) {
        for (final m in round) {
          if (m.id.isEmpty && m.teams.length >= 2) {
            count++;
          }
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchSelectionStateProvider);
    final unscheduledCount = _getUnscheduledCount(state.matches);

    return AppPage(
      title: context.l10n.match_selection_screen_title,
      actions: [
        if (unscheduledCount > 0)
          actionButton(
            context,
            onPressed: () =>
                _openScheduleAllSheet(context, state, unscheduledCount),
            icon: Icon(
              CupertinoIcons.calendar_badge_plus,
              color: context.colorScheme.primary,
              size: 22,
            ),
          ),
        _addButton(
          context,
          onPressed: () {
            final option = notifier.getMatchGroupOption();
            showActionBottomSheet(
                context: context,
                items: option
                    .map((group) => BottomSheetAction(
                        title: group.getString(context),
                        onTap: () {
                          context.pop();
                          notifier.addGroup(group);
                        }))
                    .toList());
          },
        ),
      ],
      body: Builder(
        builder: (context) => Padding(
          padding: context.mediaQueryPadding,
          child: _body(context, state, unscheduledCount),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MatchSelectionState state,
    int unscheduledCount,
  ) {
    if (state.loading) {
      return const SkeletonCards();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: _searchTextField(context, notifier, state),
        ),
        if (unscheduledCount > 0 && state.searchController.text.isEmpty)
          _scheduleAllBanner(context, state, unscheduledCount),
        _buildListView(context, state),
      ],
    );
  }

  Widget _scheduleAllBanner(
    BuildContext context,
    MatchSelectionState state,
    int unscheduledCount,
  ) {
    final cs = context.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CupertinoIcons.calendar_badge_plus,
              color: cs.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.tournament_schedule_whole_title,
                  style: AppTextStyle.subtitle2.copyWith(
                    color: cs.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$unscheduledCount pending fixtures ready to schedule',
                  style: AppTextStyle.caption.copyWith(
                    color: cs.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PrimaryButton(
            context.l10n.tournament_schedule_all_matches_btn,
            expanded: false,
            edgeInsets: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onPressed: () =>
                _openScheduleAllSheet(context, state, unscheduledCount),
          ),
        ],
      ),
    );
  }

  void _openScheduleAllSheet(
    BuildContext context,
    MatchSelectionState state,
    int unscheduledCount,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScheduleWholeTournamentSheet(
        unscheduledCount: unscheduledCount,
        tournament: state.tournament,
        onSchedule: notifier.scheduleAllMatches,
      ),
    );
  }

  Widget _buildListView(BuildContext context, MatchSelectionState state) {
    final matches = state.searchController.text.isNotEmpty
        ? state.searchResults
        : state.matches;

    if (matches.isEmpty) {
      return Expanded(
        child: EmptyScreen(
          title: state.searchController.text.isEmpty
              ? context.l10n.match_selection_no_matches_title
              : context.l10n
                  .match_selection_not_found_title(state.searchController.text),
          description: state.searchController.text.isEmpty
              ? context.l10n.match_selection_no_matches_description
              : context.l10n.match_selection_not_found_description(
                  state.searchController.text),
          isShowButton: false,
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final entry = matches.entries.elementAt(index);
          return _buildMatchGroupList(
              state.tournament?.id, entry.key, entry.value);
        },
      ),
    );
  }

  Widget _buildMatchGroupList(
    String? tournamentId,
    MatchGroup group,
    Map<int, List<MatchModel>> roundsMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: roundsMap.entries
          .map((roundEntry) => _buildRoundList(
              tournamentId, group, roundEntry.key, roundEntry.value))
          .toList(),
    );
  }

  Widget _buildRoundList(String? tournamentId, MatchGroup group, int number,
      List<MatchModel> matches) {
    final roundDisplay = group == MatchGroup.round
        ? "${group.getString(context)} $number"
        : group.getString(context);
    final showAddButton =
        (group == MatchGroup.quarterfinal && matches.length < 4) ||
            (group == MatchGroup.semifinal && matches.length < 2) ||
            (group == MatchGroup.finals && matches.isEmpty) ||
            group == MatchGroup.round;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: context.colorScheme.containerLow,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  roundDisplay,
                  style: AppTextStyle.header3.copyWith(
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),
              if (showAddButton)
                _addButton(context, onPressed: () {
                  AppRoute.addMatch(
                    tournamentId: tournamentId,
                    group: group,
                    groupNumber: number,
                  ).push(context);
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...matches.map((match) => _matchCell(context, tournamentId, match)),
      ],
    );
  }

  Widget _addButton(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    return actionButton(
      context,
      onPressed: onPressed,
      icon: Icon(
        CupertinoIcons.add,
        color: context.colorScheme.textPrimary,
        size: 24,
      ),
    );
  }

  Widget _searchTextField(
    BuildContext context,
    MatchSelectionViewNotifier notifier,
    MatchSelectionState state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SearchTextField(
        controller: state.searchController,
        onChange: notifier.onSearchChanged,
        hintText: context.l10n.search_team_search_placeholder_title,
        suffixIcon: state.searchInProgress
            ? const UnconstrainedBox(child: AppProgressIndicator(radius: 8))
            : const SizedBox(),
      ),
    );
  }

  Widget _matchCell(
    BuildContext context,
    String? tournamentId,
    MatchModel match,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
          color: context.colorScheme.containerLowOnSurface,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _matchTimeAndGroundView(context, match),
          Divider(color: context.colorScheme.outline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                _overlapProfileView(context, match),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                        text: match.teams.first.team.name_initial ??
                            match.teams.first.team.name,
                        children: [
                          TextSpan(
                              text:
                                  " ${context.l10n.common_versus_short_title} ",
                              style: AppTextStyle.body1.copyWith(
                                  color: context.colorScheme.textPrimary)),
                          TextSpan(
                              text: match.teams.last.team.name_initial ??
                                  match.teams.last.team.name),
                        ]),
                    style: AppTextStyle.subtitle1
                        .copyWith(color: context.colorScheme.textPrimary),
                  ),
                ),
                _secondaryAddEditButton(context, tournamentId, match),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlapProfileView(BuildContext context, MatchModel match) {
    return SizedBox(
      width: 70,
      child: Stack(
        children: [
          ImageAvatar(
              initial: match.teams.first.team.name_initial ??
                  match.teams.first.team.name.initials(limit: 1),
              imageUrl: match.teams.first.team.profile_img_url,
              size: 40),
          Positioned(
            left: 30,
            child: ImageAvatar(
                initial: match.teams.last.team.name_initial ??
                    match.teams.last.team.name.initials(limit: 1),
                imageUrl: match.teams.last.team.profile_img_url,
                size: 40),
          ),
        ],
      ),
    );
  }

  Widget _secondaryAddEditButton(
      BuildContext context, String? tournamentId, MatchModel match) {
    return OnTapScale(
      onTap: () => match.id.isNotEmpty
          ? AppRoute.addMatch(matchId: match.id).push(context)
          : AppRoute.addMatch(
                  tournamentId: tournamentId,
                  groupNumber: match.match_group_number,
                  group: match.match_group,
                  defaultOpponent: match.teams.last.team,
                  defaultTeam: match.teams.first.team)
              .push(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: context.colorScheme.containerNormal,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          match.id.isEmpty
              ? context.l10n.common_add_title
              : context.l10n.common_edit_title,
          style:
              AppTextStyle.button.copyWith(color: context.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _matchTimeAndGroundView(
    BuildContext context,
    MatchModel match,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
          flex: 2,
          child: Text(
              (match.start_at ?? match.start_time ?? DateTime.now())
                  .format(context, DateFormatType.dateAndTime),
              style: AppTextStyle.caption
                  .copyWith(color: context.colorScheme.textDisabled)),
        ),
        if (match.ground.isNotEmpty)
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SvgPicture.asset(
                  Assets.images.icLocation,
                  height: 20,
                  width: 20,
                  colorFilter: ColorFilter.mode(
                    context.colorScheme.textDisabled,
                    BlendMode.srcATop,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    match.ground,
                    style: AppTextStyle.caption
                        .copyWith(color: context.colorScheme.textDisabled),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ]),
    );
  }
}

class _ScheduleWholeTournamentSheet extends StatefulWidget {
  final int unscheduledCount;
  final TournamentModel? tournament;
  final Future<int> Function({
    required DateTime startDate,
    required int numberOfOvers,
    required int overPerBowler,
    required String city,
    required String ground,
    required BallType ballType,
    required PitchType pitchType,
    bool staggerTimes,
  }) onSchedule;

  const _ScheduleWholeTournamentSheet({
    required this.unscheduledCount,
    required this.tournament,
    required this.onSchedule,
  });

  @override
  State<_ScheduleWholeTournamentSheet> createState() =>
      _ScheduleWholeTournamentSheetState();
}

class _ScheduleWholeTournamentSheetState
    extends State<_ScheduleWholeTournamentSheet> {
  late DateTime _startDate;
  int _overs = 10;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _groundController = TextEditingController();
  BallType _ballType = BallType.leather;
  PitchType _pitchType = PitchType.rough;
  bool _stagger = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final tournamentStart = widget.tournament?.start_date;
    if (tournamentStart != null && tournamentStart.isAfter(DateTime.now())) {
      _startDate = tournamentStart;
    } else {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _startDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _groundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tournament_schedule_whole_title,
                        style: AppTextStyle.header3
                            .copyWith(color: cs.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scheduling all ${widget.unscheduledCount} pending matches at once',
                        style: AppTextStyle.caption
                            .copyWith(color: cs.textSecondary),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: cs.containerLow,
                    child: Icon(Icons.close, size: 16, color: cs.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Start Date & Time
            Text(
              context.l10n.tournament_schedule_start_date,
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AdaptiveOutlinedTile(
                    title: _startDate.format(context, DateFormatType.date),
                    headerImage: Assets.images.icCalendar,
                    headerText: context.l10n.add_match_date_title,
                    placeholder: context.l10n.add_match_date_title,
                    onTap: () {
                      selectDate(
                        context,
                        initialDate: _startDate,
                        onDateSelected: (selectedDate) {
                          setState(() {
                            _startDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              _startDate.hour,
                              _startDate.minute,
                            );
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdaptiveOutlinedTile(
                    title: _startDate.format(context, DateFormatType.time),
                    headerImage: Assets.images.icTime,
                    headerText: context.l10n.add_match_time_title,
                    placeholder: context.l10n.add_match_time_title,
                    onTap: () {
                      selectTime(
                        context,
                        initialTime: _startDate,
                        onTimeSelected: (selectedTime) {
                          setState(() {
                            _startDate = DateTime(
                              _startDate.year,
                              _startDate.month,
                              _startDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Overs
            Text(
              context.l10n.tournament_schedule_overs,
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [5, 10, 15, 20].map((overs) {
                final isSelected = _overs == overs;
                return ChoiceChip(
                  label: Text('$overs T$overs'),
                  selected: isSelected,
                  selectedColor: cs.primary,
                  backgroundColor: cs.containerLow,
                  labelStyle: AppTextStyle.caption.copyWith(
                    color: isSelected ? Colors.white : cs.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _overs = overs);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Venue / Ground
            Text(
              context.l10n.tournament_schedule_venue,
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _groundController,
              hintText: 'Enter stadium or ground name',
              prefixIcon: const Icon(CupertinoIcons.location, size: 18),
            ),
            const SizedBox(height: 16),

            // City
            Text(
              context.l10n.tournament_schedule_city,
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _cityController,
              hintText: 'Enter city name',
              prefixIcon: const Icon(CupertinoIcons.building_2_fill, size: 18),
            ),
            const SizedBox(height: 16),

            // Ball Type
            Text(
              'Ball Type',
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  [BallType.leather, BallType.tennis, BallType.other].map((b) {
                final isSelected = _ballType == b;
                return ChoiceChip(
                  label: Text(b.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: cs.primary,
                  backgroundColor: cs.containerLow,
                  labelStyle: AppTextStyle.caption.copyWith(
                    color: isSelected ? Colors.white : cs.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _ballType = b);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Pitch Type
            Text(
              'Pitch Type',
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  [PitchType.rough, PitchType.turf, PitchType.cement].map((p) {
                final isSelected = _pitchType == p;
                return ChoiceChip(
                  label: Text(p.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: cs.primary,
                  backgroundColor: cs.containerLow,
                  labelStyle: AppTextStyle.caption.copyWith(
                    color: isSelected ? Colors.white : cs.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _pitchType = p);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Stagger switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.containerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.tournament_schedule_spacing,
                          style: AppTextStyle.subtitle2
                              .copyWith(color: cs.textPrimary),
                        ),
                        Text(
                          context.l10n.tournament_schedule_spacing_same_day,
                          style: AppTextStyle.caption
                              .copyWith(color: cs.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: _stagger,
                    activeTrackColor: cs.primary,
                    onChanged: (val) => setState(() => _stagger = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            PrimaryButton(
              'Schedule ${widget.unscheduledCount} Matches',
              progress: _isSubmitting,
              onPressed: () async {
                setState(() => _isSubmitting = true);
                try {
                  final overPerBowler = (_overs ~/ 5).clamp(1, 4);
                  final count = await widget.onSchedule(
                    startDate: _startDate,
                    numberOfOvers: _overs,
                    overPerBowler: overPerBowler,
                    city: _cityController.text.trim(),
                    ground: _groundController.text.trim(),
                    ballType: _ballType,
                    pitchType: _pitchType,
                    staggerTimes: _stagger,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    showSnackBar(
                        context, 'Successfully scheduled $count matches!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    setState(() => _isSubmitting = false);
                    showErrorSnackBar(context: context, error: e);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
