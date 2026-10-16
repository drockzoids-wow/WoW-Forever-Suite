# Forever Suite GUI emblem

Revised October 6, 2026 with the built-in ImageGen tool, using the previous GUI emblem and the user's supplied Warcraft Forever logo screenshot as edit/style inputs.

- Current master: `artwork/ForeverSuiteLogo-v3.png` (1254 x 1254).
- Previous masters: `artwork/ForeverSuiteLogo.png` and `artwork/ForeverSuiteLogo-v2.png`.
- Previous prompt record: `artwork/ForeverSuiteLogo-v2-prompt.md`.
- Current review preview: `artwork/ForeverSuiteLogo-preview.png` (256 x 256).
- Shipped texture: `src/WoWForeverSuite/Media/ForeverSuiteLogo.tga` (256 x 256, opaque uncompressed 32-bit TGA).
- Conversion: `scripts/build-icon.py gui`, using Pillow with Lanczos downsampling; only image dimensions and format change.
- GUI placement: a passive 56 x 56 texture in the top-left header, to the left of the Forever Suite title and subtitle.

WARCRAFT, FOREVER and SUITE form three stacked text rows. A slimmer gold-and-teal infinity weaves around and through the SUITE letters and flows from FOREVER's letter tails. It occupies the lettering composition rather than a separate row. Pale-gold Warcraft letterforms and ivory Roman serif letters follow the user's supplied reference.

The user's screenshot is cached for development at `.cache/artwork-references/WoW-Forever-user-reference.png`. No reference image or font file is bundled. The addon-list and minimap texture remains the original infinity without words.

## Generation prompt

```text
Use case: precise-object-edit
Asset type: polished GUI branding bitmap for the Forever Suite addon.
Input images: Image 1 is the EDIT TARGET, the current Forever Suite GUI artwork. Image 2 is the USER'S STYLE REFERENCE showing the actual Warcraft Forever logo, especially its elegant FOREVER lettering and the infinity flourish that grows out of the letters.
Primary request: redesign Image 1 into exactly THREE tightly arranged centered text rows, with a gold-and-teal infinity ribbon cleverly interwoven THROUGH the lettering. Top row WARCRAFT, middle row FOREVER, bottom row SUITE. All three words are stacked directly above one another. The infinity is part of the lettering composition, not a separate fourth row or an isolated icon between words. Spell each word exactly, once, in uppercase.
Lettering: retain the close match to the user's actual game-logo reference. WARCRAFT has recognizable Warcraft fantasy wedge-serif capitals, smooth pale champagne-gold/ivory planar faces with restrained bronze bevel shadows. FOREVER and SUITE use the reference's broad elegant classical Roman serif shapes, smooth round O and curved R, ivory faces, thin bronze-gold edging and modest depth. Avoid hammered yellow-gold texture. Keep all three words easy to read.
Infinity integration: turn the flourish of FOREVER's final R into a graceful continuous sideways figure-eight ribbon that flows down through the spaces between FOREVER and SUITE and intertwines with the bottom letters. Preserve the Suite identity of interwoven warm gold on the left and turquoise teal on the right. Use deliberate over-and-under crossings: parts pass behind the serif stems and other small sections pass in front or through open letter counters, producing a believable intertwined emblem. The two complete infinity loops must remain recognizable. Use an elegant, slimmer sculpted ribbon rather than the previous huge standalone loop. Let the gold left loop curl around the left side of SUITE and the turquoise right loop curl around the right side, with a crisp central crossing threading through the lower lettering. Maintain generous open areas and legible letter faces. No ribbon over the important faces of whole words. The flourish should be stylish and integrated like the reference, with color providing an original Suite twist.
Composition: compact square full-bleed opaque dark slate background consistent with Image 1. WARCRAFT about 86 percent of the canvas width; FOREVER about 90 percent; SUITE about 70-78 percent. Each word gets a large clear row, with small gaps. The integrated infinity fits within the lower half of the THREE-ROW word stack; it must not create extra vertical space. Fill the canvas efficiently with safe outer margins. Crisp high contrast, clean shapes, designed to be attractive and readable when reduced to 56 x 56 in a GUI header. Do not shrink the letters just to fit decoration.
Constraints: preserve the opaque dark slate backdrop. Generate only this GUI variant; the small addon-list/minimap infinity assets stay unchanged. No WORLD or OF, no circular medallion, no globe, no runes, no border, no shields, no gears, no extra words, no mockup, no watermark. Output one finished square production asset. Exact text and order: WARCRAFT / FOREVER / SUITE. Integrated gold-and-teal infinity woven through the lower letters.
```
