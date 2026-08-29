# Model routing — which tier for which class of task

> Goal: **quality first**, cost second. Frontier capability is applied where it changes the
> outcome; cheaper tiers where it does not. Which concrete models fill the tiers is a `.env`
> choice (`COMPANY_OS_MODEL_*`); this document is about classes and rules.

## The four tiers

| Tier | For what | `.env` variable |
|---|---|---|
| **CHEAP** | web research, log scans, triage, classification, formatting, short drafts | `COMPANY_OS_MODEL_CHEAP` |
| **MID** | routine analysis, support drafts (+ a CHEAP verifier), reports | `COMPANY_OS_MODEL_MID` |
| **HIGH** | hard analysis, non-obvious diagnosis, implementation, anything a customer will see | `COMPANY_OS_MODEL_HIGH` |
| **AUDIT** | independent review BEFORE anything irreversible (ship, send, pay, delete, deploy) | `COMPANY_OS_MODEL_AUDIT` |

Empty variables fall back to `COMPANY_OS_MODEL`, then to the CLI default. Two providers
(Claude Code + Codex)? Set `COMPANY_OS_BALANCE_PROVIDERS=1` and the router alternates them on
tasks where both fit; audits always use a **different** run (and ideally a different provider)
than the author.

## The quality rule (non-negotiable)
1. **Never go below a task's minimum tier to save money.** CHEAP is for the truly low-risk.
2. **Nothing irreversible without an AUDIT** by a run that did not produce the work.
   Disagreement between author and auditor → do not ship; escalate to the founder.
3. **A reproducible check beats any model opinion** (a test, a measurable before/after).

## Routing by task class

| Class (`scripts/route-model.sh <class>`) | Base tier | Escalation |
|---|---|---|
| `research` · `scan` · `triage` · `classify` | CHEAP | → MID if the signal is ambiguous |
| `draft` · `report` · `read` | MID | → HIGH if the case is complex |
| `analyze` · `diagnose` (obvious) | HIGH | — |
| `diagnose` with `--hard` | HIGH ×2 | two independent runs, compare hypotheses |
| `implement` | HIGH | — |
| `ship` (anything irreversible) | **AUDIT** | author + independent auditor must converge |

## Per-agent defaults
- chief-of-staff: `report` (MID); arbitration → HIGH.
- ops / finance: `scan` (CHEAP) for metrics, `analyze` (HIGH) for correlations.
- support: `classify` (CHEAP) → `draft` (MID) → verifier (CHEAP) → complex → HIGH.
- growth: `research` (CHEAP), `draft` (MID), anything customer-facing → HIGH + AUDIT before GO.
- quality: HIGH (it judges what customers receive).
- reviewer: highest tier available, always; certainty required before a verdict (else DIG).
