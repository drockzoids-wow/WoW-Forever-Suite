const { test } = require('node:test');
const assert = require('node:assert/strict');
const { profiles, evaluate, compare } = require('../scripts/lib/gear-baseline.cjs');
const golden = require('../docs/research/gear-baseline-golden-20261107.json');
const item = (instance, stats = {}, extra = {}) => ({ known: true, instance, stats, ...extra });
const candidate = (instance, stats, destinations, extra = {}) => item(instance, stats, { eligible: true, destinations, ...extra });
const close = (actual, expected, tolerance = 0.000001) => assert.ok(Math.abs(actual - expected) <= tolerance, `${actual} != ${expected}`);
const bonus = (id, pieces, stats) => ({ id, pieces, stats, kind: 'equip', verified: true, source: 'test:verified-set' });

test('all 29 profiles reproduce independent published static scores', () => {
  assert.equal(profiles.size, 29);
  assert.equal(new Set([...profiles.values()].map(p => p.class)).size, 9);
  assert.equal(golden.fixtures.length, 29);
  for (const fixture of golden.fixtures) {
    close(evaluate(fixture.profile, fixture.gear, { build: 'ranged' }).score, fixture.expectedScore, fixture.tolerance);
  }
});

test('rings replace the actual weaker member; the ratio uses replaced gear', () => {
  const result = compare('warrior/fury', { finger1: item('a', { strength: 30 }), finger2: item('b', { strength: 10 }) },
    candidate('c', { strength: 20 }, ['finger1', 'finger2']));
  assert.equal(result.slot, 'finger2'); assert.equal(result.status, 'upgrade');
  close(result.delta, 10); close(result.percentOfReplacedScore, 100);
});

test('two-hander must beat the complete lost hand pair', () => {
  const before = { main: item('mh', { strength: 10 }, { weapon: true, dps: 30 }),
    off: item('oh', { strength: 10 }, { weapon: true, dps: 20 }) };
  const result = compare('warrior/fury', before, candidate('two', {}, ['main'], { twoHand: true, weapon: true, dps: 40 }));
  close(result.delta, -20); assert.equal(result.status, 'downgrade');
  assert.equal(compare('warrior/fury', { main: item('two', {}, { twoHand: true, weapon: true, dps: 40 }) },
    candidate('off', {}, ['off'], { weapon: true, dps: 50 })).status, 'unavailable');
});

test('one-hander replacing two-hander does not invent an off-hand partner', () => {
  const result = compare('warrior/fury', { main: item('two', {}, { twoHand: true, weapon: true, dps: 40 }) },
    candidate('one', {}, ['main'], { weapon: true, dps: 30 }));
  close(result.delta, -70);
});

test('actual set completion can reverse a static downgrade and set loss can reverse an upgrade', () => {
  const context = { sets: { pair: [bonus('2pc', 2, { strength: 40 })] } };
  const before = { head: item('h', {}, { set: 'pair', setPiece: 'head' }), chest: item('c', { strength: 30 }) };
  const gain = compare('warrior/fury', before, candidate('set', {}, ['chest'], { set: 'pair', setPiece: 'chest' }), context);
  close(gain.delta, 10); assert.equal(gain.status, 'upgrade');
  const loss = compare('warrior/fury', { ...before, chest: item('set', {}, { set: 'pair', setPiece: 'chest' }) },
    candidate('raw', { strength: 30 }, ['chest']), context);
  close(loss.delta, -10); assert.equal(loss.status, 'downgrade');
  close(evaluate('warrior/fury', { finger1: item('x', {}, { set: 'pair', setPiece: 'same-ring' }),
    finger2: item('y', {}, { set: 'pair', setPiece: 'same-ring' }) }, context).score, 0);
});

test('unknown proc changes remain conditional while unchanged unrelated procs cancel', () => {
  const proc = item('proc', {}, { effects: [{ id: 'proc', kind: 'proc', independent: true, source: 'test:fixed-independent-proc' }] });
  const before = { trinket1: proc, head: item('head', { strength: 10 }) };
  assert.equal(compare('warrior/fury', before, candidate('new', { strength: 20 }, ['head'])).status, 'upgrade');
  const result = compare('warrior/fury', before, candidate('new', { strength: 20 }, ['trinket1']));
  assert.equal(result.status, 'conditional'); assert.ok(result.changedUnknown.length);
  const scaling = { ...proc, effects: [{ id: 'proc', kind: 'proc' }] };
  assert.equal(compare('warrior/fury', { ...before, trinket1: scaling }, candidate('new', { strength: 20 }, ['head'])).status, 'conditional');
});

