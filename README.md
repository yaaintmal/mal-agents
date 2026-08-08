# mal-agents 🐟

**Battle-tested agent skills. Built for real machines. Shared so other devs don't have to start from zero.**

A growing collection of agent skills I actually use across all my machines and environments. They are
**global, cross-environment, and work in any agent** — with a hard preference for **Arch (Garuda) Linux
running fish shell** because, well, of course.

> Why does this repo exist? To make devs' lives better. The best tooling is knowledge you can share —
> this is my open shelf of it.

## What's inside

Ten skills so far, each a self-contained folder with a `SKILL.md` (plus linked reference docs where needed).
Drop them anywhere your agent looks for skills, e.g. `~/.agents/skills/`.

| Skill | What it does | Platform | Docs |
| --- | --- | --- | --- |
| [`diagnose`](diagnose/) | Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test. | all | [hitl-loop.template.sh](diagnose/scripts/hitl-loop.template.sh) |
| [`grill-with-docs`](grill-with-docs/) | Grilling session that stress-tests a plan against the existing domain model, sharpens terminology, and writes `CONTEXT.md` / ADRs inline. | all | [CONTEXT-FORMAT](grill-with-docs/CONTEXT-FORMAT.md), [ADR-FORMAT](grill-with-docs/ADR-FORMAT.md) |
| [`handoff`](handoff/) | Compact the current conversation into a handoff document for another agent — with a "suggested skills" section — so a fresh session can continue the work. | all | — |
| [`mal-reviewfix`](mal-reviewfix/) | Pre-merge quality gates: prettier + eslint/import-order, tsc, CVE audit (pnpm + snyk), and Vitest coverage. Auto-fixes safe issues and writes `.reviewfix/report.json`. | all | [AGENT-BRIEF](mal-reviewfix/AGENT-BRIEF.md), [OUT-OF-SCOPE](mal-reviewfix/OUT-OF-SCOPE.md), [reference](mal-reviewfix/reference.md) |
| [`mal-sonar-refacplan`](mal-sonar-refacplan/) | Turns SonarQube findings into a focused refactor plan, executes approved fixes, and updates the project's Sonar refactor ADR when needed. | all | — |
| [`mentor-me`](mentor-me/) | Mentor-style code and architecture review for React / Next.js features, testing, Core Web Vitals, and architecture. Findings include a German "Lernhinweis". | all | — |
| [`tdd`](tdd/) | Red-green-refactor, tracer bullets, vertical slices, and integration-style tests through public interfaces. | all | [tests](tdd/tests.md), [mocking](tdd/mocking.md), [deep-modules](tdd/deep-modules.md), [interface-design](tdd/interface-design.md), [refactoring](tdd/refactoring.md) |
| [`to-issues`](to-issues/) | Breaks a plan, spec, or PRD into independently-grabbable, tracer-bullet vertical-slice issues. | all | — |
| [`triage`](triage/) | Moves issue-tracker items through category and state roles, including reproduction, triage notes, and agent briefs. | all | [AGENT-BRIEF](triage/AGENT-BRIEF.md), [OUT-OF-SCOPE](triage/OUT-OF-SCOPE.md) |
| [`write-a-skill`](write-a-skill/) | Guides the creation of new agent skills with proper structure, progressive disclosure, and bundled resources. | all | — |

### Platform badges

- `all` — works on any OS / shell.
- `open ⚠️` — platform decision not finalised yet. The installer flags
  these so you can decide consciously before enabling.
- `[linux·arch]` style tags may appear later as more skills declare preferences.

## How these skills know each other

The skills are a **family**, not a pile. They cross-reference on purpose:

```
                     ┌─────────────┐
                     │ to-issues   │  breaks plans into vertical slices
                     └──────┬──────┘
                            │ slices become work
               ┌────────────┴─────────────┐
               ▼                          ▼
         ┌─────────────┐           ┌─────────────────┐
         │ tdd         │           │ grill-with-docs │  stress-tests the plan
         │ red-green   │◄──────┐   │  + CONTEXT/ADR  │  against domain docs
         └──────┬──────┘       │   └───────┬─────────┘
                │              │           │
                ▼              │           ▼
         ┌───────────────┐     │   ┌────────────────────┐
         │ mal-reviewfix │─────┘   │ triage             │
         │ quality gates │         │ issue workflow      │
         └───────────────┘         └────────────────────┘
```

- **`to-issues`** hands off to **`tdd`** for the build loop and to **`grill-with-docs`** for the architecture work.
- **`triage`** hands underspecified issues to **`grill-with-docs`** and can prepare issues for AFK agents.
- **`tdd`** calls in **`grill-with-docs`** when a refactor touches domain language.
- **`mal-reviewfix`** routes coverage gaps to **`tdd`**, **`diagnose`**-style debugging, or **`grill-with-docs`**.
- **`mentor-me`** shares the same quality vocabulary (interface design, testing, architecture) — run it
  after a feature, before the gates.
