---
tags: [agent-engineering]
chapter: 07
---

# From Prototype to Production

← [[06 - Security]] · 

---

## The HITL Spectrum: Humans as a Design Element, Not a Fallback

Everything up to this point can be prototyped on a laptop in a weekend. Getting it to production is a different discipline entirely — one that involves organizational design, operational infrastructure, and a series of decisions that have no "correct" answers, only tradeoffs appropriate to your context. This chapter covers the full journey, starting with the most consequential design decision you'll make about a production agent: how humans fit into the loop.

The guide so far has treated human intervention as binary: the agent runs, or it blocks for confirmation. In reality, HITL is a spectrum, and designing it well requires the same rigor you applied to tools and context.

**Intervention points matter.** Pre-execution review (human approves the plan before the agent acts) is high-friction but safe — appropriate for irreversible or high-stakes actions. Checkpoint-based review (the agent works autonomously, pauses at milestones) balances speed and oversight. Post-execution review (the agent completes the task, human reviews before shipping) works for non-destructive outputs like drafts or analyses. Exception-based review (the agent escalates only when uncertain) is the most efficient but requires calibrated confidence — which is model-dependent and often needs explicit prompt engineering or a dedicated "flag for review" tool.

**Sync vs async is an infrastructure decision with organizational consequences.** Sync HITL (the agent blocks until the human responds) works for interactive sessions where you're sitting at the keyboard, but it doesn't scale — the agent is idle while waiting, and the human is tethered to the session. Async HITL (the agent writes output to a PR, draft, or queue, notifies the human, and moves on to other work) is essential for production agents running overnight, across time zones, or serving multiple users. The human reviews on their own schedule, with an SLA that defines how long they have. LangGraph's built-in interrupt/resume primitives [^44] provide the most mature implementation of this pattern, with checkpointing that allows workflows to pause indefinitely and resume on a different machine.

**Handoff UX determines throughput** — and this is where most teams under-invest [^23]. When the agent hands off to a human, what does the reviewer see? A diff? A summary? The full trace? A structured approval form? The design of this surface directly impacts how quickly and accurately humans can review, and ultimately determines how many agent tasks a single human can oversee per hour. Remember the observation from the Architecture chapter: human attention is the bottleneck. The HITL interface is where that bottleneck is either relieved or worsened.

> [!summary] Key Takeaways
> 1. HITL is a spectrum from pre-execution (safest) to exception-based (fastest).
> 2. Sync HITL blocks the agent; async HITL (queue + SLA) is essential for production.
> 3. LangGraph interrupt/resume [44] provides the most mature built-in HITL support.
> 4. The handoff UX — what the reviewer sees — determines how many tasks a human can oversee per hour.

## Domain Knowledge: From Demo Data to Production Reality

A demo agent can work from its system prompt and general training knowledge. A production agent needs a **knowledge architecture** and a **data pipeline** — because real work requires domain-specific information that the model doesn't have, that changes over time, and that may be subject to privacy or regulatory constraints.

**The knowledge hierarchy** determines where different types of information live, and the right placement depends on frequency of use and volume. Domain knowledge can sit at multiple levels: in the system prompt (always available, but burns context budget), in project config (cached per project, stable across sessions), in skills (progressively disclosed on demand — recall the tool design principle from Chapter 2), in a knowledge base accessed via RAG (scales to large volumes, adds retrieval latency — techniques like Contextual Retrieval [^43] can reduce retrieval failures by up to 67% by prepending chunk-specific context before embedding), or in tool descriptions and error messages (steers behavior implicitly). A 3-line coding convention belongs in config. A 50-page regulatory framework belongs in RAG. A domain workflow belongs in a skill.

**The data pipeline** keeps this knowledge current. For any agent operating on domain knowledge, you need three things: ingestion (documents, databases, APIs → agent-consumable format), freshness (scheduled re-indexing, change detection to keep information current), and privacy (PII detection, data residency requirements, GDPR/HIPAA compliance, and clarity about which data flows through which models — especially important when choosing between API providers and self-hosted infrastructure).

