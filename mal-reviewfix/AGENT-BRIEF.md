# Agent brief — /mal-reviewfix

## Goal

Run a bounded pre-merge quality loop: lint/import/tsc → CVE audit → coverage indicator (≥42%), then report JSON + terminal summary. Auto-fix only safe, local issues.

## Principles

### Durability over precision

Prefer reusable patterns (manual `import/order` after ESLint 10 crash; extract-and-test for Sonar) over one-off hacks that break next session.

### Behavior over ceremony

Gates must map to what CI/Sonar/Snyk actually enforce. Local coverage is an indicator; Sonar is authoritative.

### Complete acceptance criteria

Done = three gates recorded in `.reviewfix/report.json`, terminal summary shown, no unsolicited commit.

### Explicit scope boundaries

Default = changed files vs `main`. `--all` / `--fast` / `--base` are the only scope knobs. Ask before dep bumps and large coverage refactors.

## Template next-steps (examples)

- `Manual import/order on tests/unit-tests/foo.spec.ts (eslint --fix crashed)`
- `pnpm audit: 2 high — propose pnpm update <pkg>@x.y.z`
- `Coverage short: extract helpers from SidebarToolCard → node Vitest (/tdd)`