- **`diagnose`** is the debugging lane — `mal-reviewfix` routes failures to it. If diagnosis exposes a
  structural problem, hand it to `improve-codebase-architecture` when that sibling skill is available.
- **`mal-sonar-refacplan`** handles SonarQube-driven refactors and keeps the project's refactor ADR current.
- **`write-a-skill`** is the contribution lane for adding another skill to the family.
- **`handoff`** compacts any session into a doc for the next agent, suggesting which skills to invoke —
  run it before a long break or a context swap.

More skills will join and the map will grow. A skill that links another skill is a skill that already
bought it a coffee.

## Install

### Quick — via npx (any shell, no clone needed)

```bash
npx mal-agents                  # interactive menu
npx mal-agents --all            # everything, no questions
npx mal-agents --check          # status table, no changes
```

`mal-agents` detects your shell and runs the matching installer (`scripts/install.fish` for fish,
`scripts/install.sh` otherwise). Every flag of the installer works through npx: `--skill <name>`
(repeatable), `--unlink`, `--refresh`, `--dest <dir>`.

### From a clone — interactive menu (fish)

```fish
./scripts/install.fish
```

A small "opencode main menu": pick skills, it symlinks them into `~/.agents/skills/`. Idempotent,
OS-aware, no root needed.

### Everything, no questions

```fish
./scripts/install.fish --all
```

### Non-fish / CI

```bash
./scripts/install.sh --all
```

### Update after a `git pull`

```fish
git pull && ./scripts/install.fish --refresh
```

Symlinks mean your installed skills track this repo — update = re-sync.

See `./scripts/install.fish --help` for every mode (`--skill <name>`, `--unlink`, `--check`, ...).

> **Heads up:** every skill has a `disable-model-invocation` or auto-trigger policy for a reason. Read a
> `SKILL.md` before you enable it — you're hiring an opinionated junior dev, not a robot.

## Structure & conventions

```
mal-agents/
├── bin/
│   └── cli.js          # npm/npx entry — detects shell, runs the installer
├── scripts/
│   ├── install.fish    # interactive installer (fish)
│   └── install.sh      # installer fallback (Bash)
├── package.json        # npm publishing (bin, files whitelist, engines)
├── SKILL-TEMPLATE.md   # canonical scaffold for adding a new skill
├── .gitignore          # full secure cross-env (vim/emacs get love)
└── <skill-name>/
    ├── SKILL.md        # frontmatter: name, description, optional platforms:
    └── <supporting>.md # linked docs (references, formats, briefs)
```

Install via `npx mal-agents`, or from a clone via `./scripts/install.fish`. Every skill folder is
self-contained and relocatable — drop it in `~/.agents/skills/` and it works.

### Adding / editing a skill

1. Copy [`SKILL-TEMPLATE.md`](SKILL-TEMPLATE.md) into a new `<skill-name>/SKILL.md`.
2. Fill in `name`, `description` (trigger phrases + when to use), and `platforms:` if it's not universal.
3. Link any supporting docs next to it.
4. Reference sibling skills by name where the workflow calls for it — that's how the family grows.

## Credits & origins

Gratefully built on other people's brilliant work — lightly tuned, then given a home:

| Skill | Origin |
| --- | --- |
| `tdd`, `grill-with-docs`, `to-issues`, `diagnose`, `handoff` | Created by [Matt Pocock](https://github.com/mattpocock/skills), lightly adjusted |
| `mentor-me` | Created by [Alex Kawa ("Paddy")](https://github.com/AlexKawaPaddy) |
| `mal-reviewfix`, the collection, installer & this repo | [Pierre-Malick](https://github.com/Pierre-Malick) a.k.a. **yaaintmal** |

> The installer (`install.fish` / `install.sh`), the family structure, `mal-reviewfix`, and the collection
> are originals from **yaaintmal** — the shelf they all live on. Everything else is a loving, lightly-tuned
> fork of the best skills + devz out there. Creditz where it's due 🙌🏽 🫶🏽

## Roadmap

- [x] Current 10 skills in the family, cross-referenced
- [x] Interactive install menu (fish) + bash fallback
- [x] npm packaging — installable via `npx mal-agents`
- [ ] Ship `mal-agents` to the npm registry (`npm run publish:cli`)
- [x] Settle the open platform question — `mal-reviewfix` is now `all`; the generic `open` convention stays for future skills
- [ ] Screenshot-able usage examples per skill
- [x] License — MIT, see [`LICENSE`](LICENSE)

## License

MIT — see [`LICENSE`](LICENSE). Portions of this collection derive from third-party work and keep
their original attribution (see [Credits & origins](#credits--origins)).
