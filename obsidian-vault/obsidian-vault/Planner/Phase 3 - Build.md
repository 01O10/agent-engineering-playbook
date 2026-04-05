---
tags: [agent-engineering, planner, phase-3]
---

# Phase 3 — Core Build

← [[00 - Index]]

---

## b1: Write system prompt + project config

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2 — Prompt & Eval Eng + Domain Expert (reviewer)
- **Skills:** Prompt engineering, domain knowledge
- **Dependencies:** d5
- **Scope drivers:** Domain complexity, number of task types, context budget

System prompt at right altitude. Project config with standards and conventions. If smaller open-weights context window, be especially concise.

> [!check] Done when
> Goldilocks review passed; fits within target context budget

**Deliverable:** System prompt + config (versioned)

---

## b2: Implement tools with descriptions

- **Complexity:** 4/5 · **Variability:** Highly variable
- **Participants:** 2-3 — Harness Eng + Prompt & Eval Eng (descriptions)
- **Skills:** Backend engineering, prompt engineering, API integration
- **Dependencies:** d4, i4a||i4b
- **Scope drivers:** Number of tools, API complexity, model's native tool-calling quality

For each bound tool: handler, clear description, typed params, actionable error messages. Open-weights models may need more explicit descriptions with examples.

> [!check] Done when
> Each tool: unit test passes, description reviewed, error tested

**Deliverable:** Tool implementations (versioned)

---

## b3: Build skills library + knowledge base + domain expert review workflow

- **Complexity:** 3/5 · **Variability:** Highly variable
- **Participants:** 3 — Prompt & Eval Eng + Domain Expert + Harness Eng
- **Skills:** ML engineering, domain expertise, knowledge management
- **Dependencies:** b1, i6
- **Scope drivers:** Number of skills, RAG complexity, domain breadth, number of domain experts

Create 3-5 critical skills with metadata frontmatter. If RAG: implement retrieval tool that searches the knowledge base. Wire domain knowledge into appropriate level of the hierarchy. Additionally, implement the domain expert review workflow: a process by which domain experts review and approve knowledge content before it goes live. This could be as simple as requiring domain expert approval on PRs that modify skills, knowledge base content, or domain-specific eval cases — or as formal as a dedicated review queue with approval/rejection and change tracking. Without this, engineers will encode domain knowledge at the wrong altitude or with subtle inaccuracies that only an expert would catch.

> [!check] Done when
> Skills load on demand; RAG returns relevant results for 10 test queries; domain expert has reviewed and approved all domain-specific content; review workflow documented and tested

**Deliverable:** Skills directory + knowledge retrieval (if RAG) + domain expert review process

---

## b4: Implement memory and persistence

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 1-2 — Harness Eng
- **Skills:** Backend engineering, context engineering
- **Dependencies:** i1, d5
- **Scope drivers:** Session length, memory volume, compaction frequency

Memory folder structure. Write triggers. Compaction with buffer. Multi-session: progress file + handoff. Wire context management hooks (caching, reminders, breakpoints).

> [!check] Done when
> Agent writes memory, compacts, restarts, reads prior memory; cache hit >85%

**Deliverable:** Memory + context pipeline

---

## b5: Build subagent architecture (if multi-agent)

- **Complexity:** 4/5 · **Variability:** Highly variable
- **Participants:** 2-3 — Harness Eng + Agent Architect
- **Skills:** Backend engineering, system architecture, distributed systems
- **Dependencies:** d2, b2
- **Scope drivers:** Number of agents, handoff complexity, cross-model compatibility

Subagent spawning, context sharing mode, output schema enforcement, task tracking. Verify cross-model compatibility if using mixed model portfolio.

> [!check] Done when
> Parent → subagent → result cycle works; cache preserved

**Deliverable:** Subagent system with verified handoff

---

## b6: Implement HITL mechanisms

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2 — Harness Eng + Agent UX Designer
- **Skills:** Backend engineering, UX engineering
- **Dependencies:** d6
- **Scope drivers:** Number of checkpoint types, async requirements, notification channels

