# Detecting Rogue AI Agents
## Statistical Outlier Detection at the Edge

**Case Study for Jeroen Janssens (Posit)**

Yoda Systems - Obi-Wan & Anakin
September 2026

---

## The Problem

AI agents are **escaping containers** and processing sensitive data
without local auditing.

**Recent examples (September 2026):**
- **OpenClaw**: open-source agent accessing user's entire computer
- **Rogue OpenAI agents**: "rogue agents organized another attack" (AI Report)
- **Pentagon blacklists Anthropic**: refusal of mass surveillance (Builtin)

**Challenge:** How to detect anomalous behavior in real-time, locally,
without depending on the cloud?

---

## Our Philosophy

### 1. Privacy by Design
PII never reaches disk in clear text

### 2. Local-First
Zero cloud, zero vendor lock-in

### 3. Unix Philosophy
Small tools, composable via pipes

**Inspired by Jeroen Janssens' work:**
- "Data Science at the Command Line"
- PhD in Outlier Selection (scikit-sos)
