# Referências Bibliográficas

Todas as referências abaixo foram consultadas e validadas diretamente contra a API oficial da Crossref (`https://api.crossref.org/works/<doi>`) pelo script [`codigo/verificar_dois.py`](codigo/verificar_dois.py). Nenhuma referência foi inventada ou incluída sem validação automatizada de título e periódico.

---

### 1. Wieczorek et al. (2012)
- **Título:** *Darwin Core: An Evolving Community-Developed Biodiversity Data Standard*
- **Periódico:** PLoS ONE, 7(1): e29715.
- **DOI:** [`10.1371/journal.pone.0029715`](https://doi.org/10.1371/journal.pone.0029715)
- **Por que está aqui:** Define o padrão internacional de termos e campos do Darwin Core (DwC), utilizado na estruturação e padronização das ocorrências de flora e fauna do GBIF.

### 2. Souza Jr. et al. (2020)
- **Título:** *Reconstructing Three Decades of Land Use and Land Cover Changes in Brazilian Biomes with Landsat Archive and Earth Engine*
- **Periódico:** Remote Sensing, 12(17): 2735.
- **DOI:** [`10.3390/rs12172735`](https://doi.org/10.3390/rs12172735)
- **Por que está aqui:** Apresenta a metodologia de classificação da cobertura e uso da terra do MapBiomas no Google Earth Engine, fonte dos dados de paisagem em 2015, 2020 e 2024.

### 3. Zizka et al. (2019)
- **Título:** *CoordinateCleaner: Standardized cleaning of occurrence records from biological collection databases*
- **Periódico:** Methods in Ecology and Evolution, 10(5): 744–751.
- **DOI:** [`10.1111/2041-210X.13152`](https://doi.org/10.1111/2041-210X.13152)
- **Por que está aqui:** Fornece a base teórica e os limiares práticos para auditoria de coordenadas geográficas de herbários e museus (detecção de centroides municipais, coordenadas (0,0) e alta incerteza).

### 4. Wickham (2014)
- **Título:** *Tidy Data*
- **Periódico:** Journal of Statistical Software, 59(10): 1–23.
- **DOI:** [`10.18637/jss.v059.i10`](https://doi.org/10.18637/jss.v059.i10)
- **Por que está aqui:** Fundamenta o princípio de conversão de planilhas largas (wide) para tabelas canônicas longas (uma observação por linha), eliminando ambiguidades e permitindo junções relacionais seguras.

### 5. Lindenmayer & Likens (2009)
- **Título:** *Adaptive monitoring: a new paradigm for long-term research and monitoring*
- **Periódico:** Trends in Ecology & Evolution, 24(9): 482–486.
- **DOI:** [`10.1016/j.tree.2009.03.005`](https://doi.org/10.1016/j.tree.2009.03.005)
- **Por que está aqui:** Discute o desenho amostral e a governança de dados em redes de monitoramento de longo prazo (PELD / LTER), ressaltando a necessidade de metadados estáveis de esforço amostral.

### 6. Turner (1989)
- **Título:** *Landscape Ecology: The Effect of Pattern on Process*
- **Periódico:** Annual Review of Ecology and Systematics, 20: 171–197.
- **DOI:** [`10.1146/annurev.es.20.110189.001131`](https://doi.org/10.1146/annurev.es.20.110189.001131)
- **Por que está aqui:** Estabelece a estrutura conceitual para a análise espacial de métricas de paisagem (remanescentes nativos, matriz agrícola) e sua dependência de escala e resolução.

### 7. Jelinski & Wu (1996)
- **Título:** *The modifiable areal unit problem and implications for landscape ecology*
- **Periódico:** Landscape Ecology, 11(3): 129–140.
- **DOI:** [`10.1007/BF02447512`](https://doi.org/10.1007/BF02447512)
- **Por que está aqui:** Explica o Problema da Unidade de Área Modificável (MAUP) na ecologia da paisagem, demonstrando por que as métricas mudam drasticamente entre o recorte municipal e buffers locais (5 km e 10 km).

### 8. Piantadosi, Byar & Green (1988)
- **Título:** *The Ecological Fallacy*
- **Periódico:** American Journal of Epidemiology, 127(5): 893–904.
- **DOI:** [`10.1093/oxfordjournals.aje.a114892`](https://doi.org/10.1093/oxfordjournals.aje.a114892)
- **Por que está aqui:** Formaliza a impossibilidade estatística de deduzir comportamentos de indivíduos ou propriedades rurais a partir de correlações em dados municipais agregados (falácia ecológica).
