# Locale-aware ILS currency + coin clarity for Money Math (Phase 3)

Phase 3 adds a `Currency` concept (`usd`/`ils`) chosen by `AppLang`, so English keeps US cents and Hebrew teaches the Israeli coin set (10 agorot, ½₪, ₪1, ₪2, ₪5, ₪10) with every value stored in the smallest unit (agorot). The abstract colored-circle emoji (🟤⚪🔵🟡) are replaced by a drawn `CoinChip` with the value printed on it, and a tappable Coin Info Map legend is reachable from the Money Math home and via a help affordance on the game screen. All Money Math prompts and legend strings route through `AppStrings`, and amounts render as LTR islands inside the RTL Hebrew UI. The change is well-scoped: it touches only the money model, generator, two screens, two new widgets, the string table, and tests — no worlds/trail/unlock/star structure moves, and no multiplication world.

Watch for: nothing blocking. One cosmetic inconsistency (confirmed) — the 10-agorot chip prints a bare `10` while every other chip carries a currency mark (`½₪`, `₪1`, `5¢`); the Info Map disambiguates it, so it is not a defect.

**Verdict**: APPROVED

## High-level view

The currency abstraction is clean: value math stays integer-in-smallest-unit, so totals, `CoinPile.total`, make-change, and distractor generation all generalize without special-casing. `Currency.format` is the only place that knows about `¢` vs `₪`/agorot, and its USD branch is textually `'$amount¢'` — the same string the original `_fmt` produced.

The USD path is byte-identical, and this is verifiable rather than asserted. The two places that were parameterized — `_distinctAmounts` (now stepping by `_smallestCoin`) and `_makeChange` (now stepping by `_changeStep`) — both collapse to the original expressions when the unit is 1 and the step is 5, which is exactly the USD case. The `_coinSet(d).first` substitutions for the old literal `Coin.penny` also resolve to penny for USD.

The ILS set and math are correct and non-negative. Denominations match the design and the user's confirmation (10a/½₪/₪1/₪2/₪5/₪10). make-change uses 10-agorot steps with payment guaranteed at least one step above price, so change is strictly positive and always a multiple of the smallest coin (hence coin-representable). Distractors are offsets in multiples of 10 agorot and are filtered to stay positive.

Coin clarity is delivered without assets: `CoinChip` is a bordered, metal-tinted circle with the value printed via a `FittedBox`, and `CoinChipRow` sizes itself with `LayoutBuilder` and wraps, so a pile of several coins cannot overflow the 430px frame. The Coin Info Map is a scrollable, height-capped comic sheet listing each coin of the current currency with its chip, localized name, and value.

RTL handling is correct where it matters: standalone amounts (chips, text-choice tiles, legend values) are wrapped in `Directionality.ltr`, while localized sentence prompts stay in the ambient direction and let the Unicode bidi algorithm handle the embedded numerals.

Test coverage is deterministic (seeded `Random`) and hits the required cases: ILS formatting, he-mode uses only ₪ denominations, en-mode stays US-only, non-negative ₪ make-change, 4 distinct valid choices per question type, and widget tests that the legend opens and lists the current currency's coins. The pre-existing USD make-change test is untouched and still parses `¢`.

<details>
<summary>Issues (1)</summary>

1. **Agora chip label omits a unit mark** (cosmetic, non-blocking) — the 10-agorot chip prints a bare `10` while every other chip in both sets carries a currency mark. The Info Map names and values it correctly, so meaning is recoverable; consider `10a`/`10אג׳` later for consistency if desired. No action required for this phase.

</details>

<details>
<summary>Details</summary>

### Currency abstraction and the byte-identical USD guarantee

`Currency` carries `coins`, `unit` (100 for both), and `format(int)`. Because every value stays in the smallest integer unit, `CoinPile.total`, the make-change arithmetic, and `_distinctAmounts` never needed to know the currency and generalize untouched — which is what makes the USD-identical claim checkable.

