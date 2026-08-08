---
name: mal-reviewfix
description: >-
  Runs Paddy pre-merge quality gates: prettier + eslint/import-order, tsc,
  CVE audit (pnpm audit + snyk), and local Vitest coverage (≥42% new-code
  indicator). Use when the user says /mal-reviewfix, malreviewfix, pre-merge
  review, Sonar coverage gate, import/order crash, or CVE/snyk check before
  commit/PR. Auto-fixes safe lint/import issues; writes
  .reviewfix/report.json; may invoke /tdd, /diagnose, or /grill-with-docs for
  coverage gaps.
platforms: all
disable-model-invocation: true
---

# /mal-reviewfix

Slash-only (`disable-model-invocation: true`). Three gates in order. Auto-fix
safe issues only. Ask before dependency bumps, large coverage refactors, or
commits.

Principles and scope: [AGENT-BRIEF.md](AGENT-BRIEF.md). Boundaries:
[OUT-OF-SCOPE.md](OUT-OF-SCOPE.md). Procedures and schema:
[reference.md](reference.md).

## Quick start

```text
/mal-reviewfix
/mal-reviewfix --all
/mal-reviewfix --fast
/mal-reviewfix --base origin/main
```

| Flag | Effect |
| --- | --- |
| (default) | Changed files vs base branch only |
| `--all` | Repo-wide lint/coverage scope |
| `--fast` | Use `pnpm run tsc:app` instead of full `pnpm run tsc` |
| `--base <ref>` | Diff against the supplied base ref |

## Workflow

Do not stop until all three gates have pass/fail/warn and the report is written.

1. **Change set** — committed-vs-base ∪ staged ∪ unstaged; filter lintable
   sources and record buckets. Empty + no `--all` → green exit. Before calling
   it push-ready, check working-tree-only fixes and Node runtime parity. See
   [reference.md](reference.md).
2. **Gate 1 — lint/tsc** — prettier → eslint (recover import/order crash
   manually) → exact CI `pnpm run tsc`. PASS requires both final commands to
   exit 0; `--fast` is diagnostic only.
3. **Gate 2 — CVE** — `pnpm audit` + optional `snyk`. No major or lockfile
   bumps without asking. PASS requires no high/critical findings or accepted
   residual risk.
4. **Gate 3 — coverage** — scoped Vitest coverage on matching **specs**, not
   bare source paths. Local ≥~42% is a PASS with a Sonar warning; large gaps
   trigger ROI triage and conditional sub-skills.
5. **Report** — write `.reviewfix/report.json` and print the terminal summary.
   Suggest a conventional commit message; never commit unless asked.

## Safe-fix boundaries

Allowed: prettier; manual import/order after the ESLint 10 crash; obvious
unused imports/vars introduced in this session; re-export paths for a util just
extracted.

Ask first: dependency bumps/lockfiles; multi-callsite extracts; Magic Chat,
Edubot, or boards UI mount suites; `eslint.config.mjs`, CI, or Sonar changes;
anything outside CHANGESET unless needed to unblock tsc.

## Done when

- [ ] Gates 1–3 recorded in `.reviewfix/report.json`
- [ ] Terminal summary printed
- [ ] Safe autofixes applied; risky changes asked
- [ ] Coverage FAIL + clear seam → sub-skill invoked or ROI in `nextSteps`
- [ ] No unsolicited commit
