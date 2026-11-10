#!/usr/bin/env python3
"""Gera lib/data/mock/district_seeds.dart.

Consulta o OpenStreetMap (Overpass e Nominatim) uma vez e, para cada um dos 96
distritos de São Paulo, sorteia pontos de descarte DENTRO do distrito, bem
espalhados entre si. Pontos conhecidos (terminais, parques, praças) entram no
distrito onde de fato caem. O app não usa este script: só o arquivo gerado.

Uso:  python tool/gerar_distritos.py
"""

import json
import math
import random
import time
import urllib.parse
import urllib.request
from pathlib import Path

# Identificação exigida pela política de uso das APIs do OpenStreetMap.
USER_AGENT = "ReciclaRadarSP/1.0 (https://github.com/jumarques03/recicla-radar-sp)"
CITY_RELATION = 298285  # município de São Paulo no OSM
CITY_CENTER = (-23.5505, -46.6333)  # Praça da Sé
SEED = 2026
OUTPUT = Path(__file__).resolve().parent.parent / "lib" / "data" / "mock" / "district_seeds.dart"

# nome, latitude, longitude, intensidade (1 a 10). Posições aproximadas.
LANDMARKS = [
    ("Terminal Jabaquara", -23.6679, -46.6410, 9),
    ("Feira livre do Jabaquara", -23.6420, -46.6430, 6),
    ("Largo da Batata", -23.5662, -46.6913, 9),
    ("Praça Benedito Calixto", -23.5630, -46.6836, 7),
    ("Av. Faria Lima", -23.5700, -46.6930, 8),
    ("Estação Mooca", -23.5586, -46.5997, 6),
    ("Rua da Mooca", -23.5600, -46.5990, 6),
    ("Praça da Sé", -23.5505, -46.6333, 10),
    ("Mercado Municipal", -23.5416, -46.6297, 9),
    ("Rua 25 de Março", -23.5440, -46.6310, 10),
    ("Parque Dom Pedro II", -23.5430, -46.6280, 7),
    ("Terminal Santo Amaro", -23.6560, -46.7100, 8),
    ("Largo Treze de Maio", -23.6537, -46.7090, 7),
    ("Terminal Itaquera", -23.5400, -46.4710, 8),
    ("Arena Corinthians", -23.5453, -46.4742, 7),
    ("Parque do Carmo", -23.5793, -46.4640, 5),
    ("Largo do Rosário da Penha", -23.5280, -46.5440, 6),
    ("Terminal Santana", -23.4990, -46.6250, 7),
    ("Rua Voluntários da Pátria", -23.5050, -46.6280, 6),
    ("Largo da Lapa", -23.5220, -46.7040, 7),
    ("Terminal Lapa", -23.5223, -46.7020, 7),
    ("Parque Ibirapuera", -23.5874, -46.6576, 9),
    ("Metrô Vila Mariana", -23.5890, -46.6340, 6),
    ("Cidade Universitária (USP)", -23.5600, -46.7300, 7),
    ("Terminal Campo Limpo", -23.6240, -46.7570, 6),
    ("Terminal Capão Redondo", -23.6590, -46.7790, 5),
]

POINT_TYPES = [
    "Praça central",
    "Feira livre",
    "Terminal de ônibus",
    "Avenida principal",
    "Mercado",
    "Parque",
]


def http_json(url, data=None):
    body = urllib.parse.urlencode(data).encode() if data else None
    request = urllib.request.Request(url, data=body, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=180) as response:
        return json.loads(response.read())


def fetch_district_ids():
    query = (
        "[out:json][timeout:90];"
        f"area({3600000000 + CITY_RELATION})->.sp;"
        'rel(area.sp)["boundary"="administrative"]["admin_level"="9"];'
        "out ids tags;"
    )
    elements = http_json("https://overpass-api.de/api/interpreter", {"data": query})["elements"]
    return [element["id"] for element in elements]


def fetch_polygons(ids):
    """Devolve {id: (nome, [(anel externo, [buracos])])} usando o Nominatim."""
    result = {}
    for start in range(0, len(ids), 50):
        batch = ids[start : start + 50]
        params = urllib.parse.urlencode(
            {
                "osm_ids": ",".join(f"R{i}" for i in batch),
                "format": "geojson",
                "polygon_geojson": 1,
                "polygon_threshold": 0.0005,
                "accept-language": "pt-BR",
            }
        )
        data = http_json("https://nominatim.openstreetmap.org/lookup?" + params)
        for feature in data["features"]:
            props = feature["properties"]
            geometry = feature["geometry"]
            parts = [geometry["coordinates"]] if geometry["type"] == "Polygon" else geometry["coordinates"]
            polygons = [
                ([(p[0], p[1]) for p in part[0]], [[(p[0], p[1]) for p in hole] for hole in part[1:]])
                for part in parts
            ]
            result[props["osm_id"]] = (props["name"], polygons)
        time.sleep(1.2)  # no máximo 1 requisição por segundo
    return result


def inside_ring(lng, lat, ring):
    inside = False
    j = len(ring) - 1
    for i in range(len(ring)):
        xi, yi = ring[i]
        xj, yj = ring[j]
        if (yi > lat) != (yj > lat) and lng < (xj - xi) * (lat - yi) / (yj - yi) + xi:
            inside = not inside
        j = i
    return inside


def inside(lng, lat, polygons):
    for outer, holes in polygons:
        if inside_ring(lng, lat, outer) and not any(inside_ring(lng, lat, hole) for hole in holes):
            return True
    return False


