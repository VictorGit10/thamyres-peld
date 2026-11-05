# ==============================================================================
# codigo/03_paisagem_gee.py
# Calcula metricas de paisagem do MapBiomas Colecao 11 no Google Earth Engine
# Extrai cobertura para municipio inteiro e buffers de 5 km e 10 km ao redor do centroide
# Anos: 2015, 2020, 2024
# ==============================================================================

import os
import json
import time
import pandas as pd
import ee

print(">>> Inicializando Google Earth Engine e processando paisagem...")

gee_project = os.environ.get("GEE_PROJECT", "SEU-PROJETO-EARTH-ENGINE")
print(f"Usando projeto Google Earth Engine: {gee_project}")
ee.Initialize(project=gee_project)

# Ler tabela de municipios
df_locais = pd.read_csv("dados/bruto/municipios_locais.csv")

# Asset MapBiomas Colecao 11
asset_id = "projects/mapbiomas-public/assets/brazil/lulc/collection11/mapbiomas_brazil_collection11_coverage_v3"
mapbiomas = ee.Image(asset_id)

anos = [2015, 2020, 2024]

# Classes MapBiomas segundo PEDIDO.md
# Vegetacao nativa: 3, 4, 11, 12, 29
# Pastagem: 15
# Agricultura: 18, 19, 20, 36, 39, 40, 41, 46, 47, 48
# Urbano: 24
# Agua: 33
classes_nativa = [3, 4, 11, 12, 29]
classes_pastagem = [15]
classes_agri = [18, 19, 20, 36, 39, 40, 41, 46, 47, 48]
classes_urbano = [24]
classes_agua = [33]

pixel_area_km2 = ee.Image.pixelArea().divide(1e6)

resultados = []

