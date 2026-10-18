# Native meter comparison — 0.2.63

Reviewed October 18, 2026 against installed executable **1.60.1.70450**, matching Blizzard source revision **172a387e3ab85b26e6640d3058d5ec1e6ccd4c63**. Actual running build/Interface and in-game comparison results are still unreported. Source evidence and hashes are in [sources.json](sources.json); native checks are in [testing.md](testing.md#native-meter-parity--0263).

| Native behavior | Suite behavior after this change |
| --- | --- |
| Ten visible metric choices | Same ten native enum choices. The built-in picker also omits standalone Absorbs. |
| Native aggregation, attribution, rankings and totals | Every returned source/spell remains scrollable in its supplied order. No Suite combat filter or reconstructed DPS. |
| Current, Overall, retained fights and shared reset | Existing native queries, retention/eviction and shared reset preserved. No combat history archived in saved preferences. |
| Personal row kept visible | Prepared top/bottom pin overlays in the same native categories; original rank and click identity retained. |
| Specialization/class icons | Spec first, class fallback; enemy damage suppresses the icon. Readable enemy faction markers with class colors. |
| Death rows and native recap | Full bars, death time, no rank, blank Overall time; native recap opens from a readable ID after combat. |
| Spell/pet/recipient breakdowns | Existing scrolling report now includes pet label priority, unit spec/class icon priority and unit-only names. |
| Minimal, Compact and Complete information | Primary, Total + rate, and Total/rate/share choices; existing Standard presentation and numeric abbreviations preserved. |
| Clock during combat | Native duration getter on a cancellable one-second timer, without full source queries or idle updates. |
| Three windows | Optional third window; original pair's snapping is preserved and the third remains independent. |
| Visibility, minimization, noninteractive windows | Per-window Always/In combat/In a group, stable header-only minimize and mouse input toggle. Shown preference supplies Hidden. |
| Source popup selection/stickiness | Left/right source clicks and Shift sticky; existing compact report, X/Escape and ordinary outside dismissal preserved. |

## Restrictions and retained choices

Blizzard's trusted code can format/divide hidden values and query with hidden IDs. Ordinary addon code cannot assume those permissions. Suite sends supported hidden amounts/names/icons/times directly to native widgets, but calculates shares only from readable finite inputs. Hidden GUID/creature-ID source queries remain blocked; click again after combat if the ID becomes readable. No name matching, index matching, text readback or other recovery is used.

Native recap loading is conservatively deferred by Suite until out of combat, with an explicit retry message and no cached ID. Native m:ss formatting can require arithmetic; opaque seconds use direct native seconds formatting. Enemy team metadata can itself be hidden, so Suite omits unreadable team markers rather than inferring a team. These are declared limits, not missing damage/healing contributions.

Suite keeps the requested original slate/teal appearance, contiguous bars, shared lock, pair docking and one compact report popup. It does not reproduce every Blizzard Edit Mode style/spacing control or independently lock a member of a snapped pair. Standard preserves the previously requested dedicated DPS/HPS single-value display; choose Total + rate for the native paired presentation. Classification stars stay absent because the matching Camelot native override suppresses them too. Spell fields overkillAmount/isAvoidable/isDeadly are not separately presented by these native rows either.

**9,927 substitute checks pass. Native equivalence is pending the side-by-side game test.**
