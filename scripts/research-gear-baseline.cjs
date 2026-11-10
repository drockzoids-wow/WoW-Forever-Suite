// Read-only public-site research. Nothing in this script is shipped with the addon.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const cache = path.join(root, '.cache', 'gear-baseline-research');
const levels = [1, 10, 20, 40, 60];
const read = file => JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));
const write = (file, value) => fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
const hash = text => crypto.createHash('sha256').update(text).digest('hex');
const configFile = path.join(cache, 'config.json');

async function collect() {
  fs.mkdirSync(cache, { recursive: true });
  const page = await fetch('https://foreverwow.gg/tool/');
  if (!page.ok) throw new Error(`Tool page: ${page.status}`);
  const html = await page.text();
  fs.writeFileSync(path.join(cache, 'tool.html'), html);
  const match = html.match(/<script[^>]*id="cfg"[^>]*>(.*?)<\/script>/s);
  if (!match) throw new Error('Public configuration missing');
  const cfg = JSON.parse(match[1]);
  write(configFile, cfg);
  const tasks = [];
  for (const cls of cfg.classes) for (const spec of cls.specs) {
    for (const level of levels) tasks.push({ cls: cls.key, spec: spec.key, level, mode: 'full' });
    tasks.push({ cls: cls.key, spec: spec.key, level: 60, mode: 'plain' });
    tasks.push({ cls: cls.key, spec: spec.key, mode: 'page' });
  }
  const manifest = { retrievedAt: new Date().toISOString(), configSHA256: hash(match[1]), requests: [] };
  let done = 0;
  async function worker() {
    while (tasks.length) {
      const task = tasks.shift();
      const key = `${task.cls}-${task.spec}-${task.mode === 'page' ? 'page' : `${task.level}-${task.mode}`}`;
      const params = new URLSearchParams({ class: task.cls, spec: task.spec, level: String(task.level),
        known_only: '0', pvp: '0', profession: '0', locale: 'enUS' });
      if (task.mode === 'plain') { params.set('no_sets', '1'); params.set('no_on_use', '1'); }
      const url = task.mode === 'page' ? `https://foreverwow.gg/${task.cls}/${task.spec}/` : `https://foreverwow.gg/api/bis?${params}`;
      const response = await fetch(url, { signal: AbortSignal.timeout(45000) });
      if (!response.ok) throw new Error(`${url}: ${response.status}`);
      const body = await response.text();
      if (task.mode !== 'page') {
        const result = JSON.parse(body);
        if (result.error || !result.slots || !result.weights) throw new Error(`${url}: invalid result`);
      }
      fs.writeFileSync(path.join(cache, `${key}.${task.mode === 'page' ? 'html' : 'json'}`), body);
      manifest.requests.push({ ...task, url, sha256: hash(body), bytes: Buffer.byteLength(body) });
      if (++done % 29 === 0) console.log(`Collected ${done}/203 resources`);
      await new Promise(resolve => setTimeout(resolve, 180));
    }
  }
  await Promise.all([worker(), worker()]);
  manifest.requests.sort((a, b) => a.url.localeCompare(b.url));
  write(path.join(cache, 'manifest.json'), manifest);
  console.log(`Collected ${done} resources for ${cfg.classes.length} classes.`);
}

function rawScore(item, weights, slot) {
  let score = (item.armor || 0) * (weights.armor || 0);
  for (const [stat, amount] of Object.entries(item.stats)) {
    score += amount * (weights[stat] ?? (stat.startsWith('skill_') ? weights.weapon_skill : 0) ?? 0);
  }
  const dpsWeight = slot === 'Ranged' ? weights.wand_dps ?? weights.ranged_dps ?? 0
    : slot === 'Off Hand' ? weights.offhand_dps ?? (weights.melee_dps || 0) * 0.5
      : weights.melee_dps || 0;
  return score + (item.dps || 0) * dpsWeight;
}