The USD byte-identical requirement is the sharpest risk in this phase, and it holds up under a line-by-line read of the two parameterized sites:

```
// _distinctAmounts, USD => unit == Coin.penny.cents == 1
spread      = 2 + (answer / 1 * 0.4).round()   // == 2 + (answer * 0.4).round()
deltaUnits  = _rng.nextInt(spread*2+1) - spread // identical RNG draw
cand        = answer + deltaUnits * 1           // == answer + delta
filler      = answer + 1 ; filler += 1          // == original
```

```
// _makeChange, USD => step == _changeStep == 5
price = priceUnits * 5 ; pay = price + extraUnits * 5   // identical
```

Because `answer / 1` is a double equal to `answer` and `* 0.4` then `.round()` yields the same int, `spread` is identical, so the RNG draw count and sequence are preserved — the generated option sets are the same, not merely equivalent. The `_fmt` USD branch returns `'$amount¢'`, matching the old `'$cents¢'`. The `_whichMore` tie-break and `_makeAmount` filler swapped the literal `Coin.penny` for `_coinSet(d).first`, which is penny at every USD tier. English prompts are the same literals via the `_he == false` branch. The pre-existing `money_make_change_test.dart` (seeded, parses `¢`) is unchanged and exercises this path.

### ILS coin set and make-change correctness

The ILS denominations are exactly `{10, 50, 100, 200, 500, 1000}` agorot — 10a, ½₪, ₪1, ₪2, ₪5, ₪10 — matching design §6 and the user's confirmed answer. `_coinSet` mirrors the USD 3-tier difficulty ramp (small coins first, full set at the top tier).

make-change in ILS steps by `_changeStep == 10`: price and the extra are each `≥ 1` step, so `answer = extraUnits * 10 > 0` and is always a multiple of 10 agorot. Since 10 agorot is the smallest coin, any multiple of 10 is representable with coins, satisfying the "correct and non-negative for both currencies, including the Vault ₪ make-change" requirement. `_distinctAmounts` offsets by `_smallestCoin == 10` and filters `cand > 0`, so distractors are positive, representable agora amounts.

### ILS formatting

`Currency.format` reads kid-friendly: `< 100` → `'N אג׳'`, exact shekels → `'₪N'`, mixed → `'₪N.NN'` with zero-padded agorot (e.g. `105 → ₪1.05`, `250 → ₪2.50`). The format body uses no RTL control characters and is consumed inside `Directionality.ltr` wrappers at every display site, so the numerals read left-to-right in the Hebrew UI. The tests pin these exact strings.

### CoinChip and no-overflow piles

`CoinChip` draws a circle with a radial metal gradient, a 3px `AppTheme.ink` border, and `AppTheme.comicShadow` — on comic style, no image assets. The value (`chipLabel`) is printed via a `FittedBox` so it scales down rather than clipping. `CoinChipRow` wraps the chips and, via `LayoutBuilder`, shrinks the chip size (to ~0.8×, floored at 30px) when a pile has more coins than two rows' worth, so even a 5-coin pile in a half-width option tile stays inside the 430px frame. Both the chip label and the row are wrapped in `Directionality.ltr`. No `MediaQuery.of(context).size` usage anywhere in the new code.

### Coin Info Map legend

`CoinInfoMap` is a modal bottom sheet built on `ComicPanel`, height-capped at 560px via `ConstrainedBox` (deliberately avoiding MediaQuery-based sizing per steering) with a `SingleChildScrollView` so a tall list scrolls. Each `_CoinRow` shows the coin's `CoinChip`, its localized name (`usdCoinName`/`ilsCoinName`), and its formatted value as an LTR island. It is reachable from a comic "Coins" button on the home screen and a help affordance on the game screen, both big tap targets. The widget `L10n` signature `L10n(lang:, notifier:, child:)` matches what the screens and tests construct.

