// Rebuild from pinned research inputs; never fetch or execute addon UI code.
const fs = require('node:fs');
const path = require('node:path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('../.cache/lua-tools/fengari');
const root = path.resolve(__dirname, '..');
const input = path.join(root, '.cache/training-catalog-20261022');
const state = lauxlib.luaL_newstate(); lualib.luaL_openlibs(state);
function value(index) {
  const kind = lua.lua_type(state, index);
  if (kind === lua.LUA_TSTRING) return to_jsstring(lua.lua_tostring(state, index));
  if (kind === lua.LUA_TNUMBER) return lua.lua_tonumber(state, index);
  if (kind === lua.LUA_TBOOLEAN) return !!lua.lua_toboolean(state, index);
  if (kind !== lua.LUA_TTABLE) throw Error('Non-data value in catalog');
  const result = {}, absolute = lua.lua_absindex(state,index); lua.lua_pushnil(state);
  while (lua.lua_next(state,absolute)) { result[value(-2)] = value(-1); lua.lua_pop(state,1); }
  return result;
}
let data;
lua.lua_pushcfunction(state, () => { data = value(1); return 0; });
lua.lua_setglobal(state,to_luastring('EXPORT'));
const classes = ['Druid','Hunter','Mage','Paladin','Priest','Rogue','Shaman','Warlock','Warrior'];
const fixture = `local data = {} local ns = { forClass = function(token) data[token] = data[token] or {} return data[token] end }\n`
  + classes.map(name => `assert(loadfile(${JSON.stringify(path.join(input,'upstream',name+'.lua').replace(/\\/g,'/'))}))('Catalog',ns)`).join('\n')
  + `\nassert(loadfile(${JSON.stringify(path.join(input,'upstream/HunterPets.lua').replace(/\\/g,'/'))}))('Catalog',ns)\nEXPORT(data)`;
if (lauxlib.luaL_dostring(state,to_luastring(fixture))) throw Error(to_jsstring(lua.lua_tostring(state,-1)));
function csv(filename) {
  const text = fs.readFileSync(path.join(input,filename),'utf8').replace(/^\uFEFF/,'');
  const rows = []; let fields = [], field = '', quoted = false;
  for (let i=0;i<text.length;i++) {
    const c=text[i];
    if(c==='"') { if(quoted&&text[i+1]==='"'){field+='"';i++;} else quoted=!quoted; }
    else if(c===','&&!quoted){fields.push(field);field='';}
    else if(c==='\n'&&!quoted){fields.push(field.replace(/\r$/,''));rows.push(fields);fields=[];field='';}
    else field+=c;
  }
  if(field||fields.length){fields.push(field);rows.push(fields);}
  return new Map(rows.slice(1).map(row=>[Number(row[0]),row[1]]));
}
const names=csv('SpellName.csv'), ranks=csv('Spell.csv');
const allowed=new Set(['id','cost','requiredIds','requiredTalentId','race','races','faction','skills']);
const out={};
for(const token of Object.keys(data).sort()) {
  const entries=[];
  for(const [level,rows] of Object.entries(data[token].spellsByLevel)) {
    if(+level<1||+level>60) throw Error('Out-of-range level');
    for(const entry of Object.values(rows)) {
      for(const key of Object.keys(entry)) if(!allowed.has(key)) throw Error('Unmapped field '+key);
      if(!names.get(entry.id)||!Number.isInteger(entry.cost)||entry.cost<0) throw Error('Missing name/cost '+entry.id);
      entries.push({...entry,level:+level,name:names.get(entry.id),rank:ranks.get(entry.id)||undefined,
        pet:data[token].petAbilityIds?.[entry.id]||undefined});
    }
  }
  entries.sort((a,b)=>a.level-b.level||a.name.localeCompare(b.name)||a.id-b.id);
  if(new Set(entries.map(e=>e.id)).size!==entries.length) throw Error('Duplicate spell in '+token);
  out[token]=entries;
}
function serialize(v) {
  if(typeof v==='string')return JSON.stringify(v).replace(/\\u([0-9a-f]{4})/gi,(_,n)=>String.fromCharCode(parseInt(n,16)));
  if(typeof v==='number'||typeof v==='boolean')return String(v);
  if(Array.isArray(v))return '{'+v.map(serialize).join(',')+'}';
  const keys=Object.keys(v);
  if(keys.every(k=>/^\d+$/.test(k)))return '{'+keys.sort((a,b)=>+a-+b).map(k=>serialize(v[k])).join(',')+'}';
  return '{'+keys.filter(k=>v[k]!==undefined).map(k=>k+'='+serialize(v[k])).join(',')+'}';
}
const header='local _, Suite = ...\n-- Adapted factual class data: fusionpit/WhatsTraining (MIT), Forever branch\n-- e0d52183bac0581464d91b3b859528d53afd4a0d. Notice: TrainingCatalog-LICENSE.txt\n-- English names/ranks: Wago client exports 1.60.1.70532. Server costs may change.\nSuite.TrainingCatalogData = {\n';
fs.writeFileSync(path.join(root,'src/WoWForeverSuite/TrainingCatalogData.lua'),header+Object.entries(out).map(([token,rows])=>'    '+token+' = {\n'+rows.map(row=>'        '+serialize(row)+',').join('\n')+'\n    },').join('\n')+'\n}\n');
fs.copyFileSync(path.join(input,'upstream/LICENSE'),path.join(root,'src/WoWForeverSuite/TrainingCatalog-LICENSE.txt'));
fs.writeFileSync(path.join(input,'catalog.json'),JSON.stringify(out,null,2));
let weapons;
lua.lua_pushcfunction(state,()=>{weapons=value(1);return 0;});lua.lua_setglobal(state,to_luastring('EXPORT_WEAPONS'));
const weaponSource=fs.readFileSync(path.join(input,'upstream/WeaponsBase.lua'),'utf8').split('local weaponMasters =')[0];
if(lauxlib.luaL_dostring(state,to_luastring('local wt = {gameVersion="forever"}\n'+weaponSource.replace('local _, wt = ...','')+'\nweaponSkills[196].classes.ROGUE=true\nweaponSkills[197].classes.SHAMAN=true\nweaponSkills[199].classes.SHAMAN=true\nEXPORT_WEAPONS(weaponSkills)')))throw Error(to_jsstring(lua.lua_tostring(state,-1)));
fs.appendFileSync(path.join(root,'src/WoWForeverSuite/TrainingCatalogData.lua'),'Suite.TrainingWeaponClasses = {\n'+Object.entries(weapons).map(([id,entry])=>'    ['+id+'] = '+serialize(entry.classes)+',').join('\n')+'\n}\n');
console.log(Object.entries(out).map(([token,rows])=>token+': '+rows.length).join('\n'));
