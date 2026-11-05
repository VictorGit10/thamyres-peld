# Correções restantes após a 2ª conferência

O pacote já tem o motor de dicionário, o teste `10_teste_dicionario.R`, o point-in-polygon para os CSVs do GBIF e a verificação numérica. Ainda faltam estes pontos para o fluxo do README funcionar com as planilhas da pesquisadora e para não haver afirmações maiores que o código.

## 1. O fluxo completo com uma tabela da pesquisadora (bloqueador)

O `README.md` manda colocar `minhas_aves.csv` em `dados/bruto/`, preencher o dicionário e rodar `03b` + `05`. O `05` já itera sobre o dicionário, mas o fluxo ainda quebra num ponto: `codigo/03b_atribuir_locais.py` só lê `gbif_flora.csv` e `gbif_fauna.csv` e só conhece `decimalLatitude`/`decimalLongitude`. A tabela da pesquisadora não recebe `id_local`/`fora_area`; o `05` a trata como fora da área e a exclui.

Faça o fluxo funcionar de ponta a ponta:
- O `03b` deve iterar sobre as `tabela_origem` do dicionário que tenham campos `lat`/`lon` (descobrir os nomes de origem no dicionário), ler cada CSV em `dados/bruto/`, fazer o `sjoin` com as malhas e gravar `id_local`, `fora_area`, `sem_coordenada` em cada arquivo. Não restrinja a GBIF.
- O `05` continua iterando sobre `unique(dicionario$tabela_origem)` (exceto `dados/exemplo` no run principal) e mapeando cada tabela para `observacao`.
- Crie um teste de integração em pasta temporária (ou um modo `--teste`) que copia `dados/exemplo/minha_flora.csv` para `dados/bruto/minha_flora.csv`, roda `03b` + `05` + `06` e verifica que as 6 linhas aparecem no banco canônico. Não deixe esse arquivo no run principal depois do teste.

## 2. Dicionário sem erro de parsing

O `dicionario_colunas.csv` tem descrições com vírgulas não citadas (ex.: `(2015, 2020, 2024)`); o `readr` emite warning e o pandas falha. Regrave o CSV com `readr::write_csv` (ou cite todos os campos com vírgula) e garanta que `read_csv` lê sem `problems()`. O `10_teste` não pode imprimir warning de parsing.

## 3. Contagens da auditoria e dos textos

O `saidas/resumo_auditoria.csv` atual tem 12 linhas e soma **8.613** ocorrências; o `ROTEIRO-ENCONTRO.md` e o `REVISAO-ALVO.md` ainda dizem **6.872** e **9 tipos**. Atualize os textos para o número atual (ou remova o total e fale em “principais diagnósticos”). Inclua essa checagem no `11_verificar_numeros.R`.

## 4. Amostra, não universo

O `01_baixar_gbif.R` baixa 1.500 registros por grupo (5 páginas de 300 na flora; 3+2 na fauna), mas o `RELATORIO.md`, o `README.md` e o `REVISAO-ALVO.md` dizem “3.000 registros” sem “amostra”. O universo da consulta é maior (≈10.109 flora e ≈52.016 fauna; confirme com a API e salve `total_disponivel` no `fontes.json`). Diga em todos os textos: **amostra de 1.500 por grupo, páginas iniciais, não aleatória; não representa o universo**. O `11` deve checar esse texto ou o `fontes.json`.

## 5. Portabilidade para a máquina dela

- `codigo/00_instalar.R` e `R/funcoes.R` ainda têm `<usuário>/AppData/Local/R/win-library/4.6`. Use `Sys.getenv("R_LIBS_USER")` (com fallback para `.libPaths()[1]`) e não crie a pasta “amara” na máquina dela. O `CLAUDE.md` pode manter o caminho desta máquina como exemplo, mas o código não.
- `codigo/03_paisagem_gee.py` ainda tem `ee.Initialize(project='SEU-PROJETO-EARTH-ENGINE')`. Use `os.environ.get("GEE_PROJECT", "SEU-PROJETO-EARTH-ENGINE")` e documente no README: `set GEE_PROJECT=seu-projeto`.
- O `README.md` deve dizer o que ela precisa mudar (projeto GEE, biblioteca R) e o que já funciona.

## 6. Textos que ainda exageram

- `RELATORIO.md`: “11_verificar_numeros.R garante que 100% das métricas” → o script confere os números-chave listados, não todas as métricas. Troque por “os números-chave listados”.
- `RELATORIO.md` / tabela: a linha “TOTAL / MÉDIA” de PIB per capita é a média simples das seis razões (94.149,12); o total ponderado seria `sum(PIB)/sum(população)`. Diga “média simples” ou mostre o valor ponderado.
- `CORRECOES-REVISAO.md`: remova duplicações e não afirme que algo foi feito se o código não tem (ex.: `id_especie`/`ESP_001` e `ordem` — confira o `especie.csv`/SQLite antes de escrever). Registre o que ficou como próximo passo.

## 7. Fechamento

Rode `Rscript codigo/99_rodar_tudo.R`, `Rscript codigo/10_teste_dicionario.R` e `Rscript codigo/11_verificar_numeros.R`; atualize `RELATORIO.md`, `README.md`, `ROTEIRO-ENCONTRO.md`, `REVISAO-ALVO.md`, `esquema.sql`, `CLAUDE.md` e `CORRECOES-REVISAO.md`. Todo número novo deve sair de script. Não invente.
