#!/usr/bin/env fish
# ─────────────────────────────────────────────────────────────────────────────
# mal-agents installer — "opencode main menu"
#
# Symlinks skills from this repo into your agent's skill directory.
# Interactive by default, scriptable when you need it. Idempotent. No root.
#
# Usage:
#   ./install.fish                interactive menu (pick skills)
#   ./install.fish --all          install every skill
#   ./install.fish --skill tdd    install specific skill(s) (repeatable)
#   ./install.fish --refresh      re-sync installed skills (after git pull)
#   ./install.fish --unlink       remove installed skills (--skill to scope)
#   ./install.fish --check        show status table, change nothing
#   ./install.fish --dest <dir>   install into a custom directory
#   ./install.fish --help
# ─────────────────────────────────────────────────────────────────────────────

set -g SCRIPT_DIR (realpath (dirname (status --current-filename)))
set -g REPO_DIR (realpath "$SCRIPT_DIR/..")
set -g DEST "$HOME/.agents/skills"
set -g MANIFEST_FILE ".mal-agents-installed"

# ── colors ──────────────────────────────────────────────────────────────────
set -g c_reset   (set_color normal)
set -g c_dim     (set_color -d)
set -g c_bold    (set_color -o)
set -g c_green   (set_color green)
set -g c_red     (set_color red)
set -g c_yellow  (set_color yellow)
set -g c_cyan    (set_color cyan)
set -g c_magenta (set_color magenta)

# ── argument parsing ────────────────────────────────────────────────────────
function __mal_usage
    printf '%s\n' \
        "usage: ./install.fish [options]" \
        "" \
        "  (no options)          interactive menu" \
        "  -a, --all             install every skill" \
        "  -s, --skill <name>    install one or more skill(s) (repeatable)" \
        "  -r, --refresh         re-sync installed skills (after git pull)" \
        "  -u, --unlink          remove installed skills (--skill to scope)" \
        "  -c, --check           print status table, change nothing" \
        "  -d, --dest <dir>      install into a custom directory" \
        "  -q, --quiet           suppress the banner" \
        "  -h, --help            show this help"
end

argparse 'a/all' 's/skill=+' 'r/refresh' 'u/unlink' 'c/check' 'd/dest=' 'q/quiet' 'h/help' -- $argv
or return 1

if set -q _flag_help
    __mal_usage
    exit 0
end

if set -q _flag_dest
    set -g DEST $_flag_dest
end

set -g MANIFEST "$DEST/$MANIFEST_FILE"

# ── helpers ─────────────────────────────────────────────────────────────────

