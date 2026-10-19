const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
process.chdir(root);
const parse = require(path.join(root, '.cache/lua-tools/luaparse/luaparse.js')).parse;
const directory = path.join(root, 'src/WoWForeverSuite');
const files = fs.readdirSync(directory).filter(name => name.endsWith('.lua'));
for (const file of files) parse(fs.readFileSync(path.join(directory, file), 'utf8'), { luaVersion: '5.1' });
console.log(`Lua 5.1 syntax passed: ${files.length} files`);
const toc = fs.readFileSync(path.join(directory, 'WoWForeverSuite.toc'), 'utf8');
if (toc !== fs.readFileSync(path.join(directory, 'WoWForeverSuite_Camelot.toc'), 'utf8')) throw new Error('TOC variants differ');
const version = toc.match(/^## Version:\s*(\d+\.\d+\.\d+)\s*$/m)?.[1];
const coreVersion = fs.readFileSync(path.join(directory, 'Core.lua'), 'utf8').match(/^Suite\.version = "([^"]+)"$/m)?.[1];
if (!version || version !== coreVersion) throw new Error('Core and TOC versions differ or are invalid');
const entries = toc.split(/\r?\n/).map(line => line.trim()).filter(line => line && !line.startsWith('#'));
const loaded = new Set();
function checkEntry(entry) {
  const resolved = path.resolve(directory, entry);
  const relative = path.relative(directory, resolved);
  if (!relative || relative === '..' || relative.startsWith('..' + path.sep) || path.isAbsolute(relative)) throw new Error(`Unsafe TOC entry: ${entry}`);
  if (!fs.statSync(resolved).isFile()) throw new Error(`Missing TOC file: ${entry}`);
  return relative.toLowerCase();
}
const bindings = toc.match(/^## Bindings:\s*(\S+)\s*$/m);
if (bindings) {
  checkEntry(bindings[1]);
  const xml = fs.readFileSync(path.join(directory, bindings[1]), 'utf8');
  const headers = new Set();
  for (const match of xml.matchAll(/<Binding\b[^>]*\bheader\s*=\s*["']([^"']+)["']/g)) {
    if (headers.has(match[1])) throw new Error(`Duplicate binding header: ${match[1]}`);
    headers.add(match[1]);
  }
}
for (const entry of entries) {
  const key = checkEntry(entry);
  if (loaded.has(key)) throw new Error(`Duplicate TOC entry: ${entry}`);
  loaded.add(key);
}
for (const file of files) if (!loaded.has(file.toLowerCase())) throw new Error(`Unloaded Lua file: ${file}`);
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require(path.join(root, '.cache/lua-tools/fengari'));
const state = lauxlib.luaL_newstate();
lualib.luaL_openlibs(state);
const luaEntries = entries.filter(entry => entry.endsWith('.lua'));
lua.lua_createtable(state, luaEntries.length, 0);
luaEntries.forEach((entry, index) => {
  lua.lua_pushstring(state, to_luastring(entry));
  lua.lua_rawseti(state, -2, index + 1);
});
lua.lua_setglobal(state, to_luastring('WFS_TEST_FILES'));
if (process.argv.includes('--gui-preview') || process.argv.includes('--dashboard-preview') || process.argv.includes('--workspace-preview')) {
  const previewDirectory = path.join(root, '.cache/gui-cleanup-ui-source-70338');
  fs.mkdirSync(previewDirectory, { recursive: true });
  function readValue(index) {
    const type = lua.lua_type(state, index);
    if (type === lua.LUA_TSTRING) return to_jsstring(lua.lua_tostring(state, index));
    if (type === lua.LUA_TBOOLEAN) return !!lua.lua_toboolean(state, index);
    if (type === lua.LUA_TNUMBER) return lua.lua_tonumber(state, index);
    if (type !== lua.LUA_TTABLE) return null;
    const absolute = lua.lua_absindex(state, index), entries = [];
    lua.lua_pushnil(state);
    while (lua.lua_next(state, absolute)) {
      entries.push([readValue(-2), readValue(-1)]); lua.lua_pop(state, 1);
    }
    if (entries.length && entries.every(([key]) => Number.isInteger(key) && key > 0)) {
      return entries.sort((a, b) => a[0] - b[0]).map(([, value]) => value);
    }
    return Object.fromEntries(entries);
  }
  if (process.argv.includes('--workspace-preview')) {
    const directory = path.join(root, '.cache/gui-workspace-0279');
    fs.mkdirSync(directory, { recursive: true });
    lua.lua_pushcfunction(state, () => {
      const model = readValue(1);
      if (!/^[a-z]+$/.test(model.page)) throw new Error('Invalid preview name');
      fs.writeFileSync(path.join(directory, model.page + '.json'), JSON.stringify(model, null, 2));
      return 0;
    });
    lua.lua_setglobal(state, to_luastring('WFS_WORKSPACE_PREVIEW'));
  }
  if (process.argv.includes('--gui-preview')) {
  lua.lua_pushcfunction(state, () => {
    const model = readValue(1);
    if (!['windows', 'bags', 'buffs', 'minimap'].includes(model.page)) throw new Error('Unknown UI preview page');
    if (model.variant && model.variant !== 'collapsed') throw new Error('Unknown UI preview variant');
    fs.writeFileSync(path.join(previewDirectory, model.page + (model.variant ? '-' + model.variant : '') + '.json'), JSON.stringify(model, null, 2));
    return 0;
  });
  lua.lua_setglobal(state, to_luastring('WFS_GUI_PREVIEW'));
  }
  if (process.argv.includes('--dashboard-preview')) {
    const dashboardDirectory = path.join(root, '.cache/character-dashboard-ui-source-70338');
    fs.mkdirSync(dashboardDirectory, { recursive: true });
    lua.lua_pushcfunction(state, () => {
      const model = readValue(1);
      fs.writeFileSync(path.join(dashboardDirectory, 'model.json'), JSON.stringify(model, null, 2));
      return 0;
    });
    lua.lua_setglobal(state, to_luastring('WFS_DASHBOARD_PREVIEW'));
  }
}
const result = lauxlib.luaL_dofile(state, to_luastring('tests/addon_spec.lua'));
if (result !== lua.LUA_OK) throw new Error(to_jsstring(lua.lua_tostring(state, -1)));
console.log('TOC checks passed. Runtime checks use API substitutes; verify the actual UI in WoW.');
