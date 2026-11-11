---
name: framer
description: For the tournament, all components will be animated. Adds Framer-style motion (staggered fade-slide entrances, count-up numbers, growing bars, tap scale, animated tab and filter switches) to every component on the Khelo tournament pages, using the app's shared animation widgets. Use when building or changing tournament screens (overview, matches, teams, points table, stats, leaderboards, scorecards) or when the user types /framer or asks to animate tournament UI.
disable-model-invocation: true
---

# Framer: animate every tournament component

Every component on the tournament pages (`khelo/lib/ui/flow/tournament/`) gets motion. Use the shared widgets below; don't hand-roll `AnimationController`s in screens.

## Building blocks (`style/lib/animations/`)

| Need | Widget | Notes |
|------|--------|-------|
| Item appears | `FadeSlideIn(delay:)` (`fade_slide_in.dart`) | Fade + 6% slide up, once |
| List / grid appears | `Appear(index:)` from `detail/components/tournament_widgets.dart`, i.e. `FadeSlideIn(delay: AppStagger.of(index))` | 40 ms step, capped at 8 items, so long lists don't drag |
| Number appears | `CountUp(value:, decimals:, style:, format:)` (`motion.dart`) | Counts from 0 on first build; integers and decimals (NRR, SR, econ) |
| Bar / progress | `GrowBar(fraction:, color:)` (`motion.dart`) | Grows from 0 to `fraction` (0–1) |
| Stacked bar / any content | `GrowIn(child:, delay:)` (`motion.dart`) | Reveals the child from the left as one piece |
| Tappable card or row | `OnTapScale(onTap:)` | Scales to 0.96 while pressed |
| Content swaps (tabs, filters, sub-tabs) | `AnimatedSwitcher(duration: AppAnimations.fast)` with a `ValueKey` per state | Fade between states, never a hard cut |
| Tab change | `PageController.animateToTab` | Already in `app_animations.dart` |

Timing comes only from `AppAnimations` (`fast` 250 ms, `normal` 380 ms, `slow` 480 ms, curve `easeOutCubic`).

## Rules
1. **Every component animates:** the hero / header, stat tiles, tab bar, each list item, table rows, leaders, charts and empty states.
2. **Entrance once.** Animate on first build only. Rebuilds from streams (live score updates) must not replay the entrance: key items by id, not by index.
3. **Stagger by position** with `AppStagger.of(index)`; cap at 8 so items after the 8th appear together.
4. **Numbers count up** (runs, wickets, points, NRR, strike rate). Keep the final text identical to the static version, e.g. `+1.28`, `176.1`.
5. **Bars grow** for comparisons (team runs, MVP point splits, form, progress such as "matches played 32 / 32").
6. **Respect reduced motion:** the shared widgets skip animation when `MediaQuery.maybeDisableAnimationsOf(context)` is true. New helpers must do the same.
7. **Taps:** wrap tappable cards in `OnTapScale`; keep `InkWell` ripples off cards that already scale.
8. **No layout jumps:** animate opacity / transform only; reserve the final size up front.
9. **Colours stay on theme:** motion never introduces new colours. Use `context.colorScheme` (navy / red / white, green only for success). See the vault's `Design System.md`.
10. **Performance:** no animation inside widgets that rebuild every ball; wrap heavy animated subtrees in `RepaintBoundary`.

## Checklist for a tournament component
```
- [ ] Entrance uses FadeSlideIn (+ AppStagger in lists)
- [ ] Numbers use CountUp, comparison bars use GrowBar
- [ ] Tappables use OnTapScale
- [ ] State swaps use AnimatedSwitcher with keys
- [ ] Reduced motion respected
- [ ] Stream rebuilds don't replay entrances
- [ ] Only theme colours
```

## Example
```dart
ListView.builder(
  itemCount: leaders.length,
  itemBuilder: (context, index) => FadeSlideIn(
    key: ValueKey(leaders[index].id),
    delay: AppStagger.of(index),
    child: OnTapScale(
      onTap: () => openPlayer(leaders[index]),
      child: LeaderRow(
        name: leaders[index].name,
        value: CountUp(value: leaders[index].runs, style: AppTextStyle.header3),
        bar: GrowBar(fraction: leaders[index].runs / leaders.first.runs),
      ),
    ),
  ),
);
```