**Domain expert involvement** is the organizational challenge that underpins all of this. Domain experts have the knowledge but typically can't write skills or prompts. Engineers can write skills but lack domain expertise. You need a continuous, structured process: domain experts review and approve content, engineers encode it at the right level of the knowledge hierarchy. This isn't a one-time setup — regulations change, products evolve, processes update, and the knowledge architecture must evolve with them.

## The Model Portfolio: Not Every Task Deserves Your Best Model

Production systems rarely run on a single model. They use a **portfolio** — different models with different capability-cost profiles assigned to different parts of the workflow. This connects to the economics from the Foundations chapter and the subagent architecture from the Architecture chapter: the model portfolio is where cost strategy meets system design.

**A typical portfolio** includes: a small, fast model (Haiku-class, Qwen-4B, Phi) for classification, routing, and extraction — high volume, low cost, no agency. A mid-tier model (Sonnet-class, Llama-70B) for routine coding and standard tool use — the workhorse that handles most tasks. A frontier model (Opus-class, GPT-5) for complex reasoning and planning — low volume, high cost, used sparingly. And possibly a fine-tuned open-weights model for domain-specific tasks where a general model falls short.

**Agency should match capability.** A router model classifies and dispatches — no tools, no autonomy. A task executor follows prescribed workflows with moderate tool access. A planner directs its own process with full agency. Giving full agency to a small model invites failure; constraining a frontier model to rigid workflows wastes it. This is the agency spectrum, and getting it right is one of the highest-leverage design decisions you'll make.

**Routing architecture** determines how tasks reach the right model. Options range from static (predefined rules based on task type), to LLM-based (a small model classifies and routes — the Routing pattern from Chapter 1 [^1]), to complexity-based (try the cheap model first, escalate on failure or uncertainty), to subagent-based (the primary agent spawns subagents with appropriate models [^9]). Many systems also have a **chatbot or UX layer** — a conversational front-end separate from the execution back-end, handling intent recognition, conversation state, result presentation, and user elicitation, often using a different (faster, cheaper) model than the execution layer.

## Environment Tiers: The Same Agent, Three Different Worlds

Your agent exists in at least three forms with fundamentally different requirements. Understanding these tiers early prevents the most common production surprise: discovering that your laptop prototype makes assumptions (about access, scaling, data, security) that simply don't hold in production.

**Local (laptop/prototyping):** Fast iteration is the priority. The model is accessed via a personal API key or a local instance (Ollama, LM Studio). Data is sample data. Security is minimal. Observability is console output. Deployment is "I run it." HITL is synchronous — you're right there. Testing is manual trace review. The goal: validate that the concept works at all.

**Staging:** A shared environment with realistic (sanitized) data. The same model stack as production, or close to it. Proper secrets management. Structured tracing visible to the team. CI/CD deploys harness changes automatically. Limited scaling (1-3 instances). HITL can be tested in async mode. Automated evals run against every change. The goal: validate reliability and performance before real users see it.

**Production:** Customer-facing with SLAs. Model versions pinned with failover configured. Auto-scaling to handle demand. Real data with PII handling. Full monitoring, alerting, and on-call rotation. Blue-green or canary deploys with eval gates that prevent regressions from shipping. HITL is async with SLAs and escalation policies. Cost attribution per tenant. Audit trails for compliance. The goal: serve users reliably, day after day.

Almost everything in the harness — prompts, skills, tools, context strategy — stays the same across tiers. What changes: how secrets are managed, how traces are stored, how the model is accessed, how failures are handled, how costs are tracked, and who has access. Designing for tier promotion from the start (rather than retrofitting) saves enormous effort later.

## Production Engineering: The Boring Work That Determines Success

The final stretch is the least glamorous and most important. Production engineering for agents borrows heavily from traditional SRE and DevOps disciplines, but with additions specific to the non-deterministic, model-dependent nature of agent systems.

