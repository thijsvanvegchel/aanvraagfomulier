# NKR Standaardset

Een webpagina waarmee een onderzoeker zelf een eenvoudige NKR-dataset op recordniveau samenstelt,
uitsluitend uit wat in de [NKR-datacatalogus](https://iknl.nl/NKR-datacatalogus) staat.

Bedoeld voor vragen die verder gaan dan [NKR Cijfers](https://iknl.nl/nkr-cijfers), maar geen maatwerk
nodig hebben. Er wordt geen script geschreven: de analist toetst alleen of de set juridisch geleverd mag worden.

De pagina maakt live:

- een **overzicht voor de analist**: populatie, gevraagde items, en aandachtspunten voor de juridische toets;
- een **specificatie** in JSON, bedoeld voor Microsoft Dynamics en PowerBI.

## Wat wel en niet in deze route past

| Wel | Niet (gebruik het gewone aanvraagformulier) |
|---|---|
| Tumorsoorten met een catalogus-dataset, ook meerdere tegelijk | Tumorsoorten zonder catalogus-dataset |
| Selectie op periode, leeftijd, geslacht, gedrag, morfologie, stadium | Morfologiecodes die niet in de catalogus staan |
| Extra selectie op elke catalogusvariabele met een waardelijst | Afgeleide variabelen, groepsindelingen |
| Items uit de catalogus, op recordniveau | Projectitems, items "in overleg", geaggregeerde tabellen |
| | Koppeling met andere bronnen (zoals PROFIEL) |

De juridische check volgt de herleidbaarheidsnoten uit de catalogus:

- **standaard**: geleverd zoals het in de catalogus staat; datums automatisch als interval, leeftijd in 5-jaarscategorieën;
- **let op**: ziekenhuisvariabelen, postcode (regio), datums zonder interval;
- **niet in deze route**: items die niet worden uitgeleverd of alleen in overleg (bijv. `zkh_patnum`, projectitems).

## Snel starten

```bash
pip install -r requirements.txt
python scripts/build.py          # bouwt dist/index.html
node --test tests/*.test.js
```

Open daarna `dist/index.html` in een browser. Er is geen server nodig.

## Mappen

| Map | Inhoud |
|---|---|
| `src/template.html` | De pagina: opmaak, formulier en logica. |
| `data/catalogus.json` | Alle variabelen uit de catalogus (10 datasets), één per regel. |
| `config/datasets.json` | Per dataset: naam, ICD-codes en (waar van toepassing) het geslacht. |
| `scripts/scrape_catalogus.py` | Haalt de catalogus opnieuw op en schrijft `data/catalogus.json`. |
| `scripts/build.py` | Voegt template, catalogus en config samen tot `dist/index.html`. |
| `tests/` | Tests, met een lokale kopie van de catalogus (Borst). |
| `docs/roadmap.md` | Open punten. |

## Catalogus bijwerken

```bash
python scripts/scrape_catalogus.py
python scripts/build.py
```

Controleer de diff van `data/catalogus.json` in je pull request: zo zie je welke items erbij of af zijn gegaan.
Nieuwe items komen vanzelf in de pagina. De juridische check werkt op de noten die de catalogus zelf meegeeft.

## Privacy

De pagina bevat geen patiëntgegevens en stuurt niets naar een server. Concepten worden alleen in de
browser van de gebruiker bewaard (`localStorage`).
