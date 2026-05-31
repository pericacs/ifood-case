# iFood Case Técnico - Data Architect

## Objetivo

Este projeto realiza a ingestão, armazenamento, transformação e disponibilização para consumo dos dados de corridas de Yellow Taxi da cidade de Nova York, referentes ao período de janeiro a maio de 2023.

A solução foi desenvolvida utilizando Databricks, PySpark, Delta Lake e Unity Catalog, seguindo arquitetura Medalhão.

---

## Arquitetura

```text
NYC TLC Open Data
        ↓
Landing Zone - Volume
workspace.raw.landing_zone
        ↓
Bronze
workspace.bronze.yellow_taxi_trips
        ↓
Silver
workspace.silver.yellow_taxi_trips
        ↓
Gold
workspace.gold.*
        ↓
SQL Analytics
```

---

## Tecnologias

| Tecnologia              | Uso                            |
| ----------------------- | ------------------------------ |
| Databricks Free Edition | Ambiente de processamento      |
| PySpark                 | Ingestão e transformação       |
| Delta Lake              | Tabelas transacionais          |
| Unity Catalog           | Governança e metadados         |
| SQL                     | Consumo analítico              |
| Parquet                 | Formato dos arquivos de origem |

---

## Estrutura do Repositório

```text
ifood-case/
├── src/
│   ├── raw/
│   ├── bronze/
│   ├── silver/
│   └── gold/
├── analysis/
│   └── analysis_questions.sql
├── README.md
└── requirements.txt
```

---

## Estrutura no Databricks

```text
workspace
├── raw
├── bronze
├── silver
└── gold
```

Foi criado um volume para armazenar os arquivos originais:

```sql
CREATE VOLUME workspace.raw.landing_zone;
```

Estrutura da Landing Zone:

```text
/Volumes/workspace/raw/landing_zone/
└── yellow_taxi/
    └── year=2023/
        ├── month=01/
        ├── month=02/
        ├── month=03/
        ├── month=04/
        └── month=05/
```

---

## Camada RAW

Responsável por baixar e armazenar os arquivos originais da NYC TLC sem transformação.

Arquivos carregados:

```text
yellow_tripdata_2023-01.parquet
yellow_tripdata_2023-02.parquet
yellow_tripdata_2023-03.parquet
yellow_tripdata_2023-04.parquet
yellow_tripdata_2023-05.parquet
```

---

## Camada Bronze

Tabela:

```text
workspace.bronze.yellow_taxi_trips
```

Responsável por armazenar os dados brutos em Delta Lake, preservando a estrutura original dos arquivos e adicionando metadados técnicos.

Metadados adicionados:

```text
source_file_month
source_year
source_system
source_entity
ingestion_timestamp
```

Durante a ingestão foi identificado schema drift entre arquivos de meses diferentes. Para resolver isso, os arquivos foram processados individualmente e consolidados com:

```python
unionByName(allowMissingColumns=True)
```

Também foi necessário tratar campos `timestamp_ntz`, convertendo-os na Bronze para evitar incompatibilidade com recursos Delta na edição utilizada.

---

## Camada Silver

Tabela:

```text
workspace.silver.yellow_taxi_trips
```

Responsável por disponibilizar os dados tratados e padronizados para consumo analítico.

Colunas exigidas pelo desafio:

```text
VendorID
passenger_count
total_amount
tpep_pickup_datetime
tpep_dropoff_datetime
```

Na Silver, os campos foram padronizados como:

```text
vendor_id
passenger_count
total_amount
pickup_datetime
dropoff_datetime
```

Colunas derivadas:

```text
pickup_year
pickup_month
pickup_day
pickup_hour
```

Tratamentos aplicados:

* Conversão de tipos.
* Remoção de valores nulos.
* Remoção de registros fora do período solicitado.
* Remoção de valores negativos.
* Padronização das datas.
* Filtro final para janeiro a maio de 2023.

---

## Qualidade dos Dados

Durante a construção da Silver foram encontrados registros fora do período esperado, mesmo dentro dos arquivos de janeiro a maio de 2023.

Exemplos de anos encontrados:

```text
2001
2002
2003
2008
2009
2014
2022
```

Esses registros foram removidos para garantir aderência ao escopo do desafio.

---

## Volume Processado

Após os tratamentos da Silver, foram disponibilizados para consumo analítico:

```text
15.616.382 registros
```

Distribuição por mês:

