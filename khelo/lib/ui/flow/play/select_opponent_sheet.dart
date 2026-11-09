import 'dart:async';

import 'package:data/api/user/user_models.dart';
import 'package:data/service/user/user_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_style.dart';

Future<UserModel?> showSelectOpponentSheet(
  BuildContext context, {
  String? title,
  bool includeMe = false,
}) =>
    showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SelectOpponentSheet(title: title, includeMe: includeMe),
    );

class _SelectOpponentSheet extends ConsumerStatefulWidget {
  final String? title;
  final bool includeMe;

  const _SelectOpponentSheet({this.title, this.includeMe = false});

  @override
  ConsumerState<_SelectOpponentSheet> createState() =>
      _SelectOpponentSheetState();
}

class _SelectOpponentSheetState extends ConsumerState<_SelectOpponentSheet> {
  Timer? _debounce;
  bool _loading = false;
  List<UserModel> _users = [];
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    setState(() {
      _query = query;
      _loading = query.isNotEmpty;
      if (query.isEmpty) _users = [];
    });
    if (query.isEmpty) return;
    try {
      final me = ref.read(currentUserPod)?.id;
      final users = await ref.read(userServiceProvider).searchUser(query);
      if (!mounted || query != _query) return;
      setState(() {
        // Only real accounts can sign in and act on the result.
        _users = users
            .where((user) =>
                (widget.includeMe || user.id != me) &&
                (user.email != null || user.phone != null))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: cs.containerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                widget.title ?? context.l10n.play_select_opponent_title,
                style: AppTextStyle.header4.copyWith(
                  color: cs.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSearchTextField(
                autofocus: true,
                placeholder: context.l10n.play_select_opponent_hint,
                style: AppTextStyle.body1.copyWith(color: cs.textPrimary),
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _results(context)),
          ],
        ),
      ),
    );
  }

  Widget _results(BuildContext context) {
    final cs = context.colorScheme;
    if (_loading) return const Center(child: AppProgressIndicator());
    if (_query.isNotEmpty && _users.isEmpty) {
      return Center(
        child: Text(
          context.l10n.play_select_opponent_empty,
          style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
        ),
      );
    }
    return ListView.builder(
      itemCount: _users.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final user = _users[index];
        return ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: ImageAvatar(
            initial: user.nameInitial,
            imageUrl: user.profile_img_url,
            size: 40,
          ),
          title: Text(
            user.name ?? '',
            style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
          ),
          subtitle: user.location == null
              ? null
              : Text(
                  user.location!,
                  style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
                ),
          trailing: Icon(CupertinoIcons.chevron_right,
              size: 16, color: cs.textDisabled),
          onTap: () => Navigator.of(context).pop(user),
        );
      },
    );
  }
}
