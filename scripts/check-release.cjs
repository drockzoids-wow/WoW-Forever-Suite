const fs = require('node:fs');
const path = require('node:path');

function checkRelease(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      checkRelease(file);
    } else if (/^TestDiagnostics\./i.test(entry.name)
      || /\.(lua|toc|xml)$/i.test(entry.name)
        && /TestDiagnostics|taintlog/i.test(fs.readFileSync(file, 'utf8'))) {
      throw new Error(`Release blocked: remove test taint logging code and TOC entries before packaging (${file}).`);
    }
  }
}

module.exports = { checkRelease };
if (require.main === module) {
  checkRelease(path.resolve(__dirname, '../src/WoWForeverSuite'));
  console.log('Release guard passed: no test taint logging in addon sources.');
}