**Reliability** means the agent keeps working when things go wrong — because they will. Retry with exponential backoff for API and tool errors. Circuit breakers for tools that start failing repeatedly. Timeout policies per tool call and per session to prevent runaway costs. Graceful degradation — fall back to a cheaper model or a simpler workflow if the primary model is down, rather than failing completely. Idempotency for actions that modify external state (if the agent sends an email twice due to a retry, what happens?). Dead letter queues for tasks that fail repeatedly and need human investigation.

**Testing beyond evals** catches issues that eval datasets miss. Unit tests for tool handlers, parsers, and permission checks. Integration tests for the full tool-model-tool chain. Load tests for concurrent agent sessions — where does it bottleneck? For self-hosted models: inference throughput under realistic load. Chaos and fault injection — what happens when the database is slow, MCP is down, the model returns malformed output, or a tool fails mid-action?

**CI/CD for the agent stack** treats harness artifacts as code, because they are. Prompts, skills, tools, and configs flow through: PR → code review → merge → eval gate (automated evals must pass) → staging deploy → promotion gate → production deploy. Model version pinning with rollback capability. Environment promotion from local → staging → production with feature flags or gradual rollout.

**Auth and multi-tenancy** become critical the moment more than one user touches the system. User authentication must flow through to tool calls — when the agent sends an email, it uses the user's OAuth token, not a service account. Agent identity uses scoped credentials, rotated on schedule. Data isolation between tenants is essential: can User A's traces, memories, or outputs leak to User B? Rate limits and cost attribution per tenant prevent one user's workload from consuming the budget.

**The UX layer** is what users actually experience. Interface type (chat UI, CLI, Slack bot, embedded widget). Agent status and progress display for long-running tasks (streaming partial results, notifications on completion). Approval workflows for HITL (email buttons, Slack interactions, dashboard queues). Result presentation (diffs, reports, dashboards). Error UX that gives users actionable information (diagnostics, suggested next steps, retry option) rather than opaque failure messages.

**Compliance and governance** round out the picture. Cost attribution per team, project, and user. Budget controls with automatic throttling when limits approach. Industry-specific requirements (HIPAA, SOC2, financial regulations) affecting model choice, data handling, retention, and access. Model governance — an approved model list, version pinning, and an approval process for model changes. Audit trails logging every action: who triggered it, when, what was done, and what data was accessed.

This is where the guide's narrative arc closes. You started with a question — workflow or agent? — and if you've followed the thread, you now have a framework for answering it: the agent loop for reasoning, tools for action, context for information, evaluation for confidence, architecture for scale, security for trust, and production engineering for reality. The Project Planner that follows translates all of this into a 56-task backlog you can import into your project tracker and start executing against. The hard part isn't knowing what to build. It's building it well, measuring it honestly, and improving it continuously.

> [!summary] Key Takeaways
> 1. Reliability patterns (retry, circuit breaker, timeout, graceful degradation, dead letter queue) are SRE adapted for non-deterministic systems.
> 2. Harness artifacts are code — they flow through PR → review → eval gate → deploy, just like application code.
> 3. Auth must flow through to tool calls: the agent acts as the user, not a service account.
> 4. Three drift types degrade agents silently: model drift, data drift, concept drift. Rolling evals catch what regression gates miss.
> 5. Agent incidents are different: the agent may have taken irreversible actions before detection. Build a kill switch and an incident playbook.


---

## References

[^1]: [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)
[^9]: [Prompt Caching Lessons](https://x.com/trq212/status/2024574133011673516)
[^23]: [Attention Bottleneck](https://x.com/Hesamation/status/2039381120127496362)
[^43]: [Contextual Retrieval](https://www.anthropic.com/news/contextual-retrieval)
[^44]: [LangGraph HITL (interrupt)](https://blog.langchain.com/making-it-easier-to-build-human-in-the-loop-agents-with-interrupt/)
