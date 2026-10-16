# Forever Suite GUI emblem

Revised October 6, 2026 with the built-in ImageGen tool. The user selected two stacked title lines above a smaller infinity and SUITE below.

- Current master: `artwork/ForeverSuiteLogo-v2.png` (1254 x 1254).
- Previous master: `artwork/ForeverSuiteLogo.png`.
- Current review preview: `artwork/ForeverSuiteLogo-preview.png` (256 x 256).
- Shipped texture: `src/WoWForeverSuite/Media/ForeverSuiteLogo.tga` (256 x 256, opaque uncompressed 32-bit TGA).
- Conversion: `scripts/build-icon.py gui`, using Pillow with Lanczos downsampling; only image dimensions and format change.
- GUI placement: a passive 56 x 56 texture in the top-left header, to the left of the Forever Suite title and subtitle.

The top-to-bottom order is WARCRAFT, FOREVER, gold-and-teal infinity, SUITE. The infinity occupies roughly 60 percent of the canvas width. WARCRAFT uses pale champagne-gold fantasy lettering; FOREVER and SUITE use ivory classical serif lettering with bronze-gold bevels.

Blizzard's [official announcement](https://news.blizzard.com/en-us/article/24301453/everything-announced-at-blizzcon-2026-opening-ceremony) supplies the typography reference: [WoW Forever logo](https://bnetcmsus-a.akamaihd.net/cms/gallery/j3/J3RLTCKOODJ51789169243964.png). The reference was read and cached at `.cache/artwork-references/WoW-Forever-official-logo.png` for this user-requested redesign. It is not shipped. The finished artwork is a separately generated Suite composition; no font file or official source image is bundled.

The addon-list and minimap texture remains the original infinity without words.

## Layout generation prompt

```text
Use case: precise-object-edit
Asset type: refined GUI-only square emblem for the Forever Suite World of Warcraft addon.
Input images: Image 1 is the EDIT TARGET, the existing Forever Suite GUI emblem with a gold-and-teal infinity. Image 2 is a TYPOGRAPHY STYLE REFERENCE ONLY, Blizzard's official World of Warcraft Forever logo. The human user explicitly wants the words to resemble Image 2 more closely.
Primary edit: reorganize Image 1 into FOUR centered horizontal rows, in this exact top-to-bottom order: WARCRAFT, FOREVER, the original gold-and-teal infinity mark, SUITE. Both WARCRAFT and FOREVER must be above the infinity. SUITE must be below the infinity. Render these three words exactly, once each, all capitals. No other text.
Typography from Image 2: WARCRAFT uses the reference's distinctive sculpted fantasy letterforms, broad wedge serifs and irregular iconic Warcraft capitals, in pale champagne gold with crisp ivory top-facing planes and restrained dark-bronze bevel shadows. FOREVER uses the reference's elegant broad classic serif capitals, with ivory faces and a thin bronze-gold beveled outline, generous open counters and refined serifs. SUITE uses matching ivory classic serif lettering with the same restrained bronze-gold edging. Make this substantially closer to the actual reference typography and cream/pale-gold coloring; keep the clean stylized illustration rather than shiny yellow hammered metal. Do not copy the official whole logo; use its lettering design as the requested visual reference.
Infinity change: retain the existing loop's two interwoven broad ribbons, original warm-gold left and turquoise teal right, over-under crossing and open dark centers. Make the infinity clearly smaller: only 58-62 percent of canvas width, roughly 22 percent of canvas height. It should act as a compact emblem between the title and SUITE, rather than dominate the entire design.
Composition: square full-bleed opaque dark slate background matching Image 1. Top WARCRAFT row roughly 86 percent of canvas width, second FOREVER row also roughly 86 percent of canvas width; SUITE roughly 64-70 percent of canvas width. Top two text rows together occupy about 43 percent of height; smaller infinity about 22 percent; SUITE about 20 percent; remaining height is clean small gaps and safe outer margin. Efficient compact layout, crisp high-contrast clean letter openings, designed to remain readable as decorative GUI artwork at 56 x 56 pixels. No collisions or overlap. Preserve the existing opaque background; no transparency.
Constraints: only revise this GUI image. Original small addon-list and minimap infinity icons are separate assets and must remain untouched. No WORLD, no OF, no circular frame, no globe, no medallion, no runes, no shields, no gears, no subtitle, no extra flourishes, no watermark, no UI screenshot, no mockup. Exact words: WARCRAFT / FOREVER / SUITE.
```

## Final lettering refinement prompt

```text
Edit target: Image 1, the new four-row Forever Suite emblem. Image 2 is the AUTHORITATIVE TYPOGRAPHY REFERENCE, the official Warcraft Forever logo.
Change only the lettering design and lettering material in Image 1 to match Image 2 much more closely. Keep all row positions, the smaller original gold-and-teal infinity, opaque dark slate background, margins, square canvas and exact word spelling unchanged.
WARCRAFT: use the actual pale champagne-gold Warcraft-style capitals visible in Image 2, with clean smooth ivory planar faces and softly shaded bronze bevels. Remove the mottled hammered yellow-gold texture. Keep its iconic fantasy letterforms.
FOREVER: REPLACE the current sharp polygonal fantasy letters with the elegant CLASSICAL ROMAN SERIF letterforms used for FOREVER in Image 2. Especially make the O a smooth round/oval Roman O, not an octagon, and use smooth curved bowls on the R. Wide refined wedge serifs, flat creamy ivory faces, thin muted bronze-gold outline and a modest dimensional bevel. This row should clearly resemble the reference FOREVER typography and be visibly different from the current WARCRAFT typography.
SUITE: use the SAME classical Roman serif family as the new FOREVER, with smooth curves, clean ivory faces and restrained thin bronze-gold bevels. Keep it centered underneath the infinity. Do not use the spiky or heavily faceted Warcraft font for FOREVER or SUITE.
Retain the exact top-to-bottom order: WARCRAFT / FOREVER / gold-and-teal infinity / SUITE. No added WORLD or OF. Do not add the reference's globe, blue background, outer ring or runes. No extra text, no border, no watermark. Preserve opacity. The subject is one finished GUI bitmap asset.
```