| Ano  | Mês | Registros |
| ---- | --: | --------: |
| 2023 |  01 | 2.969.826 |
| 2023 |  02 | 2.812.346 |
| 2023 |  03 | 3.286.331 |
| 2023 |  04 | 3.167.803 |
| 2023 |  05 | 3.380.076 |

---

## Camada Gold

A camada Gold foi criada para disponibilizar tabelas analíticas prontas para consumo.

### 1. Média mensal de valor total

Tabela:

```text
workspace.gold.monthly_total_amount_avg
```

Responde à pergunta:

> Qual a média de valor total (`total_amount`) recebido em um mês considerando todos os Yellow Taxis da frota?

---

### 2. Média de passageiros por hora em maio

Tabela:

```text
workspace.gold.may_hourly_passenger_avg
```

Responde à pergunta:

> Qual a média de passageiros (`passenger_count`) por hora do dia no mês de maio considerando todos os táxis da frota?

---

### 3. Resumo executivo

Tabela:

```text
workspace.gold.executive_summary
```

Indicadores consolidados:

| total_trips | avg_total_amount | avg_passenger_count | first_trip          | last_trip           |
| ----------: | ---------------: | ------------------: | ------------------- | ------------------- |
|  15.616.382 |            28.26 |                1.36 | 2023-01-01 00:00:05 | 2023-05-31 23:59:56 |

---

## Resultados das Análises

### Pergunta 1

Qual a média de valor total (`total_amount`) recebido em um mês considerando todos os Yellow Taxis da frota?

| Ano  | Mês | Média total_amount |
| ---- | --: | -----------------: |
| 2023 |  01 |              27.40 |
| 2023 |  02 |              27.31 |
| 2023 |  03 |              28.23 |
| 2023 |  04 |              28.72 |
| 2023 |  05 |              29.38 |

Conclusão:

Foi observada uma tendência de crescimento da média de valor total por corrida entre janeiro e maio de 2023.

A média aumentou de 27.40 em janeiro para 29.38 em maio, representando crescimento aproximado de 7,23%.

---

### Pergunta 2

Qual a média de passageiros (`passenger_count`) por hora do dia durante maio de 2023?

| Hora | Média passenger_count |
| ---: | --------------------: |
|   00 |                  1.41 |
|   01 |                  1.42 |
|   02 |                  1.44 |
|   03 |                  1.44 |
|   04 |                  1.39 |
|   05 |                  1.27 |
|   06 |                  1.23 |
|   07 |                  1.25 |
|   08 |                  1.27 |
|   09 |                  1.28 |
|   10 |                  1.32 |
|   11 |                  1.33 |
|   12 |                  1.35 |
|   13 |                  1.36 |
|   14 |                  1.36 |
|   15 |                  1.37 |
|   16 |                  1.37 |
|   17 |                  1.36 |
|   18 |                  1.36 |
|   19 |                  1.37 |
|   20 |                  1.38 |
|   21 |                  1.40 |
|   22 |                  1.41 |
|   23 |                  1.41 |

Conclusão:

A maior média de passageiros ocorreu às 02h e 03h, com 1.44 passageiros por corrida.

A menor média ocorreu às 06h, com 1.23 passageiros por corrida.

Isso sugere que corridas realizadas durante a madrugada tendem a apresentar maior ocupação média do que corridas realizadas no início da manhã.

---

## Como Executar

1. Criar ou acessar um workspace Databricks com Unity Catalog habilitado.
2. Criar os schemas:

```sql
CREATE SCHEMA IF NOT EXISTS workspace.raw;
CREATE SCHEMA IF NOT EXISTS workspace.bronze;
CREATE SCHEMA IF NOT EXISTS workspace.silver;
CREATE SCHEMA IF NOT EXISTS workspace.gold;
```

3. Criar o volume da landing zone:

```sql
CREATE VOLUME IF NOT EXISTS workspace.raw.landing_zone;
```

4. Executar os notebooks na ordem:

```text
src/raw/01_raw_ingestion
src/bronze/02_bronze_ingestion
src/silver/03_silver_transform
src/gold/04_gold_transform
```

5. Executar as consultas analíticas:

```text
analysis/analysis_questions.sql
```

---

## Decisões Arquiteturais

### Unity Catalog

Utilizado para organizar schemas, tabelas, volumes e metadados.

### Delta Lake

Utilizado para armazenar as camadas Bronze, Silver e Gold com suporte a transações ACID, controle de schema e melhor performance analítica.

### Arquitetura Medalhão

A arquitetura Medalhão foi adotada para separar responsabilidades:

