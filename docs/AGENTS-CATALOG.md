# Agents catalog — rosters and role sheets by business type

Every agent has a role sheet (`agents/<slug>/AGENTS.md`) with the same six sections:
**Identity · Mission · Autonomy · Cadence · Models · Daily report.** The sheet says what the
agent *never* does as clearly as what it does. Use `scripts/new-agent.sh <slug> "<role>"` to
scaffold one, then rewrite it from the notes below in your company's vocabulary.

## The core five (every company)

| Agent | Owns | Never |
|---|---|---|
| `chief-of-staff` | orchestration, daily digest, routing the founder's orders, watching all inboxes, escalation | specialist work; deciding what is reserved to the founder |
| `ops` | costs and health of everything the company runs on (tools, subscriptions, sites, automations, loops) | cutting, paying or scaling anything |
| `support` | customer requests: classify, answer from trusted knowledge with citations, escalate | sending anything a customer receives without the tier allowing it; refunds |
| `growth` | pipeline and demand: content, outbound, ads, partnerships — in the founder's voice | publishing, sending or spending without a GO |
| `finance` | cash, invoices, receivables/payables, spend, runway, pricing anomalies | moving money; sending a reminder or an invoice unless whitelisted T1 |

## Recommended as soon as an agent's output reaches a customer

| Agent | Owns | Never |
|---|---|---|
| `quality` | inspecting what customers actually receive (deliverables, product output, emails, site) as a customer would; filing issues to the right agent | fixing anything itself; contacting a customer |
| `reviewer` | the certainty gate — GO / DIG / SIMPLIFY / REJECT on any consequential change (process, tool, automation, code); keeping the process/architecture map current | executing; deciding product or spend |

## Agency / services

- **`delivery`** — client projects: scope, deadlines, handoffs between people, blockers.
  Reads the project tool and the shared drive; writes status to the bus; flags scope creep
  and late deliverables to `chief-of-staff` with the number of days at risk. Never promises a
  date to a client.
- **`account`** — the client relationship: renewals, satisfaction signals, upsell moments,
  silence longer than N days. Drafts check-ins in the founder's voice; sends nothing.

## SaaS / software

- **`bugwatch`** — signal (errors, logs, failed jobs, tickets) → dedup against known incidents
  → priority P0→P3 → root cause *proven* (reproduced, not guessed) → fix in an isolated branch
  → test red→green → independent review → PR. **Never merges a PR on billing, auth,
  migrations or webhooks** — those are the founder's. Post-mortem in `draft/learnings/`.
- **`product`** — research → proposal (a one-page PR-FAQ with what is verified, inferred and
  hypothesised) → GO from the founder → handoff to whoever builds. Never builds without a GO;
  never widens scope.

## E-commerce

- **`fulfillment`** — orders, stock, shipping exceptions, returns. Reads the store and the
  carriers; flags stuck orders and stock-outs; drafts customer updates for `support`.
- **`merchandising`** — catalog quality, pricing tests, bundles, seasonal calendar. Proposes;
  every price change is T3.

## Local business

- **`bookings`** — calendar, no-shows, reminders, waitlist. Drafts reminders; sends only if
  the founder whitelisted the template (T1).
- **`reputation`** — reviews and public replies drafted in the founder's voice; patterns of
  complaint routed to `quality`.

## Media / creator

- **`content`** — the pipeline: ideas → drafts → scheduled; repurposing; the calendar.
  Publishes nothing.
- **`community`** — comments, DMs, moderation patterns; drafts replies; flags sentiment shifts.

## Freelance / solo

Start with `chief-of-staff` + `growth` + `finance`. Add `delivery` when you have more than
three clients at once, `support` when clients write more than you can answer the same day.

## Writing a good role sheet

- **Identity** in the first person, one paragraph, ending with the sentence "I never …".
- **Mission** as a numbered list of what a run does, in order.
- **Autonomy** with three lines: 🟢 does alone · 🟡 does and notifies · 🔴 stops and asks.
- **Cadence** honest: a daily agent that runs hourly burns money for nothing.
- **Models** by task class (`policies/model-routing.md`), not by model name.
- **Daily report** with the four fixed headings: done · found · waiting on the founder · cost.
