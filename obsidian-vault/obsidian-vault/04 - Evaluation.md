---
tags: [agent-engineering]
chapter: 04
---

# Evaluation, Debugging, and the Flywheel

← [[03 - Context]] · → [[05 - Architecture]]

---

## Why Evaluation Is the Hardest Part — and Where You Should Spend Most of Your Time

The hardest part of agent engineering is not building the agent. It is knowing whether what you built works. This chapter may seem like it belongs later — surely you should perfect the design before worrying about measurement? — but in practice, evaluation is where you should invest 60-80% of your effort [^25], and the teams that treat it as an afterthought are the ones whose agents fail in production.

The core problem is that **agents praise their own work** even when quality is mediocre [^5]. A model that just spent 200 tokens generating an answer is poorly positioned to objectively evaluate that answer — it has a statistical bias toward believing its own output is correct. The solution is to **separate creation from critique**. The **Generator-Evaluator** pattern uses one model (or configuration) to produce work and a separate one to judge it, ideally with live-product testing — for example, the evaluator actually runs the generated code, opens the generated file in a browser, or queries the database the agent just modified [^5]. If the generator and evaluator are the same model, at minimum use a fresh context (no memory of having generated the output). A related technique, **Best of N**, generates 3-5 independent variations of the same output and selects the best [^27] — this works because the variance between attempts is often high, and the best of 5 is significantly better than a single attempt.

**Eval methodology matters more than eval infrastructure** [^25]. Teams routinely over-invest in tooling (which framework? which dashboard? which LLM-as-judge?) and under-invest in the analytical work that makes the tooling useful. The methodology that works, step by step:

**(1) Review 20-50 traces manually.** A **trace** is a complete record of everything that happened during one agent run: the prompt the model received, each tool call it made, each tool result it got back, its reasoning at each step, and its final output. Reading traces is tedious — each one might be thousands of tokens — but irreplaceable. You're looking for patterns: where does the agent make wrong decisions? Is it seeing the right context? Are tool results what you expected?

**(2) Define unambiguous success criteria.** Apply the **"two experts agree" test**: if two domain experts independently evaluate an output, do they agree on whether it passes? If they don't, your criteria are too vague. "Good quality summary" is vague. "Summary contains all key financial metrics mentioned in the source document, with no hallucinated numbers, in under 200 words" is unambiguous.

**(3) Build a failure taxonomy via open coding.** **Open coding** is a qualitative research technique: read each failing trace, give the failure a descriptive label, and group similar labels into categories. Keep going until new traces stop producing new categories (this is called "saturation"). A typical taxonomy might include: prompt issues, tool selection errors, tool parameter errors, context gaps, model reasoning limits, data quality problems, and infrastructure failures. This taxonomy is your diagnostic map — it tells you *where* to look when something goes wrong.

**(4) Match fixes to root causes.** This is where the taxonomy pays off. A prompt fix for a tool design problem wastes time. A model upgrade for a context gap changes nothing. The taxonomy tells you: prompt issues → revise the prompt. Tool failures → improve descriptions or add examples. Context gaps → adjust what information reaches the model. Model limits → consider a more capable model for that subtask, or decompose the task differently. Data quality → fix the ingestion pipeline.

**(5) Rule out infrastructure first.** Before blaming the model's reasoning, verify that it actually received the right context. Many "model failures" are actually context failures — the model didn't see the relevant document, or the tool returned an error that was swallowed, or the cache served stale content.

**(6) Separate capability evals from regression evals.** **Capability evals** ask "can the agent do this *at all*?" — use these when building new features. **Regression evals** ask "did the last change break something that used to work?" — run these on every PR. Mixing them leads to confusion: a failing capability eval isn't a bug, it's a feature gap.

Three evaluation levels exist, from narrow to broad [^25]: **single-step** (did this one tool call succeed?), **full-turn** (did the agent complete a start-to-finish task? — start here), and **multi-turn** (did the agent handle a realistic multi-session interaction?). For production agents, **state change evaluation** is essential: verify what actually changed in the external world (was the email sent? was the file modified? does the code compile?), not just what the agent *claims* happened [^25].

The goal of all this is a **flywheel**: production traces → human annotation → labeled failure categories → updated eval dataset → targeted fixes → better traces [^25]. Each rotation makes the agent measurably better. Without this flywheel, improvement is guesswork.

> [!summary] Key Takeaways
> 1. Spend 60-80% of effort on error analysis, not infrastructure. Methodology matters more than tooling.
> 2. Separate Generator from Evaluator — models praise their own work.
> 3. Build a failure taxonomy from traces. Match fixes to root causes.
> 4. The eval flywheel (traces → annotation → taxonomy → fixes → better traces) is how agents improve.
> 5. 'Read what it saw, not what it did' — the root cause is almost always in the context, not the reasoning.

## Debugging: Read What It Saw, Not What It Did

Evaluation tells you *whether* something is broken. Debugging tells you *why*. The two are deeply connected — the failure taxonomy from your eval process is the map that guides debugging.

**Traces are the primary debugging artifact** [^16]. A trace captures everything the agent saw and did: the prompt, the tool calls, the tool results, the model's reasoning, the final output. When something goes wrong, resist the urge to stare at the output and guess. Instead, "read what it saw, not what it did" — the problem is almost always in the context the model received, not in the model's reasoning ability [38].

For systemic issues, **large-scale trace reflection** works well: stratify errors by category (from your failure taxonomy), then feed a representative sample of traces to a model for pattern analysis [^16]. This often surfaces root causes that are invisible in individual traces — a tool description that's ambiguous in a specific edge case, a context ordering that buries critical information, a memory entry that contradicts the system prompt.

One pattern deserves special mention: **forced self-verification**. Models can self-correct effectively when given feedback, but they won't enter the correction loop voluntarily — you must build it into the harness as a mandatory step [^16]. This connects back to the Generator-Evaluator pattern: critique must be engineered, not hoped for.

With evaluation and debugging in hand, you have the discipline to know when your agent works and why it fails. The next question is architectural: when a single agent isn't enough, how do you compose multiple agents, models, and patterns into a coherent system?


---

## References

[^5]: [Harness Design Long-Running](https://www.anthropic.com/engineering/harness-design-long-running-apps)
[^16]: [Building Better Harnesses](https://x.com/Vtrivedy10/status/2037203679997018362)
[^25]: [Eval Readiness Checklist](https://blog.langchain.com/agent-evaluation-readiness-checklist/)
[^27]: [Coursera Agent Engineering](https://www.coursera.org/learn/claude-code)