test('caps apply to both loadouts rather than every item independently', () => {
  const before = { head: item('h', { hit: 20 }), chest: item('c', { hit: 10 }) };
  const next = candidate('new', { hit: 20 }, ['chest']);
  close(compare('warrior/fury', before, next).delta, 12.5);
  const context = { caps: { hit: { value: 30, unit: 'canonical', source: 'test:remaining-gear-budget' } } };
  const result = compare('warrior/fury', before, next, context);
  close(result.delta, 0); assert.equal(result.status, 'near-tie');
  assert.equal(compare('warrior/fury', before, next, { caps: { hit: { value: 30 } } }).status, 'unavailable');
});

test('on-use and environmental effects require explicit validated assumptions', () => {
  const effect = { id: 'crest', kind: 'use', verified: true, source: 'test:crest', stats: { attack_power: 260 },
    duration: 20, cooldown: 120, utilization: 1, availabilityGroup: 'crest' };
  const crest = item('crest', { attack_power: 64 }, { effects: [effect] });
  close(evaluate('warrior/fury', { trinket1: crest }).score, 53.6666666667);
  const environment = item('rune', {}, { effects: [{ id: 'zone', kind: 'equip', verified: true,
    source: 'test:zone', stats: { attack_power: 42 }, condition: 'forest' }] });
  assert.ok(evaluate('warrior/fury', { trinket1: environment }).unresolved.length);
  close(evaluate('warrior/fury', { trinket1: environment }, { conditions: { forest: false } }).score, 0);
  close(evaluate('warrior/fury', { trinket1: environment }, { conditions: { forest: true } }).score, 21);
  const second = item('second', {}, { effects: [{ ...effect, id: 'other' }] });
  assert.ok(evaluate('warrior/fury', { trinket1: crest, trinket2: second }).unresolved.some(k => k.startsWith('shared-use:')));
});

test('feral weapon comparisons remain conditional; armor comparisons still work', () => {
  for (const profile of ['druid/feralcat', 'druid/feralbear']) {
    const before = { main: item('staff', {}, { twoHand: true, weapon: true, dps: 50 }), head: item('h', { agility: 10 }) };
    assert.equal(compare(profile, before, candidate('staff2', {}, ['main'], { twoHand: true, weapon: true, dps: 60 })).status, 'conditional');
    assert.equal(compare(profile, before, candidate('h2', { agility: 20 }, ['head'])).status, 'upgrade');
  }
});

test('Survival needs ranged build confirmation and dagger builds need a dagger', () => {
  const bow = candidate('bow', {}, ['ranged'], { weapon: true, dps: 10 });
  assert.equal(compare('hunter/survival', {}, bow).status, 'conditional');
  assert.equal(compare('hunter/survival', {}, bow, { build: 'ranged' }).status, 'fills-empty-slot');
  assert.equal(compare('rogue/combat-daggers', {}, candidate('sword', {}, ['main'], { weapon: true, dps: 10 })).status, 'conditional');
});

test('eligibility, item identity, invalid values, unique conflicts and empty-slot meaning', () => {
  assert.equal(compare('mage/fire', {}, candidate('zero', {}, ['head'])).status, 'fills-empty-slot');
  assert.equal(compare('mage/fire', {}, candidate('zero', {}, ['head'])).percentOfReplacedScore, null);
  assert.equal(compare('mage/fire', {}, candidate('bad', {}, ['head'], { eligible: false })).status, 'unavailable');
  assert.equal(compare('mage/fire', {}, candidate('bad', { intellect: NaN }, ['head'])).status, 'unavailable');
  assert.equal(compare('mage/fire', {}, candidate('alias', { ITEM_MOD_INTELLECT_SHORT: 10 }, ['head'])).status, 'unavailable');
  const old = item('old', { intellect: 10 }, { uniqueGroup: 'unique' });
  assert.equal(compare('mage/fire', { finger1: old }, candidate('new', { intellect: 30 }, ['finger2'], { uniqueGroup: 'unique' })).status, 'unavailable');
  assert.equal(compare('mage/fire', { head: old }, { ...old, eligible: true, destinations: ['head'] }).status, 'unavailable');
  assert.equal(compare('mage/fire', { head: item('old', { intellect: 10 }) }, candidate('tiny', { intellect: 10.001 }, ['head'])).status, 'near-tie');
  assert.throws(() => evaluate('made-up/spec', {}));
});
