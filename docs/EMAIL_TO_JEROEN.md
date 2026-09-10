# Email Draft: Case Study para Jeroen Janssens

**To:** jeroen@jeroenjanssens.com
**Subject:** Case study inspired by "Data Science at the Command Line"

---

Hi Jeroen,

I'm Anakin, a data engineer from Brazil. I've been building a local-first database for AI agents called YodaDB, heavily inspired by your work — especially "Data Science at the Command Line" and your PhD research on Stochastic Outlier Selection (scikit-sos).

I wanted to share a case study we built applying your principles to a real-world problem: detecting rogue AI agents via statistical outlier detection at the edge.

**The problem:**
AI agents are escaping containers and processing sensitive data without local auditing (OpenClaw, rogue OpenAI agents from recent AI Reports).

**The approach:**
A pure Unix pipeline that sanitizes PII before persistence, then detects anomalous agent behavior via z-score > 3:

    cat agent_logs.tsv | ./yoda-shield | ./yodadb put 1
    ./yoda-stats outliers payload_length

**The result:**
- 200 agents ingested (195 normal + 5 rogue detected)
- Zero PII reaching disk (verified via grep -r)
- 100% Unix (C11 + Bash + DuckDB, no Python in core)
- 18KB binary, zero cloud dependencies

Full case study: docs/CASE_OUTLIER_DETECTION.md
Reproducible demo: ./demo-rogue-agent.sh

Would love your feedback on whether this aligns with your philosophy. No ask — just wanted to share what we built inspired by your work.

Thanks for the inspiration,
Anakin (Obi-Wan's apprentice)

---

## Notes for sending

1. Find Jeroen's email:
   - https://jeroenjanssens.com (contact page)
   - Bluesky: @jeroenjanssens.com
   - LinkedIn: /in/jeroenjanssens

2. Before sending, make repo public:
   - Create GitHub repo: yoda-systems/yodadb
   - Push all code + docs

3. Send from personal email (not work)
   - Subject line matters most
   - Keep it brief (< 200 words)
   - Include GitHub link
   - No ask, just sharing

4. Follow up in 7 days if no response
   - One polite reminder
   - Then move on
