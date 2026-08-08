# /mal-reviewfix reference

## Invocation and scope

The skill is slash-only. Parse these options before running gates:

| Option | Behavior |
| --- | --- |
| no option | Review changed files against `main` or `origin/main` |
| `--all` | Use repo-wide lint and coverage scope |
| `--fast` | Run `pnpm run tsc:app`; otherwise run `pnpm run tsc` |
| `--base <ref>` | Use the supplied Git ref instead of the default |

`--all` changes scope only; it does not skip any gate. `--fast` changes the
TypeScript command only. If an option is malformed, stop and report it rather
than silently changing scope.

## Change set

For the default scope, resolve the base and union all three sources of work:

```bash
BASE="${BASE_REF:-main}"
BASE_COMMIT="$(git merge-base HEAD "$BASE" 2>/dev/null || git merge-base HEAD "origin/$BASE")"
{
  git diff --name-only "$BASE_COMMIT"...HEAD
  git diff --name-only --cached --diff-filter=ACMR
  git diff --name-only --diff-filter=ACMR
} | sort -u
```

Filter the union to existing lintable sources (`ts`, `tsx`, `js`, `jsx`, `mjs`,
`cjs`) in the project source/test directories. Exclude deleted files, lockfiles,
images, and Markdown unless the user explicitly includes them. The cached diff
is required: `git diff` without `--cached` does not show staged changes.

If the filtered set is empty and `--all` is absent, write a green
“nothing to review” report and stop. Create `.reviewfix/` only when a report or
audit artifact must be written.

## Push parity and runtime

Keep the three change-set buckets in the report: `committed`, `staged`, and
`unstaged`. A passing check on an unstaged or staged file does not prove that
the pushed `HEAD` contains that fix. Before declaring a push-ready result,
compare each changed file with `HEAD`:

```bash
git diff --name-only HEAD -- <changed files>
git diff --cached --name-only -- <changed files>
```

If a fix exists outside `HEAD`, record it in `workingTreeOnly` and `nextSteps`,
then tell the user to stage and commit it. Never imply that CI will see an
uncommitted working-tree fix.

Check runtime parity separately from the quality gates:

```bash
node --version
node -p 'require("./package.json").engines?.node ?? "unspecified"'
cat .github/nodejs.version
```

Report mismatches between the active local Node, `package.json`'s engine range,
and `.github/nodejs.version` as a warning or failure. `--fast` is a diagnostic
shortcut only; it is not CI parity when CI runs full `pnpm run tsc`.

## Gate commands

### Gate 1 — lint and TypeScript

```bash
pnpm run prettier:fix -- <changed files>
pnpm exec eslint --fix --quiet <changed ts/tsx/js files>
pnpm exec eslint --quiet <same files>
pnpm run tsc                 # exact CI parity
```

Use a long command timeout: at least 300 seconds for ESLint and 600 seconds
for full TypeScript. Run `pnpm run tsc:app` only when the user explicitly
chooses `--fast`, and label that result as non-CI parity. Fix local, obvious
errors introduced by this session. Ask before behavior changes or unrelated
repairs.

### Gate 2 — CVE audit

```bash
pnpm audit --json > .reviewfix/pnpm-audit.json || true
command -v snyk && snyk test --json > .reviewfix/snyk.json || true
```

Parse high and critical findings, including package, severity, advisory path,
and `fixAvailable`. Missing Snyk is a warning, not a failure. Do not bump
dependencies, rewrite the lockfile, or duplicate an existing Dependabot/Snyk
fix without user approval.

### Gate 3 — coverage

Run scoped coverage against matching unit specs:

```bash
pnpm vitest run --config ./vitest.config.mts --project unit-tests --coverage \
  <matching tests/unit-tests/**/*.spec.ts files>
```

Find or extend the mirrored `tests/unit-tests/**/*.spec.ts` for each changed
source. Do not pass bare production source paths as Vitest test targets. With
`--all`, omit path filters. Inspect the text summary and `coverage/lcov.info`.

Local coverage is an indicator. SonarQube “Coverage on New Code” is authoritative
for CI. Treat local lines around 42% or higher with few uncovered changed lines
as a provisional PASS plus warning. Treat large uncovered helpers or 0% changed
files as FAIL and rank hotspots by uncovered lines.

ROI order: hook/pure → extract a colocated `*-utils.ts` and add a node Vitest
spec; thin presentational → light jsdom mount; heavy Magic Chat/Milkdown/sidebar
shell → skip for Sonar percentage. Invoke `/tdd`, `/diagnose`, or
`/grill-with-docs` only for a failing gate with a clear bounded seam. Ask before
work estimated above one hour or above three new utility modules.

## ESLint 10 `import/order` recovery

If `--fix` throws `getTokenOrCommentBefore is not a function`:

1. Record the file named by `Occurred while linting <path>`.
2. Never retry `--fix` on that file in this session.
3. Order external/builtin imports first, then internal `@/` imports, sibling
   `./`, parent `../`, and index imports; alphabetize within groups.
4. For tests, keep post-`vi.mock` SUT imports together and alphabetized.
5. Verify with `pnpm exec eslint --quiet <file>` without `--fix`.

## Report contract

Write `.reviewfix/report.json` with this minimum shape:

```ts
type GateStatus = "pass" | "fail" | "warn"

type Report = {
  skill: "mal-reviewfix"
  timestamp: string
  base: string
  scope: "changed" | "all"
  changeset: string[]
  changeBuckets: {
    committed: string[]
    staged: string[]
    unstaged: string[]
  }
  workingTreeOnly: string[]
  runtime: {
    localNode: string
    packageEngine: string | null
    ciNode: string
    status: GateStatus
  }
  gates: {
    lint: { status: GateStatus; eslintExit: number; importOrderManualFixes: string[]; notes: string[] }
    tsc: { status: GateStatus; command: string; errorCount: number; notes: string[] }
    cve: {
      status: GateStatus
      pnpmAudit: { high: number; critical: number; path: string }
      snyk: { available: boolean; high: number; critical: number; path: string | null }
    }
    coverage: {
      status: GateStatus
      localLinesPct: number | null
      targetPct: 42
      sonarAuthoritative: true
      uncoveredHotspots: { file: string; uncoveredLines: number }[]
      roi: { file: string; strategy: string; priority: "P0" | "P1" | "P2" | "skip" }[]
    }
  }
  nextSteps: string[]
  subskillsInvoked: string[]
}
```

Always include the Sonar-authority warning in `notes` or `nextSteps`, record
every gate as pass/fail/warn, and print:

```text
## /mal-reviewfix
Gate 1 lint/tsc .......... PASS|FAIL
Gate 2 CVE ............... PASS|FAIL|WARN
Gate 3 coverage (≥42%) ... PASS|FAIL|WARN  (local indicator; Sonar authoritative)
Report: .reviewfix/report.json
```
