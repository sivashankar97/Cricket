import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:flutter/material.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/button/chip_button.dart';

/// Horizontal pool selector. A null pool id stands for "Ungrouped teams".
class TeamPoolChips extends StatelessWidget {
  final List<TeamPool> pools;
  final bool showUngrouped;
  final String? selectedPoolId;
  final bool ungroupedSelected;
  final ValueChanged<String?> onSelect;
  final VoidCallback? onNewPool;

  const TeamPoolChips({
    super.key,
    required this.pools,
    required this.onSelect,
    this.showUngrouped = false,
    this.selectedPoolId,
    this.ungroupedSelected = false,
    this.onNewPool,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final pool in pools) ...[
            ChipButton(
              title: pool.name,
              isSelected: !ungroupedSelected && pool.id == selectedPoolId,
              onTap: () => onSelect(pool.id),
            ),
            const SizedBox(width: 8),
          ],
          if (showUngrouped) ...[
            ChipButton(
              title: context.l10n.team_pools_ungrouped,
              isSelected: ungroupedSelected,
              onTap: () => onSelect(null),
            ),
            const SizedBox(width: 8),
          ],
          if (onNewPool != null)
            ChipButton(
              title: context.l10n.team_pools_add_new,
              onTap: onNewPool,
            ),
        ],
      ),
    );
  }
}
