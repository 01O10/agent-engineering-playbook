---
name: agent-project-planner
description: >
  Load this skill to generate a customized project backlog for building an AI agent
  system. Produces a phased plan with 56 tasks across 6 phases, tailored to the
  user's specific context (team size, model choice, domain, compliance requirements).
  Each task includes complexity, variability, scope drivers, skills needed, and dependencies.
trigger: >
  User asks for a project plan, backlog, task list, or roadmap for building an
  AI agent system. Also trigger when user has completed architecture decisions
  and needs an execution plan.
---

# Agent Project Planner

Generate a customized project backlog for building an AI agent system. The backlog has 56 tasks across 6 phases. Tailor it based on user context.

## Intake Questions

Before generating the backlog, gather:

1. **Team size and skills**: How many people? What expertise (ML, backend, DevOps, domain)?
2. **Model strategy**: API-only, self-hosted, or hybrid? Which providers/models?
3. **Architecture**: Single agent, multi-agent, or agentic workflow?
4. **Domain**: What domain? Any compliance requirements (HIPAA, SOC2, GDPR)?
5. **MVP scope**: What's the minimum viable first version?
6. **Existing infrastructure**: Greenfield or extending existing systems?

## Phase Structure

### Phase 1 — Discovery & Design (15 tasks)
Every decision documented before code. Serial work, 1-2 decision-makers.

Core tasks (always include):
- d0: Define MVP scope + stakeholder alignment (Cx:2, Variable)
- d1: Define agency level on the spectrum (Cx:2, Predictable)
- d2: Choose architecture pattern (Cx:3, Variable)
- d4: Design action space — L1/L2 split (Cx:3, Variable)
- d5: Design context strategy (Cx:3, Variable)
- d6: Design HITL policy (Cx:2, Variable)
- d8: Design security model (Cx:3, Variable)
- d11: Define evaluation plan (Cx:2, Variable)

Conditional tasks:
- d2b: Framework evaluation — include if team is choosing a framework (Cx:3, Variable)
- d3: Model portfolio design — include if using multiple models (Cx:3, Variable)
- d7: Domain knowledge architecture — include if domain-specific agent (Cx:3, Highly variable)
- d9: UX layer design — include if user-facing agent (Cx:2, Variable)
- d12: Cost model — include if budget-constrained (Cx:2, Predictable)
- d13: Compliance requirements — include if regulated domain (Cx:2, Highly variable)

### Phase 2 — Infrastructure (10 tasks)
Parallel work across 2-3 people. Separate paths for API vs self-hosted.

Core tasks:
- i1: Local dev environment (Cx:1, Predictable)
- i5: Observability stack (Cx:2, Predictable)
- i8: Harness version control (Cx:1, Predictable)

API path:
- i4a: Configure model API access + caching (Cx:1, Predictable)

Self-hosted path:
- i4b: Set up model serving — vLLM/TGI (Cx:4, Highly variable)
- i4c: Fine-tune for function calling if needed (Cx:4, Highly variable)

Conditional:
- i2: Staging environment (Cx:3, Variable) — defer if MVP-only
- i3: Production environment (Cx:4, Variable) — defer to v2
- i6: Data pipeline for RAG (Cx:4, Highly variable) — only if RAG needed
- i7: Auth and identity (Cx:3, Variable) — only if multi-user

### Phase 3 — Core Build (11 tasks)
Parallel across 3-5 people. The main implementation phase.

Core tasks:
- b1: System prompt + config (Cx:3, Variable)
- b2: Implement tools + descriptions (Cx:4, Highly variable)
- b4: Memory and persistence (Cx:3, Variable)
- b6: HITL mechanisms (Cx:3, Variable)
- b8: Permission gating (Cx:2, Predictable)
- b9: Reliability patterns (Cx:3, Variable)

Conditional:
- b3: Skills library + knowledge base (Cx:3, Highly variable) — if domain-specific
- b5: Subagent architecture (Cx:4, Highly variable) — only if multi-agent
- b7: UX layer (Cx:3, Highly variable) — if user-facing
- b10: Model routing (Cx:3, Variable) — only if multi-model
- b11: Async task queue (Cx:3, Variable) — only if background processing

### Phase 4 — Evaluation (6 tasks)
ML-heavy, 1-2 people. 60-80% of real improvement effort.

All tasks are core:
- e1: Manual trace review — 20-50 traces (Cx:2, Predictable)
- e2: Build failure taxonomy via open coding (Cx:3, Variable)
- e3: Build eval dataset — 20-50 cases (Cx:3, Highly variable)
- e4: Automated eval runner + software tests (Cx:4, Highly variable)
- e5: Model-powered tool optimization cycle (Cx:2, Variable)
- e6: Establish baseline metrics (Cx:1, Predictable)

### Phase 5 — Iteration & Hardening (5 tasks)
Refinement from eval data. Can partially overlap with Phase 4.

- r1: Optimize tool descriptions + prompt altitude (Cx:2, Variable)
- r2: Test model alternatives (Cx:2, Variable)
- r3: Strip dead weight from harness (Cx:2, Predictable)
- r4: Validate cost model against actuals (Cx:2, Predictable)
- r5: Security audit + chaos testing + injection defense (Cx:3, Variable)

### Phase 6 — Production & Operations (9 tasks)
DevOps-heavy. Ship and operate.

Core tasks:
- o1: Production monitoring + alerting (Cx:3, Variable)
- o2: CI/CD with eval gates (Cx:3, Variable)
- o3: Trace-to-dataset flywheel (Cx:2, Predictable)
- o6: Team training + model upgrade cadence (Cx:2, Predictable)
- o9: Incident response playbook + kill switch (Cx:3, Variable)

Conditional:
- o4: Cost governance — if multi-tenant or budget-sensitive (Cx:2, Variable)
- o5: Compliance audit — if regulated domain (Cx:3, Highly variable)
- o7: User feedback loop (Cx:2, Variable) — if user-facing
- o8: Drift detection + rolling eval (Cx:3, Variable) — if long-running production

## Estimation Guidance

- **Complexity** (1-5): relative scale across this backlog
- **Variability**: Predictable = estimate confidently. Variable = add buffer. Highly variable = add 2-3x buffer
- **Scope drivers**: what makes THIS instance bigger or smaller (e.g., "3 tools" vs "20 tools")
- Senior team with infrastructure: 3-5x faster than greenfield
- Minimum team: 2 (ML/AI + backend). Well-resourced: 5-7

## Output Format

Produce a Markdown backlog with:
1. Tasks labeled MVP / v2 / scale based on user's scope
2. Conditional tasks included/excluded based on intake answers
3. Adjusted complexity notes based on user's team and infrastructure
4. Dependency chain highlighted (which tasks block others)
5. Suggested team allocation per phase
