---
tags: [agent-engineering, planner, phase-1]
---

# Phase 1 — Discovery & Design

← [[00 - Index]]

---

## d0: Define MVP scope, phase boundaries, and stakeholder alignment

- **Complexity:** 2/5 · **Variability:** Variable
- **Participants:** 3-5 — Agent Product Mgr + Agent Architect + stakeholder reps
- **Skills:** Product management, stakeholder facilitation
- **Scope drivers:** Team size, org politics, number of stakeholders

Before any other design work, decide what's v1 vs v2 vs v3. A reasonable MVP might be: design spec → local env + API → core build (no subagents, no multi-model routing, sync HITL only) → manual eval → ship to internal users. Then layer in: automated evals, staging, async HITL, multi-model routing, production infra. Mark each task in the backlog with its tier (MVP / v2 / scale). This prevents over-engineering the first iteration while ensuring nothing critical is forgotten for later phases. Additionally, identify and align all stakeholders: who will use the agent (end users), who will fund it (sponsors), who will operate it (engineering/ops), who provides domain expertise (SMEs), and who must approve it (compliance/legal). Get explicit sign-off on the MVP scope, expected timeline, and success criteria before proceeding.

> [!check] Done when
> Team agrees on MVP boundary; every backlog task labeled MVP/v2/scale; all stakeholders identified and aligned on scope and timeline

**Deliverable:** Scoped MVP definition with tier labels on all backlog tasks + stakeholder sign-off

---

## d1: Define agency level: deterministic, agentic workflow, or autonomous

- **Complexity:** 2/5 · **Variability:** Predictable
- **Participants:** 2 — Agent Architect + Agent Product Mgr
- **Skills:** System architecture, decision frameworks
- **Dependencies:** d0
- **Scope drivers:** Task clarity and specificity

Analyze task against the agency spectrum. Document where on the spectrum your system should sit and why. Consider whether an agentic workflow (predetermined structure with LLM decisions at key points) suffices, or whether fully autonomous agent reasoning is justified. Document the cost-quality tradeoff.

> [!check] Done when
> Two stakeholders agree on agency level and tradeoff justification

**Deliverable:** Task Fit Document with agency level

---

## d2: Choose architecture pattern

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2-3 — Agent Architect + Prompt & Eval Eng + Harness Eng
- **Skills:** System architecture, agent design patterns
- **Dependencies:** d1
- **Scope drivers:** Number of agent roles, handoff complexity

Single agent, initializer-coder, generator-evaluator, orchestrator-workers, or swarm. Draw topology: agents, responsibilities, handoffs, output schemas.

> [!check] Done when
> Topology reviewed; each agent's role and schema documented

**Deliverable:** Architecture Diagram + Agent Spec

---

## d2b: Evaluate and select agentic framework

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2-3 — Agent Architect + Harness Eng + Prompt & Eval Eng
- **Skills:** System architecture, framework evaluation, prototyping
- **Dependencies:** d2
- **Scope drivers:** Number of candidate frameworks, team familiarity, prototype complexity

Decide whether to use a framework or build from raw API calls. If framework: evaluate options against your architecture pattern, model portfolio, and team skills. Key criteria: model provider support (does it work with your chosen models?), orchestration model (graph-based like LangGraph, role-based like CrewAI, code-first like smolagents?), context management (built-in caching/compaction or manual?), multi-agent support (if your architecture requires it), HITL built-in, MCP integration depth, observability integration, deployment model, licensing, community maturity. Test 2-3 candidates with a minimal prototype of your core use case before committing. If building custom: document which patterns from this guide you'll implement and in what order.

> [!check] Done when
> 2-3 frameworks evaluated against criteria; winner selected with documented rationale; minimal prototype validates core use case works

**Deliverable:** Framework Selection Record with evaluation matrix

---

## d3: Design model portfolio

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2 — Prompt & Eval Eng + Agent Architect
- **Skills:** ML engineering, infrastructure planning
- **Dependencies:** d2
- **Scope drivers:** Number of models, API vs self-hosted mix, hosting complexity

Decide frontier API vs self-hosted open-weights for each agent role. Assign agency level per model tier (router/executor/planner). Design routing architecture (static/LLM-based/complexity-based). If a chatbot layer is needed, specify its model and handoff protocol.

> [!check] Done when
> Each agent role has model + agency level + hosting strategy; routing documented

**Deliverable:** Model Portfolio Document

---

## d4: Design action space

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2-3 — Agent Architect + Harness Eng
- **Skills:** System architecture, tool design
- **Dependencies:** d2
- **Scope drivers:** Number of actions, number of external services

List every action. Assign each to L1 (bound tool) or L2 (via code). Justify each bound tool (security/UX/observability reason).

> [!check] Done when
> Every action classified; total bound tools <15

**Deliverable:** Action Space Spec

---

## d5: Design context strategy

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2 — Prompt & Eval Eng + Agent Architect
- **Skills:** Prompt engineering, context engineering
- **Dependencies:** d4
- **Scope drivers:** Prompt length, number of skills, context budget

Prompt layout order. What goes in system prompt vs config vs skills vs messages. Cache/KV-cache strategy. Compaction approach and buffer.

> [!check] Done when
> Layout with token budget estimates; caching documented

**Deliverable:** Context Strategy Document

---

## d6: Design HITL policy

