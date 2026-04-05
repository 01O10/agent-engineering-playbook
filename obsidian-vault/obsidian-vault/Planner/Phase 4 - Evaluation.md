---
tags: [agent-engineering, planner, phase-4]
---

# Phase 4 — Evaluation

← [[00 - Index]]

---

## e1: Manual trace review (20-50 traces)

- **Complexity:** 2/5 · **Variability:** Predictable
- **Participants:** 2 — Prompt & Eval Eng + Domain Expert
- **Skills:** ML engineering, domain expertise, patience
- **Dependencies:** b4
- **Scope drivers:** Number of traces to review — more traces = more signal but linear effort

Run agent on realistic tasks. Read every trace. Annotate. For open-weights: watch for tool-call parse failures, context overflows, stop-token issues.

> [!check] Done when
> 20+ traces reviewed with pass/fail and failure reasons

**Deliverable:** Annotated trace review

---

## e2: Build failure taxonomy

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2-3 — Prompt & Eval Eng + Domain Expert
- **Skills:** ML engineering, domain expertise, analytical thinking
- **Dependencies:** e1
- **Scope drivers:** Failure diversity, domain specificity, model behavior novelty

Open coding from traces. Categories: prompt, tool design, model limitation, data gap, infrastructure, routing error. Include domain expert for domain-specific failures.

> [!check] Done when
> Stable — 5 additional traces produce no new categories

**Deliverable:** Failure Taxonomy

---

## e3: Build eval dataset

- **Complexity:** 3/5 · **Variability:** Highly variable
- **Participants:** 2-3 — Prompt & Eval Eng + Domain Expert + Agent Product Mgr
- **Skills:** ML engineering, domain expertise, eval design
- **Dependencies:** d11, e2
- **Scope drivers:** Number of task types, domain complexity, need for domain expert involvement

20-50 hand-reviewed cases. Positive AND negative. Unambiguous criteria. Reference solutions. Domain expert validates domain-specific cases.

> [!check] Done when
> 'Two experts agree' test passed; domain expert approved domain cases

**Deliverable:** Eval dataset (versioned)

---

## e4: Build automated eval runner + software tests

- **Complexity:** 4/5 · **Variability:** Highly variable
- **Participants:** 2-3 — Harness Eng + Prompt & Eval Eng + Agent Ops Eng
- **Skills:** Backend engineering, ML engineering, DevOps
- **Dependencies:** e3
- **Scope drivers:** Eval complexity, number of metrics, state-change verification needs, CI integration

Eval automation at chosen level with metrics tracking. PLUS unit tests for tool handlers, integration tests for tool chains, and load tests for concurrent sessions.

> [!check] Done when
> Eval runs unattended; unit/integration tests pass; load test benchmarks documented

**Deliverable:** Eval suite + test suite

---

## e5: Run model-powered tool optimization

- **Complexity:** 2/5 · **Variability:** Variable
- **Participants:** 1-2 — Prompt & Eval Eng
- **Skills:** ML engineering, prompt engineering
- **Dependencies:** e4
- **Scope drivers:** Number of tools to optimize, transcript volume

Concatenate transcripts → model analyzes → fix contradictions → re-run evals. At least one full cycle.

> [!check] Done when
> Improvement measurable in eval metrics

**Deliverable:** Optimized tools with before/after metrics

---

## e6: Establish baseline metrics

- **Complexity:** 1/5 · **Variability:** Predictable
- **Participants:** 1 — Prompt & Eval Eng
- **Skills:** ML engineering
- **Dependencies:** e4
- **Scope drivers:** Minimal — run suite and record results

Run full suite. Record: pass rate, tokens/completion, cost, latency, failure modes. This is the regression gate.

> [!check] Done when
> Baseline documented; regression eval alerts on >5% degradation

**Deliverable:** Baseline Metrics Report

---

