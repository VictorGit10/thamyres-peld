# ==============================================================================
# codigo/03b_atribuir_locais.py
# Atribuicao espacial point-in-polygon para TODAS as tabelas de observacao
# declaradas em dicionario_colunas.csv (nao apenas GBIF).
# Le os nomes de lat/lon do dicionario, faz o sjoin com as malhas do IBGE e
# grava id_local, fora_area e sem_coordenada em cada CSV de dados/bruto/.
# ==============================================================================

import csv
import glob
import json
import os
import re

import geopandas as gpd
import pandas as pd

print(">>> Iniciando atribuicao espacial point-in-polygon (GeoPandas)...")

DIR_BRUTO = "dados/bruto"
DIR_MALHAS = os.path.join(DIR_BRUTO, "malhas")
DICIONARIO = "dicionario_colunas.csv"

# ------------------------------------------------------------------------------
# 1. Malhas municipais oficiais
# ------------------------------------------------------------------------------
arquivos_geojson = glob.glob(os.path.join(DIR_MALHAS, "*.geojson"))
if not arquivos_geojson:
    raise FileNotFoundError("Nenhum GeoJSON encontrado em dados/bruto/malhas/")

mun_dfs = []
for p in arquivos_geojson:
    gdf = gpd.read_file(p)
    cod = os.path.splitext(os.path.basename(p))[0]
    gdf["codigo_ibge"] = str(cod)
    mun_dfs.append(gdf)

muns_gdf = pd.concat(mun_dfs, ignore_index=True)
if muns_gdf.crs is None:
    muns_gdf.set_crs(epsg=4326, inplace=True)
else:
    muns_gdf = muns_gdf.to_crs(epsg=4326)

mapa_municipios = {
    "5204409": {"id_local": "LOC_CAI", "nome": "Caiapônia"},
    "5211909": {"id_local": "LOC_JAT", "nome": "Jataí"},
    "5213103": {"id_local": "LOC_MIN", "nome": "Mineiros"},
    "5216452": {"id_local": "LOC_PER", "nome": "Perolândia"},
    "5218805": {"id_local": "LOC_RVE", "nome": "Rio Verde"},
    "5220504": {"id_local": "LOC_SER", "nome": "Serranópolis"},
}

muns_gdf["id_local_poly"] = muns_gdf["codigo_ibge"].apply(
    lambda c: mapa_municipios[c]["id_local"]
)
muns_gdf["municipio_poly"] = muns_gdf["codigo_ibge"].apply(
    lambda c: mapa_municipios[c]["nome"]
)
muns_gdf = muns_gdf[["codigo_ibge", "id_local_poly", "municipio_poly", "geometry"]]

# ------------------------------------------------------------------------------
# 2. Descobrir tabelas e colunas de lat/lon pelo dicionario
# ------------------------------------------------------------------------------
with open(DICIONARIO, "r", encoding="utf-8", newline="") as f:
    dic = list(csv.DictReader(f))

fontes = {}
for row in dic:
    if row.get("tabela_destino") != "observacao":
        continue
    tab = row.get("tabela_origem")
    campo = row.get("campo_destino")
    origem = row.get("campo_origem")
    if tab and campo in ("lat", "lon") and origem:
        fontes.setdefault(tab, {})[campo] = origem

print("Tabelas de observacao declaradas no dicionario:", sorted(fontes))

# ------------------------------------------------------------------------------
# 3. Processar cada arquivo em dados/bruto/
# ------------------------------------------------------------------------------
resumo_espacial = []

