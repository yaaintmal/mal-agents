---
name: mal-sonar-refacplan
description: Turn a SonarQube issue report into a focused refactor plan for paddy, execute the fixes, and update the project's Sonar refactor ADR if the work reveals a new pattern. Use when the user pastes a SonarQube report and asks to plan or fix the findings.
---

# Mal's Sonar Refactor Planner

## Quick start

When the user pastes a SonarQube issue report:

1. Read [`docs/adr/0015-sonar-refactor-patterns.md`](docs/adr/0015-sonar-refactor-patterns.md).
2. Extract the reported file paths, rule IDs, severity, and line numbers.
3. Read each reported file and draft a fix plan using ADR-0015 patterns.
4. Present the plan and ask for confirmation before editing code.
5. After the fixes are implemented, reflect on whether a new pattern or insight emerged. If yes, update the ADR.

## Workflows

### 1. Parse the report

Pull out:

- File path(s)
- Rule name / ID (e.g. `typescript:S3776`, `brain-overload`, `confusing`, `type-dependent`)
- Severity and effort
- Line numbers
- Issue description (e.g. "Refactor this function to reduce its Cognitive Complexity")

If the report is a screenshot or unstructured text, ask for the file path + line numbers if they are missing.

### 2. Read the ADR and the files

Always read in this order:

1. `docs/adr/0015-sonar-refactor-patterns.md`
2. Each reported file

Identify the function/component at the reported line and the control structure that causes the finding.

### 3. Plan the fix

For each finding, choose the smallest ADR-0015 pattern that resolves it:

| Finding | Pattern |
| ------- | ------- |
| Cognitive complexity >15 | Extract hook, helper component, or module-level helper; split by responsibility |
| Nested ternary | Replace with early-return helper component/function |
| Mutable component props | Wrap props type in `Readonly<...>` |
| `void` operator on async handler | Replace with `.catch(() => undefined)` and type handler as `() => Promise<void>` |
| `setState` in effect | Move guard to callback or use derived conditions |
| Ref during render | Do not use refs during render; prefer callback guards or derived state |

Keep helpers in the same file unless they have multiple cohesive exports.

Return a concise plan with file, function/component, concrete change, expected Sonar impact, and order of work (high severity first). Ask the user to confirm before editing code.

### 4. Implement the fixes

After the user confirms:

- Apply the planned changes.
- Run `pnpm exec prettier --write --list-different <files>` on every edited file.
- Run `pnpm tsc:app`.
- Run `pnpm exec eslint <files>`.
- Fix any new errors before declaring the refactor done.

### 5. Update the ADR if a new pattern emerged

After the fixes are verified, ask:

> Did this refactor reveal a pattern not already covered in ADR-0015?

If the answer is yes, update `docs/adr/0015-sonar-refactor-patterns.md`:

- Add the new rule to the Decision section as an imperative bullet.
- Add a Consequence if the change affects future refactors or tooling.
- Keep the ADR on one screen; if it grows, split the rule into a new ADR and update the README index.
- Run `pnpm exec prettier --write --list-different docs/adr/0015-sonar-refactor-patterns.md docs/adr/README.md`.
- Do not update the ADR for routine applications of existing patterns.

## References

- [`docs/adr/0015-sonar-refactor-patterns.md`](docs/adr/0015-sonar-refactor-patterns.md)
- [`docs/adr/test/0003-sonar-rule-hygiene-refactor-guardrails.md`](docs/adr/test/0003-sonar-rule-hygiene-refactor-guardrails.md)
- [`AGENTS.md`](AGENTS.md)
