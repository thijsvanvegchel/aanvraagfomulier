"""Bouwt dist/index.html uit src/template.html, data/catalogus.json en config/datasets.json.

Gebruik:  python scripts/build.py
Het resultaat is één zelfstandig HTML-bestand zonder server of build-stap aan de kant van de gebruiker.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Beschikbaarheid wordt alleen gelezen uit zinnen met het woord 'beschikbaar',
# zodat jaartallen in andere toelichting (zoals TNM-edities) niet meetellen.
RE_VAN_TOT = re.compile(r"beschikbaar\s+van\s+(\d{4})\s+tot(?: en met)?\s+(\d{4})", re.I)
RE_VANAF = re.compile(r"beschikbaar\s+vanaf\s+(\d{4})", re.I)
RE_TOT = re.compile(r"beschikbaar\s+tot(?: en met)?\s+(\d{4})", re.I)


def availability(text):
    m = RE_VAN_TOT.search(text)
    if m:
        return int(m.group(1)), int(m.group(2))
    a = RE_VANAF.search(text)
    b = RE_TOT.search(text)
    return (int(a.group(1)) if a else None), (int(b.group(1)) if b else None)


def compact(catalogus):
    """Compacte vorm voor de pagina: [categorie, naam, label, toelichting, noot, waarden, vanaf, tot]."""
    out = {}
    for ds, items in catalogus.items():
        rows = []
        for x in items:
            van, tot = availability(x["x"])
            rows.append([x["c"], x["n"], x["l"], x["x"][:260], x["w"], x["v"], van, tot])
        out[ds] = rows
    return out


def build():
    cat = json.loads((ROOT / "data" / "catalogus.json").read_text(encoding="utf-8"))
    datasets = json.loads((ROOT / "config" / "datasets.json").read_text(encoding="utf-8"))
    missing = set(datasets) - set(cat)
    if missing:
        raise SystemExit(f"Datasets in config maar niet in catalogus: {sorted(missing)}")
    html = (ROOT / "src" / "template.html").read_text(encoding="utf-8")
    dump = lambda o: json.dumps(o, ensure_ascii=False, separators=(",", ":"))
    for key, value in {
        "/*__DATA__*/": dump(compact(cat)),
        "/*__DATASETS__*/": dump(datasets),
    }.items():
        if key not in html:
            raise SystemExit(f"Placeholder {key} ontbreekt in src/template.html")
        html = html.replace(key, value)
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    (dist / "index.html").write_text(html, encoding="utf-8")
    script = html.split("<script>", 1)[1].rsplit("</script>", 1)[0]
    (dist / "app.js").write_text(script, encoding="utf-8")  # alleen voor tests en syntaxcontrole
    print(f"dist/index.html gebouwd ({len(html) // 1024} kB, {sum(len(v) for v in cat.values())} variabelen)")


if __name__ == "__main__":
    build()
