# Gear stats and manual spec selection

November 9, 2026 implementation. Open `/wfs gear` → **Upgrades → Comparison profile** to select a spec, broad role or saved custom profile. Choices are manual and character-owned; they do not change learned talents. Automatic retains its previous class-based starter, and existing custom selections remain active after updating.

## Stats and units

The editor has 46 stat weights plus melee/ranged DPS coefficients. The original 13 fields retain their keys and arithmetic. New fields cover physical/spell/ranged hit, crit and haste ratings; expertise; dodge, parry, block rating/value; armor/spell penetration; flat health/mana and health recovery; effective spell-damage/healing totals; six school-only damage bonuses and six resistances.

Ratings use raw API points, not percentage points. There is no hidden rating conversion or cap calculation. Armor is the native total; bonus armor is not added again. Weapon-family skill, flat weapon damage, proc/set effects, caps, speed-specific abilities and talent/pet scaling remain outside this step.

`GearStats.lua` supplies both markers and tooltip comparisons from actual links. Ordered native aliases choose one amount rather than summing potentially overlapping fields:

| Stat | Native priority |
| --- | --- |
| Armor | `RESISTANCE0_NAME`, then `ITEM_MOD_ARMOR_SHORT` |
| Physical hit/crit/haste | Generic rating, then matching melee rating |
| Spell hit/crit/haste | Spell-specific rating, then generic rating |
| Ranged hit/crit/haste | Ranged-specific rating, then generic rating |
| Effective spell damage | `ITEM_MOD_SPELL_POWER_SHORT`, then `ITEM_MOD_SPELL_DAMAGE_DONE_SHORT` |
| Effective healing | `ITEM_MOD_SPELL_HEALING_DONE_SHORT`, then `ITEM_MOD_SPELL_POWER_SHORT` |
| Resistances | `RESISTANCE1_NAME` through `RESISTANCE6_NAME` |

Every present alias must be readable and finite. A public alternative does not bypass a restricted field. New alias groups also reject unequal alternatives: without native evidence, they could be independent contributions or overlapping totals. Legacy armor retains its existing priority. Other ordinary fields use `ITEM_MOD_<key>_SHORT`. Physical/spell/ranged weights represent separate intended contributions; hybrid custom profiles choose their own relative weights.

Effective spell/healing totals are alternatives to the original independent spell fields. New spec starters use effective totals. Existing custom spell weights retain their previous arithmetic. Save explains and rejects overlapping effective/legacy weights instead of silently double counting or rewriting an old profile.

School-specific fields are not invented GetItemStats keys. Positive school weights additionally request `C_TooltipInfo.GetHyperlink` and parse exact English static equip sentences, such as `Equip: Increases damage done by Fire spells and effects by up to 7.` Color markup and whitespace are normalized. Use/set text does not become a static bonus. Missing/restricted data, unsupported locales or unfamiliar Equip school-damage wording make the comparison unavailable. A readable tooltip with no matching school bonus records zero for that school. Support is currently enUS/enGB; profiles without school weights do not request extra tooltips. Native examples must still confirm exact alias/total semantics and tooltip coverage.

## Spec starters

The picker shows only the current class's specs. All 29 are original preference maps derived from Suite's existing roles, not imported third-party coefficients, simulation results or calibrated optimal weights. A custom copy is independent of its built-in source.

| Class | Choices |
| --- | --- |
| Warrior | Arms, Fury, Protection |
| Paladin | Holy, Protection, Retribution |
| Hunter | Beast Mastery, Marksmanship, Survival (ranged) |
| Rogue | Assassination, Combat, Combat Daggers, Subtlety |
| Priest | Discipline, Holy, Shadow |
| Shaman | Elemental, Enhancement, Restoration |
| Mage | Arcane, Fire, Frost |
| Warlock | Affliction, Demonology, Destruction |
| Druid | Balance, Feral Cat, Feral Bear, Restoration |

Cat/Bear omit raw weapon DPS pending form-mechanics validation. Hunter profiles are ranged builds. Combat Daggers requires a known dagger main hand in stat mode; its custom copies retain the restriction. These limits are visible in settings. General hand-set logic and the disclosed 50% off-hand DPS factor remain unchanged.

## Preservation and validation

Initialization preserves all eight custom IDs, labels, numeric coefficients, explicit zeros, next-ID counter, active selection, comparison mode and tooltip-detail setting. Missing new weights remain absent/zero. Existing names that collide with new spec names stay editable. An unchanged precise coefficient, including scientific notation, retains its exact stored numeric value on an editor save; changed inputs keep the existing bounded three-decimal rule.

Editor height follows the stat catalog, with actions/status below all inputs and scrolling for keyboard-focused lower fields outside combat. Spec changes are refused in combat. Search recognizes specs and the added stats.

`tests/gear_model_spec.lua` covers repeated full-profile migration, actual SavedVariables startup, all spec selections/reloads/class isolation, raw units and secret aliases, spell conventions, six school readers, actual marker/tooltip/breakdown agreement, dagger-copy restrictions and editor reachability. Native calibration, appearance, item examples and taint checks remain pending in `testing.md`.

## Source evidence

Pinned build-70862 Blizzard `ItemDocumentation.lua` documents `C_Item.GetItemStats`, `MayReturnNothing` and `AllowedWhenUntainted`; `TooltipInfoDocumentation.lua` documents `C_TooltipInfo.GetHyperlink` and its optional return. Neither enumerates every stat-table key or guarantees ordinary-addon access in all contexts. Export revision: `9dc84f0d3bbae1768ac3405b3716000bd93eda06`.

Read-only installed ForeverWoWBiS key-index and [Pawn source](https://github.com/VgerMods/Pawn/blob/main/Pawn.lua) review informed terminology and API-versus-tooltip distinctions. No implementation or numeric maps were copied; these references are not native verification. The earlier [all-class baseline research](gear-upgrade-baseline.md) remains a future reference rather than this patch's coefficient source.
