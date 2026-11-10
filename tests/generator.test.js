// Draait de generator uit dist/app.js op voorbeeld 26-01697 en vergelijkt met sas/voorbeelden/26-01697_geanonimiseerd.sas.
// Het voorbeeld staat alleen hier in de test, niet in de pagina.
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
  const fn = new Function(...Object.keys(sandbox), js + '\n;return {buildPrompt, buildSpec, checks, pSentence, selectiecriteria, empty, applySex, setState: s => { S = s; }};');
  return fn(...Object.values(sandbox));
}

const EXAMPLE_VARS = 'gesl incjr leeft mal mal_int mal_tumsoort meno_stat vit_stat_int vit_stat topo_sublok later morf diffgrad diag_basis ct cn cm pt pn pm cstadium pstadium stadium ond_lymf pos_lymf tum_afm multifoc er_stat er_waarde pr_stat pr_waarde her2_stat her2_tech mammaprint_uitslag oncotype_uitslag chir chir_type chir_int uitgebr_chir_type uitgebr_chir_int inv_rad_laatste dcis_rad_laatste residu okd rt chemo chemo_code chemo_start_int chemo_stop_int horm horm_code horm_start_int target target_code target_start_int target_stop_int mri mri_int mari mari_int mari_uitslag swk swk_int swk_uitslag oksel_echo oksel_echo_uitslag oksel_echo_int'.split(' ');

const app = loadApp();
app.setState({ ...app.empty(),
  type: 'update', vorige: '25-01377', nr: '26-01697', doel: 'onderzoek', titel: 'Testaanvraag',
  dss: ['Borst'], jrvan: 2005, jrtot: 2019, lmin: 18, lmax: '', gesl: 'beide', gedrag: 'invasief',
  morf: ['8500'], morfExtra: '8520', stadvar: 'stadium', stad: ['1', '2', '3'], receptor: 'hrpos', malexcl: '5j',
  pi: 'Invasief lobulair carcinoom', pc: 'NST (ductaal carcinoom NNO)', po: 'Overleving',
  ic: { I: [{ n: 'morf', vals: [], extra: '8520' }], C: [{ n: 'morf', vals: ['8500'], extra: '' }] }, iconly: 'nee',
  out: ['vit_stat', 'vit_stat_int'], levering: 'record', vars: new Set(EXAMPLE_VARS), toel: '' });

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

test('I en C uit de catalogus worden een groepsvariabele', () => {
  const p = app.buildPrompt();
  assert.ok(p.includes('if morf in (8520) then groep = 1;'));
  assert.ok(p.includes('else if morf in (8500) then groep = 0;'));
  assert.ok(p.includes('key_nkr key_eid groep'));
  const pico = app.buildSpec().pico;
  assert.deepStrictEqual(pico.C.regels[0], { variabele: 'morf', waarden: [{ code: '8500', label: 'Ductaal carcinoom, NNO' }] });
  assert.deepStrictEqual(pico.O.variabelen, ['vit_stat', 'vit_stat_int']);
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

test('geslacht volgt uit de tumorsoort bij prostaat, en wordt weer vrij bij borst', () => {
  const app2 = loadApp();
  app2.setState({ ...app2.empty(), dss: ['Prostaat'], gesl: 'beide' });
  app2.applySex(null);
  assert.match(app2.pSentence(), /^Mannen /);
  assert.ok(app2.buildPrompt().includes('volgt uit de tumorsoort'));
  assert.ok(!app2.buildPrompt().includes('gesl = 1'));
  assert.deepStrictEqual(app2.buildSpec().populatie.geslacht, { waarde: 'man', volgt_uit_tumorsoort: true });
  app2.setState({ ...app2.empty(), dss: ['Borst'], gesl: 'man' });
  app2.applySex('man');
  assert.match(app2.pSentence(), /^Patiënten /);
});

test('meerdere tumorsoorten: borst en darm met vermoeidheid via PROFIEL', () => {
  const a = loadApp();
  a.setState({ ...a.empty(), dss: ['Borst', 'CRC'], po: 'Vermoeidheid', vars: new Set(['gesl', 'incjr', 'er_stat', 'chemo']) });
  const p = a.buildPrompt();
  assert.ok(p.includes('tumsoort in (501300, [tumsoort-code CRC, TODO analist])'));
  assert.ok(p.includes('key_nkr key_eid tumsoort'));
  const msgs = a.checks().map(c => c[1]).join('\n');
  assert.match(msgs, /er_stat: alleen in Borst; ontbreekt voor Darm \(CRC\)/);
  assert.match(msgs, /Kies koppeling met PROFIEL/);
  a.setState({ ...a.empty(), dss: ['Borst', 'CRC'], po: 'Vermoeidheid', koppel: 'ja', bronnen: ['PROFIEL'], vars: new Set(['gesl']) });
  assert.doesNotMatch(a.checks().map(c => c[1]).join('\n'), /Kies koppeling met PROFIEL/);
  assert.deepStrictEqual(a.buildSpec().koppeling, { gewenst: 'ja', bronnen: ['PROFIEL'] });
  assert.deepStrictEqual(a.buildSpec().datasets, ['Borst', 'CRC']);
});

test('geslacht staat vast bij meerdere vrouwelijke tumorsoorten, niet bij borst + cervix', () => {
  const a = loadApp();
  a.setState({ ...a.empty(), dss: ['Cervix', 'Ovarium'] }); a.applySex(null);
  assert.match(a.pSentence(), /^Vrouwen /);
  a.setState({ ...a.empty(), dss: ['Borst', 'Cervix'] }); a.applySex(null);
  assert.match(a.pSentence(), /^Patiënten /);
});
