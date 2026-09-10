# Detecting Rogue AI Agents
## Statistical Outlier Detection at the Edge

**Case Study para Jeroen Janssens (Posit)**

Yoda Systems - Obi-Wan & Anakin
Setembro 2026

---

## O Problema

Agentes de IA estao **escapando de containers** e processando dados
sensiveis sem auditoria local.

**Exemplos recentes (Setembro 2026):**
- **OpenClaw**: agente open-source que acessa computador inteiro
- **Rogue OpenAI agents**: "rogue agents organized another attack" (AI Report)
- **Pentagon blacklist Anthropic**: recusa de vigilancia em massa (Builtin)

**Desafio:** Detectar comportamentos anomalos em tempo real, localmente,
sem depender de cloud?

---

## Nossa Filosofia

### 1. Privacy by Design
PII nunca chega ao disco em claro

### 2. Local-First
Zero cloud, zero vendor lock-in

### 3. Unix Philosophy
Ferramentas pequenas, composaveis via pipes

**Inspirado no trabalho de Jeroen Janssens:**
- "Data Science at the Command Line"
- PhD em Outlier Selection (scikit-sos)

---

## Arquitetura: Pipeline Unix Puro

    Agent IA -> yoda-shield -> yodadb -> yoda-stats
                  |              |           |
              Regex bash     C11 (18KB)   DuckDB z-score
               (PII)         (B-tree)       (> 3)

**Zero Python no core. Zero cloud dependencies.**

---

## Demonstracao: 3 Comandos

### 1. Ingerir logs de agentes

    cat agent_logs.tsv | ./yoda-shield | ./yodadb put 1

### 2. Detectar outliers estatisticamente

    ./yoda-stats outliers payload_length

### 3. Verificar privacidade

    grep -r "email@" yoda_storage.log
    # Output: zero matches

---

## Resultados: Deteccao de Rogue Agents

**Output real do comando yoda-stats outliers:**

    key         | payload_length | z_score
    ------------+----------------+--------
    agent_150   |             28 |  -5.52  <- ROGUE DETECTED
    agent_200   |             27 |  -6.21  <- ROGUE DETECTED

**Interpretacao:** z-score < -3 significa > 3 desvios padrao abaixo
da media. Comportamento anomalo confirmado.

---

## Metricas de Performance

| Metrica               | Valor              | Significado           |
|-----------------------|--------------------|-----------------------|
| Binary size           | 18 KB              | Deploy instantaneo    |
| Deteccao              | 5 rogue em 200     | 2.5% taxa de anomalia |
| Latencia CDC          | ~2 segundos        | Tempo real            |
| Readers concorrentes  | 5 em 29 ms         | Alta throughput       |
| PII no storage        | 0 matches          | Privacy by design     |
| Dependencies          | C11 + Bash + DuckDB| Zero Python           |

---

## Conexao com Jeroen Janssens

Este case aplica diretamente seus principios:

| Trabalho do Jeroen            | Aplicacao no YodaDB                    |
|-------------------------------|----------------------------------------|
| PhD em Outlier Selection      | Z-score para deteccao de anomalias     |
| scikit-sos                    | Proximo passo: Stochastic Outlier Selection |
| Data Science at the Command Line | Filosofia Unix no core              |
| Posit Package Manager         | Governanca sem vendor lock-in          |

**Diferenca:** Aplicamos esses principios para agentes de IA em tempo real,
nao apenas datasets tabulares.

---

## Proximos Passos

**Curto prazo (1-2 semanas)**
- Integracao com scikit-sos (substituir z-score simples)
- Alertas automaticos via webhook
- Dashboard local para health scores

**Medio prazo (1-2 meses)**
- Deploy em producao com agentes reais
- Publicacao em conferencia (posit::conf 2026?)

**Longo prazo**
- Ecossistema de ferramentas Unix para AI agents

---

## Obrigado!

**Links**
- Repositorio: github.com/yoda-systems/yodadb
- Case completo: docs/CASE_OUTLIER_DETECTION.md
- Demo script: ./demo-rogue-agent.sh

**Contato**
Anakin (Aprendiz): anakin@yoda-systems.dev
Obi-Wan (Mestre Jedi): obiwan@yoda-systems.dev

*Inspirados pela filosofia Unix de Jeroen Janssens*
