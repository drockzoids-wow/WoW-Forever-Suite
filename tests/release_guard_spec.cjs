const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { checkRelease } = require('../scripts/check-release.cjs');

test('release guard requires removal of temporary logging and TOC references', () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'wfs-release-guard-'));
  try {
    fs.writeFileSync(path.join(directory, 'Core.lua'), 'local addonName, Suite = ...\n');
    assert.doesNotThrow(() => checkRelease(directory));
    for (const [name, contents] of [
      ['TestDiagnostics.lua', '-- disabled test file still must be removed'],
      ['WoWForeverSuite.toc', 'Core.lua\nTestDiagnostics.lua\n'],
      ['Other.lua', 'C_CVar.SetCVar("taintLog", "2")'],
      ['Other.xml', '<Script>SetCVar("TAINTLOG", "2")</Script>'],
    ]) {
      const file = path.join(directory, name);
      fs.writeFileSync(file, contents);
      assert.throws(() => checkRelease(directory), /Release blocked/);
      fs.unlinkSync(file);
    }
    assert.doesNotThrow(() => checkRelease(directory));
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});
