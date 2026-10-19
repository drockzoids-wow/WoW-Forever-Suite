# Forever Suite

A modular addon for WoW Forever with optional quality of life tools and an original slate-and-teal control panel. Version **0.2.85** adds deliberate group-chat requests when clicking teammate-buff reminders. Your existing setup becomes Default automatically. Most features start off. See the [request test guide](docs/testing.md#clicked-group-buff-requests--0285).

## Settings and layout profiles

Open **/wfs profiles** or the **Profiles** sidebar section. Your existing choices are preserved as **Default**; you can keep using the Suite without creating or editing anything. The header shows which profile you are changing.

To save another setup, enter a new **Profile name**, choose **Current setup** or a recorded character in the source picker, and click **Save as new profile**. Copies are independent and stay inactive until you review a switch. Up to twelve profiles, including Default, are available. Character sources appear after logging into those characters with this update and use their last saved settings.

Changes normally apply to every character using the shared profile. Choose **Only this character** for personal differences; unchanged settings still inherit the shared setup. **Use shared settings** suspends private differences and keeps them available for later. Switching a profile or scope shows a review followed by **Use & reload**. Your outgoing setup saves first. Profile actions are unavailable in combat.

Profiles include Suite feature choices, appearance and supported window/meter/bar layouts. Gear weights, macros, inventory/bank records, saved searches, mail contacts, item protection rules, training and the character leveling tracker retain their own settings/data. Native Edit Mode layouts and keybindings remain in the game. Unused profiles can be renamed or deleted with confirmation; Default and profiles still assigned to a character are protected.

## Class macro recipes

Open **/wfs macros** or **Everyday → Macros**. Your class gets its own section with two recipes; the shared supply and item recipes remain available. Preview a recipe, click **Create macro**, then drag it from Blizzard's **General** macro tab onto your action bar. Nothing is created automatically just by browsing. Spell names come from the client; no name, rank or equipment editing is required.

| Class | Recipes |
| --- | --- |
| Druid | Innervate; Rebirth |
| Mage | Counterspell; Polymorph |
| Paladin | Hammer of Justice; Blessing of Freedom |
| Priest | Power Word: Shield; Dispel Magic |
| Rogue | Kick; Blind |
| Shaman | Earth Shock; Chain Heal |
| Warlock | Pet recall; Drain Life |
| Warrior | Heroic Strike & attack; Taunt |
| Hunter | Existing Misdirection and Pet care retained |

Spells must be learned and obey their usual range, resource, reagent, form/stance and target rules. Mouseover choices fall back as explained in the preview. Emergency Counterspell, Hammer of Justice and Earth Shock interrupt your current cast. Pet recall leaves the pet Passive. Existing manual edits and conflicting macro names remain protected. [Research and adaptations](docs/sources.json) and [native test cases](docs/testing.md#classic-class-macro-recipes--0280) record the limits.

## Suite workspace

Open **/wfs** for six workspaces: **Home**, **Bags & Gear**, **Combat**, **Interface**, **Everyday**, and **Profiles**. The selected workspace expands its own pages in the sidebar; Setup Guide stays available at the bottom. Search remains at the top and jumps directly to the matching control. Existing slash shortcuts still work.

The rectangular panel fits itself to your screen without manual sizing. Related settings use two columns where useful, with room for their descriptions. Home offers six shortcuts instead of duplicate switches. Character/inventory and macro panes use the wider space; gear profiles and weights use three columns. Each optional feature retains its previous setting. The scrolling behavior confirmed in 0.2.78 is retained.

## Characters and inventory

Open **/wfs inventory**, or choose **Characters → Inventory**. The default view shows all recorded items in your region; no search setup or manual editing is required. Select a character in the roster and choose **Browse inventory**, or click an item result to focus its owner. Cycle **All locations / Bags / Personal bank / Shared bank** to narrow the view. Shared contents count once.

Search by item name, type, subtype or exact item ID. **Save view** keeps the search, owner and location together; up to eight views save account-wide. Item rows show quantities and the age of their source records. Amber dates flag records at least a day old; unknown locations stay distinct from recorded empty ones. Modified item clicks use the client's normal link/dressing-room behavior.

**Open this character's bank** opens that owner's recorded slot layout when available. This view cannot move items. Refresh records by enabling the existing character/bank recording options, logging into your alts and visiting their banks. Existing records remain readable when recording is off. Ordinary scrolling moves the page; Shift+wheel changes result pages. Native bank artwork may require visiting a bank once after login.

## Gear comparisons

Open **/wfs gear** → Gear Details and enable **Possible upgrades**. Choose **Comparison profile** for Automatic, Balanced, Physical, Caster, Healer or Tank. They work without editing. New characters start with Automatic and Stats; existing characters retain their previous role and Stats/Item level preference. These choices now save per character.

Automatic supplies a class-aware leveling starter: Caster for Mage/Warlock/Priest, Physical with ranged weapon emphasis for Hunter, Physical with melee weapon emphasis for Rogue/Warrior, and Balanced for other classes. Choose a ready-made role for a different build or activity; no manual weights are required. Automatic does not infer your talents or current combat role.

Each teal **+** has a tooltip explanation: equipped and candidate scores plus the largest signed stat changes. **Details & custom weights → Tooltip: full breakdown** shows every weighted change and multiplier, with the replaced armor/accessory item. Weapons compare the complete hand set, with the disclosed 50% off-hand base-DPS factor. Known empty slots get an explicit reason instead of an invented score gain. Item level remains an independent comparison choice.

Customization is optional. Open **Details & custom weights**, then **Create custom copy**. Name it, enter weights and choose **Save & use profile**. Up to eight custom profiles save per character. Built-ins stay intact; typing changes nothing until Save. Cancel, closing settings or leaving the page discards edits. Removal needs a second confirmation click. Zero ignores a stat; positive weights assign points per stat. Values range from 0 to 1000 with up to three decimals.

Scores express the selected preferences. Unweighted stats, special effects, set bonuses, talents, weapon speed and hit penalties still need your judgment; these are not definitive best-in-slot decisions. Native appearance, real item data, persistence and combat behavior need the [gear checklist](docs/testing.md#character-upgrade-profiles-and-explained-scores--0275).

## Training Planner

Open `/wfs training` for **Class** and **Weapons**. Level-up reminders use only saved class training. Weapon visits keep their own records and actual prices; the Weapons tab also lists your faction's four reference capital-city masters, their locations, skills and base prices before discounts. Both the reference and recorded visits show only your faction. Reference stock does not imply your class can learn every skill.

After updating, visit your class trainer once to refresh the Class list. Older mixed history is kept separately and excluded from level-up reminders. Recording and automatic openings remain optional under **Bags & Gear → Professions**. See the [trainer smoke test](docs/testing.md#separate-class-and-weapon-training--0273) and [reference sources](docs/sources.json).

## Leveling tracker

Open `/wfs leveling` (or `/wfs xp`) and enable **Leveling tracker**. Its five rows show current level/XP progress, XP/hour, net gold/hour, estimated time to the next level and elapsed session time. It starts at the top left; existing moved positions are retained. Drag the unlocked **Leveling** header to move. The padlock toggles locking: clicks pass through the locked tracker while hover details remain available. Both header buttons remain clickable. The **-** button minimizes to the header; **+** expands it. Tracking continues while minimized. Position, lock and minimized state save per character.

Right-click the unlocked tracker to open its settings; Ctrl-right-click restores top left. Settings also offer lock, minimize, reset position and **Start a new session**, which resets the counters without changing layout. Hover for XP earned, net gold and XP remaining. Changes to input and layout wait until combat ends.

Rates appear after one minute and include idle time. Gold is net change, including purchases, repairs and transfers. `/reload` continues the same session, including loading time when available; a fresh login starts over and excludes offline time. Disabling ends tracking; re-enabling starts fresh. Partial totals have a `~` marker, and missing/paused/incomplete XP tracking has no time-to-level estimate. This brings over EverCore's leveling/session behavior in a focused Suite tracker. Native appearance, hover/click routing, persistence and combat behavior need the [tracker smoke test](docs/testing.md#vertical-leveling-tracker--0254).

## Training Planner

Open **Bags & Gear → Professions** and enable **Record trainer offerings**. The planner opens beside the trainer after readable data arrives; its separate auto-open toggle can be turned off. The attachment follows the trainer and uses the left side when that fits better. **/wfs training** opens the latest saved view. Available now, future training levels and Other requirements show unlearned offers, ranks, costs, group totals, your gold and savings gaps. Scroll longer groups; totals include every listed offer. Training purchases remain manual.

With recording enabled, **Show Training Planner on level up** opens **Available now** after every level, independently of trainer auto-opening. Combat delays the popup until combat ends. Newly reached saved level requirements appear as **Level met · confirm at trainer** estimates; known unmet prerequisites remain separate. Visit a trainer to populate or refresh the saved list.

Snapshots and standalone placement save per character. Saved prices and eligibility are historical, native filters can hide offerings, and unknown prices produce a known partial total. Pet training uses points and is excluded. Away from trainers, drag the header to place the planner; temporary trainer attachment preserves that position. X/Escape closes it. Native appearance and data delivery still need the focused test.

## Square minimap header

After `/reload`, the existing **Square minimap** choice uses a clear two-line location header, with tracking and the native day/night indicator on the left and calendar on the right. The new gold location-button background stays hidden even during hover/click. Native map-opening clicks, tracking, calendar, clock and day/night updates remain in control. Disabling square mode restores the original native layout. Check the [current-header smoke test](docs/testing.md#current-minimap-header-and-daynight-art--0250) for appearance, scaling and combat results.

## Target threat indicator

After `/reload`, open `/wfs unitframes` and enable **Target threat indicator**. On a living enemy NPC, a compact 60×24 percentage rectangle uses Blizzard tooltip-border art with warm trim and a translucent chat background. Its stronger translucent threat fill warms from grey through orange to red toward 100%, while the outlined percentage stays bright. It aligns with the visible left frame edge above the name strip normally, and below/outside the left edge when **Buffs on top** is selected. Native movement/scale and input stay in control. **--** means no readable percentage is available. The setting starts off independently; initial setup and layout changes wait through combat. Check the [threat alignment and contrast smoke test](docs/testing.md#threat-alignment-and-contrast--0258) for native appearance, clearance and combat results.

## Combined bag order

After `/reload`, open `/wfs bags` and enable **Bag Order → Reverse combined bag order**. Your equipped bags read from the opposite end, with the backpack at the bottom: for the requested setup, **ammo → red → blue → backpack**. Each bag's normal slot order and item locations stay the same. It starts off, saves independently, and turning it off restores native order. Layout changes wait until combat ends. Check the [combined bag order smoke test](docs/testing.md#reverse-combined-bag-order--0245) for native appearance, item input and taint.

Enable **Bag Order → Reverse slots within each bag** to display each bag's first slot at its bottom-right end while keeping items in the same physical bag/slot. With **Reverse combined bag order** also on, the backpack's first slot is the combined window's bottom-right cell. This gives the requested Hearthstone position when native cleanup places it in that first backpack slot. Native sorting and exclusions retain ownership.

Version 0.2.47 replaces the old native sort-direction choice with this display option, carries its checked state forward and restores the captured native cleanup preference outside combat. Click cleanup once afterward to return items moved by the old setting to their normal bag allocation. Fresh defaults stay off. Display changes wait through combat. Check the [within-bag slot smoke test](docs/testing.md#reverse-slots-inside-each-bag--0247) for native confirmation.

Version **0.2.49** corrects the combined window reverting to normal slot order in combat. Prepared order now remains through native redraws when the container and its slots explicitly allow anchoring; protected or unknown layouts still wait. Your existing choices are retained. `/reload` and repeat the [combat bag-order test](docs/testing.md#preserve-combined-bag-order-during-combat--0249), checking that the Hearthstone stays at the same corner.

## Auto-open bag containers

Enable **Bags & Gear → Bags & Bank → Container Opening → Auto-open bag containers**. It starts off. With at least one free regular bag slot, the Suite opens native lootable containers one at a time. Version 0.2.55 also recognizes the native **Right Click to Open** tooltip prompt, covering clams when the bag's loot flag is false. Detection uses the client's localized prompt and waits for native tooltip data when needed. Specialty/reagent and bank space do not count. Your normal Auto Loot/Quick loot choices and native confirmations remain in control; one free slot does not guarantee every reward fits.

Opening pauses in combat, while casting/holding an item, and at vendors, banks, mail, trade and similar interaction windows. An unchanged failed/unopenable stack is not repeatedly retried; manually open it or toggle the option for another pass. Native clam opening still needs the [clam smoke test](docs/testing.md#clam-opening-detection--0255); the [general container test](docs/testing.md#automatic-bag-container-opening--0237) covers loot settings, permissions and overflow.

If opening still does nothing, run `/wfs containerstatus 5523` for Small Barnacled Clam (or replace the number with another item ID). It reports enabled/active state, the current pause reason, regular bag space, the item's loot/prompt/identity checks and the last request outcome. It does not use an item or retry an unchanged attempt. The user's report now confirms the clam is eligible with four free regular slots; a hidden BankPanel was falsely stopping all opening. Version 0.2.57 checks that child panel's effective visibility while retaining the open-bank guard. The [bank/chat retest](docs/testing.md#hidden-bank-panel-and-native-chat-copy--0257) tracks corrected native opening.

## Profession, castbar and reputation tools

**Bags & Gear → Professions:** enable modifier-click Disenchant and choose Alt, Ctrl or Shift. Hold only that modifier and left-click eligible carried equipment to cast learned Disenchant. **This destroys the item.** A teal outline identifies the prepared action; native skill and item restrictions still apply.

**Combat & Bars → Castbars:** select Player, Target or Focus, enable its custom size and adjust width/height. Valid typed sizes apply immediately; Enter or leaving the field also commits. Preview the idle native bar outside combat; target/focus must be visible. Native positions stay in place. Restore native size disables that bar's override. Layout and preview cleanup wait during combat.

**Everyday Tools → Quests & Loot:** enable Zone reputation tracking for mapped home-city regions and the four neutral goblin towns. Unmapped areas/instances preserve your watch; a manual selection is respected until the next zone change. Each feature starts off independently and is searchable. Follow the [in-game checklist](docs/testing.md#modifier-disenchant-castbar-sizes-and-zone-reputation--0232) before treating native behavior as verified.

## Audio sync

Open `/wfs audio` or **Everyday Tools → Audio** and enable **Follow Windows audio device**. The feature selects System Default game output and refreshes it after Windows playback-device notifications, without a reload. **Sync now** requests a manual refresh. Updates pause during movies/cinematics; refreshing can briefly interrupt game sound.

Disabling stops automatic refreshes; choose a fixed output through the game's Audio settings afterward. Volume, mute, background sound, microphone and voice-chat choices remain under native control. The setting starts off independently. Test real speaker/headset switching with the [audio checklist](docs/testing.md#follow-windows-audio-device--0231) before calling native routing verified.

## Nearby quest items

Enable **Nearby quest-item button** under **Everyday Tools → Quests & Loot**; it starts off. A compact item icon appears when you carry a native quest-log special item and the game reports its nearby objective or quest area. Hover for the quest, count and normal item tooltip; left-click uses it with native targeting and cooldowns. Left-drag saves placement, and Ctrl-right-click resets it. **Use nearby quest item** is available under Forever Suite in native Keybindings.

The button hides during combat/death and rechecks the item before clicks. Items without native special-item/location data may not appear. See the [quest-item checklist](docs/testing.md#compact-nearby-quest-item-button--0226) for native use, placement and taint tests.

## Class macros

Open `/wfs macros`. Hunters additionally see **Hunter · Misdirection** and **Hunter · Pet care** (scroll the grouped recipe list when needed); other classes see their existing recipes. The list scrolls independently of the detail panel, with General and class headings; click a category heading to collapse/expand it without changing the selected details. Categories start expanded after reload and remember their state while logged in. Adding a custom item opens Item Macros and reveals it. Misdirection uses a friendly focus, friendly target, then pet. Pet care revives a dead pet (Shift with no pet), mends in combat and feeds a living pet outside combat. Summon your pet and choose food before creating it; the picker shows only carried items the game confirms your active pet can eat, including acceptable ingredients. No pet or unavailable food data gets an explanation, and switching pets refreshes suitability feedback. Depleted food stays selected and the panel reminds you to restock or change it. There is no automatic replacement or popup on a macro press.

Preview, then click Create/Update outside combat and drag the macro from Blizzard's General macros to an action bar. Recipes require their spells to be learned; missing spell information prevents creation. General macros are shared, while recipes and pet-food choices are kept per character. Automatic updates remain off by default. See the [class macro checklist](docs/testing.md#class-macro-starters--0222) for native targeting/feeding checks.

## Finding settings

Version **0.2.19** adds **Overview → Characters**. Open `/wfs characters` or `/wfs dashboard` to browse recorded names, rulesets, levels, gold, profession ranks and inventory snapshot dates. Enable **Record character dashboard** to update each character as you play it; it starts off and preserves saved records when disabled. Log into alts and visit their banks to refresh them. Search names/context/professions, cycle sorting and page through longer rosters. Click a character to see its professions with aligned ranks beneath the roster. Gold totals cover known character balances in your region, with coverage shown; offline information can be stale. Hover for complete text and each field's recording date. See the [dashboard checklist](docs/testing.md#recorded-character-dashboard--0219) for native verification.

Choose **Maps & Layout**, **Bags & Gear**, **Combat & Bars**, **Everyday Tools**, **Mail & Chat** or **Macros**; related pages appear as tabs above the controls. Overview and Setup Guide stay directly accessible. Categories remember their last visited tab during the session. Long pages scroll inside the panel, keeping the title, navigation and footer visible.

Click a section heading such as **Launcher & Addon Buttons** or **Map Appearance** to collapse or expand its settings. A plus means collapsed; a minus means expanded. Choices stay independent and are remembered while logged in, including after closing settings. Reload starts expanded. Collapsing a section keeps its feature settings intact. Search reopens a hidden setting's section before highlighting it.

Type in **Search settings** to find toggles and detailed controls such as fonts, meter size, opacity and macro updates. Use multiple words to narrow matches. Click a result or press Enter to open its page and highlight the control; search never presses its switch or action for you. Arrows or the mouse wheel page through broader results. Escape clears the query, and closing settings clears results and highlights. Setup drafts keep their existing discard-on-navigation behavior.

Window movement/reset lives in **Maps & Layout → Windows**. Bag sorting, cross-character search, tooltip inventory counts and saved bank tools live in **Bags & Gear → Bags & Bank**; `/wfs bags` opens that page directly. The existing feature slash commands still open their corresponding tab.

## Player buff borders

After `/reload`, open `/wfs bars` → **Other Bars** and enable **Player buff borders**. Your main top-right buff icons fill fine teal outlines with the same inset-bevel crop as Suite action-bar buttons. Disabling restores their original crop. Debuffs, weapon enchants and player/target-frame auras retain their native appearance. The feature starts independently off; native timers, counts, tooltips, right-click cancellation and Edit Mode layout stay intact. Follow the [buff border smoke test](docs/testing.md#player-hud-buff-borders--0214) before marking in-game appearance or taint verified.

## Low bag space alert

After `/reload`, open `/wfs bags` → **Low Bag Space** and enable **Low bag space alert**. It starts off. At two free regular bag slots or fewer, a **48 × 48** icon button offers the gray or white stack with the lowest total vendor value. Its default position is the screen center. Left-drag anywhere on it to move; completed placement is remembered across reloads and characters. Hover for item details, stack count/value, free slots and click/drag instructions; no text appears on the button. It skips quest items, locked stacks, items with no vendor sale value and blacklisted item types. Specialty/reagent slots and banks are excluded. Vendor value does not measure auction or personal value.

Left-click to open the game's deletion confirmation for that stack; cancel keeps it. Right-click to blacklist that item type across every character and offer the next eligible stack. **Clear trash blacklist** restores suggestions for those types. Existing cursor-held items and other dialogs stay under your control. The alert pauses during combat and updates when bags change; it never discards automatically. Native confirmation permissions, rendering and persistence still need the [in-game smoke test](docs/testing.md#low-bag-space-discard-suggestion--0210).

## Cross-character inventory search

After `/reload`, open `/wfs bags` and enable **Search across characters**. It remains independently default off.

Search by item name, native item type/subtype or exact numeric item ID. Results appear beside the owning bag or bank: a right-side window puts them on its left, and a left-side window puts them on its right. Active saved Window tools placement determines the side; otherwise the actual screen position does. The compact popup shows small item icons, names and owners, with four rows per page and no fixed heading or informational footer. Full owner context, separate bag/bank quantities and capture dates are on hover; shared-bank contents have one owner row. Empty results use a short No matches strip. Page arrows or the mouse wheel reveal additional results, and partial pages shrink to fit. The game's existing search continues filtering its own slots. Clearing text, Enter, Escape, the popup's X, an outside click, closing the source window or combat dismisses results without adding item transactions. Modified item-link clicks retain native chat-link/dress-up behavior.

Search records inventory independently of **Item inventory** tooltip counts. Log into each alt with search enabled and visit its bank to update records. Unknown locations stay omitted, offsite records can be stale, and counts combine variants of the same item ID. The Suite's saved-bank search gets the same dropdown. Third-party bag replacements and guild-bank recording are outside this first implementation.

The addon has its own slate and teal GUI, sidebar navigation and compact controls. The inventory tooltip presentation is adapted from the user's MIT-licensed ZoidsTools at their request; its license notice ships with the addon. Enhance QoL supplies feature inspiration only.

The addon list and minimap settings button share an original gold-and-teal infinity icon. The minimap button now masks it into a circle and adds Blizzard's gold ring; `/reload` loads this presentation change. The PNG master and generation prompt are in `artwork/`; only the compact TGA ships with the addon. Check the [circular launcher smoke test](docs/testing.md#circular-suite-minimap-launcher--0164) for native fit and input.

Version 0.1.28 centers the GUI emblem's gold-and-teal infinity through FOREVER, with WARCRAFT above and SUITE clear below. It remains in the top-left header beside the Forever Suite title and subtitle. The small icons keep just the infinity mark. The separate GUI artwork fits the existing header without changing navigation or controls.

## Setup guide

On the first login after this update, Suite offers **Everyday → Bars & HUD → Map & windows → Items & social → Review**. Your current settings are the starting point. Choose individual options or use each page's suggested choices; nothing changes until **Apply setup** on Review. **Use current choices** undoes that page's draft edits. **Later**, X, Escape, navigating to ordinary settings or reloading discards the draft and dismisses the one-time welcome.

Open **Setup guide** in the sidebar or type `/wfs setup` to run it again. It covers Auto Loot, Quick loot, vendor/quest tools, bars, minimap, supported window movement, gear information, inventory/banks, mail, chat and camping. Native Auto Loot is changed only when you explicitly apply its choice; later logins do not enforce it. Arrange your HUD and minimap through Edit Mode. Drag empty window headers outside combat, Ctrl+scroll to resize, and Ctrl+right-click to reset. More detailed controls remain in their individual pages.

The guide uses original Suite code, wording and presentation. ElvUI 15.26 was reviewed only as an installation-flow reference. Native rendering, game permissions, combat behavior and persistence still need the [in-game checklist](docs/testing.md#first-login-setup-guide--0198).

## Missing buffs

After /reload, open **/wfs buffs** or **Combat → Missing Buffs** and enable **Missing buff bar**. It starts off. Teal icons use your learned self/group buffs or carried supplies. Persistent gold **Group** icons identify relevant missing buffs a nearby teammate may provide, with provider names on hover. **Left-click requests that buff in party, raid or instance chat**; right-click hides its family. Requests use a 30-second per-buff and 3-second global cooldown. They cannot cast another player's spell. Browsing and automatic updates never announce requests; native restrictions produce local feedback. Existing local notices remain throttled; missing weapon supplies still have no fake action icon. Unknown data never proves a buff is missing.

Intellect and Mana recovery recognize all seven Forever Mana classes, including **Hunters** and shifted **Druids**. Physical choices use broad class-appropriate targets, and universal buffs retain broad coverage. The same model drives your outgoing targets and learned alternatives, such as Might/Wisdom; a useful existing alternative satisfies its family. Defaults do not claim a spec-optimal or multi-Paladin assignment. Divine Spirit/Fear Ward reflect Forever's baseline class notes; unseen teammate talents are not inferred. Class/level means a teammate may provide the buff, not that the addon has read their spellbook.

**Manage buff reminders** opens a searchable, paged **Buff list** with All/Hidden/My class views. Restore or hide one family and choose learned alternatives. **Custom learned buff spells** opens a name/icon picker: select a learned spell, choose Self or Party/raid, and keep up to eight custom families without editing IDs or ranks. Built-ins link to their existing controls; higher ranks do not become duplicate custom entries. Existing custom records and hidden choices remain saved.

**Buff bar appearance** controls bar scale, icon size, movement lock, rested-area behavior and class-aware targeting. Defaults are 100% scale, 34-unit icons, unlocked movement and class-aware targets on. Enabled reminders now appear in rested areas by default; pause them there if preferred. The bar starts top-center near breath/fatigue bars, preserves saved positions, wraps after eight icons and shrinks again. Preview and settings resets remain available. Display/reminder preferences work with named/shared/personal settings profiles.

The ordinary secure bar hides while dead or in combat. Optional **Combat buff reminders** retain a separate passive panel for prepared permitted effects/coatings, without hidden-data recovery or incoming-combat guarantees. **Warn before buffs expire** uses 15 seconds for short spells and selectable 30/60/120 seconds for long spells/coatings; unknown timing and permanent/equivalent coverage do not imply expiry. Self/group actions retain native casting, range, targeting, reagent and click-time checks; active toggles cannot be clicked off accidentally.

**Weapon coating reminders** still reuse Macros' main/off-hand choices. Selected carried supplies get deliberate item actions; carried alternatives open that hand's selection. No macro creation is required and no item is applied automatically. Rogue poison choices stay deliberate. Known weapon spells suppress redundant missing-item notices; unavailable supplies use local chat. Native item restrictions and replacement confirmations remain.

See the [native smoke test](docs/testing.md#class-aware-buff-reminders-and-controls--0284) before treating class coverage, rendering, casting, persistence or taint as verified.

## First version

| Area | Included |
| --- | --- |
| Setup guide | Five pages of staged choices, current/suggested options, a final review and one-time account welcome; `/wfs setup` reruns it |
| Missing buffs | Usable spells/items plus persistent teammate-buff icons, class-aware targets, searchable controls and optional custom reminders |
| Minimap | Square mask and border; optional FPS, home/world latency, coordinates and local clock strip; addon-button drawer |
| World map | Reveal unexplored terrain over a translucent slate cover with a 0–100% terrain opacity slider; prepared maps refresh in combat |
| Windows | Dragging from empty native header space, including bags and Calendar; saved positions, proportional resizing, Ctrl-right-click reset and reset all |
| Bag sorting | Optional native cleanup once per carried-bag opening, independently of window movement; respects bag exclusions |
| Bank snapshots | Saved character/account bank pages with native Forever framing, slots and side tabs; searchable items, native link tooltips, equipment comparisons, chat links and dress-up clicks |
| Items | Quality-colored equipment and weapon icon levels, tooltip levels, an optional character-frame equipped average, and possible armor/weapon upgrades with a Stats / Item level preference |
| Players | Class color tooltip names and equipped item levels when inspect data is available |
| Unit frames | Class colored player, target, target of target and focus health fills, replacing the native colored pixels and tint |
| Inventory tooltips | Bag/bank quantities by recorded character, a combined total and shared account-bank contents counted once |
| Cross-character search | Original results popup beside native bags/banks and the saved bank, with owners, bag/bank counts, paging and snapshot dates |
| Macros | Fixed recovery, self-bandage and weapon-coating recipes; chosen-item variants, preview and optional automatic updates |
| Camping | Nearby-camp bar with carried objects, counts, cooldowns and a remembered resting pose |
| Damage meters | Up to three slate/teal windows with metric/fight menus, clickable player breakdowns, quick reset, independent appearance and snapping with shared-edge sizing |
| Action bars | Optional square slate-and-teal skin with native controls and Edit Mode layout; independently optional full-icon red range feedback |
| Vendor | Independent automatic repair with personal/guild funding, paced gray-item selling with Buyback, or confirmed native instant junk selling |
| Quests | Pickup after quest data loads, ready turn-in with zero/one reward choice and single-option gossip; Shift bypass and manual confirmations |
| Quick loot | Immediate auto-loot pass respecting the game's Auto Loot setting/modifier; native rolls and bind confirmations |
| Audio | Optional following of the Windows default playback device, coalesced sound refreshes and Sync now; pauses during movies/cinematics |
| Mail | Searchable class-colored character/recipient list beside Send Mail, sorting/paging, saved contacts and optional successful-send recipient memory |
| Chat | Slate chat with compact colored tabs, account-wide text size/background opacity and direct rendered-text selection/copying |

Features start off, apart from the minimap settings launcher. Enable each feature in the control panel after disabling the overlapping feature in another addon. Window support covers ordinary named Blizzard panels and registered UI panels; protected HUD elements remain under Blizzard Edit Mode. Weapon and special-effect comparisons are outside the initial stat model.

Enable **Always show values** and **Addon button drawer** outside combat first. Existing unprotected progress labels now stay visible through combat, and the prepared drawer opens/closes with its usual input. Collected addons keep their own combat rules. Initial setup, protected layout changes and icon collection/restoration still wait; the [combat smoke test](docs/testing.md#combat-values-and-minimap-drawer--0190) remains pending.

After `/reload`, open `/wfs map` → **World map** and enable **Reveal unexplored areas** outside combat for initial preparation. Missing terrain appears over a dark, translucent tooltip-style cover that follows each area's textured outline. Surrounding sea, coast decoration and parchment edges retain their native artwork. Choose **Unexplored area opacity**: 0% shows just the area cover, 100% fully reveals missing terrain, and the default 60% leaves terrain faded. Explored regions retain native artwork; discoveries still require visiting the area. Prepared reveal, map navigation and opacity/toggle updates continue in combat where widgets are unprotected. New setup or restricted affected widgets wait until combat ends. Disable to remove the owned area layers. The toggle and opacity save for all characters. Corrected appearance, native rendering/controls, combat and persistence need the [map smoke test](docs/testing.md#area-only-map-cover--0193).

After `/reload`, open `/wfs actionbars` and enable **Suite action bar skin**. Square cropped icons sit on slate backgrounds with fine teal borders, brighter hover edges and subdued pressed/selected fills. Main and additional Blizzard buttons, pet/stance/possess buttons and available override/extra-action buttons share the look. The main bar's ornamental frame, end caps and dividers are hidden visually. Arrange bars through Edit Mode; native controls, cooldowns, proc glows, labels and clicks remain. Turning the skin on or off waits for combat to end, and turning it off restores the native presentation. The range-indicator option stays independent. Other bar replacements and the separate gamepad UI are outside this skin's support. Native fit/input/taint and persistence need the [skin smoke test](docs/testing.md#suite-action-bar-skin--0178).

After `/reload`, open `/wfs bags` → **Bags & bank** and enable **Sort bags on opening**. It uses native cleanup once when the first carried bag opens; bags opened together share that request. Close all bags and reopen to sort again. Sorting waits through combat while the bags remain open, and skips an opening when you hold an item on the cursor. Enabling with bags already open affects their next opening. Window movement and bank snapshots stay independent. Native sorting, exclusions, input and taint need the [bag sorting smoke test](docs/testing.md#sort-bags-on-opening--0176).

After `/reload`, open `/wfs loot` → **Quests & loot** and enable **Quick loot**. With the game's Auto Loot enabled, it collects ready loot in an immediate pass. The configured Auto Loot modifier (normally Shift) retains its native automatic/manual toggle. Bind confirmations and group rolls stay native; full bags and other server constraints still apply. Enabling Quick loot alone does not change Auto Loot. It does not close/replace the loot window or automatically accept bind prompts. Native speed, combat and persistence need the [loot smoke test](docs/testing.md#quick-loot--0175).

After `/reload`, open `/wfs quests` and enable the quest/gossip options you want. Hold Shift when talking to pause automation for that conversation. Several reward choices, gold costs, PvP confirmations, gossip prompts/codes and menus with several options remain manual. Repeatable quests run once per conversation. Native behavior, combat taint and persistence still need the [quest smoke test](docs/testing.md#quests-and-gossip--0174).

After `/reload`, open `/wfs mail` and enable **Mail contacts**. Visit a mailbox and select Send Mail to see your alts; your active character stays hidden. Clicking a contact fills To with first and last name. Switching to Inbox hides the list. Log into each alt with this setting on to record its full name and ruleset. Older recorded alts automatically fill missing surnames from native account-character autocomplete when the match is unambiguous and on the same known ruleset. Unresolved contacts show Add last name: click one, choose its full name in native autocomplete, then Save recipient. Save new full names with that button and remove contacts through their x and confirmation. Search names/rulesets and sort Name, Ruleset or Level. Unknown rulesets stay unknown; ruleset labels do not establish delivery eligibility. **Remember recipient** independently keeps the full name after a successful send during that visit; closing clears it. Both settings start off and native sending remains manual. Client visuals/input/combat still need the [mail smoke test](docs/testing.md#mail-alt-surname-backfill-and-active-character-filter--0197).

After `/reload`, open `/wfs` → **Maps & layout → Minimap** and enable **Addon button drawer**. Click the teal grid button to open collected addon buttons, including Suite settings; their original click actions and tooltips remain available. Drag the grid button around either map shape. Escape, a click outside or a left-clicked addon closes the drawer; right-click menus keep it open. Blizzard's map controls stay in place. Turning the drawer off restores collected buttons' original parents, anchors, scale and layers, while honoring their owners' hidden state. Construction and layout changes wait for combat to end, and combat entry closes the drawer. Native fit, addon compatibility and saved-angle persistence need the [drawer smoke test](docs/testing.md#minimap-addon-button-drawer--0163).

After `/reload`, open `/wfs unitframes` and enable **Class colored health bars**. Player, target, target of target and focus use softer class colors at 75% RGB intensity with a neutral opaque fill that replaces the native colored artwork and tint. NPCs and vehicles keep native appearance, and disabling restores native fills. Party/raid retain Blizzard's built-in setting. Native rendering, combat taint and persistence still need the [health bar smoke test](docs/testing.md#class-colored-health-bars--0152).

After `/reload`, open `/wfs actionbars` and enable **Full button range indicator**. The entire action icon turns red when the native range check reports your target out of range, and returns to its current normal color when range clears. Blizzard action bars and pet buttons are supported; custom replacements and flyout choices are outside the initial scope. The setting starts off, and native keybinds, clicks and cooldowns keep their behavior. Native visuals/targeting/combat still need the [range smoke test](docs/testing.md#full-button-range-indicator--0139).

After `/reload`, open `/wfs` → **Items** and enable **Character frame item level**. A gold label and white rounded equipped average appear at the top center above the character model, below zoom/rotation controls. The level/class line retains its full space. The value follows equipped gear, hides on the pet view and shows an em dash while the native result is unavailable. This toggle starts off independently of icon and tooltip levels; combat changes defer. Native rendering and average availability still need the [character-frame smoke test](docs/testing.md#character-frame-item-level--0137).

After `/reload`, open `/wfs` → **Tooltips** and enable **Item inventory**. Item tooltips gain ZoidsTools' gold Inventory heading, blue count labels with white quantities, and class icons beside class-colored character names. Realm suffixes appear only for duplicate names. Bag/bank counts share a compact row; known zero and unrecorded locations are omitted. Log into each alt with this on to record its bags, and visit each bank to record its contents. Known total includes only recorded counts when any location is unknown; counts for offline characters and closed banks are last recorded. Shared account-bank items appear once as Warband when available. This option starts off and is independent of item levels and stat hints. Native counts, visuals and persistence still need the [unrecorded-location retest](docs/testing.md#hide-unrecorded-inventory-locations--0195), [styling smoke test](docs/testing.md#zoidstools-inventory-tooltip-styling--0151) and [inventory smoke test](docs/testing.md#item-inventory-tooltip-smoke-test--0149).

Version 0.1.50 removes an incorrect region limit that stopped inventory tracking on the beta. Your enabled setting stays enabled. `/reload`, reopen your bank and hover an item again to record and display its bag/bank counts. The supplied region-110 diagnostic reproduces the old failure in the regression checks; corrected native counts still need the [retest](docs/testing.md#beta-inventory-region-retest--0150).

## Run it

Version 0.2.57 also removes Suite mouse-press/release monitoring from native chat selection after a reported protected CopyToClipboard error. Click the same paper button, select text and release; only Blizzard's native handlers perform the gesture/copy, with feedback from its result callback. Reload is required to remove old hooks. Actual clipboard copying and absence of the reported error need the [focused retest](docs/testing.md#hidden-bank-panel-and-native-chat-copy--0257).

Use `/reload` for these changes if Chat is already loaded; otherwise restart WoW, open `/wfs chat`, choose **Default text size** and **Background opacity**, and click **Use Suite chat**. Enter Blizzard Edit Mode, place chat at the bottom left and save; the selection includes the full typing box plus a tiny margin. These defaults apply account-wide, including new characters. Click the paper button below the native chat bubble, drag across text and release to copy directly; click it again for normal chat. Blizzard's scroll-to-current control stays available. **Restore Blizzard chat** returns native presentation/input placement and Edit Mode boundaries while retaining the two defaults. Native copying, appearance/clamping, layout/account persistence and taint still need the [chat smoke test](docs/testing.md#chat--0170).

The addon is already linked into `C:\Games\World of Warcraft\_classic_beta_\Interface\AddOns\WoWForeverSuite`. The junction points at this workspace, so `/reload` picks up later source edits. Only this new addon entry was added.

The addon source is `src/WoWForeverSuite`. To recreate or verify the link:

```powershell
.\scripts\Deploy.ps1
```

Restart the WoW client if the new addon does not appear, enable **Forever Suite** on character select, then enter `/wfs` in game. Existing installed addons are not overwritten by the deployment script.

| Command | Action |
| --- | --- |
| `/wfs` | Open or close the control panel |
| `/wfs resetwindows` | Reset tracked window positions and sizes |
| `/wfs bank` | Open or close the saved bank view; close the real bank when it is open |
| `/wfs status` | Report client build, basic APIs and whether saved settings were present at startup |
| `/wfs containerstatus [itemID]` | Inspect auto-open pauses, bag space and up to five item slots without using items |
| `/wfs setup` | Open the five-step setup guide, starting from current preferences |
| `/wfs windows` | Report enabled state and input regions/layers for currently open tracked windows |
| `/wfs macros` | Open the macro recipes page |
| `/wfs mail` | Open the Mail settings page |
| `/wfs macrostatus` | Report automatic refreshes and each created macro's current or paused state |
| `/wfs camping` | Open camping settings; `/wfs campfire` also works |
| `/wfs buffs` | Open missing buff settings; `/wfs missingbuffs` also works |
| `/wfs meters` | Open damage meter settings; `/wfs damage` also works |
| `/wfs actionbars` | Open the full button range indicator setting |
| `/wfs vendor` | Open automatic repair and junk-selling settings |
| `/wfs quests` | Open quest pickup, turn-in and gossip settings; `/wfs gossip` also works |
| `/wfs loot` | Open Quests & loot for the independent Quick loot setting |
| `/wfs bags` | Open Windows for the independent Sort bags on opening setting |

Enable **Window tools** once in `/wfs`. Drag empty space in a supported window's existing header to move it; there is no separate drag bar or lock mode. Native close buttons, menus and other clickable header controls keep their own space. The calendar's month title and empty side bars are draggable, while its arrows and Filters menu are excluded. Drag a bag title to move it; a normal left-click on that title opens its original menu. Portrait settings and close buttons remain directly clickable. Hold Ctrl and scroll up/down over the header to enlarge/shrink the window. There is no resize icon. Hold Ctrl and right-click the draggable header or the window's background to reset position and size. Movement and wheel resizing are available outside combat.

Version 0.1.44 corrects native bags snapping to their default location during combat. After Blizzard's bag layout pass, known unprotected bags immediately regain their saved position and scale, including a saved bag first opened during combat. The runtime protection check must be readable and false; protected or unknown bags still wait until lockdown ends. This adds no position polling, timers or combat header work. Other windows retain their combat deferral, and the launcher still ends its drag updater on combat entry. Check the [bag combat placement smoke test](docs/testing.md#bag-combat-placement--0144) for native retention, input, taint and performance.

Version 0.1.1 also fixes the item-level error on comparison tooltips such as `ShoppingTooltip1` by reading modern tooltip callback data instead of assuming every tooltip has `GetItem()`.

Version 0.1.2 puts the GUI close button above the draggable header so clicks reach the button.

Version 0.1.3 replaces the separate movement bars with transparent native header areas and excludes clickable child controls, including anonymous bag menu routers. Header areas refresh when relevant controls show, hide, move or resize.

Version 0.1.5 lets the bag title share menu clicks and movement gestures, so it no longer reserves the entire title for the menu. The user's ZoidsTools mover supplied a local reference for the parented-frame input pattern; Forever Suite retains its own implementation and GUI. The bag fix requires an in-game retest.

## Bank snapshots

Restart WoW to load the new keybinding entry. Open `/wfs` → **Windows**, enable **Bank snapshots**, and visit a bank. The addon records complete readable character and account-bank slots, including empty spaces, separate stacks and full item links. No screenshot is saved: the recorded items rebuild Forever's native bank appearance with working tooltips.

Click **Bank keybind** in that page, or open **Options → Keybindings → Forever Suite → Open bank view**, and assign your preferred key. No key is assigned automatically. Away from the bank, that key or `/wfs bank` opens/closes the last recorded view. Use the normal side tabs to browse bank pages; search dims nonmatching items. Hover for native item tooltips, hold Shift for equipment comparisons, Shift-click to link items in chat, and use the normal dress-up modifier to preview gear. Slots retain their recorded positions. The footer gives the recording time and identifies the view as saved.

The saved view cannot withdraw, deposit, move, split, use or destroy items, purchase slots or change bank settings. Visit a real bank for those actions; opening it dismisses the saved view automatically. Personal snapshots belong to the current character; the shared bank snapshot is recorded once per region. Incomplete/unavailable bank data retains the previous complete view. Recording is independent of **Item inventory** tooltips, and turning it off retains the saved data. A key press during combat waits until combat ends; pressing again cancels it. With **Window tools** enabled, the saved window follows the same header drag, Ctrl-wheel and Ctrl-right-click controls as other supported windows.

The default view follows the real bank's last visible top-left position and scale, retaining that alignment across pages. Bank movement and resizing update that saved layout while the real bank is shown; closing preserves it for later sessions. Window tools can save a separate snapshot position; Ctrl-right-click empty snapshot header/background restores the real-bank default. Account Bank pages appear only for an actual recorded shared bank and never reuse personal-bank contents.

With Window tools enabled, saved native-bank and snapshot positions are restored within their opening/layout calls. Header refresh still shares one coalesced worker, and combat defers addon movement.

Native visuals, keybinding registration/input, bank freshness, modified-click behavior, combat taint and reload/relog/restart persistence still need the [bank snapshot smoke test](docs/testing.md#bank-snapshots--0157).

## Vendor tools

After `/reload`, open `/wfs vendor` (or **Vendor** in `/wfs`). **Automatically repair** and **Automatically sell junk** start off independently. Click **Repair funding** to choose Personal gold or Guild gold. Guild mode requires permission, sufficient bank funds and sufficient repair allowance to cover the full cost; it skips unavailable guild repairs without deliberately falling back to personal gold. Personal mode can retry when junk-sale proceeds make an initially unaffordable repair possible.

Click **Junk sale mode** to choose **Slow** or **Instant**. Slow starts selected: it sends one gray-quality stack at a time, at least 0.2 seconds apart, and waits for the previous slot to change. It stops after 12 stacks per vendor visit because Buyback retains only the last 12 sales. Remaining junk stays in your bags. Sold stacks can be recovered from the native Buyback tab while retained; later sales can displace them, and Buyback is temporary. Already completed sales are not repeated when you buy items back during the same active visit.

Instant uses the same `C_MerchantFrame.SellAllJunkItems` action as Blizzard's Sell Junk button. With **Automatically sell junk** on and **Instant** selected, sales proceed automatically and Blizzard's matching junk-sale popup is accepted for you. The settings explicitly warn that these permanent sales aren't recoverable through Buyback. Only the native junk-sale callback is recognized; other confirmation dialogs retain their normal behavior. Both modes respect native bag/backpack junk exclusions. Slow mode leaves locked, missing/restricted-data, valueless, non-gray and changed queued items alone; it scans carried bags only. All actions wait until outside combat and require an open merchant.

The existing deployment junction loads these changes on `/reload`; no other addon or SavedVariables were modified. Native sales, popup acceptance, Buyback behavior, guild funding, input, taint and persistence still need the [vendor smoke test](docs/testing.md#vendor-tools--0142).

## Damage meters

Version **0.2.63** adds an optional **Window 3**, native spec icons, an offscreen personal-row pin, pet/recipient labels, death timestamps and native recap clicks after combat. Each window now offers value-detail modes, icon and self-pin toggles, Always/In combat/In a group visibility, header-only minimization and mouse pass-through. Restore mouse input through `/wfs meters`. The original snapped pair remains independent of Window 3; the shared lock includes all three. Current/Overall time advances during combat through a cancellable clock. Shift-click keeps a breakdown open; either mouse button selects a source.

The meters use every native source/spell in its supplied order. Complete values show shares only when the required totals are readable; hidden values still use supported native display paths. Restricted source IDs require another click after combat. See the [native meter comparison](docs/meter-parity.md) for the exact source review, supported additions and remaining differences. Native comparison and taint tests are pending.

Each size/appearance setting has a right-aligned editable value beside its label and a teal slider below. Drag or scroll the slider for live adjustments, or type a precise value and press Enter. Opacity uses percentages. Escape cancels an unfinished typed edit; sliders and numbers remain synchronized when switching windows or resizing from a corner.

Bar text now starts at Blizzard's 14-point size with a normal, antialiased outline. The old 11-point default upgrades once; other custom sizes are kept, and you can still choose 9–16 in settings afterward. Names and values share the native meter font family.

Names use the space left by the displayed values, with a small gap. Full numbers are now the default and apply once to existing meter preferences: **16,568 (13.5)** keeps the exact damage total and decimal DPS. Healing and breakdown rows use the same precision. You can still choose Compact in either window's settings; that choice then stays saved. Rates keep one decimal when fractional, and whole rates avoid unnecessary trailing decimals when readable.

Click **Test both windows** in `/wfs meters` to show eight sample players, even with the module disabled or either window hidden. The compact default layout fits all eight; smaller windows scroll through the rest. Try the appearance options, metric menus, movement, resizing and snapping. **Stop test**, also available from either meter's `...` menu, restores normal visibility and real fight data. Test mode ends on combat or reload; sample data is never recorded or saved. Layout and appearance edits still save normally.

`/reload`, open `/wfs meters` and enable **Damage meters**. Window 1 starts on Damage / Current and Window 2 on Healing / Current. Choose each window's appearance in its settings tab; slate panels and teal bars are the defaults, with optional class colors. The header's metric menu switches Damage, DPS, Healing, HPS and other native categories. Its session menu offers Overall and Current, which expands to Follow current fight and the client's retained battles.

The meters use Blizzard's meter font, textured bar fill, soft shaded edges and a class icon beside each recognized player's rank/name. The fill sits inside its shadows with icons aligned to the full row height. Suite teal remains the default bar color, with optional class colors. A small arrow at the far left opens the metric picker, using its own native border and hover/press feedback; its gold title is part of the draggable header. The compact session button shows **C** for Current (including a selected stored fight) or **O** for Overall; hover for its full selection. The expandable metric/fight menus scroll through longer history and close on selection, an outside click or Escape. Readable fight time appears in the header, and test mode identifies sample data with **TEST**. Drag the title or empty header space to move. Drag either lower corner to change width and height freely; Ctrl+scroll remains available. Corner sizing holds the opposite top corner in place where screen bounds permit, saves on release and cancels during combat. Sizes range from 240–1600 wide and 120–1000 high, fitting within the screen. General native window tools retain their existing Ctrl-scroll behavior.

Click either header's **padlock**, **Windows: Unlocked** in settings, or **Lock both windows** in the `...` menu to lock the pair. Both windows hide their resize corners and drag dots, and movement, corner sizing, Ctrl-scroll and the background reset gesture stop. Menus and body scrolling remain available. The lock saves across reloads. Unlock from the same controls; deliberate size/position resets in settings remain available while locked.

The small **reset arrow** beside the padlock clears Overall, Current and stored fights for all Suite windows and the built-in meters through the native shared reset. Layout, styling, chosen metrics and the lock remain saved. In test mode it restarts the sample display and preserves real fights. Hover for the reset scope; the button is unavailable if the client lacks native reset support. Layout resets remain in settings.

Damage bars show the exact grouped total followed by DPS in parentheses, such as **16,568 (13.5)**. Healing shows total healing followed by HPS, and damage-taken views pair their own totals and rates. Compact/full number settings apply to both values; Compact remains available for abbreviations such as **972.6k (38.9k)**. Dedicated DPS/HPS views keep their single `/s` value; action counts remain single numbers. A missing rate leaves only the total. These values come from the selected Current, Overall or retained native fight.

Click any player's bar to open a compact Blizzard-style spell breakdown for that window's metric and Current, Overall or selected fight. The Suite-owned popup sits beside the meter, with spell icons, native textured bars and readable 14-point text. The player name and X sit inside the popup border, without an opaque title strip. Each row pairs the supplied total and rate; DPS/HPS views put the rate first. Readable totals also show each spell's share, while restricted values omit that calculation. Recipient names share the spell label, and hovering a readable spell opens its normal tooltip. The popup follows live updates and scrolls through longer lists. Bars stay clickable while locked. Close by clicking outside the popup, with X or Escape. Changing the owning window's metric/fight, hiding it, resetting data or stopping a test dismisses its popup. Sample players include invented ability/unit details. During combat it keeps its existing position. If the client hides a source identifier, the popup retains the displayed total and asks you to click the bar again after combat; Suite does not bypass that restriction.

Drop near the other meter's edge to snap: side-by-side windows match height; stacked windows match width. A snapped pair moves together and retains its shared dimension when resized. Alt+drag or **Detach windows** separates; Ctrl+right-click resets the selected layout. Each window keeps its own metric and fight choice. Scroll the body to see more sources. Native recording supplies the data and history; Suite saves layout/preferences without archiving combat data. Native meters retain their own settings. Complete the [meter smoke test](docs/testing.md#meter-name-fit-and-numeric-precision--0146) before treating combat rendering as verified.

## Camping bar

Open **Camping** or `/wfs camping` and enable **Camping bar**. The compact slate and teal bar appears while **Campfire Nearby** is active, including when you have no camp objects. Click its pose button to rest; the arrow chooses **Sit, Kneel, Sleep or Lie down** and remembers your preference. Choosing a pose alone does not perform it. Blizzard's [beta notes](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-1/2360696) confirm these resting poses qualify for camp buffs.

Finished objects in your carried bags are discovered from their item-use action and English nearby-campfire requirement text, including Lodestone and newly added objects. Recipes, ingredients and unrelated consumables are excluded. Duplicate stacks share one button with a combined count; additional objects wrap to another row. Native tooltips, placement rules, profession requirements and shared cooldowns apply. The bar does not place anything automatically or create General macros. Object discovery currently requires English tooltips.

Drag the bar's small header to move it. **Preview position** shows an inactive outline away from camp; closing settings or entering combat ends it. Ctrl-right-click the header or use **Reset bar position** to restore the default. Visibility starts off; pose and position are saved account-wide, like the other Suite options. The bar and pose chooser hide through a native secure driver during combat, with inventory and protected changes deferred. Native execution, visuals and taint still need the [camping smoke test](docs/testing.md#camping-smoke-test-0123).

## Development reference

- [Forever development reference](docs/forever-development.md) covers APIs, lifecycle, secure code, persistence, performance and packaging.
- [Feature plan](docs/feature-plan.md) records the requested scope, design decisions and remaining work.
- [In-game testing](docs/testing.md) provides the first test sequence and the verification log.
- [Source provenance](docs/sources.json) records the matching UI revision and the older community API export.
- `AGENTS.md` carries the project rules into future work.

The complete matching Lua, XML and TOC UI source is cached in `.cache/wow-ui-source`. It is a development reference and is excluded from the addon package.

## Checks and packaging

For GitHub Desktop setup, encrypted CurseForge credentials and automatic version-tag releases, see [Publishing](docs/publishing.md). Ordinary pushes run checks; version tags publish to CurseForge project **1749120** using the Forever game flavor.

```powershell
# Only needed when the local test dependency cache is missing:
.\scripts\Bootstrap-Checks.ps1

node scripts/check-addon.cjs
.\scripts\Package.ps1
```

The current checks pass Lua 5.1 syntax, TOC integrity and behavior using substitute APIs. Native rendering, combat taint and client persistence require the in-game checks; they are not yet verified.

Version 0.1.24 fixes missing icon levels on native bag and equipment buttons. Numbers use item-quality colors in the top-right corner, without Retail upgrade-path letters. Live slot data takes priority over inherited empty or stale item links, and native bag/bank updates refresh their buttons. Use `/reload` to load the change, enable **Item levels on icons**, then check gear in combined/individual bags and equipped slots. Food and reagents remain unlabeled. Native rendering and combat behavior need an in-game retest.

Version 0.1.6 adds a compact slate minimap header with a teal rule, a centered gold area name, a smaller centered subzone label, and native tracking/calendar/clock controls. Its single-line stats sit below Blizzard's coordinate frame. Suite coordinates and time are fallbacks when the corresponding native display is disabled or hidden. Turning square mode off restores native header layouts. The visual design needs an in-game retest.

Version 0.1.7 refines the minimap with translucent header/stats backgrounds and thin teal borders. Area and subzone names stay centered and fit or wrap in full. The native clock moves just inside the map at bottom center with a larger outlined font. Turning square mode off restores its original position and font. Visual fit still needs an in-game retest.

Version 0.1.8 anchors the header to both outer minimap border corners, so its edges track the full bordered width when the map changes size or scale.

Version 0.1.9 releases minimap screen clamping while square mode is enabled. Use Blizzard Edit Mode to move it closer to the screen edges and save the layout. Disabling square mode restores the original clamp flags.

Version 0.1.10 adds practical Overview helpers and small delayed hover hints on draggable window headers. Move, Ctrl+scroll resize and Ctrl+right-click reset are explained where the tools are enabled. Bag hints also explain title menu clicks; hints disappear when interacting and never intercept input.

Version 0.1.11 adds an FS minimap button. Click to open settings; drag around the edge of square or circular maps. Position saves automatically. Hide/show it in Minimap settings; /wfs remains available. The launcher starts enabled and works independently of minimap styling and stats.

Version 0.1.12 uses the standard Blizzard tooltip for window-header instructions, appearing immediately on hover. The custom hint panel and half-second delay are removed.

Version 0.1.13 restricts tooltip item levels to equipment and weapons. Consumables, materials, quest items, bags and other non-gear no longer receive a Suite item-level line.

The October 6 correction applies that same equipment-only rule to icon levels in every supported window, including profession results and reagents. Food and raw-fish ingredients receive no level labels; recycled buttons clear old labels when their items change. Reload to pick up the fix.

Version 0.1.14 shows equipment tooltip levels as a gold Item Level N line directly below the name, matching the requested Retail appearance. Comparison tooltips use the same layout.

Version 0.1.15 insets the FS launcher so its outer edge aligns with the square minimap's teal border, one UI unit outside the map. Round placement moves inward by the same amount. Dragging uses the adjusted track and preserves the saved angle.

Version 0.1.16 gives player tooltips a gold Item Level label on the left and a white whole-number value on the right, matching the requested Retail example.

Version 0.1.17 corrects the launcher placement: the FS button sits outside the minimap with its inner edge against the square map's teal border. Round placement also keeps the full button outside the map. Dragging retains the saved angle.

Version 0.1.18 starts inspection directly from mouseover without targeting or clicking. Fresh hovers queue through the inspect cooldown and retry delayed responses while visible. Cached players display immediately; fresh equipment still depends on inspect range and the server response.

Version 0.1.19 adds simpler macro generation inspired by the user's EverCore macros. Open **Macros** or `/wfs macros`, choose Food / Health, Drink / Mana, Bandage or a weapon hand, inspect the preview and click **Create macro**. Food and drink prefer conjured supplies. Bandages target yourself; coatings choose ordinary sharpening/weightstones matching the equipped weapon. Choose a carried item to override automatic selection with food, drink, oils or poisons. **Add item macro** creates separate chosen-item variants for other buffs or use items, with native targeting. Names and routine conditions are supplied automatically.

Food and Drink have one optional combat checkbox each, initially off. Food attempts a Healthstone and healing potion in combat; Drink attempts a mana potion. Both health items can be used on one press if native rules permit. Creating a macro never uses an item: drag it from the **General** tab in Blizzard's Macros window onto an action bar to use it.

Create a Suite macro once: when it already exists in **General**, other characters recognize it automatically, including chosen-item macros. **Keep created macros current** starts off and is shared across characters. Enable it once to refresh recognized recipes for the current character's supplies or weapons, outside combat. Existing character choices are retained; newly recognized item macros inherit their shared item. General names are shared, so the last character to update a name determines its text. Existing EverCore macros are untouched. External text edits pause further updates; the native macro editor also pauses writes while open. Removing an item choice keeps its game macro and remembers that removal on this character. Automatic recovery classification supports English; choose explicit food/drink on other locales. Native execution, targeting and visual fit still require the macro smoke tests in `docs/testing.md`.

Version 0.1.20 fixes the Lua error when opening Macros: the preview EditBox now receives the required font-flags argument. Reload before reopening the page to clear the partially built panel from 0.1.19.

Version 0.1.21 lets automatic main/off-hand recipes **Create placeholder** with an empty hand or no suitable carried coating. The placeholder has no use action. With **Keep created macros current** on, the same macro fills in once a relevant weapon and coating are available, and clears its action when they are absent. Close Blizzard's Macros window before creating/updating through Suite; this protects unsaved editor text. The user confirmed closing that window resolves main-hand creation.

