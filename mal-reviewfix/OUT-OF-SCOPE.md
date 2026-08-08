# Out of scope — /mal-reviewfix

This skill is **not**:

- Issue triage / AFK agent briefs (use `/triage`)
- Full parallel verify-all (use `.cursor/skills/verify-all-parallel`)
- A substitute for SonarQube CI upload — it only approximates new-code coverage locally
- Automatic Dependabot PR merge or lockfile rewrite without user OK
- Mounting Magic Chat / Milkdown / full SidebarToolCard solely to chase Sonar %
- Committing or opening PRs unless the user explicitly asks

## Why

Keep the skill fast and reversible. Autofix stays in the lint/prettier lane; security and coverage strategy stay human-gated when expensive.
