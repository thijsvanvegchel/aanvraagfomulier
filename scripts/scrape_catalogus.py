"""Haalt de NKR-datacatalogus op en schrijft data/catalogus.json.

Gebruik:
    python scripts/scrape_catalogus.py              # alle datasets online ophalen
    python scripts/scrape_catalogus.py --file X.html --dataset Borst   # één lokaal bestand parsen (tests)

Per variabele: categorie, naam, label, toelichting, herleidbaarheidsnoot en waardelijst.
"""
import argparse
import json
import re
import sys
from pathlib import Path

from bs4 import BeautifulSoup

BASE = "https://as-nkr-catalogus-2023-prod.azurewebsites.net/"
DATASETS = ["Borst", "CRC", "Cervix", "Endometrium", "HPB", "Long",
            "MaagSlokdarm", "Ovarium", "Prostaat", "Vulva"]
ROOT = Path(__file__).resolve().parent.parent


def _first_text(td):
    """Eerste tekstnode van een cel (de naam of het label, zonder tooltip of uitklapdeel)."""
    for node in td.children:
        if isinstance(node, str) and node.strip():
            return node.strip()
    return ""


def parse(html):
    soup = BeautifulSoup(html, "html.parser")
    out = []
    for tr in soup.find_all("tr"):
        tds = tr.find_all("td", recursive=False)
        if len(tds) < 5 or not tds[0].find("input", {"type": "checkbox"}):
            continue
        name_td, label_td, val_td = tds[2], tds[3], tds[4]
        tip = name_td.find("a", class_="tooltip")
        hidden = label_td.find("div", style=re.compile(r"display:\s*none"))
        values = []
        table = val_td.find("table", class_="value-table")
        if table and table.tbody:
            for row in table.tbody.find_all("tr"):
                cells = row.find_all("td")
                if len(cells) >= 2:
                    values.append([cells[0].get_text(strip=True), cells[1].get_text(strip=True)])
        out.append({
            "c": tds[1].get_text(strip=True),
            "n": _first_text(name_td),
            "l": _first_text(label_td),
            "x": re.sub(r"\s+", " ", hidden.get_text(" ")).strip() if hidden else "",
            "w": tip.get("data-title", "") if tip else "",
            "v": values,
            # De catalogus toont bij lange lijsten maar een selectie ("de tabel toont een selectie van 12 waarden").
            "s": bool(re.search(r"selectie van \d+ waarden", val_td.get_text(" "))),
        })
    return out


def dumps(result):
    """Eén variabele per regel, zodat een git-diff per variabele leesbaar is."""
    parts = []
    for ds, items in result.items():
        rows = ",\n".join("  " + json.dumps(x, ensure_ascii=False) for x in items)
        parts.append(f"{json.dumps(ds)}: [\n{rows}\n]")
    return "{\n" + ",\n".join(parts) + "\n}\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file")
    ap.add_argument("--dataset")
    ap.add_argument("--out", default=str(ROOT / "data" / "catalogus.json"))
    a = ap.parse_args()
    if a.file:
        result = {a.dataset or Path(a.file).stem: parse(Path(a.file).read_text(encoding="utf-8"))}
    else:
        import requests
        result = {}
        for ds in DATASETS:
            r = requests.get(f"{BASE}{ds}.html", timeout=60)
            r.raise_for_status()
            r.encoding = "utf-8"
            result[ds] = parse(r.text)
            print(f"{ds}: {len(result[ds])} variabelen", file=sys.stderr)
    Path(a.out).write_text(dumps(result), encoding="utf-8")


if __name__ == "__main__":
    main()
