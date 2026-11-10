# Upgrade assessment baseline v1 — November 7, 2026

November 9 follow-up: [runtime stat/spec selection](gear-modeling.md) now adds a guarded stat adapter and original role-derived manual spec starters while preserving existing custom weights. The offline reference weights/effect/cap evaluator below remain research; their numerical maps and full-loadout algorithm have not been imported into runtime scoring.

This establishes an executable, offline baseline for all nine classes and 29 spec variants. It is ready to inform the next Suite scorer implementation; it does not change current in-game hints, SavedVariables or custom profiles. Scores express disclosed preferences, not simulated DPS/healing, optimal tank survival or guaranteed BiS.

## Research scope and results

Reviewed the site's methodology, custom-search configuration and browser script, addon/comparison implementation, all 29 default spec pages, and public API results for all specs at levels **1, 10, 20, 40 and 60**. For every spec, additionally fetched level 60 with set and on-use scoring disabled. These are **203 page/API resources**, plus the configuration and earlier addon download. This evaluates the site's ranking model across every class, rather than claiming to have independently verified every item or every generated webpage.

The sampled full responses contain **17,914 item rows**, including repeated items between specs/levels. All **4,074 static item/slot scores** without listed effects or set contributions in the plain level-60 responses match the independently implemented weighted-stat/DPS calculation. Tolerance includes rounding of published DPS to two decimal places. Every sampled list is nonincreasing by score, and no row's reported availability exceeds the requested level. These checks establish arithmetic consistency, not that availability/source data or weights are correct.

All five sampled levels use exactly the configuration's weight map for each spec: there is no observed leveling-specific reweighting. The downloaded addon contains **225,014 valid rank bands** and at least one ranking for all **3,480 spec × level × faction combinations** (29 × 60 × 2). This is a coverage check, not a recomputation of every ranking or proof that every slot is populated at every level.

All live API responses identify **1.60.1.70862**. The downloaded release is labeled **2026.11.08-220a211**; retrieval was November 7 in America/Chicago (November 8 UTC). Search-engine versions of the pages can be older. Machine-readable observations, timestamps, data hash and per-spec results are in [the audit](research/foreverwow-audit-20261107.json). The backend generator was not available for inspection.

## Class-by-class evaluation

All numerical weights, including secondary stats, spell schools and weapon coefficients, are preserved in [the reference snapshot](research/foreverwow-stat-weights-20261107.json). Absent weights mean zero in the reference model. The numbers are observed external defaults, not independently calibrated Suite coefficients.

| Class | Specs evaluated | Matching static checks | Baseline interpretation and limits |
| --- | --- | ---: | --- |
| Warrior | Arms, Fury, Protection | 410 | Arms/Fury favor Strength, hit and weapon DPS; Fury has separate off-hand DPS. Protection emphasizes Stamina, defense, avoidance, block and armor. Retain distinct damage and tank profiles; no claim that one tank score optimizes every encounter. |
| Paladin | Holy, Protection, Retribution | 372 | Holy values healing/regen/Intellect; Protection mixes defenses with spell threat stats; Retribution mixes physical and smaller holy/spell contributions. Balanced is inadequate as a shared default. |
| Hunter | Beast Mastery, Marksmanship, Survival | 436 | All three site profiles are ranged-focused, with small melee-DPS coefficients. Survival needs an explicit ranged-build choice; the site also lists melee-themed set effects which it does not score. Pet scaling and melee Survival are not established by these maps. |
| Rogue | Assassination, Combat, Combat Daggers, Subtlety | 553 | All prioritize Agility, hit and weapon DPS with separate hand values. Combat and Combat Daggers have identical numerical weights but different weapon selection context. A dagger variant must not recommend a non-dagger main hand as a definitive upgrade. Speed/poison/ability effects remain unmodeled. |
| Priest | Discipline, Holy, Shadow | 443 | Discipline/Holy have different recovery, Intellect and crit tradeoffs; Shadow values shadow damage and hit with lower crit. Healing profiles and Shadow leveling cannot share a generic caster map. Wand coefficients are preferences, not a healing-throughput benefit. |
| Shaman | Elemental, Enhancement, Restoration | 416 | Elemental values nature/spell damage and hit; Enhancement emphasizes Strength, weapon DPS and physical secondary stats with small spell values; Restoration emphasizes healing/regen. Imbues, speed, dual-wield legality and rotations require separate evidence. |
| Mage | Arcane, Fire, Frost | 450 | Distinct school weights and crit/Intellect differences: Fire crit 1 versus Frost 0.6; Arcane Intellect 0.6 versus 0.45. Keep general spell bonuses separate from additional school-only bonuses without alias duplication. |
| Warlock | Affliction, Demonology, Destruction | 446 | Affliction crit 0.35 versus Destruction 0.85; Demonology has higher Stamina weight. Distinct school splits are present. Pet/talent conversions and encounter damage mixes are not explained by the weights. |
| Druid | Balance, Feral Cat, Feral Bear, Restoration | 548 | Balance mixes arcane/nature; Cat values Agility/Strength; Bear emphasizes Stamina/armor/avoidance; Restoration values healing/recovery. Cat and Bear share a talent tree but require separate manual roles. The site's positive base-weapon-DPS coefficients need Forever form-mechanics verification; v1 marks changed Feral weapons conditional. |

