import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

/// Allows the match owner to view the current assigned scorer, remove them,
/// or search for a registered user by name and assign them to score this match.
class AssignScorerSheet extends StatefulWidget {
  final String matchId;
  const AssignScorerSheet({super.key, required this.matchId});

  @override
  State<AssignScorerSheet> createState() => _AssignScorerSheetState();
}

class _AssignScorerSheetState extends State<AssignScorerSheet> {
  Timer? _debounce;
  List<Map<String, dynamic>> _assignedScorers = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _searchResults = [];
  bool _loadingCurrent = true;
  bool _busy = false;
  String? _error;
  int _searchVersion = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentScorers();
  }

  Future<void> _loadCurrentScorers() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .get();
      final ids = (doc.data()?['scorer_ids'] as List?)?.cast<String>() ?? [];
      if (ids.isEmpty) {
        if (mounted) {
          setState(() {
            _assignedScorers = [];
            _loadingCurrent = false;
          });
        }
        return;
      }

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: ids.take(10).toList())
          .get();

      if (mounted) {
        setState(() {
          _assignedScorers = usersSnapshot.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList();
          _loadingCurrent = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCurrent = false);
      }
    }
  }

  void _search(String value) {
    _debounce?.cancel();
    final version = ++_searchVersion;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final query = value.toLowerCase().replaceAll(' ', '');
      if (query.isEmpty) {
        if (mounted) setState(() => _searchResults = []);
        return;
      }
      try {
        final result = await FirebaseFirestore.instance
            .collection('users')
            .orderBy('name_lowercase')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(20)
            .get();
        if (!mounted || version != _searchVersion) return;
        setState(() {
          _searchResults = result.docs
              .where((doc) =>
                  doc.data()['created_by'] == null &&
                  doc.data()['auction_id'] == null &&
                  (doc.data()['email'] as String? ?? '').isNotEmpty)
              .toList();
          _error = null;
        });
      } catch (_) {
        if (mounted) setState(() => _error = 'Could not search. Try again.');
      }
    });
  }

  Future<void> _save(List<String> ids) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updates = <String, dynamic>{'scorer_ids': ids};
      if (ids.isEmpty) {
        updates['active_scorer'] = null;
      }
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .update(updates);

      await _loadCurrentScorers();
      if (mounted) {
        setState(() {
          _busy = false;
          _searchController.clear();
          _searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ids.isEmpty
                ? 'Assigned scorer removed. Owner has scoring access.'
                : 'Scorer successfully assigned.'),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not update scorer. Only the owner can make changes.';
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SizedBox(
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(CupertinoIcons.person_badge_plus_fill,
                      color: cs.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Assign Match Scorer',
                    style: AppTextStyle.header3.copyWith(color: cs.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Only registered users can be assigned. They can record runs and wickets, while match management remains with you.',
                style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
              ),
              const SizedBox(height: 16),

              // ── Current Scorer Section ──
              Text(
                'CURRENT SCORER',
                style: AppTextStyle.caption.copyWith(
                  color: cs.textDisabled,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingCurrent)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_assignedScorers.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.containerLowOnSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 20, color: cs.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No external scorer assigned. As the match owner, you have scoring control.',
                          style: AppTextStyle.body2
                              .copyWith(color: cs.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._assignedScorers.map(
                  (scorer) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: cs.positive.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        ImageAvatar(
                          imageUrl: scorer['profile_img_url'],
                          initial: (scorer['name'] as String? ?? 'S')
                                  .characters
                                  .firstOrNull ??
                              'S',
                          size: 38,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scorer['name'] as String? ?? 'Scorer',
                                style: AppTextStyle.subtitle2.copyWith(
                                  color: cs.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                scorer['email'] as String? ?? 'Assigned Scorer',
                                style: AppTextStyle.caption
                                    .copyWith(color: cs.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _busy ? null : () => _save([]),
                          icon: Icon(Icons.person_remove,
                              size: 16, color: cs.alert),
                          label: Text(
                            'Remove',
                            style: AppTextStyle.button
                                .copyWith(color: cs.alert, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.5)),
              const SizedBox(height: 12),

              // ── Search & Assign Section ──
              Text(
                'ASSIGN NEW SCORER',
                style: AppTextStyle.caption.copyWith(
                  color: cs.textDisabled,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                enabled: !_busy,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Search user by registered name…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cs.containerLowOnSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _error!,
                    style: AppTextStyle.caption.copyWith(color: cs.alert),
                  ),
                ),
              if (_busy) const LinearProgressIndicator(),

              Expanded(
                child: _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Type a player’s name to search'
                              : 'No matching registered users found',
                          style: AppTextStyle.caption
                              .copyWith(color: cs.textDisabled),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final userDoc = _searchResults[index];
                          final userData = userDoc.data();
                          final userName =
                              userData['name'] as String? ?? 'User';
                          final userEmail =
                              userData['email'] as String? ?? '';
                          final isAlreadyAssigned = _assignedScorers
                              .any((s) => s['id'] == userDoc.id);

                          return Container(
                            decoration: BoxDecoration(
                              color: cs.containerLowOnSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: ImageAvatar(
                                imageUrl: userData['profile_img_url'],
                                initial:
                                    userName.characters.firstOrNull ?? 'U',
                                size: 34,
                              ),
                              title: Text(
                                userName,
                                style: AppTextStyle.subtitle2
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: userEmail.isNotEmpty
                                  ? Text(userEmail, style: AppTextStyle.caption)
                                  : null,
                              trailing: isAlreadyAssigned
                                  ? Text(
                                      'Assigned',
                                      style: AppTextStyle.caption.copyWith(
                                        color: cs.positive,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cs.primary,
                                        foregroundColor: cs.onPrimary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: _busy
                                          ? null
                                          : () => _save([userDoc.id]),
                                      child: const Text('Assign',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
