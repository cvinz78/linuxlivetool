#!/usr/bin/env bash
set -euo pipefail

ROOT=/src
TMP="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() {
    rm -rf -- "$TMP"
}
trap cleanup EXIT

pass() {
    printf 'OK  %s\n' "$1"
    PASS=$((PASS + 1))
}

fail() {
    printf 'FAIL %s\n' "$1" >&2
    FAIL=$((FAIL + 1))
}

expect_ok() {
    local name="$1"
    shift
    local output rc=0
    output="$("$@" 2>&1)" || rc=$?
    if (( rc == 0 )); then
        pass "$name"
    else
        printf '%s\n' "$output" >&2
        fail "$name (exit $rc)"
    fi
}

expect_nonzero() {
    local name="$1"
    shift
    local rc=0
    "$@" >/dev/null 2>&1 || rc=$?
    if (( rc != 0 )); then
        pass "$name"
    else
        fail "$name (unexpected exit 0)"
    fi
}

expect_file_count() {
    local name="$1" dir="$2" expected="$3" actual
    actual="$(find "$dir" -maxdepth 1 -type f | wc -l)"
    if [[ "$actual" -eq "$expected" ]]; then
        pass "$name ($actual files)"
    else
        fail "$name (expected $expected files, got $actual)"
    fi
}

check_shell_syntax() {
    local name="$1" file="$2"
    if bash -n "$file"; then
        pass "$name"
    else
        fail "$name"
    fi
}

WRAPPER="$TMP/linuxlivetool.sh"
cp -- "$ROOT/linuxlivetool.sh" "$WRAPPER"
chmod 755 "$WRAPPER"

expect_ok "wrapper help" "$WRAPPER" -h
expect_ok "wrapper version" "$WRAPPER" -v
expect_nonzero "wrapper rejects unknown option" "$WRAPPER" --not-a-real-option

TOOLS="$TMP/tools"
expect_ok "extract all embedded tools" "$WRAPPER" -x "$TOOLS"
expect_file_count "embedded tool extraction" "$TOOLS" 5

for tool in ubuntulive-tool debianlive-tool archlive-tool alpinelive-tool clonie; do
    if [[ ! -x "$TOOLS/$tool" ]]; then
        fail "$tool extracted and executable"
        continue
    fi
    check_shell_syntax "$tool syntax" "$TOOLS/$tool"
    expect_ok "$tool help" "$TOOLS/$tool" --help
    expect_ok "$tool version" "$TOOLS/$tool" -V
done

PARTS="$TMP/parts"
expect_ok "export all standalone scripts" "$WRAPPER" -xx all "$PARTS"
expect_file_count "standalone script export" "$PARTS" 13
while IFS= read -r -d '' script; do
    check_shell_syntax "exported syntax: $(basename "$script")" "$script"
    expect_ok "exported help: $(basename "$script")" "$script" --help
done < <(find "$PARTS" -maxdepth 1 -type f -print0)

for distro in ubuntu debian arch alpine clonie; do
    distro_parts="$TMP/xx-$distro"
    expect_ok "export standalone scripts for $distro" "$WRAPPER" -xx "$distro" "$distro_parts"
    if [[ "$distro" == clonie ]]; then
        expect_file_count "$distro standalone export" "$distro_parts" 1
    else
        expect_file_count "$distro standalone export" "$distro_parts" 3
    fi
done

for tool in ubuntulive-tool debianlive-tool archlive-tool alpinelive-tool; do
    test_dir="$TMP/$tool-exports"
    expect_ok "$tool standalone export" "$TOOLS/$tool" -x "$test_dir"
    if [[ -d "$test_dir" ]]; then
        while IFS= read -r -d '' script; do
            check_shell_syntax "$tool exported syntax: $(basename "$script")" "$script"
        done < <(find "$test_dir" -maxdepth 1 -type f -print0)
    else
        fail "$tool standalone export created its directory"
    fi
done

for tool in ubuntulive-tool debianlive-tool; do
    for action in iso install cleanup export; do
        expect_ok "$tool $action help" "$TOOLS/$tool" "$action" --help
    done
done

for action in iso install cleanup; do
    expect_ok "archlive-tool $action help" "$TOOLS/archlive-tool" "$action" --help
done

for tool in ubuntulive-tool debianlive-tool archlive-tool; do
    work="$TMP/$tool-work"
    mkdir -p "$work"
    printf 'disposable fixture\n' > "$work/llt-functional-fixture"
    expect_ok "$tool targets" "$TOOLS/$tool" targets
    expect_ok "$tool cleanup" "$TOOLS/$tool" cleanup -w "$work"
done

for action in iso install part; do
    expect_ok "alpinelive-tool $action help" "$TOOLS/alpinelive-tool" "$action" --help
done

expect_nonzero "Clonie rejects unknown option" "$TOOLS/clonie" --not-a-real-option
expect_nonzero "Ubuntu tool rejects unknown command" "$TOOLS/ubuntulive-tool" --not-a-real-command
expect_nonzero "Debian tool rejects unknown command" "$TOOLS/debianlive-tool" --not-a-real-command
expect_nonzero "Arch tool rejects unknown command" "$TOOLS/archlive-tool" --not-a-real-command
expect_nonzero "Alpine tool rejects unknown command" "$TOOLS/alpinelive-tool" --not-a-real-command

REEMBED="$TMP/reembed"
mkdir -p "$REEMBED"
cp -- "$WRAPPER" "$REEMBED/linuxlivetool.sh"
chmod 755 "$REEMBED/linuxlivetool.sh"
"$REEMBED/linuxlivetool.sh" -x "$REEMBED/tools" >/dev/null
printf '\n# Docker functional test fixture\n' >> "$REEMBED/tools/clonie"
expect_ok "re-embed changed tool" "$REEMBED/linuxlivetool.sh" -r "$REEMBED/tools"
if [[ -f "$REEMBED/linuxlivetool.sh.bak" ]]; then
    pass "re-embed created backup"
else
    fail "re-embed created backup"
fi
"$REEMBED/linuxlivetool.sh" -x "$REEMBED/roundtrip" >/dev/null
if grep -q '^# Docker functional test fixture$' "$REEMBED/roundtrip/clonie"; then
    pass "re-embedded tool survives extraction"
else
    fail "re-embedded tool survives extraction"
fi

printf '\nErgebnis: %d bestanden, %d fehlgeschlagen\n' "$PASS" "$FAIL"
(( FAIL == 0 ))
