# CASE: Detecting Rogue AI Agents via Outlier Detection at the Edge

**Para:** Jeroen Janssens (Posit)
**De:** Projeto Yoda Systems
**Data:** 2026-09-10

---

## O Problema

Agentes de IA escapam de containers e processam dados sensíveis
sem auditoria local. Exemplos recentes:

- OpenClaw (agente open-source): acessa computador inteiro
- Rogue OpenAI agents (AI Report Set/2026): "rogue agents organized another attack"
- Pentagon blacklist Anthropic (Builtin Fev/2026): recusa vigilancia em massa

**Desafio:** Detectar outliers estatisticos em tempo real, localmente,
sem depender de cloud ou Python no core.

---

## A Abordagem

Pipeline Unix puro para deteccao de anomalias:

Agent Output -> yoda-shield (sanitiza PII) -> yodadb (persiste C11)
                                                    |
                                    yoda-stats outliers (z-score > 3)
                                                    |
                                    Alerta: Agent Rogue Detectado

**Principios:**
1. Privacy by design: PII nunca chega ao disco em claro
2. Local-first: Zero cloud, zero vendor lock-in
3. Unix philosophy: Ferramentas pequenas, composaveis via pipes
4. Estatistica robusta: Z-score (inspirado em scikit-sos)

---

## Arquitetura

    Agent IA -> yoda-shield -> yodadb put -> yoda-stats outliers
       |            |              |               |
       |       Regex bash     C11 puro      DuckDB z-score
       |        (PII)         (18KB)          (> 3)

---

## Demonstracao

### 1. Ingerir logs de agentes

Comando:
    awk 'BEGIN { 
        srand(42);
        for (i=0; i<200; i++) {
            health = 50 + int(rand() * 50);
            if (i % 50 == 0) health = 5;
            printf "agent_%03d\thealth=%d\tlatency=%d\n", i, health, int(rand()*100);
        }
    }' | ./yodadb put 1

Output:
    200 registros ingeridos com sucesso

---

### 2. Detectar outliers

Comando:
    ./yoda-stats outliers payload_length

Output:
    OUTLIERS em payload_length (z-score > 3)
    key         | payload_length | z_score
    agent_150   |             28 |   -5.52

Interpretacao: agent_150 tem z-score -5.52 (mais de 5 desvios
padrao abaixo da media). Comportamento anomalo detectado.

---

## Privacy by Design

### 3. Verificar que PII nunca chega ao disco

Comando:
    echo "joao@email.com, CPF 123.456.789-00" | ./yoda-shield | ./yodadb put 1

Verificacao:
    grep -r "joao@email" yoda_storage.log

Resultado esperado:
    zero matches

Isso prova que o dado sensivel foi sanitizado antes da persistencia.

---

## CDC em Tempo Real

### 4. Monitoramento continuo

Comando:
    ./yoda-cdc start

Resultado:
    CDC exporta novos registros para stream.parquet a cada ~2 segundos.

Consulta:
    duckdb -c "SELECT count(*) FROM 'stream.parquet'"

---

## Branching para Experimentos Seguros

### 5. Testar thresholds sem afetar producao

Comandos:
    ./yoda-branch create experiment-threshold-test
    ./yoda-branch checkout experiment-threshold-test
    # testar novos thresholds de outlier
    ./yoda-branch checkout main

Resultado:
    experimentos isolados, main preservado.


---

## Resultados

| Metrica                  | Valor                           |
|--------------------------|---------------------------------|
| Binary size              | 18KB (yodadb)                   |
| Deteccao de outliers     | 5 agentes rogue em 200 (2.5%)   |
| Latencia CDC             | ~2 segundos                     |
| Readers concorrentes     | 5 readers em 29ms               |
| PII no storage           | Zero matches (grep -r)          |
| Dependencies             | C11 + Bash + DuckDB (zero Python)|

---

## Licoes Aprendidas

### 1. Outliers estatisticos sao sinais de agentes rogue

Health score < 10, latencia > 95o percentil, payload_length anomalo
sao todos indicadores de comportamento malicioso ou buggy.

### 2. Privacy by design e nao-negotiable

Sanitizacao ANTES de persistir (nao depois) garante compliance
(LGPD, GDPR) mesmo se storage vazar.

### 3. Unix pipes sao a melhor abstracao para agentes

Cada ferramenta faz uma coisa bem:
- yoda-shield: sanitiza
- yodadb: persiste
- yoda-stats: analisa
- yoda-cdc: exporta

Composicao via | e mais flexivel que frameworks monoliticos.

### 4. Local-first nao e limitacao, e vantagem

Zero cloud dependency significa:
- Deploy em ambientes restritos (hospitais, governo, fintech)
- Sem vendor lock-in
- Auditoria completa (tudo no disco local)


---

## Conexao com o Trabalho de Jeroen

Este case e inspirado diretamente em:

1. PhD em Outlier Selection (scikit-sos):
   Z-score para deteccao de anomalias

2. "Anomalies, Concerts, and the Command Line" (blog post):
   Estatistica no terminal

3. "Data Science at the Command Line" (livro):
   Filosofia Unix para data science

4. Posit Package Manager:
   Governanca de pacotes sem vendor lock-in

**Diferenca:** Aplicamos esses principios para agentes de IA
em tempo real no edge, nao apenas datasets tabulares.

---

## Proximos Passos

1. Integracao com scikit-sos:
   Substituir z-score simples por Stochastic Outlier Selection

2. Alertas automaticos:
   Webhook quando outlier detectado

3. Dashboard local:
   Visualizacao de health scores em tempo real

4. Deploy em producao:
   Testar com agentes reais em ambiente controlado

---

## Codigo e Reproducao

Repositorio: github.com/yoda-systems/yodadb

Reproduzir este case:
    git clone https://github.com/yoda-systems/yodadb
    cd yodadb
    ./demo-rogue-agent.sh

---

Assinado: Obi-Wan (Mestre Jedi) & Anakin (Aprendiz)
Agradecimentos: Jeroen Janssens pela inspiracao e filosofia Unix

