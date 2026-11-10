// Draait de generator uit dist/app.js op het voorbeeld 26-01697 en vergelijkt met het echte SAS-script.
// Gebruik: python scripts/build.py && node --test tests/
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

function loadApp() {
  const js = fs.readFileSync(path.join(__dirname, '..', 'dist', 'app.js'), 'utf8');
  const els = {};
  const el = id => els[id] || (els[id] = { id, value: '', innerHTML: '', textContent: '', hidden: false, dataset: {}, setAttribute() {}, querySelectorAll() { return []; } });
  const sandbox = {
    document: { getElementById: el, querySelectorAll: () => [], addEventListener() {}, createRange() {} },
    getSelection: () => ({}), navigator: {}, localStorage: { getItem: () => null, setItem() {} },
    setTimeout, clearTimeout, console,
  };
  const fn = new Function(...Object.keys(sandbox), js + '\n;return {buildPrompt, buildSpec, checks, pSentence, selectiecriteria, example, setState: s => { S = s; }};');
  return fn(...Object.values(sandbox));
}

const app = loadApp();
app.setState(app.example());

test('standaardselectie komt overeen met het voorbeeldscript', () => {
  const p = app.buildPrompt();
  for (const line of ['tumsoort in (501300)', 'tum_incl in (1)', 'nl_incl in (1)', 'ond_gebruik = 1', '2005 <= incjr <= 2019', "epis in ('DIA')", 'gesl in (1,2)', 'leeft >= 18', 'regstat = 0', '%kernborst']) {
    assert.ok(p.includes(line), `ontbreekt: ${line}`);
  }
});

test('verdere selectie: morfologie, receptor, stadium, eerdere maligniteit', () => {
  const p = app.buildPrompt();
  assert.ok(p.includes('if morf in (8500,8520);'));
  assert.ok(p.includes('if er_stat=1 or pr_stat=1; if her2_stat in (0,1);'));
  assert.ok(p.includes('if substr(stadium,1,1) in ("1", "2", "3");'));
  assert.ok(p.includes('maanden=0-60, gedrag=3-9, tum_incl=1, regstat=0 1 5'));
});

test('leeft wordt geleverd als leeft_cat, prefix-variabelen krijgen een dubbele punt', () => {
  const names = app.buildSpec().variabelen.map(v => v.sas);
  assert.ok(names.includes('leeft_cat'));
  assert.ok(!names.includes('leeft'));
  assert.ok(names.includes('chemo_code:'));
});

test('selectiecriteria heeft precies 10 records', () => {
  assert.strictEqual(app.selectiecriteria().length, 10);
});

test('beschikbaarheidscontroles: meno_stat en oksel_echo, maar geen valse TNM-jaren', () => {
  const msgs = app.checks().map(c => c[1]).join('\n');
  assert.match(msgs, /meno_stat: pas beschikbaar vanaf 2011/);
  assert.match(msgs, /oksel_echo: pas beschikbaar vanaf 2014/);
  assert.doesNotMatch(msgs, /vanaf 2026/);
});
