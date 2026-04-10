---
tags: [agent-engineering]
chapter: 05
---

# Architecture, Subagents, and the Software Factory

← [[04 - Evaluation]] · → [[06 - Security]]

---

## When One Agent Isn't Enough: Patterns for Composition

A single agent with well-designed tools, good context engineering, and a solid eval loop can accomplish a surprising amount. But at some point you'll hit limits — tasks too large for one context window, subtasks requiring different capabilities or models, workflows where you need strategy separated from execution. That's when architecture becomes the design problem.

The patterns here aren't theoretical; they emerged from teams solving real scaling problems, and each connects directly to the foundations, tools, and context principles from earlier chapters.

**Initializer-Coder** [^6] is the simplest multi-phase pattern. Phase 1: a planning agent writes feature requirements and a progress file. Phase 2: a coding agent implements one feature at a time, updating the progress file after each. This prevents the most common failure mode of ambitious agents — trying to one-shot the entire task and losing coherence as context fills. The progress file is the key: it's a human-readable contract between phases, and it embodies the context engineering principle of structured handoff.

**Subagents** extend this to parallel and hierarchical work [^7][^13]. Two modes: simple delegation (parent sends a task, child returns a result, parent continues) or full context sharing (child inherits the parent's context). Both preserve the parent's cache [^9], which is why subagents often outperform model-switching within a single agent. Each subagent gets its own context window, its own tool set, and potentially its own model — which connects directly to the model portfolio concepts in the Prototype→Production chapter.

**Slate's Thread Weaving** [^17] is the most sophisticated pattern documented publicly. An orchestrator dispatches workers that return "episodes" — compressed outcome summaries rather than raw transcripts. This cleanly separates strategy (the orchestrator decides what to do) from execution (the workers do it), and the episode format keeps the orchestrator's context manageable even when workers produce large outputs.

**Case studies ground these patterns in reality.** A solo agent completing a task took 20 minutes and cost $9; a full harness with subagents took 6 hours and cost $200 — but handled a task the solo agent couldn't [^5]. An autonomous port of a large codebase required 583 API calls and cost less than $60 [^17]. And across model generations, it was memory strategy — not raw model capability or harness sophistication — that most differentiated performance [^4].

> [!summary] Key Takeaways
> 1. Initializer-Coder prevents the most common failure: trying to one-shot a large task.
> 2. Subagents preserve the parent cache and can use different models — model portfolio meets architecture.
> 3. Thread Weaving (compressed episode summaries) separates strategy from execution.
> 4. The filesystem is the coordination layer between agents — plain files any agent or human can inspect.

## The Software Factory: A Philosophy, Not a Blueprint

The patterns above are tactics. The software factory is the strategic frame that holds them together. Its core principles connect to everything you've read so far — and everything that follows.

"Enable experimentation, don't declare The Solution." [^21] The teams that succeed with agents are the ones that build infrastructure for rapid iteration, not the ones that design the perfect architecture on a whiteboard. **Persistent compute** is the key primitive — a running environment where the agent can build, test, and iterate without cold starts [^21]. The **filesystem is the coordination layer** between agents, phases, and sessions [^13][^16] — not a message bus, not a database, not an API, but plain files that any agent can read and any human can inspect.

Two observations from production teams deserve attention. First: most users exercise only 10% of available agent capabilities [^22]. Second: human attention is the bottleneck — winning products solve the attention problem, not the capability problem [^23]. These insights shape everything from architecture (don't build for theoretical scale; build for the tasks people actually run) to UX (the review interface matters more than the agent's internal sophistication).

As your architecture grows in capability — more agents, more tools, more external integrations, more autonomy — it also grows in attack surface. Every new tool is a potential injection vector. Every subagent is a potential escalation path. Every external integration is a boundary where trust assumptions can break down. That brings us to security.


---

## References

[^4]: [Harnessing Intelligence Patterns](https://claude.com/blog/harnessing-claudes-intelligence)
[^5]: [Harness Design Long-Running](https://www.anthropic.com/engineering/harness-design-long-running-apps)
[^6]: [Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
[^7]: [Agent SDK Guide](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
[^9]: [Prompt Caching Lessons](https://x.com/trq212/status/2024574133011673516)
[^13]: [Agent Design Patterns](https://x.com/RLanceMartin/status/2024573404888911886)
[^16]: [Building Better Harnesses](https://x.com/Vtrivedy10/status/2037203679997018362)
[^17]: [Slate Thread Weaving](https://randomlabs.ai/blog/slate)
[^21]: [Software Factory](https://blog.exe.dev/bones-of-the-software-factory)
[^22]: [Agent Source Analysis](https://x.com/mal_shaik/status/2038918662489510273)
[^23]: [Attention Bottleneck](https://x.com/Hesamation/status/2039381120127496362)
