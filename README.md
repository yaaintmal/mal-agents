# mal-agents 🐟

**Battle-tested agent skills. Built for real machines. Shared so other devs don't have to start from zero.**

A growing collection of agent skills I actually use across all my machines and environments. They are
**global, cross-environment, and work in any agent** — with a hard preference for **Arch (Garuda) Linux
running fish shell** because, well, of course.

> Why does this repo exist? To make devs' lives better. The best tooling is knowledge you can share —
> this is my open shelf of it.

## What's inside

Seven skills so far, each a self-contained folder with a `SKILL.md` (plus linked reference docs where needed).
Drop them anywhere your agent looks for skills, e.g. `~/.agents/skills/`.

| Skill | What it does | Platform | Docs |
| --- | --- | --- | --- |
| [`tdd`](tdd/) | Red-green-refactor, tracer bullets, vertical slices. Integration-style tests through public interfaces. | all | [tests](tdd/tests.md), [mocking](tdd/mocking.md), [deep-modules](tdd/deep-modules.md), [interface-design](tdd/interface-design.md), [refactoring](tdd/refactoring.md) |
| [`grill-with-docs`](grill-with-docs/) | Grilling session that stress-tests a plan against the existing domain model, sharpens terminology, and writes `CONTEXT.md` / ADRs inline. | all | [CONTEXT-FORMAT](grill-with-docs/CONTEXT-FORMAT.md), [ADR-FORMAT](grill-with-docs/ADR-FORMAT.md) |
| [`mal-reviewfix`](mal-reviewfix/) | Pre-merge quality gates: prettier + eslint/import-order, tsc, CVE audit (pnpm + snyk), Vitest coverage. Auto-fixes safe issues, writes `.reviewfix/report.json`. | open ⚠️ | [AGENT-BRIEF](mal-reviewfix/AGENT-BRIEF.md), [OUT-OF-SCOPE](mal-reviewfix/OUT-OF-SCOPE.md), [reference](mal-reviewfix/reference.md) |
| [`mentor-me`](mentor-me/) | Mentor-style code & architecture review of the feature you're building (React / Next.js / testing / CWV / architecture), each finding with a "Lernhinweis". | all | — |
| [`diagnose`](diagnose/) | Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test. | all | [hitl-loop.template.sh](diagnose/scripts/hitl-loop.template.sh) |
| [`to-issues`](to-issues/) | Break a plan, spec, or PRD into independently-grabbable, tracer-bullet vertical-slice issues. | all | — |
| [`handoff`](handoff/) | Compact the current conversation into a handoff document for another agent — with a "suggested skills" section — so a fresh session can continue the work. | all | — |

### Platform badges

- `all` — works on any OS / shell.
- `open ⚠️` — platform decision not finalised yet (looking at you, `mal-reviewfix`). The installer flags
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
        │ mal-reviewfix │─────┘   │ mentor-me          │
        │ quality gates │         │ mentor code review │
        └───────────────┘         └────────────────────┘
```

- **`to-issues`** hands off to **`tdd`** for the build loop and to **`grill-with-docs`** for the architecture work.
- **`tdd`** calls in **`grill-with-docs`** when a refactor touches domain language.
- **`mal-reviewfix`** routes coverage gaps to **`tdd`**, **`diagnose`**-style debugging, or **`grill-with-docs`**.
- **`mentor-me`** shares the same quality vocabulary (interface design, testing, architecture) — run it
  after a feature, before the gates.
- **`diagnose`** is the debugging lane — `mal-reviewfix` routes failures to it, and it hands architecture
  findings to `improve-codebase-architecture`.
- **`handoff`** compacts any session into a doc for the next agent, suggesting which skills to invoke —
  run it before a long break or a context swap.

More skills will join and the map will grow. A skill that links another skill is a skill that already
bought it a coffee.

## Install

### Quick — interactive menu (fish)

```fish
./install.fish
```

A small "opencode main menu": pick skills, it symlinks them into `~/.agents/skills/`. Idempotent,
OS-aware, no root needed.

### Everything, no questions

```fish
./install.fish --all
```

### Non-fish / CI

```bash
./install.sh --all
```

### Update after a `git pull`

```fish
git pull && ./install.fish --refresh
```

Symlinks mean your installed skills track this repo — update = re-sync.

See `./install.fish --help` for every mode (`--skill <name>`, `--unlink`, `--check`, ...).

> **Heads up:** every skill has a `disable-model-invocation` or auto-trigger policy for a reason. Read a
> `SKILL.md` before you enable it — you're hiring an opinionated junior dev, not a robot.

## Structure & conventions

```
mal-agents/
├── install.fish        # interactive installer (fish)
├── install.sh          # installer fallback (POSIX bash)
├── AGENTS.md           # conventions for agents working in this repo
├── SKILL-TEMPLATE.md   # canonical scaffold for adding a new skill
├── .gitignore
└── <skill-name>/
    ├── SKILL.md        # frontmatter: name, description, optional platforms:
    └── <supporting>.md # linked docs (references, formats, briefs)
```

Every skill folder is self-contained and relocatable — drop it in `~/.agents/skills/` and it works.

### Adding / editing a skill

1. Copy [`SKILL-TEMPLATE.md`](SKILL-TEMPLATE.md) into a new `<skill-name>/SKILL.md`.
2. Fill in `name`, `description` (trigger phrases + when to use), and `platforms:` if it's not universal.
3. Link any supporting docs next to it.
4. Reference sibling skills by name where the workflow calls for it — that's how the family grows.

See [`AGENTS.md`](AGENTS.md) for the conventions an agent should follow when working here.

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

- [x] First 7 skills in the family, cross-referenced
- [x] Interactive install menu (fish) + bash fallback
- [ ] Settle the open platform question for `mal-reviewfix` (and review the others)
- [ ] `improve-codebase-architecture` and friends join the family
- [ ] Screenshot-able usage examples per skill
- [ ] License + contribution guide (deliberately omitted for the first push)

## License

None yet — first push. Everything here is yours to read and learn from; ask before you ship it.
