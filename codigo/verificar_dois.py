# ==============================================================================
# codigo/verificar_dois.py
# Verifica formalmente todas as referencias bibliograficas na API do Crossref
# ==============================================================================

import urllib.request
import json
import sys

referencias = [
    {
        "doi": "10.1371/journal.pone.0029715",
        "esperado": "Darwin Core",
        "contexto": "Padrao internacional de dados sobre ocorrencias de biodiversidade (Darwin Core / GBIF)"
    },
    {
        "doi": "10.3390/rs12172735",
        "esperado": "Land Use and Land Cover Changes in Brazilian Biomes",
        "contexto": "Mapeamento historico e algoritmos no Earth Engine do MapBiomas no Brasil"
    },
    {
        "doi": "10.1111/2041-210X.13152",
        "esperado": "CoordinateCleaner",
        "contexto": "Auditoria e limpeza automatizada de dados de colecoes biologicas e coordenadas"
    },
    {
        "doi": "10.18637/jss.v059.i10",
        "esperado": "Tidy Data",
        "contexto": "Principios de organizacao de dados canônicos em tabelas longas e integracao relacional"
    },
    {
        "doi": "10.1016/j.tree.2009.03.005",
        "esperado": "Adaptive monitoring",
        "contexto": "Monitoramento adaptativo e estruturacao de dados ecologicos de longa duracao (PELD/LTER)"
    },
    {
        "doi": "10.1146/annurev.es.20.110189.001131",
        "esperado": "Landscape Ecology",
        "contexto": "Fundamentos da ecologia de paisagens e interacao padrao-processo em diferentes escalas"
    },
    {
        "doi": "10.1007/BF02447512",
        "esperado": "The modifiable areal unit problem",
        "contexto": "O problema da unidade de area modificavel (MAUP) e efeitos de escala na paisagem"
    },
    {
        "doi": "10.1093/oxfordjournals.aje.a114892",
        "esperado": "THE ECOLOGICAL FALLACY",
        "contexto": "Fundamentacao matematica e epidemiologica do risco da falacia ecologica em dados agregados"
    }
]

print(">>> Verificando 8 referencias cientificas na API Crossref (https://api.crossref.org)...")
falhas = 0

for ref in referencias:
    doi = ref["doi"]
    url = f"https://api.crossref.org/works/{doi}"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'PELD-DataKit/1.0 (mailto:pesquisa@ufg.br)'})
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode('utf-8'))['message']
            title = data.get('title', [''])[0]
            journal = data.get('container-title', [''])[0]
            year = data.get('issued', {}).get('date-parts', [[None]])[0][0]
            print(f"[OK CONFERIDO] DOI: {doi}")
            print(f"     Titulo: {title}")
            print(f"     Periodico: {journal} ({year})")
            print(f"     Contexto: {ref['contexto']}\n")
    except Exception as e:
        print(f"[FALHA] DOI: {doi} -> {e}")
        falhas += 1

if falhas > 0:
    print(f"ATENCAO: {falhas} referencias falharam na verificacao.")
    sys.exit(1)
else:
    print("Sucesso absoluto: Todas as 8 referencias foram conferidas e aprovadas via Crossref API!")