def km_between(a, b):
    """Distância aproximada em km entre dois pontos (lat, lng)."""
    dlat = (a[0] - b[0]) * 110.57
    dlng = (a[1] - b[1]) * 111.32 * math.cos(math.radians((a[0] + b[0]) / 2))
    return math.hypot(dlat, dlng)


def area_km2(polygons):
    total = 0.0
    for outer, holes in polygons:
        for index, ring in enumerate([outer] + holes):
            s = 0.0
            for i in range(len(ring)):
                x1, y1 = ring[i]
                x2, y2 = ring[(i + 1) % len(ring)]
                s += x1 * y2 - x2 * y1
            lat = sum(p[1] for p in ring) / len(ring)
            k = 111.32 * math.cos(math.radians(lat)) * 110.57
            total += (1 if index == 0 else -1) * abs(s) / 2 * k
    return total


def candidates(polygons, rng, count=400):
    """Pontos sorteados dentro do distrito, longe da borda (~250 m)."""
    xs = [p[0] for outer, _ in polygons for p in outer]
    ys = [p[1] for outer, _ in polygons for p in outer]
    result = []
    for _ in range(count * 40):
        lng = rng.uniform(min(xs), max(xs))
        lat = rng.uniform(min(ys), max(ys))
        margin = 0.0025
        ring_ok = all(
            inside(lng + dx, lat + dy, polygons)
            for dx, dy in ((margin, 0), (-margin, 0), (0, margin), (0, -margin))
        )
        if inside(lng, lat, polygons) and ring_ok:
            result.append((lat, lng))
            if len(result) >= count:
                break
    return result


def spread(pool, chosen, wanted):
    """Escolhe pontos do pool o mais longe possível uns dos outros."""
    chosen = list(chosen)
    picked = []
    while pool and len(picked) < wanted:
        if chosen:
            best = max(pool, key=lambda c: min(km_between(c, o) for o in chosen))
        else:
            best = pool[0]
        picked.append(best)
        chosen.append(best)
        pool = [c for c in pool if c != best]
    return picked


def label_point(pool, polygons):
    """Ponto para o rótulo do distrito: o mais central entre os candidatos."""
    if not pool:
        outer = polygons[0][0]
        return (sum(p[1] for p in outer) / len(outer), sum(p[0] for p in outer) / len(outer))
    cx = sum(c[1] for c in pool) / len(pool)
    cy = sum(c[0] for c in pool) / len(pool)
    return min(pool, key=lambda c: (c[1] - cx) ** 2 + (c[0] - cy) ** 2)


def target_points(area):
    if area < 8:
        return 2
    if area < 25:
        return 3
    return 4


def dart_string(text):
    return text.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")


def main():
    rng = random.Random(SEED)
    print("Buscando os distritos no Overpass (pode levar ~1 min)...")
    ids = fetch_district_ids()
    print(f"{len(ids)} distritos. Buscando os polígonos no Nominatim...")
    polygons = fetch_polygons(ids)

    districts = sorted(((i, polygons[i][0], polygons[i][1]) for i in ids), key=lambda d: d[1])
    assigned = {i: [] for i in ids}
    for name, lat, lng, intensity in LANDMARKS:
        for osm_id, _, shape in districts:
            if inside(lng, lat, shape):
                assigned[osm_id].append((name, lat, lng, intensity))
                break
        else:
            print("  aviso: fora de qualquer distrito:", name)

    lines = []
    total_points = 0
    for osm_id, name, shape in districts:
        pool = candidates(shape, rng)
        landmarks = assigned[osm_id]
        wanted = max(target_points(area_km2(shape)), len(landmarks))
        generated = spread(pool, [(lat, lng) for _, lat, lng, _ in landmarks], wanted - len(landmarks))
        points = list(landmarks)
        kinds = rng.sample(POINT_TYPES, len(generated))  # sem repetir no distrito
        for (lat, lng), kind in zip(generated, kinds):
            dist = km_between((lat, lng), CITY_CENTER)
            intensity = int(round(8.5 - dist * 0.3 + rng.uniform(-1.2, 1.2)))
            points.append((f"{kind} de {name}", lat, lng, max(2, min(8, intensity))))
        total_points += len(points)
        lat, lng = label_point(pool, shape)
        point_lines = "\n".join(
            f"      ('{dart_string(n)}', {la:.5f}, {lo:.5f}, {it})," for n, la, lo, it in points
        )
        lines.append(
            f"  ({osm_id}, '{dart_string(name)}', {lat:.5f}, {lng:.5f}, [\n{point_lines}\n  ]),"
        )

    content = (
        "// GERADO por tool/gerar_distritos.py. Não edite à mão: rode o script de novo.\n"
        "//\n"
        "// Cada distrito de São Paulo (relação do OpenStreetMap), com o ponto do rótulo e\n"
        "// os pontos de descarte que ficam dentro dele.\n\n"
        "typedef PointSeed = (String name, double lat, double lng, int intensity);\n"
        "typedef DistrictSeed = (\n"
        "  int osmId,\n"
        "  String name,\n"
        "  double lat,\n"
        "  double lng,\n"
        "  List<PointSeed> points,\n"
        ");\n\n"
        "const List<DistrictSeed> districtSeeds = [\n" + "\n".join(lines) + "\n];\n"
    )
    OUTPUT.write_text(content, encoding="utf-8", newline="\n")
    print(f"Gerado {OUTPUT} com {len(districts)} distritos e {total_points} pontos.")


if __name__ == "__main__":
    main()
