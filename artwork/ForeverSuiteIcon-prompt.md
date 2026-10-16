# Forever Suite shared icon

Created October 6, 2026 with the built-in ImageGen tool. Original artwork; no third-party addon art was used.

- Master: `artwork/ForeverSuiteIcon.png` (1254 x 1254, as returned by ImageGen).
- Review preview: `artwork/ForeverSuiteIcon-preview.png` (256 x 256).
- Shipped texture: `src/WoWForeverSuite/Media/ForeverSuiteIcon.tga` (128 x 128, opaque uncompressed 32-bit TGA).
- Conversion: `scripts/build-icon.py`, using Pillow with Lanczos downsampling; no creative edits after generation.

Both TOCs use the shipped texture through `IconTexture`; MinimapButton.lua uses that same texture. Version 0.1.64 responds to the user's October 9 request by replacing the runtime teal square border with Blizzard's portrait circle mask and gold minimap tracking ring. The original master and shipped TGA remain unchanged; the circular composition is native UI code. Master art and development tools remain outside the addon package.

## Generation prompt

```text
Use case: logo-brand
Asset type: original square bitmap icon for the Forever Suite World of Warcraft addon, shared by the addon list at 20x20 pixels and a minimap launcher at 26x26 pixels.
Primary request: a polished, memorable fantasy game UI emblem representing forever: one large, bold horizontal infinity loop made from two interwoven broad metal ribbons. The left ribbon is warm luminous antique gold; the right ribbon is luminous turquoise teal. Clear over-under crossing at the center. Each loop has a generously open dark center so the silhouette reads instantly at tiny size.
Scene/backdrop: full-bleed opaque very dark slate square, nearly black, subtle vignette and restrained shadow behind the emblem.
Style/medium: crisp premium hand-painted game inventory icon, restrained beveled metallic highlights, simple sculpted surfaces, a small amount of depth. Keep the graphic exceptionally clean and legible, not photorealistic. Original artwork.
Composition/framing: centered and symmetrical, infinity loop occupies roughly 82 percent of canvas width and 56 percent of canvas height; safe dark margin on every side. Square 1024x1024 image, straight-on view. Strong readable silhouette and high contrast. The emblem is the entire subject.
Color palette: dark slate #09131b, seafoam teal #69d6bf and warm gold #e6b866. Restrained highlights.
Text: none.
Constraints: single production icon, full-bleed square, no presentation sheet, no label, no watermark, no letters, no outer frame or border, no gears, no extra symbols, no sparks, no runes, no filigree, no busy background, no borrowed addon logos or visual identity. The infinity loop should remain easy to recognize after reduction to 20 pixels.
```