```text
RAW     → arquivos originais
Bronze  → dados brutos com metadados
Silver  → dados tratados e padronizados
Gold    → dados agregados para consumo
```

### Schema Drift

A ingestão foi preparada para lidar com diferenças de schema entre arquivos mensais.

### Qualidade dos Dados

Foram aplicadas validações de período, valores nulos, tipos e consistência dos registros.

---

## Possíveis Evoluções

Em ambiente produtivo, a solução poderia evoluir com:

* Amazon S3 como Data Lake principal.
* Auto Loader para ingestão incremental.
* Delta Live Tables.
* Databricks Workflows.
* CI/CD com GitHub Actions.
* Dashboards em Databricks SQL ou Power BI.
* Monitoramento de qualidade de dados.
* Particionamento e otimização com `OPTIMIZE` e `ZORDER`.

---

# Considerações para Ambiente Produtivo

A solução apresentada foi desenvolvida com foco no atendimento dos requisitos do desafio técnico, priorizando clareza, simplicidade e facilidade de avaliação.

Em um ambiente corporativo, diversas atividades atualmente executadas durante a configuração inicial seriam automatizadas através dos próprios pipelines e mecanismos de infraestrutura como código.

## Provisionamento Automatizado

Neste desafio, os Schemas, Volumes e tabelas foram criados durante o processo de desenvolvimento para facilitar a demonstração da arquitetura proposta.

Em um cenário produtivo, o pipeline seria responsável por validar a existência desses objetos e criá-los automaticamente quando necessário.

Exemplos:

* Criação automática de Schemas no Unity Catalog.
* Criação automática de Volumes.
* Criação automática de tabelas Delta.
* Evolução controlada de Schema (Schema Evolution).
* Registro automático de metadados.

Dessa forma, o ambiente poderia ser provisionado do zero sem necessidade de intervenção manual.

---

## Orquestração End-to-End

A solução poderia ser executada integralmente através de uma única pipeline orquestrada.

Fluxo esperado:

1. Download dos arquivos da NYC TLC.
2. Armazenamento na Landing Zone.
3. Ingestão para Bronze.
4. Tratamento e padronização na Silver.
5. Geração das tabelas analíticas na Gold.
6. Execução de validações de qualidade.
7. Publicação para consumo dos usuários finais.

Em produção, essa orquestração poderia ser implementada utilizando Databricks Workflows, Apache Airflow ou outra ferramenta corporativa equivalente.

---

## Processamento Incremental

Para fins do desafio foi realizado processamento do histórico completo referente ao período solicitado.

Em um ambiente produtivo, a solução seria adaptada para processamento incremental, evitando releitura completa dos dados e reduzindo custos computacionais.

Possíveis abordagens:

* Auto Loader.
* Delta Live Tables.
* CDC (Change Data Capture).
* Controle de Watermark.
* Controle de arquivos processados.

---

## Governança e Observabilidade

Em ambientes corporativos, recomenda-se complementar a solução com mecanismos de governança e monitoramento operacional.

Exemplos:

* Auditoria de execução.
* Controle de lineage.
* Logs estruturados.
* Alertas automáticos.
* Monitoramento de SLA.
* Métricas de qualidade de dados.
* Catálogo corporativo de dados.

O Unity Catalog já fornece uma base sólida para evolução desses controles.

---

## Escalabilidade

A arquitetura foi projetada seguindo conceitos de Data Lakehouse e Arquitetura Medalhão, permitindo crescimento do volume de dados sem necessidade de mudanças estruturais significativas.

A mesma abordagem poderia ser facilmente adaptada para:

* Amazon S3.
* Azure Data Lake Storage.
* Google Cloud Storage.
* Databricks Enterprise.
* Ambientes multi-catálogo e multi-domínio.

---

## Consideração Final

A implementação apresentada foi simplificada para fins de avaliação técnica, porém a arquitetura foi concebida considerando práticas modernas de Engenharia e Arquitetura de Dados, incluindo automação, governança, processamento incremental, observabilidade e escalabilidade normalmente utilizadas em ambientes corporativos.

---

## Conclusão

A solução atende aos requisitos do desafio ao realizar a ingestão dos dados da NYC TLC, armazenar os arquivos originais em uma Landing Zone, transformar os dados com PySpark, disponibilizar tabelas Delta em arquitetura Medalhão e responder às análises solicitadas via SQL.

Além dos requisitos funcionais, a solução inclui decisões voltadas a governança, rastreabilidade, qualidade dos dados, organização em camadas e possibilidade de evolução para um ambiente produtivo.
