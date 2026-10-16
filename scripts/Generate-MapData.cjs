// Development only: compile Blizzard DB2 records exported for the installed build.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const directory = path.join(root, '.cache/map-data-70338');
function read(name) {
  const lines = fs.readFileSync(path.join(directory, name + '.csv'), 'utf8').trim().split(/\r?\n/);
  const fields = lines.shift().replace(/^\uFEFF/, '').split(',');
  return lines.map(line => Object.fromEntries(line.split(',').map((value, i) => {
    if (!/^-?\d+(?:\.\d+)?$/.test(value)) throw new Error(`Invalid ${name} numeric field`);
    return [fields[i], Number(value)];
  })));
}
const overlays = read('WorldMapOverlay');
const tiles = read('WorldMapOverlayTile');
const art = new Map(read('UiMapArt').map(row => [row.ID, row]));
const layers = new Map(read('UiMapArtStyleLayer').filter(row => row.LayerIndex === 0).map(row => [row.UiMapArtStyleID, row]));
const tileGroups = new Map();
for (const tile of tiles) {
  if (tile.LayerIndex !== 0 || tile.FileDataID <= 0) throw new Error('Unexpected terrain tile layer/file');
  const group = tileGroups.get(tile.WorldMapOverlayID) || [];
  group.push(tile); tileGroups.set(tile.WorldMapOverlayID, group);
}
const groups = new Map();
const omitted = [];
for (const row of overlays.sort((a, b) => a.ID - b.ID)) {
  if (row.PlayerConditionID !== 0 || ![0, 4].includes(row.Flags)) throw new Error('Review newly conditional/flagged terrain before shipping');
  if (!tileGroups.has(row.ID)) { omitted.push({ id: row.ID, artID: row.UiMapArtID, reason: 'No terrain tile records in this build' }); continue; }
  const layer = layers.get(art.get(row.UiMapArtID)?.UiMapArtStyleID);
  if (!layer || row.TextureWidth <= 0 || row.TextureHeight <= 0) throw new Error('Missing map layer or invalid overlay');
  const columns = Math.ceil(row.TextureWidth / layer.TileWidth);
  const rows = Math.ceil(row.TextureHeight / layer.TileHeight);
  const files = Array(columns * rows).fill(null);
  for (const tile of tileGroups.get(row.ID) || []) {
    const index = tile.RowIndex * columns + tile.ColIndex;
    if (tile.ColIndex < 0 || tile.ColIndex >= columns || tile.RowIndex < 0 || tile.RowIndex >= rows || files[index] !== null)
      throw new Error(`Invalid/duplicate tile in overlay ${row.ID}`);
    files[index] = tile.FileDataID;
  }
  if (files.includes(null)) throw new Error(`Incomplete overlay ${row.ID}`);
  const group = groups.get(row.UiMapArtID) || { layer, records: [] };
  group.records.push(`        { ${row.TextureWidth}, ${row.TextureHeight}, ${row.OffsetX}, ${row.OffsetY}, { ${files.join(', ')} } },`);
  groups.set(row.UiMapArtID, group);
}
const output = ['-- Generated from Blizzard WorldMapOverlay/WorldMapOverlayTile, build 1.60.1.70338.',
  '-- Terrain geometry and file IDs only; no third-party addon data or packaged textures.',
  '-- Regenerate with node scripts/Generate-MapData.cjs. See docs/sources.json for hashes.',
  'local _, Suite = ...', 'Suite.MapRevealData = {'];
for (const [id, { layer, records }] of [...groups].sort((a, b) => a[0] - b[0])) {
  output.push(`    [${id}] = { width = ${layer.LayerWidth}, height = ${layer.LayerHeight}, tileWidth = ${layer.TileWidth}, tileHeight = ${layer.TileHeight}, overlays = {`,
    ...records, '    } },');
}
output.push('}', '');
fs.writeFileSync(path.join(root, 'src/WoWForeverSuite/MapRevealData.lua'), output.join('\n'));
const sources = ['WorldMapOverlay', 'WorldMapOverlayTile', 'UiMapArt', 'UiMapArtStyleLayer'].map(name => ({
  table: name, url: `https://wago.tools/db2/${name}/csv?build=1.60.1.70338`, cachePath: `.cache/map-data-70338/${name}.csv`,
  sha256: crypto.createHash('sha256').update(fs.readFileSync(path.join(directory, name + '.csv'))).digest('hex'),
}));
const metadata = { build: '1.60.1.70338', sources, artCount: groups.size, overlays: overlays.length - omitted.length, tiles: tiles.length, omitted,
  outputSha256: crypto.createHash('sha256').update(output.join('\n')).digest('hex') };
fs.writeFileSync(path.join(directory, 'provenance.json'), JSON.stringify(metadata, null, 2) + '\n');
console.log(`Compiled ${metadata.overlays} overlays / ${tiles.length} terrain tiles for ${groups.size} map art IDs; omitted ${omitted.length} records without tiles.`);
