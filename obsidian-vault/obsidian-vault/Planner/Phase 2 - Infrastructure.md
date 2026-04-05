---
tags: [agent-engineering, planner, phase-2]
---

# Phase 2 — Infrastructure

← [[00 - Index]]

---

## i1: Provision local dev environment

- **Complexity:** 1/5 · **Variability:** Predictable
- **Participants:** 1 — Harness Eng
- **Skills:** Backend engineering
- **Scope drivers:** Stack familiarity, package availability

Set up local agent runtime: SDK installed, personal API key or local model running (Ollama/LM Studio), sample data, basic trace output. Every developer should be able to run the agent locally in <30 min.

> [!check] Done when
> New developer follows guide, runs agent, gets output within 30 min

**Deliverable:** Local setup guide + working local agent

---

## i2: Provision staging environment

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2 — Agent Ops Eng + Harness Eng
- **Skills:** DevOps, security engineering
- **Dependencies:** d10
- **Scope drivers:** Data sensitivity, infrastructure complexity

Shared environment with realistic (sanitized) data. Same model stack as production. Proper secrets manager. Structured tracing visible to team. CI/CD deploys harness changes. Limited scaling (1-3 instances).

> [!check] Done when
> Agent runs on staging; traces visible to team; CI/CD deploys changes

**Deliverable:** Running staging environment

---

## i3: Provision production environment

- **Complexity:** 4/5 · **Variability:** Variable
- **Participants:** 2-3 — Agent Ops Eng + SRE + Harness Eng
- **Skills:** DevOps, SRE, cloud architecture
- **Dependencies:** i2
- **Scope drivers:** Scaling requirements, HA needs, compliance constraints

Production compute with auto-scaling, persistent storage, HTTPS, monitoring integration. Blue-green or canary deployment capability. Separate from staging with promotion gate.

> [!check] Done when
> Auto-scaling verified; deployment pipeline tested; monitoring connected

**Deliverable:** Production environment ready for deployment

---

## i4a: Configure model access (API path)

- **Complexity:** 1/5 · **Variability:** Predictable
- **Participants:** 1 — Harness Eng
- **Skills:** Backend engineering
- **Dependencies:** d3
- **Scope drivers:** SDK familiarity, API documentation quality

API keys in secrets manager, SDK installed, caching configured, rate limits set. Verify cache headers working. Set up failover (secondary model/provider if primary is down).

> [!check] Done when
> API call succeeds; cache confirmed; failover tested

**Deliverable:** Working API connection with caching + failover

---

## i4b: Set up model serving (self-hosted path)

- **Complexity:** 4/5 · **Variability:** Highly variable
- **Participants:** 2 — Model Ops Eng + Prompt & Eval Eng
- **Skills:** MLOps, GPU infrastructure, model optimization
- **Dependencies:** d3
- **Scope drivers:** Model size, GPU availability, quantization needs, throughput requirements

Deploy model serving (vLLM/TGI/Ollama). Configure GPU allocation, quantization, context window, KV-cache. Benchmark throughput and latency. Secure endpoint (not publicly accessible).

> [!check] Done when
> Latency p50/p95 documented; throughput meets requirements; endpoint secured

**Deliverable:** Running inference endpoint with benchmarks

---

## i4c: Fine-tune for function calling (if needed)

- **Complexity:** 4/5 · **Variability:** Highly variable
- **Participants:** 2 — Prompt & Eval Eng + Model Ops Eng
- **Skills:** ML engineering, fine-tuning, dataset curation
- **Dependencies:** i4b
- **Scope drivers:** Model capability gap, fine-tuning dataset availability, evaluation criteria

If open-weights model lacks native tool calling: fine-tune on function-calling datasets. Validate parse success rate >90%. Set up chat templates with tool-call special tokens.

> [!check] Done when
> 20 tool-calling test cases pass with >90% parse rate

**Deliverable:** Fine-tuned model with verified tool calling

---

## i5: Set up observability stack

- **Complexity:** 2/5 · **Variability:** Predictable
- **Participants:** 1-2 — Agent Ops Eng
- **Skills:** DevOps, observability engineering
- **Dependencies:** i4a||i4b
- **Scope drivers:** Tracing tool choice, integration points

Tracing infrastructure producing searchable traces for every run. Annotation queues for trace review. Works identically for API and self-hosted models.

> [!check] Done when
> 5 test runs produce complete, reviewable traces

**Deliverable:** Tracing pipeline with annotation

---

## i6: Set up data pipeline (if RAG/knowledge base)

- **Complexity:** 4/5 · **Variability:** Highly variable
- **Participants:** 2-3 — Data Eng + Harness Eng + Prompt & Eval Eng
- **Skills:** Data engineering, search/retrieval, NLP
- **Dependencies:** d7
- **Scope drivers:** Number of data sources, document types, embedding quality, freshness requirements

Document ingestion pipeline (parsers, chunkers, embedding generation). Scheduled re-indexing for freshness. PII detection/redaction if needed. Data residency compliance.

> [!check] Done when
> 10 test documents ingested; retrievable via search; freshness schedule configured

**Deliverable:** Working data pipeline with test ingestion

---

## i7: Set up auth and identity

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2 — Security Eng + Harness Eng
- **Skills:** Security engineering, backend engineering
- **Dependencies:** d8
- **Scope drivers:** Auth provider complexity, number of tenants, compliance requirements

User auth (OAuth/SSO) flowing through to tool calls. Agent service credentials with appropriate scopes. Multi-tenancy data isolation if needed. Audit logging.

> [!check] Done when
> User A's actions use A's credentials; A cannot access B's data; audit log captures all actions

**Deliverable:** Auth system with verified isolation

---

## i8: Set up harness version control

- **Complexity:** 1/5 · **Variability:** Predictable
- **Participants:** 1 — Harness Eng
- **Skills:** Backend engineering
- **Scope drivers:** Minimal — standard git setup

Git repo for all harness artifacts: prompts, config, skills, tool definitions, eval datasets, permission matrix.

> [!check] Done when
> All artifacts versioned; PR workflow established

**Deliverable:** Repo with documented structure

---