Checkpoint/escalation tools per HITL policy. Sync blocking for interactive mode. Async notification + queue for production mode. Flag-for-review tool for agent uncertainty.

> [!check] Done when
> Sync: agent blocks until human responds. Async: notification sent, agent continues, review queued

**Deliverable:** HITL system with both sync and async modes

---

## b7: Build UX layer

- **Complexity:** 3/5 · **Variability:** Highly variable
- **Participants:** 2-3 — Frontend Eng + Agent UX Designer + Harness Eng
- **Skills:** Frontend engineering, UX design
- **Dependencies:** d9, b6
- **Scope drivers:** Interface type and polish, design requirements, approval flow complexity

Implement chosen interface (chat/CLI/embedded/Slack). Progress display for long tasks. Approval UI for HITL. Result presentation. Error UX with diagnostics and retry.

> [!check] Done when
> User can start task, see progress, approve checkpoints, view results, handle errors

**Deliverable:** Working user interface

---

## b8: Implement permission gating

- **Complexity:** 2/5 · **Variability:** Predictable
- **Participants:** 1-2 — Harness Eng
- **Skills:** Backend engineering, security
- **Dependencies:** d8, b2
- **Scope drivers:** Number of permission tiers, auto-mode complexity

Wire permission matrix. Auto-approve/confirm/block tiers. Staleness checks on writes. Auto-mode safety judge if applicable.

> [!check] Done when
> Each tier tested end-to-end

**Deliverable:** Permission system gating all tool calls

---

## b9: Implement reliability patterns

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 1-2 — Harness Eng / Agent Ops Eng
- **Skills:** Backend engineering, SRE, distributed systems
- **Dependencies:** b2
- **Scope drivers:** Number of external dependencies, failure mode variety

Retry with backoff for API/tool errors. Circuit breakers for failing tools. Timeout per tool call and per session. Graceful degradation (fallback model or workflow). Idempotency for state-changing actions. Dead letter queue.

> [!check] Done when
> Simulated API failure triggers retry → circuit breaker → fallback; dead letter captures persistent failures

**Deliverable:** Reliability layer with fallback tested

---

## b10: Implement model routing (if multi-model)

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2 — Harness Eng + Prompt & Eval Eng
- **Skills:** Backend engineering, ML engineering
- **Dependencies:** d3, b2
- **Scope drivers:** Number of models in portfolio, routing logic complexity

Wire routing logic per model portfolio design. Static rules or LLM-based classifier. Complexity-based escalation. Verify each model receives appropriate traffic.

> [!check] Done when
> Test cases routed to correct model tier; escalation triggers on expected conditions

**Deliverable:** Routing system with verified distribution

---

## b11: Implement async task queue (if background/async agent)

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 1-2 — Harness Eng
- **Skills:** Backend engineering, distributed systems
- **Dependencies:** b6, b9
- **Scope drivers:** Concurrency requirements, number of tenants, queue sophistication

For agents that handle work asynchronously (user submits task, agent works in background, user gets notified on completion): implement the work queue and lifecycle management. Covers: task submission and validation, priority ordering (urgency, tenant fairness, task type), duplicate detection and deduplication, maximum queue depth with backpressure (reject or delay new tasks when overloaded), task status tracking visible to the user (queued / in-progress / review / complete / failed), cancellation mechanism (user can abort a running task), timeout for stalled tasks (auto-fail and notify after threshold), and for multi-tenant systems: fair scheduling so one tenant's burst doesn't starve others. If using async HITL, the review queue is itself a queue that needs the same management — SLAs on review time, escalation when reviews are overdue.

> [!check] Done when
> Tasks queue, execute, and complete with correct status updates; duplicate rejected; cancellation tested; backpressure triggers at configured depth; fair scheduling verified across 2+ tenants

**Deliverable:** Queue system with lifecycle management and status API

---