function audit() {
  const cfg = read(configFile);
  const manifest = read(path.join(cache, 'manifest.json'));
  for (const task of manifest.requests) {
    const key = `${task.cls}-${task.spec}-${task.mode === 'page' ? 'page' : `${task.level}-${task.mode}`}`;
    const body = fs.readFileSync(path.join(cache, `${key}.${task.mode === 'page' ? 'html' : 'json'}`), 'utf8');
    if (hash(body) !== task.sha256) throw new Error(`Mixed or modified cache: ${key}`);
  }
  const profiles = [], summaries = [], failures = [], builds = new Set(), fixtures = [];
  let pureChecks = 0, pureMatches = 0, itemRows = 0;
  for (const cls of cfg.classes) for (const spec of cls.specs) {
    const id = `${cls.key}/${spec.key}`;
    const full = read(path.join(cache, `${cls.key}-${spec.key}-60-full.json`));
    const plain = read(path.join(cache, `${cls.key}-${spec.key}-60-plain.json`));
    const summary = { id, class: full.class, spec: full.spec, levels: [], pureChecks: 0, pureMatches: 0,
      scoredEffects: 0, unscoredEffects: 0, setRows: 0, weightChanges: [], examples: [] };
    for (const level of levels) {
      const data = read(path.join(cache, `${cls.key}-${spec.key}-${level}-full.json`));
      builds.add(data.build);
      if (JSON.stringify(Object.entries(data.weights).sort()) !== JSON.stringify(Object.entries(spec.weights).sort())) summary.weightChanges.push(level);
      summary.levels.push({ level, rows: Object.values(data.slots).flat().length, slots: Object.keys(data.slots).length });
      for (const [slot, items] of Object.entries(data.slots)) {
        for (const item of items) {
          itemRows++;
          if (!Number.isFinite(item.score)) failures.push({ id, level, slot, item: item.id, reason: 'nonfinite score' });
          if (item.available_level > level) failures.push({ id, level, slot, item: item.id, reason: 'future availability' });
        }
        for (let i = 1; i < items.length; i++) if (items[i].score > items[i - 1].score + 0.001) failures.push({ id, level, slot, reason: 'sort order' });
      }
    }
    for (const [slot, items] of Object.entries(plain.slots)) for (const item of items) {
      if (item.effects.length || item.set_bonus) continue;
      const expected = rawScore(item, plain.weights, slot);
      // Published DPS is rounded to 0.01; its contribution can differ by 0.005*weight.
      const tolerance = 0.011 + (item.dps ? 0.005 * Math.max(plain.weights.melee_dps || 0, plain.weights.ranged_dps || 0, plain.weights.wand_dps || 0) : 0);
      pureChecks++; summary.pureChecks++;
      if (Math.abs(expected - item.score) <= tolerance) { pureMatches++; summary.pureMatches++; }
      else summary.examples.push({ slot, item: item.id, name: item.name, score: item.score, expected, difference: item.score - expected });
    }
    for (const items of Object.values(full.slots)) for (const item of items) {
      if (item.set_bonus) summary.setRows++;
      for (const effect of item.effects) summary[effect.scored ? 'scoredEffects' : 'unscoredEffects']++;
    }
    profiles.push({ id, class: full.class, spec: full.spec, weights: spec.weights });
    const preferred = cls.key === 'hunter' ? 'Ranged' : spec.key === 'fury' || cls.key === 'rogue' ? 'Main Hand'
      : spec.key === 'arms' || spec.key === 'retribution' || spec.key === 'enhancement' ? 'Two-Hand'
        : spec.key === 'protection' ? 'Off Hand' : 'Head';
    const golden = plain.slots[preferred]?.find(item => !item.effects.length && !item.set_bonus);
    if (!golden) throw new Error(`No static golden example: ${id}/${preferred}`);
    const stats = { ...golden.stats, armor: golden.armor || 0 };
    for (const key of Object.keys(stats)) if (key.startsWith('skill_')) {
      stats.weapon_skill = (stats.weapon_skill || 0) + stats[key]; delete stats[key];
    }
    const slot = ({ Ranged: 'ranged', 'Main Hand': 'main', 'Off Hand': 'off', 'Two-Hand': 'main', Head: 'head' })[preferred];
    fixtures.push({ profile: id, itemID: golden.id, sourceSlot: preferred, expectedScore: golden.score,
      tolerance: 0.011 + (golden.dps ? 0.005 * Math.max(...Object.values(plain.weights)) : 0),
      gear: { [slot]: { known: true, instance: `fixture:${golden.id}`, stats,
        ...(golden.dps ? { weapon: true, dps: golden.dps } : {}),
        ...(cls.key === 'rogue' && spec.key === 'combat-daggers' ? { weaponFamily: 'dagger' } : {}),
        ...(preferred === 'Two-Hand' ? { twoHand: true } : {}) } } });
    summaries.push(summary);
  }
  // Parse generated numeric rank bands as data; never execute downloaded third-party Lua.
  const addonPath = path.join(root, '.cache', 'foreverwow-research', 'ForeverWoWBiS', 'Data.lua');
  let rankCoverage = null;
  if (fs.existsSync(addonPath)) {
    const source = fs.readFileSync(addonPath, 'utf8');
    const starts = [...source.matchAll(/^    ([A-Z]+) = function\(\) return \{/gm)];
    const coverage = new Set(), invalid = [];
    let bands = 0;
    for (let i = 0; i < starts.length; i++) {
      const chunk = source.slice(starts[i].index, starts[i + 1]?.index ?? source.length);
      const keys = [...chunk.match(/specs = (.*)/)[1].matchAll(/key="([^"]+)"/g)].map(m => m[1]);
      const items = chunk.slice(chunk.indexOf('      items = {'), chunk.indexOf('      scores = {'));
      for (const line of items.matchAll(/^      \[\d+\] = "([^"]*)",/gm)) {
        for (const token of line[1].split(' ')) {
          const match = token.match(/^(\d+)\/(\d+)\/([abh])\/\d*\/(.*)$/);
          if (!match) { invalid.push(token); continue; }
          for (const run of match[4].split(',')) {
            const band = run.match(/^(\d+)(?:-(\d+))?:(\d+)$/);
            if (!band) { invalid.push(run); continue; }
            const lo = +band[1], hi = +(band[2] || band[1]), rank = +band[3];
            if (!keys[+match[1] - 1] || lo < 1 || hi > 60 || lo > hi || rank < 1 || rank > 10) { invalid.push(token); continue; }
            bands++;
            for (let level = lo; level <= hi; level++) for (const faction of match[3] === 'b' ? ['a', 'h'] : [match[3]]) {
              coverage.add(`${starts[i][1].toLowerCase()}/${keys[+match[1] - 1]}/${level}/${faction}`);
            }
          }
        }
      }
    }
    const missing = [];
    for (const p of profiles) for (let level = 1; level <= 60; level++) for (const faction of ['a', 'h']) {
      const key = `${p.id}/${level}/${faction}`;
      if (!coverage.has(key)) missing.push(key);
    }
    rankCoverage = { sha256: hash(source), version: source.match(/version = "([^"]+)"/)?.[1], bands,
      coveredSpecLevelFactions: coverage.size, expected: profiles.length * 60 * 2, missing, invalid };
  }
  const result = { schema: 1, retrievedAt: manifest.retrievedAt, builds: [...builds], levels,
    classCount: cfg.classes.length, specCount: profiles.length, requests: manifest.requests.length,
    itemRows, pureChecks, pureMatches, failures, rankCoverage, specs: summaries };
  write(path.join(cache, 'audit.json'), result);
  fs.mkdirSync(path.join(root, 'docs', 'research'), { recursive: true });
  write(path.join(root, 'docs', 'research', 'foreverwow-stat-weights-20261107.json'), {
    schema: 1, source: 'https://foreverwow.gg/tool/', retrievedAt: manifest.retrievedAt,
    sourceConfigSHA256: manifest.configSHA256, builds: [...builds], status: 'Observed external reference weights; not calibrated Suite defaults.', profiles });
  write(path.join(root, 'docs', 'research', 'foreverwow-audit-20261107.json'), result);
  write(path.join(root, 'docs', 'research', 'gear-baseline-golden-20261107.json'), {
    schema: 1, source: 'ForeverWoW.gg public API with no_sets=1 and no_on_use=1; one static example per spec.',
    build: [...builds].join(', '), fixtures });
  console.log(JSON.stringify({ ...result, specs: summaries.map(s => ({ id: s.id, pureChecks: s.pureChecks,
    pureMatches: s.pureMatches, weightChanges: s.weightChanges, mismatches: s.examples })) }, null, 2));
  if (failures.length || pureChecks !== pureMatches || summaries.some(s => s.weightChanges.length)
    || rankCoverage?.missing.length || rankCoverage?.invalid.length) process.exitCode = 1;
}

if (require.main === module) {
  if (process.argv[2] === '--collect') collect().catch(error => { console.error(error); process.exitCode = 1; });
  else if (process.argv[2] === '--audit') audit();
  else console.log('Use --collect to refresh the public research cache. See docs/gear-upgrade-baseline.md.');
}
module.exports = { root, cache, levels, read, write, rawScore };