## What the site actually calculates

For a static item in a slot:

`reference score = sum(raw stat amount × spec weight) + base armor × armor weight + weapon DPS × slot weight`

Explicit bonus armor is a separate stat in these API results. Weapon-specific skill stats use the general weapon-skill coefficient. Main/two-hand uses `melee_dps`; off hand uses `offhand_dps`, falling back to half `melee_dps`; ranged uses `wand_dps` where present, otherwise `ranged_dps`. Flat bonus weapon damage is its own weighted stat, not the white-damage range of a weapon. Item level and rarity are not extra terms.

The comparison addon reads precomputed scores for ordinary items, and adds actual link stats for random-roll items to a stored base. Website percentages compare an item to the top item for that slot. Addon percentages compare it to equipped gear. Neither measures a predicted output change.

Recognized on-use stat effects can be averaged by duration/cooldown. The Fury Slayer's Crest control changes from 32 to 53.67 when enabled: `64 AP × 0.5 + 260 AP × 0.5 × 20/120`. Set outputs are consistent with assigning each recognized bonus's weighted value divided by its threshold to each piece. For example Warlord's Battlegear adds `20 Stamina × 0.1 / 2 + 40 AP × 0.5 / 6 = 4.33`. This allocation is an inference from output, not inspected server source.

Set value is therefore a pursuit allowance, not necessarily the immediate benefit of equipping one piece. The downloaded addon does not recount equipped sets. Among sampled full level-60 rows there are 207 scored effect occurrences and 282 unscored occurrences (not unique effects). Complex tier abilities and many procs remain unscored. Static zone-dependent effect values can reflect an advantageous condition. There is no established cap-aware or rotation-aware valuation in the inspected calculation.

## Suite baseline algorithm

The original [reference evaluator](../scripts/lib/gear-baseline.cjs) implements the following contract. It uses the captured weights as a starting reference while improving comparison context.

1. **Select a spec and intended role.** Keep all 29 IDs stable, allow manual selection, and preserve character custom profiles. Talent detection may suggest a profile, but cannot decide Cat/Bear or ranged/melee Survival, or reliably distinguish early hybrid leveling paths. Never compare absolute scores across different profiles.
2. **Resolve eligible, complete item instances.** Use actual item links/rolls, class/level/proficiency, legal destination slots, dual-wield permission and unique-equipped restrictions. For a carried item, use actual required level/eligibility; quest acceptance level belongs to acquisition planning. A missing/secret/rejected native result is unavailable, not zero. A confirmed empty slot is distinct from a zero-scoring occupied item.
3. **Normalize stats once.** Inputs to the offline evaluator are canonical facts. Raw API keys are rejected. Combined spell power, generic spell damage, heal-only power, school-only bonuses, general AP, ranged-only AP, armor and bonus armor must represent independent contributions. Do not count API aliases twice, convert Strength into AP and also weight both, or add bonus armor again when the supplied armor already includes it. Rating amounts and percentage points are different units. Applicable weapon skill depends on the equipped weapon family. An eventual adapter must validate these shapes on the actual client before enabling the corresponding term.
4. **Build each complete legal result.** Try both ring/trinket slots separately. For hands, retain all surviving contributions; a two-hander removes both hands, and a one-hander replacing a two-hander leaves the off hand empty. Never assume an additional unowned weapon. Keep unique constraints and spec weapon restrictions. Item level is a separate explicit user preference, not a hidden bonus in this stat model.
5. **Calculate full-loadout utility.** Sum independent static stats and verified effect contributions. Add a set bonus only when the resulting loadout reaches its actual threshold; losing it subtracts its full modeled value. Count distinct set pieces, not duplicate physical copies of one piece. Do not spread future set value over individual pieces.
6. **Apply caps only with verified context.** A provided cap is a remaining gear budget in canonical units, after non-gear/talent/buff contributions. Apply it to the aggregate before and after totals, not per item. No Classic-derived numeric hit/expertise cap is hardcoded. With no supplied validated cap, v1 remains linear and explicitly discloses that limitation.
7. **Model only validated effects.** Constant effects need independent stats and provenance. A use effect needs duration, cooldown, explicit utilization and availability group: `equivalent stats = bonus × min(1, duration/cooldown) × utilization`. Shared-use interactions remain conditional unless separately modeled. Conditional zone/form effects need known context. Proc/ability changes without a validated model remain unresolved; do not silently fabricate uptime or score them as absent.
8. **Compare resulting scores.** `delta = utility(after) - utility(before)`. Unknown effects on unchanged, noninteracting gear cancel for a delta only when their independence is an established input fact (`independent: true` with provenance). Otherwise even an unchanged unknown effect makes a changed-stat/weapon comparison conditional, because its scaling may change. Changed unresolved contributions also make the result conditional. Return every placement, preferring an assessable placement before a conditional one, then the largest delta. Report unmodeled cap/talent/rotation assumptions even for assessable results.
9. **Communicate the result.** Return upgrade, downgrade, near tie, fills empty slot, conditional or unavailable. The provisional noise threshold is `max(0.1 point, 1% of the removed group's known static/DPS score)`; this is a UX starting choice, not a calibration result. An optional percentage uses that removed-group denominator and must be labeled **score gain versus replaced gear**. Sets/caps can affect its numerator, so it is not a pure item-stat ratio. Empty slots and zero denominators have no fabricated percentage. Show the named profile, contributions and limitations; conditional results contain only a partial modeled delta and do not get an unconditional upgrade marker or a headline percentage.

