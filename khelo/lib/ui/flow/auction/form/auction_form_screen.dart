import 'package:data/api/auction/auction_models.dart';
import 'package:data/api/user/user_models.dart';
import 'package:data/service/auction/auction_service.dart';
import 'package:data/service/user/user_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:data/extensions/string_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart';

import '../../play/select_opponent_sheet.dart';
import '../components/auction_image_picker.dart';
import '../components/auction_widgets.dart';

/// Creates an auction (as a draft) or edits its details, teams and admins.
class AuctionFormScreen extends ConsumerStatefulWidget {
  final Auction? auction;

  const AuctionFormScreen({super.key, this.auction});

  @override
  ConsumerState<AuctionFormScreen> createState() => _AuctionFormScreenState();
}

class _TeamRow {
  final String id;
  final TextEditingController name;
  final TextEditingController short;

  _TeamRow(this.id, {String? name, String? short})
      : name = TextEditingController(text: name),
        short = TextEditingController(text: short);

  void dispose() {
    name.dispose();
    short.dispose();
  }
}

class _AuctionFormScreenState extends ConsumerState<AuctionFormScreen> {
  Auction? get _initial => widget.auction;

  late final _name = TextEditingController(text: _initial?.name);
  late final _tournament =
      TextEditingController(text: _initial?.tournamentName);
  late final _description =
      TextEditingController(text: _initial?.description);
  late final _budget = _number(_initial?.teamBudget ?? 1000);
  late final _base = _number(_initial?.basePrice ?? 20);
  late final _increment = _number(_initial?.bidIncrement ?? 10);
  late final _minSquad = _number(_initial?.minSquad ?? 0);
  late final _maxSquad = _number(_initial?.maxSquad ?? 0);
  late DateTime? _date = _initial?.auctionDate;
  late bool _showBudgets = _initial?.showBudgets ?? true;
  late final List<_TeamRow> _teams = _initial == null
      ? [for (var i = 0; i < 4; i++) _TeamRow(_service.newId())]
      : [
          for (final t in _initial!.teams)
            _TeamRow(t.id, name: t.name, short: t.shortName),
        ];
  late List<String> _adminIds = [...?_initial?.adminIds];
  Map<String, String> _adminNames = {};
  Uint8List? _banner;
  bool _saving = false;

  AuctionService get _service => ref.read(auctionServiceProvider);

  bool get _teamsEditable => _initial?.status.isSetup ?? true;

  static TextEditingController _number(int value) =>
      TextEditingController(text: '$value');

  int _value(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadAdminNames();
  }