for tab, cols in sorted(fontes.items()):
    caminho = os.path.join(DIR_BRUTO, f"{tab}.csv")
    if not os.path.exists(caminho):
        print(f"  [{tab}] nao encontrado em dados/bruto/; pulando.")
        continue

    lat_col = cols.get("lat")
    lon_col = cols.get("lon")
    if not lat_col or not lon_col:
        print(f"  [{tab}] sem par lat/lon no dicionario; pulando.")
        continue

    df = pd.read_csv(caminho, low_memory=False)
    if lat_col not in df.columns or lon_col not in df.columns:
        print(f"  [{tab}] colunas '{lat_col}'/'{lon_col}' ausentes; pulando.")
        continue

    total_linhas = len(df)
    lat_num = pd.to_numeric(df[lat_col], errors="coerce")
    lon_num = pd.to_numeric(df[lon_col], errors="coerce")
    sem_coords_mask = lat_num.isna() | lon_num.isna()
    sem_coords_count = int(sem_coords_mask.sum())

    df_valid = df[~sem_coords_mask].copy()
    pts_gdf = gpd.GeoDataFrame(
        df_valid,
        geometry=gpd.points_from_xy(
            pd.to_numeric(df_valid[lon_col]),
            pd.to_numeric(df_valid[lat_col]),
        ),
        crs="EPSG:4326",
    )

    joined = gpd.sjoin(pts_gdf, muns_gdf, how="left", predicate="intersects")
    joined = joined[~joined.index.duplicated(keep="first")]

    # Limpa flags antigas, se o pipeline for rodado de novo
    for col in ("id_local", "codigo_ibge_spatial", "municipio_spatial",
                "fora_area", "sem_coordenada"):
        if col in df.columns:
            df = df.drop(columns=[col])

    df["id_local"] = None
    df["codigo_ibge_spatial"] = None
    df["municipio_spatial"] = None
    df["fora_area"] = True
    df["sem_coordenada"] = False

    df.loc[sem_coords_mask, "sem_coordenada"] = True
    df.loc[joined.index, "id_local"] = joined["id_local_poly"].values
    df.loc[joined.index, "codigo_ibge_spatial"] = joined["codigo_ibge"].values
    df.loc[joined.index, "municipio_spatial"] = joined["municipio_poly"].values

    dentro_mask = df["id_local"].notna()
    df.loc[dentro_mask, "fora_area"] = False

    dentro_count = int(dentro_mask.sum())
    fora_count = total_linhas - dentro_count - sem_coords_count

    df.to_csv(caminho, index=False, encoding="utf-8")
    print(
        f"  [{tab}] Total: {total_linhas} | Dentro: {dentro_count} | "
        f"Fora: {fora_count} | Sem coord: {sem_coords_count}"
    )

    contagens = df.loc[dentro_mask, "municipio_spatial"].value_counts().to_dict()
    grupo = "Flora" if re.search(r"flora|veget|planta", tab) else (
        "Fauna" if re.search(r"fauna|ave|mam|bicho|animal", tab) else "Indeterminado"
    )

    resumo_espacial.append({
        "tabela": tab,
        "grupo": grupo,
        "arquivo": caminho,
        "total_registros": total_linhas,
        "dentro_6_municipios": dentro_count,
        "fora_6_municipios": fora_count,
        "sem_coordenadas": sem_coords_count,
        "detalhe_por_municipio": contagens,
    })

# ------------------------------------------------------------------------------
# 4. Relatorios
# ------------------------------------------------------------------------------
os.makedirs("saidas", exist_ok=True)

df_resumo_csv = pd.DataFrame([
    {
        "tabela": r["tabela"],
        "grupo": r["grupo"],
        "total_registros": r["total_registros"],
        "dentro_6_municipios": r["dentro_6_municipios"],
        "fora_6_municipios": r["fora_6_municipios"],
        "sem_coordenadas": r["sem_coordenadas"],
        "pct_aproveitamento": round(
            (r["dentro_6_municipios"] / r["total_registros"]) * 100, 2
        ) if r["total_registros"] else 0,
    }
    for r in resumo_espacial
])
df_resumo_csv.to_csv(
    "saidas/resumo_espacializacao.csv", index=False, encoding="utf-8"
)

with open("saidas/resumo_espacializacao.json", "w", encoding="utf-8") as f:
    json.dump(resumo_espacial, f, indent=2, ensure_ascii=False)

print("Atribuicao espacial concluida com sucesso!")
