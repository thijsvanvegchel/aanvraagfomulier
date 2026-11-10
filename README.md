# Roadmap en open punten

## Bevindingen uit voorbeeld 26-01697

- 64 van de 66 geleverde variabelen hebben in de catalogus exact dezelfde naam als in het SAS-script.
  De `%let variabelen`-lijst kan dus rechtstreeks uit de keuzes van de aanvrager komen.
- `leeft_cat` is afgeleid van `leeft` (via `%leeft_cat`); dat regelt de generator.
- `horm_stop_int` wordt wel geleverd, maar staat niet in de catalogus.
- Morfologiecode 8520 (lobulair) ontbreekt in de waardelijst `morf` van dataset Borst.
- Het script maakt oksel-echo leeg voor diagnoses vóór 2014; de catalogus noemt hetzelfde jaar.
  Zulke beschikbaarheidsregels kunnen al in het formulier worden gemeld.

## Kort

- [x] Meerdere tumorsoorten in één aanvraag; per variabele zichtbaar in welke tumorsoorten hij bestaat.
- [x] Koppeling met andere bronnen (o.a. PROFIEL voor vermoeidheid en kwaliteit van leven).
- [ ] Per tumorsoort aparte selectie op morfologie en stadium (nu één selectie voor alle gekozen tumorsoorten).

- [ ] `tumsoort`, `kern` en `kernbestand` invullen voor de 9 datasets naast Borst (`config/datasets.json`).
- [ ] Catalogus aanvullen: `horm_stop_int`, volledige waardelijst `morf`.
- [ ] Vaste delen van het SAS-script (header, libnames, standaardselectie, sleutels, export, data dictionary)
      als sjabloon genereren, zonder taalmodel. De prompt alleen voor afgeleide variabelen en aanvullende wensen.
- [ ] Twee of drie geanonimiseerde voorbeeldscripts toevoegen per tumorsoort.
- [ ] Geaggregeerde levering uitwerken (nu alleen een TODO in de prompt).

## Middellang

- [ ] Grove telling: vooraf berekende tabel per DWH-release (tumorsoort × incidentiejaar × geslacht ×
      leeftijdscategorie × gedrag × stadiumgroep × morfologiegroep), afgerond op 50, kleine aantallen als "< 50".
      Nagaan of NKR Cijfers deze telling al heeft.
- [ ] Specificatie-JSON koppelen aan het bestaande formulier en Dynamics (velden vastleggen).
- [ ] Itemsets als tabel beschikbaar maken, zodat ook tumorsoorten zonder catalogus-dataset gekozen kunnen worden.

## Klantportaal

- [ ] Inloggen: stap 1 overslaan voor terugkerende aanvragers.
- [ ] Update van een eerdere aanvraag: kies de aanvraag en toon alleen het verschil (bijv. "+ morf 8500").
- [ ] Vragen en antwoorden met de analist in het portaal, met versies van de specificatie.
- [ ] Status per fase met verwachte datum; data dictionary al vóór levering inzien.
