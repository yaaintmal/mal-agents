name: mentor-me
description: Performs a mentor-style code and architecture review of the feature currently being developed. Checks against Next.js App Router, React best practices, testing standards, Core Web Vitals, identifies bugs, anti-patterns, architectural shortcomings, and performance issues. Each finding includes a "Lernhinweis" (learning comment), a concrete code suggestion, and a clear problem description. Findings are saved to a timestamped .md review file. Use when the user says "/meme", "mentor me", "review my feature", or asks for a mentor code review.

### Mentor Me – Code & Architecture Review

# Goal

Perform a mentor-level review of the feature currently being developed.

Outcome: a structured .md review file with actionable findings, each with a learning comment inside the project under /docs or similar if present.

# Trigger

User says /meme or "mentor me".

## Step 1 – Discover Scope

Read the git status to find all changed/new files for this feature.
If multiple features are in flight, ask the user which files to include.
Read all in-scope files before writing any findings.

---

## Step 2 – Review Dimensions

Check each file against all applicable dimensions:

# React
Unnecessary re-renders (missing useMemo, useCallback, unstable refs)
useEffect misuse (missing deps, side effects that belong on server, cleanup gaps)
State shape design (over-normalised or under-normalised)
useState vs useReducer fit
Component responsibility (doing too much, should be split)
Missing or wrong key props in lists
Prop drilling vs context vs lifting state

# Next.js App Router
Server vs Client Component boundary placement
Initial page data in useEffect instead of Server Component
Mutations not using Server Actions
Server Actions missing auth/authz check
Sensitive logic leaking into Client Components
Missing or wrong revalidatePath / revalidateTag calls
Incorrect use of "use client" (added speculatively, not needed)
Route segment config (dynamic, revalidate) correctness

# Testing & Resilience
Testability: Is the code structured to facilitate testing (e.g., extraction of pure functions, dependency injection)?

Test Coverage: Are unit or integration tests (e.g., using Jest, Vitest, Testing Library) provided for critical logic, edge cases, and new hooks?

Error Handling: Are robust fallbacks (e.g., ErrorBoundary, Next.js error.tsx) implemented to handle unexpected runtime errors gracefully?

# Performance & Core Web Vitals
Metric Impact: Does the implementation negatively impact Core Web Vitals—specifically LCP (Large Contentful Paint) due to blocking script execution or TBT (Total Blocking Time) due to excessive client-side CPU usage?
Layout Shifts: Do dynamically loaded components or missing image dimensions cause CLS (Cumulative Layout Shift)?
Streaming & Suspense: Are slow data sources appropriately wrapped in Suspense boundaries to enable efficient selective HTML streaming?

# Code Quality

Duplicated logic that should be extracted
Overly complex abstractions for single-use code
Magic values / missing constants
Error states not handled (loading, empty, error)
Dead code or unreachable branches
Incorrect TypeScript types (any, non-null assertions without guard)

# Architecture

Responsibility misplacement (DB access in component, business logic in UI layer)
Missing separation between data-fetching and rendering
Premature generalisation
Naming that doesn't reflect intent

--- 

## Step 3 – Write Findings

For every finding, use this exact structure:

### [SHORT TITLE]

**Datei:** `path/to/file.tsx` (Zeile X–Y)  
**Kategorie:** React | Next.js | Testing & Resilienz | Performance & UX | Code Quality | Architecture  
**Schweregrad:** 🔴 Kritisch | 🟡 Verbesserung | 🟢 Nice-to-have

**Problem** [Concrete description of what is wrong and why it matters.]

**Lernhinweis** [Plain-language explanation of the underlying concept. What rule/pattern applies here?
Link a concept, not a URL. E.g. "Server Components run only on the server – they never ship JS to the browser.
Putting a DB call there keeps it off the client bundle entirely."]

**Codevorschlag** ```tsx
// show the fix – before/after or just the corrected version



---

## Step 4 – Write the Review File

Save findings to:

```
.cursor/reviews/YYYY-MM-DD-<feature-slug>.md
```


File structure:

# Code Review – <Feature Name>
_Datum: YYYY-MM-DD_

## Zusammenfassung
[2–4 sentences: overall quality, biggest risks, main theme of findings.]

## Befunde

[All findings in Step 3 format, grouped by Schweregrad: 🔴 first, then 🟡, then 🟢]

## Nächste Schritte
[Ordered list: what to fix first, what to revisit later.]


## Step 5 – Deliver Summary to User

After writing the file, output a short summary in chat:
Total finding count by severity
The 1–2 most critical issues in one sentence each
Path to the review file

# Rules
Never fix code silently. Only report. User decides what to change.
Every finding must have a Lernhinweis. No exceptions.
If a file is clean, say so explicitly in the summary ("keine Befunde").
Match severity honestly: not everything is 🔴.
Keep Lernhinweis in German (Lernhinweis) and code/paths in exact original casing.