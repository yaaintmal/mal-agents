#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# mal-agents installer — Bash fallback
#
# Same job as install.fish, for non-fish shells and CI. Idempotent. No root.
# If you can, run `./install.fish` instead — this is the tofu option.
#
# Usage:
#   ./install.sh                 interactive menu (pick skills)
#   ./install.sh --all           install every skill
#   ./install.sh --skill tdd     install specific skill(s) (repeatable)
#   ./install.sh --refresh       re-sync installed skills (after git pull)
#   ./install.sh --unlink        remove installed skills (--skill to scope)
#   ./install.sh --check         print status table, change nothing
#   ./install.sh --dest <dir>    install into a custom directory
#   ./install.sh --help
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${HOME}/.agents/skills"
MANIFEST_FILE=".mal-agents-installed"

# ── colors (best effort — degrade gracefully when not a tty) ─────────────────
if [ -t 1 ] && [ -n "${TERM:-}" ] && [ "$TERM" != "dumb" ]; then
    C_RESET="$(tput sgr0)"
    C_DIM="$(tput setaf 8)"
    C_BOLD="$(tput bold)"
    C_GREEN="$(tput setaf 2)"
    C_RED="$(tput setaf 1)"
    C_YELLOW="$(tput setaf 3)"
    C_CYAN="$(tput setaf 6)"
    C_MAGENTA="$(tput setaf 5)"
else
    C_RESET=""; C_DIM=""; C_BOLD=""; C_GREEN=""; C_RED=""; C_YELLOW=""; C_CYAN=""; C_MAGENTA=""
fi

usage() {
    cat <<'EOF'
usage: ./install.sh [options]

  (no options)          interactive menu
  -a, --all             install every skill
  -s, --skill <name>    install one or more skills (repeatable)
  -r, --refresh         re-sync installed skills (after git pull)
  -u, --unlink          remove installed skills (--skill to scope)
  -c, --check           print status table, change nothing
  -d, --dest <dir>      install into a custom directory
  -h, --help            show this help
EOF
}

# ── arg parsing ──────────────────────────────────────────────────────────────
ALL=0; REFRESH=0; UNLINK=0; CHECK=0; QUIET=0
SKILLS=()

while [ $# -gt 0 ]; do
    case "$1" in
        -a|--all)     ALL=1 ;;
        -r|--refresh) REFRESH=1 ;;
        -u|--unlink)  UNLINK=1 ;;
        -c|--check)   CHECK=1 ;;
        -q|--quiet)   QUIET=1 ;;
        -d|--dest)    DEST="$2"; shift ;;
        -s|--skill)   SKILLS+=("$2"); shift ;;
        -h|--help)    usage; exit 0 ;;
        *) echo "${C_RED}unknown option:${C_RESET} $1" >&2; usage >&2; exit 1 ;;
    esac
    shift
done

MANIFEST="$DEST/$MANIFEST_FILE"

# ── helpers ──────────────────────────────────────────────────────────────────

