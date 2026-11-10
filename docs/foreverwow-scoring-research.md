# ForeverWoW.gg item-scoring research — November 7, 2026

Follow-up: [all-class baseline](gear-upgrade-baseline.md) extends this initial Fury investigation to every class/spec, captures the numeric maps, verifies sampled arithmetic and provides an original offline comparison algorithm. Runtime scoring remains unchanged.

Research requested by the user; no addon behavior changed or third-party implementation imported. Public resources were retrieved into `.cache` only. Existing unrelated working changes were preserved.

## Evidence

- [Methodology](https://foreverwow.gg/about/)
- [Custom search](https://foreverwow.gg/tool/), including its embedded `cfg` JSON and public ToolView script
- [Addon page](https://foreverwow.gg/addon/) and its current public download, `ForeverWoWBiS-2026.11.08-220a211.zip`
- [Fury API response](https://foreverwow.gg/api/bis?class=warrior&spec=fury&level=60), also requested with `no_sets=1&no_on_use=1`
- Downloaded addon `Score.lua`, talent selection in `Core.lua`, and generated `Data.lua` header
- Suite `Scoring.lua` and `Items.lua`

The live download and API identify build **1.60.1.70862**. The release is labeled November 8 by the site although the user's local research date is November 7. Web search's cached pages showed older build/download labels; prefer the directly retrieved evidence. The backend generator was not obtained, so distinguish observed results from inferred server internals.

## How their model works

The public configuration exposes 29 spec weight maps. A normal stat contributes `amount * spec weight`; weapon DPS has slot-dependent weights. Additional recognized effects and set allowances can increase the score. This is a weighted ranking system; the inspected public artifacts do not establish a full combat simulation or a derivation/calibration for the weights.

Example Fury weights: Strength 1, Agility 0.75, attack power 0.5, crit rating 1, hit rating 1.25, haste/expertise 0.9, weapon skill 1.5, Stamina 0.1, main-hand DPS 7, off-hand DPS 3.5. Its ranged-DPS weight is 0.2. Do not assume these raw rating weights are weights per percentage point.

Verified examples:

- Lionheart Helm: `18*1 + 28*1 + 20*1.25 = 71`. Its armor contributes nothing to this Fury profile.
- Death's Sting: `10*0.1 + 38*0.5 + 3*1.5 + 66.39*7 = 489.23` main hand; replacing DPS weight 7 with 3.5 gives 256.87 off hand.
- Slayer's Crest: static `64*0.5 = 32`; the API adds `260*0.5*(20/120) = 21.67` for the use effect, totaling 53.67. Disabling on-use scoring returns 32. The API explicitly reports uptime 1/6. This averages use availability rather than modeling burst timing or actual player activation.

Spec profiles also expose school-specific spell damage, healing, mana regeneration, penetration, defenses and other attributes. For example Fire Mage weights crit at 1 versus Frost's 0.6, while both weight Intellect at 0.45. The site lets users override weights and re-ranks through `/api/bis`; the public browser script renders server results rather than calculating all effects itself.

Level/faction/source/profession/PvP filters change the candidate pool. Random-suffix variants are ranked separately. Availability can reflect quest acceptance level instead of only the item's required level. Website percentage bars are `item score / best score in that slot`, not expected damage or healing percentages.

## Set bonuses and model limits

The API returns bonus thresholds, scored/active flags and a separate `set_bonus` value. Results support a threshold-based allocation: sum each recognized reachable bonus's weighted value divided by its required piece count. Warlord's Battlegear gives Fury `20*0.1/2 + 40*0.5/6 = 4.33` per piece; Heroism's six-piece +40 AP contributes `40*0.5/6 = 3.33`. These numbers match returned scores. This allocation formula is inferred from outputs, not verified backend source.

The downloaded addon reads fixed precomputed item scores; it does not recount equipped set pieces when comparing. A piece can therefore receive speculative set value without completing that bonus. Complicated ability changes and proc effects often explicitly say not scored. The model should not be treated as an exact answer for caps, hybrid talents, encounter timing or set breakpoints. The Rune of the Guard Captain example returns a score consistent with the tripled zone-dependent AP effect, illustrating another context assumption worth checking before adopting effect values.

## In-game implementation observed

Fixed items use generated per-spec/per-slot score lookups. Random-roll items combine a stored base contribution with readable stats from the actual item link. Rings/trinkets compare against the lower-scoring equipped member; two-handers compare against both occupied hands. The addon computes rounded `(candidate - equipped) / equipped * 100`, flags at least 1% after rounding, and treats zero-score baselines as empty in its comparison record. This percentage is a score difference, not a simulated output gain.

Automatic spec selection uses the talent group with the most spent points and permits a manual override. Shared-tree variants default to the first matching entry, so cat/bear and Combat/daggers still need explicit selection when appropriate. Rankings/scores ship with the addon and require updates; they are not downloaded by WoW during play.

## Comparison and recommended Suite work

Suite currently has five broad role presets. Automatic maps classes to a starter, without talent/spec detection. Paladin, Shaman and Druid fall back to Balanced. Its 13 editable stat keys omit hit, crit, haste, expertise, avoidance/block and school-specific damage. Custom profiles cannot currently repair those omissions. Effects and set bonuses are explicitly unmodeled. Existing comparison logic already accounts for paired accessories, legal hand configurations and actual item-link stats; preserve those safeguards.

The largest immediate improvement would be broader validated stat support plus explicit spec profiles and manual selection. Consider optional talent-based selection only after checking the matching client APIs. Retain disclosed, editable weights and distinguish raw ratings from percentages. Then add separately validated effect data and actual equipped-set breakpoint comparisons, with source/version provenance. Do not blindly copy their averaged set allowance into immediate upgrade hints. Preserve current custom profiles and settings through migration.

Research supports why their spec recommendations can be more useful; it does not independently prove their weights optimal. No code/check/package/deployment/junction changes were made. Native comparisons and actual running build/Interface remain untested.
