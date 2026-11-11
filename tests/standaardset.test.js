// Tests voor de standaardset: alleen catalogusitems, juridische check, geen maatwerk.
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
    document: { getElementById: el, querySelectorAll: () => [], querySelector: () => null, addEventListener() {}, createRange() {} },
    getSelection: () => ({}), navigator: {}, localStorage: { getItem: () => null, setItem() {} },
    setTimeout, clearTimeout, console,
  };
  const fn = new Function(...Object.keys(sandbox), js + '\n;return {buildSpec, legalCheck, verdict, itemStatus, vmap, pSentence, applySex, empty, morfIcdo, mailText, mailHtml, mailtoHref, mailSubject, setState: s => { S = s; }};');
  return fn(...Object.values(sandbox));
}

const state = (app, extra) => ({ ...app.empty(), titel: 'Test', vraag: 'Beschrijvende vraag.', ...extra });

test('standaardset zonder aandachtspunten krijgt status OK', () => {
  const app = loadApp();
  app.setState(state(app, { vars: new Set(['incjr', 'morf', 'stadium', 'vit_stat', 'vit_stat_int']) }));
  assert.strictEqual(app.verdict(app.legalCheck())[0], 'ok');
  assert.strictEqual(app.buildSpec().route, 'standaardset');
});

test('datum wordt interval, leeftijd wordt categorie', () => {
  const app = loadApp();
  app.setState(state(app, { vars: new Set(['incdat', 'leeft', 'chir_dat']) }));
  const lev = Object.fromEntries(app.buildSpec().variabelen.map(v => [v.item.replace(/\s*\[.*\]/, ''), v.levering]));
  assert.strictEqual(lev.leeft, 'leeft_cat');
  assert.strictEqual(lev.chir_dat, 'chir_int');
});

test('ziekenhuisvariabele geeft juridisch aandachtspunt', () => {
  const app = loadApp();
  app.setState(state(app, { vars: new Set(['incjr', 'rt_zkh']) }));
  const [cls] = app.verdict(app.legalCheck());
  assert.strictEqual(cls, 'wn');
  assert.ok(app.buildSpec().variabelen.find(v => v.item.startsWith('rt_zkh')).juridisch);
});

test('niet-leverbare items worden niet meegenomen', () => {
  const app = loadApp();
  app.setState(state(app, { vars: new Set(['zkh_patnum', 'gebdat', 'incjr']) }));
  const items = app.buildSpec().variabelen.map(v => v.item);
  assert.deepStrictEqual(items, ['incjr']);
});

test('zonder onderzoeksvraag of items is de aanvraag niet compleet', () => {
  const app = loadApp();
  app.setState({ ...app.empty() });
  const msgs = app.legalCheck().filter(r => r[0] === 'bad').map(r => r[1]).join('\n');
  assert.match(msgs, /onderzoeksvraag/);
  assert.match(msgs, /minstens één data-item/);
});

test('extra selectie op een catalogusvariabele komt in populatie en specificatie', () => {
  const app = loadApp();
  app.setState(state(app, { filters: [{ n: 'er_stat', vals: ['1'] }], vars: new Set(['er_stat']) }));
  assert.match(app.pSentence(), /oestrogeenreceptor status: Positief/i);
  assert.deepStrictEqual(app.buildSpec().populatie.extra_selectie, [{ variabele: 'er_stat', waarden: [{ code: '1', label: 'Positief' }] }]);
});

test('meerdere tumorsoorten: item dat maar in één bestaat krijgt een melding', () => {
  const app = loadApp();
  app.setState(state(app, { dss: ['Borst', 'CRC'], vars: new Set(['er_stat', 'chemo']) }));
  const msgs = app.legalCheck().map(r => r[1]).join('\n');
  assert.match(msgs, /er_stat: alleen in Borst; leeg voor Darm \(CRC\)/);
  assert.deepStrictEqual(app.buildSpec().datasets, ['Borst', 'CRC']);
});

test('geslacht volgt uit de tumorsoort', () => {
  const app = loadApp();
  app.setState(state(app, { dss: ['Prostaat'] })); app.applySex(null);
  assert.match(app.pSentence(), /^Mannen /);
  app.setState(state(app, { dss: ['Borst', 'Cervix'], gesl: 'vrouw' })); app.applySex('vrouw');
  assert.match(app.pSentence(), /^Patiënten /);
});

test('de pagina bevat geen SAS of interne macro\'s', () => {
  const html = fs.readFileSync(path.join(__dirname, '..', 'dist', 'index.html'), 'utf8');
  for (const w of ['%kern', 'krn.kern', 'SAS', '%anderemaligniteit', '501300']) {
    assert.ok(!html.includes(w), `pagina bevat nog ${w}`);
  }
});

test('mail bevat titel, onderzoeksvraag en aangevraagde data, en gaat naar de analist', () => {
  const app = loadApp();
  app.setState(state(app, { titel: 'Vermoeidheid na chemo', vraag: 'Hoe vaak krijgen patiënten chemotherapie?', vars: new Set(['chemo', 'rt_zkh']) }));
  const txt = app.mailText();
  assert.match(txt, /Titel: Vermoeidheid na chemo/);
  assert.match(txt, /ONDERZOEKSVRAAG\nHoe vaak krijgen patiënten chemotherapie\?/);
  assert.match(txt, /- chemo: /);
  assert.match(txt, /rt_zkh.*LET OP/);
  assert.match(app.mailHtml(), /<h1[^>]*>Vermoeidheid na chemo<\/h1>/);
  const { href, kort } = app.mailtoHref();
  assert.ok(href.startsWith('mailto:t.vanvegchel@iknl.nl?subject=NKR-standaardset'));
  assert.strictEqual(kort, false);
});

test('lange aanvraag: korte mailtekst, volledige versie via klembord', () => {
  const app = loadApp();
  const alle = new Set(app.vmap ? Object.keys(app.vmap()) : []);
  app.setState(state(app, { vars: alle }));
  const { href, kort } = app.mailtoHref();
  assert.strictEqual(kort, true);
  assert.ok(href.length < 2000);
});

test('morfologie krijgt de gedragscode uit Gedrag', () => {
  const app = loadApp();
  app.setState(state(app, { morf: ['8500'], gedrag: 'invasief' }));
  assert.deepStrictEqual(app.morfIcdo(), ['8500/3']);
  assert.match(app.pSentence(), /morfologie 8500\/3/);
  app.setState(state(app, { morf: ['8500'], gedrag: 'insitu' }));
  assert.deepStrictEqual(app.buildSpec().populatie.morfologie_icdo, ['8500/2']);
  app.setState(state(app, { morf: ['8500', '8201'], gedrag: 'beide' }));
  assert.deepStrictEqual(app.morfIcdo(), ['8500/2', '8500/3', '8201/2', '8201/3']);
});