- **Complexity:** 2/5 · **Variability:** Variable
- **Participants:** 2-3 — Agent Product Mgr + Agent Architect + Agent UX Designer
- **Skills:** Product management, UX design
- **Dependencies:** d4
- **Scope drivers:** Number of action categories, org risk tolerance

For each action category, define intervention level: autonomous, checkpoint-review, pre-approval, or blocked. Decide sync vs async for each. Design the handoff: what does the reviewer see? Specify escalation paths and review SLAs for production.

> [!check] Done when
> Every action category has intervention level; handoff UX spec drafted

**Deliverable:** HITL Policy Document

---

## d7: Design domain knowledge architecture

- **Complexity:** 3/5 · **Variability:** Highly variable
- **Participants:** 3 — Agent Architect + Domain Expert + Data Eng
- **Skills:** Domain expertise, data architecture
- **Dependencies:** d5
- **Scope drivers:** Volume of domain knowledge, number of data sources, regulatory requirements

Audit existing domain knowledge. Assign each knowledge type to the right level: system prompt, config, skill, RAG, or tool description. Plan data ingestion pipeline, freshness cadence, and PII handling. Identify domain experts who will review/approve content.

> [!check] Done when
> Knowledge hierarchy documented; ingestion sources identified; domain expert assigned

**Deliverable:** Knowledge Architecture + Data Pipeline Spec

---

## d8: Design security and auth model

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2-3 — Agent Architect + Security + Agent Ops Eng
- **Skills:** Security engineering, identity management
- **Dependencies:** d4
- **Scope drivers:** Number of external services, compliance requirements, number of tenants

Permission matrix per action type. Sandbox choice. User auth flow (how user identity reaches tool calls). Agent credentials and rotation. Multi-tenancy data isolation. Audit trail requirements.

> [!check] Done when
> Every action has permission level; auth flow documented; isolation strategy chosen

**Deliverable:** Security Spec + Permission Matrix

---

## d9: Design UX layer

- **Complexity:** 2/5 · **Variability:** Variable
- **Participants:** 2 — Agent UX Designer + Agent Product Mgr
- **Skills:** UX/product design, frontend architecture
- **Dependencies:** d6
- **Scope drivers:** Interface complexity, number of approval checkpoints

Choose interface type (chat/CLI/embedded/Slack). Design progress display for long tasks. Specify approval UI for HITL checkpoints. Plan error UX (diagnostics, retry, escalation). If chatbot layer: specify conversation design.

> [!check] Done when
> Interface type chosen; progress, approval, and error flows designed

**Deliverable:** UX Spec with wireframes

---

## d10: Plan environment tiers

- **Complexity:** 2/5 · **Variability:** Predictable
- **Participants:** 2 — Agent Ops Eng + Agent Architect
- **Skills:** DevOps, infrastructure planning
- **Dependencies:** d2
- **Scope drivers:** Number of tiers, existing infrastructure maturity

Define local/staging/prod requirements. Specify what changes at each tier: secrets management, model access, data handling, scaling, deployment method, observability depth, HITL mode.

> [!check] Done when
> Three tiers defined with specific requirements; promotion path documented

**Deliverable:** Environment Tier Plan

---

## d11: Define evaluation plan

- **Complexity:** 2/5 · **Variability:** Variable
- **Participants:** 2-3 — Prompt & Eval Eng + Domain Expert
- **Skills:** ML engineering, domain expertise, eval design
- **Dependencies:** d1
- **Scope drivers:** Number of task types, domain specificity

Unambiguous success criteria per task type. Eval level (run/trace/thread). Dataset plan. Metrics to track. Domain-specific eval criteria identified with domain expert.

> [!check] Done when
> Success criteria pass 'two experts agree' test; dataset plan complete

**Deliverable:** Evaluation Plan

---

## d12: Build cost and latency model

- **Complexity:** 2/5 · **Variability:** Predictable
- **Participants:** 2 — Agent Product Mgr + Prompt & Eval Eng
- **Skills:** Product management, financial modeling
- **Dependencies:** d3, d5
- **Scope drivers:** Number of models in portfolio, API vs compute mix

For API models: estimate tokens/task, set cache hit rate target (>90%), calculate cost per completed task. For self-hosted: estimate compute hours, GPU utilization, throughput capacity. Set budget thresholds per tenant/team with alerting levels. Additionally, define latency targets: time-to-first-token and total response time for interactive agents, or completion time SLAs for background agents. These targets constrain model selection, context strategy, and caching architecture — a fast response requires either a smaller model, aggressive caching, or pre-computed context.

> [!check] Done when
> Cost per task estimated within 2x; latency targets specified per task type; budget thresholds set with alert plan

**Deliverable:** Cost & Latency Model Spreadsheet

---

## d13: Identify compliance requirements

- **Complexity:** 2/5 · **Variability:** Highly variable
- **Participants:** 2-3 — Agent Product Mgr + Legal/Compliance + Domain Expert
- **Skills:** Legal/compliance, domain expertise
- **Dependencies:** d3
- **Scope drivers:** Industry regulations, geographic scope, legal complexity

Regulatory requirements (HIPAA/SOC2/GDPR/industry-specific). Which models are approved. Data residency constraints. Retention policies. Audit trail requirements. Model governance process for version changes.

> [!check] Done when
> All applicable regulations identified; constraints documented; approved model list established

**Deliverable:** Compliance Requirements Document

---