### Localization and LTR islands

New strings (`coinsButton`, `coinInfoTitle`, `coinInfoClose`, `usdCoinName`, `ilsCoinName`) are added to both `EnStrings` and `HeStrings`; English values are plain literals and Hebrew values are authored kid names (עשר אגורות, חצי שקל, שקל, שני שקלים, חמישה שקלים, עשרה שקלים). Prompts branch on `_he` with byte-identical English. The game screen resolves the language once in `initState` via the non-listening `L10n.read`, matching the Word Wizard pattern and the generator's static shape; the home and widgets read `context.lang`/`context.l10n`. Sentence prompts carry the embedded amount in the ambient direction and rely on the bidi algorithm for the numeral run, while every standalone amount (chips, text choices, legend values) is explicitly `Directionality.ltr`.

### Scope discipline

The diff is confined to `money_question.dart`, `money_generator.dart`, the two money screens, the two new widgets, `app_strings.dart`, and the two test files. `money_level.dart`, `money_state.dart`, and the trail screen are untouched, so worlds, trail layout, unlock gating, and star/fastest-time records are unchanged. No multiplication world (correctly deferred to Phase 4). The retained `CoinPile.emojiRow` getter and `Coin.emoji` field are dead-but-harmless backward-compat holdovers; no production code references `emojiRow` anymore (confirmed by searching the worktree).

### Tests

`money_ils_currency_test.dart` adds 8 deterministic tests (seeded `Random`): ILS formatting across agora/whole/mixed, USD formatting still `¢`, he-mode piles contain only ILS denominations (explicitly carving out the shared value 10 so a dime can't masquerade as 10 agorot), en-mode stays USD-only, ₪ make-change strictly positive and agora-valued, 4 distinct valid choices for countCoins/makeChange (text) and makeAmount (pile totals) plus distinct A/B for whichMore, and two widget tests at a 430×900 surface that the legend opens and names every coin of the current currency. The commit records `flutter build web` success and `flutter test` → all 72 pass (64 baseline + 8 new), consistent with the diff. Per the brief I did not re-run the suites; the evidence is present and the diff corroborates it.

The one theoretical gap is the `makeAmount` 4-distinct-totals filler: if the 40-try guard loop fails to find 4 distinct piles, the filler appends piles that could repeat a total, which would fail the distinctness assertion. In practice the guard loop fills 4 distinct piles and the seeded test passes deterministically, so this is informational, not a regression this phase introduced (the filler shape predates Phase 3).

</details>

<details>
<summary>File map</summary>

- `lib/games/money_math/models/money_question.dart` — adds `Currency` enum with `format`; `Coin` gains `currency`/`chipLabel`/`color`; US set kept, ILS set added; `usdAll`/`ilsAll`/`forCurrency`.
- `lib/games/money_math/services/money_generator.dart` — threads `AppLang`/`Currency`; branches `_coinSet`, prompts, `_fmt`, make-change step, and distractor step by currency; USD collapses to original.
- `lib/games/money_math/screens/money_math_home_screen.dart` — adds the "Coins" legend button opening the Coin Info Map.
- `lib/games/money_math/screens/money_game_screen.dart` — resolves lang in `initState`; renders piles as `CoinChipRow`; adds a "?" help affordance; text choices wrapped LTR.
- `lib/games/money_math/widgets/coin_chip.dart` — new `CoinChip` + `CoinChipRow` (LayoutBuilder, Wrap, LTR, no assets).
- `lib/games/money_math/widgets/coin_info_map.dart` — new scrollable, height-capped legend sheet.
- `lib/core/l10n/app_strings.dart` — new coin-legend strings + `usdCoinName`/`ilsCoinName` in En/He.
- `test/money_ils_currency_test.dart` — 8 new deterministic tests (formatting, coin-set isolation, make-change, distinct choices, legend widget).

Full diff: `git -C <worktree> show 8829274`.

</details>
