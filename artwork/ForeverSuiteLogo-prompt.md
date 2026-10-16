# Forever Suite GUI emblem

Revised October 6, 2026 with the built-in ImageGen tool, editing the v3 GUI emblem to center the infinity through FOREVER.

- Current master: `artwork/ForeverSuiteLogo-v4.png` (1254 x 1254).
- Previous masters: `artwork/ForeverSuiteLogo.png`, `artwork/ForeverSuiteLogo-v2.png` and `artwork/ForeverSuiteLogo-v3.png`.
- Previous prompt records: `artwork/ForeverSuiteLogo-v2-prompt.md` and `artwork/ForeverSuiteLogo-v3-prompt.md`.
- Current review preview: `artwork/ForeverSuiteLogo-preview.png` (256 x 256).
- Shipped texture: `src/WoWForeverSuite/Media/ForeverSuiteLogo.tga` (256 x 256, opaque uncompressed 32-bit TGA).
- Conversion: `scripts/build-icon.py gui`, using Pillow with Lanczos downsampling; only image dimensions and format change.
- GUI placement: a passive 56 x 56 texture in the top-left header, to the left of the Forever Suite title and subtitle.

WARCRAFT, FOREVER and SUITE remain three stacked text rows. The gold-and-teal infinity is centered on the FOREVER row, weaving through its letter counters and stems with over/under crossings. WARCRAFT and SUITE remain clear. Pale-gold Warcraft letterforms and ivory Roman serif letters retain the earlier reference styling.

No reference image or font file is bundled. The addon-list and minimap texture remains the original infinity without words.

## Generation prompt

```text
Use case: precise-object-edit
Edit target: the supplied current Forever Suite GUI emblem.
Primary request: make a new version where the sideways infinity ribbon is centered on the word FOREVER and woven primarily THROUGH FOREVER, instead of around SUITE.
Keep unchanged: the three centered stacked words, in exact order WARCRAFT / FOREVER / SUITE; the existing pale champagne-gold Warcraft fantasy lettering; the ivory Roman serif FOREVER and SUITE lettering with bronze-gold bevels; the square opaque dark slate background, margins, clear high-contrast rendering and overall polished game-logo style.
Main edit: move the complete gold-and-turquoise figure-eight upward so its horizontal and vertical center align with the center of FOREVER's capital letters. Its center crossing is at the middle of the word FOREVER, not in the gap below it. The gold left loop intertwines with F/O/R and the teal right loop intertwines with the remaining E/V/E/R. Thread portions through open counters and behind selected serif stems, with a few restrained overpasses in front. Make the loop's smooth upper and lower arcs clearly visible around the middle word so the figure-eight remains recognizable. Keep the ribbon elegant and slimmer than the letters, with obvious deliberate over-under depth. Keep important letter faces and all seven letters readable. The infinity should feel structurally integrated into FOREVER rather than merely placed behind it.
Remove the old ribbon wrapping around SUITE and remove the long tails that flow from FOREVER down around the bottom row. SUITE should now be a clean centered bottom word, primarily unobstructed. WARCRAFT should also remain clear. Allow only subtle flourish tails connected to FOREVER; the infinity's main loops must stay on the FOREVER row. Do not add a separate fourth row or an isolated infinity icon.
Composition constraints: infinity about 75-82 percent of canvas width, centered across FOREVER; its height fits that middle text row with a little breathing room above and below. Preserve an orderly three-row stack, ensuring neither adjacent word overlaps the infinity. Designed to remain readable at 56 x 56 pixels in the GUI header.
No extra words, no WORLD or OF, no medallion, no globe, no border, no runes, no watermark, no mockup. Preserve opacity. Only this GUI image is being edited; the small minimap/addon-list icons are unchanged. Exact text: WARCRAFT / FOREVER / SUITE.
```
