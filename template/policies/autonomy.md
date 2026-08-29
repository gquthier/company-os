# Autonomy policy — who decides what

## Principle
**Tiered** autonomy, never total on money or the irreversible. The founder is the final
decision-maker. Autonomy starts narrow (reading, drafting, reporting) and widens one
whitelisted action at a time, after that action has been done draft-first and reviewed.

## Tiers

| Tier | Trigger | Behaviour |
|---|---|---|
| **T1 · Auto** | low risk, reversible, under a ceiling | executes + logs; reviewed in the digest |
| **T2 · Notify** | moderate deviation / notable action | executes but **notifies**; proceeds if no objection within 30–60 min |
| **T3 · Hard-stop** | ceiling exceeded / new category / irreversible / money / legal / customer-facing send | **founder approval BEFORE execution** |

## Mapping for this company
> Derived from `COMPANY.md` → "Never without me". Every line there is T3 here. Fill the rest.

| Domain / action | Tier | Ceiling / condition |
|---|---|---|
| Reading any system of record (read-only connector) | T1 | scoped to the task |
| Drafting a customer reply (support) | T1 | draft only, never sent |
| Sending a customer reply — whitelisted intent, proven | TODO (T2 once promoted) | intent listed in `knowledge/trusted/support/` |
| Sending a customer reply — new / sensitive / billing / complaint | **T3** | |
| Refund / credit / discount | **T3** | TODO: T1 below X if reason whitelisted |
| Any price change | **T3** | |
| Publishing content, sending campaigns, spending on ads | **T3** | |
| Paying, subscribing, cancelling a tool | **T3** | |
| Deleting data, deploying to production, running a migration | **T3** | |
| Contacting a third party (partner, supplier, investor) on the company's behalf | **T3** | |
| Opening an investigation task for another agent | T1 | |
| Proposing a cost optimisation that cuts something | **T3** | |
| Hiring, contracts, legal, taxes | **T3** | |
| TODO: (company-specific) | | |

## Anti alert-fatigue
Tune ceilings so that T2 notifications arrive **a few times a week**, not per hour. A human
drowned in approvals rubber-stamps — which makes the tier useless.

## Escalation
Every T3 → a message in `bus/inbox/chief-of-staff/` + a `PENDING` row in `bus/DECISIONS.md`
(`scripts/decision.sh set … PENDING`). The chief of staff summarises and asks the founder.
No silent "human task": a blocked agent escalates explicitly, then stops.
