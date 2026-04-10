---
tags: [agent-engineering, planner, phase-6]
---

# Phase 6 — Production & Operations

← [[00 - Index]]

---

## o1: Set up production monitoring + alerting

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2 — Agent Ops Eng + SRE
- **Skills:** DevOps, SRE, data visualization
- **Dependencies:** e6
- **Scope drivers:** Number of metrics, alerting sophistication, dashboard complexity

Dashboards: cache hit rate, completion rate, error rate, cost/task, latency. For self-hosted: GPU utilization, queue depth. Anomaly alerting.

> [!check] Done when
> All metrics visible; test alert fires correctly

**Deliverable:** Monitoring dashboard with alerts

---

## o2: Implement CI/CD pipeline with eval gates

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2 — Agent Ops Eng + Harness Eng
- **Skills:** DevOps, CI/CD engineering
- **Dependencies:** e4, i3
- **Scope drivers:** Pipeline complexity, number of eval gates, rollback requirements

Full pipeline: PR → review → merge → eval gate → staging deploy → promotion gate → production deploy. Rollback capability for all harness artifacts.

> [!check] Done when
> Degrading change blocked; rollback tested

**Deliverable:** CI/CD pipeline with verified rollback

---

## o3: Set up trace-to-dataset flywheel

- **Complexity:** 2/5 · **Variability:** Predictable
- **Participants:** 1-2 — Prompt & Eval Eng
- **Skills:** ML engineering, process design
- **Dependencies:** i5, e3
- **Scope drivers:** Annotation tool choice, review frequency

Production traces → annotation queue → weekly expert review → promote failures to dataset → expand coverage.

> [!check] Done when
> First weekly review completed; 3+ cases added

**Deliverable:** Annotation pipeline with schedule

---

## o4: Set up cost governance

- **Complexity:** 2/5 · **Variability:** Variable
- **Participants:** 2 — Harness Eng + Agent Product Mgr
- **Skills:** Backend engineering, finance operations
- **Dependencies:** o1
- **Scope drivers:** Number of tenants, billing integration complexity

Cost attribution per team/project/user. Budget alerts. Automatic throttling or model downgrade when budget exhausted.

> [!check] Done when
> Costs attributed correctly; budget alert fires; throttling tested

**Deliverable:** Cost governance system

---

## o5: Compliance audit + documentation

- **Complexity:** 3/5 · **Variability:** Highly variable
- **Participants:** 3 — Agent Product Mgr + Legal/Compliance + Security Eng
- **Skills:** Compliance, legal, security engineering
- **Dependencies:** d13, r5
- **Scope drivers:** Number of regulatory domains, audit depth, documentation requirements

Verify all regulatory requirements met. ADRs for major decisions. Approved model list. Audit trail completeness. Retention policies enforced.

> [!check] Done when
> All requirements verified; ADRs cover every matrix dimension

**Deliverable:** Compliance Report + ADR collection

---

## o6: Train team + define model upgrade cadence

- **Complexity:** 2/5 · **Variability:** Predictable
- **Participants:** 2-3 — Prompt & Eval Eng + team leads
- **Skills:** ML engineering, technical communication
- **Dependencies:** b3
- **Scope drivers:** Team size, existing AI literacy

Teach workflows, config practices, trace reading, skill authoring. Establish process for new model releases (eval within 48h, compare baseline, strip/add components).

> [!check] Done when
> Each member can write a skill and read a trace; upgrade runbook tested

**Deliverable:** Training materials + Model Upgrade Runbook

---

## o7: Set up user feedback loop

- **Complexity:** 2/5 · **Variability:** Variable
- **Participants:** 2 — Agent Product Mgr + Harness Eng
- **Skills:** Product management, data analysis, backend engineering
- **Dependencies:** o3, b7
- **Scope drivers:** User volume, feedback mechanism complexity, analysis depth

The trace-to-dataset flywheel (o3) captures the engineer-side signal. This task captures the user-side signal, which is often more valuable. Implement: explicit feedback collection (thumbs up/down, corrections, ratings on agent outputs), implicit signal tracking (which tasks users stop using the agent for — silent churn — and which they repeat — satisfaction), a pipeline that routes user feedback into the eval dataset (real failures from real users are the highest-value test cases), a process for user complaints and corrections to update the failure taxonomy (users surface failure categories you never anticipated), and periodic analysis of feedback trends to inform skill refinements, prompt changes, and domain knowledge updates. Without this, you're optimizing against synthetic or engineer-generated test cases while real user pain points go unaddressed.

> [!check] Done when
> Feedback mechanism live; first batch of user-reported failures promoted to eval dataset; monthly feedback trend report generated

**Deliverable:** Feedback collection system + pipeline to eval dataset

---

## o8: Set up drift detection and rolling evaluation

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2 — Prompt & Eval Eng + Agent Ops Eng
- **Skills:** ML engineering, SRE, statistics
- **Dependencies:** e6, o1
- **Scope drivers:** Eval complexity, number of drift types to monitor

The baseline (e6) and regression gates (o2) catch degradation from harness changes. But three types of drift cause gradual degradation with no change on your side: model drift (API provider silently updates model behavior, or your self-hosted model's inference stack changes subtly with library updates), data drift (knowledge base content evolves in ways that affect retrieval quality — new documents don't match old embedding patterns, or source data quality degrades), and concept drift (user behavior and expectations change over time — the tasks they bring shift, the quality bar rises, new edge cases emerge). Implement automated monitoring that runs a representative subset of the eval suite on a schedule (daily or weekly) against live production traffic, compares rolling performance metrics against the baseline, and alerts when degradation exceeds a threshold — even if no harness change was deployed. For self-hosted models: also monitor inference performance metrics (latency percentiles, throughput) for infrastructure-level drift.

> [!check] Done when
> Rolling eval runs on schedule; alert fires when accuracy drops >5% from baseline with no harness change; first drift event investigated and root-caused

**Deliverable:** Scheduled eval runner + drift alerting dashboard

---

## o9: Write incident response playbook

- **Complexity:** 3/5 · **Variability:** Variable
- **Participants:** 2-3 — Agent Ops Eng + SRE + Agent Product Mgr (comms)
- **Skills:** SRE, DevOps, incident management, communication
- **Dependencies:** o1, o2
- **Scope drivers:** Number of external systems agent interacts with, action reversibility

Agent incidents differ from traditional software incidents because the agent may have already taken actions (sent emails, modified files, called APIs, committed code) before the problem is detected. The playbook must cover: investigation (pull the trace, identify the failure point, determine what actions were already taken and whether they can be reversed), mitigation (pause the agent immediately — kill switch mechanism; revert the harness change if one was made; fall back to a manual workflow for affected task types; if actions were taken on external systems, assess which need manual reversal), communication (notify affected users about what happened and what was done about it; for B2B/enterprise: formal incident report), prevention (add the failure to the eval dataset; update the failure taxonomy; if the failure class is systemic, add a new verification hook or permission gate to prevent recurrence), and escalation paths (who gets paged, in what order, for what severity levels — distinct from HITL checkpoints which are routine, incidents are abnormal). Include a post-incident review template for blameless retrospectives.

> [!check] Done when
> Playbook reviewed by team; kill switch tested (agent pauses within 30s); simulated incident run through full playbook including communication and post-incident review

**Deliverable:** Incident Response Playbook + kill switch mechanism

---