for _, row in df_locais.iterrows():
    id_local = row['id_local']
    nome_mun = row['municipio']
    cod_ibge = str(row['codigo_ibge'])
    
    # Carrega GeoJSON salvo pelo script 02
    geojson_path = f"dados/bruto/malhas/{cod_ibge}.geojson"
    with open(geojson_path, "r", encoding="utf-8") as f:
        geo_dict = json.load(f)
    
    geom_mun = ee.Geometry(geo_dict['features'][0]['geometry'])
    # Centroide exato
    centroid_pt = ee.Geometry.Point([float(row['lon']), float(row['lat'])])
    
    geometrias_escala = [
        {"buffer_m": 0, "geom": geom_mun, "label": "Municipio Inteiro"},
        {"buffer_m": 5000, "geom": centroid_pt.buffer(5000), "label": "Buffer 5 km"},
        {"buffer_m": 10000, "geom": centroid_pt.buffer(10000), "label": "Buffer 10 km"}
    ]
    
    for ano in anos:
        band_name = f"classification_{ano}"
        img_ano = mapbiomas.select(band_name)
        
        # Mascaras
        mask_nativa = img_ano.remap(classes_nativa, [1]*len(classes_nativa), 0)
        mask_pastagem = img_ano.remap(classes_pastagem, [1]*len(classes_pastagem), 0)
        mask_agri = img_ano.remap(classes_agri, [1]*len(classes_agri), 0)
        mask_urbano = img_ano.remap(classes_urbano, [1]*len(classes_urbano), 0)
        mask_agua = img_ano.remap(classes_agua, [1]*len(classes_agua), 0)
        
        img_metricas = ee.Image.cat([
            pixel_area_km2.rename("total_km2"),
            mask_nativa.multiply(pixel_area_km2).rename("nativa_km2"),
            mask_pastagem.multiply(pixel_area_km2).rename("pastagem_km2"),
            mask_agri.multiply(pixel_area_km2).rename("agri_km2"),
            mask_urbano.multiply(pixel_area_km2).rename("urbano_km2"),
            mask_agua.multiply(pixel_area_km2).rename("agua_km2")
        ])
        
        for esc in geometrias_escala:
            buf = esc["buffer_m"]
            g = esc["geom"]
            label = esc["label"]
            
            # Executa reducao
            # Buffer usa escala 30m; municipio inteiro usa 60m para eficiencia e robustez
            scale_res = 30 if buf > 0 else 60
            stats = img_metricas.reduceRegion(
                reducer=ee.Reducer.sum(),
                geometry=g,
                scale=scale_res,
                maxPixels=1e9
            ).getInfo()
            
            total_km2 = stats.get("total_km2", 0) or 0
            nativa_km2 = stats.get("nativa_km2", 0) or 0
            pastagem_km2 = stats.get("pastagem_km2", 0) or 0
            agri_km2 = stats.get("agri_km2", 0) or 0
            urbano_km2 = stats.get("urbano_km2", 0) or 0
            agua_km2 = stats.get("agua_km2", 0) or 0
            
            soma_conhecida = nativa_km2 + pastagem_km2 + agri_km2 + urbano_km2 + agua_km2
            outras_km2 = max(0.0, total_km2 - soma_conhecida)
            
            pct_nativa = (nativa_km2 / total_km2 * 100) if total_km2 > 0 else 0
            pct_pastagem = (pastagem_km2 / total_km2 * 100) if total_km2 > 0 else 0
            pct_agri = (agri_km2 / total_km2 * 100) if total_km2 > 0 else 0
            pct_urbano = (urbano_km2 / total_km2 * 100) if total_km2 > 0 else 0
            pct_agua = (agua_km2 / total_km2 * 100) if total_km2 > 0 else 0
            pct_outras = (outras_km2 / total_km2 * 100) if total_km2 > 0 else 0
            
            resultados.append({
                "id_local": id_local,
                "municipio": nome_mun,
                "codigo_ibge": cod_ibge,
                "ano": ano,
                "buffer_m": buf,
                "escala_label": label,
                "area_nativa_km2": round(nativa_km2, 3),
                "area_pastagem_km2": round(pastagem_km2, 3),
                "area_agricultura_km2": round(agri_km2, 3),
                "area_urbano_km2": round(urbano_km2, 3),
                "area_agua_km2": round(agua_km2, 3),
                "area_outras_km2": round(outras_km2, 3),
                "area_total_km2": round(total_km2, 3),
                "pct_nativa": round(pct_nativa, 2),
                "pct_pastagem": round(pct_pastagem, 2),
                "pct_agricultura": round(pct_agri, 2),
                "pct_urbano": round(pct_urbano, 2),
                "pct_agua": round(pct_agua, 2),
                "pct_outras": round(pct_outras, 2)
            })
            print(f"  {nome_mun} ({ano}, buf={buf}m): Nativa={pct_nativa:.1f}%, Pasto={pct_pastagem:.1f}%, Agri={pct_agri:.1f}%")

df_out = pd.DataFrame(resultados)
caminho_csv = "dados/bruto/paisagem.csv"
df_out.to_csv(caminho_csv, index=False, encoding="utf-8")
print(f"Sucesso! Metricas de paisagem salvas em {caminho_csv} ({len(df_out)} linhas).")

# Atualiza fontes.json
fontes_path = "dados/bruto/fontes.json"
if os.path.exists(fontes_path):
    with open(fontes_path, "r", encoding="utf-8") as f:
        fontes = json.load(f)
else:
    fontes = {}

fontes["mapbiomas_gee"] = {
    "data_execucao": time.strftime("%Y-%m-%d %H:%M:%S"),
    "asset": asset_id,
    "anos": anos,
    "escalas_buffer_m": [0, 5000, 10000],
    "classes": {
        "nativa": classes_nativa,
        "pastagem": classes_pastagem,
        "agricultura": classes_agri,
        "urbano": classes_urbano,
        "agua": classes_agua
    },
    "total_combinacoes": len(df_out)
}

with open(fontes_path, "w", encoding="utf-8") as f:
    json.dump(fontes, f, indent=2, ensure_ascii=False)
print("Fontes atualizadas em fontes.json.")
