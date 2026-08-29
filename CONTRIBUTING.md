# Contributing

Welcome. Three kinds of contributions are especially useful:

1. **A roster for a business type** — `docs/AGENTS-CATALOG.md`: the agents a clinic, a
   restaurant, a newsletter, a consultancy actually needs, with role sheets that say what each
   agent *never* does.
2. **A connector pattern** — `template/connectors/README.md`: how to read a common system of
   record read-only (variable names only, never values).
3. **A bridge** — a script that turns an external event (a chat message, a webhook) into an
   inbox file. It must write *telemetry, not instructions*, and go through the bus only.

Rules of the house: no application code in the control plane; files under 200 lines; a rule
is added after a failure, and checked to correct it; `bash template/tests/smoke.sh` green;
never a credential anywhere in the repo.

Open an issue first for anything structural.
