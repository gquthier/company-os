# Connectors — how agents reach the systems of record

Agents read the world **read-only by default** and act through the autonomy tiers. Each
connector = a thin wrapper (a script, a CLI, an API call) + credentials in `.env` — **never
here, never in a `.md`**.

## Inventory (one row per system named in `COMPANY.md`)
| Connector | Holds | Read by | Access | Env variable (name only) | Status |
|---|---|---|---|---|---|
| TODO CRM | customers, pipeline | growth, support, finance | read-only key | `CRM_API_KEY` | to wire |
| TODO payments | charges, subscriptions, refunds | finance, support | read-only key | `PAYMENTS_API_KEY` | to wire |
| TODO helpdesk / inbox | customer requests | support | read + draft | `HELPDESK_API_KEY` | to wire |
| TODO repo / project tool | delivery | delivery / bugwatch | read + PR, never admin | `REPO_TOKEN` | to wire |
| TODO analytics | traffic, funnels | growth, ops | read-only | `ANALYTICS_API_KEY` | to wire |
| notifications | P0 alerts to the founder | all (R5) | write (one channel) | `NOTIFY_WEBHOOK_URL` | `scripts/notify.sh` |

## Hard rules
- **Read-only by default.** No write to a system of record without the tier allowing it
  (`policies/autonomy.md`). T3 = founder first.
- **Least privilege.** A connector that does not need to write has no write scope. Prefer
  restricted / read-only keys when the provider offers them.
- **Scoped reads.** An agent reads what its task needs (this customer, this period), not the
  whole table.
- **Secrets live in `.env` only.** A script loads them; an agent never sees, prints or logs them.
- **Every external action is idempotent and locked by code** (a key, a "seen" store), never
  by a prompt.

## The four flows (see `docs/ARCHITECTURE.md` §3 of the template)
1. founder → `bus/inbox/chief-of-staff/` · 2. agent ↔ agent (consult / inbox) ·
3. agent → world (connector, tiered) · 4. world → agent (bridge/webhook/watcher → inbox file).
**Nothing external calls an agent directly.** The bus is the only door in.

## Wiring priority
1. The system where customers talk to you (helpdesk / inbox) — without it, support is blind.
2. Notifications (one channel, P0 only).
3. Money (read-only) — finance and ops need it for drifts.
4. The rest, one at a time, each proven by a manual run before any loop depends on it.
