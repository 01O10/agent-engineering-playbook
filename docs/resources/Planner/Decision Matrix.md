---
tags: [agent-engineering, planner]
---

# Decision Matrix (16 Dimensions)

Answer these before writing code. Your answers become the design spec.

| Dimension | Key Questions | What to Document |
|---|---|---|
| **Task Fit** | Where on the agency spectrum? Deterministic, agentic workflow, or autonomous? | Task description · success criteria · agency level justification · spectrum position [^1] [^48] |
| **Action Space** | Code or JSON? How many tools? L1 vs L2? | Tool inventory · bound vs sandbox · code execution strategy [^12] [^14] |
| **Tool Specs** | Descriptions clear? Errors guide? Eval-tested? | Per tool: name, desc, params, errors, eval results [^3] [^46] |
| **Context** | Prompt layout? Cache strategy? KV-cache config? | Prompt ordering · breakpoints · system vs messages vs skills [^2] [^9] [^33] |
| **Memory** | Across turns? Sessions? Compaction triggers? | Compaction strategy · memory folder · handoff mechanism [^4] [^6] [^24] |
| **Evaluation** | Success criteria? Level? Taxonomy? Flywheel? User feedback? Drift detection? | Criteria · level · taxonomy · dataset · metrics · flywheel · user feedback pipeline · drift monitoring schedule [^3] [^5] [^25] |
| **Architecture** | Single or multi-agent? Subagent pattern? | Topology · responsibilities · schemas · context sharing [^1] [^6] [^17] |
| **Model Portfolio** | Which models for which roles? Agency levels? Routing? | Model per agent role · agency level · routing strategy · chatbot layer [^5] [^9] [^15] |
| **HITL** | Where do humans intervene? Sync or async? Review UX? | Intervention points · escalation policy · handoff UX · review SLA [^4] [^8] [^23] [^44] |
| **Domain & Data** | Knowledge hierarchy? Data pipeline? Freshness? Privacy? | Knowledge placement · ingestion · freshness cadence · PII handling [^2] [^10] [^43] |
| **Security & Auth** | Permissions? Sandbox? User auth? Multi-tenancy? Prompt injection defense? | Permission matrix · sandbox · identity · data isolation · audit · injection test cases · input sanitization · tool-result validation [^4] [^14] [^41] [^42] |
| **Environments** | Local/staging/prod? What changes at each tier? | Tier plan · secrets · scaling · deployment · promotion path [^21] |
| **Reliability** | Retry? Fallback? Timeout? Idempotency? Incident response? | Retry policy · circuit breakers · timeout config · dead letters · incident playbook · kill switch [^6] |
| **UX Layer** | Interface? Progress display? Approvals? Error UX? | Interface type · status display · approval workflow · error handling [^8] [^23] |
| **Compliance** | Regulatory? Model governance? Audit trails? Budget? | Requirements · approved models · audit log · cost attribution [^33] |
| **Cost & Latency** | API or compute? Cache target? Budget? Latency targets? | Cost structure · cache target · budget threshold · attribution · TTFT target · completion time SLA [^9] [^33] [^40] |

