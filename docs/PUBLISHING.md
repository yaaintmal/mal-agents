# PUBLISHING.md — mal-agents an npm veröffentlichen

> **Nur für Maintainer.** Dieses Howto ist bewusst NICHT öffentlich: es ist weder im `README.md`
> verlinkt noch im npm-Tarball enthalten (`docs/` steht nicht in der `files`-Whitelist in `package.json`).

## Voraussetzungen

- Node ≥ 14 (laut `engines` in `package.json`).
- npm-Account, einmalig eingeloggt: `npm login`.
- Paketname **`mal-agents`** muss frei sein: `npm view mal-agents`
  → `404 Not Found` = frei. Nach der **ersten** Publikation ist der Name dauerhaft vergeben.

## Pre-Flight — vor jedem Release

1. **Tarball prüfen:**
   ```bash
   npm pack --dry-run
   ```
   Muss enthalten: `bin/cli.js`, `scripts/install.fish`, `scripts/install.sh`, **jeden** Skill-Ordner.
   Kein Junk (`.zed/`, `node_modules/`, `.tgz`, Logs). — Fehlt ein Skill-Ordner, steht er nicht in der
   `files`-Whitelist (siehe unten).
2. **Installer-Gesundheit:**
   ```bash
   ./scripts/install.fish --check   # → 10 Skills gelistet
   ./scripts/install.sh --check     # → identisch
   ```
3. **Version bumpen:** `version` in `package.json` nach semver (aktuell `1.0.0`).
4. Optional: echter Tarball ohne Upload, als aussagekräftigerer Preflight:
   ```bash
   npm publish --dry-run
   ```

## Publish

```bash
npm run publish:cli   # = npm publish --access public
```

## Nach dem Publish — verifizieren

```bash
npm view mal-agents version   # zeigt die neue Version
```

Danach auf einem sauberen Rechner (nicht auf der Dev-Maschine) wirklich testen:

```bash
npx mal-agents --check                      # Status, nichts installiert
npx mal-agents --dest /tmp/mtg --skill tdd  # Symlink + Manifest in /tmp/mtg
```

## Neue Skill-Ordner = neue `files`-Einträge

Jeder neue Skill-Ordner MUSS in die `files`-Whitelist von `package.json` aufgenommen werden
(AGENTS.md, Regel 6), sonst fehlt er im Tarball (`npx mal-agents` kann ihn nie installieren).
Check immer über `npm pack --dry-run`.

## Update-Routine & Fallen

- Reihenfolge: `git commit` → `version` bumpen → `npm run publish:cli`.
- `docs/PUBLISHING.md` selbst wird nie gepusht — `docs/` liegt nicht in `files`.
- README bleibt öffentlich und ohne Publish-Anleitung; die Einträge dort setzen `npx mal-agents` voraus.