function __mal_skills
    for dir in $REPO_DIR/*/
        set -l name (basename "$dir")
        if test -f "$REPO_DIR/$name/SKILL.md"
            echo "$name"
        end
    end
end

function __mal_skill_name_width
    set -l width 16
    for skill in (__mal_skills)
        set -l length (string length -- "$skill")
        if test $length -gt $width
            set width $length
        end
    end
    echo $width
end

function __mal_platform
    set -l skill $argv[1]
    set -l line (grep -m1 '^platforms:' "$REPO_DIR/$skill/SKILL.md" 2>/dev/null)
    if test -z "$line"
        echo "all"
    else
        string replace -r '^\s*platforms:\s*' '' -- "$line" | string trim
    end
end

function __mal_rev
    if test -d "$REPO_DIR/.git"
        git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null
    end
end

function __mal_installed
    set -l skill $argv[1]
    test -L "$DEST/$skill"
end

function __mal_managed_skills
    if test -f "$MANIFEST"
        while read -l line; string match -r -g '^([^[:space:]]+)' -- "$line"; end < "$MANIFEST"
    end
end

function __mal_contains
    set -l needle $argv[1]
    for value in $argv[2..-1]
        if test "$value" = "$needle"
            return 0
        end
    end
    return 1
end

function __mal_manifest_rev
    set -l skill $argv[1]
    if test -f "$MANIFEST"
        set -l line (grep -m1 "^$skill " "$MANIFEST" 2>/dev/null)
        if test -n "$line"
            string replace -r "^$skill\s+" '' -- "$line"
        end
    end
end

function __mal_write_manifest
    set -l skills
    if test (count $argv) -gt 0
        set skills $argv
    else
        set skills (__mal_managed_skills)
    end

    set -l unique_skills
    for skill in $skills
        if not __mal_contains "$skill" $unique_skills
            set -a unique_skills "$skill"
        end
    end

    rm -f "$MANIFEST"
    set -l rev (__mal_rev)
    if test -n "$rev"
        for skill in $unique_skills
            if test -f "$REPO_DIR/$skill/SKILL.md"
                echo "$skill $rev" >> "$MANIFEST"
            end
        end
    end
end

function __mal_status
    set -l skill $argv[1]
    set -l state
    if not __mal_installed "$skill"
        set state "○  available"
    else
        set -l cur   (__mal_rev)
        set -l stored (__mal_manifest_rev "$skill")
        if test -n "$cur" && test -n "$stored" && test "$cur" != "$stored"
            set state "▲  update"
        else
            set state "✓  installed"
        end
    end
    echo "$state"
end

function __mal_install
    set -l skill $argv[1]
    mkdir -p "$DEST"
    ln -sfn "$REPO_DIR/$skill" "$DEST/$skill"
    printf '%s  %s%s%s\n' "$c_green"'+'"$c_reset" "$skill" $c_dim " → $DEST/$skill"$c_reset
end

function __mal_unlink
    set -l skill $argv[1]
    if __mal_installed "$skill"
        rm -f "$DEST/$skill"
        printf '%s  %s%s%s\n' "$c_red"'-'"$c_reset" "$skill" $c_dim " (removed)"$c_reset
    else
        printf '%s  %s%s%s\n' "$c_dim"'.'"$c_reset" "$skill" $c_dim " (not installed)"$c_reset
    end
end

function __mal_render_row
    set -l idx   $argv[1]
    set -l skill $argv[2]
    set -l marker $argv[3]
    set -l checked $argv[4]
    set -l plat  (__mal_platform "$skill")
    set -l state (__mal_status "$skill")

    set -l p
    switch "$plat"
        case 'all'
            set p "$c_cyan"["$plat"]"$c_reset"
        case '*'
            set p "$c_yellow"["$plat"]"$c_reset"
    end

    set -l s
    switch "$state"
        case '*installed'
            set s "$c_green""✓""$c_reset"
        case '*update'
            set s "$c_yellow""▲""$c_reset"
        case '*'
            set s "$c_dim""○""$c_reset"
    end

    if test (count $argv) -ge 3
        printf '  %s [%s] %-3s %-*s %-10s %s\n' \
            "$marker" "$checked" "$idx" $SKILL_WIDTH "$skill" "$p" "$state"
    else
        printf '  %-3s %-*s %-10s %s\n' \
            "$idx" $SKILL_WIDTH "$skill" "$p" "$state"
    end
end

function __mal_banner
    set -l distro (__mal_distro)
    set -l shell  (basename -- "$SHELL" 2>/dev/null; or echo unknown)

    printf '\n'
    printf '%s%s%s\n' "$c_bold""$c_cyan" '  ┌─────────────────────────────────────────────┐' "$c_reset"
    printf '%s%s%s\n' "$c_bold""$c_cyan" '  │      mal-agents · collection installer      │' "$c_reset"
    printf '%s%s%s\n' "$c_bold""$c_cyan" '  │         battle-tested skills, shipped       │' "$c_reset"
    printf '%s%s%s\n' "$c_bold""$c_cyan" '  └─────────────────────────────────────────────┘' "$c_reset"
    printf '\n'
    printf '  %sos:%s %s  %sshell:%s %s  %s→%s %s\n' \
        $c_dim "$c_reset" "$distro" \
        $c_dim "$c_reset" "$shell" \
        $c_dim "$c_reset" "$DEST"
    printf '\n'
end

function __mal_distro
    if test -f /etc/os-release
        set -l pretty (grep -m1 '^PRETTY_NAME=' /etc/os-release 2>/dev/null)
        set -l cleaned (string replace -r '^PRETTY_NAME=["'\'']' '' -- "$pretty" | string replace -r '["'\'']$' '')
        if string match -qi '*garuda*' -- "$cleaned"
            echo "Garuda (Arch) 🐟"
            return 0
        else if string match -qi '*arch*' -- "$cleaned"
            echo "Arch"
            return 0
        else
            echo "$cleaned"
            return 0
        end
    else
        switch (uname -s)
            case Darwin
                echo "macOS"
            case '*'
                uname -s
        end
    end
end

# ── main ────────────────────────────────────────────────────────────────────
set -g SKILL_WIDTH (__mal_skill_name_width)

if not set -q _flag_quiet
    __mal_banner
end

# --check: table only, no changes
if set -q _flag_check
    for skill in (__mal_skills | sort)
        __mal_render_row "" "$skill"
    end
    printf '\n  %sdest:%s %s\n' $c_dim "$c_reset" "$DEST"
    exit 0
end

# --unlink: remove (optionally scoped to --skill)
if set -q _flag_unlink
    if set -q _flag_skill
        set targets $_flag_skill
    else
        set targets (__mal_managed_skills)
    end
    if not set -q targets[1]
        echo "  nothing installed — nothing to do."
        exit 0
    end
    for skill in $targets
        __mal_unlink "$skill"
    end
    set remaining
    for skill in (__mal_managed_skills)
        if not __mal_contains "$skill" $targets
            set -a remaining "$skill"
        end
    end
    __mal_write_manifest $remaining
    exit 0
end

# --refresh: re-sync currently installed skills
if set -q _flag_refresh
    set targets (__mal_managed_skills)
    if not set -q targets[1]
        echo "  nothing installed — run without flags to pick some."
        exit 0
    end
    for skill in $targets
        __mal_install "$skill"
    end
    __mal_write_manifest $targets
    printf '\n  %s✓%s re-synced %d skill(s)\n' "$c_green" "$c_reset" (count $targets)
    exit 0
end

# --all: install everything
if set -q _flag_all
    for skill in (__mal_skills | sort)
        __mal_install "$skill"
    end
    __mal_write_manifest (__mal_skills | sort)
    printf '\n  %s✓%s installed all skills\n' "$c_green" "$c_reset"
    exit 0
end

# --skill: install specific
if set -q _flag_skill
    set targets $_flag_skill
    for skill in $targets
        if test -f "$REPO_DIR/$skill/SKILL.md"
            __mal_install "$skill"
        else
            printf '%s  %s%s%s\n' "$c_red""!""$c_reset" "$skill" $c_dim " (no such skill)"$c_reset
        end
    end
    __mal_write_manifest (__mal_managed_skills) $targets
    exit 0
end

# ── interactive menu ────────────────────────────────────────────────────────

set skills (__mal_skills | sort)

if not set -q skills[1]
    echo "  no skills found in $REPO_DIR"
    exit 1
end

set -l picks
if isatty stdin; and isatty stdout
    set -l selected
    for skill in $skills
        if __mal_installed "$skill"
            set -a selected 1
        else
            set -a selected 0
        end
    end

    set -l cursor 1
    set -l cancelled 0
    set -g __mal_stty_state (stty -g </dev/tty)
    function __mal_menu_cleanup --on-signal INT
        stty "$__mal_stty_state" </dev/tty
        printf '\e[?25h\n'
        exit 130
    end

    stty -icanon -echo min 1 time 0 </dev/tty
    printf '\e[?25l'
    while true
        printf '\e[2J\e[H'
        __mal_banner
        printf '  %sAvailable skills%s\n\n' "$c_bold" "$c_reset"
        set -l idx 0
        for skill in $skills
            set idx (math $idx + 1)
            set -l marker ' '
            if test $idx -eq $cursor
                set marker '❯'
            end
            set -l checked ' '
            if test $selected[$idx] -eq 1
                set checked x
            end
            __mal_render_row $idx "$skill" "$marker" "$checked"
        end
        printf '  %s↑/↓ move · Space select · a all · Enter confirm · q cancel%s\n' \
            $c_dim $c_reset

        set -l key (dd if=/dev/tty bs=1 count=1 2>/dev/null)
        set -l esc (printf '\e')
        if test "$key" = "$esc"
            set -l sequence (dd if=/dev/tty bs=1 count=2 2>/dev/null)
            switch "$sequence"
                case '[A'
                    set cursor (math $cursor - 1)
                case '[B'
                    set cursor (math $cursor + 1)
                case '*'
                    set cancelled 1
                    break
            end
        else
            switch "$key"
                case ''
                    break
                case ' '
                    if test $selected[$cursor] -eq 1
                        set selected[$cursor] 0
                    else
                        set selected[$cursor] 1
                    end
                case j
                    set cursor (math $cursor + 1)
                case k
                    set cursor (math $cursor - 1)
                case a
                    set -l all_selected 1
                    for value in $selected
                        if test $value -ne 1
                            set all_selected 0
                        end
                    end
                    for idx in (seq (count $selected))
                        if test $all_selected -eq 1
                            set selected[$idx] 0
                        else
                            set selected[$idx] 1
                        end
                    end
                case q
                    set cancelled 1
                    break
            end
        end

        if test $cursor -lt 1
            set cursor (count $skills)
        else if test $cursor -gt (count $skills)
            set cursor 1
        end
    end

    stty "$__mal_stty_state" </dev/tty
    printf '\e[?25h'
    functions --erase __mal_menu_cleanup
    set -e __mal_stty_state
    if test $cancelled -eq 1
        echo "  bye 👋"
        exit 0
    end
    for idx in (seq (count $skills))
        if test $selected[$idx] -eq 1
            set -a picks $skills[$idx]
        end
    end
else
    printf '  %sAvailable skills%s\n\n' "$c_bold" "$c_reset"
    set -l idx 0
    for skill in $skills
        set idx (math $idx + 1)
        __mal_render_row $idx "$skill"
    end

    printf '\n  %sEnter numbers %s%s for all, or %s%s to quit: %s' \
        $c_dim \
        "$c_cyan""a""$c_reset" \
        "$c_yellow""q""$c_reset" \
        $c_reset
    read -l answer

    for tok in (string split -- ' ' -- $answer | string split -- ',')
        switch "$tok"
            case 'a' 'all'
                set picks $skills
            case 'q'
                echo "  bye 👋"
                exit 0
            case '*'
                if string match -qr '^[0-9]+$' -- "$tok"
                    set -l n (math $tok)
                    if test $n -ge 1 && test $n -le (count $skills)
                        set -a picks $skills[$n]
                    end
                end
        end
    end
end

if set -q picks[1]
    printf '\n'
    for skill in $picks
        __mal_install "$skill"
    end
    __mal_write_manifest (__mal_managed_skills) $picks
    printf '\n  %s✓%s done — %d skill(s) linked into %s\n' \
        "$c_green" "$c_reset" (count $picks) "$DEST"
else
    echo "  nothing selected — no changes."
end
