# NKR Aanvraagbouwer

Prototype voor een gestructureerde NKR-gegevensaanvraag. De aanvrager kiest PICO en data-items uit de
[NKR-datacatalogus](https://iknl.nl/NKR-datacatalogus). De pagina maakt daar live van:

- een **samenvatting voor de analist** (één scherm, met controles op beschikbaarheid en herleidbaarheid);
- een **specificatie** in JSON, bedoeld voor Microsoft Dynamics en PowerBI;
- een **prompt voor het SAS-basisscript**, volgens de vaste IKNL-structuur;
- een opzet voor een **indicatief aantal patiënten** (nog niet gekoppeld).

## Snel starten

```bash
pip install -r requirements.txt
python scripts/build.py          # bouwt dist/index.html
node --test tests/*.test.js      # controleert de generator op voorbeeld 26-01697
```

Open daarna `dist/index.html` in een browser. Er is geen server nodig.

## Mappen

| Map | Inhoud |
|---|---|
| `src/template.html` | De pagina: opmaak, formulier en generator-logica. Hier werk je meestal in. |
| `data/catalogus.json` | Alle variabelen uit de catalogus (10 datasets, 1684 items). |
| `config/datasets.json` | Per dataset: naam, ICD-codes, `tumsoort`-code, kernmacro en kernbestand voor SAS. |
| `config/itemsets.json` | Links naar itemsets voor tumorsoorten zonder catalogus-dataset. |
| `scripts/scrape_catalogus.py` | Haalt de catalogus opnieuw op en schrijft `data/catalogus.json`. |
| `scripts/build.py` | Voegt template, data en config samen tot `dist/index.html`. |
| `sas/voorbeelden/` | Geanonimiseerde, goedgekeurde SAS-scripts als referentie voor de prompt. |
| `tests/` | Tests van de generator, met een lokale kopie van de catalogus (Borst). |
| `docs/` | Ontwerpkeuzes, bevindingen en open punten. |

## Catalogus bijwerken

```bash
python scripts/scrape_catalogus.py
python scripts/build.py
```

Controleer de diff van `data/catalogus.json` in je pull request: zo zie je welke variabelen erbij of af zijn gegaan.

## Samenwerken

- Werk in een branch en open een pull request; de workflow bouwt de pagina en draait de tests.
- Nieuwe tumorsoort: vul `tumsoort`, `kern` en `kernbestand` aan in `config/datasets.json`.
  Zolang die leeg zijn, zet de prompt er `TODO analist` neer.
- Nieuwe voorbeeldscripts: alleen geanonimiseerd (geen namen, geen netwerkpaden, geen aanvragersgegevens).
- Open punten staan in [`docs/roadmap.md`](docs/roadmap.md).

## Privacy

De pagina bevat geen patiëntgegevens en stuurt niets naar een server. Concepten worden alleen in de
browser van de gebruiker bewaard (`localStorage`).