list_skills() {
    local name
    for dir in "$REPO_DIR"/*/; do
        name="$(basename "$dir")"
        [ -f "$REPO_DIR/$name/SKILL.md" ] && echo "$name"
    done | sort
}

skill_name_width() {
    local width=16 name
    while IFS= read -r name; do
        [ "${#name}" -gt "$width" ] && width="${#name}"
    done < <(list_skills)
    echo "$width"
}

platform_of() {
    local skill="$1" line
    line="$(grep -m1 '^platforms:' "$REPO_DIR/$skill/SKILL.md" 2>/dev/null || true)"
    if [ -z "$line" ]; then
        echo "all"
    else
        line="${line#*platforms:}"
        echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
    fi
}

git_rev() {
    if [ -d "$REPO_DIR/.git" ]; then
        git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || true
    fi
}

is_installed() { [ -L "$DEST/$1" ]; }

managed_skills() {
    local skill _rev
    [ -f "$MANIFEST" ] || return 0
    while read -r skill _rev; do
        [ -n "$skill" ] && echo "$skill"
    done < "$MANIFEST"
}

write_manifest() {
    local rev skill
    local -a skills=()
    if [ "$#" -gt 0 ]; then
        mapfile -t skills < <(printf '%s\n' "$@" | sort -u)
    else
        mapfile -t skills < <(managed_skills)
    fi

    rm -f "$MANIFEST"
    rev="$(git_rev)"
    if [ -n "$rev" ]; then
        for skill in "${skills[@]}"; do
            [ -f "$REPO_DIR/$skill/SKILL.md" ] && echo "$skill $rev" >> "$MANIFEST"
        done
    fi
}

manifest_rev() {
    local skill="$1" line
    [ -f "$MANIFEST" ] || return 0
    line="$(grep -m1 "^$skill " "$MANIFEST" 2>/dev/null || true)"
    [ -n "$line" ] && echo "${line#* }"
}

status_of() {
    local skill="$1" cur stored
    if ! is_installed "$skill"; then
        echo "○  available"
    else
        cur="$(git_rev)"
        stored="$(manifest_rev "$skill")"
        if [ -n "$cur" ] && [ -n "$stored" ] && [ "$cur" != "$stored" ]; then
            echo "▲  update"
        else
            echo "✓  installed"
        fi
    fi
}

render_row() {
    local idx="$1" skill="$2" plat status p s
    local marker="${3:-}" checked="${4:-}"
    plat="$(platform_of "$skill")"
    status="$(status_of "$skill")"

    case "$plat" in
        all) p="${C_CYAN}[$plat]${C_RESET}" ;;
        *)   p="${C_YELLOW}[$plat]${C_RESET}" ;;
    esac

    case "$status" in
        *installed) s="${C_GREEN}✓${C_RESET}" ;;
        *update)    s="${C_YELLOW}▲${C_RESET}" ;;
        *)          s="${C_DIM}○${C_RESET}" ;;
    esac

    if [ -n "$marker" ]; then
        printf '  %s [%s] %-3s %-*s %-10s %s\n' \
            "$marker" "$checked" "$idx" "$SKILL_WIDTH" "$skill" "$p" "$status"
    else
        printf '  %-3s %-*s %-10s %s\n' \
            "$idx" "$SKILL_WIDTH" "$skill" "$p" "$status"
    fi
}

install_skill() {
    local skill="$1"
    mkdir -p "$DEST"
    ln -sfn "$REPO_DIR/$skill" "$DEST/$skill"
    printf '%s  %s%s%s\n' "${C_GREEN}+${C_RESET}" "$skill" "${C_DIM}" " → $DEST/$skill${C_RESET}"
}

unlink_skill() {
    local skill="$1"
    if is_installed "$skill"; then
        rm -f "$DEST/$skill"
        printf '%s  %s%s%s\n' "${C_RED}-${C_RESET}" "$skill" "${C_DIM}" " (removed)${C_RESET}"
    else
        printf '%s  %s%s%s\n' "${C_DIM}·${C_RESET}" "$skill" "${C_DIM}" " (not installed)${C_RESET}"
    fi
}

distro_name() {
    local pretty
    if [ -f /etc/os-release ]; then
        pretty="$(grep -m1 '^PRETTY_NAME=' /etc/os-release 2>/dev/null || true)"
        pretty="${pretty#PRETTY_NAME=}"; pretty="${pretty%\"}"; pretty="${pretty#\"}"
        case "$pretty" in
            *Garuda*|*garuda*) echo "Garuda (Arch) 🐟"; return ;;
            *Arch*|*arch*)     echo "Arch"; return ;;
            *)                 echo "$pretty"; return ;;
        esac
    fi
    case "$(uname -s)" in
        Darwin) echo "macOS" ;;
        *)      uname -s ;;
    esac
}

banner() {
    printf '\n'
    printf '%s%s%s\n' "${C_BOLD}${C_CYAN}" '  ┌─────────────────────────────────────────────┐' "${C_RESET}"
    printf '%s%s%s\n' "${C_BOLD}${C_CYAN}" '  │      mal-agents · collection installer      │' "${C_RESET}"
    printf '%s%s%s\n' "${C_BOLD}${C_CYAN}" '  │         battle-tested skills, shipped       │' "${C_RESET}"
    printf '%s%s%s\n' "${C_BOLD}${C_CYAN}" '  └─────────────────────────────────────────────┘' "${C_RESET}"
    printf '\n'
    printf '  %sos:%s %s  %sshell:%s %s  %s→%s %s\n' \
        "${C_DIM}" "${C_RESET}" "$(distro_name)" \
        "${C_DIM}" "${C_RESET}" "$(basename "${SHELL:-unknown}")" \
        "${C_DIM}" "${C_RESET}" "$DEST"
    printf '\n'
}

SKILL_WIDTH="$(skill_name_width)"

interactive_menu() {
    local -a selected=()
    local i key sequence all_selected

    for i in "${!skills[@]}"; do
        if is_installed "${skills[$i]}"; then
            selected[$i]=1
        else
            selected[$i]=0
        fi
    done

    draw_menu() {
        local j marker checked
        for j in "${!skills[@]}"; do
            if [ "$j" -eq "$cursor" ]; then marker="❯"; else marker=" "; fi
            if [ "${selected[$j]}" -eq 1 ]; then checked="x"; else checked=" "; fi
            render_row "$((j + 1))" "${skills[$j]}" "$marker" "$checked"
        done
        printf '  %s↑/↓ move · Space select · a all · Enter confirm · q cancel%s\n' \
            "$C_DIM" "$C_RESET"
    }

    cursor=0
    printf '  %sAvailable skills%s\n\n' "${C_BOLD}" "${C_RESET}"
    draw_menu
    printf '\033[?25l'
    cleanup_menu() {
        printf '\033[?25h'
    }
    trap cleanup_menu EXIT
    trap 'cleanup_menu; exit 130' INT TERM

    while true; do
        key=""
        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')
                sequence=""
                IFS= read -rsn2 -t 0.1 sequence || true
                case "$sequence" in
                    '[A') cursor=$((cursor - 1)) ;;
                    '[B') cursor=$((cursor + 1)) ;;
                    *) PICKS=(); return 0 ;;
                esac
                ;;
            $'\x0a'|$'\x0d')
                break
                ;;
            " ")
                if [ "${selected[$cursor]}" -eq 1 ]; then
                    selected[$cursor]=0
                else
                    selected[$cursor]=1
                fi
                ;;
            j) cursor=$((cursor + 1)) ;;
            k) cursor=$((cursor - 1)) ;;
            a)
                all_selected=1
                for i in "${!skills[@]}"; do
                    [ "${selected[$i]}" -eq 1 ] || all_selected=0
                done
                for i in "${!skills[@]}"; do
                    if [ "$all_selected" -eq 1 ]; then selected[$i]=0; else selected[$i]=1; fi
                done
                ;;
            q)
                PICKS=()
                return 0
                ;;
        esac

        [ "$cursor" -lt 0 ] && cursor=$((${#skills[@]} - 1))
        [ "$cursor" -ge "${#skills[@]}" ] && cursor=0
        printf '\033[%dA' "$((${#skills[@]} + 1))"
        printf '\033[2K\r'
        draw_menu
    done

    PICKS=()
    for i in "${!skills[@]}"; do
        [ "${selected[$i]}" -eq 1 ] && PICKS+=("${skills[$i]}")
    done
}

# ── main ─────────────────────────────────────────────────────────────────────
[ "$QUIET" -eq 1 ] || banner

if [ "$CHECK" -eq 1 ]; then
    for skill in $(list_skills); do
        render_row "" "$skill"
    done
    printf '\n  %sdest:%s %s\n' "${C_DIM}" "${C_RESET}" "$DEST"
    exit 0
fi

if [ "$UNLINK" -eq 1 ]; then
    targets=()
    if [ ${#SKILLS[@]} -gt 0 ]; then
        targets=("${SKILLS[@]}")
    else
        mapfile -t targets < <(managed_skills)
    fi
    if [ ${#targets[@]} -eq 0 ]; then
        echo "  nothing installed — nothing to do."
        exit 0
    fi
    for skill in "${targets[@]}"; do
        unlink_skill "$skill"
    done
    remaining=()
    while read -r skill; do
        skip=0
        for target in "${targets[@]}"; do
            [ "$skill" = "$target" ] && skip=1 && break
        done
        [ "$skip" -eq 0 ] && remaining+=("$skill")
    done < <(managed_skills)
    write_manifest "${remaining[@]}"
    exit 0
fi

if [ "$REFRESH" -eq 1 ]; then
    targets=()
    mapfile -t targets < <(managed_skills)
    if [ ${#targets[@]} -eq 0 ]; then
        echo "  nothing installed — run without flags to pick some."
        exit 0
    fi
    for skill in "${targets[@]}"; do
        install_skill "$skill"
    done
    write_manifest "${targets[@]}"
    printf '\n  %s✓%s re-synced %d skill(s)\n' "${C_GREEN}" "${C_RESET}" "${#targets[@]}"
    exit 0
fi

if [ "$ALL" -eq 1 ]; then
    for skill in $(list_skills); do
        install_skill "$skill"
    done
    write_manifest $(list_skills)
    printf '\n  %s✓%s installed all skills\n' "${C_GREEN}" "${C_RESET}"
    exit 0
fi

if [ ${#SKILLS[@]} -gt 0 ]; then
    for skill in "${SKILLS[@]}"; do
        if [ -f "$REPO_DIR/$skill/SKILL.md" ]; then
            install_skill "$skill"
        else
            printf '%s  %s%s%s\n' "${C_RED}!${C_RESET}" "$skill" "${C_DIM}" " (no such skill)${C_RESET}"
        fi
    done
    write_manifest $(managed_skills) "${SKILLS[@]}"
    exit 0
fi

# ── interactive menu ─────────────────────────────────────────────────────────
mapfile -t skills < <(list_skills)

if [ ${#skills[@]} -eq 0 ]; then
    echo "  no skills found in $REPO_DIR"
    exit 1
fi

if [ -t 0 ] && [ -t 1 ]; then
    interactive_menu
    picks=("${PICKS[@]}")
else
    printf '  %sAvailable skills%s\n\n' "${C_BOLD}" "${C_RESET}"
    idx=0
    for skill in "${skills[@]}"; do
        idx=$((idx + 1))
        render_row "$idx" "$skill"
    done

    printf '\n  %sEnter numbers %s%s for all, or %s%s to quit: %s' \
        "${C_DIM}" \
        "${C_CYAN}a${C_RESET}" \
        "${C_YELLOW}q${C_RESET}" \
        "${C_RESET}"

    read -r answer

    picks=()
    IFS=' ,' read -ra tokens <<< "$answer"
    for tok in "${tokens[@]}"; do
        case "$tok" in
            a|all) picks=("${skills[@]}") ;;
            q) echo "  bye 👋"; exit 0 ;;
            *)
                if [[ "$tok" =~ ^[0-9]+$ ]] && [ "$tok" -ge 1 ] && [ "$tok" -le "${#skills[@]}" ]; then
                    picks+=("${skills[$((tok - 1))]}")
                fi
                ;;
        esac
    done
fi

if [ ${#picks[@]} -gt 0 ]; then
    printf '\n'
    for skill in "${picks[@]}"; do
        install_skill "$skill"
    done
    write_manifest $(managed_skills) "${picks[@]}"
    printf '\n  %s✓%s done — %d skill(s) linked into %s\n' \
        "${C_GREEN}" "${C_RESET}" "${#picks[@]}" "$DEST"
else
    echo "  nothing selected — no changes."
fi
