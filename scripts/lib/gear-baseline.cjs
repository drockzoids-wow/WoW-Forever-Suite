// Original offline reference algorithm. Inputs are normalized facts, never raw WoW API values.
// This is a research baseline, not shipped addon behavior or a combat simulation.
const reference = require('../../docs/research/foreverwow-stat-weights-20261107.json');
const profiles = new Map(reference.profiles.map(profile => [profile.id, profile]));
const finite = value => typeof value === 'number' && Number.isFinite(value);
const canonicalStats = new Set(reference.profiles.flatMap(p => Object.keys(p.weights))
  .filter(key => !key.endsWith('_dps')).concat(['holy_resistance', 'fire_resistance', 'nature_resistance',
    'frost_resistance', 'shadow_resistance', 'arcane_resistance', 'hp5', 'mana']));
const slots = new Set(['head', 'neck', 'shoulder', 'back', 'chest', 'wrist', 'hands', 'waist',
  'legs', 'feet', 'finger1', 'finger2', 'trinket1', 'trinket2', 'main', 'off', 'ranged']);

function addStats(target, stats, factor = 1) {
  if (!stats || typeof stats !== 'object' || Array.isArray(stats)) throw new Error('Normalized stats required');
  for (const [key, value] of Object.entries(stats)) {
    if (!canonicalStats.has(key) || !finite(value)) throw new Error(`Unnormalized stat: ${key}`);
    target[key] = (target[key] || 0) + value * factor;
  }
}

function evaluate(profileID, gear, context = {}) {
  const profile = profiles.get(profileID);
  if (!profile) throw new Error('Explicit known spec profile required');
  const weights = profile.weights, totals = {}, unresolved = new Set(), interactions = new Set(), cautions = new Set();
  let weaponScore = 0;
  const instances = new Set(), unique = new Set(), setCounts = {};
  const unknownEffect = (effect, key) => {
    unresolved.add(key);
    // Unchanged procs cancel only when their independence is an established input fact.
    if (effect.independent !== true || !effect.source) interactions.add(key);
  };
  const addEffect = (effect, key) => {
    if (!effect || typeof effect.id !== 'string') throw new Error('Stable effect ID required');
    if (effect.verified !== true || !effect.source) { unknownEffect(effect, key); return; }
    if (effect.condition) {
      const active = context.conditions?.[effect.condition];
      if (active === false) return;
      if (active !== true) { unknownEffect(effect, key); return; }
    }
    let factor = 1;
    if (effect.kind === 'use') {
      if (!finite(effect.duration) || !finite(effect.cooldown) || effect.duration <= 0 || effect.cooldown <= 0
        || !finite(effect.utilization) || effect.utilization < 0 || effect.utilization > 1
        || !effect.availabilityGroup) { unknownEffect(effect, key); return; }
      factor = Math.min(1, effect.duration / effect.cooldown) * effect.utilization;
      cautions.add('averaged-on-use');
    } else if (effect.kind !== 'equip') { unknownEffect(effect, key); return; }
    addStats(totals, effect.stats, factor);
  };
  const useGroups = new Map();
  for (const [slot, item] of Object.entries(gear)) {
    if (!slots.has(slot)) throw new Error(`Unknown slot: ${slot}`);
    if (!item) continue;
    if (item.known !== true || typeof item.instance !== 'string') throw new Error('Known item instance required');
    if (instances.has(item.instance)) throw new Error('One physical item cannot occupy two slots');
    instances.add(item.instance);
    if (item.uniqueGroup) {
      if (unique.has(item.uniqueGroup)) throw new Error('Unique-equipped conflict');
      unique.add(item.uniqueGroup);
    }
    if (item.twoHand && (slot !== 'main' || gear.off)) throw new Error('Illegal two-hand configuration');
    addStats(totals, item.stats);
    if (item.set) {
      if (typeof item.setPiece !== 'string') throw new Error('Stable set-piece identity required');
      if (!setCounts[item.set]) setCounts[item.set] = new Set();
      setCounts[item.set].add(item.setPiece);
    }
    for (const effect of item.effects || []) {
      const key = `item:${item.instance}:${effect.id}`;
      if (effect.kind === 'use' && effect.availabilityGroup) {
        const keys = useGroups.get(effect.availabilityGroup) || [];
        keys.push(key); useGroups.set(effect.availabilityGroup, keys);
      }
      addEffect(effect, key);
    }
    if (['main', 'off', 'ranged'].includes(slot) && item.weapon === true) {
      const weight = slot === 'ranged' ? weights.wand_dps ?? weights.ranged_dps ?? 0
        : slot === 'off' ? weights.offhand_dps ?? (weights.melee_dps || 0) * 0.5 : weights.melee_dps || 0;
      if (weight) {
        if (!finite(item.dps) || item.dps <= 0) throw new Error('Readable weapon DPS required');
        // Keep their number as a reference; do not claim a form-DPS model without client evidence.
        if (profileID === 'druid/feralcat' || profileID === 'druid/feralbear') unresolved.add(`form-dps:${item.instance}`);
        else weaponScore += item.dps * weight;
      }
      if (profileID === 'hunter/survival' && context.build !== 'ranged') unresolved.add(`survival-build:${item.instance}`);
      if (profileID === 'rogue/combat-daggers' && slot === 'main' && item.weaponFamily !== 'dagger') {
        unresolved.add(`dagger-build:${item.instance}`);
      }
      if (item.speedSensitive) unresolved.add(`weapon-speed:${item.instance}`);
    }
  }
  for (const keys of useGroups.values()) if (keys.length > 1) for (const key of keys) unresolved.add(`shared-use:${key}`);
  for (const [setID, pieces] of Object.entries(setCounts)) {
    const count = pieces.size;
    const definition = context.sets?.[setID];
    if (!definition) { unknownEffect({}, `set:${setID}:${count}`); continue; }
    for (const bonus of definition) {
      if (!Number.isInteger(bonus.pieces) || bonus.pieces <= 0) throw new Error('Valid set threshold required');
      if (count >= bonus.pieces) addEffect(bonus, `set:${setID}:${bonus.id}`);
    }
  }
  let score = weaponScore;
  for (const [stat, total] of Object.entries(totals)) {
    let effective = total;
    const cap = context.caps?.[stat];
    if (cap) {
      if (!cap.source || cap.unit !== 'canonical' || !finite(cap.value) || cap.value < 0) throw new Error('Verified canonical-unit cap required');
      effective = Math.min(total, cap.value);
    }
    score += effective * (weights[stat] || 0);
  }
  if (!finite(score)) throw new Error('Invalid score');
  cautions.add('external-uncalibrated-weights');
  cautions.add('caps-unmodeled-unless-supplied');
  cautions.add('rotation-talents-and-encounter-unmodeled');
  const interactionSignature = JSON.stringify({ stats: Object.entries(totals).sort(([a], [b]) => a.localeCompare(b)),
    weapons: ['main', 'off', 'ranged'].map(slot => { const item = gear[slot];
      return [slot, item?.weapon === true, item?.dps ?? null, item?.weaponFamily ?? null, item?.speed ?? null]; }) });
  return { score, totals, unresolved: [...unresolved].sort(), interactions: [...interactions].sort(),
    interactionSignature, cautions: [...cautions].sort() };
}