  Future<void> _loadAdminNames() async {
    if (_adminIds.isEmpty) return;
    final users =
        await ref.read(userServiceProvider).getUsersByIds(_adminIds);
    if (mounted) {
      setState(() => _adminNames = {for (final u in users) u.id: u.name ?? ''});
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _tournament,
      _description,
      _budget,
      _base,
      _increment,
      _minSquad,
      _maxSquad,
    ]) {
      c.dispose();
    }
    for (final t in _teams) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserPod)?.id;
    final isCreator = _initial == null || _initial!.createdBy == userId;
    return AppPage(
      title: _initial == null
          ? context.l10n.auction_create_title
          : context.l10n.auction_edit_title,
      body: ListView(
        padding: context.mediaQueryPadding +
            const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _bannerPicker(context),
          const SizedBox(height: 16),
          _field(_name, context.l10n.auction_name_label,
              hint: context.l10n.auction_name_hint,),
          const SizedBox(height: 12),
          _field(_tournament, context.l10n.auction_tournament_name_label,
              hint: context.l10n.auction_tournament_name_hint,),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              context.l10n.auction_tournament_name_help,
              style: AppTextStyle.caption
                  .copyWith(color: context.colorScheme.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          _field(_description, context.l10n.auction_description_label,
              hint: context.l10n.auction_description_hint, lines: 3,),
          const SizedBox(height: 12),
          _datePicker(context),
          AuctionSectionTitle(context.l10n.auction_rules_title),
          _rules(context),
          AuctionSectionTitle(
            '${context.l10n.auction_teams_title} (${_teams.length})',
            actions: [
              if (_teamsEditable)
                TextButton.icon(
                  onPressed: () => setState(
                    () => _teams.add(_TeamRow(_service.newId())),
                  ),
                  icon: const Icon(CupertinoIcons.add, size: 16),
                  label: Text(context.l10n.auction_add_team),
                ),
            ],
          ),
          if (!_teamsEditable)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                context.l10n.auction_teams_locked,
                style: AppTextStyle.caption
                    .copyWith(color: context.colorScheme.textSecondary),
              ),
            ),
          for (var i = 0; i < _teams.length; i++) _teamRow(context, i),
          if (isCreator) ..._admins(context, userId),
          const SizedBox(height: 24),
          PrimaryButton(
            _initial == null
                ? context.l10n.auction_create_title
                : context.l10n.auction_save,
            progress: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int lines = 1,
    bool number = false,
  }) =>
      AppTextField(
        controller: controller,
        label: label,
        hintText: hint,
        minLines: lines,
        maxLines: lines,
        keyboardType: number ? TextInputType.number : null,
        inputFormatters:
            number ? [FilteringTextInputFormatter.digitsOnly] : null,
        textCapitalization:
            number ? TextCapitalization.none : TextCapitalization.sentences,
        borderType: AppTextFieldBorderType.outline,
      );

  Widget _bannerPicker(BuildContext context) {
    final cs = context.colorScheme;
    final hasExisting = _initial?.hasBanner ?? false;
    return GestureDetector(
      onTap: () async {
        final bytes = await pickAuctionPhoto(banner: true);
        if (bytes != null) setState(() => _banner = bytes);
      },
      child: Container(
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: cs.cardDecoration(radius: 18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_banner != null)
              Image.memory(_banner!, fit: BoxFit.cover)
            else if (hasExisting)
              LayoutBuilder(
                builder: (context, c) => AuctionPhoto(
                  photoId: _initial!.bannerPhotoId,
                  hasPhoto: true,
                  fallback: '',
                  size: c.maxWidth,
                  height: c.maxHeight,
                  radius: 0,
                ),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.photo, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      _banner != null || hasExisting
                          ? context.l10n.auction_banner_change
                          : context.l10n.auction_banner_add,
                      style: AppTextStyle.caption.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker(BuildContext context) {
    final cs = context.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _date ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 3),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.calendar, size: 18, color: cs.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _date == null
                    ? context.l10n.auction_date_pick
                    : '${context.l10n.auction_date_label}: ${DateFormat.yMMMEd().format(_date!)}',
                style: AppTextStyle.body2.copyWith(
                  color: _date == null ? cs.textSecondary : cs.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rules(BuildContext context) {
    Widget pair(Widget a, Widget b) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ],),
        );
    return Column(
      children: [
        pair(
          _field(_budget, context.l10n.auction_team_budget, number: true),
          _field(_base, context.l10n.auction_base_price, number: true),
        ),
        pair(
          _field(_increment, context.l10n.auction_bid_increment, number: true),
          const SizedBox(),
        ),
        pair(
          _field(_minSquad, context.l10n.auction_min_squad, number: true),
          _field(_maxSquad, context.l10n.auction_max_squad, number: true),
        ),
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          value: _showBudgets,
          onChanged: (v) => setState(() => _showBudgets = v),
          title: Text(
            context.l10n.auction_show_budgets,
            style: AppTextStyle.body2
                .copyWith(color: context.colorScheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _teamRow(BuildContext context, int index) {
    final team = _teams[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: AppTextField(
              controller: team.name,
              enabled: _teamsEditable,
              label: context.l10n.auction_team_name(index + 1),
              textCapitalization: TextCapitalization.words,
              borderType: AppTextFieldBorderType.outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppTextField(
              controller: team.short,
              enabled: _teamsEditable,
              label: context.l10n.auction_team_short,
              textCapitalization: TextCapitalization.characters,
              borderType: AppTextFieldBorderType.outline,
            ),
          ),
          if (_teamsEditable)
            IconButton(
              icon: Icon(CupertinoIcons.minus_circle,
                  color: context.colorScheme.alert, size: 20,),
              onPressed: () => setState(() => _teams.removeAt(index).dispose()),
            ),
        ],
      ),
    );
  }

  List<Widget> _admins(BuildContext context, String? userId) {
    final cs = context.colorScheme;
    final others = _adminIds.where((id) => id != (_initial?.createdBy ?? userId));
    return [
      AuctionSectionTitle(
        context.l10n.auction_admins_title,
        actions: [
          TextButton.icon(
            onPressed: _addAdmin,
            icon: const Icon(CupertinoIcons.person_add, size: 16),
            label: Text(context.l10n.auction_add_admin),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          context.l10n.auction_admins_help,
          style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
        ),
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(CupertinoIcons.person_crop_circle_fill, color: cs.primary),
        title: Text(
          ref.watch(currentUserPod)?.name ?? '',
          style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
        ),
        subtitle: Text(
          context.l10n.auction_creator,
          style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
        ),
      ),
      for (final id in others)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(CupertinoIcons.person_crop_circle, color: cs.primary),
          title: Text(
            _adminNames[id] ?? '…',
            style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
          ),
          trailing: IconButton(
            icon: Icon(CupertinoIcons.minus_circle, color: cs.alert, size: 20),
            onPressed: () => setState(
              () => _adminIds = _adminIds.where((a) => a != id).toList(),
            ),
          ),
        ),
    ];
  }

  Future<void> _addAdmin() async {
    final UserModel? user = await showSelectOpponentSheet(
      context,
      title: context.l10n.auction_select_admin,
    );
    if (user == null || _adminIds.contains(user.id)) return;
    setState(() {
      _adminIds = [..._adminIds, user.id];
      _adminNames = {..._adminNames, user.id: user.name ?? ''};
    });
  }

  String? _validate() {
    if (_name.text.trim().isEmpty || _tournament.text.trim().isEmpty) {
      return context.l10n.auction_validation_name;
    }
    final min = _value(_minSquad);
    final max = _value(_maxSquad);
    if ([_budget, _base, _increment].map(_value).any((n) => n <= 0) ||
        (max > 0 && min > max)) {
      return context.l10n.auction_validation_rules;
    }
    final names = _teams
        .map((t) => t.name.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.length < 2 || names.length != _teams.length) {
      return context.l10n.auction_validation_teams;
    }
    if (names.map((n) => n.caseAndSpaceInsensitive).toSet().length !=
        names.length) {
      return context.l10n.auction_validation_team_names;
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      showSnackBar(context, error);
      return;
    }
    final userId = ref.read(currentUserPod)?.id;
    if (userId == null) return;
    final budget = _value(_budget);
    final description = _description.text.trim();
    final details = Auction(
      id: _initial?.id ?? _service.newId(),
      name: _name.text.trim(),
      tournamentName: _tournament.text.trim(),
      description: description.isEmpty ? null : description,
      auctionDate: _date,
      createdBy: _initial?.createdBy ?? userId,
      adminIds: {_initial?.createdBy ?? userId, ..._adminIds}.toList(),
      createdAt: _initial?.createdAt ?? DateTime.now(),
      teamBudget: budget,
      basePrice: _value(_base),
      bidIncrement: _value(_increment),
      minSquad: _value(_minSquad),
      maxSquad: _value(_maxSquad),
      showBudgets: _showBudgets,
      teams: [
        for (final t in _teams)
          AuctionTeam(
            id: t.id,
            name: t.name.text.trim(),
            shortName: t.short.text.trim().isEmpty ? null : t.short.text.trim(),
            budget: budget,
            logoVersion: _initial?.teamById(t.id)?.logoVersion ?? 0,
          ),
      ],
    );
    setState(() => _saving = true);
    try {
      if (_initial == null) {
        await _service.createAuction(details);
      } else {
        await _service.saveDetails(details.id, userId, details);
      }
      if (_banner != null) {
        await _service.uploadBanner(details.id, userId, _banner!);
      }
      if (!mounted) return;
      if (_initial == null) {
        AppRoute.auctionRoom(details.id).pushReplacement(context);
      } else {
        Navigator.of(context).pop();
      }
    } on AuctionActionException catch (e) {
      if (mounted) showSnackBar(context, e.error.label(context));
    } catch (e) {
      if (mounted) showErrorSnackBar(context: context, error: e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
