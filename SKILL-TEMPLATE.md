---
name: <skill-name>
description: >-
  One-paragraph trigger-rich description. List the phrases users say, the exact
  use-cases ("use when ..."), and any slash-invocations. This is the contract a
  model reads to decide whether to load you.
platforms: all
---

# <Skill Title>

One or two sentences on what this skill does and when to reach for it. Example:

> Use this when you want to X, or when the user says "foo", "bar", or "I need a baz".

## The idea

The core principle in 2–4 lines. What problem does it solve, and what's the mental
model someone should hold? Keep it honest and opinionated — skills are personal.

## Workflow

### 1. First step

Concrete numbered steps. Ask questions one at a time where decisions matter. Refer to
supporting docs by **relative path**:

See [reference.md](reference.md) for the exact procedure.

### 2. Next step

Only enough depth for the skill to run. Push the rest into linked docs.

## Checklist

```
[ ] Thing to verify before done
[ ] Another gate
[ ] Hand off to a sibling skill by name when relevant (e.g. "invoke /tdd")
```

## Done when

- [ ] The output is produced / behaviour verified
- [ ] No unsolicited side effects (commits, file edits the user didn't ask for)

---

## Adding this skill to the family

- [ ] Frontmatter above is filled in (`name` matches folder, `description` is trigger-rich)
- [ ] `platforms:` reflects reality (`all`, or a specific set — use `open` while undecided)
- [ ] Supporting docs live **next to** `SKILL.md`, linked relatively
- [ ] `README.md` skill index table updated
- [ ] Cross-references to sibling skills use their **names**, not paths
