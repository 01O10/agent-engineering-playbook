# Agent Engineering Playbook

A comprehensive interactive guide and project planner for building AI agent systems — from local prototype to production operations.

## What this is

An interactive React application covering the full lifecycle of agent engineering, synthesized from 38+ primary sources including Anthropic's engineering blog, LangChain's evaluation methodology, HuggingFace's agent course, and practitioner insights from teams building production agent systems.

**Two modes:**

- **Guide** (7 chapters) — conceptual foundations covering the agent loop, tool design, context engineering, evaluation methodology, architecture patterns, security, and the full prototype-to-production journey (HITL, domain knowledge, model portfolios, environment tiers, production engineering)
- **Project Planner** — a 16-dimension decision matrix feeding into a 56-task phased backlog, each task with role assignment, deliverables, done criteria, dependencies, complexity rating, variability indicator, scope drivers, required skills, and participant count

## Key features

- **Model-agnostic** — works for frontier API models and self-hosted open-weights models, with branching paths in the planner for each
- **Framework-aware** — covers the framework landscape (LangGraph, CrewAI, Pydantic AI, smolagents, Strands, etc.) without being prescriptive
- **Honest estimation** — uses complexity (1-5), variability (Predictable/Variable/Highly variable), and scope drivers instead of fabricated time estimates
- **Role-specific** — tasks assigned to agentic-specific roles: Agent Architect, Harness Engineer, Prompt & Eval Engineer, Agent Ops Engineer, Agent Product Manager, Agent UX Designer, Model Ops Engineer, Domain Expert
- **Exportable** — the backlog exports as Markdown with checkboxes, ready to paste into Linear, Notion, GitHub Issues, or any project tracker
- **38 numbered references** with clickable links throughout

## Guide chapters

1. **Foundations** — Agent loop, workflow patterns, paradigm shift, economics, framework selection
2. **Tools** — Two-layer action space, tool descriptions as prompt engineering, MCP, progressive disclosure
3. **Context** — Right altitude, caching architecture, memory, compaction, RLMs
4. **Evaluation** — Generator-Evaluator, eval methodology (LangChain checklist), debugging with traces
5. **Architecture** — Initializer-coder, subagents, swarms, case studies, software factory
6. **Security** — Permission gating, prompt injection defense, sandboxing
7. **Prototype → Production** — HITL spectrum, domain knowledge hierarchy, model portfolio & agency spectrum, environment tiers (local/staging/prod), production engineering (reliability, testing, CI/CD, auth, UX, compliance)

## Planner structure

### Decision matrix (16 dimensions)

Task Fit · Action Space · Tool Specs · Context · Memory · Evaluation · Architecture · Model Portfolio · HITL · Domain & Data · Security & Auth · Environments · Reliability · UX Layer · Compliance · Cost & Latency

### Phased backlog (56 tasks across 6 phases)

| Phase | Tasks | Focus |
|---|---|---|
| Phase 1 — Design | 15 | Every architectural decision documented before code |
| Phase 2 — Infrastructure | 10 | Local, staging, prod environments + model access + data pipeline |
| Phase 3 — Core Build | 11 | Harness implementation: prompts, tools, skills, memory, HITL, UX, reliability |
| Phase 4 — Evaluation | 6 | Manual review → failure taxonomy → eval dataset → automated runner → baseline |
| Phase 5 — Hardening | 5 | Optimize from eval data, test alternatives, security audit, chaos testing |
| Phase 6 — Production | 9 | Monitoring, CI/CD, flywheel, user feedback, drift detection, incident response |

### Per-task metadata

- **Complexity** (1-5 relative scale)
- **Variability** (Predictable / Variable / Highly variable)
- **Scope drivers** (what makes YOUR instance bigger or smaller)
- **Required skills** (specific expertise needed)
- **Participants** (number of people + which roles)
- **Deliverable** (what you produce)
- **Done criteria** (how the reviewer knows it's complete)
- **Dependencies** (which tasks must finish first)
- **References** (clickable links to source material)

## Minimum team composition (5-7 people)

| Role | Covers |
|---|---|
| 1× Prompt & Eval Engineer | System prompts, skills, evals, tool descriptions, drift monitoring |
| 1× Harness Engineer | Tools, memory, HITL mechanisms, queue, reliability, context pipeline |
| 1× Agent Ops Engineer | Infra tiers, CI/CD with eval gates, monitoring, incident response |
| 1× Agent Architect | Design decisions, framework evaluation, architecture patterns |
| 1× Agent Product Manager | MVP scoping, cost & latency, compliance, user feedback |
| 1× Domain Expert | Knowledge review, eval criteria, failure taxonomy validation |

Optional: +1 Agent UX Designer, +1 Model Ops Engineer

## How to use

The artifact is a standalone React (JSX) component. You can:

1. **Run in Claude.ai** — paste the JSX as an artifact
2. **Run locally** — use any React environment (Vite, Next.js, Create React App) and import the component
3. **Export the backlog** — use the Export button to generate Markdown, paste into your project tracker

## Primary sources

Built from 38+ references including:
- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) (Anthropic)
- [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (Anthropic)
- [Writing Effective Tools](https://www.anthropic.com/engineering/writing-tools-for-agents) (Anthropic)
- [Harness Design for Long-Running Applications](https://www.anthropic.com/engineering/harness-design-long-running-apps) (Anthropic)
- [Agent Evaluation Readiness Checklist](https://blog.langchain.com/agent-evaluation-readiness-checklist/) (LangChain)
- [HuggingFace Agents Course](https://huggingface.co/learn/agents-course/unit1/agent-steps-and-structure)
- [Slate: Thread Weaving](https://randomlabs.ai/blog/slate) (Random Labs)
- [Cloudflare Code Mode](https://blog.cloudflare.com/code-mode/)
- And 30+ more — all linked in the artifact with numbered references

## License

MIT
