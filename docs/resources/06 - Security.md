---
tags: [agent-engineering]
chapter: 06
---

# Security, Permissions, and Prompt Injection

← [[05 - Architecture]] · → [[07 - Prototype→Prod]]

---

## Why Agent Security Is Different — and What to Do About It

Every capability you've added in the preceding chapters — tools, context, subagents, external integrations — is also a potential attack vector. Agent security is fundamentally different from traditional application security because agents have *agency*: they make decisions, call tools, and modify external state. A vulnerability in a traditional application might expose data; a vulnerability in an agent might cause it to take destructive actions autonomously. The OWASP Top 10 for LLM Applications [^41] provides the industry-standard risk framework for these threats, covering prompt injection, excessive agency, sensitive information disclosure, and more.

Security for agents breaks into three distinct concerns, and conflating them is a common mistake.

**Concern 1: Permission gating** controls which actions the agent is allowed to take, and under what conditions. The governing principle is the **reversibility heuristic**: actions that are hard to reverse (sending an email, deleting a file, deploying code, making a payment) should require human confirmation, while easily reversible actions (reading a file, running a query, listing a directory) can be auto-approved [^4]. Three permission tiers cover most cases: **auto-approved** (read-only operations — the agent proceeds without asking), **confirm** (the agent pauses, presents what it intends to do, and waits for human approval before proceeding), and **block** (the agent cannot perform this action under any circumstances, regardless of context) [^4].

A more sophisticated variant is **auto-mode**: a second, lightweight model reviews each proposed action and judges whether it is safe enough to proceed without human review [^4]. The safety judge sees the action, the current context, and the permission policy, and makes a fast approve/escalate decision. This allows the agent to work autonomously on routine tasks while still flagging unusual or high-risk actions for human review. The tradeoff: auto-mode is only as good as the safety judge — too permissive and dangerous actions slip through; too conservative and it blocks so frequently that it defeats the purpose of automation.

**Concern 2: Sandboxing** ensures that even auto-approved actions cannot escape their intended scope. The question is not "is the agent allowed to run code?" (that is permission gating) but "what can that code access?" Three sandboxing approaches are common: **V8 isolates** run code in a JavaScript sandbox where bindings explicitly hide API keys and sensitive environment variables — the code can compute and return results but cannot access the host system [^14]. **Persistent VMs** provide a full operating system environment with filesystem boundaries, network restrictions, and resource limits — more capability but still contained [^21]. **PTC handlers** intercept every tool call within the agent's code and validate it against a policy before execution — this is sandboxing at the function call level rather than the infrastructure level [^12][35]. For self-hosted models, the inference endpoint itself must not be publicly accessible, and agent actions still need containment regardless of where the model runs.

**Prompt injection** is a distinct threat from permission violations, and this distinction matters profoundly. Simon Willison coined the term "lethal trifecta" [^42] to describe the dangerous combination: any system that has **access to private data**, processes **untrusted content**, and has an **exfiltration vector** (a way to send data out) is vulnerable to injection attacks.

The key insight: prompt injection is not the same as jailbreaking [^42]. Jailbreaking is when a user directly tricks a model into misbehaving. Prompt injection is when *malicious instructions embedded in content the agent processes* hijack its behavior. The attack comes through data the agent reads (emails, RAG documents, MCP tool responses, web pages), not from the user. This makes it far more dangerous because the user may have no idea malicious content is present in what the agent is reading.

Defenses work in layers: **Input sanitization** flags suspicious patterns before they reach the model. **System prompt hardening** explicitly instructs the model to never follow instructions found inside documents or tool results. **Tool-result validation** verifies that outputs are well-formed data, not instruction-like text. And most critically: **testing** with dedicated prompt injection cases in your eval suite [^41], verifying the agent refuses injected instructions across multiple vectors.

Notice how this connects to the evaluation chapter: injection defense is only as good as the test cases that validate it.

With security addressed, you have all the conceptual pieces: the agent loop, tools, context, evaluation, architecture, and security. What remains is the most practical challenge of all — and the one where the widest gap exists between tutorials and real-world practice. How do you take what works on your laptop and run it in production, reliably, at scale, with real users? That's the subject of the final chapter.

> [!summary] Key Takeaways
> 1. Three distinct concerns — do not conflate: permission gating (what CAN it do), sandboxing (what SCOPE), injection (can it be TRICKED).
> 2. Reversibility heuristic: hard-to-reverse actions get human confirmation, reversible ones can auto-approve.
> 3. The lethal trifecta (private data + untrusted content + exfiltration vector) is the condition that makes injection dangerous [42].
> 4. OWASP Top 10 for LLMs [41] is the industry-standard audit checklist for agent security.
> 5. Injection defense is only as good as the test cases that validate it — add them to your eval suite.


---

## References

[^4]: [Harnessing Intelligence Patterns](https://claude.com/blog/harnessing-claudes-intelligence)
[^12]: [Programmatic Tool Calling](https://x.com/rlancemartin/status/2027450018513490419)
[^14]: [Cloudflare Code Mode](https://blog.cloudflare.com/code-mode/)
[^21]: [Software Factory](https://blog.exe.dev/bones-of-the-software-factory)
[^41]: [OWASP Top 10 for LLMs](https://genai.owasp.org/llm-top-10/)
[^42]: [Willison: The Lethal Trifecta](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/)