In compact form, with canonical gear totals `T`, validated effect/set totals `E`, and remaining gear caps `C` when supplied:

`U(loadout, spec, context) = sum_stat(weight × effective(T + E, C)) + sum_weapon(slot weight × DPS)`

`effective(x, C) = min(x, C)` for a validated capped stat, otherwise `x`.

The evaluator assumes `candidate.eligible` and `candidate.destinations` have already been resolved by the native eligibility adapter. It validates physical/unique identity and basic hand configurations; it is not a substitute for WoW's equip rules. `known: true` means the normalizer has completely enumerated the item, including unknown effects. The full-loadout input includes every equipped slot whose set/cap/effect interaction matters. Unchanged unknown effects are only safely cancellable when their interactions are absent or already represented by context; independence must not be asserted merely to obtain a green marker. Unmodeled situational stats such as resistances retain zero reference weight; their situational usefulness requires a different profile/model.

## Concrete deliverables and validation

- [Observed weights for all 29 profiles](research/foreverwow-stat-weights-20261107.json), with provenance and hash.
- [Per-spec audit and all-level rank coverage](research/foreverwow-audit-20261107.json).
- [Independent published static examples](research/gear-baseline-golden-20261107.json), one per spec, excluding effect/set scoring.
- [Executable baseline](../scripts/lib/gear-baseline.cjs) and [behavior checks](../tests/gear_baseline.test.cjs): all-class golden scores; actual accessory replacement; complete hand loss; set completion/breakage/duplicates; caps; environmental/on-use/unknown effects; Feral/Survival/dagger ambiguity; eligibility/invalid values/unique conflicts; empty slots and near ties.
- [Research collector/auditor](../scripts/research-gear-baseline.cjs). `node scripts/research-gear-baseline.cjs --collect` fetches two paced public requests at a time into `.cache/gear-baseline-research`. `--audit` verifies resource hashes and regenerates observations/fixtures. Downloaded addon rank coverage is optional and reads the earlier cached `Data.lua` without executing it. `node --test tests/gear_baseline.test.cjs` runs the standalone model checks without network/cache dependencies.

Before replacing runtime scoring: validate native stat aliases/units and matching-build capability behavior; add supported stat keys to the Lua 5.1 scorer/editor; migrate saved profiles without altering their weights; introduce manual spec selection; reconcile icon and tooltip explanations; then add validated effect/set providers. Feral weapon mechanics, melee Survival, speed-sensitive builds, weapon-skill applicability, raw rating units, actual caps and unknown effect interactions are explicit evidence gaps. Baseline numeric weights may be tuned after real comparisons; API agreement alone cannot validate them.

Validation: all 11 standalone behavior tests pass, including the 29 external golden examples. The normal addon checker passes with 82 Lua 5.1 files, identical TOCs and 31,990 substitute behavior assertions. These are offline checks. No runtime feature was enabled, deployed or packaged. Native smoke tests, actual running build/Interface, practical class-weight calibration and taint/visual results remain pending.

## Sources

- [ForeverWoW methodology](https://foreverwow.gg/about/), [custom search and public weight configuration](https://foreverwow.gg/tool/), [addon distribution](https://foreverwow.gg/addon/).
- Every API/spec-page URL and SHA-256 is recorded in the local cache manifest; for example [Fury](https://foreverwow.gg/api/bis?class=warrior&spec=fury&level=60), [Holy Paladin](https://foreverwow.gg/paladin/holy/), [Survival Hunter](https://foreverwow.gg/hunter/survival/), [Feral Cat](https://foreverwow.gg/druid/feralcat/).
- Local matching build-70862 `Blizzard_APIDocumentationGenerated/ItemDocumentation.lua` declares that `GetItemStats` may return nothing and allows secret arguments only when untainted. It does not document all stat-table keys, units, aliases or ordinary-addon access in every context. Preserve Suite's existing secret-value guards and native capability checks.