function compare(profileID, before, candidate, context = {}) {
  if (candidate.eligible !== true) return { status: 'unavailable', reason: 'Eligibility not confirmed' };
  if (!Array.isArray(candidate.destinations) || !candidate.destinations.length) return { status: 'unavailable', reason: 'No legal destination' };
  if (Object.values(before).some(item => item?.instance === candidate.instance)) return { status: 'unavailable', reason: 'Candidate is already equipped' };
  let baseline;
  try { baseline = evaluate(profileID, before, context); }
  catch (error) { return { status: 'unavailable', reason: error.message }; }
  const choices = [];
  for (const slot of candidate.destinations) {
    if (!slots.has(slot)) continue;
    const after = { ...before }, removed = {};
    // Destinations must already reflect class/spec/level proficiency and dual-wield rules.
    // A 1H replacing a 2H leaves the off hand empty; it never assumes an unowned partner.
    if (candidate.twoHand && slot !== 'main') continue;
    for (const removedSlot of candidate.twoHand ? ['main', 'off'] : [slot]) {
      if (after[removedSlot]) removed[removedSlot] = after[removedSlot];
      delete after[removedSlot];
    }
    if (slot === 'off' && before.main?.twoHand) continue;
    after[slot] = candidate;
    try {
      const next = evaluate(profileID, after, context);
      const changedUnknown = [...new Set([...baseline.unresolved, ...next.unresolved])]
        .filter(key => baseline.unresolved.includes(key) !== next.unresolved.includes(key));
      if (baseline.interactionSignature !== next.interactionSignature) {
        for (const key of new Set([...baseline.interactions, ...next.interactions])) {
          if (baseline.unresolved.includes(key) && next.unresolved.includes(key)) changedUnknown.push(`interaction:${key}`);
        }
      }
      const delta = next.score - baseline.score;
      // Display a local equipment-group ratio, not a diluted whole-character percentage.
      const replacement = evaluate(profileID, removed, { ...context, sets: {} });
      const empty = Object.keys(removed).length === 0;
      const threshold = Math.max(0.1, replacement.score * 0.01);
      const status = changedUnknown.length ? 'conditional' : empty ? 'fills-empty-slot'
        : delta >= threshold ? 'upgrade' : delta <= -threshold ? 'downgrade' : 'near-tie';
      choices.push({ slot, status, delta, before: baseline.score, after: next.score,
        percentOfReplacedScore: !empty && replacement.score > 0 ? delta / replacement.score * 100 : null,
        replacedScore: replacement.score, changedUnknown,
        cautions: [...new Set([...baseline.cautions, ...next.cautions])] });
    } catch (error) { choices.push({ slot, status: 'unavailable', reason: error.message }); }
  }
  const rank = choice => choice.status === 'unavailable' ? 0 : choice.status === 'conditional' ? 1 : 2;
  choices.sort((a, b) => rank(b) - rank(a) || (b.delta ?? -Infinity) - (a.delta ?? -Infinity) || a.slot.localeCompare(b.slot));
  return choices.length ? { ...choices[0], choices } : { status: 'unavailable', reason: 'No legal configuration' };
}

module.exports = { profiles, evaluate, compare };
