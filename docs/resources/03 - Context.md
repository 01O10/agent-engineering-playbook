---
tags: [agent-engineering]
chapter: 03
---

# Context Engineering — Caching, Memory, and RLMs

← [[02 - Tools]] · → [[04 - Evaluation]]

---

## The Art of Showing the Model What It Needs to See

Tools let the agent act. Context determines whether those actions are intelligent. If the previous chapter gave the agent hands, this chapter gives it eyes — and teaches you how to control what it sees, when, and at what cost. Remember Law #2 from the Foundations chapter: context is the bottleneck. Everything in this chapter flows from that principle.

**Finding the right altitude** for prompts is the central skill of context engineering [^2]. "Altitude" is a metaphor from practitioners: too low (overly specific, step-by-step instructions for every scenario) and the agent becomes brittle — it follows your script perfectly for anticipated cases but fails on anything you didn't predict. Too high (vague principles like "be helpful and thorough") and the agent flounders, making poor decisions because it lacks guidance. The sweet spot — the **right altitude** — gives the agent enough structure to handle routine cases confidently while leaving room to reason through novel situations. The right altitude also depends on model capability: stronger models need less hand-holding and can work from higher-altitude prompts; weaker models need more explicit structure.

**Prompt layout order matters for caching**, and understanding *why* requires knowing how caching works under the hood. When you send a prompt to an API model, the provider processes each token sequentially, building an internal representation. **Prompt caching** stores this internal representation for a prefix of your prompt, so subsequent requests that start with the same prefix can skip reprocessing it — paying only for the new tokens at the end. The canonical layout [^9] puts content in order of stability: *system prompt* (changes rarely, cached longest) → *tool definitions* (stable per session) → *project config* (stable per project) → *conversation history* (changes every turn). Each layer extends the cached prefix.

Seven hard-won lessons govern caching strategy [^9]: **(1)** Put static content first — it caches longest. **(2)** Use reminder messages (brief restatements of key instructions) as conversation grows, because the model's attention to the system prompt weakens over long contexts. **(3)** Don't switch models mid-session — it rebuilds the entire cache from scratch. **(4)** Never change the tool set after the session starts — any change invalidates the cache from that point forward. **(5)** Move cache breakpoints forward as conversation accumulates — the breakpoint is where cached content ends and new content begins. **(6)** Compaction preserves the cache prefix — because you're replacing old conversation with a summary, the static prefix remains intact. **(7)** Always save buffer space for the model's response — if context is 95% full, the model has almost no room to think, leading to truncated or degraded output.

For self-hosted models, the equivalent mechanism is **KV-cache prefix matching** — the model's key-value attention cache (the internal state the model builds as it processes tokens) can be reused across requests that share a prompt prefix. Frameworks like vLLM implement this automatically [^40], but you still need to design your prompt layout to maximize prefix sharing.

**Context anxiety** is a real and measurable phenomenon in long-running agent sessions [^5]. As the context window fills — say, past 60-70% capacity — models begin exhibiting premature completion behavior: they start wrapping up tasks, producing summaries, and tidying up even when significant work remains. The model isn't "deciding" to stop; it's a statistical artifact of how attention works over very long sequences. Two strategies address this:

**Compaction** replaces older conversation history with a condensed summary, freeing space while retaining the essential information. For example, after 80K tokens of back-and-forth, the harness might replace the oldest 60K tokens with a 4K summary of what was accomplished, what decisions were made, and what remains. The agent continues with full awareness of progress in a fraction of the tokens. Crucially, compaction preserves the cache prefix (the system prompt, tools, and config remain untouched), so you don't lose your caching investment.

**Context resets** take a more aggressive approach: start a completely fresh context window, handing off state through external artifacts — typically a **progress file** (a structured document the agent writes before the reset, summarizing everything it needs to continue) and **git commits** (so code changes persist across windows) [^6]. The agent in the new window reads the progress file and picks up where the previous window left off, but with a completely clean context. Which strategy works better depends on the model, the task type, and the session length [^4][^5] — this is one of those things you must test empirically rather than decide theoretically.

**Memory folders** extend the agent's recall beyond a single session [^4]. The agent writes context to files — learnings, preferences, patterns it discovered, corrections it received — and reads them on demand in future sessions. This is different from conversation history: memory is *distilled* knowledge that persists indefinitely, not a transcript of what happened. A nuance worth noting: stronger models tend to distill tactical learnings into concise, useful notes ("When modifying the auth module, always run the integration tests in /tests/auth/ because they cover edge cases the unit tests miss"), while weaker models create verbatim transcripts that are bulky and less useful. Memory should be "constrained, structured, purposeful" [^24] — organized into folders by topic, pruned regularly, and accessed selectively rather than dumped wholesale into context.

**Recursive Language Models (RLMs)** represent the frontier of context engineering [^19]. The core idea is radical: instead of treating the context window as a passive container for information, treat it as an **environment** that the model navigates programmatically. The model writes code to search across documents, filter results, reorganize information, dispatch sub-queries to specialized sub-models, and assemble findings — managing information flow through code rather than through raw token accumulation. This allows the model to operate across information volumes that exceed native context windows by 100x or more, because it never tries to hold everything in context simultaneously.

RLMs, PTC (from the Tools chapter), and Code Mode [^14] all share one fundamental insight: **code manages information flow better than tokens** [^4][^12][^14][^19]. Instead of hoping the model pays attention to the right part of a long context (which becomes unreliable past ~100K tokens), you write code that extracts exactly what's needed and presents it cleanly. This insight is arguably the most important idea in the guide.

This insight — that the quality of what the agent sees determines the quality of what it does — connects directly to the next challenge. You've designed tools and crafted context strategies. But how do you know if any of it actually works? That question is deceptively simple, and answering it well is where most teams either succeed or fail.

> [!summary] Key Takeaways
> 1. Context is the bottleneck — the model can only act on what it can see.
> 2. Prompt layout order (static → tools → config → conversation) maximizes cache hits and minimizes cost.
> 3. Right altitude: specific enough to guide, flexible enough to adapt. Iterate empirically, not theoretically.
> 4. Compaction (summarize in place) and context resets (fresh window + progress file) handle long sessions. Which works is model-dependent.
> 5. Code manages information flow better than tokens — this connects PTC, Code Mode, and RLMs.


---

## References

[^2]: [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
[^4]: [Harnessing Intelligence Patterns](https://claude.com/blog/harnessing-claudes-intelligence)
[^5]: [Harness Design Long-Running](https://www.anthropic.com/engineering/harness-design-long-running-apps)
[^6]: [Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
[^9]: [Prompt Caching Lessons](https://x.com/trq212/status/2024574133011673516)
[^12]: [Programmatic Tool Calling](https://x.com/rlancemartin/status/2027450018513490419)
[^14]: [Cloudflare Code Mode](https://blog.cloudflare.com/code-mode/)
[^19]: [RLM Paper](https://arxiv.org/abs/2512.24601)
[^24]: [Memory Architecture](https://x.com/himanshustwts/status/2038924027411222533)
[^40]: [vLLM Docs](https://docs.vllm.ai/)
