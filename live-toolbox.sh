#!/usr/bin/env bash
#===============================================================================
# live-toolbox - Sammel-Skript: die 4 *live-tool Hauptskripte eingebettet
# (ubuntu/debian/arch/alpine; die Install/ISO/Part-Einzelskripte sind bewusst
#  NICHT eingebettet - sie lassen sich bei Bedarf separat entpacken)
#
# Enthaltene Skripte (eingebettet zwischen Markern, je Zeile):
#   #@@@SCRIPT:<dist>/<datei>@@@   ... Inhalt ...   #@@@END:<dist>/<datei>@@@
#   ubuntulive-tool, debianlive-tool, archlive-tool, alpinelive-tool
#
# Aufruf:
#   Ohne Argumente          -> interaktives Menue (Skript auswaehlen und ausfuehren)
#   -xx <distro> <verz>     -> die 3 Einzelskripte der Distribution entpacken
#                              (arch | alpine | ubuntu | debian | all); nutzt die
#                              eingebaute Export-Funktion des jeweiligen Tools;
#                              Verzeichnis wird angelegt, falls nicht vorhanden
#   -x  <verzeichnis>       -> alle eingebetteten Skripte direkt (flach, ohne
#                               Unterordner) in das Verzeichnis entpacken
#                               (Verzeichnis wird angelegt, falls nicht vorhanden)
#   -r  <verzeichnis>       -> veraenderte Skripte aus dem entpackten Verzeichnis
#                              wieder einbetten (ersetzt die eingebetteten
#                              Versionen); VERSION wird um 0.1 erhoeht.
#                              Vorher wird automatisch eine Sicherung
#                              <skriptname>.bak angelegt.
#   -v                      -> Version des Skripts anzeigen (ohne Farben,
#                              maschinenlesbar)
#   -nc                     -> Fallback fuer aeltere Konsolen: keine Farben
#                              (Farben sind ausserdem automatisch aus, wenn die
#                               Ausgabe kein Terminal ist)
#   -h | --help             -> diese Hilfe
#===============================================================================
#
# Copyright (C) 2026 LinuxLiveTool contributors
# Lizenz/License: GPL-3.0-or-later (siehe LICENSE-Datei im Projekt / see the
# LICENSE file in the project root for the full GNU General Public License).
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# SPDX-License-Identifier: GPL-3.0-or-later

TOOLBOX_VERSION="2.5"

MARK_S='#@@@SCRIPT:'
MARK_E='#@@@END:'
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
DIST_ORDER=(alpine arch debian ubuntu)

# ==================== SPRACHE / LANGUAGE ====================
# Standard: DE (Regel AGENTS.md). Fest ueber SPRACHE oder Schalter -de/-en.
# Ist eine Sprache gesetzt, erscheinen NUR Ausgaben dieser Sprache.
t() {
    local key=$1; shift
    case "$key:$SPRACHE" in
    u_title:EN) printf 'live-toolbox v%s - collection script (ubuntu/debian/arch/alpine)' "$1" ;;
    u_title:*)  printf 'live-toolbox v%s - Sammel-Skript (ubuntu/debian/arch/alpine)' "$1" ;;
    u_call:EN)  printf 'Usage: %s [-de|-en] [-x <dir> | -xx [distro] <dir> | -r <dir>] [-nc] [-v] [-h]' "$1" ;;
    u_call:*)   printf 'Aufruf: %s [-de|-en] [-x <verz> | -xx [distro] <verz> | -r <verz>] [-nc] [-v] [-h]' "$1" ;;
    u_noargs:EN) printf '%s\n' "  Without arguments   interactive menu" ;;
    u_noargs:*)  printf '%s\n' "  Ohne Argumente   interaktives Menue" ;;
    u_x:EN)  printf '%s\n' "  -x <dir>         extract all embedded scripts flat (directory is created)" ;;
    u_x:*)   printf '%s\n' "  -x <verzeichnis> alle eingebetteten Skripte flach entpacken (Verzeichnis wird angelegt)" ;;
    u_xx:EN) printf '%s\n' "  -xx <distro> <dir>  extract the 3 standalone scripts (arch|alpine|ubuntu|debian|all)" ;;
    u_xx:*)  printf '%s\n' "  -xx <distro> <verz> 3 Einzelskripte der Distro entpacken (arch|alpine|ubuntu|debian|all)" ;;
    u_r:EN)  printf '%s\n' "  -r <dir>         re-embed changed scripts, VERSION +0.1 (backup: .bak)" ;;
    u_r:*)   printf '%s\n' "  -r <verzeichnis> veraenderte Skripte wieder einbetten, VERSION +0.1 (Backup: .bak)" ;;
    u_v:EN)  printf '%s\n' "  -v               show version" ;;
    u_v:*)   printf '%s\n' "  -v               Version anzeigen" ;;
    u_nc:EN) printf '%s\n' "  -nc              no colors (older terminals)" ;;
    u_nc:*)  printf '%s\n' "  -nc              keine Farben (aeltere Konsolen)" ;;
    u_h:EN)  printf '%s\n' "  -h | --help      show this help" ;;
    u_h:*)   printf '%s\n' "  -h | --help      diese Hilfe" ;;
    e_x_dir:EN) printf '%s\n' "-x requires a target directory" ;;
    e_x_dir:*)  printf '%s\n' "-x benoetigt ein Zielverzeichnis" ;;
    e_r_dir:EN) printf '%s\n' "-r requires a directory" ;;
    e_r_dir:*)  printf '%s\n' "-r benoetigt ein Verzeichnis" ;;
    e_xx_syn:EN) printf '%s\n' "-xx requires [distro] <directory>" ;;
    e_xx_syn:*)  printf '%s\n' "-xx benoetigt [distro] <verzeichnis>" ;;
    e_xx_dir:EN) printf '%s requires a directory\n'  "$1" ;;
    e_xx_dir:*)  printf '%s benoetigt ein Zielverzeichnis\n'  "$1" ;;
    e_distro:EN) printf 'Unknown distribution: %s (allowed: ubuntu, debian, arch, alpine, all)\n'  "$1" ;;
    e_distro:*)  printf 'Unbekannte Distribution: %s (erlaubt: ubuntu, debian, arch, alpine, all)\n'  "$1" ;;
    e_unknown:EN) printf 'Unknown option: %s' "$1" ;;
    e_unknown:*)  printf 'Unbekannte Option: %s' "$1" ;;
    m_title:EN) printf '  live-toolbox v%s - live tools collection script' "$1" ;;
    m_title:*)  printf '  live-toolbox v%s - Live-Tools Sammel-Skript' "$1" ;;
    m_0:EN)  printf '%s\n' "  0)  Quit" ;;
    m_0:*)   printf '%s\n' "  0)  Beenden" ;;
    m_00:EN) printf '%s\n' "  00) Quit" ;;
    m_00:*)  printf '%s\n' "  00) Beenden" ;;
    m_prompt:EN) printf '%s> Choice (1-4, 0): %s' "$CYAN_H" "$RESET" ;;
    m_prompt:*)  printf '%s> Auswahl (1-4, 0): %s' "$CYAN_H" "$RESET" ;;
    e_input:EN) printf '%s\n' "Invalid input." ;;
    e_input:*)  printf '%s\n' "Ungültige Eingabe." ;;
    e_choice:EN) printf '%s\n' "Invalid choice." ;;
    e_choice:*)  printf '%s\n' "Ungültige Auswahl." ;;
    bye:EN)  printf '%s\n' "Goodbye." ;;
    bye:*)   printf '%s\n' "Auf Wiedersehen." ;;
    d_title:EN) printf '=== %s - scripts ===' "$1" ;;
    d_title:*)  printf '=== %s - Skripte ===' "$1" ;;
    d_back:EN)  printf '%s\n' "  0)  Back" ;;
    d_back:*)   printf '%s\n' "  0)  Zurück" ;;
    d_prompt:EN) printf '%s%s> Choice (1-%d, 0, 00): %s' "$CYAN_H" "$1" "$2" "$RESET" ;;
    d_prompt:*)  printf '%s%s> Auswahl (1-%d, 0, 00): %s' "$CYAN_H" "$1" "$2" "$RESET" ;;
    r_start:EN) printf '%sStarting: %s%s' "$MAGENTA_L" "$1" "$RESET" ;;
    r_start:*)  printf '%sStarte: %s%s' "$MAGENTA_L" "$1" "$RESET" ;;
    r_ok:EN)  printf '%sFinished (RC=0): %s%s' "$GREEN_O" "$1" "$RESET" ;;
    r_ok:*)   printf '%sBeendet (RC=0): %s%s' "$GREEN_O" "$1" "$RESET" ;;
    r_err:EN) printf '%sFinished (RC=%s): %s%s' "$RED_H" "$1" "$2" "$RESET" ;;
    r_err:*)  printf '%sBeendet (RC=%s): %s%s' "$RED_H" "$1" "$2" "$RESET" ;;
    pause:EN) printf '%sPress Enter to continue... %s' "$YELLOW_H" "$RESET" ;;
    pause:*)  printf '%sEnter zum Fortfahren... %s' "$YELLOW_H" "$RESET" ;;
    x_title:EN) printf 'live-toolbox v%s - extracting' "$1" ;;
    x_title:*)  printf 'live-toolbox v%s - Entpacken' "$1" ;;
    e_not_dir:EN) printf 'ERROR: %s exists but is not a directory.' "$1" ;;
    e_not_dir:*)  printf 'FEHLER: %s existiert, ist aber kein Verzeichnis.' "$1" ;;
    e_mkdir:EN) printf 'ERROR: directory %s could not be created.' "$1" ;;
    e_mkdir:*)  printf 'FEHLER: Verzeichnis %s konnte nicht angelegt werden.' "$1" ;;
    e_mktemp:EN) printf '%s\n' "ERROR: mktemp failed." ;;
    e_mktemp:*)  printf '%s\n' "FEHLER: mktemp fehlgeschlagen." ;;
    x_one:EN) printf '%s  extracted: %s%s' "$GREEN_O" "$1" "$RESET" ;;
    x_one:*)  printf '%s  entpackt: %s%s' "$GREEN_O" "$1" "$RESET" ;;
    x_done:EN) printf '%s scripts extracted to: %s' "$1" "$2" ;;
    x_done:*)  printf '%s Skripte entpackt nach: %s' "$1" "$2" ;;
    xx_title:EN) printf 'live-toolbox v%s - extracting standalone scripts' "$1" ;;
    xx_title:*)  printf 'live-toolbox v%s - Einzelskripte entpacken' "$1" ;;
    ep_distro:EN) err "ERROR: Unknown distribution '${1}' (allowed: ubuntu, debian, arch, alpine, all)." ;;
    ep_distro:*)  err "FEHLER: Unbekannte Distribution '${1}' (erlaubt: ubuntu, debian, arch, alpine, all)." ;;
    ep_start:EN) printf '%sExporting the 3 standalone scripts (%s) to: %s%s' "$MAGENTA_L" "$1" "$2" "$RESET" ;;
    ep_start:*)  printf '%sExport der 3 Einzelskripte (%s) nach: %s%s' "$MAGENTA_L" "$1" "$2" "$RESET" ;;
    ep_done:EN) printf '%sDone: standalone scripts (%s) in %s%s' "$GREEN_O" "$1" "$2" "$RESET" ;;
    ep_done:*)  printf '%sFertig: Einzelskripte (%s) in %s%s' "$GREEN_O" "$1" "$2" "$RESET" ;;
    ep_fail:EN) printf '%sExport failed (%s, RC=%s).%s' "$RED_H" "$1" "$2" "$RESET" >&2 ;;
    ep_fail:*)  printf '%sExport fehlgeschlagen (%s, RC=%s).%s' "$RED_H" "$1" "$2" "$RESET" >&2 ;;
    re_title:EN) printf 'live-toolbox v%s - re-embedding from: %s' "$1" "$2" ;;
    re_title:*)  printf 'live-toolbox v%s - Wieder-Einbetten aus: %s' "$1" "$2" ;;
    re_nodir:EN) printf 'ERROR: directory %s does not exist.' "$1" >&2 ;;
    re_nodir:*)  printf 'FEHLER: Verzeichnis %s existiert nicht.' "$1" >&2 ;;
    re_nothing:EN) printf '%s\n' "No changed scripts found - nothing to do." ;;
    re_nothing:*)  printf '%s\n' "Keine veraenderten Skripte gefunden - nichts zu tun." ;;
    re_tmpout:EN) printf '%s\n' "ERROR: could not create temporary file." ;;
    re_tmpout:*)  printf '%s\n' "FEHLER: temporaere Datei konnte nicht angelegt werden." ;;
    re_backup:EN) printf 'ERROR: backup %s failed.' "$1" ;;
    re_backup:*)  printf 'FEHLER: Backup %s fehlgeschlagen.' "$1" ;;
    re_done:EN) printf 'Done: %s script(s) re-embedded.' "$1" ;;
    re_done:*)  printf 'Fertig: %s Skript(e) neu eingebettet.' "$1" ;;
    re_replaced:EN) printf '%s  replaced: %s%s' "$GREEN_O" "$1" "$RESET" ;;
    re_replaced:*)  printf '%s  ersetzt: %s%s' "$GREEN_O" "$1" "$RESET" ;;
    esac
}


#-------------------------------------------------------------------------------
# Argumente parsen (vor den Farben, damit -nc wirkt)
#-------------------------------------------------------------------------------
NO_COLOR=0
SPRACHE=DE
XDIR=""
RDIR=""
XXDIST=""
XXDIR=""
SHOW_HELP=0
SHOW_VERSION=0
PARSE_ERR=""

while (( $# )); do
    case "$1" in
        -nc)          NO_COLOR=1 ;;
        -de)          SPRACHE=DE ;;
        -en)          SPRACHE=EN ;;
        -x)           if [[ $# -ge 2 && -n "${2:-}" ]]; then XDIR="$2"; shift;
                      else PARSE_ERR="$(t e_x_dir)"; fi ;;
        -xx)          if [[ $# -ge 2 && -n "${2:-}" ]]; then
                          case "$2" in
                              ubuntu|debian|arch|alpine|all)
                                  if [[ $# -ge 3 && -n "${3:-}" ]]; then XXDIST="$2"; XXDIR="$3"; shift 2;
                                  else PARSE_ERR="$(t e_xx_dir "$2")"; fi ;;
                              *)  if [[ $# -ge 3 ]]; then
                                      PARSE_ERR="$(t e_distro "$2")"
                                  else XXDIST="all"; XXDIR="$2"; shift; fi ;;
                          esac
                      else PARSE_ERR="$(t e_xx_syn)"; fi ;;
        -r)           if [[ $# -ge 2 && -n "${2:-}" ]]; then RDIR="$2"; shift;
                      else PARSE_ERR="$(t e_r_dir)"; fi ;;
        -h|--help)    SHOW_HELP=1 ;;
        -v)           SHOW_VERSION=1 ;;
        -h*)          SHOW_HELP=1 ;;
        --help)       SHOW_HELP=1 ;;
        *)            [[ -n "$PARSE_ERR" ]] || PARSE_ERR="$(t e_unknown "$1")" ;;
    esac
    shift
done

#-------------------------------------------------------------------------------
# Farbschema nach DESIGN.md (-nc oder nicht-Terminal => ohne Farben)
#-------------------------------------------------------------------------------
if [[ -t 1 && "$NO_COLOR" != "1" ]]; then
    CYAN_H=$'\033[1;96m'; YELLOW_H=$'\033[1;93m'; RED_H=$'\033[1;91m'
    MAGENTA_L=$'\033[1;35m'; GREEN_O=$'\033[1;92m'; RESET=$'\033[0m'
else
    CYAN_H=""; YELLOW_H=""; RED_H=""; MAGENTA_L=""; GREEN_O=""; RESET=""
fi

hdr()      { printf '%s%s%s\n' "$CYAN_H"    "$1" "$RESET"; }
txt()      { printf '%s%s%s\n' "$YELLOW_H"  "$1" "$RESET"; }
lbl()      { printf '%s%s%s\n' "$MAGENTA_L" "$1" "$RESET"; }
ok()       { printf '%s%s%s\n' "$GREEN_O"   "$1" "$RESET"; }
err()      { printf '%s%s%s\n' "$RED_H"     "$1" "$RESET" >&2; }


usage() {
    hdr "$(t u_title "$TOOLBOX_VERSION")"
    txt "$(t u_call "${0##*/}")"
    txt "$(t u_noargs)"
    txt "$(t u_x)"
    txt "$(t u_xx)"
    txt "$(t u_r)"
    txt "$(t u_v)"
    txt "$(t u_nc)"
    txt "$(t u_h)"
}

if [[ -n "$PARSE_ERR" ]]; then
    err "FEHLER: $PARSE_ERR"
    usage
    exit 1
fi

if (( SHOW_HELP )); then
    usage
    exit 0
fi

#-------------------------------------------------------------------------------
# Eingebettete Skripte: auflisten / extrahieren
#-------------------------------------------------------------------------------
# Namen aller eingebetteten Skripte im Format <dist>/<datei>
list_names() {
    grep -h "^${MARK_S}" "$SELF" | sed -e "s|^${MARK_S}||" -e 's|@@@$||'
}

names_for_dist() {
    list_names | grep "^$1/"
}

# Inhalt eines eingebetteten Skripts nach $2 schreiben
extract_one() {
    local name="$1" out="$2"
    awk -v s="${MARK_S}${name}@@@" -v e="${MARK_E}${name}@@@" '
        index($0, s) == 1 { f = 1; next }
        index($0, e) == 1 { f = 0; next }
        f
    ' "$SELF" > "$out"
}

# Die 3 Einzelskripte einer Distribution entpacken: nutzt die eingebaute
# Export-Funktion des jeweiligen Tools (dazu wird das Tool temporaer
# entpackt und mit seinem eigenen Export-Befehl aufgerufen)
export_parts() {
    local dist="$1" dir="$2"
    case "$dist" in
        all) local d
             for d in ubuntu debian arch alpine; do export_parts "$d" "$dir" || return $?; done
             return 0 ;;
        ubuntu|debian|arch|alpine) ;;
        *) t ep_distro "$dist"
           exit 1 ;;
    esac
    if [[ -e "$dir" && ! -d "$dir" ]]; then
        err "$(t e_not_dir "$dir")"
        exit 1
    fi
    mkdir -p -- "$dir" || { err "$(t e_mkdir "$dir")"; exit 1; }
    local tool name tmpdir rc=0
    name="$(names_for_dist "$dist" | head -n1)"
    tmpdir="$(mktemp -d)" || { err "$(t e_mktemp)"; exit 1; }
    extract_one "$name" "$tmpdir/$(basename -- "$name")"
    chmod +x "$tmpdir/$(basename -- "$name")"
    tool="$tmpdir/$(basename -- "$name")"
    lbl "$(t ep_start "$dist" "$dir")"
    # Alle 4 Tools nutzen einheitlich: tool -x <verzeichnis>
    bash "$tool" -x "$dir" || rc=$?
    rm -rf -- "$tmpdir"
    if (( rc == 0 )); then
        ok "$(t ep_done "$dist" "$dir")"
    else
        err "$(t ep_fail "$dist" "$rc")"
    fi
    return "$rc"
}

# Alles entpacken nach $1 (flach, ohne Unterordner; Verzeichnis wird angelegt)
extract_all() {
    local dir="$1" n
    if [[ -e "$dir" && ! -d "$dir" ]]; then
        err "$(t e_not_dir "$dir")"
        exit 1
    fi
    mkdir -p -- "$dir" || { err "$(t e_mkdir "$dir")"; exit 1; }
    local count=0
    while IFS= read -r n; do
        extract_one "$n" "$dir/$(basename -- "$n")"
        chmod +x -- "$dir/$(basename -- "$n")"
        ok "$(t x_one "$(basename -- "$n")")"
        count=$((count + 1))
    done < <(list_names)
    hdr "$(t x_done "$count" "$dir")"
}

#-------------------------------------------------------------------------------
# veraenderte Skripte wieder einbetten (-r): VERSION +0.1, Backup vorher
#-------------------------------------------------------------------------------
reembed() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        err "$(t re_nodir "$dir")"
        exit 1
    fi

    local -a lines out
    mapfile -t lines < "$SELF"

    local i line cur f have=0 changed=0
    local -a repl

    for i in "${!lines[@]}"; do
        line="${lines[i]}"
        if (( have )); then
            # Inhalt des Blocks wird ersetzt: Original ueberspringen
            if [[ "$line" == "${MARK_E}${cur}@@@" ]]; then
                out+=("$line")
                have=0
            fi
            continue
        fi
        if [[ "$line" == "${MARK_S}"* ]]; then
            cur="${line#"${MARK_S}"}"
            cur="${cur%@@@}"
            # flaches Verzeichnis: Datei liegt direkt unter $dir (Fallback: <dist>/<name>)
            f="$dir/$(basename -- "$cur")"
            [[ -f "$f" ]] || f="$dir/$cur"
            out+=("$line")
            if [[ -f "$f" ]]; then
                # eingebettete Version extrahieren und vergleichen
                local tmpcmp
                tmpcmp="$(mktemp)" || { err "$(t e_mktemp)"; exit 1; }
                extract_one "$cur" "$tmpcmp"
                if ! cmp -s "$tmpcmp" "$f"; then
                    mapfile -t repl < "$f"
                    out+=("${repl[@]}")
                    have=1
                    changed=$((changed + 1))
                    ok "$(t re_replaced "$cur")"
                fi
                rm -f -- "$tmpcmp"
            fi
        else
            out+=("$line")
        fi
    done

    if (( changed == 0 )); then
        txt "$(t re_nothing)"
        exit 0
    fi

    # Neue Datei schreiben, VERSION um 0.1 erhoehen
    local tmpout nv
    tmpout="$(mktemp "$(dirname -- "$SELF")/.live-toolbox.XXXXXX")" \
        || { err "$(t re_tmpout)"; exit 1; }
    printf '%s\n' "${out[@]}" > "$tmpout"
    # major.minor-String-Arithmetik (awk %.1f wuerde 1.12+0.1=1.2 runden!)
    # Versions-Regel: Minor nur bis 9 — 1.9 -> 2.0 (nicht 1.10)
    nv="$(awk -v v="$TOOLBOX_VERSION" 'BEGIN { split(v, a, "."); if (a[2] + 0 >= 9) printf "%d.0", a[1] + 1; else printf "%d.%d", a[1], a[2] + 1 }')"
    sed -i "s/^TOOLBOX_VERSION=\"[^\"]*\"/TOOLBOX_VERSION=\"${nv}\"/" "$tmpout"

    # Backup anlegen (dateiname.bak) und neue Version einfuehren
    cp -p -- "$SELF" "${SELF}.bak" || { err "$(t re_backup "${SELF}.bak")"; rm -f -- "$tmpout"; exit 1; }
    chmod --reference="${SELF}.bak" "$tmpout"
    mv -f -- "$tmpout" "$SELF"

    hdr "$(t re_done "$changed")"
    hdr "Version: ${TOOLBOX_VERSION} -> ${nv}   Backup: ${SELF}.bak"
    exit 0
}

#-------------------------------------------------------------------------------
# Interaktives Menue (0 = Zurueck, 00 = Beenden)
#-------------------------------------------------------------------------------
pause() {
    local _x
    read -r -p "$(t pause)" _x
}

run_script() {
    local name="$1" tmpdir tmpfile
    tmpdir="$(mktemp -d)" || { err "$(t e_mktemp)"; return 1; }
    tmpfile="${tmpdir}/$(basename -- "$name")"
    extract_one "$name" "$tmpfile"
    chmod +x "$tmpfile"
    lbl "$(t r_start "$name")"
    bash "$tmpfile"
    local rc=$?
    rm -rf -- "$tmpdir"
    if (( rc == 42 )); then
        # 00 im Tool: GESAMTES Skript SOFORT beenden (Quit-All-Signal)
        exit 42
    fi
    if (( rc == 0 )); then
        ok "$(t r_ok "$name")"
    else
        err "$(t r_err "$rc" "$name")"
    fi
    pause
}

dist_menu() {
    local dist="$1"
    local -a scripts
    mapfile -t scripts < <(names_for_dist "$dist")
    local i choice
    while true; do
        echo
        hdr "$(t d_title "$dist")"
        for i in "${!scripts[@]}"; do
            txt "  $((i + 1))) ${scripts[i]#${dist}/}"
        done
        txt "$(t d_back)"
        txt "$(t m_00)"
        local prompt
        prompt="$(t d_prompt "${dist}" "${#scripts[@]}")"
        read -r -p "$prompt" choice || exit 0
        case "$choice" in
            0)   return 0 ;;
            00)  ok "$(t bye)"; exit 0 ;;
            ''|*[!0-9]*) err "$(t e_input)"; continue ;;
            *)   if (( choice >= 1 && choice <= ${#scripts[@]} )); then
                     run_script "${scripts[choice - 1]}"
                 else
                     err "$(t e_choice)"
                 fi ;;
        esac
    done
}

main_menu() {
    local i choice
    while true; do
        echo
        hdr "=============================================="
        hdr "$(t m_title "$TOOLBOX_VERSION")"
        hdr "=============================================="
        for i in "${!DIST_ORDER[@]}"; do
            txt "  $((i + 1))) ${DIST_ORDER[i]^}"
        done
        txt "$(t m_0)"
        txt "$(t m_00)"
        read -r -p "$(t m_prompt)" choice || exit 0
        case "$choice" in
            0|00) ok "$(t bye)"; exit 0 ;;
            ''|*[!0-9]*) err "$(t e_input)"; continue ;;
            *)    if (( choice >= 1 && choice <= ${#DIST_ORDER[@]} )); then
                      local d="${DIST_ORDER[choice - 1]}"
                      local -a one
                      mapfile -t one < <(names_for_dist "$d")
                      if (( ${#one[@]} == 1 )); then
                          # nur 1 Skript in der Distribution: direkt starten
                          run_script "${one[0]}"
                      else
                          dist_menu "$d"
                      fi
                  else
                      err "$(t e_choice)"
                  fi ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Hauptprogramm
#-------------------------------------------------------------------------------
if (( SHOW_VERSION )); then
    # bewusst ohne Farben, damit maschinenlesbar
    echo "live-toolbox v${TOOLBOX_VERSION}"
    # Versionen der eingebetteten Tools mit ausgeben - so sieht man sofort,
    # ob das Bundle aktuell ist (ein Skript mit altem Stand = Bundle erneuern)
    while IFS= read -r n; do
        v="$(extract_one "$n" /dev/stdout | grep -m1 '^VERSION=' || true)"
        echo "  ${n}  $(printf '%s' "${v#VERSION=}" | tr -d '\"')"
    done < <(list_names)
    exit 0
fi

if [[ -n "$XXDIST" ]]; then
    hdr "$(t xx_title "$TOOLBOX_VERSION")"
    export_parts "$XXDIST" "$XXDIR"
    exit $?
fi

if [[ -n "$XDIR" ]]; then
    hdr "$(t x_title "$TOOLBOX_VERSION")"
    extract_all "$XDIR"
    exit 0
fi

if [[ -n "$RDIR" ]]; then
    hdr "$(t re_title "$TOOLBOX_VERSION" "$RDIR")"
    reembed "$RDIR"
fi

main_menu

exit 0

#=== AB HIER EINGEBETTETE SKRIpte (Nur Daten, werden nie ausgefuehrt) =========
#@@@SCRIPT:ubuntu/ubuntulive-tool@@@
#!/usr/bin/env bash
#
# ubuntulive-tool 2.6 - Ubuntu-Live-ISO bauen + gebootetes Live-System installieren
#                       + interaktiver Partitionierer (sfdisk-Basis)
#
# Zweck:
#   Ein einziges Werkzeug für alle Aufgaben rund um die eigene Ubuntu-Live-ISO:
#     - Live-ISO vom LAUFENDEN System erstellen (BIOS + UEFI bootbar, casper)
#     - das gebootete Live-System auf Festplatte oder Partition installieren
#       (inkl. GRUB, BIOS + UEFI automatisch erkannt)
#     - Festplatten interaktiv partitionieren (Zahlen-Auswahl)
#
# Verwendung:
#   ubuntulive-tool                       interaktives Hauptmenü
#   ubuntulive-tool iso [OPTIONEN] [ZIEL] Live-ISO erstellen
#   ubuntulive-tool install -d GERÄT [-y] Live-System installieren
#   ubuntulive-tool part                  Partitionierer (interaktiv)
#   ubuntulive-tool cleanup [-w VERZ]     ISO-Bau-Artefakte entfernen
#   ubuntulive-tool targets               mögliche Installationsziele zeigen
#   ubuntulive-tool export [-s 1,2,3] [-o VERZ]
#                                         Teile als Einzelskripte ausgeben
#   ubuntulive-tool help | -V             Hilfe / Version
#
# Benötigte Tools:
#   bash >= 4.4, GNU coreutils, util-linux (Pakete util-linux/fdisk), udev,
#   je nach Aktion apt-get, squashfs-tools, grub-common + grub-pc-bin +
#   grub-efi-amd64-bin, xorriso, mtools, casper + initramfs-tools (werden
#   bei Bedarf nachinstalliert), dosfstools/e2fsprogs/ntfs-3g fürs Formatieren.
#
# Exit-Codes:
#   0  Erfolg
#   2  Falsche Argumente / unbekannter Befehl (Usage wird ausgegeben)
#   3  Fataler Fehler ("die") oder Abbruch durch den Benutzer
#   130/143/129  SIGINT/SIGTERM/SIGHUP (Aufräumarbeiten laufen vorher)
#
# Farben: Überschriften hell-cyan, Text hell-gelb, Dateien/Pfade hell-lila,
#         alles andere hell-grün (Fehler rot). Abschaltbar mit --no-color
#         oder der Umgebungsvariable NO_COLOR.
#
# Zweisprachig DE/EN: Sprache oben über SPRACHE einstellbar (AUTO = Systemsprache).
# -de/-en-Flags und language.ini (sprache=de|en) setzen die Sprache ebenfalls.
#
set -euo pipefail

VERSION="3.4"
SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || true)"
if [[ -z "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$0"
fi
ORIG_ARGS=("$@")
SCRIPT_NAME="${ULTOOL_SELF_NAME:-$(basename -- "$0")}"

# ==================== SPRACHE / LANGUAGE ====================
# Sprache aller Meldungen: AUTO (Systemsprache, Voreinstellung), DE oder EN.
# Zum Festlegen den Wert unten eintragen, z. B.:  SPRACHE=DE   bzw.   SPRACHE=EN
# Startet man das Skript aus der LinuxLiveTool-GUI, gewinnt die dort gewaehlte
# Sprache (Umgebungsvariable LLT_LANG = DE oder EN) ueber dieser Einstellung.
SPRACHE=DE
case "${LLT_LANG:-}" in
    DE|EN) SPRACHE="$LLT_LANG" ;;
esac

# Kompatibilitaet: die Flags -de/-en setzen die Sprache explizit.
SPRACHE_GESETZT="n"
for a in "$@"; do
    case "$a" in
        -de) SPRACHE=DE; SPRACHE_GESETZT="j" ;;
        -en) SPRACHE=EN; SPRACHE_GESETZT="j" ;;
    esac
done

# language.ini (Legacy): die Marker-Zeile in Zeile 1 erkennt die eigene
# Sprachdatei; sie setzt nur noch die Sprache (sprache=de|en).
if [[ "$SPRACHE_GESETZT" == "n" && -z "${LLT_LANG:-}" ]]; then
    ini_kandidat="$(dirname -- "$SCRIPT_PATH")/language.ini"
    if [[ -f "$ini_kandidat" ]] \
        && [[ "$(head -n1 -- "$ini_kandidat" 2>/dev/null)" == "[ubuntulive-tool-sprache]" ]]; then
        ini_code="$(sed -n 's/^[[:space:]]*sprache=[[:space:]]*//p' -- "$ini_kandidat" | head -n1)"
        case "${ini_code,,}" in
            de) SPRACHE=DE ;;
            en) SPRACHE=EN ;;
        esac
    fi
fi
case "$SPRACHE" in
    AUTO) case "${LC_ALL:-${LANG:-}}" in de*|DE*) SPRACHE=DE ;; *) SPRACHE=EN ;; esac ;;
esac

# Textkatalog: alle Meldungen in DE und EN (keine Extradatei).
#   t  KEY [ARGS...]  -> Meldung nach stdout
#   te KEY [ARGS...]  -> Meldung nach stderr
#   td KEY [ARGS...]  -> Meldung nach stderr + Abbruch (exit 1)
# ARGS werden per printf %s in die Meldung eingesetzt (%s-Platzhalter im Text).
t() {
    local key=$1; shift
    case "$key:$SPRACHE" in
    word_error:EN) printf '%s\n' "ERROR" ;;
    word_error:*)  printf '%s\n' "FEHLER" ;;
    word_warning:EN) printf '%s\n' "Warning" ;;
    word_warning:*)  printf '%s\n' "Warnung" ;;
    word_unknown:EN) printf '%s\n' "unknown" ;;
    word_unknown:*)  printf '%s\n' "unbekannt" ;;
    word_label:EN) printf '%s\n' "label" ;;
    word_label:*)  printf '%s\n' "Label" ;;
    word_mounted:EN) printf '%s\n' "mounted" ;;
    word_mounted:*)  printf '%s\n' "eingehängt" ;;
    word_current:EN) printf '%s\n' "currently" ;;
    word_current:*)  printf '%s\n' "aktuell" ;;
    word_mounted_protected:EN) printf '%s\n' "MOUNTED - delete-protected" ;;
    word_mounted_protected:*)  printf '%s\n' "EINGEHÄNGT - löschgeschützt" ;;
    word_raw:EN) printf '%s\n' "raw" ;;
    word_raw:*)  printf '%s\n' "roh" ;;
    word_no_table:EN) printf '%s\n' "no table" ;;
    word_no_table:*)  printf '%s\n' "keine Tabelle" ;;
    word_not_detected:EN) printf '%s\n' "NOT DETECTED" ;;
    word_not_detected:*)  printf '%s\n' "NICHT ERKANNT" ;;
    word_workdir:EN) printf '%s\n' "Work directory" ;;
    word_workdir:*)  printf '%s\n' "Arbeitsverzeichnis" ;;
    word_output_dir:EN) printf '%s\n' "Output directory" ;;
    word_output_dir:*)  printf '%s\n' "Ausgabeordner" ;;
    word_partitioner:EN) printf '%s\n' "Partitioner" ;;
    word_partitioner:*)  printf '%s\n' "Partitionierer" ;;
    menu_choice:EN) printf '%s\n' "Choice " ;;
    menu_choice:*)  printf '%s\n' "Auswahl " ;;
    menu_abort_quit:EN) printf '%s\n' "0=Back, 00=Quit" ;;
    menu_abort_quit:*)  printf '%s\n' "0=Abbrechen, 00=Ende" ;;
    menu_enter_number:EN) printf '%s\n' "Please enter a NUMBER." ;;
    menu_enter_number:*)  printf '%s\n' "Bitte eine ZAHL eingeben." ;;
    menu_invalid_number:EN) printf 'Invalid number (1-%s).\n'  "$1" ;;
    menu_invalid_number:*) printf 'Ungültige Nummer (1-%s).\n'  "$1" ;;
    menu_main_title:EN) printf '%s %s - main menu\n'  "$1" "$2" ;;
    menu_main_title:*) printf '%s %s - Hauptmenü\n'  "$1" "$2" ;;
    menu_main_iso:EN) printf '%s\n' "Create live ISO from the running system" ;;
    menu_main_iso:*)  printf '%s\n' "Live-ISO vom laufenden System erstellen" ;;
    menu_main_install:EN) printf '%s\n' "Install the live system to disk/partition" ;;
    menu_main_install:*)  printf '%s\n' "Live-System auf Festplatte/Partition installieren" ;;
    menu_main_part:EN) printf '%s\n' "Open the partitioner (manage disks/partitions)" ;;
    menu_main_part:*)  printf '%s\n' "Partitionierer öffnen (Platten/Partitionen verwalten)" ;;
    menu_main_cleanup:EN) printf '%s\n' "Cleanup (remove ISO build artifacts)" ;;
    menu_main_cleanup:*)  printf '%s\n' "Aufräumen (ISO-Bau-Artefakte entfernen)" ;;
    menu_main_targets:EN) printf '%s\n' "Show possible installation targets" ;;
    menu_main_targets:*)  printf '%s\n' "Mögliche Installationsziele anzeigen" ;;
    menu_main_export:EN) printf '%s\n' "Export individual scripts (partitioner/ISO/installation)" ;;
    menu_main_export:*)  printf '%s\n' "Einzelskripte exportieren (Partitionierer/ISO/Installation)" ;;
    q_jn:EN) printf '%s\n' "Y/n" ;;
    q_jn:*)  printf '%s\n' "J/n" ;;
    q_jn_lower:EN) printf '%s\n' "Y/n" ;;
    q_jn_lower:*)  printf '%s\n' "j/n" ;;
    q_confirm_continue:EN) printf '%s\n' "Confirm to continue" ;;
    q_confirm_continue:*)  printf '%s\n' "Zum Fortfahren bestätigen" ;;
    q_empty_abort:EN) printf '%s\n' "Aborted (empty input)." ;;
    q_empty_abort:*)  printf '%s\n' "Abgebrochen (leere Eingabe)." ;;
    q_yes_no_please:EN) printf '%s\n' "Please answer y (yes) or n (no)." ;;
    q_yes_no_please:*)  printf '%s\n' "Bitte j (ja) oder n (nein) antworten." ;;
    q_tool_missing_install:EN) printf '%s is missing (package %s). Install now via apt-get?\n'  "$1" "$2" ;;
    q_tool_missing_install:*) printf '%s fehlt (Paket %s). Jetzt per apt-get nachinstallieren?\n'  "$1" "$2" ;;
    q_install_now:EN) printf '%s\n' "Install now via apt-get?" ;;
    q_install_now:*)  printf '%s\n' "Jetzt per apt-get nachinstallieren?" ;;
    q_format_now:EN) printf 'Format with %s now?\n'  "$1" ;;
    q_format_now:*) printf 'Jetzt mit %s formatieren?\n'  "$1" ;;
    q_iso_label:EN) printf '%s\n' "Volume label (max. 32 characters, A-Z 0-9 . _ -)" ;;
    q_iso_label:*)  printf '%s\n' "Volume-Label (max. 32 Zeichen, A-Z 0-9 . _ -)" ;;
    q_iso_target:EN) printf '%s\n' "ISO target (.iso file or directory, empty = <work directory>/ubuntulive.iso)" ;;
    q_iso_target:*)  printf '%s\n' "ISO-Ziel (Datei .iso oder Verzeichnis, leer = <Arbeitsverzeichnis>/ubuntulive.iso)" ;;
    q_iso_excludes:EN) printf '%s\n' "Additional exclusions (space separated, empty = none)" ;;
    q_iso_excludes:*)  printf '%s\n' "Zusätzliche Ausschlüsse (leerzeichengetrennt, leer = keine)" ;;
    q_iso_start_build:EN) printf '%s\n' "Start the ISO build now (several GB, takes a long time)?" ;;
    q_iso_start_build:*)  printf '%s\n' "ISO-Bau jetzt starten (mehrere GB, dauert lange)?" ;;
    q_iso_cleanup:EN) printf 'Really remove build artifacts in %s?\n'  "$1" ;;
    q_iso_cleanup:*) printf 'Build-Artefakte in %s wirklich entfernen?\n'  "$1" ;;
    q_iso_casper_restore:EN) printf '%s\n' "Restore casper files from the current casper package (network required)?" ;;
    q_iso_casper_restore:*)  printf '%s\n' "casper-Dateien aus dem aktuellen casper-Paket wiederherstellen (Netzwerk nötig)?" ;;
    q_exp_overwrite:EN) printf "At least one target file already exists in '%s' - overwrite?\n"  "$1" ;;
    q_exp_overwrite:*) printf "Mindestens eine Zieldatei existiert in '%s' - überschreiben?\n"  "$1" ;;
    info_done:EN) printf '%s\n' "Done." ;;
    info_done:*)  printf '%s\n' "Ende." ;;
    info_aborted:EN) printf '%s\n' "Aborted." ;;
    info_aborted:*)  printf '%s\n' "Abgebrochen." ;;
    info_press_enter:EN) printf '%s\n' "[Press Enter to continue]" ;;
    info_press_enter:*)  printf '%s\n' "[Weiter mit Enter]" ;;
    info_requesting_root:EN) printf '%s\n' "Requesting root privileges (sudo)..." ;;
    info_requesting_root:*)  printf '%s\n' "Fordere Root-Rechte an (sudo)..." ;;
    info_nothing_changed:EN) printf '%s\n' "Aborted - nothing changed." ;;
    info_nothing_changed:*)  printf '%s\n' "Abgebrochen - nichts verändert." ;;
    info_installing_pkg:EN) printf 'Installing package %s (network required)...\n'  "$1" ;;
    info_installing_pkg:*) printf 'Installiere Paket %s (Netzwerk nötig)...\n'  "$1" ;;
    info_retry_apt_update:EN) printf '%s\n' "Retrying with 'apt-get update' (refreshing the package database)..." ;;
    info_retry_apt_update:*)  printf '%s\n' "Neuer Versuch mit 'apt-get update' (Paketdatenbank auffrischen)..." ;;
    info_tool_now_available:EN) printf '%s is now available.\n'  "$1" ;;
    info_tool_now_available:*) printf '%s ist jetzt verfügbar.\n'  "$1" ;;
    info_remove_autologin:EN) printf '%s\n' "Removing autologin configuration - the fresh system starts with the login screen." ;;
    info_remove_autologin:*)  printf '%s\n' "Entferne Autologin-Konfiguration - das frische System startet mit dem Login-Bildschirm." ;;
    info_remove_live_user:EN) printf "Removing live session user '%s' (blank password, sudo grant sudoers.d/casper).\n"  "$1" ;;
    info_remove_live_user:*) printf "Entferne Live-Sitzungs-Benutzer '%s' (leeres Passwort, sudo-Freischaltung sudoers.d/casper).\n"  "$1" ;;
    info_remove_casper_divert_initrd:EN) printf '%s\n' "Removing the casper diversion of update-initramfs (otherwise initramfs builds and kernel updates have no effect)." ;;
    info_remove_casper_divert_initrd:*)  printf '%s\n' "Entferne casper-Divert von update-initramfs (sonst bleiben Initramfs-Bau und Kernel-Updates wirkungslos)." ;;
    info_remove_casper_divert_anacron:EN) printf '%s\n' "Removing the casper diversion of anacron (live system)." ;;
    info_remove_casper_divert_anacron:*)  printf '%s\n' "Entferne casper-Divert von anacron (Live-System)." ;;
    info_kernel_cmdline:EN) printf '%s\n' "Kernel command line:" ;;
    info_kernel_cmdline:*)  printf '%s\n' "Kernel command line:" ;;
    warn_ctx_aborted:EN) printf '%s aborted - %s is still missing.\n'  "$1" "$2" ;;
    warn_ctx_aborted:*) printf '%s abgebrochen - %s fehlt weiterhin.\n'  "$1" "$2" ;;
    warn_fat32_few_clusters:EN) printf 'FAT32: only %s clusters (small volume) - creating it anyway.\n'  "$1" ;;
    warn_fat32_few_clusters:*) printf 'FAT32: nur %s Cluster (kleines Volume) - wird trotzdem angelegt.\n'  "$1" ;;
    warn_part_multi_gaps:EN) printf '%s\n' "Multiple free areas - automatically using the largest." ;;
    warn_part_multi_gaps:*)  printf '%s\n' "Mehrere freie Bereiche - verwende automatisch den größten." ;;
    warn_part_dev_not_yet:EN) printf 'Device node %s has not appeared yet (waiting for udev).\n'  "$1" ;;
    warn_part_dev_not_yet:*) printf 'Gerätedatei %s ist noch nicht erschienen (udev braucht momentan).\n'  "$1" ;;
    warn_part_created_anyway:EN) printf '%s\n' "sfdisk reported an error; the partition is nevertheless on the disk. sfdisk reports:" ;;
    warn_part_created_anyway:*)  printf '%s\n' "sfdisk meldete einen Fehler; die Partition liegt aber auf der Platte. sfdisk meldet:" ;;
    warn_part_newtable_wipe:EN) printf 'ATTENTION: ALL partitions and data on %s will be deleted!\n'  "$1" ;;
    warn_part_newtable_wipe:*) printf 'ACHTUNG: ALLE Partitionen und Daten auf %s werden gelöscht!\n'  "$1" ;;
    warn_part_delete_wipe:EN) printf 'Partition %s is being DELETED - all data on it is irretrievably lost!\n'  "$1" ;;
    warn_part_delete_wipe:*) printf 'Partition %s wird GELÖSCHT - alle Daten darauf sind unwiederbringlich verloren!\n'  "$1" ;;
    warn_part_format_wipe:EN) printf '%s is being formatted with %s - ALL data on it will be lost!\n'  "$1" "$2" ;;
    warn_part_format_wipe:*) printf '%s wird mit %s formatiert - ALLE Daten darauf gehen verloren!\n'  "$1" "$2" ;;
    warn_part_live_excluded:EN) printf 'Live medium %s is excluded from the selection.\n'  "$1" ;;
    warn_part_live_excluded:*) printf 'Live-Medium %s ist von der Auswahl ausgeschlossen.\n'  "$1" ;;
    warn_inst_live_unknown:EN) printf '%s\n' "The live medium could not be determined automatically." ;;
    warn_inst_live_unknown:*)  printf '%s\n' "Das Live-Medium konnte nicht automatisch bestimmt werden." ;;
    warn_inst_moddir_missing:EN) printf '%s/%s does not exist.\n'  "$1" "$2" ;;
    warn_inst_moddir_missing:*) printf '%s/%s existiert nicht.\n'  "$1" "$2" ;;
    warn_inst_uefi_std_failed:EN) printf '%s\n' "Standard UEFI installation (EFI/ubuntu + NVRAM entry) failed -
using the portable fallback path EFI/BOOT without an NVRAM entry." ;;
    warn_inst_uefi_std_failed:*)  printf '%s\n' "Standard-UEFI-Installation (EFI/ubuntu + NVRAM-Eintrag) fehlgeschlagen -
verwende den portablen Fallback-Pfad EFI/BOOT ohne NVRAM-Eintrag." ;;
    warn_inst_uefi_portable_failed:EN) printf '%s\n' "Portable EFI/BOOT path could not be created -
the standard path EFI/ubuntu is installed anyway." ;;
    warn_inst_uefi_portable_failed:*)  printf '%s\n' "Portabler EFI/BOOT-Pfad konnte nicht angelegt werden -
der Standardpfad EFI/ubuntu ist trotzdem installiert." ;;
    warn_secure_boot:EN) printf '%s\n' "Disable Secure Boot in the UEFI (GRUB is unsigned, just like the live ISO)." ;;
    warn_secure_boot:*)  printf '%s\n' "Secure Boot im UEFI deaktivieren (GRUB ist nicht signiert, wie schon die Live-ISO)." ;;
    warn_iso_mount_blocked:EN) printf "'%s' is blocked. These processes are holding it:\n"  "$1" ;;
    warn_iso_mount_blocked:*) printf "'%s' blockiert. Diese Prozesse halten es fest:\n"  "$1" ;;
    warn_iso_lazy_umount:EN) printf "'%s' was unmounted lazily.\n"  "$1" ;;
    warn_iso_lazy_umount:*) printf "'%s' wurde verzögert (lazy) ausgehängt.\n"  "$1" ;;
    warn_iso_user_unknown:EN) printf "User '%s' not found - ownership was not changed.\n"  "$1" ;;
    warn_iso_user_unknown:*) printf "Benutzer '%s' nicht gefunden - Eigentümer wurde nicht geändert.\n"  "$1" ;;
    warn_iso_no_unmkinitramfs:EN) printf '%s\n' "unmkinitramfs missing - structural initramfs check skipped (provided by package initramfs-tools)." ;;
    warn_iso_no_unmkinitramfs:*)  printf '%s\n' "unmkinitramfs fehlt - strukturelle Initramfs-Prüfung übersprungen (Paket initramfs-tools bringt es)." ;;
    warn_iso_low_space:EN) printf 'Only about %s GB free in %s - roughly 8 GB recommended.\n'  "$1" "$2" ;;
    warn_iso_low_space:*) printf 'Nur ca. %s GB frei in %s - grob 8 GB empfohlen.\n'  "$1" "$2" ;;
    warn_iso_kernel_no_modules:EN) printf '%s\n' "Running kernel %s has NO modules (only metadata - typically after
a kernel update without reboot). Using kernel %s instead (modules present)." "$1" "$2" ;;
    warn_iso_kernel_no_modules:*)  printf '%s\n' "Laufender Kernel %s hat KEINE Module (nur Metadaten - typisch nach
Kernel-Update ohne Neustart). Verwende stattdessen Kernel %s (Module vorhanden)." "$1" "$2" ;;
    warn_iso_no_live_user:EN) printf '%s\n' "No user of the secured system could be determined - the live system starts with the login screen without autologin." ;;
    warn_iso_no_live_user:*)  printf '%s\n' "Kein Benutzer des gesicherten Systems ermittelbar - das Live-System startet ohne Autologin in den Login-Bildschirm." ;;
    warn_iso_no_sddm_session:EN) printf '%s\n' "No default SDDM session could be determined - the live autologin may fail (login screen). Please start the desired session once on the source system so that /var/lib/sddm/state.conf records it." ;;
    warn_iso_no_sddm_session:*)  printf '%s\n' "Keine Standard-SDDM-Sitzung ermittelbar - der Live-Autologin kann scheitern (Login-Bildschirm). Bitte im Quellsystem einmal die gewünschte Sitzung starten, damit /var/lib/sddm/state.conf sie festhält." ;;
    warn_iso_own_partitions:EN) printf '%s\n' "These directories are separate partitions and will NOT be in the image:" ;;
    warn_iso_own_partitions:*)  printf '%s\n' "Diese Verzeichnisse sind eigene Partitionen und landen NICHT im Abbild:" ;;
    warn_iso_no_network:EN) printf '%s\n' "Neither NetworkManager nor systemd-networkd in the image - live networking then depends on
the network configuration of the source system (often MAC-bound) and may only work on identical hardware." ;;
    warn_iso_no_network:*)  printf '%s\n' "NetworkManager und systemd-networkd fehlen im Abbild - Live-Netzwerk hängt an der
Netzwerkkonfiguration des Quell-Systems (oft MAC-gebunden) und funktioniert evtl. nur auf identischer Hardware." ;;
    warn_iso_manifest:EN) printf '%s\n' "Manifest could not be created." ;;
    warn_iso_manifest:*)  printf '%s\n' "Manifest konnte nicht erstellt werden." ;;
    warn_iso_secure_boot:EN) printf '%s\n' "ISO is not Secure-Boot signed -> disable Secure Boot in the UEFI." ;;
    warn_iso_secure_boot:*)  printf '%s\n' "ISO nicht Secure-Boot-signiert -> Secure Boot im UEFI deaktivieren." ;;
    warn_iso_arch:EN) printf 'Architecture %s - BIOS boot may not be available; ISO may be UEFI-bootable only.\n'  "$1" ;;
    warn_iso_arch:*) printf 'Architektur %s - BIOS-Boot steht evtl. nicht bereit; ISO ggf. nur UEFI-bootbar.\n'  "$1" ;;
    err_fat32_sector_size:EN) printf 'FAT32: sector size %s is not supported.\n'  "$1" ;;
    err_fat32_sector_size:*) printf 'FAT32: Sektorgröße %s wird nicht unterstützt.\n'  "$1" ;;
    err_fat32_size_unknown:EN) printf 'FAT32: could not determine the size of %s.\n'  "$1" ;;
    err_fat32_size_unknown:*) printf 'FAT32: Größe von %s konnte nicht ermittelt werden.\n'  "$1" ;;
    err_fat32_too_large:EN) printf 'FAT32: device too large for FAT32 (%s bytes).\n'  "$1" ;;
    err_fat32_too_large:*) printf 'FAT32: Gerät zu groß für FAT32 (%s Bytes).\n'  "$1" ;;
    err_fat32_cluster_invalid:EN) printf 'FAT32: cluster size invalid for sector size %s.\n'  "$1" ;;
    err_fat32_cluster_invalid:*) printf 'FAT32: Clustergröße für Sektorgröße %s ungültig.\n'  "$1" ;;
    err_fat32_too_small:EN) printf '%s\n' "FAT32: device too small for a FAT32." ;;
    err_fat32_too_small:*)  printf '%s\n' "FAT32: Gerät zu klein für ein FAT32." ;;
    err_fat32_many_clusters:EN) printf 'FAT32: too many clusters (%s).\n'  "$1" ;;
    err_fat32_many_clusters:*) printf 'FAT32: zu viele Cluster (%s).\n'  "$1" ;;
    err_fat32_create_failed:EN) printf 'FAT32 could not be created on %s.\n'  "$1" ;;
    err_fat32_create_failed:*) printf 'FAT32 konnte auf %s nicht angelegt werden.\n'  "$1" ;;
    err_dev_mounted_unplug:EN) printf '%s is mounted - unmount it first.\n'  "$1" ;;
    err_dev_mounted_unplug:*) printf '%s ist eingehängt - bitte zuerst aushängen.\n'  "$1" ;;
    err_mkfs_ext4_missing:EN) printf '%s\n' "mkfs.ext4 missing (package e2fsprogs) - cannot format ext4." ;;
    err_mkfs_ext4_missing:*)  printf '%s\n' "mkfs.ext4 fehlt (Paket e2fsprogs) - ext4 kann nicht formatiert werden." ;;
    err_mkswap_missing:EN) printf '%s\n' "mkswap missing (package util-linux)." ;;
    err_mkswap_missing:*)  printf '%s\n' "mkswap fehlt (Paket util-linux)." ;;
    err_mkfs_ntfs_missing:EN) printf '%s\n' "mkfs.ntfs missing (package ntfs-3g) - cannot format NTFS." ;;
    err_mkfs_ntfs_missing:*)  printf '%s\n' "mkfs.ntfs fehlt (Paket ntfs-3g) - NTFS kann nicht formatiert werden." ;;
    err_format_fat32_failed:EN) printf 'Formatting %s with FAT32 failed.\n'  "$1" ;;
    err_format_fat32_failed:*) printf 'Formatieren von %s mit FAT32 fehlgeschlagen.\n'  "$1" ;;
    info_fs_vfat_builtin:EN) printf 'Filesystem vfat (FAT32) created on %s (built-in formatter).\n'  "$1" ;;
    info_fs_vfat_builtin:*) printf 'Dateisystem vfat (FAT32) auf %s angelegt (eingebauter Formatierer).\n'  "$1" ;;
    info_formatting:EN) printf 'Formatting %s with %s ...\n'  "$1" "$2" ;;
    info_formatting:*) printf 'Formatiere %s mit %s ...\n'  "$1" "$2" ;;
    info_fs_created:EN) printf 'Filesystem %s created on %s.\n'  "$1" "$2" ;;
    info_fs_created:*) printf 'Dateisystem %s auf %s angelegt.\n'  "$1" "$2" ;;
    err_format_failed:EN) printf 'Formatting %s with %s failed.\n'  "$1" "$2" ;;
    err_format_failed:*) printf 'Formatieren von %s mit %s fehlgeschlagen.\n'  "$1" "$2" ;;
    info_fat32_builtin:EN) printf 'FAT32 (built-in): cluster %s bytes, %s clusters, 2 FATs of %s KiB\n'  "$1" "$2" "$3" ;;
    info_fat32_builtin:*) printf 'FAT32 (eingebaut): Cluster %s Bytes, %s Cluster, 2 FATs à %s KiB\n'  "$1" "$2" "$3" ;;
    err_tool_install_failed:EN) printf '%s\n' "%s could not be installed (package %s).
Check the network - inside the live system 'apt-get update' usually helps." "$1" "$2" ;;
    err_tool_install_failed:*)  printf '%s\n' "%s konnte nicht installiert werden (Paket %s).
Netzwerk prüfen - im Live-System hilft meist 'apt-get update'." "$1" "$2" ;;
    err_tool_install_failed_short:EN) printf '%s could not be installed (package %s).\n'  "$1" "$2" ;;
    err_tool_install_failed_short:*) printf '%s konnte nicht installiert werden (Paket %s).\n'  "$1" "$2" ;;
    err_action_failed:EN) printf '%s\n' "Action failed/aborted - back to the menu." ;;
    err_action_failed:*)  printf '%s\n' "Aktion fehlgeschlagen/abgebrochen - zurück zum Menü." ;;
    part_overview_title:EN) printf 'Overview: %s\n'  "$1" ;;
    part_overview_title:*) printf 'Übersicht: %s\n'  "$1" ;;
    err_part_no_table:EN) printf 'No partition table on %s.\n'  "$1" ;;
    err_part_no_table:*) printf 'Keine Partitionstabelle auf %s.\n'  "$1" ;;
    info_part_use_menu2:EN) printf '%s\n' "Use menu item 2 to create a new table (GPT or MBR)." ;;
    info_part_use_menu2:*)  printf '%s\n' "Über Menüpunkt 2 eine neue Tabelle anlegen (GPT oder MBR)." ;;
    part_table_info:EN) printf 'Table: %s   Sector size: %s B\n'  "$1" "$2" ;;
    part_table_info:*) printf 'Tabelle: %s   Sektorgröße: %s B\n'  "$1" "$2" ;;
    part_free_areas:EN) printf '%s\n' "  Free areas:" ;;
    part_free_areas:*)  printf '%s\n' "  Freie Bereiche:" ;;
    part_gap_line:EN) printf '     %s free - %s\n'  "$1" "$2" ;;
    part_gap_line:*) printf '     %s frei – %s\n'  "$1" "$2" ;;
    part_none:EN) printf '%s\n' "     (none)" ;;
    part_none:*)  printf '%s\n' "     (keine)" ;;
    part_gap_between:EN) printf 'between partitions %s and %s\n'  "$1" "$2" ;;
    part_gap_between:*) printf 'zwischen Partition %s und %s\n'  "$1" "$2" ;;
    part_gap_after:EN) printf 'after partition %s\n'  "$1" ;;
    part_gap_after:*) printf 'nach Partition %s\n'  "$1" ;;
    part_gap_before:EN) printf 'before partition %s\n'  "$1" ;;
    part_gap_before:*) printf 'vor Partition %s\n'  "$1" ;;
    part_gap_empty:EN) printf '%s\n' "on an empty disk" ;;
    part_gap_empty:*)  printf '%s\n' "auf leerer Platte" ;;
    part_newtable_title:EN) printf 'New partition table: %s\n'  "$1" ;;
    part_newtable_title:*) printf 'Neue Partitionstabelle: %s\n'  "$1" ;;
    part_choose_table:EN) printf '%s\n' "Choose partition table" ;;
    part_choose_table:*)  printf '%s\n' "Partitionstabelle wählen" ;;
    part_table_gpt:EN) printf '%s\n' "GPT (modern, for UEFI; any number of partitions)" ;;
    part_table_gpt:*)  printf '%s\n' "GPT (modern, für UEFI; beliebig viele Partitionen)" ;;
    part_table_mbr:EN) printf '%s\n' "MBR / msdos (classic, max. 4 primary)" ;;
    part_table_mbr:*)  printf '%s\n' "MBR / msdos (klassisch, max. 4 primäre)" ;;
    part_wiping_disk:EN) printf '%s\n' "Cleaning disk (wipefs)..." ;;
    part_wiping_disk:*)  printf '%s\n' "Säubere Platte (wipefs)..." ;;
    part_creating_gpt:EN) printf '%s\n' "Creating GPT..." ;;
    part_creating_gpt:*)  printf '%s\n' "Lege GPT an..." ;;
    err_gpt_failed:EN) printf '%s\n' "GPT could not be created - sfdisk reports:" ;;
    err_gpt_failed:*)  printf '%s\n' "GPT konnte nicht angelegt werden - sfdisk meldet:" ;;
    part_creating_mbr:EN) printf '%s\n' "Creating MBR (dos)..." ;;
    part_creating_mbr:*)  printf '%s\n' "Lege MBR (dos) an..." ;;
    err_mbr_failed:EN) printf '%s\n' "MBR could not be created - sfdisk reports:" ;;
    err_mbr_failed:*)  printf '%s\n' "MBR konnte nicht angelegt werden - sfdisk meldet:" ;;
    part_table_done:EN) printf '%s\n' "New partition table in place." ;;
    part_table_done:*)  printf '%s\n' "Neue Partitionstabelle steht." ;;
    part_create_title:EN) printf 'Create partition: %s\n'  "$1" ;;
    part_create_title:*) printf 'Partition erstellen: %s\n'  "$1" ;;
    err_part_no_table_first:EN) printf '%s\n' "No partition table - use menu item 2 first (new table)." ;;
    err_part_no_table_first:*)  printf '%s\n' "Keine Partitionstabelle - zuerst Menüpunkt 2 (neue Tabelle)." ;;
    part_purpose_linux:EN) printf '%s\n' "Linux data partition (ext4)" ;;
    part_purpose_linux:*)  printf '%s\n' "Linux-Datenpartition (ext4)" ;;
    part_purpose_esp:EN) printf '%s\n' "EFI system partition (FAT32, ESP, 512 MiB)" ;;
    part_purpose_esp:*)  printf '%s\n' "EFI-Systempartition (FAT32, ESP, 512 MiB)" ;;
    part_purpose_extended:EN) printf '%s\n' "Extended partition (container for logical)" ;;
    part_purpose_extended:*)  printf '%s\n' "Erweiterte Partition (Container für logische)" ;;
    part_purpose_swap:EN) printf '%s\n' "Swap" ;;
    part_purpose_swap:*)  printf '%s\n' "Swap" ;;
    part_purpose_ntfs:EN) printf '%s\n' "NTFS (Windows compatible)" ;;
    part_purpose_ntfs:*)  printf '%s\n' "NTFS (Windows-kompatibel)" ;;
    part_purpose_fat32:EN) printf '%s\n' "FAT32 (data)" ;;
    part_purpose_fat32:*)  printf '%s\n' "FAT32 (Daten)" ;;
    part_purpose_raw:EN) printf '%s\n' "No filesystem (raw)" ;;
    part_purpose_raw:*)  printf '%s\n' "Ohne Dateisystem (roh)" ;;
    part_choose_purpose:EN) printf '%s\n' "Purpose of the new partition" ;;
    part_choose_purpose:*)  printf '%s\n' "Zweck der neuen Partition" ;;
    err_part_no_free:EN) printf 'No free area on %s.\n'  "$1" ;;
    err_part_no_free:*) printf 'Kein freier Bereich auf %s.\n'  "$1" ;;
    part_gap_auto:EN) printf 'Free area (automatic): %s - %s\n'  "$1" "$2" ;;
    part_gap_auto:*) printf 'Freier Bereich (automatisch): %s – %s\n'  "$1" "$2" ;;
    err_part_gap_too_small:EN) printf '%s\n' "Free area too small - a 1 MiB reserve always stays free,
so at least 2 MiB (1 MiB partition + 1 MiB reserve) must be free." ;;
    err_part_gap_too_small:*)  printf '%s\n' "Freier Bereich zu klein - es bleiben immer 1 MiB Reserve frei,
daher müssen mindestens 2 MiB (1 MiB Partition + 1 MiB Reserve) frei sein." ;;
    part_q_size:EN) printf 'Size in MiB/GiB (empty = automatic, max. %s)\n'  "$1" ;;
    part_q_size:*) printf 'Größe in MiB/GiB (leer = automatisch, max. %s)\n'  "$1" ;;
    part_q_size_invalid:EN) printf '%s\n' "Invalid input - e.g. 512, 20G or 1.5T." ;;
    part_q_size_invalid:*)  printf '%s\n' "Ungültige Angabe - z. B. 512, 20G oder 1.5T." ;;
    err_part_size_no_fit:EN) printf '%s\n' "Size does not fit - at least 1 MiB always stays free
(max. %s in this area)." "$1" ;;
    err_part_size_no_fit:*)  printf '%s\n' "Größe passt nicht - es bleiben immer mindestens 1 MiB frei
(max. %s in diesem Bereich)." "$1" ;;
    err_part_mbr_slots_full:EN) printf '%s\n' "MBR: all 4 primary slots used and no extended partition present.
Create an 'extended partition' first, then logical partitions inside it." ;;
    err_part_mbr_slots_full:*)  printf '%s\n' "MBR: alle 4 primären Slots belegt und keine erweiterte Partition vorhanden.
Zuerst eine 'Erweiterte Partition' anlegen, dann logische Partitionen darin erstellen." ;;
    part_creating_line:EN) printf 'Creating partition: %s\n'  "$1" ;;
    part_creating_line:*) printf 'Lege Partition an: %s\n'  "$1" ;;
    err_part_create_failed:EN) printf '%s\n' "sfdisk could not create the partition - sfdisk reports:" ;;
    err_part_create_failed:*)  printf '%s\n' "sfdisk konnte die Partition nicht anlegen - sfdisk meldet:" ;;
    err_part_no_new_nr:EN) printf '%s\n' "Could not determine the new partition number." ;;
    err_part_no_new_nr:*)  printf '%s\n' "Neue Partitionsnummer konnte nicht ermittelt werden." ;;
    part_created:EN) printf 'Created: %s\n'  "$1" ;;
    part_created:*) printf 'Neu angelegt: %s\n'  "$1" ;;
    part_delete_title:EN) printf 'Delete partition: %s\n'  "$1" ;;
    part_delete_title:*) printf 'Partition löschen: %s\n'  "$1" ;;
    part_no_partitions:EN) printf '%s\n' "No partitions present." ;;
    part_no_partitions:*)  printf '%s\n' "Keine Partitionen vorhanden." ;;
    part_choose_delete:EN) printf '%s\n' "Partition to delete" ;;
    part_choose_delete:*)  printf '%s\n' "Zu löschende Partition" ;;
    err_part_mounted_nodelete:EN) printf '%s is mounted and cannot be deleted.\n'  "$1" ;;
    err_part_mounted_nodelete:*) printf '%s ist eingehängt und kann nicht gelöscht werden.\n'  "$1" ;;
    part_deleted:EN) printf '%s\n' "Partition deleted." ;;
    part_deleted:*)  printf '%s\n' "Partition gelöscht." ;;
    err_part_delete_failed:EN) printf '%s\n' "Deleting failed." ;;
    err_part_delete_failed:*)  printf '%s\n' "Löschen fehlgeschlagen." ;;
    part_format_title:EN) printf 'Format partition: %s\n'  "$1" ;;
    part_format_title:*) printf 'Partition formatieren: %s\n'  "$1" ;;
    part_no_formattable:EN) printf '%s\n' "No formattable partitions." ;;
    part_no_formattable:*)  printf '%s\n' "Keine formatierbaren Partitionen." ;;
    part_choose_format:EN) printf '%s\n' "Partition to format" ;;
    part_choose_format:*)  printf '%s\n' "Zu formatierende Partition" ;;
    err_dev_mounted:EN) printf '%s is mounted.\n'  "$1" ;;
    err_dev_mounted:*) printf '%s ist eingehängt.\n'  "$1" ;;
    part_choose_fs:EN) printf '%s\n' "Filesystem" ;;
    part_choose_fs:*)  printf '%s\n' "Dateisystem" ;;
    part_settype_title:EN) printf 'Set partition type: %s\n'  "$1" ;;
    part_settype_title:*) printf 'Partitionstyp setzen: %s\n'  "$1" ;;
    part_choose_partition:EN) printf '%s\n' "Partition" ;;
    part_choose_partition:*)  printf '%s\n' "Partition" ;;
    part_newtype_gpt:EN) printf '%s\n' "New type (GPT)" ;;
    part_newtype_gpt:*)  printf '%s\n' "Neuer Typ (GPT)" ;;
    part_type_esp:EN) printf '%s\n' "EFI system partition (ESP)" ;;
    part_type_esp:*)  printf '%s\n' "EFI-Systempartition (ESP)" ;;
    part_type_biosboot:EN) printf '%s\n' "BIOS boot partition (GRUB in BIOS mode)" ;;
    part_type_biosboot:*)  printf '%s\n' "BIOS-Boot-Partition (GRUB im BIOS-Modus)" ;;
    part_type_linux:EN) printf '%s\n' "Linux filesystem" ;;
    part_type_linux:*)  printf '%s\n' "Linux-Dateisystem" ;;
    part_type_linux_swap:EN) printf '%s\n' "Linux swap" ;;
    part_type_linux_swap:*)  printf '%s\n' "Linux-Swap" ;;
    part_type_msft:EN) printf '%s\n' "Microsoft Basic Data (Windows/NTFS)" ;;
    part_type_msft:*)  printf '%s\n' "Microsoft Basic Data (Windows/NTFS)" ;;
    part_type_lvm:EN) printf '%s\n' "Linux LVM" ;;
    part_type_lvm:*)  printf '%s\n' "Linux-LVM" ;;
    part_newtype_mbr:EN) printf '%s\n' "New type (MBR)" ;;
    part_newtype_mbr:*)  printf '%s\n' "Neuer Typ (MBR)" ;;
    part_type_linux83:EN) printf '%s\n' "Linux (83)" ;;
    part_type_linux83:*)  printf '%s\n' "Linux (83)" ;;
    part_type_efi_ef:EN) printf '%s\n' "EFI system (ef)" ;;
    part_type_efi_ef:*)  printf '%s\n' "EFI-System (ef)" ;;
    part_type_fat32lba:EN) printf '%s\n' "FAT32 LBA (0c)" ;;
    part_type_fat32lba:*)  printf '%s\n' "FAT32 LBA (0c)" ;;
    part_type_swap82:EN) printf '%s\n' "Swap (82)" ;;
    part_type_swap82:*)  printf '%s\n' "Swap (82)" ;;
    part_type_ntfs07:EN) printf '%s\n' "NTFS/HPFS (07)" ;;
    part_type_ntfs07:*)  printf '%s\n' "NTFS/HPFS (07)" ;;
    part_type_ext05:EN) printf '%s\n' "Extended (05)" ;;
    part_type_ext05:*)  printf '%s\n' "Erweitert (05)" ;;
    part_type_set:EN) printf 'Type set: %s on %s\n'  "$1" "$2" ;;
    part_type_set:*) printf 'Typ gesetzt: %s auf %s\n'  "$1" "$2" ;;
    err_part_type_failed:EN) printf '%s\n' "Type could not be set." ;;
    err_part_type_failed:*)  printf '%s\n' "Typ konnte nicht gesetzt werden." ;;
    err_part_bootflag_gpt:EN) printf '%s\n' "Boot flag only exists on MBR tables (GPT: use partition type ESP)." ;;
    err_part_bootflag_gpt:*)  printf '%s\n' "Boot-Flag gibt es nur bei MBR-Tabellen (GPT: Partitionstyp ESP verwenden)." ;;
    part_bootflag_title:EN) printf 'Set boot flag (MBR): %s\n'  "$1" ;;
    part_bootflag_title:*) printf 'Boot-Flag setzen (MBR): %s\n'  "$1" ;;
    part_choose_bootflag:EN) printf '%s\n' "Partition (gets boot flag, all others lose it)" ;;
    part_choose_bootflag:*)  printf '%s\n' "Partition (erhält Boot-Flag, alle anderen verlieren es)" ;;
    part_bootflag_set:EN) printf 'Boot flag set on %s\n'  "$1" ;;
    part_bootflag_set:*) printf 'Boot-Flag gesetzt auf %s\n'  "$1" ;;
    err_part_bootflag_failed:EN) printf '%s\n' "Boot flag could not be set." ;;
    err_part_bootflag_failed:*)  printf '%s\n' "Boot-Flag konnte nicht gesetzt werden." ;;
    err_part_missing_tools:EN) printf 'The partitioner is missing tools: %s\n'  "$1" ;;
    err_part_missing_tools:*) printf 'Für den Partitionierer fehlen Werkzeuge: %s\n'  "$1" ;;
    err_part_needs:EN) printf 'The partitioner needs: %s\n'  "$1" ;;
    err_part_needs:*) printf 'Der Partitionierer braucht: %s\n'  "$1" ;;
    part_menu_disk_title:EN) printf '%s\n' "Partitioner - disk selection" ;;
    part_menu_disk_title:*)  printf '%s\n' "Partitionierer - Plattenauswahl" ;;
    err_part_no_disk:EN) printf '%s\n' "No suitable disk found." ;;
    err_part_no_disk:*)  printf '%s\n' "Keine passende Festplatte gefunden." ;;
    part_choose_disk:EN) printf '%s\n' "Choose disk" ;;
    part_choose_disk:*)  printf '%s\n' "Festplatte wählen" ;;
    part_menu_title:EN) printf 'Partitioning: %s\n'  "$1" ;;
    part_menu_title:*) printf 'Partitionieren: %s\n'  "$1" ;;
    part_menu_overview:EN) printf '%s\n' "Show overview (partitions + free areas)" ;;
    part_menu_overview:*)  printf '%s\n' "Übersicht anzeigen (Partitionen + freie Bereiche)" ;;
    part_menu_newtable:EN) printf '%s\n' "Create new partition table (DELETES EVERYTHING on the disk)" ;;
    part_menu_newtable:*)  printf '%s\n' "Neue Partitionstabelle anlegen (LÖSCHT ALLES auf der Platte)" ;;
    part_menu_create:EN) printf '%s\n' "Create partition" ;;
    part_menu_create:*)  printf '%s\n' "Partition erstellen" ;;
    part_menu_delete:EN) printf '%s\n' "Delete partition" ;;
    part_menu_delete:*)  printf '%s\n' "Partition löschen" ;;
    part_menu_format:EN) printf '%s\n' "Format partition (ext4/FAT32/swap/NTFS)" ;;
    part_menu_format:*)  printf '%s\n' "Partition formatieren (ext4/FAT32/swap/NTFS)" ;;
    part_menu_settype:EN) printf '%s\n' "Set partition type (ESP, BIOS boot, swap ...)" ;;
    part_menu_settype:*)  printf '%s\n' "Partitionstyp setzen (ESP, BIOS-Boot, Swap ...)" ;;
    part_menu_bootflag:EN) printf '%s\n' "Set boot flag (MBR only)" ;;
    part_menu_bootflag:*)  printf '%s\n' "Boot-Flag setzen (nur MBR)" ;;
    inst_whole_disk:EN) printf '%s\n' "- WHOLE DISK - " ;;
    inst_whole_disk:*)  printf '%s\n' "- GANZE PLATTE - " ;;
    inst_will_repart:EN) printf '%s\n' "[will be repartitioned]" ;;
    inst_will_repart:*)  printf '%s\n' "[wird neu partitioniert]" ;;
    inst_extended_skipped:EN) printf '%s\n' "- extended partition (skipped)" ;;
    inst_extended_skipped:*)  printf '%s\n' "- erweiterte Partition (übersprungen)" ;;
    inst_partition:EN) printf '%s\n' "- partition - " ;;
    inst_partition:*)  printf '%s\n' "- Partition - " ;;
    inst_targets_title:EN) printf '%s\n' "Possible installation targets" ;;
    inst_targets_title:*)  printf '%s\n' "Mögliche Installationsziele" ;;
    inst_live_excluded:EN) printf 'The live medium %s and its partitions are excluded.\n'  "$1" ;;
    inst_live_excluded:*) printf 'Das Live-Medium %s und seine Partitionen sind ausgeschlossen.\n'  "$1" ;;
    err_inst_no_targets:EN) printf '%s\n' "No suitable targets found." ;;
    err_inst_no_targets:*)  printf '%s\n' "Keine geeigneten Ziele gefunden." ;;
    inst_choose_target:EN) printf '%s\n' "Choose installation target" ;;
    inst_choose_target:*)  printf '%s\n' "Installationsziel wählen" ;;
    inst_title:EN) printf '%s\n' "UbuntuLive installer - installs the booted live system" ;;
    inst_title:*)  printf '%s\n' "UbuntuLive-Installer - installiert das gebootete Live-System" ;;
    err_inst_not_block:EN) printf 'Not a block device: %s\n'  "$1" ;;
    err_inst_not_block:*) printf 'Kein Blockgerät: %s\n'  "$1" ;;
    err_inst_no_parent:EN) printf "Could not determine the parent disk of '%s'.\n"  "$1" ;;
    err_inst_no_parent:*) printf "Übergeordnete Festplatte von '%s' konnte nicht ermittelt werden.\n"  "$1" ;;
    err_inst_extended:EN) printf "An extended partition ('%s') cannot be an installation target.\n"  "$1" ;;
    err_inst_extended:*) printf "Eine erweiterte Partition ('%s') kann kein Installationsziel sein.\n"  "$1" ;;
    err_inst_neither:EN) printf "'%s' is neither a whole disk nor a partition.\n"  "$1" ;;
    err_inst_neither:*) printf "'%s' ist weder eine komplette Festplatte noch eine Partition.\n"  "$1" ;;
    err_inst_unsuitable:EN) printf "'%s' is not a suitable installation target.\n"  "$1" ;;
    err_inst_unsuitable:*) printf "'%s' ist kein geeignetes Installationsziel.\n"  "$1" ;;
    inst_session_mode:EN) printf 'Session mode: %s - the installation will be for %s.\n'  "$1" "$2" ;;
    inst_session_mode:*) printf 'Sitzungs-Modus: %s - die Installation erfolgt für %s.\n'  "$1" "$2" ;;
    inst_boot_bios:EN) printf '%s\n' "For a BIOS installation, boot the ISO in BIOS/CSM mode." ;;
    inst_boot_bios:*)  printf '%s\n' "Für eine BIOS-Installation das ISO im BIOS-/CSM-Modus starten." ;;
    inst_boot_uefi:EN) printf '%s\n' "For a UEFI installation, boot the ISO in UEFI mode." ;;
    inst_boot_uefi:*)  printf '%s\n' "Für eine UEFI-Installation das ISO im UEFI-Modus starten." ;;
    err_inst_arch:EN) printf 'Only x86_64 is supported (found: %s).\n'  "$1" ;;
    err_inst_arch:*) printf 'Nur x86_64 wird unterstützt (gefunden: %s).\n'  "$1" ;;
    err_inst_no_live_system:EN) printf '%s\n' "No Ubuntu live system detected (/cdrom missing) -
is the script running inside the booted live system?" ;;
    err_inst_no_live_system:*)  printf '%s\n' "Kein Ubuntu-Live-System erkannt (/cdrom fehlt) -
läuft das Script im gebooteten Live-System?" ;;
    err_inst_no_squash:EN) printf '%s\n' "No Ubuntu SquashFS found - diagnostics:" ;;
    err_inst_no_squash:*)  printf '%s\n' "Kein Ubuntu-SquashFS gefunden - Diagnose:" ;;
    inst_files_under_cdrom:EN) printf '%s\n' "Files under /cdrom:" ;;
    inst_files_under_cdrom:*)  printf '%s\n' "Dateien unter /cdrom:" ;;
    err_inst_no_squashfs:EN) printf '%s\n' "No Ubuntu live system detected (filesystem.squashfs missing).
Please start this program from inside the booted live ISO." ;;
    err_inst_no_squashfs:*)  printf '%s\n' "Kein Ubuntu-Live-System erkannt (filesystem.squashfs fehlt).
Bitte dieses Programm innerhalb der gebooteten Live-ISO starten." ;;
    inst_squashfs:EN) printf 'SquashFS:    %s\n'  "$1" ;;
    inst_squashfs:*) printf 'SquashFS:    %s\n'  "$1" ;;
    err_inst_on_live_medium:EN) printf "'%s' lies on the live medium the system was just booted from!\n"  "$1" ;;
    err_inst_on_live_medium:*) printf "'%s' liegt auf dem Live-Medium, von dem gerade gebootet wurde!\n"  "$1" ;;
    inst_target:EN) printf 'Target:      %s\n'  "$1" ;;
    inst_target:*) printf 'Ziel:        %s\n'  "$1" ;;
    inst_mode_part:EN) printf 'Mode:        partition (disk: %s, no repartitioning)\n'  "$1" ;;
    inst_mode_part:*) printf 'Modus:       Partition (Platte: %s, keine Neupartitionierung)\n'  "$1" ;;
    inst_mode_disk:EN) printf '%s\n' "Mode:        whole disk (will be repartitioned)" ;;
    inst_mode_disk:*)  printf '%s\n' "Modus:       Gesamte Festplatte (wird neu partitioniert)" ;;
    inst_live_medium:EN) printf 'Live medium: %s\n'  "$1" ;;
    inst_live_medium:*) printf 'Live-Medium: %s\n'  "$1" ;;
    err_inst_still_mounted:EN) printf "File systems are still mounted on '%s'.\n"  "$1" ;;
    err_inst_still_mounted:*) printf "Auf '%s' sind noch Dateisysteme eingehängt.\n"  "$1" ;;
    err_inst_too_small:EN) printf 'Target too small: %s MB. At least 8 GB.\n'  "$1" ;;
    err_inst_too_small:*) printf 'Ziel zu klein: %s MB. Mindestens 8 GB.\n'  "$1" ;;
    inst_size:EN) printf 'Size:        %s MB\n'  "$1" ;;
    inst_size:*) printf 'Größe:       %s MB\n'  "$1" ;;
    inst_model:EN) printf 'Model:       %s\n'  "$1" ;;
    inst_model:*) printf 'Modell:      %s\n'  "$1" ;;
    inst_warn_wipe:EN) printf 'ATTENTION - ALL DATA ON %s WILL BE DELETED!\n'  "$1" ;;
    inst_warn_wipe:*) printf 'ACHTUNG - ALLE DATEN AUF %s WERDEN GELÖSCHT!\n'  "$1" ;;
    inst_missing_tools:EN) printf '%s\n' "Missing tools - installing packages (network required):" ;;
    inst_missing_tools:*)  printf '%s\n' "Fehlende Werkzeuge - installiere Pakete (Netzwerk nötig):" ;;
    err_inst_missing_pkgs:EN) printf '%s\n' "Missing packages: %s
Please install: apt-get install %s" "$1" "$2" ;;
    err_inst_missing_pkgs:*)  printf '%s\n' "Fehlende Pakete: %s
Bitte installieren: apt-get install %s" "$1" "$2" ;;
    err_inst_pkgs_failed:EN) printf '%s\n' "Packages could not be installed (network? did you run 'apt-get update'?)" ;;
    err_inst_pkgs_failed:*)  printf '%s\n' "Pakete konnten nicht installiert werden (Netzwerk? 'apt-get update' ausgeführt?)" ;;
    err_inst_pkg_still_missing:EN) printf "Package for '%s' is still missing.\n"  "$1" ;;
    err_inst_pkg_still_missing:*) printf "Paket für '%s' fehlt weiterhin.\n"  "$1" ;;
    err_inst_mkfsvfat_missing:EN) printf '%s\n' "mkfs.vfat is still missing (package dosfstools)." ;;
    err_inst_mkfsvfat_missing:*)  printf '%s\n' "mkfs.vfat fehlt weiterhin (Paket dosfstools)." ;;
    err_inst_grub_bios_missing:EN) printf '%s\n' "GRUB modules for BIOS (i386-pc) are missing from the live system.
On the source machine run 'sudo apt-get install grub-pc-bin' and rebuild the ISO." ;;
    err_inst_grub_bios_missing:*)  printf '%s\n' "grub-Module für BIOS (i386-pc) fehlen im Live-System.
Auf dem Quellrechner 'sudo apt-get install grub-pc-bin' ausführen und die ISO neu bauen." ;;
    err_inst_grub_uefi_missing:EN) printf '%s\n' "GRUB modules for UEFI (x86_64-efi) are missing from the live system.
On the source machine run 'sudo apt-get install grub-efi-amd64-bin' and rebuild the ISO." ;;
    err_inst_grub_uefi_missing:*)  printf '%s\n' "grub-Module für UEFI (x86_64-efi) fehlen im Live-System.
Auf dem Quellrechner 'sudo apt-get install grub-efi-amd64-bin' ausführen und die ISO neu bauen." ;;
    err_inst_no_kernel:EN) printf '%s\n' "No kernel found (neither in the live system nor on the medium)." ;;
    err_inst_no_kernel:*)  printf '%s\n' "Kein Kernel gefunden (weder im Live-System noch auf dem Medium)." ;;
    inst_kernel_source:EN) printf 'Kernel source: %s\n'  "$1" ;;
    inst_kernel_source:*) printf 'Kernel-Quelle: %s\n'  "$1" ;;
    inst_part_mode_note1:EN) printf '%s\n' "Target is a single partition - the partition table" ;;
    inst_part_mode_note1:*)  printf '%s\n' "Ziel ist eine einzelne Partition - die Partitionstabelle" ;;
    inst_part_mode_note2:EN) printf 'of %s will NOT be changed.\n'  "$1" ;;
    inst_part_mode_note2:*) printf 'von %s wird NICHT verändert.\n'  "$1" ;;
    inst_partitioning:EN) printf 'Partitioning %s (%s) - all data will be deleted...\n'  "$1" "$2" ;;
    inst_partitioning:*) printf 'Partitioniere %s (%s) - alle Daten werden gelöscht...\n'  "$1" "$2" ;;
    inst_creating_gpt:EN) printf '%s\n' "Creating GPT with 512 MiB EFI + root (sfdisk)..." ;;
    inst_creating_gpt:*)  printf '%s\n' "Erstelle GPT mit 512-MiB-EFI + Root (sfdisk)..." ;;
    err_inst_part_gpt:EN) printf '%s\n' "Partitioning (GPT) failed." ;;
    err_inst_part_gpt:*)  printf '%s\n' "Partitionierung (GPT) fehlgeschlagen." ;;
    inst_creating_mbr:EN) printf '%s\n' "Creating MBR with a bootable root partition (sfdisk)..." ;;
    inst_creating_mbr:*)  printf '%s\n' "Erstelle MBR mit einer bootbaren Root-Partition (sfdisk)..." ;;
    err_inst_part_mbr:EN) printf '%s\n' "Partitioning (MBR) failed." ;;
    err_inst_part_mbr:*)  printf '%s\n' "Partitionierung (MBR) fehlgeschlagen." ;;
    err_inst_p1_missing:EN) printf 'Partition %s was not found.\n'  "$1" ;;
    err_inst_p1_missing:*) printf 'Partition %s wurde nicht gefunden.\n'  "$1" ;;
    err_inst_p2_missing:EN) printf 'Partition %s was not found.\n'  "$1" ;;
    err_inst_p2_missing:*) printf 'Partition %s wurde nicht gefunden.\n'  "$1" ;;
    inst_partitions:EN) printf '%s\n' "Partitions:" ;;
    inst_partitions:*)  printf '%s\n' "Partitionen:" ;;
    inst_formatting:EN) printf '%s\n' "Formatting..." ;;
    inst_formatting:*)  printf '%s\n' "Formatiere..." ;;
    inst_formatting_part:EN) printf 'Formatting %s (ext4) - all data on this partition will be deleted...\n'  "$1" ;;
    inst_formatting_part:*) printf 'Formatiere %s (ext4) - alle Daten auf dieser Partition werden gelöscht...\n'  "$1" ;;
    inst_swap_off:EN) printf '%s\n' "Partition is active as swap - switching it off..." ;;
    inst_swap_off:*)  printf '%s\n' "Partition ist als Swap aktiv - schalte sie aus..." ;;
    err_inst_swap_off_failed:EN) printf '%s is active as swap and could not be switched off.\n'  "$1" ;;
    err_inst_swap_off_failed:*) printf '%s ist als Swap aktiv und konnte nicht ausgeschaltet werden.\n'  "$1" ;;
    err_inst_format_target:EN) printf '%s\n' "Target partition could not be formatted." ;;
    err_inst_format_target:*)  printf '%s\n' "Ziel-Partition konnte nicht formatiert werden." ;;
    inst_search_esp:EN) printf 'Looking for EFI system partition on %s...\n'  "$1" ;;
    inst_search_esp:*) printf 'Suche EFI-Systempartition auf %s...\n'  "$1" ;;
    inst_partlist:EN) printf 'Partition list of %s (type/FSTYPE):\n'  "$1" ;;
    inst_partlist:*) printf 'Partitionsliste von %s (Typ/FSTYPE):\n'  "$1" ;;
    err_inst_no_esp:EN) printf '%s\n' "UEFI mode: no EFI system partition (ESP) was found on
%s (see the partition list above).

Please create an ESP with the partitioner ('%s part') -
use the preset 'EFI system partition (FAT32, ESP, 512 MiB)'.
The 2 MiB 'BIOS boot' partition is for BIOS mode only, not for UEFI.
If the disk is MBR: use GPT + ESP in UEFI mode, or boot the ISO
in BIOS/CSM mode for an MBR/BIOS installation." "$1" "$2" ;;
    err_inst_no_esp:*)  printf '%s\n' "UEFI-Modus: Es wurde keine EFI-Systempartition (ESP) auf
%s gefunden (siehe Partitionsliste oben).

Bitte über den Partitionierer ('%s part') eine ESP anlegen -
Preset 'EFI-Systempartition (FAT32, ESP, 512 MiB)' verwenden.
Die 2-MiB-'BIOS-Boot'-Partition ist nur für den BIOS-Modus, nicht für UEFI.
Ist die Platte MBR: im UEFI-Modus GPT + ESP verwenden, oder das ISO
für eine MBR/BIOS-Installation im BIOS-/CSM-Modus starten." "$1" "$2" ;;
    inst_esp_unformatted:EN) printf 'ESP %s is unformatted - creating FAT32...\n'  "$1" ;;
    inst_esp_unformatted:*) printf 'ESP %s ist unformatiert - lege FAT32 an...\n'  "$1" ;;
    err_inst_esp_format:EN) printf '%s\n' "ESP could not be formatted." ;;
    err_inst_esp_format:*)  printf '%s\n' "ESP konnte nicht formatiert werden." ;;
    err_inst_esp_wrong_fs:EN) printf "%s is marked as ESP but contains '%s' instead of vfat.\n"  "$1" "$2" ;;
    err_inst_esp_wrong_fs:*) printf "%s ist als ESP markiert, enthält aber '%s' statt vfat.\n"  "$1" "$2" ;;
    err_inst_bios_gpt_no_biosboot:EN) printf '%s\n' "BIOS mode with GPT partition table: %s is missing
a BIOS boot partition (1-2 MiB, type 'BIOS boot').

In the partitioner: create a 2 MiB partition 'No filesystem (raw)' and in
the 'Set type' menu choose 'BIOS boot partition (GRUB in BIOS mode)' -
or use an MBR table." "$1" ;;
    err_inst_bios_gpt_no_biosboot:*)  printf '%s\n' "BIOS-Modus mit GPT-Partitionstabelle: Auf %s fehlt
eine BIOS-Boot-Partition (1-2 MiB, Typ 'BIOS boot').

Im Partitionierer: 2-MiB-Partition 'Ohne Dateisystem (roh)' anlegen und im
'Typ setzen'-Menü 'BIOS-Boot-Partition (GRUB im BIOS-Modus)' wählen -
oder eine MBR-Tabelle verwenden." "$1" ;;
    err_inst_esp_format2:EN) printf '%s\n' "EFI system partition could not be formatted." ;;
    err_inst_esp_format2:*)  printf '%s\n' "EFI-Systempartition konnte nicht formatiert werden." ;;
    err_inst_root_format:EN) printf '%s\n' "Root partition could not be formatted." ;;
    err_inst_root_format:*)  printf '%s\n' "Root-Partition konnte nicht formatiert werden." ;;
    err_inst_root_uuid:EN) printf '%s\n' "UUID of the root partition could not be determined." ;;
    err_inst_root_uuid:*)  printf '%s\n' "UUID der Root-Partition konnte nicht ermittelt werden." ;;
    err_inst_esp_uuid:EN) printf '%s\n' "UUID of the EFI partition could not be determined." ;;
    err_inst_esp_uuid:*)  printf '%s\n' "UUID der EFI-Partition konnte nicht ermittelt werden." ;;
    inst_mounting:EN) printf '%s\n' "Mounting the target system..." ;;
    inst_mounting:*)  printf '%s\n' "Mounte Zielsystem..." ;;
    err_inst_mnt_mounted:EN) printf '%s\n' "/mnt is already mounted - please reboot the live system." ;;
    err_inst_mnt_mounted:*)  printf '%s\n' "/mnt ist bereits eingehängt - bitte Live-System neu starten." ;;
    inst_clean_mnt:EN) printf '%s\n' "Cleaning leftovers in /mnt..." ;;
    inst_clean_mnt:*)  printf '%s\n' "Räume Reste in /mnt weg..." ;;
    err_inst_root_mount:EN) printf '%s\n' "Root partition could not be mounted." ;;
    err_inst_root_mount:*)  printf '%s\n' "Root-Partition konnte nicht gemountet werden." ;;
    inst_extracting:EN) printf 'Extracting the live system to %s (source: %s MB compressed)...\n'  "$1" "$2" ;;
    inst_extracting:*) printf 'Entpacke das Live-System nach %s (Quelle: %s MB komprimiert)...\n'  "$1" "$2" ;;
    inst_extracting_long:EN) printf 'Extracting the live system to %s - depending on the ISO this takes minutes...\n'  "$1" ;;
    inst_extracting_long:*) printf 'Entpacke das Live-System nach %s - je nach ISO mehrere Minuten...\n'  "$1" ;;
    err_inst_unsquash:EN) printf '%s\n' "unsquashfs failed." ;;
    err_inst_unsquash:*)  printf '%s\n' "unsquashfs fehlgeschlagen." ;;
    err_inst_esp_mount:EN) printf '%s\n' "EFI partition could not be mounted." ;;
    err_inst_esp_mount:*)  printf '%s\n' "EFI-Partition konnte nicht gemountet werden." ;;
    inst_free_after:EN) printf 'Free space after extraction: %s MB\n'  "$1" ;;
    inst_free_after:*) printf 'Freier Speicher nach dem Entpacken: %s MB\n'  "$1" ;;
    err_inst_low_space:EN) printf '%s\n' "Too little free space on the target partition." ;;
    err_inst_low_space:*)  printf '%s\n' "Zu wenig freier Speicher auf der Zielpartition." ;;
    inst_remove_bootloader:EN) printf '%s\n' "Removing inherited bootloader leftovers..." ;;
    inst_remove_bootloader:*)  printf '%s\n' "Entferne übernommene Bootloader-Reste..." ;;
    inst_checking_kernel:EN) printf '%s\n' "Checking kernel..." ;;
    inst_checking_kernel:*)  printf '%s\n' "Prüfe Kernel..." ;;
    err_inst_kernel_copy:EN) printf '%s\n' "Kernel could not be copied." ;;
    err_inst_kernel_copy:*)  printf '%s\n' "Kernel konnte nicht kopiert werden." ;;
    inst_kernel_copied:EN) printf 'Kernel copied: %s\n'  "$1" ;;
    inst_kernel_copied:*) printf 'Kernel kopiert: %s\n'  "$1" ;;
    inst_kernel:EN) printf 'Kernel: %s\n'  "$1" ;;
    inst_kernel:*) printf 'Kernel: %s\n'  "$1" ;;
    err_inst_no_modbase:EN) printf '%s\n' "No kernel modules in the installed system (/lib/modules missing)." ;;
    err_inst_no_modbase:*)  printf '%s\n' "Keine Kernelmodule im installierten System (/lib/modules fehlt)." ;;
    err_inst_no_kver:EN) printf '%s\n' "No kernel version found in the installed system." ;;
    err_inst_no_kver:*)  printf '%s\n' "Keine Kernel-Version im installierten System gefunden." ;;
    err_inst_no_matching_modules:EN) printf '%s\n' "Matching kernel modules were not found." ;;
    err_inst_no_matching_modules:*)  printf '%s\n' "Passende Kernelmodule wurden nicht gefunden." ;;
    inst_creating_fstab:EN) printf '%s\n' "Creating /etc/fstab..." ;;
    inst_creating_fstab:*)  printf '%s\n' "Erzeuge /etc/fstab..." ;;
    inst_creating_machine_id:EN) printf '%s\n' "Creating a new machine-id..." ;;
    inst_creating_machine_id:*)  printf '%s\n' "Erzeuge neue machine-id..." ;;
    err_inst_machine_id:EN) printf '%s\n' "machine-id could not be created." ;;
    err_inst_machine_id:*)  printf '%s\n' "machine-id konnte nicht erzeugt werden." ;;
    err_inst_dm_broken:EN) printf '%s\n' "display-manager.service points to a nonexistent unit (%s) -
the installation is aborted so that no unbootable system can result." "$1" ;;
    err_inst_dm_broken:*)  printf '%s\n' "display-manager.service zeigt auf eine nicht existierende Unit (%s) -
die Installation wird abgebrochen, damit kein unbootbares System entsteht." "$1" ;;
    inst_set_dm:EN) printf 'Setting /etc/X11/default-display-manager to the installed display manager: %s\n'  "$1" ;;
    inst_set_dm:*) printf 'Setze /etc/X11/default-display-manager auf den installierten Display-Manager: %s\n'  "$1" ;;
    inst_building_initramfs:EN) printf '%s\n' "Building initramfs for the installed system..." ;;
    inst_building_initramfs:*)  printf '%s\n' "Baue Initramfs für das installierte System..." ;;
    err_inst_update_initramfs:EN) printf '%s\n' "update-initramfs failed" ;;
    err_inst_update_initramfs:*)  printf '%s\n' "update-initramfs fehlgeschlagen" ;;
    inst_fallback_updategrub:EN) printf '%s\n' "Fallback: GRUB configuration the normal way (update-grub)..." ;;
    inst_fallback_updategrub:*)  printf '%s\n' "Fallback: GRUB-Konfiguration auf dem normalen Weg (update-grub)..." ;;
    inst_updategrub_done:EN) printf '%s\n' "GRUB configuration generated via update-grub (normal way)." ;;
    inst_updategrub_done:*)  printf '%s\n' "GRUB-Konfiguration per update-grub erzeugt (normaler Weg)." ;;
    err_inst_updategrub_failed:EN) printf '%s\n' "update-grub failed - generating a minimal GRUB configuration. Message:" ;;
    err_inst_updategrub_failed:*)  printf '%s\n' "update-grub fehlgeschlagen - es wird eine minimale GRUB-Konfiguration erzeugt. Meldung:" ;;
    inst_installing_grub:EN) printf 'Installing GRUB (%s)...\n'  "$1" ;;
    inst_installing_grub:*) printf 'Installiere GRUB (%s)...\n'  "$1" ;;
    err_inst_grub_bios:EN) printf '%s\n' "grub-install BIOS failed." ;;
    err_inst_grub_bios:*)  printf '%s\n' "grub-install BIOS fehlgeschlagen." ;;
    err_inst_esp_not_mounted:EN) printf '%s\n' "EFI system partition is not mounted - aborting before grub-install." ;;
    err_inst_esp_not_mounted:*)  printf '%s\n' "EFI-Systempartition ist nicht eingehängt - Abbruch vor grub-install." ;;
    err_inst_grub_uefi:EN) printf '%s\n' "grub-install UEFI failed." ;;
    err_inst_grub_uefi:*)  printf '%s\n' "grub-install UEFI fehlgeschlagen." ;;
    inst_creating_grubcfg:EN) printf '%s\n' "Creating GRUB configuration..." ;;
    inst_creating_grubcfg:*)  printf '%s\n' "Erzeuge GRUB-Konfiguration..." ;;
    err_inst_no_bootloader_files:EN) printf '%s\n' "Neither BOOTX64.EFI nor EFI/ubuntu/grubx64.efi was created by grub-install" ;;
    err_inst_no_bootloader_files:*)  printf '%s\n' "Weder BOOTX64.EFI noch EFI/ubuntu/grubx64.efi wurden vom grub-install erstellt" ;;
    err_inst_autologin_survived:EN) printf '%s\n' "An autologin configuration was still found in the target system
(sddm.conf or sddm.conf.d) - the installation is aborted so that
no system with a broken autologin can result." ;;
    err_inst_autologin_survived:*)  printf '%s\n' "Es wurde noch eine Autologin-Konfiguration im Zielsystem gefunden
(sddm.conf oder sddm.conf.d) - die Installation wird abgebrochen, damit
kein System mit defektem Autologin entstehen kann." ;;
    inst_success:EN) printf '%s\n' "INSTALLATION SUCCESSFUL" ;;
    inst_success:*)  printf '%s\n' "INSTALLATION ERFOLGREICH" ;;
    inst_done_target:EN) printf 'Target:     %s\n'  "$1" ;;
    inst_done_target:*) printf 'Ziel:       %s\n'  "$1" ;;
    inst_done_root:EN) printf 'Root:       %s\n'  "$1" ;;
    inst_done_root:*) printf 'Root:       %s\n'  "$1" ;;
    inst_now_do:EN) printf '%s\n' "Now please:" ;;
    inst_now_do:*)  printf '%s\n' "Bitte jetzt:" ;;
    inst_step1:EN) printf '%s\n' "  1. Remove the USB stick / live medium" ;;
    inst_step1:*)  printf '%s\n' "  1. USB-Stick / Live-Medium entfernen" ;;
    inst_step2:EN) printf '%s\n' "  2. Reboot the machine" ;;
    inst_step2:*)  printf '%s\n' "  2. Rechner neu starten" ;;
    inst_step3:EN) printf '%s\n' "  3. Boot from the installed disk" ;;
    inst_step3:*)  printf '%s\n' "  3. Von der installierten Festplatte booten" ;;
    inst_login_screen_info:EN) printf '%s\n' "The installed system starts with the login screen
(autologin is not carried over, just like a normal installation;
it can be re-enabled in the SDDM/login settings)." ;;
    inst_login_screen_info:*)  printf '%s\n' "Das installierte System startet mit dem Login-Bildschirm
(Autologin wird wie bei einer normalen Installation nicht
übernommen - in den SDDM-/Login-Einstellungen wieder aktivierbar)." ;;
    inst_menu_title:EN) printf '%s\n' "Install the live system" ;;
    inst_menu_title:*)  printf '%s\n' "Live-System installieren" ;;
    inst_menu:EN) printf '%s\n' "Installation" ;;
    inst_menu:*)  printf '%s\n' "Installation" ;;
    inst_menu_choose:EN) printf '%s\n' "Choose target and install" ;;
    inst_menu_choose:*)  printf '%s\n' "Ziel wählen und installieren" ;;
    inst_menu_show:EN) printf '%s\n' "Show possible targets" ;;
    inst_menu_show:*)  printf '%s\n' "Mögliche Ziele anzeigen" ;;
    inst_menu_partition:EN) printf '%s\n' "Partition first (open the partitioner)" ;;
    inst_menu_partition:*)  printf '%s\n' "Zuerst partitionieren (Partitionierer öffnen)" ;;
    err_iso_system_area:EN) printf "%s '%s' lies in the system/boot area - aborted (data-loss protection).\n"  "$1" "$2" ;;
    err_iso_system_area:*) printf "%s '%s' liegt im System-/Boot-Bereich - abgebrochen (Schutz vor Datenverlust).\n"  "$1" "$2" ;;
    err_iso_fat_area:EN) printf '%s\n' "%s '%s' lies on a FAT/EFI partition - aborted.
Multi-GB files and boot trees do not belong there -
the computer's boot files would otherwise have been overwritten." "$1" "$2" ;;
    err_iso_fat_area:*)  printf '%s\n' "%s '%s' liegt auf einer FAT/EFI-Partition - abgebrochen.
Dorthin gehören keine mehr-GB-Dateien und keine Boot-Bäume - die
Boot-Dateien des Rechners wären sonst überschrieben worden." "$1" "$2" ;;
    iso_cleaning:EN) printf '%s\n' "Cleaning up..." ;;
    iso_cleaning:*)  printf '%s\n' "Räume auf..." ;;
    err_iso_work_invalid:EN) printf "Work directory '%s' invalid.\n"  "$1" ;;
    err_iso_work_invalid:*) printf "Arbeitsverzeichnis '%s' ungültig.\n"  "$1" ;;
    iso_cleanup_title:EN) printf 'Cleanup: unmounting mounts and removing build artifacts under %s\n'  "$1" ;;
    iso_cleanup_title:*) printf 'Aufräumen: löse Mounts und entferne Build-Artefakte unter %s\n'  "$1" ;;
    err_iso_artifacts_delete:EN) printf '%s\n' "Build artifacts could not be deleted" ;;
    err_iso_artifacts_delete:*)  printf '%s\n' "Build-Artefakte konnten nicht gelöscht werden" ;;
    iso_cleanup_done:EN) printf '%s\n' "Done. Work directory emptied (finished ISO is kept)." ;;
    iso_cleanup_done:*)  printf '%s\n' "Fertig. Arbeitsverzeichnis geleert (fertige ISO bleibt erhalten)." ;;
    iso_owner_set:EN) printf 'Owner of %s: %s\n'  "$1" "$2" ;;
    iso_owner_set:*) printf 'Eigentümer von %s: %s\n'  "$1" "$2" ;;
    iso_owner_failed:EN) printf "Owner of %s could not be changed to '%s' - manually: sudo chown -R \"%s:\" \"%s\"\n"  "$1" "$2" "$3" "$4" ;;
    iso_owner_failed:*) printf "Eigentümer von %s konnte nicht auf '%s' geändert werden - manuell: sudo chown -R \"%s:\" \"%s\"\n"  "$1" "$2" "$3" "$4" ;;
    err_iso_initrd_empty:EN) printf "Initramfs '%s' is empty.\n"  "$1" ;;
    err_iso_initrd_empty:*) printf "Initramfs '%s' ist leer.\n"  "$1" ;;
    err_iso_initrd_unmk:EN) printf '%s\n' "Initramfs cannot be unpacked (unmkinitramfs)." ;;
    err_iso_initrd_unmk:*)  printf '%s\n' "Initramfs lässt sich nicht entpacken (unmkinitramfs)." ;;
    err_iso_initrd_incomplete:EN) printf 'Initramfs is incomplete, missing:%s\n'  "$1" ;;
    err_iso_initrd_incomplete:*) printf 'Initramfs ist unvollständig, es fehlen:%s\n'  "$1" ;;
    err_iso_initrd_truncated:EN) printf '%s\n' "Initramfs main segment does not decompress completely (truncated/broken archive)." ;;
    err_iso_initrd_truncated:*)  printf '%s\n' "Initramfs-Hauptsegment lässt sich nicht vollständig dekomprimieren (abgeschnittenes/defektes Archiv)." ;;
    err_iso_work_spaces:EN) printf 'The work directory must not contain spaces: %s\n'  "$1" ;;
    err_iso_work_spaces:*) printf 'Das Arbeitsverzeichnis darf keine Leerzeichen enthalten: %s\n'  "$1" ;;
    err_iso_outdir_create:EN) printf 'Output directory %s could not be created\n'  "$1" ;;
    err_iso_outdir_create:*) printf 'Ausgabeordner %s konnte nicht angelegt werden\n'  "$1" ;;
    iso_missing_pkgs_title:EN) printf '%s\n' "Missing packages for the ISO build:" ;;
    iso_missing_pkgs_title:*)  printf '%s\n' "Fehlende Pakete für den ISO-Bau:" ;;
    err_iso_missing_pkgs:EN) printf '%s\n' "Missing packages: %s
Please install: apt-get install %s" "$1" "$2" ;;
    err_iso_missing_pkgs:*)  printf '%s\n' "Fehlende Pakete: %s
Bitte installieren: apt-get install %s" "$1" "$2" ;;
    iso_installing_pkgs:EN) printf 'Installing missing packages: %s ...\n'  "$1" ;;
    iso_installing_pkgs:*) printf 'Installiere fehlende Pakete: %s ...\n'  "$1" ;;
    err_iso_pkgs_failed:EN) printf '%s\n' "Packages could not be installed.
Please run 'sudo apt-get update' (refresh package lists) first
and restart the build afterwards." ;;
    err_iso_pkgs_failed:*)  printf '%s\n' "Pakete konnten nicht installiert werden.
Bitte zuerst 'sudo apt-get update' (Paketlisten auffrischen) ausführen
und den Bau danach erneut starten." ;;
    err_iso_tool_missing:EN) printf '%s not found - please install package(s): %s\n'  "$1" "$2" ;;
    err_iso_tool_missing:*) printf '%s nicht gefunden - bitte Paket(e) installieren: %s\n'  "$1" "$2" ;;
    info_iso_casper_missing:EN) printf '%s\n' "casper files are missing (hooks/casper or scripts/casper) - typically on an
installed copy from an older tool version (the installer used to remove them)." ;;
    info_iso_casper_missing:*)  printf '%s\n' "casper-Dateien fehlen (hooks/casper oder scripts/casper) - typisch bei einer
installierten Kopie aus einer älteren Tool-Version (der Installer entfernte sie früher)." ;;
    err_iso_casper_missing_fatal:EN) printf '%s\n' "casper files are missing - the build would produce an unbootable ISO.
Manually: download and extract the casper package, then copy to /usr/share/initramfs-tools/:
  cd /tmp && apt-get download casper && dpkg-deb -x casper_*.deb casper-x
  sudo cp -a casper-x/usr/share/initramfs-tools/hooks/casper /usr/share/initramfs-tools/hooks/
  sudo cp -a casper-x/usr/share/initramfs-tools/scripts/. /usr/share/initramfs-tools/scripts/" ;;
    err_iso_casper_missing_fatal:*)  printf '%s\n' "casper-Dateien fehlen - der Bau würde eine unbootbare ISO erzeugen.
Manuell: das casper-Paket laden und entpacken, dann nach /usr/share/initramfs-tools/ kopieren:
  cd /tmp && apt-get download casper && dpkg-deb -x casper_*.deb casper-x
  sudo cp -a casper-x/usr/share/initramfs-tools/hooks/casper /usr/share/initramfs-tools/hooks/
  sudo cp -a casper-x/usr/share/initramfs-tools/scripts/. /usr/share/initramfs-tools/scripts/" ;;
    err_iso_casper_download:EN) printf '%s\n' "apt-get download casper failed (network/archive reachable?).
Manually: sudo apt-get update, then apt-get download casper; extract the deb with
dpkg-deb -x and copy hooks/casper + scripts/. to /usr/share/initramfs-tools/." ;;
    err_iso_casper_download:*)  printf '%s\n' "apt-get download casper fehlgeschlagen (Netzwerk/Archive erreichbar?).
Manuell: sudo apt-get update, dann apt-get download casper; die Deb-Datei mit
dpkg-deb -x entpacken und hooks/casper + scripts/. nach /usr/share/initramfs-tools/ kopieren." ;;
    err_iso_casper_download_short:EN) printf '%s\n' "apt-get download casper failed (network/archive reachable?)." ;;
    err_iso_casper_download_short:*)  printf '%s\n' "apt-get download casper fehlgeschlagen (Netzwerk/Archive erreichbar?)." ;;
    err_iso_casper_extract:EN) printf '%s\n' "dpkg-deb -x could not extract the casper package (download broken?)." ;;
    err_iso_casper_extract:*)  printf '%s\n' "dpkg-deb -x konnte das casper-Paket nicht entpacken (Download defekt?)." ;;
    err_iso_casper_restore_failed:EN) printf '%s\n' "casper files could not be restored (unexpected package layout).
See the message above for manual steps." ;;
    err_iso_casper_restore_failed:*)  printf '%s\n' "casper-Dateien konnten nicht wiederhergestellt werden (unerwartetes Paket-Layout).
Manuell siehe Meldung oben." ;;
    info_iso_casper_restored:EN) printf '%s\n' "casper files restored (from the current casper package)." ;;
    info_iso_casper_restored:*)  printf '%s\n' "casper-Dateien wiederhergestellt (aus dem aktuellen casper-Paket)." ;;
    err_iso_low_space:EN) printf '%s\n' "Only about %s GB free in %s - too little!
The build needs at least about 2 GB, sensibly 8+ GB.
Please choose a different work directory (e.g. an external disk)." "$1" "$2" ;;
    err_iso_low_space:*)  printf '%s\n' "Nur ca. %s GB frei in %s - zu wenig!
Für den Bau werden mindestens ca. 2 GB, sinnvoll 8+ GB gebraucht.
Bitte ein anderes Arbeitsverzeichnis wählen (z. B. externe Festplatte)." "$1" "$2" ;;
    err_iso_no_overlay:EN) printf '%s\n' "Kernel module 'overlay' is not available!
Running kernel: %s
This usually happens when the kernel was updated but NOT yet rebooted
and the modules of the running kernel are then missing from /lib/modules.
-> Please reboot once and run the builder again." "$1" ;;
    err_iso_no_overlay:*)  printf '%s\n' "Kernelmodul 'overlay' ist nicht verfügbar!
Laufender Kernel: %s
Das passiert meist, wenn der Kernel aktualisiert, aber noch NICHT neu gestartet
wurde - die Module des laufenden Kernels fehlen dann in /lib/modules.
-> Bitte einmal NEU STARTEN und den Builder erneut ausführen." "$1" ;;
    err_iso_label_empty:EN) printf '%s\n' "Volume label is empty" ;;
    err_iso_label_empty:*)  printf '%s\n' "Volume-Label ist leer" ;;
    err_iso_label_long:EN) printf 'Volume label too long (max. 32 characters): %s\n'  "$1" ;;
    err_iso_label_long:*) printf 'Volume-Label zu lang (max. 32 Zeichen): %s\n'  "$1" ;;
    err_iso_label_chars:EN) printf 'Volume label contains invalid characters (only A-Z 0-9 . _ -): %s\n'  "$1" ;;
    err_iso_label_chars:*) printf 'Volume-Label enthält ungültige Zeichen (nur A-Z 0-9 . _ -): %s\n'  "$1" ;;
    err_iso_bad_comp:EN) printf '%s\n' "Invalid squashfs compression: '%s'
Allowed: xz, zstd, lzma, gzip, lzo, lz4 (configurable in the script: SQUASH_COMP=...)" "$1" ;;
    err_iso_bad_comp:*)  printf '%s\n' "Ungültige SquashFS-Kompression: '%s'
Erlaubt: xz, zstd, lzma, gzip, lzo, lz4 (Standard im Script einstellbar: SQUASH_COMP=...)" "$1" ;;
    iso_comp:EN) printf 'SquashFS compression: %s\n'  "$1" ;;
    iso_comp:*) printf 'SquashFS-Kompression: %s\n'  "$1" ;;
    err_iso_workdirs:EN) printf '%s\n' "Work directories could not be created" ;;
    err_iso_workdirs:*)  printf '%s\n' "Arbeitsverzeichnisse konnten nicht angelegt werden" ;;
    err_iso_no_kernel_modules:EN) printf '%s\n' "No kernel with modules found!
Most common cause: kernel updated but NOT rebooted yet - the modules
of the running kernel are then missing from /lib/modules.
-> Please reboot once and run the builder again.
(If still missing after the reboot: sudo apt-get install --reinstall linux-modules-\$(uname -r))" ;;
    err_iso_no_kernel_modules:*)  printf '%s\n' "Kein Kernel mit Modulen gefunden!
Häufigste Ursache: Kernel aktualisiert, aber noch NICHT neu gestartet - die Module
des laufenden Kernels fehlen dann in /lib/modules.
-> Bitte einmal NEU STARTEN und den Builder erneut ausführen.
(Falls nach dem Neustart weiterhin fehlend: sudo apt-get install --reinstall linux-modules-\$(uname -r))" ;;
    err_iso_kernel_file_missing:EN) printf 'No kernel found (/boot/vmlinuz-%s missing)!\n'  "$1" ;;
    err_iso_kernel_file_missing:*) printf 'Kein Kernel gefunden (/boot/vmlinuz-%s fehlt)!\n'  "$1" ;;
    iso_using_kernel:EN) printf 'Using kernel: %s (%s)\n'  "$1" "$2" ;;
    iso_using_kernel:*) printf 'Verwende Kernel: %s (%s)\n'  "$1" "$2" ;;
    iso_copying_kernel:EN) printf '%s\n' "Copying kernel..." ;;
    iso_copying_kernel:*)  printf '%s\n' "Kopiere Kernel..." ;;
    err_iso_kernel_copy:EN) printf '%s\n' "Kernel copy failed" ;;
    err_iso_kernel_copy:*)  printf '%s\n' "Kernel-Kopie fehlgeschlagen" ;;
    iso_live_autologin_user:EN) printf "Live autologin as the secured system's user: %s (username= boot parameter).\n"  "$1" ;;
    iso_live_autologin_user:*) printf 'Live-Autologin als Benutzer des gesicherten Systems: %s (username= Boot-Parameter).\n'  "$1" ;;
    iso_dm_session:EN) printf '%s session adopted for the live autologin: %s\n'  "$1" "$2" ;;
    iso_dm_session:*) printf '%s-Sitzung für den Live-Autologin übernommen: %s\n'  "$1" "$2" ;;
    warn_iso_no_dm_session:EN) printf 'No default %s session could be determined - the live autologin may fail (login screen). Please log out once in the source system, choose the desired session and rebuild the ISO.\n'  "$1" ;;
    warn_iso_no_dm_session:*) printf 'Keine Standard-Sitzung des Display-Managers (%s) ermittelbar - der Live-Autologin kann scheitern (Login-Bildschirm). Bitte im Quell-System einmal abmelden, die gewünschte Sitzung wählen und die ISO neu bauen.\n'  "$1" ;;
    iso_lightdm_block_written:EN) printf 'LightDM autologin block written into the image: user %s, session %s.\n'  "$1" "$2" ;;
    iso_lightdm_block_written:*) printf 'LightDM-Autologin-Block ins Abbild geschrieben: Benutzer %s, Sitzung %s.\n'  "$1" "$2" ;;
    iso_gdm_session_set:EN) printf 'GDM: session for the live autologin available via AccountsService: %s\n'  "$1" ;;
    iso_gdm_session_set:*) printf 'GDM: Sitzung für den Live-Autologin über AccountsService bereit: %s\n'  "$1" ;;
    iso_disable_autologin:EN) printf '%s\n' "Disabling casper autologin in the live system (login screen instead of automatic login)..." ;;
    iso_disable_autologin:*)  printf '%s\n' "Deaktiviere casper-Autologin im Live-System (Login-Bildschirm statt automatischer Anmeldung)..." ;;
    iso_fallback_initramfs:EN) printf '%s\n' "Fallback (older Ubuntu version): building the initramfs the normal way (system configuration)..." ;;
    iso_fallback_initramfs:*)  printf '%s\n' "Fallback (ältere Ubuntu-Version): baue Initramfs auf dem normalen Weg (Systemkonfiguration)..." ;;
    iso_building_initramfs:EN) printf '%s\n' "Building initramfs with casper (all drivers, may take several minutes)..." ;;
    iso_building_initramfs:*)  printf '%s\n' "Baue Initramfs mit casper (alle Treiber, kann einige Minuten dauern)..." ;;
    err_iso_mkinitramfs_failed:EN) printf '%s\n' "mkinitramfs failed - message from mkinitramfs:" ;;
    err_iso_mkinitramfs_failed:*)  printf '%s\n' "mkinitramfs fehlgeschlagen - Meldung von mkinitramfs:" ;;
    iso_check_pkgs:EN) printf '%s\n' "Check packages: casper initramfs-tools busybox-initramfs" ;;
    iso_check_pkgs:*)  printf '%s\n' "Pakete prüfen: casper initramfs-tools busybox-initramfs" ;;
    err_iso_initrd_failed:EN) printf '%s\n' "Could not create the initramfs - see the message above." ;;
    err_iso_initrd_failed:*)  printf '%s\n' "Initramfs konnte nicht erstellt werden - siehe Meldung oben." ;;
    err_iso_initrd_broken:EN) printf '%s\n' "The built initramfs is incomplete/broken - aborting so that no
unbootable ISO is produced. Please check: kernel modules (ls /lib/modules/%s/kernel),
casper package (hooks/casper + scripts/casper) and free disk space; then rebuild." "$1" ;;
    err_iso_initrd_broken:*)  printf '%s\n' "Das gebaute Initramfs ist unvollständig/defekt - Abbruch, damit keine
unbootbare ISO entsteht. Bitte prüfen: Kernel-Module (ls /lib/modules/%s/kernel),
casper-Paket (hooks/casper + scripts/casper) und freien Speicherplatz; dann neu bauen." "$1" ;;
    iso_mounting_overlay:EN) printf '%s\n' "Mounting root filesystem (read-only overlay)..." ;;
    iso_mounting_overlay:*)  printf '%s\n' "Hänge Root-Dateisystem (read-only Overlay) ein..." ;;
    err_iso_overlay_dirs:EN) printf '%s\n' "Overlay directories failed" ;;
    err_iso_overlay_dirs:*)  printf '%s\n' "Overlay-Verzeichnisse fehlgeschlagen" ;;
    err_iso_overlay_mount:EN) printf '%s\n' "Overlay mount failed" ;;
    err_iso_overlay_mount:*)  printf '%s\n' "Overlay-Mount fehlgeschlagen" ;;
    err_iso_overlay_incomplete:EN) printf '%s\n' "Overlay content incomplete" ;;
    err_iso_overlay_incomplete:*)  printf '%s\n' "Overlay-Inhalt unvollständig" ;;
    err_iso_no_systemd:EN) printf '%s\n' "systemd missing from the image - are / or /usr on a separate partition?" ;;
    err_iso_no_systemd:*)  printf '%s\n' "systemd fehlt im Abbild - liegt / oder /usr auf einer eigenen Partition?" ;;
    iso_nm_enabled:EN) printf '%s\n' "Network: NetworkManager enabled for all devices in the image." ;;
    iso_nm_enabled:*)  printf '%s\n' "Netzwerk: NetworkManager im Abbild für alle Geräte freigegeben." ;;
    iso_networkd_fallback:EN) printf '%s\n' "Network: systemd-networkd DHCP fallback for foreign hardware added to the image." ;;
    iso_networkd_fallback:*)  printf '%s\n' "Netzwerk: systemd-networkd-DHCP-Fallback für fremde Hardware ins Abbild übernommen." ;;
    iso_sddm_block_written:EN) printf 'SDDM autologin block written into the image: user %s, session %s.\n'  "$1" "$2" ;;
    iso_sddm_block_written:*) printf 'SDDM-Autologin-Block ins Abbild geschrieben: Benutzer %s, Sitzung %s.\n'  "$1" "$2" ;;
    iso_sddm_fallback:EN) printf "SDDM session fallback set in the image's /var/lib/sddm/state.conf: %s\n"  "$1" ;;
    iso_sddm_fallback:*) printf 'SDDM-Sitzungs-Fallback in /var/lib/sddm/state.conf des Abbilds gesetzt: %s\n'  "$1" ;;
    iso_close_apps:EN) printf '%s\n' "Important: close other applications if possible so the image is consistent." ;;
    iso_close_apps:*)  printf '%s\n' "Wichtig: Schließe möglichst andere Anwendungen, damit das Abbild konsistent ist." ;;
    iso_creating_squash_slow:EN) printf 'Creating SquashFS (%s - highest compression, may take a long time)...\n'  "$1" ;;
    iso_creating_squash_slow:*) printf 'Erstelle SquashFS (%s - höchste Kompression, kann lange dauern)...\n'  "$1" ;;
    iso_creating_squash:EN) printf 'Creating SquashFS (%s)...\n'  "$1" ;;
    iso_creating_squash:*) printf 'Erstelle SquashFS (%s)...\n'  "$1" ;;
    err_iso_mksquashfs:EN) printf '%s\n' "mksquashfs failed" ;;
    err_iso_mksquashfs:*)  printf '%s\n' "mksquashfs fehlgeschlagen" ;;
    err_iso_squash_move:EN) printf '%s\n' "applying the SquashFS failed" ;;
    err_iso_squash_move:*)  printf '%s\n' "SquashFS übernehmen fehlgeschlagen" ;;
    iso_creating_iso:EN) printf 'Creating ISO with grub-mkrescue (BIOS + UEFI bootable): %s\n'  "$1" ;;
    iso_creating_iso:*) printf 'Erstelle ISO mit grub-mkrescue (BIOS + UEFI bootbar): %s\n'  "$1" ;;
    err_iso_grubmkrescue:EN) printf '%s\n' "grub-mkrescue failed.
Common causes: mtools missing or broken (apt-get install mtools),
insufficient disk space for the temporary files, or the
output ISO resides in the same directory as the source files." ;;
    err_iso_grubmkrescue:*)  printf '%s\n' "grub-mkrescue fehlgeschlagen.
Häufige Ursachen: mtools fehlt oder ist defekt (apt-get install mtools),
zu wenig Speicherplatz für die temporären Dateien, oder die
Ausgabe-ISO liegt im selben Verzeichnis wie die Quelldateien." ;;
    err_iso_not_created:EN) printf '%s\n' "ISO was not created!" ;;
    err_iso_not_created:*)  printf '%s\n' "ISO wurde nicht erstellt!" ;;
    iso_success:EN) printf '%s\n' "SUCCESS: ISO CREATED" ;;
    iso_success:*)  printf '%s\n' "ERFOLG: ISO ERSTELLT" ;;
    iso_done_close:EN) printf '%s\n' "DONE - The ISO has been created. You can close this tool now." ;;
    iso_done_close:*)  printf '%s\n' "FERTIG - Die ISO ist erstellt. Sie können dieses Tool jetzt schließen." ;;
    iso_output_path:EN) printf 'Output path: %s (%s MB)\n'  "$1" "$2" ;;
    iso_output_path:*) printf 'Ausgabepfad: %s (%s MB)\n'  "$1" "$2" ;;
    iso_autologin_user_session:EN) printf 'Live autologin: %s, session %s (user of the secured system)\n'  "$1" "$2" ;;
    iso_autologin_user_session:*) printf 'Live-Autologin: %s, Sitzung %s (Benutzer des gesicherten Systems)\n'  "$1" "$2" ;;
    iso_autologin_user:EN) printf 'Live autologin: %s (user of the secured system)\n'  "$1" ;;
    iso_autologin_user:*) printf 'Live-Autologin: %s (Benutzer des gesicherten Systems)\n'  "$1" ;;
    iso_autologin_none:EN) printf '%s\n' "Live system starts with the login screen (autologin not possible)." ;;
    iso_autologin_none:*)  printf '%s\n' "Live-System startet mit dem Login-Bildschirm (kein Autologin möglich)." ;;
    iso_comp_xz:EN) printf '%s\n' "smallest size, slowest build + unpacking" ;;
    iso_comp_xz:*)  printf '%s\n' "kleinste Größe, langsamster Bau + Entpacken" ;;
    iso_comp_zstd:EN) printf '%s\n' "very fast build + unpacking, good size" ;;
    iso_comp_zstd:*)  printf '%s\n' "sehr schneller Bau + Entpacken, gute Größe" ;;
    iso_comp_lzma:EN) printf '%s\n' "small size, slow build" ;;
    iso_comp_lzma:*)  printf '%s\n' "kleine Größe, langsamer Bau" ;;
    iso_comp_gzip:EN) printf '%s\n' "fast, classic format" ;;
    iso_comp_gzip:*)  printf '%s\n' "schnell, klassisches Format" ;;
    iso_comp_lzo:EN) printf '%s\n' "very fast build, larger images" ;;
    iso_comp_lzo:*)  printf '%s\n' "sehr schneller Bau, größere Images" ;;
    iso_comp_lz4:EN) printf '%s\n' "fastest method, largest images" ;;
    iso_comp_lz4:*)  printf '%s\n' "schnellstes Verfahren, größte Images" ;;
    iso_comp_default:EN) printf '%s\n' "   [default]" ;;
    iso_comp_default:*)  printf '%s\n' "   [Standard]" ;;
    iso_choose_comp:EN) printf '%s\n' "Choose SquashFS compression" ;;
    iso_choose_comp:*)  printf '%s\n' "SquashFS-Kompression wählen" ;;
    iso_comp_invalid:EN) printf 'Invalid input (1-%s or empty).\n'  "$1" ;;
    iso_comp_invalid:*) printf 'Ungültige Eingabe (1-%s oder leer).\n'  "$1" ;;
    iso_menu_title:EN) printf '%s\n' "Create live ISO from the running system" ;;
    iso_menu_title:*)  printf '%s\n' "Live-ISO vom laufenden System erstellen" ;;
    iso_summary:EN) printf '%s\n' "Summary:" ;;
    iso_summary:*)  printf '%s\n' "Zusammenfassung:" ;;
    iso_sum_work:EN) printf '  Work directory: %s\n'  "$1" ;;
    iso_sum_work:*) printf '  Arbeitsverzeichnis: %s\n'  "$1" ;;
    iso_sum_target:EN) printf '  Target:             %s\n'  "$1" ;;
    iso_sum_target:*) printf '  Ziel:               %s\n'  "$1" ;;
    iso_sum_excludes:EN) printf '  Exclusions:         %s\n'  "$1" ;;
    iso_sum_excludes:*) printf '  Ausschlüsse:        %s\n'  "$1" ;;
    iso_sum_no_excludes:EN) printf '%s\n' "  Exclusions:         (none)" ;;
    iso_sum_no_excludes:*)  printf '%s\n' "  Ausschlüsse:        (keine)" ;;
    exp_desc_part:EN) printf '%s\n' "Partitioner" ;;
    exp_desc_part:*)  printf '%s\n' "Partitionierer" ;;
    exp_desc_iso:EN) printf '%s\n' "ISO creation" ;;
    exp_desc_iso:*)  printf '%s\n' "ISO-Erstellung" ;;
    exp_desc_install:EN) printf '%s\n' "Installation" ;;
    exp_desc_install:*)  printf '%s\n' "Installation" ;;
    exp_title:EN) printf '%s\n' "Export individual scripts" ;;
    exp_title:*)  printf '%s\n' "Einzelskripte exportieren" ;;
    exp_which_parts:EN) printf '%s\n' "Which parts? " ;;
    exp_which_parts:*)  printf '%s\n' "Welche Teile? " ;;
    exp_parts_hint:EN) printf '%s\n' "e.g. 2 or 1,3; Enter = all three, 0 = Back, 00 = Quit" ;;
    exp_parts_hint:*)  printf '%s\n' "z. B. 2 oder 1,3; Enter = alle drei, 0 = Abbrechen, 00 = Ende" ;;
    exp_sel_invalid:EN) printf '%s\n' "Invalid input - allowed: 1, 2 or 3, comma separated (e.g. 1,3)." ;;
    exp_sel_invalid:*)  printf '%s\n' "Ungültige Eingabe - erlaubt: 1, 2 oder 3, kommasepariert (z. B. 1,3)." ;;
    err_exp_no_marker:EN) printf "Block marker '%s' not found in '%s'.\n"  "$1" "$2" ;;
    err_exp_no_marker:*) printf "Blockmarkierung '%s' in '%s' nicht gefunden.\n"  "$1" "$2" ;;
    err_exp_no_core:EN) printf "Core header not found in '%s' - export not possible.\n"  "$1" ;;
    err_exp_no_core:*) printf "Kernkopf in '%s' nicht gefunden - Export nicht möglich.\n"  "$1" ;;
    err_exp_need_sel:EN) printf '%s is missing the selection (e.g. 1,2,3).\n'  "$1" ;;
    err_exp_need_sel:*) printf 'Für %s fehlt die Auswahl (z. B. 1,2,3).\n'  "$1" ;;
    err_need_dir:EN) printf '%s is missing a directory.\n'  "$1" ;;
    err_need_dir:*) printf 'Für %s fehlt ein Verzeichnis.\n'  "$1" ;;
    err_need_path:EN) printf '%s is missing a path.\n'  "$1" ;;
    err_need_path:*) printf 'Für %s fehlt ein Pfad.\n'  "$1" ;;
    err_need_label:EN) printf '%s is missing a label.\n'  "$1" ;;
    err_need_label:*) printf 'Für %s fehlt ein Label.\n'  "$1" ;;
    err_need_algo:EN) printf '%s is missing an algorithm (xz, zstd, lzma, gzip, lzo, lz4).\n'  "$1" ;;
    err_need_algo:*) printf 'Für %s fehlt ein Algorithmus (xz, zstd, lzma, gzip, lzo, lz4).\n'  "$1" ;;
    err_need_excludes:EN) printf '%s is missing the exclusions.\n'  "$1" ;;
    err_need_excludes:*) printf 'Für %s fehlen die Ausschlüsse.\n'  "$1" ;;
    err_need_device:EN) printf '%s is missing a device.\n'  "$1" ;;
    err_need_device:*) printf 'Für %s fehlt ein Gerät.\n'  "$1" ;;
    err_unknown_arg:EN) printf 'Unknown argument: %s (help: %s)\n'  "$1" "$2" ;;
    err_unknown_arg:*) printf 'Unbekanntes Argument: %s (Hilfe: %s)\n'  "$1" "$2" ;;
    err_unknown_opt:EN) printf 'Unknown option: %s (help: %s)\n'  "$1" "$2" ;;
    err_unknown_opt:*) printf 'Unbekannte Option: %s (Hilfe: %s)\n'  "$1" "$2" ;;
    err_unknown_cmd:EN) printf 'Unknown command: %s\n'  "$1" ;;
    err_unknown_cmd:*) printf 'Unbekannter Befehl: %s\n'  "$1" ;;
    err_exp_bad_sel:EN) printf "Invalid selection: '%s' (allowed: 1, 2, 3 - e.g. -s 1,2,3)\n"  "$1" ;;
    err_exp_bad_sel:*) printf "Ungültige Auswahl: '%s' (erlaubt: 1, 2, 3 - z. B. -s 1,2,3)\n"  "$1" ;;
    err_exp_outdir:EN) printf "Target directory '%s' could not be created.\n"  "$1" ;;
    err_exp_outdir:*) printf "Zielverzeichnis '%s' konnte nicht angelegt werden.\n"  "$1" ;;
    err_exp_chmod:EN) printf 'chmod failed: %s\n'  "$1" ;;
    err_exp_chmod:*) printf 'chmod fehlgeschlagen: %s\n'  "$1" ;;
    err_exp_invalid_script:EN) printf 'Generated script is invalid and will be removed: %s\n'  "$1" ;;
    err_exp_invalid_script:*) printf 'Erzeugtes Skript ist ungültig und wird entfernt: %s\n'  "$1" ;;
    err_exp_aborted:EN) printf '%s\n' "Export aborted - at least one script was faulty." ;;
    err_exp_aborted:*)  printf '%s\n' "Export abgebrochen - mindestens ein Skript war fehlerhaft." ;;
    exp_done:EN) printf '%s\n' "Export finished" ;;
    exp_done:*)  printf '%s\n' "Export abgeschlossen" ;;
    err_iso_one_target:EN) printf '%s\n' "Only one ISO target may be given." ;;
    err_iso_one_target:*)  printf '%s\n' "Nur ein ISO-Ziel angeben." ;;
    err_iso_umount_failed:EN) printf "'%s' could not be unmounted!\n"  "$1" ;;
    err_iso_umount_failed:*) printf "'%s' konnte nicht ausgehängt werden!\n"  "$1" ;;
    grub_std:EN) printf '%s\n' "Standard (quiet splash)" ;;
    grub_std:*)  printf '%s\n' "Standard (quiet splash)" ;;
    grub_verbose:EN) printf '%s\n' "verbose (error diagnosis)" ;;
    grub_verbose:*)  printf '%s\n' "ausführlich (Fehlerdiagnose)" ;;
    grub_toram:EN) printf '%s\n' "load completely into RAM (toram)" ;;
    grub_toram:*)  printf '%s\n' "vollständig in den RAM laden (toram)" ;;
    grub_nomodeset:EN) printf '%s\n' "bypass graphics problems (nomodeset)" ;;
    grub_nomodeset:*)  printf '%s\n' "Grafikprobleme umgehen (nomodeset)" ;;
    *) printf '%s\n' "$key" ;;
    esac
}
te() { t "$@" >&2; }
td() { te "$@"; exit 1; }



#@@BLOCK:COMMON
# ============================================================
# Farben
# ============================================================

USE_COLOR="j"

# -nc / --no-color: Farben abschalten; Flags aus den Argumenten entfernen
no_color_args=()
for a in "$@"; do
    if [[ "$a" == "--no-color" || "$a" == "-nc" ]]; then
        USE_COLOR="n"
    else
        no_color_args+=("$a")
    fi
done
set -- "${no_color_args[@]}"

# FALLBACK_MODUS - Kompatibilitätsweg für ältere Ubuntu-Versionen (vor 25.04,
# casper schreibt dort andere Autologin-/Sitzungsformate):
#   auto (Standard) = ältere Version automatisch erkennen und für sie den
#     normalen Weg nutzen (offizielles Initramfs des Live-Mediums bzw.
#     Systemkonfiguration; update-grub im Installer); neuere Versionen wie
#     bisher (Mini-Confdir, handgeschriebene grub.cfg)
#   an = Fallback erzwingen; aus = Fallback niemals verwenden
FALLBACK_MODUS="auto"

# ist_altes_ubuntu - wahr für Ubuntu-Versionen vor 25.04 (altes casper-
# Autologin-/Sitzungsformat), gelesen aus /etc/os-release des laufenden
# Systems (= das Quell-System des Abbilds)
ist_altes_ubuntu() {
    local vid
    vid="$(sed -n 's/^VERSION_ID="\?\([^"]*\)"\?$/\1/p' /etc/os-release 2>/dev/null | head -n1 || true)"
    [[ -n "$vid" ]] || return 1
    awk -v v="$vid" 'BEGIN {
        split(v, a, ".")
        exit !((a[1] + 0) < 25 || ((a[1] + 0) == 25 && (a[2] + 0) < 4))
    }'
}

# fallback_aktiv - entscheidet anhand FALLBACK_MODUS und Ubuntu-Version
fallback_aktiv() {
    case "$FALLBACK_MODUS" in
        an) return 0 ;;
        aus) return 1 ;;
        *) ist_altes_ubuntu ;;
    esac
}

# init_colors - Farbcodes je nach Terminal und NO_COLOR setzen
init_colors() {
    if [[ "$USE_COLOR" == "j" && -t 1 && -z "${NO_COLOR:-}" ]]; then
        C_HEAD=$'\e[1;36m'
        C_TEXT=$'\e[1;33m'
        C_FILE=$'\e[1;35m'
        C_MISC=$'\e[1;32m'
        C_ERR=$'\e[1;31m'
        C_OFF=$'\e[0m'
    else
        C_HEAD=""
        C_TEXT=""
        C_FILE=""
        C_MISC=""
        C_ERR=""
        C_OFF=""
    fi
}

init_colors

# ---------- Ausgabe-Helfer ----------

head_msg() { printf '\n%s\n' "${C_HEAD}=== $* ===${C_OFF}"; }

txt()   { printf '%s\n' "${C_TEXT}$*${C_OFF}"; }
misc()  { printf '%s\n' "${C_MISC}$*${C_OFF}"; }
warn()  { printf '%s\n' "${C_TEXT}$(t word_warning): $*${C_OFF}"; }
err()   { printf '%s\n' "${C_ERR}>>> $*${C_OFF}" >&2; }

fstr()  { printf '%s' "${C_FILE}$*${C_OFF}"; }

die() {
    printf '\n%s\n' "${C_ERR}>>> $(t word_error): $*${C_OFF}" >&2
    exit 3
}

dump_misc() { "$@" 2>&1 | sed "s/^/${C_MISC}/; s/$/${C_OFF}/"; }

# ---------- Eingabe-Helfer (Zahlen-Auswahl) ----------

INTERACTIVE="n"
INPUT=""
USER_ABORTED="n"

get_input() {
    INPUT=""
    if [[ -t 0 ]]; then
        read -r INPUT && return 0
    else
        read -r INPUT </dev/tty 2>/dev/null && return 0
    fi
    return 1
}

quit_all() {
    # 00 = GESAMTES Skript SOFORT beenden (42 = Quit-All-Signal, wird von
    # run_action durchgereicht und vom aufrufenden Bündel-Skript ausgewertet)
    exit 42
}

menu_select() {
    local title="$1"
    shift
    local -a opts=("$@")
    local o pick

    head_msg "$title"
    local i=1
    for o in "${opts[@]}"; do
        misc "  ${i}) ${o}"
        i=$((i + 1))
    done
    while :; do
        printf '%s' "${C_TEXT}$(t menu_choice)${C_MISC}[1-${#opts[@]}, $(t menu_abort_quit)]: ${C_OFF}"
        get_input || { USER_ABORTED="j"; return 1; }
        pick="${INPUT:-0}"
        case "$pick" in
            00) quit_all ;;
            0|q|Q) USER_ABORTED="j"; return 1 ;;
        esac
        if [[ ! "$pick" =~ ^[0-9]+$ ]]; then
            misc "$(t menu_enter_number)"
            continue
        fi
        if (( pick >= 1 && pick <= ${#opts[@]} )); then
            MENU_NR="$pick"
            USER_ABORTED="n"
            return 0
        fi
        misc "$(t menu_invalid_number "${#opts[@]}")"
    done
}

ask_string() {
    local prompt="$1" def="${2:-}"
    if [[ -n "$def" ]]; then
        printf '%s' "${C_TEXT}${prompt} ${C_MISC}[${def}]: ${C_OFF}"
    else
        printf '%s' "${C_TEXT}${prompt}: ${C_OFF}"
    fi
    get_input || return 1
    ANSWER="${INPUT:-$def}"
    return 0
}

confirm_yes() {
    if [[ "${ASSUME_YES:-n}" == "j" ]]; then
        return 0
    fi
    printf '%s' "${C_TEXT}$1 ${C_MISC}[$(t q_jn)]: ${C_OFF}"
    get_input || return 1
    case "${INPUT,,}" in
        ""|j|ja|y|yes) return 0 ;;
        *) return 1 ;;
    esac
}

confirm_ja_nein() {
    if [[ "${ASSUME_YES:-n}" == "j" ]]; then
        return 0
    fi
    while :; do
        printf '%s' "${C_TEXT}$(t q_confirm_continue) ${C_MISC}[$(t q_jn_lower)]: ${C_OFF}"
        get_input || return 1
        case "${INPUT,,}" in
            j|ja|y|yes) return 0 ;;
            n|nein|no) return 1 ;;
            "")
                misc "$(t q_empty_abort)"
                return 1 ;;
            *)
                misc "$(t q_yes_no_please)"
                continue ;;
        esac
    done
}

pause_key() {
    printf '%s' "${C_TEXT}$(t info_press_enter)${C_OFF}"
    get_input >/dev/null 2>&1 || true
    printf '\n'
}

# ---------- Root / Umgebung ----------

invoking_home() {
    local u="${SUDO_USER:-}" h=""
    if [[ -n "$u" ]]; then
        h="$(getent passwd "$u" 2>/dev/null | cut -d: -f6 || true)"
    fi
    if [[ -z "$h" ]]; then
        h="${HOME:-/root}"
    fi
    printf '%s\n' "$h"
}

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        txt "$(t info_requesting_root)"
        # Zusatzargumente (z. B. --action <funktion>) durchreichen: nach dem
        # Root-Wechsel wird die GEWAEHLTE Aktion direkt ausgefuehrt, ohne
        # erneutes Menue (Regel Nutzer).
        exec sudo bash "$SCRIPT_PATH" "${ORIG_ARGS[@]}" "$@"
    fi
}

# ============================================================
# Geräte-Grundlagen (sfdisk/lsblk, alles read-only)
# ============================================================

sfdisk_dump() {
    sfdisk -d "$1" 2>/dev/null || true
}

disk_table() {
    sfdisk_dump "$1" | sed -n 's/^label: *//p' | head -n1
}

disk_is_gpt() {
    [[ "$(disk_table "$1")" == "gpt" ]]
}

disk_has_biosboot() {
    sfdisk_dump "$1" | grep -qi "21686148-6449-6e6f-744e-656564454649" || return 1
    return 0
}

part_regions() {
    local disk="$1" base
    base="${disk##*/}"
    sfdisk_dump "$disk" | while IFS= read -r line; do
        local dev start size nr
        [[ "$line" == *" : start="* ]] || continue
        dev="${line%% :*}"
        dev="${dev##*/}"
        start="$(printf '%s\n' "$line" | sed -n 's/.*start= *\([0-9]*\),.*/\1/p')"
        size="$(printf '%s\n' "$line" | sed -n 's/.*size= *\([0-9]*\),.*/\1/p')"
        nr="${dev#"$base"}"
        nr="${nr#p}"
        [[ "$nr" =~ ^[0-9]+$ ]] || continue
        [[ -n "$start" && -n "$size" ]] || continue
        printf '%s %s %s\n' "$start" "$size" "$nr"
    done | sort -n
}

part_nrs() {
    local start size nr
    part_regions "$1" | while read -r start size nr; do
        printf '%s\n' "$nr"
    done | sort -n
}

sector_size() {
    local s
    s="$(blockdev --getss "$1" 2>/dev/null)" || s=""
    if [[ ! "$s" =~ ^[0-9]+$ ]] || (( s < 512 )); then
        s=512
    fi
    printf '%s\n' "$s"
}

part_prefix() {
    local dev="$1"
    case "$dev" in
        *[0-9]) printf '%sp\n' "$dev" ;;
        *) printf '%s\n' "$dev" ;;
    esac
}

compute_gaps() {
    local disk="$1"
    local SECTOR ALIGN first last total_bytes
    SECTOR="$(sector_size "$disk")"
    ALIGN=$((1048576 / SECTOR))

    first="$(sfdisk_dump "$disk" | sed -n 's/^first-lba: *//p' | head -n1)"
    last="$(sfdisk_dump "$disk" | sed -n 's/^last-lba: *//p' | head -n1)"
    if [[ -z "$first" || -z "$last" ]]; then
        total_bytes="$(blockdev --getsize64 "$disk" 2>/dev/null)" || return 1
        [[ "$total_bytes" =~ ^[0-9]+$ ]] || return 1
        first="$ALIGN"
        last=$((total_bytes / SECTOR - 1))
    fi

    local -a occ=()
    local s sz nr dev e
    while read -r s sz nr; do
        [[ -n "$s" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        if part_is_extended "$dev"; then
            continue
        fi
        e=$((s + sz - 1))
        s=$((s / ALIGN * ALIGN))
        if (( e % ALIGN )); then
            e=$(( (e / ALIGN + 1) * ALIGN - 1 ))
        fi
        if (( e >= s )); then
            occ+=("$s $e")
        fi
    done < <(part_regions "$disk")

    first=$(((first + ALIGN - 1) / ALIGN * ALIGN))
    last=$((last / ALIGN * ALIGN))

    local cur="$first" r
    for r in "${occ[@]}"; do
        [[ -n "$r" ]] || continue
        s="${r% *}"
        e="${r#* }"
        if (( s > cur )); then
            printf '%s %s\n' "$cur" $((s - 1))
        fi
        if (( e >= cur )); then
            cur=$((e + 1))
        fi
    done
    if (( last >= cur )); then
        printf '%s %s\n' "$cur" "$last"
    fi
    return 0
}

fmt_mib() {
    local mib="$1"
    if (( mib >= 1024 )); then
        awk -v m="$mib" 'BEGIN{printf "%.1f GiB", m/1024}'
    else
        printf '%s MiB' "$mib"
    fi
}

sectors_to_mib() {
    printf '%s\n' $((($1 * $2) / 1048576))
}

lsblk_val() {
    local v
    v="$(lsblk -nro "$1" "$2" 2>/dev/null | head -n1 || true)"
    printf '%s' "${v//\\x20/ }"
}

part_is_extended() {
    local t
    t="$(lsblk_val PARTTYPE "$1")"
    case "$t" in
        0x5|0x05|0x0f|0x0F|0x85|5|f|F|85) return 0 ;;
    esac
    case "$(lsblk_val PARTTYPENAME "$1")" in
        *[Ee]xtended*) return 0 ;;
    esac
    return 1
}

dev_is_mounted() {
    findmnt -rn -S "$1" >/dev/null 2>&1
}

gap_lage() {
    local disk="$1" gs="$2" ge="$3"
    local start size nr before="" after="" end
    while read -r start size nr; do
        [[ -n "$nr" ]] || continue
        end=$((start + size - 1))
        if (( end < gs )); then
            before="$nr"
        fi
        if [[ -z "$after" ]] && (( start > ge )); then
            after="$nr"
        fi
    done < <(part_regions "$disk")

    if [[ -n "$before" && -n "$after" ]]; then
        printf '%s' "$(t part_gap_between "$before" "$after")"
    elif [[ -n "$before" ]]; then
        printf '%s' "$(t part_gap_after "$before")"
    elif [[ -n "$after" ]]; then
        printf '%s' "$(t part_gap_before "$after")"
    else
        printf '%s' "$(t part_gap_empty)"
    fi
    return 0
}

# ============================================================
# Live-Medium erkennen (3-stufig)
# ============================================================

resolve_disk() {
    local dev="$1" real pk
    [[ -n "$dev" ]] || return 1
    case "$dev" in
        LABEL=*) real="$(blkid -L "${dev#LABEL=}" 2>/dev/null || true)" ;;
        UUID=*) real="$(blkid -U "${dev#UUID=}" 2>/dev/null || true)" ;;
        PARTUUID=*) real="$(blkid -t "$dev" -o device 2>/dev/null | head -n1 || true)" ;;
        *) real="$dev" ;;
    esac
    [[ -n "$real" ]] || return 1
    if [[ -e "$real" ]]; then
        real="$(readlink -f "$real" 2>/dev/null || true)"
        [[ -n "$real" ]] || return 1
    fi
    [[ -b "$real" ]] || return 1
    if [[ "$(lsblk -ndo TYPE "$real" 2>/dev/null)" == "disk" ]]; then
        printf '%s\n' "$real"
        return 0
    fi
    pk="$(lsblk -nro PKNAME "$real" 2>/dev/null | head -n1 || true)"
    [[ -n "$pk" ]] || return 1
    printf '/dev/%s\n' "$pk"
}

live_medium_from_bootmnt() {
    local src
    src="$(findmnt -nro SOURCE /cdrom 2>/dev/null || true)"
    if [[ -z "$src" ]]; then
        src="$(findmnt -nro SOURCE /run/live/medium 2>/dev/null || true)"
    fi
    [[ -n "$src" ]] || return 1
    resolve_disk "$src"
}

live_medium_from_squash() {
    local src back dev
    while read -r src; do
        [[ "$src" == /dev/loop* ]] || continue
        back="$(losetup -no BACK-FILE "$src" 2>/dev/null || true)"
        case "$back" in
            */filesystem.squashfs|*/casper/*.squashfs|*/live/*.squashfs) ;;
            *) continue ;;
        esac
        dev="$(findmnt -nro SOURCE -T "$back" 2>/dev/null || true)"
        [[ -n "$dev" ]] || continue
        if resolve_disk "$dev"; then
            return 0
        fi
    done < <(findmnt -rn -o SOURCE -t squashfs 2>/dev/null)
    return 1
}

live_medium_from_iso9660() {
    local dev dtype fstype pk
    while read -r dev dtype fstype; do
        [[ -n "$dev" ]] || continue
        [[ "$fstype" == "iso9660" ]] || continue
        if [[ "$dtype" == "disk" ]]; then
            printf '%s\n' "$dev"
            return 0
        fi
        pk="$(lsblk -nro PKNAME "$dev" 2>/dev/null | head -n1 || true)"
        if [[ -n "$pk" ]]; then
            printf '/dev/%s\n' "$pk"
        else
            printf '%s\n' "$dev"
        fi
        return 0
    done < <(lsblk -pnrno NAME,TYPE,FSTYPE 2>/dev/null)
    return 1
}

detect_live_medium() {
    local dev
    dev="$(live_medium_from_bootmnt || true)"
    if [[ -z "$dev" ]]; then dev="$(live_medium_from_squash || true)"; fi
    if [[ -z "$dev" ]]; then dev="$(live_medium_from_iso9660 || true)"; fi
    if [[ -n "$dev" ]]; then
        printf '%s\n' "$dev"
    fi
    return 0
}

# ============================================================
# Paket-Backend (apt/dpkg) + Formatieren
# ============================================================

ensure_tool() {
    local tool="$1" pkg="$2" kontext="${3:-Aktion}"
    if command -v "$tool" >/dev/null 2>&1; then
        return 0
    fi

    if [[ "$INTERACTIVE" == "j" ]]; then
        if ! confirm_yes "$(t q_tool_missing_install "$tool" "$pkg")"; then
            warn "$(t warn_ctx_aborted "$kontext" "$tool")"
            return 1
        fi
    fi

    misc "$(t info_installing_pkg "$pkg")"
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >/dev/null 2>&1; then
        misc "$(t info_retry_apt_update)"
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >/dev/null 2>&1; then
            err "$(t err_tool_install_failed "$tool" "$pkg")"
            return 1
        fi
    fi

    if command -v "$tool" >/dev/null 2>&1; then
        misc "$(t info_tool_now_available "$tool")"
        return 0
    fi
    err "$(t err_tool_install_failed_short "$tool" "$pkg")"
    return 1
}

pkg_missing() {
    local p st
    for p in "$@"; do
        st="$(dpkg-query -W -f="\${db:Status-Abbrev}" "$p" 2>/dev/null || true)"
        if [[ "$st" != ii* ]]; then
            printf '%s\n' "$p"
        fi
    done
}

# ---------- Eingebauter FAT32-Formatierer (Ersatz für mkfs.vfat) ----------

fat_le16() {
    printf '%b' \
        "\\x$(printf '%02x' $(( $1 & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 256) & 255 )))"
}

fat_le32() {
    printf '%b' \
        "\\x$(printf '%02x' $(( $1 & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 256) & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 65536) & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 16777216) & 255 )))"
}

mkfs_fat32_builtin() {
    local dev="$1" label="${2:-NO NAME}"
    local SS bytes total_sect sc fat_sz reserved=32 nfats=2
    local data_start clusters cluster_bytes

    SS="$(sector_size "$dev")"
    case "$SS" in
        512|1024|2048|4096) : ;;
        *)
            err "$(t err_fat32_sector_size "$SS")"
            return 1 ;;
    esac

    bytes="$(blockdev --getsize64 "$dev" 2>/dev/null)" || bytes=""
    if [[ ! "$bytes" =~ ^[0-9]+$ ]] || (( bytes == 0 )); then
        bytes="$(stat -c%s "$dev" 2>/dev/null)" || bytes=""
    fi
    if [[ ! "$bytes" =~ ^[0-9]+$ ]] || (( bytes == 0 )); then
        err "$(t err_fat32_size_unknown "$dev")"
        return 1
    fi
    total_sect=$((bytes / SS))
    if (( total_sect >= 4294967296 )); then
        err "$(t err_fat32_too_large "$bytes")"
        return 1
    fi

    if   (( bytes <= 272629760 ));   then cluster_bytes=$SS
    elif (( bytes <= 8589934592 ));  then cluster_bytes=4096
    elif (( bytes <= 17179869184 )); then cluster_bytes=8192
    elif (( bytes <= 34359738368 )); then cluster_bytes=16384
    elif (( bytes <= 549755813888 )); then cluster_bytes=32768
    else cluster_bytes=65536
    fi
    if (( cluster_bytes < SS )); then
        cluster_bytes=$SS
    fi
    sc=$((cluster_bytes / SS))
    if (( sc > 128 )); then
        err "$(t err_fat32_cluster_invalid "$SS")"
        return 1
    fi

    fat_sz=$(( (total_sect / sc) * 4 / SS + 2 ))
    local needed i
    for i in 1 2 3 4 5 6 7 8; do
        data_start=$(( reserved + fat_sz * nfats ))
        if (( data_start + sc > total_sect )); then
            err "$(t err_fat32_too_small)"
            return 1
        fi
        clusters=$(( (total_sect - data_start) / sc ))
        needed=$(( ( (clusters + 2) * 4 + SS - 1 ) / SS ))
        fat_sz=$needed
    done
    data_start=$(( reserved + fat_sz * nfats ))
    clusters=$(( (total_sect - data_start) / sc ))
    if (( clusters < 65525 )); then
        warn "$(t warn_fat32_few_clusters "$clusters")"
    fi
    if (( clusters > 268435446 )); then
        err "$(t err_fat32_many_clusters "$clusters")"
        return 1
    fi

    misc "$(t info_fat32_builtin "$cluster_bytes" "$clusters" "$((fat_sz * SS / 1024))")"

    if ! (
        tmpdir="$(mktemp -d)" || exit 1
        trap 'rm -rf "$tmpdir"' EXIT

        boot="$tmpdir/boot"
        {
            printf '\xeb\x3c\x90'
            printf 'UBUNTULIVE'
            fat_le16 "$SS"
            case "$sc" in
                1) printf '\x01' ;;
                2) printf '\x02' ;;
                4) printf '\x04' ;;
                8) printf '\x08' ;;
                16) printf '\x10' ;;
                32) printf '\x20' ;;
                64) printf '\x40' ;;
                128) printf '\x80' ;;
            esac
            fat_le16 32
            printf '\x02'
            fat_le16 0
            if (( total_sect < 65536 )); then
                fat_le16 "$total_sect"
            else
                fat_le16 0
            fi
            printf '\xf8'
            fat_le16 0
            fat_le16 63
            fat_le16 255
            fat_le32 0
            if (( total_sect >= 65536 )); then
                fat_le32 "$total_sect"
            else
                fat_le32 0
            fi
            fat_le32 "$fat_sz"
            fat_le16 0
            fat_le16 0
            fat_le32 2
            fat_le16 1
            fat_le16 6
            dd if=/dev/zero bs=1 count=12 2>/dev/null
            printf '\x80\x00\x29'
            head -c 4 /dev/urandom
            printf '%-11.11s' "$label"
            printf 'FAT32   '
            dd if=/dev/zero bs=1 count=420 2>/dev/null
            printf '\x55\xaa'
        } > "$boot"
        [[ "$(stat -c%s "$boot")" -eq 512 ]] || exit 1

        fsinfo="$tmpdir/fsinfo"
        {
            printf '\x52\x52\x61\x41'
            dd if=/dev/zero bs=1 count=480 2>/dev/null
            printf '\x72\x72\x41\x61'
            fat_le32 $((clusters - 1))
            fat_le32 3
            dd if=/dev/zero bs=1 count=14 2>/dev/null
            printf '\x55\xaa'
        } > "$fsinfo"
        [[ "$(stat -c%s "$fsinfo")" -eq 512 ]] || exit 1

        fat="$tmpdir/fat"
        printf '\xf8\xff\xff\x0f\xff\xff\xff\x0f\xff\xff\xff\x0f' > "$fat" || exit 1
        truncate -s $((fat_sz * SS)) "$fat" || exit 1
        dd if="$boot" of="$dev" bs="$SS" seek=0 conv=notrunc 2>/dev/null || exit 1
        dd if="$fsinfo" of="$dev" bs="$SS" seek=1 conv=notrunc 2>/dev/null || exit 1
        dd if="$boot" of="$dev" bs="$SS" seek=6 conv=notrunc 2>/dev/null || exit 1
        dd if="$fsinfo" of="$dev" bs="$SS" seek=7 conv=notrunc 2>/dev/null || exit 1
        dd if="$fat" of="$dev" bs="$SS" seek=$reserved conv=notrunc 2>/dev/null || exit 1
        dd if="$fat" of="$dev" bs="$SS" seek=$((reserved + fat_sz)) conv=notrunc 2>/dev/null || exit 1
        if [[ "$label" != "NO NAME" ]]; then
            rootfile="$tmpdir/root"
            {
                printf '%-11.11s' "$label"
                printf '\x08'
                dd if=/dev/zero bs=1 count=$((SS - 12)) 2>/dev/null
            } > "$rootfile"
            [[ "$(stat -c%s "$rootfile")" -eq "$SS" ]] || exit 1
            dd if="$rootfile" of="$dev" bs="$SS" seek=$data_start count=1 conv=notrunc 2>/dev/null || exit 1
            if (( sc > 1 )); then
                dd if=/dev/zero of="$dev" bs="$SS" seek=$((data_start + 1)) count=$((sc - 1)) conv=notrunc 2>/dev/null || exit 1
            fi
        else
            dd if=/dev/zero of="$dev" bs="$SS" seek=$data_start count=$sc conv=notrunc 2>/dev/null || exit 1
        fi
    ); then
        err "$(t err_fat32_create_failed "$dev")"
        return 1
    fi

    sync
    return 0
}

make_fs() {
    local dev="$1" fs="$2"
    local -a mkfs_cmd=()

    if dev_is_mounted "$dev"; then
        err "$(t err_dev_mounted_unplug "$(fstr "$dev")")"
        return 1
    fi

    wipefs -a "$dev" >/dev/null 2>&1 || true

    case "$fs" in
        ext4)
            if ! command -v mkfs.ext4 >/dev/null 2>&1; then
                err "$(t err_mkfs_ext4_missing)"
                return 1
            fi
            mkfs_cmd=(mkfs.ext4 -q -F "$dev") ;;
        vfat)
            if command -v mkfs.vfat >/dev/null 2>&1; then
                mkfs_cmd=(mkfs.vfat -F32 "$dev")
            elif command -v mkfs.fat >/dev/null 2>&1; then
                mkfs_cmd=(mkfs.fat -F32 "$dev")
            else
                if mkfs_fat32_builtin "$dev"; then
                    misc "$(t info_fs_vfat_builtin "$(fstr "$dev")")"
                    return 0
                fi
                err "$(t err_format_fat32_failed "$dev")"
                return 1
            fi ;;
        swap)
            if ! command -v mkswap >/dev/null 2>&1; then
                err "$(t err_mkswap_missing)"
                return 1
            fi
            mkfs_cmd=(mkswap "$dev") ;;
        ntfs)
            if ! command -v mkfs.ntfs >/dev/null 2>&1; then
                err "$(t err_mkfs_ntfs_missing)"
                return 1
            fi
            mkfs_cmd=(mkfs.ntfs -f "$dev") ;;
        *) return 1 ;;
    esac

    misc "$(t info_formatting "$(fstr "$dev")" "$fs")"
    if "${mkfs_cmd[@]}" >/dev/null 2>&1; then
        misc "$(t info_fs_created "$fs" "$(fstr "$dev")")"
        return 0
    fi
    err "$(t err_format_failed "$dev" "$fs")"
    return 1
}

# casper_live_cleanup - entfernt casper-Reste der Live-Sitzung aus einem
# Systembaum ($1 = Wurzel, z. B. /mnt oder "$MERGED"). Struktur-Garantie
# (Änderung 41): Autologin-Konfiguration wird KOMPLETT entfernt (sddm inkl.
# conf.d, lightdm, gdm3) - ein frisch installiertes System startet immer
# mit dem Login-Bildschirm, ganz gleich welche casper-Version welche
# [Autologin]-Blöcke (Live-Benutzer-Phantom, eigene Blöcke) hinterlassen
# hat; genau wie bei einer normalen Ubuntu-Installation. Das Live-System
# selbst setzt sein Autologin bei jedem Boot neu (casper 15autologin) -
# die Bereinigung stoert die Live-Sitzung nicht. Dazu: der Live-Benutzer
# (leeres Passwort, passwortloses sudo via /etc/sudoers.d/casper) wird
# entfernt und die casper-Diverts (update-initramfs-Stub, anacron) werden
# rueckgebaut, damit Initramfs-Bau und Kernel-Updates funktionieren.
casper_live_cleanup() {
    local root="$1"
    [[ -n "$root" && "$root" != "/" && -d "$root/etc" && -f "$root/etc/passwd" ]] || return 0

    # Live-Benutzer erkennen: GECOS "Live session user" (casper setz den
    # Namen zur Bootzeit je nach Flavour, der GECOS bleibt konstant)
    local live_user=""
    live_user="$(awk -F: '$5 == "Live session user" { print $1; exit }' \
        "$root/etc/passwd" 2>/dev/null || true)"
    if [[ -z "$live_user" && -f "$root/etc/casper.conf" ]]; then
        local conf_user
        conf_user="$(sed -n 's/^export USERNAME="\([^"]*\)"$/\1/p' \
            "$root/etc/casper.conf" 2>/dev/null | head -n1 || true)"
        if [[ -n "$conf_user" ]] && grep -qs "^${conf_user}:" "$root/etc/passwd"; then
            live_user="$conf_user"
        fi
    fi

    local tmp
    tmp="$(mktemp /tmp/ultool-cln-XXXXXX)"

    # sddm: /etc/sddm.conf UND alle Drop-ins in /etc/sddm.conf.d/ - ALLE
    # [Autologin]-Abschnitte kommen weg, ohne Rücksicht auf den Inhalt.
    # Begründung (Struktur-Garantie, siehe Änderung 41): SDDM merged alle
    # Dateien/Abschnitte, der LETZTE Block gewinnt - ein einziger
    # überlebender oder später geschriebener Block (Live-Benutzer-Phantom
    # von irgendeiner casper-Version) macht das System unbenutzbar. Eine
    # frische Installation zeigt deshalb IMMER den Login-Bildschirm, wie
    # bei einer normalen Ubuntu-Installation; Autologin kann der Benutzer
    # danach selbst wieder aktivieren. [Users] nur ganz entfernen, wenn
    # er nur aus MinimumUid=999 (casper-Fingerabdruck) besteht.
    local sddm_file
    for sddm_file in "$root/etc/sddm.conf" "$root"/etc/sddm.conf.d/*.conf; do
        [[ -f "$sddm_file" ]] || continue
        if awk '
            function flush() { if (!drop && buf != "") printf "%s", buf; buf = "" }
            /^\[/ {
                flush()
                if ($0 == "[Autologin]") { drop = 1; kind = "auto" }
                else if ($0 == "[Users]") { drop = 1; kind = "users" }
                else { drop = 0; kind = "" }
                buf = $0 "\n"
                next
            }
            {
                buf = buf $0 "\n"
                if (kind == "users" && $0 !~ /^[[:space:]]*$/ && $0 !~ /^MinimumUid=999$/) {
                    drop = 0
                }
            }
            END { flush() }
        ' "$sddm_file" > "$tmp"; then
            if ! cmp -s "$tmp" "$sddm_file"; then
                cat "$tmp" > "$sddm_file"
                misc "$(t info_remove_autologin)"
            fi
        fi
    done

    # lightdm: alle Autologin-Zeilen weg (gleiche Struktur-Garantie)
    local ldm
    for ldm in "$root/etc/lightdm/lightdm.conf" "$root"/etc/lightdm/lightdm.conf.d/*.conf; do
        [[ -f "$ldm" ]] || continue
        if grep -qs '^autologin-user=' "$ldm"; then
            grep -vE '^autologin-user=|^autologin-user-timeout=|^autologin-guest=|^autologin-session=' \
                "$ldm" > "$tmp" || true
            cat "$tmp" > "$ldm"
            misc "$(t info_remove_autologin)"
        fi
    done

    # gdm3: AutomaticLogin-Zeilen auskommentieren (gleiche Struktur-Garantie)
    local gdm
    gdm="$root/etc/gdm3/custom.conf"
    if [[ -f "$gdm" ]] && grep -qs '^AutomaticLogin' "$gdm"; then
        sed -e 's/^AutomaticLoginEnable=true$/#AutomaticLoginEnable=true/' \
            -e 's/^AutomaticLogin=/#AutomaticLogin=/' "$gdm" > "$tmp" || true
        cat "$tmp" > "$gdm"
        misc "$(t info_remove_autologin)"
    fi

    if [[ -n "$live_user" ]]; then
        local acct
        for acct in passwd shadow group gshadow; do
            [[ -f "$root/etc/$acct" ]] || continue
            grep -v "^${live_user}:" "$root/etc/$acct" > "$tmp" || true
            if ! cmp -s "$tmp" "$root/etc/$acct"; then
                cat "$tmp" > "$root/etc/$acct"
            fi
        done
        rm -f -- "$root/etc/sudoers.d/casper" "$root/var/mail/$live_user" \
            "$root/var/spool/mail/$live_user" 2>/dev/null || true
        if [[ -d "$root/home/$live_user" ]]; then
            rm -rf -- "${root:?}/home/${live_user:?}"
        fi
        misc "$(t info_remove_live_user "$live_user")"
    fi

    # Diverts rueckbauen, die casper zur Live-Boot-Zeit anlegt
    # (43disable_updateinitramfs / 25configure_init): ohne Rueckbau ist
    # update-initramfs auf dem Zielsystem ein Stub (kein Initramfs-Bau,
    # Kernel-Updates ins Leere) und anacron tot.
    if [[ -e "$root/usr/sbin/update-initramfs.distrib" ]] \
        && { [[ -L "$root/usr/sbin/update-initramfs" ]] \
            || grep -qs "update-initramfs is disabled" "$root/usr/sbin/update-initramfs" 2>/dev/null; }; then
        misc "$(t info_remove_casper_divert_initrd)"
        chroot "$root" dpkg-divert --remove --rename --quiet /usr/sbin/update-initramfs 2>/dev/null \
            || mv -f "$root/usr/sbin/update-initramfs.distrib" "$root/usr/sbin/update-initramfs"
    fi
    if [[ -L "$root/usr/sbin/anacron" && -e "$root/usr/sbin/anacron.distrib" ]] \
        && [[ "$(readlink "$root/usr/sbin/anacron" 2>/dev/null)" == "/bin/true" ]]; then
        misc "$(t info_remove_casper_divert_anacron)"
        chroot "$root" dpkg-divert --remove --rename --quiet /usr/sbin/anacron 2>/dev/null \
            || mv -f "$root/usr/sbin/anacron.distrib" "$root/usr/sbin/anacron"
    fi

    rm -f -- "$tmp"
    return 0
}

run_action() {
    local status=0
    (
        USER_ABORTED="n"
        rc=0
        "$@" || rc=$?
        if [[ "$USER_ABORTED" == "j" ]]; then
            exit 4
        fi
        exit "$rc"
    ) || status=$?
    if [[ "$status" -eq 4 ]]; then
        return 0
    fi
    if [[ "$status" -eq 42 ]]; then
        # 00-Signal: gesamtes Skript SOFORT beenden
        exit 42
    fi
    if [[ "$status" -ne 0 ]]; then
        err "$(t err_action_failed)"
    fi
    pause_key
}

#@@ENDBLOCK:COMMON

#@@BLOCK:PART
# ============================================================
# Partitionierer (interaktiv, Zahlen-Auswahl)
# ============================================================

PART_DISK=""

part_overview() {
    local disk="$PART_DISK"
    local SECTOR table fstype label tname mntp mib start size nr dev

    SECTOR="$(sector_size "$disk")"
    table="$(disk_table "$disk")"

    head_msg "$(t part_overview_title "$disk")"
    if [[ -z "$table" ]]; then
        err "$(t err_part_no_table "$disk")"
        misc "$(t info_part_use_menu2)"
        return 0
    fi
    misc "$(t part_table_info "$(fstr "$table")" "$SECTOR")"

    while read -r start size nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        mib="$(sectors_to_mib "$size" "$SECTOR")"
        fstype="$(lsblk_val FSTYPE "$dev")"
        label="$(lsblk_val LABEL "$dev")"
        tname="$(lsblk_val PARTTYPENAME "$dev")"
        mntp="$(findmnt -nro TARGET -S "$dev" 2>/dev/null | head -n1 || true)"
        txt "  $nr) $(fstr "$dev")  $(fmt_mib "$mib")  ${fstype:-raw}  ${tname:-$(t word_unknown)}${label:+ ($(t word_label): $label)}${mntp:+ [$(t word_mounted): $mntp]}"
    done < <(part_regions "$disk")

    misc "$(t part_free_areas)"
    local gcount=0 gs ge gmib
    while read -r gs ge; do
        [[ -n "$gs" ]] || continue
        gcount=$((gcount + 1))
        gmib="$(sectors_to_mib $((ge - gs + 1)) "$SECTOR")"
        misc "$(t part_gap_line "$(fmt_mib "$gmib")" "$(gap_lage "$disk" "$gs" "$ge")")"
    done < <(compute_gaps "$disk" || true)
    if (( gcount == 0 )); then
        misc "$(t part_none)"
    fi
    return 0
}

part_reread() {
    local disk="$PART_DISK"
    udevadm settle 2>/dev/null || true
    blockdev --rereadpt "$disk" 2>/dev/null || true
    partprobe "$disk" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
}

part_newtable() {
    local disk="$PART_DISK"
    head_msg "$(t part_newtable_title "$disk")"

    if ! menu_select "$(t part_choose_table)" \
        "$(t part_table_gpt)" \
        "$(t part_table_mbr)"; then
        return 0
    fi
    local kind="$MENU_NR"

    err "$(t warn_part_newtable_wipe "$(fstr "$disk")")"
    confirm_ja_nein || { misc "$(t info_nothing_changed)"; return 0; }

    misc "$(t part_wiping_disk)"
    wipefs --all --force "$disk" >/dev/null 2>&1 || true

    local sfd_out=""
    case "$kind" in
        1)
            misc "$(t part_creating_gpt)"
            if ! sfd_out="$(printf 'label: gpt\n' | sfdisk --force --no-reread --no-tell-kernel "$disk" 2>&1)"; then
                err "$(t err_gpt_failed)"
                printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
                return 1
            fi ;;
        2)
            misc "$(t part_creating_mbr)"
            if ! sfd_out="$(printf 'label: dos\n' | sfdisk --force --no-reread --no-tell-kernel "$disk" 2>&1)"; then
                err "$(t err_mbr_failed)"
                printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
                return 1
            fi ;;
    esac

    part_reread

    misc "$(t part_table_done)"
    part_overview
}

parse_size_sectors() {
    local s="$1" ALIGN="$2" SECTOR="$3" unit="" num mult
    while [[ -n "$s" ]]; do
        case "${s: -1}" in
            [0-9.,]) break ;;
            *) unit="${s: -1}$unit"; s="${s%?}" ;;
        esac
    done
    if [[ -z "$s" || "$s" == *[!0-9.,]* ]]; then
        return 1
    fi
    num="${s//,/.}"
    case "$unit" in
        ''|M|m|Mi|MiB|mi|mb) mult=1 ;;
        G|g|Gi|GiB|gi|gib) mult=1024 ;;
        T|t|Ti|TiB|ti|tib) mult=1048576 ;;
        K|k|Ki|KiB) mult=0.0009765625 ;;
        *) return 1 ;;
    esac
    local mib sect
    mib="$(awk -v n="$num" -v m="$mult" 'BEGIN{printf "%.3f", n*m}')"
    sect="$(awk -v m="$mib" -v sec="$SECTOR" 'BEGIN{printf "%d", int(m*1048576/sec)}')"
    [[ "$sect" =~ ^[0-9]+$ ]] || return 1
    sect=$((sect / ALIGN * ALIGN))
    if (( sect < ALIGN )); then
        return 1
    fi
    SIZE_SECTORS="$sect"
    return 0
}

part_create() {
    local disk="$PART_DISK"
    head_msg "$(t part_create_title "$disk")"

    local table
    table="$(disk_table "$disk")"
    if [[ -z "$table" ]]; then
        err "$(t err_part_no_table_first)"
        return 1
    fi

    local SECTOR ALIGN
    SECTOR="$(sector_size "$disk")"
    ALIGN=$((1048576 / SECTOR))

    local -a purposes=() pids=()
    purposes+=("$(t part_purpose_linux)"); pids+=(1)
    if [[ "$table" == "gpt" ]]; then
        purposes+=("$(t part_purpose_esp)"); pids+=(2)
    fi
    if [[ "$table" != "gpt" ]]; then
        purposes+=("$(t part_purpose_extended)"); pids+=(3)
    fi
    purposes+=("$(t part_purpose_swap)"); pids+=(4)
    purposes+=("$(t part_purpose_ntfs)"); pids+=(5)
    purposes+=("$(t part_purpose_fat32)"); pids+=(6)
    purposes+=("$(t part_purpose_raw)"); pids+=(7)

    menu_select "$(t part_choose_purpose)" "${purposes[@]}" || return 0
    local purpose="${pids[MENU_NR - 1]}"

    local -a gapstarts=() gapends=()
    local gs ge
    while read -r gs ge; do
        [[ -n "$gs" ]] || continue
        gapstarts+=("$gs")
        gapends+=("$ge")
    done < <(compute_gaps "$disk" || true)

    if [[ "${#gapstarts[@]}" -eq 0 ]]; then
        err "$(t err_part_no_free "$disk")"
        return 1
    fi

    local gsel=0 gsize=$((gapends[0] - gapstarts[0]))
    local idx
    for idx in "${!gapstarts[@]}"; do
        if (( gapends[idx] - gapstarts[idx] > gsize )); then
            gsel="$idx"
            gsize=$((gapends[idx] - gapstarts[idx]))
        fi
    done
    if [[ "${#gapstarts[@]}" -gt 1 ]]; then
        warn "$(t warn_part_multi_gaps)"
    fi
    local gstart="${gapstarts[$gsel]}" gend="${gapends[$gsel]}"
    local gmib
    gmib="$(sectors_to_mib $((gend - gstart + 1)) "$SECTOR")"
    misc "$(t part_gap_auto "$(fmt_mib "$gmib")" "$(gap_lage "$disk" "$gstart" "$gend")")"

    local def_mib="" ptype="" fs=""
    case "$purpose" in
        1)
            if [[ "$table" == "gpt" ]]; then ptype="0FC63DAF-8483-4772-8E79-3D69D8477DE4"; else ptype="83"; fi
            fs="ext4" ;;
        2)
            if [[ "$table" == "gpt" ]]; then ptype="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"; else ptype="ef"; fi
            def_mib="512" fs="vfat" ;;
        3)
            ptype="5" ;;
        4)
            if [[ "$table" == "gpt" ]]; then ptype="0657FD6D-A4AB-43C4-84E5-0933C84B4F4F"; else ptype="82"; fi
            fs="swap" ;;
        5)
            if [[ "$table" == "gpt" ]]; then ptype="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"; else ptype="07"; fi
            fs="ntfs" ;;
        6)
            if [[ "$table" == "gpt" ]]; then ptype="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"; else ptype="0c"; fi
            fs="vfat" ;;
        7)
            if [[ "$table" == "gpt" ]]; then ptype="0FC63DAF-8483-4772-8E79-3D69D8477DE4"; else ptype="83"; fi
            fs="" ;;
    esac

    local max_sect=$((gend - gstart + 1))
    local usable_sect=$(((max_sect - ALIGN) / ALIGN * ALIGN))
    if (( usable_sect < ALIGN )); then
        err "$(t err_part_gap_too_small)"
        return 1
    fi
    local max_mib
    max_mib="$(sectors_to_mib "$usable_sect" "$SECTOR")"
    local size_input="" sect
    while :; do
        ask_string "$(t part_q_size "$(fmt_mib "$max_mib")")" "$def_mib" || return 0
        size_input="$ANSWER"
        if [[ -z "$size_input" ]]; then
            sect="$usable_sect"
            break
        fi
        if parse_size_sectors "$size_input" "$ALIGN" "$SECTOR"; then
            sect="$SIZE_SECTORS"
            break
        fi
        misc "$(t part_q_size_invalid)"
    done
    if (( sect > usable_sect )); then
        err "$(t err_part_size_no_fit "$(fmt_mib "$max_mib")")"
        return 1
    fi

    local start="$gstart"

    local sfd_line="start=$start, size=$sect, type=$ptype"
    if [[ "$table" != "gpt" && "$ptype" != "5" ]]; then
        local nprim=0 has_ext="n" nr
        while read -r nr; do
            [[ -n "$nr" ]] || continue
            if (( nr <= 4 )); then
                nprim=$((nprim + 1))
                if part_is_extended "$(part_prefix "$disk")$nr"; then has_ext="j"; fi
            fi
        done < <(part_nrs "$disk")
        if (( nprim >= 4 )) && [[ "$has_ext" != "j" ]]; then
            err "$(t err_part_mbr_slots_full)"
            return 1
        fi
    fi

    local nrs_before new_nr="" new_dev
    nrs_before="$(part_nrs "$disk")"

    misc "$(t part_creating_line "$sfd_line")"
    local sfd_out=""
    if ! sfd_out="$(printf '%s\n' "$sfd_line" | sfdisk --force --no-reread --no-tell-kernel --append "$disk" 2>&1)"; then
        part_reread
        if [[ -z "$(comm -13 <(printf '%s\n' "$nrs_before") <(part_nrs "$disk") || true)" ]]; then
            err "$(t err_part_create_failed)"
            printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
            return 1
        fi
        warn "$(t warn_part_created_anyway)"
        printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
    fi
    part_reread

    local new_list nr
    new_list="$(comm -13 <(printf '%s\n' "$nrs_before") <(part_nrs "$disk") || true)"
    while read -r nr; do
        new_nr="$nr"
    done <<< "$new_list"
    if [[ -z "$new_nr" ]]; then
        while read -r nr; do
            new_nr="$nr"
        done < <(part_nrs "$disk")
    fi
    if [[ -z "$new_nr" ]]; then
        err "$(t err_part_no_new_nr)"
        return 1
    fi
    new_dev="$(part_prefix "$disk")$new_nr"

    local i
    for i in {1..20}; do
        if [[ -b "$new_dev" ]]; then break; fi
        sleep 1
        part_reread
    done
    if [[ ! -b "$new_dev" ]]; then
        warn "$(t warn_part_dev_not_yet "$(fstr "$new_dev")")"
    fi

    misc "$(t part_created "$(fstr "$new_dev")")"

    # Alte Dateisystem-Reste der vorherigen Partitionierung entfernen - sonst
    # zeigt blkid/lsblk das alte FS an und find_esp_on_disk überspringt eine
    # frische ESP, deren Blöcke noch eine alte ext4-Signatur tragen
    wipefs --all --force "$new_dev" >/dev/null 2>&1 || true

    if [[ -n "$fs" ]]; then
        if confirm_yes "$(t q_format_now "$fs")"; then
            make_fs "$new_dev" "$fs"
        fi
    fi

    part_overview
}

part_delete() {
    local disk="$PART_DISK"
    head_msg "$(t part_delete_title "$disk")"

    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_no_partitions)"
        return 0
    fi

    local -a opts=() nrsel=()
    local nr dev mib SECTOR fstype sz
    SECTOR="$(sector_size "$disk")"
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        if dev_is_mounted "$dev"; then
            opts+=("$dev  ($(t word_mounted_protected))")
        else
            sz="$(part_regions "$disk" | awk -v n="$nr" '$3 == n {print $2; exit}')"
            [[ "$sz" =~ ^[0-9]+$ ]] || sz=0
            mib="$(sectors_to_mib "$sz" "$SECTOR")"
            fstype="$(lsblk_val FSTYPE "$dev")"
            opts+=("$dev  $(fmt_mib "$mib")  ${fstype:-raw}")
        fi
        nrsel+=("$nr")
    done <<< "$nrs"

    menu_select "$(t part_choose_delete)" "${opts[@]}" || return 0
    local sel_nr="${nrsel[$((MENU_NR - 1))]}"
    local sel_dev
    sel_dev="$(part_prefix "$disk")$sel_nr"

    if dev_is_mounted "$sel_dev"; then
        err "$(t err_part_mounted_nodelete "$(fstr "$sel_dev")")"
        return 1
    fi

    err "$(t warn_part_delete_wipe "$(fstr "$sel_dev")")"
    confirm_ja_nein || { misc "$(t info_aborted)"; return 0; }

    if sfdisk --force --no-reread --no-tell-kernel --delete "$disk" "$sel_nr" >/dev/null 2>&1; then
        part_reread
        misc "$(t part_deleted)"
    else
        err "$(t err_part_delete_failed)"
    fi
    part_overview
}

part_format() {
    local disk="$PART_DISK"
    head_msg "$(t part_format_title "$disk")"

    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_no_partitions)"
        return 0
    fi

    local -a opts=() devs=()
    local nr dev fstype
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        if part_is_extended "$dev"; then continue; fi
        fstype="$(lsblk_val FSTYPE "$dev")"
        opts+=("$dev  ${fstype:-raw}")
        devs+=("$dev")
    done <<< "$nrs"
    if [[ "${#devs[@]}" -eq 0 ]]; then
        misc "$(t part_no_formattable)"
        return 0
    fi

    menu_select "$(t part_choose_format)" "${opts[@]}" || return 0
    dev="${devs[$((MENU_NR - 1))]}"

    if dev_is_mounted "$dev"; then
        err "$(t err_dev_mounted "$(fstr "$dev")")"
        return 1
    fi

    menu_select "$(t part_choose_fs)" "ext4" "FAT32" "swap" "NTFS" || return 0
    local fs
    case "$MENU_NR" in
        1) fs="ext4" ;;
        2) fs="vfat" ;;
        3) fs="swap" ;;
        4) fs="ntfs" ;;
    esac

    err "$(t warn_part_format_wipe "$(fstr "$dev")" "$fs")"
    confirm_ja_nein || { misc "$(t info_aborted)"; return 0; }

    make_fs "$dev" "$fs"
    part_overview
}

part_settype() {
    local disk="$PART_DISK"
    head_msg "$(t part_settype_title "$disk")"

    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_no_partitions)"
        return 0
    fi

    local -a opts=() devs=()
    local nr dev type tname nr_new
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        tname="$(lsblk_val PARTTYPENAME "$dev")"
        opts+=("$dev  $(t word_current): ${tname:-$(t word_unknown)}")
        devs+=("$dev")
    done <<< "$nrs"

    menu_select "$(t part_choose_partition)" "${opts[@]}" || return 0
    dev="${devs[$((MENU_NR - 1))]}"
    nr_new="$(lsblk -nro PARTN "$dev" 2>/dev/null || true)"
    if [[ -z "$nr_new" ]]; then
        nr_new="${dev##*[a-z]}"
    fi

    if disk_is_gpt "$disk"; then
        menu_select "$(t part_newtype_gpt)" \
            "$(t part_type_esp)" \
            "$(t part_type_biosboot)" \
            "$(t part_type_linux)" \
            "$(t part_type_linux_swap)" \
            "$(t part_type_msft)" \
            "$(t part_type_lvm)" || return 0
        case "$MENU_NR" in
            1) type="C12A7328-F81F-11D2-BA4B-00A0C93EC93B" ;;
            2) type="21686148-6449-6E6F-744E-656564454649" ;;
            3) type="0FC63DAF-8483-4772-8E79-3D69D8477DE4" ;;
            4) type="0657FD6D-A4AB-43C4-84E5-0933C84B4F4F" ;;
            5) type="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" ;;
            6) type="E6D6D379-F507-44C2-A23C-238F2A3DF928" ;;
        esac
    else
        menu_select "$(t part_newtype_mbr)" \
            "$(t part_type_linux83)" \
            "$(t part_type_efi_ef)" \
            "$(t part_type_fat32lba)" \
            "$(t part_type_swap82)" \
            "$(t part_type_ntfs07)" \
            "$(t part_type_ext05)" || return 0
        case "$MENU_NR" in
            1) type="83" ;;
            2) type="ef" ;;
            3) type="0c" ;;
            4) type="82" ;;
            5) type="07" ;;
            6) type="05" ;;
        esac
    fi

    if sfdisk --force --no-reread --no-tell-kernel --part-type "$disk" "$nr_new" "$type" >/dev/null 2>&1; then
        part_reread
        misc "$(t part_type_set "$(fstr "$type")" "$(fstr "$dev")")"
    else
        err "$(t err_part_type_failed)"
    fi
    part_overview
}

part_bootflag() {
    local disk="$PART_DISK"
    if disk_is_gpt "$disk"; then
        err "$(t err_part_bootflag_gpt)"
        return 1
    fi

    head_msg "$(t part_bootflag_title "$disk")"
    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_no_partitions)"
        return 0
    fi

    local -a opts=() nrsel=()
    local nr dev
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        opts+=("$dev")
        nrsel+=("$nr")
    done <<< "$nrs"

    menu_select "$(t part_choose_bootflag)" "${opts[@]}" || return 0
    local nr_sel="${nrsel[$((MENU_NR - 1))]}"

    if sfdisk --force --no-reread --no-tell-kernel --activate "$disk" "$nr_sel" >/dev/null 2>&1; then
        part_reread
        misc "$(t part_bootflag_set "$(fstr "$(part_prefix "$disk")$nr_sel")")"
    else
        err "$(t err_part_bootflag_failed)"
    fi
    part_overview
}

part_check_tools() {
    local -a need=(sfdisk:fdisk wipefs:util-linux lsblk:util-linux
        findmnt:util-linux blockdev:util-linux udevadm:udev)
    local -a missing=()
    local entry cmd pkg list=""

    for entry in "${need[@]}"; do
        cmd="${entry%%:*}"
        pkg="${entry#*:}"
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$entry")
            list+="$cmd (Paket $pkg) "
        fi
    done
    if [[ "${#missing[@]}" -eq 0 ]]; then
        return 0
    fi

    err "$(t err_part_missing_tools "$list")"
    for entry in "${missing[@]}"; do
        if ! ensure_tool "${entry%%:*}" "${entry#*:}" "$(t word_partitioner)"; then
            die "$(t err_part_needs "$list")"
        fi
    done
    return 0
}

part_menu() {
    head_msg "$(t part_menu_disk_title)"

    part_check_tools

    local live_dev
    live_dev="$(detect_live_medium || true)"

    local -a disks=() dopts=()
    local d size model table
    while read -r d size model; do
        [[ -n "$d" ]] || continue
        if [[ -n "$live_dev" && "$d" == "$live_dev" ]]; then continue; fi
        case "${d##*/}" in
            loop*|zram*|ram*|sr*|fd*|dm-*|md*) continue ;;
        esac
        disks+=("$d")
        table="$(disk_table "$d")"
        dopts+=("$d  $size  ${model:-}  (${table:-$(t word_no_table)})")
    done < <(lsblk -dpnro NAME,SIZE,MODEL 2>/dev/null)

    if [[ "${#disks[@]}" -eq 0 ]]; then
        err "$(t err_part_no_disk)"
        return 1
    fi

    menu_select "$(t part_choose_disk)" "${dopts[@]}" || return 0
    PART_DISK="${disks[$((MENU_NR - 1))]}"

    if [[ -n "$live_dev" ]]; then
        warn "$(t warn_part_live_excluded "$(fstr "$live_dev")")"
    fi

    while :; do
        if menu_select "$(t part_menu_title "$PART_DISK")" \
            "$(t part_menu_overview)" \
            "$(t part_menu_newtable)" \
            "$(t part_menu_create)" \
            "$(t part_menu_delete)" \
            "$(t part_menu_format)" \
            "$(t part_menu_settype)" \
            "$(t part_menu_bootflag)"; then
            case "$MENU_NR" in
                1) part_overview ;;
                2) part_newtable ;;
                3) part_create ;;
                4) part_delete ;;
                5) part_format ;;
                6) part_settype ;;
                7) part_bootflag ;;
            esac
        else
            return 0
        fi
    done
}

#@@ENDBLOCK:PART

#@@BLOCK:INSTALL
# ============================================================
# Installer (installiert das gebootete Live-System)
# ============================================================

DISK=""
ASSUME_YES="n"

root_overlay_lowerdirs() {
    local opts
    opts="$(findmnt -nro OPTIONS / 2>/dev/null || true)"
    if [[ -z "$opts" ]]; then
        return 1
    fi
    printf '%s\n' "$opts" | tr ',' '\n' | sed -n 's/^lowerdir=//p' | tr ':' '\n'
}

squash_from_overlay() {
    local mnt src back
    while IFS= read -r mnt; do
        [[ -n "$mnt" ]] || continue
        case "$mnt" in /*) ;; *) continue ;; esac
        [[ -d "$mnt" ]] || continue
        src="$(findmnt -no SOURCE --target "$mnt" 2>/dev/null || true)"
        [[ -n "$src" ]] || continue
        case "$src" in
            /dev/loop*) back="$(losetup -no BACK-FILE "$src" 2>/dev/null || true)" ;;
            *) back="$src" ;;
        esac
        if [[ -n "$back" && -f "$back" ]]; then
            printf '%s\n' "$back"
            return 0
        fi
    done < <(root_overlay_lowerdirs)
    return 1
}

find_esp_on_disk() {
    local disk="$1" line dev ptype fstype
    while IFS= read -r line; do
        [[ "$line" == *" : start="* ]] || continue
        dev="${line%% :*}"
        ptype="$(printf '%s\n' "$line" | sed -n 's/.*[ ,]type=\([^,]*\).*/\1/p' | tr '[:lower:]' '[:upper:]')"
        case "$ptype" in
            C12A7328-F81F-11D2-BA4B-00A0C93EC93B|EF|0XEF) ;;
            *) continue ;;
        esac
        [[ -b "$dev" ]] || continue
        fstype="$(lsblk -nro FSTYPE "$dev" 2>/dev/null | head -n1 || true)"
        if [[ -n "$fstype" && "$fstype" != "vfat" ]]; then
            continue
        fi
        printf '%s\n' "$dev"
        return 0
    done < <(sfdisk_dump "$disk")
    return 1
}

build_install_targets() {
    TARGETS=()
    TARGET_DESCR=()

    local live_dev
    live_dev="$(detect_live_medium || true)"

    local d dsize model p psize pfstype ptname pk m
    while read -r d dsize model; do
        [[ -n "$d" ]] || continue
        model="${model//\\x20/ }"
        case "${d##*/}" in
            loop*|zram*|ram*|sr*|fd*|dm-*|md*) continue ;;
        esac
        if [[ -n "$live_dev" && "$d" == "$live_dev" ]]; then
            continue
        fi

        TARGETS+=("$d")
        TARGET_DESCR+=("$(fstr "$d") $(t inst_whole_disk) $dsize ${model:+($model)} $(t inst_will_repart)")

        while read -r p; do
            [[ -n "$p" ]] || continue
            pk="$(lsblk -nro PKNAME "$p" 2>/dev/null | head -n1 || true)"
            if [[ "/dev/$pk" != "$d" ]]; then continue; fi
            if part_is_extended "$p"; then
                TARGET_DESCR+=("  $(fstr "$p") $(t inst_extended_skipped)")
                TARGETS+=("")
                continue
            fi
            if [[ -n "$live_dev" ]]; then
                case "$p" in
                    "$live_dev"*) continue ;;
                esac
            fi
            psize="$(lsblk -nro SIZE "$p" 2>/dev/null | head -n1 || true)"
            pfstype="$(lsblk_val FSTYPE "$p")"
            ptname="$(lsblk_val PARTTYPENAME "$p")"
            m="$(findmnt -nro TARGET -S "$p" 2>/dev/null | head -n1 || true)"
            m="${m//\\x20/ }"
            TARGETS+=("$p")
            TARGET_DESCR+=("  $(fstr "$p") $(t inst_partition) $psize - ${pfstype:-$(t word_raw)} - ${ptname:--}${m:+ [$(t word_mounted): $m]}")
        done < <(lsblk -pnro NAME "$d" 2>/dev/null)
    done < <(lsblk -dpnro NAME,SIZE,MODEL 2>/dev/null)
    return 0
}

show_targets() {
    build_install_targets
    head_msg "$(t inst_targets_title)"
    local i n=0
    for i in "${!TARGETS[@]}"; do
        if [[ -n "${TARGETS[$i]}" ]]; then
            n=$((n + 1))
            misc "  $n  ${TARGET_DESCR[$i]}"
        else
            txt "     ${TARGET_DESCR[$i]}"
        fi
    done
    local live_dev
    live_dev="$(detect_live_medium || true)"
    if [[ -n "$live_dev" ]]; then
        txt "$(t inst_live_excluded "$(fstr "$live_dev")")"
    fi
    return 0
}

choose_install_target() {
    build_install_targets

    local -a devs=() descs=()
    local i
    for i in "${!TARGETS[@]}"; do
        if [[ -n "${TARGETS[$i]}" ]]; then
            devs+=("${TARGETS[$i]}")
            descs+=("${TARGET_DESCR[$i]}")
        fi
    done

    if [[ "${#descs[@]}" -eq 0 ]]; then
        err "$(t err_inst_no_targets)"
        return 1
    fi

    menu_select "$(t inst_choose_target)" "${descs[@]}" || return 1
    DISK="${devs[$((MENU_NR - 1))]}"
    return 0
}

do_install() {
    head_msg "$(t inst_title)"

    if [[ -z "$DISK" ]]; then
        usage_install
        exit 2
    fi

    if [[ ! -b "$DISK" ]]; then
        die "$(t err_inst_not_block "$DISK")"
    fi
    DISK="$(readlink -f "$DISK")"

    local disk_type
    disk_type="$(lsblk -ndo TYPE "$DISK" 2>/dev/null || true)"

    PART_MODE="no"
    INSTALL_DISK="$DISK"

    case "$disk_type" in
        disk)
            PART_MODE="no" ;;
        part)
            PART_MODE="yes"
            INSTALL_DISK="$(lsblk -npro PKNAME "$DISK" 2>/dev/null | head -n1 || true)"
            if [[ -z "$INSTALL_DISK" || ! -b "$INSTALL_DISK" ]]; then
                die "$(t err_inst_no_parent "$DISK")"
            fi
            case "$(lsblk -nro PARTTYPENAME "$DISK" 2>/dev/null || true)" in
                *[Ee]xtended*)
                    die "$(t err_inst_extended "$DISK")" ;;
            esac ;;
        *)
            die "$(t err_inst_neither "$DISK")" ;;
    esac

    case "${INSTALL_DISK##*/}" in
        loop*|zram*|ram*|sr*|fd*|dm-*|md*)
            die "$(t err_inst_unsuitable "$INSTALL_DISK")" ;;
    esac

    FIRMWARE="BIOS"
    if [[ -d /sys/firmware/efi ]]; then
        FIRMWARE="UEFI"
    fi
    txt "$(t inst_session_mode "$FIRMWARE" "$FIRMWARE")"
    if [[ "$FIRMWARE" == "UEFI" ]]; then
        misc "$(t inst_boot_bios)"
    else
        misc "$(t inst_boot_uefi)"
    fi

    ARCH="$(uname -m)"
    [[ "$ARCH" == "x86_64" ]] || die "$(t err_inst_arch "$ARCH")"

    if [[ ! -d /cdrom && ! -d /run/live ]]; then
        die "$(t err_inst_no_live_system)"
    fi

    SQUASH="$(squash_from_overlay || true)"
    if [[ -z "$SQUASH" ]]; then
        SQUASH="$(find /cdrom /run/live -maxdepth 6 -type f -name '*.squashfs' -print 2>/dev/null | head -n1 || true)"
    fi
    if [[ -z "$SQUASH" || ! -f "$SQUASH" ]]; then
        err "$(t err_inst_no_squash)"
        misc "$(t info_kernel_cmdline)"
        dump_misc cat /proc/cmdline
        misc "$(t inst_files_under_cdrom)"
        find /cdrom -maxdepth 6 -print 2>/dev/null | head -n 50 | sed 's/^/  /' || true
        die "$(t err_inst_no_squashfs)"
    fi
    txt "$(t inst_squashfs "$(fstr "$SQUASH")")"

    LIVE_DEV="$(live_medium_from_bootmnt || true)"
    if [[ -z "$LIVE_DEV" ]]; then LIVE_DEV="$(live_medium_from_squash || true)"; fi
    if [[ -z "$LIVE_DEV" ]]; then LIVE_DEV="$(live_medium_from_iso9660 || true)"; fi

    if [[ -n "$LIVE_DEV" && "$INSTALL_DISK" == "$LIVE_DEV" ]]; then
        die "$(t err_inst_on_live_medium "$DISK")"
    fi

    txt "$(t inst_target "$(fstr "$DISK")")"
    if [[ "$PART_MODE" == "yes" ]]; then
        txt "$(t inst_mode_part "$(fstr "$INSTALL_DISK")")"
    else
        txt "$(t inst_mode_disk)"
    fi
    txt "Firmware:    $FIRMWARE"
    txt "Architektur: $ARCH"
    txt "$(t inst_live_medium "$(fstr "${LIVE_DEV:-$(t word_not_detected)}")")"

    if [[ -z "$LIVE_DEV" ]]; then
        warn "$(t warn_inst_live_unknown)"
        dump_misc cat /proc/cmdline
    fi

    if findmnt -rn -o SOURCE 2>/dev/null | grep -Eq "^${DISK}($|[0-9])"; then
        die "$(t err_inst_still_mounted "$DISK")"
    fi

    local size_bytes size_mb=0 disk_model
    size_bytes="$(lsblk -dnbro SIZE "$DISK" 2>/dev/null | head -n1 || true)"
    if [[ "$size_bytes" =~ ^[0-9]+$ ]]; then
        size_mb=$((size_bytes / 1000000))
    fi
    (( size_mb >= 8000 )) || die "$(t err_inst_too_small "$size_mb")"

    disk_model="$(lsblk -dno MODEL "$DISK" 2>/dev/null | sed 's/[[:space:]]*$//' || true)"
    txt "$(t inst_size "$size_mb")"
    txt "$(t inst_model "${disk_model:-$(t word_unknown)}")"

    head_msg "$(t inst_warn_wipe "$(fstr "$DISK")")"
    confirm_ja_nein || die "$(t info_aborted)"

    local -a pkgs=()
    need_pkg() {
        if ! command -v "$1" >/dev/null 2>&1; then
            case " ${pkgs[*]} " in
                *" $2 "*) ;;
                *) pkgs+=("$2") ;;
            esac
        fi
    }
    need_pkg unsquashfs squashfs-tools
    need_pkg mkfs.ext4 e2fsprogs
    need_pkg wipefs util-linux
    need_pkg blkid util-linux
    need_pkg lsblk util-linux
    need_pkg blockdev util-linux
    need_pkg mount util-linux
    need_pkg umount util-linux
    need_pkg findmnt util-linux
    need_pkg losetup util-linux
    need_pkg sfdisk fdisk
    need_pkg udevadm udev
    need_pkg grub-install grub-common
    need_pkg chroot coreutils
    need_pkg update-initramfs initramfs-tools
    need_pkg systemd-machine-id-setup systemd
    need_pkg sync coreutils
    if [[ "$FIRMWARE" == "UEFI" ]]; then
        need_pkg mkfs.vfat dosfstools
        need_pkg efibootmgr efibootmgr
    fi
    if [[ "$FIRMWARE" == "BIOS" && ! -d /usr/lib/grub/i386-pc ]]; then
        pkgs+=("grub-pc-bin")
    fi
    if [[ "$FIRMWARE" == "UEFI" && ! -d /usr/lib/grub/x86_64-efi ]]; then
        pkgs+=("grub-efi-amd64-bin")
    fi

    if [[ "${#pkgs[@]}" -gt 0 ]]; then
        txt "$(t inst_missing_tools)"
        misc "  ${pkgs[*]}"
        if ! confirm_yes "$(t q_install_now)"; then
            die "$(t err_inst_missing_pkgs "${pkgs[*]}")"
        fi
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"; then
            misc "$(t info_retry_apt_update)"
            apt-get update >/dev/null 2>&1 || true
            DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}" \
                || die "$(t err_inst_pkgs_failed)"
        fi
    fi

    local c
    for c in unsquashfs mkfs.ext4 wipefs blkid lsblk blockdev \
             findmnt losetup sfdisk udevadm grub-install chroot; do
        if ! command -v "$c" >/dev/null 2>&1; then
            die "$(t err_inst_pkg_still_missing "$c")"
        fi
    done
    if [[ "$FIRMWARE" == "UEFI" ]] && ! command -v mkfs.vfat >/dev/null 2>&1; then
        die "$(t err_inst_mkfsvfat_missing)"
    fi

    if [[ "$FIRMWARE" == "BIOS" && ! -d /usr/lib/grub/i386-pc ]]; then
        die "$(t err_inst_grub_bios_missing)"
    fi
    if [[ "$FIRMWARE" == "UEFI" && ! -d /usr/lib/grub/x86_64-efi ]]; then
        die "$(t err_inst_grub_uefi_missing)"
    fi

    KVER="$(uname -r)"
    if [[ ! -d "/lib/modules/$KVER" ]]; then
        KVER="$(find /lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
            | grep -Ev 'extramodules|^build$|^source$' | sort -V | tail -n1 || true)"
    fi
    HOST_KERNEL="/boot/vmlinuz-${KVER}"
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="/cdrom/casper/vmlinuz"
    fi
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="$(find /cdrom /run/live -maxdepth 6 -type f -name 'vmlinuz*' -print 2>/dev/null | head -n1 || true)"
    fi
    if [[ -z "$HOST_KERNEL" || ! -e "$HOST_KERNEL" ]]; then
        die "$(t err_inst_no_kernel)"
    fi
    txt "$(t inst_kernel_source "$(fstr "$HOST_KERNEL")")"

    if [[ "$PART_MODE" == "yes" ]]; then
        txt "$(t inst_part_mode_note1)"
        txt "$(t inst_part_mode_note2 "$(fstr "$INSTALL_DISK")")"
    else
        PART_PREFIX="$(part_prefix "$DISK")"
        P1="${PART_PREFIX}1"
        P2="${PART_PREFIX}2"

        txt "$(t inst_partitioning "$(fstr "$DISK")" "$FIRMWARE")"
        wipefs --all --force "$DISK" >/dev/null 2>&1 || true

        if [[ "$FIRMWARE" == "UEFI" ]]; then
            misc "$(t inst_creating_gpt)"
            if ! printf 'label: gpt\nname="ESP", size=512MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\nname="Root", type=0FC63DAF-8483-4772-8E79-3D69D8477DE4\n' \
                | sfdisk --force --no-reread --no-tell-kernel "$DISK" >/dev/null; then
                die "$(t err_inst_part_gpt)"
            fi
        else
            misc "$(t inst_creating_mbr)"
            if ! printf 'label: dos\nstart=1MiB, type=83, bootable\n' \
                | sfdisk --force --no-reread --no-tell-kernel "$DISK" >/dev/null; then
                die "$(t err_inst_part_mbr)"
            fi
        fi

        sync
        udevadm settle 2>/dev/null || true
        blockdev --rereadpt "$DISK" >/dev/null 2>&1 || true
        local i
        for i in {1..20}; do
            if [[ -b "$P1" ]]; then break; fi
            sleep 1
            udevadm settle 2>/dev/null || true
            blockdev --rereadpt "$DISK" >/dev/null 2>&1 || true
        done
        [[ -b "$P1" ]] || die "$(t err_inst_p1_missing "$P1")"
        if [[ "$FIRMWARE" == "UEFI" && ! -b "$P2" ]]; then
            die "$(t err_inst_p2_missing "$P2")"
        fi

        misc "$(t inst_partitions)"
        dump_misc lsblk -o NAME,SIZE,FSTYPE,TYPE "$DISK"
    fi

    txt "$(t inst_formatting)"

    if [[ "$PART_MODE" == "yes" ]]; then
        txt "$(t inst_formatting_part "$(fstr "$DISK")")"

        if swapon --show=NAME --noheadings 2>/dev/null | grep -Fxq "$DISK"; then
            misc "$(t inst_swap_off)"
            if ! swapoff "$DISK" 2>/dev/null; then
                die "$(t err_inst_swap_off_failed "$DISK")"
            fi
        fi

        wipefs -a "$DISK" >/dev/null 2>&1 || true
        mkfs.ext4 -q -F -L ubunturoot "$DISK" \
            || die "$(t err_inst_format_target)"

        ROOT_PART="$DISK"
        ESP_PART=""

        if [[ "$FIRMWARE" == "UEFI" ]]; then
            misc "$(t inst_search_esp "$(fstr "$INSTALL_DISK")")"
            ESP_PART="$(find_esp_on_disk "$INSTALL_DISK" || true)"
            if [[ -z "$ESP_PART" ]]; then
                misc "$(t inst_partlist "$(fstr "$INSTALL_DISK")")"
                dump_misc lsblk -o NAME,SIZE,PARTTYPENAME,FSTYPE "$INSTALL_DISK"
                die "$(t err_inst_no_esp "$INSTALL_DISK" "$SCRIPT_NAME")"
            fi
            local esp_fstype
            esp_fstype="$(lsblk -nro FSTYPE "$ESP_PART" 2>/dev/null | head -n1 || true)"
            if [[ -z "$esp_fstype" ]]; then
                misc "$(t inst_esp_unformatted "$(fstr "$ESP_PART")")"
                mkfs.vfat -F32 "$ESP_PART" || die "$(t err_inst_esp_format)"
            elif [[ "$esp_fstype" != "vfat" ]]; then
                die "$(t err_inst_esp_wrong_fs "$ESP_PART" "$esp_fstype")"
            fi
        else
            if disk_is_gpt "$INSTALL_DISK" && ! disk_has_biosboot "$INSTALL_DISK"; then
                die "$(t err_inst_bios_gpt_no_biosboot "$INSTALL_DISK")"
            fi
        fi
    else
        if [[ "$FIRMWARE" == "UEFI" ]]; then
            wipefs -a "$P1" >/dev/null 2>&1 || true
            mkfs.vfat -F32 -n ARCHESP "$P1" || die "$(t err_inst_esp_format2)"
            wipefs -a "$P2" >/dev/null 2>&1 || true
            mkfs.ext4 -q -F -L ubunturoot "$P2" || die "$(t err_inst_root_format)"
            ROOT_PART="$P2"
            ESP_PART="$P1"
        else
            wipefs -a "$P1" >/dev/null 2>&1 || true
            mkfs.ext4 -q -F -L ubunturoot "$P1" || die "$(t err_inst_root_format)"
            ROOT_PART="$P1"
            ESP_PART=""
        fi
    fi

    ROOT_UUID="$(blkid -s UUID -o value "$ROOT_PART" 2>/dev/null || true)"
    [[ -n "$ROOT_UUID" ]] || die "$(t err_inst_root_uuid)"
    txt "Root UUID: $ROOT_UUID"

    if [[ -n "$ESP_PART" ]]; then
        ESP_UUID="$(blkid -s UUID -o value "$ESP_PART" 2>/dev/null || true)"
        [[ -n "$ESP_UUID" ]] || die "$(t err_inst_esp_uuid)"
        txt "ESP UUID:  $ESP_UUID"
    fi

    txt "$(t inst_mounting)"

    if mountpoint -q /mnt 2>/dev/null; then
        die "$(t err_inst_mnt_mounted)"
    fi

    mkdir -p /mnt
    umount /mnt/boot/efi 2>/dev/null || true
    umount /mnt/boot 2>/dev/null || true
    if [[ -n "$(ls -A /mnt 2>/dev/null || true)" ]]; then
        misc "$(t inst_clean_mnt)"
        find /mnt -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
    fi

    mount "$ROOT_PART" /mnt || die "$(t err_inst_root_mount)"

    ROOT_MOUNTED="yes"
    ESP_MOUNTED=""
    CHROOT_MOUNTED=""

    cleanup_mounts() {
        sync 2>/dev/null || true
        if [[ "${CHROOT_MOUNTED:-}" == "yes" ]]; then
            umount /mnt/dev /mnt/sys /mnt/proc 2>/dev/null || true
        fi
        if [[ "${ESP_MOUNTED:-}" == "yes" ]]; then umount /mnt/boot/efi 2>/dev/null || true; fi
        if [[ "${ROOT_MOUNTED:-}" == "yes" ]]; then umount /mnt 2>/dev/null || true; fi
    }
    trap cleanup_mounts EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP

    local squash_mb=0
    squash_mb="$(du -m -- "$SQUASH" 2>/dev/null | cut -f1 || true)"
    if [[ "$squash_mb" =~ ^[0-9]+$ && "$squash_mb" -gt 0 ]]; then
        txt "$(t inst_extracting "$(fstr "/mnt")" "$squash_mb")"
    else
        txt "$(t inst_extracting_long "$(fstr "/mnt")")"
    fi
    unsquashfs -no-progress -f -d /mnt "$SQUASH" || die "$(t err_inst_unsquash)"

    if [[ -n "$ESP_PART" ]]; then
        rm -rf -- /mnt/boot/efi
        mkdir -p /mnt/boot/efi
        mount "$ESP_PART" /mnt/boot/efi || die "$(t err_inst_esp_mount)"
        ESP_MOUNTED="yes"
    fi

    local avail_kb avail_mb=0
    avail_kb="$(df -Pk /mnt 2>/dev/null | awk 'NR==2 {print $4}' || true)"
    if [[ "$avail_kb" =~ ^[0-9]+$ ]]; then
        avail_mb=$((avail_kb / 1024))
    fi
    txt "$(t inst_free_after "$avail_mb")"
    (( avail_mb >= 300 )) || die "$(t err_inst_low_space)"

    if [[ "$PART_MODE" == "no" && -d /mnt/boot/efi ]]; then
        misc "$(t inst_remove_bootloader)"
        find /mnt/boot/efi -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
    fi

    txt "$(t inst_checking_kernel)"
    TARGET_KERNEL="/mnt/boot/vmlinuz-${KVER}"
    if [[ ! -e "$TARGET_KERNEL" ]]; then
        mkdir -p /mnt/boot
        cp -L "$HOST_KERNEL" "$TARGET_KERNEL" || die "$(t err_inst_kernel_copy)"
        misc "$(t inst_kernel_copied "$(fstr "$HOST_KERNEL")")"
    fi
    txt "$(t inst_kernel "$(fstr "$TARGET_KERNEL")")"

    local modbase=""
    if [[ -d /mnt/lib/modules ]]; then modbase="/mnt/lib/modules"; fi
    if [[ -z "$modbase" && -d /mnt/usr/lib/modules ]]; then modbase="/mnt/usr/lib/modules"; fi
    if [[ -z "$modbase" ]]; then
        die "$(t err_inst_no_modbase)"
    fi

    local kver_list
    kver_list="$(find "$modbase" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
        | grep -Ev 'extramodules|^build$|^source$' | sort -V || true)"

    KVER="$(uname -r)"
    if ! printf '%s\n' "$kver_list" | grep -qxF "$KVER"; then
        KVER="$(printf '%s\n' "$kver_list" | tail -n1 || true)"
    fi
    if [[ -z "$KVER" ]]; then
        die "$(t err_inst_no_kver)"
    fi
    txt "Kernel-Version: $KVER"

    if [[ ! -d "$modbase/$KVER" ]]; then
        warn "$(t warn_inst_moddir_missing "$modbase" "$KVER")"
        find "$modbase" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null || true
        die "$(t err_inst_no_matching_modules)"
    fi

    txt "$(t inst_creating_fstab)"
    mkdir -p /mnt/etc
    {
        printf '# /etc/fstab\n'
        printf '# Erzeugt vom %s %s\n\n' "$SCRIPT_NAME" "$VERSION"
        printf 'UUID=%s  /  ext4  defaults  0 1\n' "$ROOT_UUID"
        if [[ -n "$ESP_PART" ]]; then
            printf 'UUID=%s  /boot/efi  vfat  umask=0077,nofail  0 0\n' "$ESP_UUID"
        fi
    } > /mnt/etc/fstab

    txt "$(t inst_creating_machine_id)"
    rm -f -- /mnt/etc/machine-id
    if command -v systemd-machine-id-setup >/dev/null 2>&1; then
        systemd-machine-id-setup --root=/mnt >/dev/null 2>&1 || true
    fi

    if [[ ! -s /mnt/etc/machine-id ]]; then
        MACHINE_ID="$(tr -d '-' < /proc/sys/kernel/random/uuid 2>/dev/null || true)"
        if [[ -z "$MACHINE_ID" ]]; then
            MACHINE_ID="$(head -c 16 /dev/urandom 2>/dev/null | od -An -tx1 | tr -d ' \n' || true)"
        fi
        if [[ -n "$MACHINE_ID" ]]; then
            printf '%s\n' "$MACHINE_ID" > /mnt/etc/machine-id
        fi
    fi
    [[ -s /mnt/etc/machine-id ]] || die "$(t err_inst_machine_id)"
    chmod 444 /mnt/etc/machine-id

    if [[ -e /mnt/var/lib/dbus/machine-id && ! -L /mnt/var/lib/dbus/machine-id ]]; then
        cp -f /mnt/etc/machine-id /mnt/var/lib/dbus/machine-id 2>/dev/null || true
    fi
    rm -f -- /mnt/var/lib/systemd/random-seed 2>/dev/null || true

    casper_live_cleanup /mnt

    # display-manager-Kette konsistent machen: der Symlink muss auf eine
    # existierende Unit zeigen und /etc/X11/default-display-manager auf
    # deren Binary (sddms ExecStartPre bricht sonst den Start ab)
    local dm_target
    dm_target="$(readlink /mnt/etc/systemd/system/display-manager.service 2>/dev/null || true)"
    if [[ -n "$dm_target" ]]; then
        local dm_bin=""
        case "$(basename -- "$dm_target")" in
            sddm.service) dm_bin="/usr/bin/sddm" ;;
            lightdm.service) dm_bin="/usr/sbin/lightdm" ;;
            gdm3.service) dm_bin="/usr/sbin/gdm3" ;;
        esac
        if [[ -L /mnt/etc/systemd/system/display-manager.service \
            && ! -e /mnt/etc/systemd/system/display-manager.service ]]; then
            die "$(t err_inst_dm_broken "$dm_target")"
        fi
        if [[ -n "$dm_bin" && -e "/mnt$dm_bin" ]]; then
            local ddm
            ddm="$(cat /mnt/etc/X11/default-display-manager 2>/dev/null || true)"
            if [[ "$ddm" != "$dm_bin" ]]; then
                mkdir -p /mnt/etc/X11
                printf '%s\n' "$dm_bin" > /mnt/etc/X11/default-display-manager
                misc "$(t inst_set_dm "$dm_bin")"
            fi
        fi
    fi

    txt "$(t inst_building_initramfs)"
    # casper-Dateien (hooks/casper, scripts/casper, casper-helpers) werden
    # bewusst NICHT mehr aus dem Zielsystem entfernt: initramfs-tools
    # sourced /scripts/casper nur bei boot=casper - ohne den Kernel-
    # Parameter (installierte Systeme) ist casper dort toter Code. Die
    # Anwesenheit macht jede installierte Kopie DAUERHAFT ISO-baufähig
    # (früher: Bau von der installierten Kopie scheiterte an fehlenden
    # casper-Dateien -> unbootbare ISOs mit Kernel-Panik). Nebeneffekt:
    # künftige update-initramfs-Läufe binden die inerten casper-Skripte
    # ein - harmlos, casper exitet ohne boot=casper.

    mkdir -p /mnt/proc /mnt/sys /mnt/dev
    mount -o bind /proc /mnt/proc 2>/dev/null || true
    mount -o bind /sys /mnt/sys 2>/dev/null || true
    mount -o bind /dev /mnt/dev 2>/dev/null || true
    CHROOT_MOUNTED="yes"

    if [[ -f "/mnt/boot/initrd.img-$KVER" ]]; then
        chroot /mnt update-initramfs -u -k "$KVER" || die "$(t err_inst_update_initramfs)"
    else
        chroot /mnt update-initramfs -c -k "$KVER" || die "$(t err_inst_update_initramfs)"
    fi

    local grub_cfg_done="n"
    if fallback_aktiv; then
        # Fallback für ältere Ubuntu-Versionen: der normale Weg - update-grub
        # erzeugt die Konfiguration aus /etc/default/grub + /etc/grub.d des
        # Zielsystems (getestete Kernel-Kommandozeile, Standard-Menü wie bei
        # einer normalen Installation). Läuft mit gebundenen /proc,/sys,/dev.
        mkdir -p /mnt/boot/grub
        local ug_log
        ug_log="$(mktemp /tmp/ultool-updgrub.XXXXXX)"
        txt "$(t inst_fallback_updategrub)"
        if chroot /mnt update-grub > "$ug_log" 2>&1; then
            grub_cfg_done="j"
            misc "$(t inst_updategrub_done)"
        else
            {
                printf '%s\n' "$(t err_inst_updategrub_failed)"
                sed 's/^/   /' "$ug_log"
            } >&2
        fi
        rm -f "$ug_log"
    fi

    umount /mnt/dev /mnt/sys /mnt/proc 2>/dev/null || true
    CHROOT_MOUNTED=""

    txt "$(t inst_installing_grub "$FIRMWARE")"
    mkdir -p /mnt/boot/grub

    if [[ "$FIRMWARE" == "BIOS" ]]; then
        grub-install \
            --target=i386-pc \
            --recheck \
            --boot-directory=/mnt/boot \
            "$INSTALL_DISK" || die "$(t err_inst_grub_bios)"
    else
        [[ "${ESP_MOUNTED:-}" == "yes" ]] \
            || die "$(t err_inst_esp_not_mounted)"
        local efi_std_ok=n
        # Standardpfad EFI/ubuntu + NVRAM-Eintrag: ueberschreibt Bootloader-Reste
        # einer frueheren Installation und gibt der Firmware den richtigen Verweis
        if grub-install \
            --target=x86_64-efi \
            --recheck \
            --efi-directory=/mnt/boot/efi \
            --boot-directory=/mnt/boot \
            --bootloader-id=Ubuntu \
            "$INSTALL_DISK"; then
            efi_std_ok=j
        else
            warn "$(t warn_inst_uefi_std_failed)"
        fi
        # Portabler Fallback-Pfad EFI/BOOT (Firmware ohne NVRAM-Zugriff/Boot-Menu)
        if ! grub-install \
            --target=x86_64-efi \
            --recheck \
            --efi-directory=/mnt/boot/efi \
            --boot-directory=/mnt/boot \
            --bootloader-id=Ubuntu \
            --removable \
            --no-nvram \
            "$INSTALL_DISK"; then
            if [[ "$efi_std_ok" == "j" ]]; then
                warn "$(t warn_inst_uefi_portable_failed)"
            else
                die "$(t err_inst_grub_uefi)"
            fi
        fi
    fi

    if [[ "$grub_cfg_done" != "j" ]]; then
        txt "$(t inst_creating_grubcfg)"
        {
            printf 'set timeout=5\nset default=0\n\n'
            printf 'menuentry "Ubuntu (%s)" {\n' "$KVER"
            printf '    linux /boot/vmlinuz-%s root=UUID=%s rw\n' "$KVER" "$ROOT_UUID"
            printf '    initrd /boot/initrd.img-%s\n}\n\n' "$KVER"
            printf 'menuentry "Ubuntu (%s) - Fallback" {\n' "$KVER"
            printf '    linux /boot/vmlinuz-%s root=UUID=%s rw\n' "$KVER" "$ROOT_UUID"
            printf '    initrd /boot/initrd.img-%s\n}\n' "$KVER"
        } > /mnt/boot/grub/grub.cfg
    fi

    if [[ "$FIRMWARE" == "UEFI" && ! -f /mnt/boot/efi/EFI/BOOT/BOOTX64.EFI \
        && ! -f /mnt/boot/efi/EFI/ubuntu/grubx64.efi \
        && ! -f /mnt/boot/efi/EFI/ubuntu/shimx64.efi ]]; then
        die "$(t err_inst_no_bootloader_files)"
    fi

    sync

    # Boot-Garantie (Struktur-Pruefung): es darf KEINE Autologin-
    # Konfiguration im Zielsystem ueberleben - das frische System zeigt
    # immer den Login-Bildschirm. Falls doch etwas ueberlebt hat, wird
    # hier hart abgebrochen statt ein System mit defektem Autologin
    # auszuliefern.
    if grep -qs '^\[Autologin\]' /mnt/etc/sddm.conf /mnt/etc/sddm.conf.d/*.conf 2>/dev/null; then
        die "$(t err_inst_autologin_survived)"
    fi

    head_msg "$(t inst_success)"
    txt "$(t inst_done_target "$(fstr "$DISK")")"
    txt "Firmware:   $FIRMWARE"
    txt "$(t inst_done_root "$(fstr "$ROOT_PART")")"
    txt "Root UUID:  $ROOT_UUID"
    txt ""
    txt "$(t inst_now_do)"
    misc "$(t inst_step1)"
    misc "$(t inst_step2)"
    misc "$(t inst_step3)"
    txt ""
    misc "$(t inst_login_screen_info)"
    txt ""
    warn "$(t warn_secure_boot)"
    return 0
}

install_interactive() {
    head_msg "$(t inst_menu_title)"

    while :; do
        if menu_select "$(t inst_menu)" \
            "$(t inst_menu_choose)" \
            "$(t inst_menu_show)" \
            "$(t inst_menu_partition)"; then
            case "$MENU_NR" in
                1)
                    if choose_install_target; then
                        do_install
                    fi ;;
                2) show_targets ;;
                3) part_menu ;;
            esac
        else
            return 0
        fi
    done
}

#@@ENDBLOCK:INSTALL

#@@BLOCK:ISO
# ============================================================
# ISO-Builder (Live-ISO vom laufenden System, casper)
# ============================================================

WORK=""
OUT=""
ISO_LABEL="UBUNTULIVE"
SQUASH_COMP="zstd"
EXTRA_EXCLUDES=()

LIVE_TREE=""
MERGED=""
OVL_UPPER="/run/liveiso-overlay-upper"
OVL_WORK="/run/liveiso-overlay-work"

iso_check_target() {
    local kind="$1" path="$2" fst
    if [[ -z "$path" ]]; then
        return 0
    fi
    mkdir -p "$path" 2>/dev/null || true
    case "$path" in
        /|/boot|/boot/*|/efi|/efi/*|/etc|/etc/*|/usr|/usr/*|/var|/var/*|/bin|/bin/*|/sbin|/sbin/*|/lib|/lib/*|/lib64|/lib64/*|/root|/root/*|/dev|/dev/*|/proc|/proc/*|/sys|/sys/*)
            die "$(t err_iso_system_area "$kind" "$path")" ;;
    esac
    fst="$(findmnt -nro FSTYPE --target "$path" 2>/dev/null || true)"
    case "$fst" in
        vfat|msdos|fat*|exfat)
            die "$(t err_iso_fat_area "$kind" "$path")" ;;
    esac
}

kill_mount_users() {
    local base="$1" pid root cwd pidpath
    if [[ -z "$base" || ! -d "$base" ]]; then
        return 0
    fi
    for pidpath in /proc/[0-9]*; do
        [[ -d "$pidpath" ]] || continue
        pid="${pidpath#/proc/}"
        if [[ "$pid" == "$$" ]]; then continue; fi
        root="$(readlink "$pidpath/root" 2>/dev/null)" || continue
        case "$root" in
            "$base"|"$base"/*) kill -9 "$pid" 2>/dev/null || true; continue ;;
        esac
        cwd="$(readlink "$pidpath/cwd" 2>/dev/null)" || continue
        case "$cwd" in
            "$base"|"$base"/*) kill -9 "$pid" 2>/dev/null || true ;;
        esac
    done
    return 0
}

do_umount() {
    local m="$1" i
    mountpoint -q "$m" 2>/dev/null || return 0
    for i in 1 2 3; do
        if umount "$m" 2>/dev/null; then
            return 0
        fi
        sleep 1
    done
    warn "$(t warn_iso_mount_blocked "$m")"
    if command -v fuser >/dev/null 2>&1; then fuser -vm "$m" 2>&1 || true; fi
    if umount -l "$m" 2>/dev/null; then
        warn "$(t warn_iso_lazy_umount "$m")"
    else
        err "$(t err_iso_umount_failed "$m")"
    fi
    return 0
}

iso_cleanup_mounts() {
    txt "$(t iso_cleaning)"
    pkill -9 -f "mksquashfs.*$MERGED" 2>/dev/null || true
    kill_mount_users "$MERGED"
    do_umount "$MERGED"
    rm -rf -- "$OVL_UPPER" "$OVL_WORK" 2>/dev/null || true
    sync
}

do_iso_cleanup() {
    require_root
    if [[ -z "$WORK" ]]; then
        WORK="$(invoking_home)/remastern"
    fi
    if [[ -z "$WORK" || "$WORK" == "/" ]]; then
        die "$(t err_iso_work_invalid "$WORK")"
    fi
    LIVE_TREE="$WORK/live-iso-tree"
    MERGED="$WORK/MERGED"

    head_msg "$(t iso_cleanup_title "$(fstr "$WORK")")"
    iso_cleanup_mounts
    rm -rf -- "${LIVE_TREE:?}" "$OVL_UPPER" "$OVL_WORK" "$WORK/initramfs-live-conf" \
        || die "$(t err_iso_artifacts_delete)"
    rmdir "$WORK" 2>/dev/null || true
    sync
    misc "$(t iso_cleanup_done)"
}

give_back_ownership() {
    local user="${SUDO_USER:-}"
    if [[ -z "$user" ]]; then
        return 0
    fi
    if ! getent passwd "$user" >/dev/null; then
        warn "$(t warn_iso_user_unknown "$user")"
        return 0
    fi
    local pfad
    for pfad in "$@"; do
        pfad="${pfad:?}"
        if [[ ! -e "$pfad" ]]; then
            continue
        fi
        if chown -R -- "$user:" "$pfad" 2>/dev/null; then
            misc "$(t iso_owner_set "$(fstr "$pfad")" "$user")"
        else
            err "$(t iso_owner_failed "$(fstr "$pfad")" "$user" "$user" "$pfad")"
        fi
    done
}

# initramfs_verifizieren - Sicherheitsnetz nach dem mkinitramfs-Lauf
# (Wiedereinbau der Erkenntnisse aus Änderung 46): entpackt das gebaute
# Initramfs und prüft die Bestandteile, ohne die das Live-System nicht
# booten kann - /init, das casper-Hauptskript, die Konfiguration und der
# kernel/-Modulbaum (ein /lib/modules/$kver mit NUR Metadaten lieferte
# früher unbootbare ISOs mit Kernel-Panik). Im Stub-Fall zusätzlich die
# neutralisierte 15autologin. Dazu Truncations-Erkennung: das Hauptsegment
# muss sich VOLLSTÄNDIG dekomprimieren lassen. Rückgabe 0 = OK, 1 = Defekt
# (Aufrufer bricht dann ab - der Bau liefert keine unbootbare ISO).
# Aufruf: initramfs_verifizieren <initrd> <kver> <stub_aktiv j|n>
initramfs_verifizieren() {
    local initrd="$1" kver="$2" stub="$3"
    if [[ ! -s "$initrd" ]]; then
        err "$(t err_iso_initrd_empty "$initrd")"
        return 1
    fi

    if command -v unmkinitramfs >/dev/null 2>&1; then
        local vdir base fehl="" mod_quelle=""
        vdir="$(mktemp -d /tmp/ultool-verify-XXXXXX)"
        if ! unmkinitramfs "$initrd" "$vdir" 2>/dev/null; then
            rm -rf -- "$vdir"
            err "$(t err_iso_initrd_unmk)"
            return 1
        fi
        # Layout je nach initramfs-tools-Version: alles unter main/ oder
        # direkt; NOBLE-/24.04-SPECIAL: die Kernelmodule liegen im EARLY-
        # Segment (unkomprimiert, VOR dem komprimierten Hauptsegment) -
        # der Kernel entpackt beim Boot ALLE Segmente ins rootfs, ein
        # solches Initramfs ist völlig in Ordnung (im Docker noble-
        # Container nachgewiesen: 148 Module, alle in early/). Deshalb:
        # init/conf nur in main (dort gehören sie hin), Module und
        # casper-Skripte ÜBERALL suchen (early*/main/direct).
        if [[ -d "$vdir/main" ]]; then base="$vdir/main"; else base="$vdir"; fi
        [[ -e "$base/init" ]] || fehl="$fehl init"
        [[ -e "$base/conf/initramfs.conf" ]] || fehl="$fehl conf/initramfs.conf"
        local casper_gefunden=""
        casper_gefunden="$(find "$vdir" -type f -path "*/scripts/casper" -print -quit 2>/dev/null || true)"
        [[ -n "$casper_gefunden" ]] || fehl="$fehl scripts/casper (casper-Hauptskript)"
        mod_quelle="$(find "$vdir" -type d -path "*/modules/$kver/kernel" -print -quit 2>/dev/null || true)"
        if [[ -z "$mod_quelle" ]] \
            || [[ -z "$(find "$mod_quelle" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
            fehl="$fehl lib/modules/$kver/kernel (Kernelmodule)"
        fi
        if [[ "$stub" == "j" ]] && ! grep -qs "ubuntulive-tool deaktiviert" \
            "$(find "$vdir" -type f -path "*/casper-bottom/15autologin" -print -quit 2>/dev/null)" 2>/dev/null; then
            fehl="$fehl 15autologin-Stub"
        fi
        rm -rf -- "$vdir"
        if [[ -n "$fehl" ]]; then
            err "$(t err_iso_initrd_incomplete "$fehl")"
            return 1
        fi
    else
        warn "$(t warn_iso_no_unmkinitramfs)"
    fi

    # Truncations-Erkennung: das Hauptsegment beginnt nach den (unkomprimierten)
    # Mikrocode-cpio-Segmenten - frühestes Kompressions-Magic an 4-Byte-
    # ausgerichteter Position suchen (Segmentgrenzen sind 4-aligned); ab dem
    # Kandidaten muss der Rest VOLLSTÄNDIG dekomprimieren (-t bestätigt den
    # echten Magie-Treffer und weist falsche zurück). Ein Datei ohne jedes
    # Kompressions-Magic, die mit dem newc-cpio-Magic beginnt, ist
    # unkomprimiert und damit bootbar. Über stdin lesen - grep -abo auf eine
    # Datei würde "datei:offset:treffer" ausgeben.
    local pat hex tool off gefunden=""
    for pat in 'zstd:\x28\xb5\x2f\xfd' 'xz:\xfd\x37\x7a\x58\x5a' 'lz4:\x04\x22\x4d\x18' \
        'lzop:\x89\x4c\x5a\x4f' 'gzip:\x1f\x8b' 'bzip2:\x42\x5a\x68'; do
        tool="${pat%%:*}"
        hex="${pat#*:}"
        while read -r off; do
            [[ -n "$off" ]] || continue
            case "$tool" in
                zstd)  tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | zstd -t >/dev/null 2>&1 || continue ;;
                xz)    tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | xz -t >/dev/null 2>&1 || continue ;;
                lz4)   tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | lz4 -t >/dev/null 2>&1 || continue ;;
                lzop)  tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | lzop -t >/dev/null 2>&1 || continue ;;
                gzip)  tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | gzip -t >/dev/null 2>&1 || continue ;;
                bzip2) tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | bzip2 -t >/dev/null 2>&1 || continue ;;
            esac
            gefunden="$off"
            break
        done < <(LC_ALL=C grep -abo -F -- "$(printf "$hex")" < "$initrd" 2>/dev/null \
            | awk -F: '$1 ~ /^[0-9]+$/ && NF >= 2 && $1 % 4 == 0 {print $1}' || true)
        [[ -n "$gefunden" ]] && break
    done
    if [[ -z "$gefunden" && "$(head -c6 -- "$initrd" 2>/dev/null)" != "070701" ]]; then
        err "$(t err_iso_initrd_truncated)"
        return 1
    fi
    return 0
}

do_iso_build() {
    require_root

    if [[ -z "$WORK" ]]; then
        WORK="$(invoking_home)/remastern"
    fi
    if [[ -z "$WORK" || "$WORK" == "/" ]]; then
        die "$(t err_iso_work_invalid "$WORK")"
    fi
    case "$WORK" in
        *[[:space:]]*) die "$(t err_iso_work_spaces "$WORK")" ;;
    esac

    LIVE_TREE="$WORK/live-iso-tree"
    MERGED="$WORK/MERGED"

    local iso_name="ubuntulive.iso" outdir="$WORK"
    if [[ -n "$OUT" ]]; then
        case "$OUT" in
            */) outdir="${OUT%/}" ;;
            *.iso|*.ISO|*.Iso)
                outdir="$(dirname -- "$OUT")"
                iso_name="$(basename -- "$OUT")" ;;
            *) outdir="$OUT" ;;
        esac
    fi
    iso_name="${iso_name##*/}"
    case "$iso_name" in
        *.iso|*.ISO|*.Iso) : ;;
        *) iso_name="${iso_name}.iso" ;;
    esac
    ISO_LABEL="${ISO_LABEL^^}"
    local output_iso="$outdir/$iso_name"

    iso_check_target "$(t word_workdir)" "$WORK"
    iso_check_target "$(t word_output_dir)" "$outdir"

    mkdir -p "$outdir" || die "$(t err_iso_outdir_create "$outdir")"

    trap iso_cleanup_mounts EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP

    local -a build_pkgs=(casper initramfs-tools squashfs-tools grub-common
        grub-pc-bin grub-efi-amd64-bin xorriso mtools)
    local missing
    missing="$(pkg_missing "${build_pkgs[@]}" | tr '\n' ' ' || true)"
    missing="${missing% }"
    if [[ -n "$missing" ]]; then
        local -a missing_arr=()
        read -r -a missing_arr <<< "$missing"
        txt "$(t iso_missing_pkgs_title)"
        misc "  ${missing_arr[*]}"
        if ! confirm_yes "$(t q_install_now)"; then
            die "$(t err_iso_missing_pkgs "${missing_arr[*]}")"
        fi
        txt "$(t iso_installing_pkgs "${missing_arr[*]}")"
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_arr[@]}"; then
            misc "$(t info_retry_apt_update)"
            apt-get update >/dev/null 2>&1 || true
            DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_arr[@]}" \
                || die "$(t err_iso_pkgs_failed)"
        fi
    fi

    local t
    local -A tool_pkg=(
        [mksquashfs]="squashfs-tools"
        [mkinitramfs]="initramfs-tools"
        [grub-mkrescue]="grub-common"
        [xorriso]="xorriso"
        [mformat]="mtools"
        [mcopy]="mtools"
    )
    for t in mksquashfs mkinitramfs grub-mkrescue xorriso mformat mcopy; do
        if ! command -v "$t" >/dev/null 2>&1; then
            die "$(t err_iso_tool_missing "$t" "${tool_pkg[$t]}")"
        fi
    done
    # casper-Dateien prüfen: hooks/casper UND scripts/casper müssen
    # existieren (beide fehlen in installierten Kopien älterer Installer-
    # Versionen, die sie entfernten). KEIN --reinstall: das scheitert, sobald
    # die exakt installierte Version aus dem Archiv rotiert ist (Versionen
    # werden laufend ersetzt) - stattdessen das AKTUELLE casper-Paket per
    # apt-get download ziehen und die Dateien per dpkg-deb -x extrahieren.
    # Die Datei-Existenz wird VOR dem mkinitramfs sichergestellt (der
    # frühere stille Fehler - Initramfs ohne casper -> Kernel-Panik - ist
    # damit strukturell ausgeschlossen; Rest absichert initramfs_verifizieren).
    if [[ ! -e /usr/share/initramfs-tools/hooks/casper \
        || ! -e /usr/share/initramfs-tools/scripts/casper ]]; then
        misc "$(t info_iso_casper_missing)"
        if ! confirm_yes "$(t q_iso_casper_restore)"; then
            die "$(t err_iso_casper_missing_fatal)"
        fi
        local casper_tmp casper_deb=""
        casper_tmp="$(mktemp -d /tmp/ultool-casper-XXXXXX)"
        # Quelle 1: bereits geladenes Deb im apt-Cache (kein Netzwerk nötig)
        local cachef
        for cachef in /var/cache/apt/archives/casper_*.deb; do
            [[ -e "$cachef" ]] || continue
            casper_deb="$cachef"
            break
        done
        # Quelle 2: aktuelles Archiv. apt-get download hängt an der Version
        # der LOKALEN Paketlisten - ist die installierte Version (z. B. 1.498)
        # inzwischen aus dem Archiv rotiert, schlägt es fehl ("keine Quelle
        # gefunden"); dann Listen auffrischen und erneut versuchen.
        if [[ -z "$casper_deb" ]]; then
            if ! (cd "$casper_tmp" && apt-get download casper >/dev/null 2>&1); then
                misc "$(t info_retry_apt_update)"
                apt-get update >/dev/null 2>&1 || true
                if ! (cd "$casper_tmp" && apt-get download casper); then
                    rm -rf -- "$casper_tmp"
                    die "$(t err_iso_casper_download)"
                fi
            fi
            casper_deb="$(find "$casper_tmp" -maxdepth 1 -name 'casper_*.deb' -print -quit)"
        fi
        if [[ -z "$casper_deb" ]]; then
            rm -rf -- "$casper_tmp"
            die "$(t err_iso_casper_download_short)"
        fi
        if ! dpkg-deb -x "$casper_deb" "$casper_tmp/x"; then
            rm -rf -- "$casper_tmp"
            die "$(t err_iso_casper_extract)"
        fi
        mkdir -p /usr/share/initramfs-tools/hooks /usr/share/initramfs-tools/scripts
        cp -a -- "$casper_tmp/x/usr/share/initramfs-tools/hooks/casper" \
            /usr/share/initramfs-tools/hooks/ 2>/dev/null || true
        # casper-bottom als GESAMTES Verzeichnis ersetzen (alte Reste würden
        # mit neuen Helfern mischen), dazu casper-Hauptskript und Helfer
        rm -rf -- /usr/share/initramfs-tools/scripts/casper-bottom
        cp -a -- "$casper_tmp/x/usr/share/initramfs-tools/scripts/." \
            /usr/share/initramfs-tools/scripts/
        rm -rf -- "$casper_tmp"
        if [[ ! -e /usr/share/initramfs-tools/hooks/casper \
            || ! -e /usr/share/initramfs-tools/scripts/casper ]]; then
            die "$(t err_iso_casper_restore_failed)"
        fi
        misc "$(t info_iso_casper_restored)"
    fi

    local free_gb
    free_gb="$(df -Pk "$WORK" 2>/dev/null | awk 'NR==2{print int($4/1048576)}' || true)"
    if [[ "$free_gb" =~ ^[0-9]+$ ]]; then
        if (( free_gb < 2 )); then
            die "$(t err_iso_low_space "$free_gb" "$WORK")"
        elif (( free_gb < 8 )); then
            warn "$(t warn_iso_low_space "$free_gb" "$WORK")"
        fi
    fi

    if ! grep -qw overlay /proc/filesystems 2>/dev/null; then
        modprobe overlay 2>/dev/null || true
    fi
    if ! grep -qw overlay /proc/filesystems 2>/dev/null; then
        die "$(t err_iso_no_overlay "$(uname -r)")"
    fi

    [[ -n "$ISO_LABEL" ]] || die "$(t err_iso_label_empty)"
    [[ "${#ISO_LABEL}" -le 32 ]] || die "$(t err_iso_label_long "$ISO_LABEL")"
    case "$ISO_LABEL" in
        *[!A-Za-z0-9._-]*) die "$(t err_iso_label_chars "$ISO_LABEL")" ;;
    esac

    case "$SQUASH_COMP" in
        xz|zstd|lzma|gzip|lzo|lz4) : ;;
        *) die "$(t err_iso_bad_comp "$SQUASH_COMP")" ;;
    esac
    txt "$(t iso_comp "$SQUASH_COMP")"

    mkdir -p "$WORK" "$LIVE_TREE/casper" "$LIVE_TREE/boot/grub" \
        || die "$(t err_iso_workdirs)"

    local MACH
    MACH="$(uname -m)"
    if [[ "$MACH" != "x86_64" ]]; then
        warn "$(t warn_iso_arch "$MACH")"
    fi

    # Kernel-Auswahl: ein KVER zählt NUR mit nicht-leerem kernel/-Baum in
    # /lib/modules - ein Verzeichnis mit NUR Metadaten (modules.alias/dep,
    # passiert nach Kernel-Update OHNE Reboot: die Module des laufenden
    # Kernels sind dann entfernt) liefert ein Initramfs OHNE Treiber ->
    # Kernel-Panik beim Boot der ISO (früherer Defekt, Änderung 46).
    KVER="$(uname -r)"
    local -a module_kernels=()
    local mk
    while read -r mk; do
        [[ -n "$mk" ]] || continue
        if [[ -n "$(find "/lib/modules/$mk/kernel" -mindepth 1 -print -quit 2>/dev/null || true)" ]]; then
            module_kernels+=("$mk")
        fi
    done < <(find /lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
        | grep -Ev 'extramodules|^build$|^source$' | sort -V || true)
    if [[ -n "$(find "/lib/modules/$KVER/kernel" -mindepth 1 -print -quit 2>/dev/null || true)" ]]; then
        : # laufender Kernel hat Module - bester Kandidat
    elif [[ "${#module_kernels[@]}" -gt 0 ]]; then
        local old_kver="$KVER"
        KVER="${module_kernels[${#module_kernels[@]}-1]}"
        warn "$(t warn_iso_kernel_no_modules "$old_kver" "$KVER")"
    else
        die "$(t err_iso_no_kernel_modules)"
    fi
    HOST_KERNEL="/boot/vmlinuz-$KVER"
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="/cdrom/casper/vmlinuz"
    fi
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="$(find /cdrom /run/live -maxdepth 6 -type f -name 'vmlinuz*' -print 2>/dev/null | head -n1 || true)"
    fi
    if [[ -z "$HOST_KERNEL" || ! -e "$HOST_KERNEL" ]]; then
        die "$(t err_iso_kernel_file_missing "$KVER")"
    fi
    txt "$(t iso_using_kernel "$KVER" "$(fstr "$HOST_KERNEL")")"

    misc "$(t iso_copying_kernel)"
    cp "$HOST_KERNEL" "$LIVE_TREE/casper/vmlinuz" || die "$(t err_iso_kernel_copy)"

    # Quell-Benutzer für den Live-Autologin ermitteln (Änderung 44): casper
    # schreibt bei jedem Live-Boot einen [Autologin]-Block mit SEINEM
    # Benutzernamen (Standard "ubuntu", wenn keine Flavour-Info vorliegt) -
    # dieser existiert im kopierten System meist NICHT (UID-1000-Konflikt
    # bei 25adduser) -> Anmelde-Schleife, schwarzer Bildschirm. Über den
    # Boot-Parameter username= (casper CMD_USERNAME) meldet sich das
    # Live-System stattdessen als der Benutzer des gesicherten Systems an,
    # der im kopierten System ja existiert. Reihenfolge: Autologin-Config
    # des Quell-Systems, sonst kleinste UID >= 1000. Ein gefundener Name
    # wird gegen /etc/passwd geprüft (casper-Appends mit Phantom-Namen
    # fallen so weg).
    local live_benutzer=""
    live_benutzer="$(grep -hs '^User=' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null | tail -n1 | cut -d= -f2 || true)"
    if [[ -z "$live_benutzer" ]]; then
        live_benutzer="$(grep -hs '^autologin-user=' /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.d/*.conf 2>/dev/null | tail -n1 | cut -d= -f2 || true)"
    fi
    if [[ -z "$live_benutzer" ]]; then
        live_benutzer="$(grep -hs '^AutomaticLogin=' /etc/gdm3/custom.conf 2>/dev/null | tail -n1 | cut -d= -f2 || true)"
    fi
    if [[ -n "$live_benutzer" ]] && ! grep -qs "^${live_benutzer}:" /etc/passwd; then
        live_benutzer=""
    fi
    if [[ -z "$live_benutzer" ]]; then
        live_benutzer="$(awk -F: '$3 >= 1000 && $3 < 65534 { if (!min || $3 < min) { min = $3; u = $1 } } END { print u }' /etc/passwd 2>/dev/null || true)"
    fi
    if [[ -n "$live_benutzer" ]]; then
        txt "$(t iso_live_autologin_user "$live_benutzer")"
    else
        warn "$(t warn_iso_no_live_user)"
    fi

    # Standard-Sitzung des Quell-Systems ermitteln - JE NACH DISPLAY-
    # MANAGER (Ubuntu-Flavours: GNOME=gdm3, Kubuntu/Lubuntu-Neu=sddm,
    # Xubuntu/Lubuntu-Alt=lightdm). casper (1.498) schreibt in seinen
    # [Autologin]-Block Session= LEER - die Flavour-Marker-Dateien
    # (*-live-environment.desktop, plasma.desktop) existieren nur auf
    # Live-Medien, nicht in der kopierten Installation. SDDM findet dann
    # keine Sitzung ("Unable to find autologin session entry"), bricht den
    # Autologin ab und zeigt den Greeter mit vorausgewähltem Benutzer -
    # Anmeldung nur von Hand. Deshalb die Standard-Sitzung des Quell-
    # Systems je DM beim Bau ermitteln und ins Abbild schreiben.
    # WICHTIG (Nutzerbefund): geschrieben wird der Sitzungsname OHNE
    # ".desktop" (z. B. "Lubuntu", nicht "Lubuntu.desktop") - mit Suffix
    # schlägt der Live-Autologin fehl und es bleibt nur der Passwort-
    # Login. Die .desktop-Endung wird NUR zur Existenzprüfung ergänzt.
    local dm_name=""
    local dm_read
    dm_read="$(cat /etc/X11/default-display-manager 2>/dev/null || true)"
    case "$dm_read" in
        *lightdm) dm_name="LightDM" ;;
        *sddm)    dm_name="SDDM" ;;
        *gdm3)    dm_name="GDM" ;;
    esac
    if [[ -z "$dm_name" ]]; then
        if [[ -e /usr/sbin/lightdm ]]; then
            dm_name="LightDM"
        elif [[ -e /usr/bin/sddm ]]; then
            dm_name="SDDM"
        elif [[ -e /usr/sbin/gdm3 ]]; then
            dm_name="GDM"
        fi
    fi

    local sddm_session=""
    local sess_kandidat
    if [[ -n "$live_benutzer" && -n "$dm_name" ]]; then
        case "$dm_name" in
            SDDM)
                # Reihenfolge: letzte genutzte Sitzung (state.conf [Last]
                # Session, alt: [General] LastSession), Session= der
                # Autologin-Config.
                sess_kandidat="$(awk -F= '/^\[/{inlast=($0 ~ /^\[Last\]/); next} inlast && $1 ~ /^[[:space:]]*Session[[:space:]]*$/ {gsub(/[[:space:]]/, "", $2); v=$2} END {print v}' /var/lib/sddm/state.conf 2>/dev/null || true)"
                if [[ -z "$sess_kandidat" ]]; then
                    sess_kandidat="$(awk -F= '/^\[/{ingen=($0 ~ /^\[General\]/); next} ingen && $1 ~ /^[[:space:]]*LastSession[[:space:]]*$/ {gsub(/[[:space:]]/, "", $2); v=$2} END {print v}' /var/lib/sddm/state.conf 2>/dev/null || true)"
                fi
                sess_kandidat="${sess_kandidat##*/}"
                if [[ -n "$sess_kandidat" && "$sess_kandidat" != *.desktop ]]; then
                    sess_kandidat="${sess_kandidat}.desktop"
                fi
                if [[ -n "$sess_kandidat" && ! -e "/usr/share/xsessions/$sess_kandidat" \
                    && ! -e "/usr/share/wayland-sessions/$sess_kandidat" ]]; then
                    sess_kandidat=""
                fi
                if [[ -z "$sess_kandidat" ]]; then
                    sess_kandidat="$(grep -hs '^Session=' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null \
                        | tail -n1 | cut -d= -f2- | tr -d '[:space:]' || true)"
                    case "$sess_kandidat" in
                        *.desktop)
                            if [[ ! -e "/usr/share/xsessions/$sess_kandidat" \
                                && ! -e "/usr/share/wayland-sessions/$sess_kandidat" ]]; then
                                sess_kandidat=""
                            fi ;;
                        *) sess_kandidat="" ;;
                    esac
                fi
                ;;
            LightDM)
                # autologin-session= steht ohne .desktop in der Config.
                sess_kandidat="$(grep -hs '^autologin-session=' /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.d/*.conf 2>/dev/null \
                    | tail -n1 | cut -d= -f2- | tr -d '[:space:]' || true)"
                if [[ -n "$sess_kandidat" \
                    && ! -e "/usr/share/xsessions/$sess_kandidat.desktop" \
                    && ! -e "/usr/share/wayland-sessions/$sess_kandidat.desktop" ]]; then
                    sess_kandidat=""
                fi
                ;;
            GDM)
                # GDM liest die Sitzung aus AccountsService (ohne .desktop;
                # manche Versionen tragen das Suffix - hier abschneiden).
                sess_kandidat="$(awk -F= '$1 ~ /^[[:space:]]*Session[[:space:]]*$/ {gsub(/[[:space:]]/, "", $2); v=$2} END {print v}' \
                    "/var/lib/AccountsService/users/$live_benutzer" 2>/dev/null || true)"
                sess_kandidat="${sess_kandidat%.desktop}"
                if [[ -n "$sess_kandidat" \
                    && ! -e "/usr/share/xsessions/$sess_kandidat.desktop" \
                    && ! -e "/usr/share/wayland-sessions/$sess_kandidat.desktop" ]]; then
                    sess_kandidat=""
                fi
                ;;
        esac
        # Gemeinsamer Fallback (alle DMs): genau EINE vorhandene
        # Sitzung -> deren Name (ohne .desktop).
        if [[ -z "$sess_kandidat" ]]; then
            local -a sess_dateien=()
            local sf
            for sf in /usr/share/xsessions/*.desktop /usr/share/wayland-sessions/*.desktop; do
                if [[ -e "$sf" ]]; then
                    sess_dateien+=("${sf##*/}")
                fi
            done
            if [[ "${#sess_dateien[@]}" -eq 1 ]]; then
                sess_kandidat="${sess_dateien[0]}"
            fi
        fi
        sddm_session="${sess_kandidat%.desktop}"
        if [[ -n "$sddm_session" ]]; then
            txt "$(t iso_dm_session "$dm_name" "$sddm_session")"
        else
            warn "$(t warn_iso_no_dm_session "$dm_name")"
        fi
    fi

    local confdir="$WORK/initramfs-live-conf"
    mkdir -p "$confdir/conf.d"
    # mkinitramfs liest mit -d nur diese Datei - ohne COMPRESS bricht es ab
    {
        printf 'MODULES=most\n'
        printf 'BUSYBOX=auto\n'
        printf 'COMPRESS=zstd\n'
        printf 'DEVICE=\n'
        printf 'NFSROOT=auto\n'
        printf 'RUNSIZE=10%%\n'
        printf 'FSTYPE=auto\n'
        printf 'RESUME=none\n'
    } > "$confdir/initramfs.conf"

    # casper-Autologin NUR neutralisieren, wenn kein Quell-Benutzer
    # ermittelbar war: sonst schreibt 15autologin beim Live-Boot einen
    # [Autologin]-Block auf ein Phantom (SDDM-Anmelde-Schleife, schwarzer
    # Bildschirm). Mit Benutzer UND erkannter SDDM-Sitzung läuft 15autologin
    # unangetastet - sein Session= LEER ist dann harmlos, weil die Sitzung
    # über /var/lib/sddm/state.conf im Abbild bereitsteht (SDDM-Fallback,
    # siehe unten). Das Skript wird nur für die Dauer des mkinitramfs-Laufs
    # neutralisiert (Original wird danach zurückgestellt); das laufende
    # System ist danach unangetastet.
    local al_script="/usr/share/initramfs-tools/scripts/casper-bottom/15autologin"
    local al_backup="${al_script}.ultool-orig"
    local al_neutralisiert="n"
    if [[ -z "$live_benutzer" ]]; then
        if [[ -f "$al_backup" ]]; then
            # Absturz-Recovery: Backup eines früheren Laufs zurückstellen
            mv -f -- "$al_backup" "$al_script"
        fi
        if [[ -f "$al_script" ]]; then
            cp -a -- "$al_script" "$al_backup"
            cat > "$al_script" <<'ALSTUB'
#!/bin/sh
# casper-Autologin durch ubuntulive-tool deaktiviert: das Live-System
# startet mit dem SDDM-Login-Bildschirm statt Autologin.
PREREQ=""
prereqs() { echo "$PREREQ"; }
case $1 in
    prereqs) prereqs; exit 0 ;;
esac
ALSTUB
            al_neutralisiert="j"
            txt "$(t iso_disable_autologin)"
        fi
    fi

    local mki_log
    mki_log="$(mktemp /tmp/ultool-mkinitramfs.XXXXXX)"
    local -a mki_args=(-o "$LIVE_TREE/casper/initrd" "$KVER")
    if fallback_aktiv; then
        # Fallback für ältere Ubuntu-Versionen: der normale Weg -
        # mkinitramfs mit der Systemkonfiguration statt Mini-Confdir.
        txt "$(t iso_fallback_initramfs)"
    else
        mki_args=(-d "$confdir" "${mki_args[@]}")
        txt "$(t iso_building_initramfs)"
    fi
    if ! mkinitramfs "${mki_args[@]}" 2> "$mki_log"; then
        if [[ "$al_neutralisiert" == "j" ]]; then
            mv -f -- "$al_backup" "$al_script"
        fi
        {
            printf '%s\n' "$(t err_iso_mkinitramfs_failed)"
            sed 's/^/   /' "$mki_log"
            printf '\n%s\n' "$(t iso_check_pkgs)"
        } >&2
        rm -f "$mki_log"
        die "$(t err_iso_initrd_failed)"
    fi
    rm -f "$mki_log"
    if [[ "$al_neutralisiert" == "j" ]]; then
        mv -f -- "$al_backup" "$al_script"
    fi
    chmod 644 "$LIVE_TREE/casper/vmlinuz" "$LIVE_TREE/casper/initrd"

    # Sicherheitsnetz (Änderung 46/50): das gebaute Initramfs muss bootbar
    # sein - Init, casper-Hauptskript, Konfiguration, kernel/-Modulbaum;
    # im Stub-Fall zusätzlich der neutralisierte 15autologin; dazu
    # Truncations-Erkennung. Defekt -> Abbruch statt unbootbarer ISO.
    if ! initramfs_verifizieren "$LIVE_TREE/casper/initrd" "$KVER" "$al_neutralisiert"; then
        die "$(t err_iso_initrd_broken "$KVER")"
    fi

    local base_params="boot=casper"
    if [[ -n "$live_benutzer" ]]; then
        base_params="$base_params username=$live_benutzer"
    fi

    add_entry() {
        local title="$1" extra="$2"
        {
            printf '\nmenuentry "Ubuntu Live - %s" {\n' "$title"
            printf '    linux /casper/vmlinuz %s %s\n' "$base_params" "$extra"
            printf '    initrd /casper/initrd\n}\n' 
        } >> "$LIVE_TREE/boot/grub/grub.cfg"
    }

    {
        printf 'insmod all_video\n'
        printf 'insmod gzio\n'
        printf 'set timeout=10\n'
        printf 'set default=0\n'
    } > "$LIVE_TREE/boot/grub/grub.cfg"

    add_entry "$(t grub_std)" "quiet splash"
    add_entry "$(t grub_verbose)" "loglevel=7"
    add_entry "$(t grub_toram)" "toram"
    add_entry "$(t grub_nomodeset)" "nomodeset"

    txt "$(t iso_mounting_overlay)"
    rm -rf -- "$OVL_UPPER" "$OVL_WORK"
    mkdir -p "$OVL_UPPER" "$OVL_WORK" "$MERGED" || die "$(t err_iso_overlay_dirs)"
    if ! mount -t overlay overlay \
        -o "lowerdir=/,upperdir=$OVL_UPPER,workdir=$OVL_WORK" "$MERGED"; then
        die "$(t err_iso_overlay_mount)"
    fi
    if [[ ! -e "$MERGED/usr/bin" ]]; then
        do_umount "$MERGED"
        die "$(t err_iso_overlay_incomplete)"
    fi
    if [[ ! -e "$MERGED/sbin/init" && ! -e "$MERGED/usr/lib/systemd/systemd" ]]; then
        do_umount "$MERGED"
        die "$(t err_iso_no_systemd)"
    fi

    local other_parts
    other_parts="$(findmnt -rn -o TARGET,FSTYPE 2>/dev/null | awk \
        '$2 !~ /^(proc|sysfs|tmpfs|devtmpfs|devpts|squashfs|efivarfs|cgroup2|securityfs|pstore|bpf|debugfs|tracefs|configfs|mqueue|hugetlbfs|ramfs|autofs|binfmt_misc|overlay|fusectl|nsfs|vfat|iso9660)$/ && $1 ~ /^\/[^\/]/ && $1 != "/boot/efi" {print $1}' || true)"
    if [[ -n "$other_parts" ]]; then
        warn "$(t warn_iso_own_partitions)"
        printf '%s\n' "$other_parts" | sed 's/^/   - /'
    fi

    printf '# Live-System: Root wird vom casper-Hook eingebunden, fstab absichtlich leer.\n' \
        > "$MERGED/etc/fstab"
    if [[ -e "$MERGED/etc/crypttab" ]]; then
        : > "$MERGED/etc/crypttab"
    fi
    : > "$MERGED/etc/machine-id"
    if [[ -d "$MERGED/var/lib/dbus" ]]; then
        rm -f -- "$MERGED/var/lib/dbus/machine-id"
        ln -sf /etc/machine-id "$MERGED/var/lib/dbus/machine-id"
    fi

    # Netzwerk live-tauglich machen (nur im Abbild). NM-Pfad: das network-
    # manager-Paket schraenkt Ethernet in /usr/lib/NetworkManager/conf.d ein -
    # die leere /etc-Override schattet sie aus (Mechanik der offiziellen
    # Live-Images, die sonst nur der Installer anlegt). Das udev-Regelfile
    # sortiert nach netplans 90-/99-Regeln (zz-) und hebt deren NM_UNMANAGED=1
    # auf. networkd-Pfad (Server-Quellen ohne NM): netplan rendert zu
    # systemd-networkd, ist aber meist MAC-gebunden (cloud-init) - auf fremder
    # Hardware matcht kein Eintrag -> kein DHCP. networkd nimmt das ERSTE
    # matchende .network-File; netplan-Files heissen 10-netplan-*, der
    # Fallback 85-live-dhcp.network greift also nur dort, wo netplan nichts
    # matcht.
    if [[ -d "$MERGED/etc/NetworkManager" ]]; then
        mkdir -p "$MERGED/etc/NetworkManager/conf.d"
        : > "$MERGED/etc/NetworkManager/conf.d/10-globally-managed-devices.conf"
        rm -f -- "$MERGED/var/lib/NetworkManager/NetworkManager-intern.conf"
        mkdir -p "$MERGED/etc/udev/rules.d"
        {
            printf '# Live-ISO: nach netplans 90-/99-Regeln (zz- sortiert zuletzt);\n'
            printf '# hebt NM_UNMANAGED=1 fuer fremde Geraete (andere MAC) auf.\n'
            printf 'ACTION=="add|change", SUBSYSTEM=="net", ENV{NM_UNMANAGED}="0"\n'
        } > "$MERGED/etc/udev/rules.d/zz-ubuntulive-nm.rules"
        txt "$(t iso_nm_enabled)"
    fi
    if [[ -e "$MERGED/usr/lib/systemd/system/systemd-networkd.service" ]]; then
        mkdir -p "$MERGED/etc/systemd/network"
        {
            printf '# Live-ISO-Fallback: DHCP fuer Geraete ohne netplan-Match\n'
            printf '# (fremde MAC/Hardware); netplan-Files (10-*) haben Vorrang.\n'
            printf '[Match]\n'
            printf 'Name=e* eth*\n'
            printf '\n[Network]\n'
            printf 'DHCP=yes\n'
        } > "$MERGED/etc/systemd/network/85-live-dhcp.network"
        if [[ ! -d "$MERGED/etc/NetworkManager" ]]; then
            local nd_wants="$MERGED/etc/systemd/system/multi-user.target.wants"
            if [[ ! -e "$nd_wants/systemd-networkd.service" && \
                ! -L "$nd_wants/systemd-networkd.service" ]]; then
                mkdir -p "$nd_wants"
                ln -sf /usr/lib/systemd/system/systemd-networkd.service \
                    "$nd_wants/systemd-networkd.service"
            fi
            txt "$(t iso_networkd_fallback)"
        fi
    fi
    if [[ ! -d "$MERGED/etc/NetworkManager" && \
        ! -e "$MERGED/usr/lib/systemd/system/systemd-networkd.service" ]]; then
        warn "$(t warn_iso_no_network)"
    fi

    casper_live_cleanup "$MERGED"

    # Eigener SDDM-Autologin ins Abbild (nur wenn Benutzer UND Sitzung
    # ermittelt). Zwei Dateien, zwei Aufgaben:
    # - /etc/sddm.conf [Autologin] User= + Session=: bewirkt, dass SDDM den
    #   Autologin VERSUCHT. caspers 15autologin hängt beim Live-Boot einen
    #   weiteren Block mit Session= LEER an (QSettings: letzter gewinnt) -
    #   dieser falls casper fehlt unverzichtbare Block wird dadurch zwar
    #   neutralisiert, aber:
    # - /var/lib/sddm/state.conf [Last] Session=: SDDMs offizieller Fallback
    #   bei leerer Autologin-Session (Display.cpp: attemptAutologin liest
    #   stateConfig.Last.Session). Diese Datei trägt die Sitzung durch
    #   caspers Append hindurch. Beide Formate ([Last] neu ab sddm 0.19/0.20,
    #   [General] LastSession alt) werden geschrieben - QSettings ignoriert
    #   unbekannte Sektionen/Keys, unbekannte Teile sind harmlos.
    # caspers 15autologin bleibt dafür UNANGETASTET (kein Initramfs-Eingriff
    # mehr im Normalfall); alte [Autologin]-Blöcke hat casper_live_cleanup
    # direkt oben entfernt.
    if [[ -n "$live_benutzer" && -n "$sddm_session" ]]; then
        # sddm_session traegt die je DM ermittelte Sitzung (ohne .desktop).
        case "$dm_name" in
            SDDM)
                # Zwei Dateien, zwei Aufgaben:
                # - /etc/sddm.conf [Autologin] User= + Session=: bewirkt,
                #   dass SDDM den Autologin VERSUCHT. caspers 15autologin
                #   haengt beim Live-Boot einen weiteren Block mit Session=
                #   LEER an (QSettings: letzter gewinnt).
                # - /var/lib/sddm/state.conf [Last] Session=: SDDMs
                #   offizieller Fallback bei leerer Autologin-Session
                #   (Display.cpp: attemptAutologin liest
                #   stateConfig.Last.Session). Diese Datei traegt die
                #   Sitzung durch caspers Append hindurch. Beide Formate
                #   ([Last] neu ab sddm 0.19/0.20, [General] LastSession
                #   alt) werden geschrieben.
                {
                    printf '# Live-Autologin (ubuntulive-tool): Sitzungs-Fallback in\n'
                    printf '# /var/lib/sddm/state.conf hält die Sitzung, falls casper\n'
                    printf '# seinen [Autologin]-Block mit leerer Session= anhängt.\n'
                    printf '[Autologin]\n'
                    printf 'User=%s\n' "$live_benutzer"
                    printf 'Session=%s\n' "$sddm_session"
                } >> "$MERGED/etc/sddm.conf"
                mkdir -p "$MERGED/var/lib/sddm"
                {
                    printf '[Last]\n'
                    printf 'User=%s\n' "$live_benutzer"
                    printf 'Session=%s\n' "$sddm_session"
                    printf '[General]\n'
                    printf 'LastUser=%s\n' "$live_benutzer"
                    printf 'LastSession=%s\n' "$sddm_session"
                } > "$MERGED/var/lib/sddm/state.conf"
                # Eigentümer am sddm-Account des ABBILDS ausrichten
                # (numerisch, der Host kennt den Bild-Benutzer nicht).
                local sddm_uid sddm_gid
                sddm_uid="$(awk -F: '$1 == "sddm" {print $3; exit}' "$MERGED/etc/passwd" 2>/dev/null || true)"
                sddm_gid="$(awk -F: '$1 == "sddm" {print $3; exit}' "$MERGED/etc/group" 2>/dev/null || true)"
                if [[ "$sddm_uid" =~ ^[0-9]+$ && "$sddm_gid" =~ ^[0-9]+$ ]]; then
                    chown "$sddm_uid:$sddm_gid" "$MERGED/var/lib/sddm/state.conf" 2>/dev/null || true
                fi
                chmod 600 "$MERGED/var/lib/sddm/state.conf"
                txt "$(t iso_sddm_block_written "$live_benutzer" "$sddm_session")"
                txt "$(t iso_sddm_fallback "$sddm_session")"
                ;;
            LightDM)
                # autologin-session= erwartet den Sitzungsnamen ohne
                # .desktop - exakt das hier geschriebene Format.
                mkdir -p "$MERGED/etc/lightdm/lightdm.conf.d"
                {
                    printf '# Live-Autologin (ubuntulive-tool): Benutzer und\n'
                    printf '# Sitzung des gesicherten Systems.\n'
                    printf '[Seat:*]\n'
                    printf 'autologin-user=%s\n' "$live_benutzer"
                    printf 'autologin-session=%s\n' "$sddm_session"
                } > "$MERGED/etc/lightdm/lightdm.conf.d/50-ubuntulive-autologin.conf"
                txt "$(t iso_lightdm_block_written "$live_benutzer" "$sddm_session")"
                ;;
            GDM)
                # GDM liest die Sitzung aus AccountsService; die kopierte
                # Installation bringt sie meist selbst mit - nur ergänzen,
                # wenn im Abbild keine Session= steht.
                local gdm_user_file="$MERGED/var/lib/AccountsService/users/$live_benutzer"
                if [[ -f "$gdm_user_file" ]] && grep -qs '^Session=' "$gdm_user_file"; then
                    :
                else
                    mkdir -p "$MERGED/var/lib/AccountsService/users"
                    {
                        printf '[User]\n'
                        printf 'Session=%s\n' "$sddm_session"
                    } > "$gdm_user_file"
                fi
                txt "$(t iso_gdm_session_set "$sddm_session")"
                ;;
        esac
    fi

    local -a excl=( "proc/*" "sys/*" "dev/*" "run/*" "tmp/*" "mnt/*" "media/*"
        "var/tmp/*" "var/log/*" "var/crash/*" "var/lib/systemd/coredump/*"
        "var/cache/apt/archives/*" "var/lib/apt/lists/*"
        "var/lib/systemd/random-seed"
        "lost+found" "cdrom" "swapfile" "swap.img" )

    local work_rel="${WORK#/}"
    if [[ -n "$work_rel" ]]; then
        excl+=("$work_rel")
    fi
    local p
    for p in "${EXTRA_EXCLUDES[@]}"; do
        excl+=("${p#/}")
    done

    txt "$(t iso_close_apps)"
    case "$SQUASH_COMP" in
        xz|lzma) txt "$(t iso_creating_squash_slow "$SQUASH_COMP")" ;;
        *) txt "$(t iso_creating_squash "$SQUASH_COMP")" ;;
    esac
    local new_squash="$LIVE_TREE/casper/filesystem.squashfs.new"
    rm -f -- "$new_squash"
    if ! mksquashfs "$MERGED" "$new_squash" -noappend -comp "$SQUASH_COMP" -b 1M -no-recovery \
        -wildcards -e "${excl[@]}"; then
        do_umount "$MERGED"
        die "$(t err_iso_mksquashfs)"
    fi
    sync
    mv -f "$new_squash" "$LIVE_TREE/casper/filesystem.squashfs" \
        || die "$(t err_iso_squash_move)"

    if ! dpkg-query -W -f="\${Package}\t\${Version}\n" > "$LIVE_TREE/casper/filesystem.manifest" 2>/dev/null; then
        warn "$(t warn_iso_manifest)"
    fi

    do_umount "$MERGED"
    rm -rf -- "$OVL_UPPER" "$OVL_WORK"

    txt "$(t iso_creating_iso "$(fstr "$output_iso")")"
    rm -f -- "$output_iso"
    if ! grub-mkrescue -o "$output_iso" "$LIVE_TREE" -volid "$ISO_LABEL" -iso-level 3 -J -R; then
        die "$(t err_iso_grubmkrescue)"
    fi
    [[ -s "$output_iso" ]] || die "$(t err_iso_not_created)"

    give_back_ownership "$WORK"
    if [[ "$output_iso" != "$WORK"/* ]]; then
        give_back_ownership "$output_iso"
    fi

    local iso_mb
    iso_mb="$(du -m "$output_iso" 2>/dev/null | cut -f1 || true)"
    head_msg "$(t iso_success)"
    txt "$(t iso_output_path "$(fstr "$output_iso")" "${iso_mb:-?}")"
    txt "Kernel:      $KVER"
    # SHA256 der ISO ausgeben (Änderung 46/50): Kopien/USB-Übertragungen
    # lassen sich damit prüfen - dieselbe Schadstelle (abgeschnittene
    # Datei) kann auch beim Kopieren entstehen.
    if command -v sha256sum >/dev/null 2>&1; then
        local iso_sha
        iso_sha="$(sha256sum -- "$output_iso" 2>/dev/null | awk '{print $1}' || true)"
        if [[ -n "$iso_sha" ]]; then
            txt "SHA256:      $iso_sha"
        fi
    fi
    txt "Label:       $ISO_LABEL"
    if [[ -n "$live_benutzer" && -n "$sddm_session" ]]; then
        misc "$(t iso_autologin_user_session "$live_benutzer" "$sddm_session")"
    elif [[ -n "$live_benutzer" ]]; then
        misc "$(t iso_autologin_user "$live_benutzer")"
    else
        misc "$(t iso_autologin_none)"
    fi
    warn "$(t warn_iso_secure_boot)"
    printf '\n'
    head_msg "$(t iso_done_close)"
    return 0
}

choose_squash_comp() {
    local -a comp_algos=(xz zstd lzma gzip lzo lz4)
    local -a comp_descr=(
        "$(t iso_comp_xz)"
        "$(t iso_comp_zstd)"
        "$(t iso_comp_lzma)"
        "$(t iso_comp_gzip)"
        "$(t iso_comp_lzo)"
        "$(t iso_comp_lz4)"
    )
    local -a opts=()
    local i mark pick
    for i in "${!comp_algos[@]}"; do
        mark=""
        if [[ "${comp_algos[$i]}" == "$SQUASH_COMP" ]]; then
            mark="$(t iso_comp_default)"
        fi
        opts+=("$(printf '%-5s %s' "${comp_algos[$i]}" "${comp_descr[$i]}")${mark}")
    done
    head_msg "$(t iso_choose_comp)"
    i=1
    for opt in "${opts[@]}"; do
        misc "  ${i}) ${opt}"
        i=$((i + 1))
    done
    while :; do
        printf '%s' "${C_TEXT}$(t menu_choice)${C_MISC}[1-${#comp_algos[@]}, Enter=${SQUASH_COMP}]: ${C_OFF}"
        get_input || return 1
        pick="${INPUT:-}"
        if [[ -z "$pick" ]]; then
            COMP_CHOICE="$SQUASH_COMP"
            return 0
        fi
        if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#comp_algos[@]} )); then
            COMP_CHOICE="${comp_algos[$((pick - 1))]}"
            return 0
        fi
        misc "$(t iso_comp_invalid "${#comp_algos[@]}")"
    done
}

iso_interactive() {
    head_msg "$(t iso_menu_title)"

    ask_string "$(t word_workdir)" "$(invoking_home)/remastern" || return 0
    WORK="$ANSWER"

    ask_string "$(t q_iso_label)" "UBUNTULIVE" || return 0
    ISO_LABEL="$ANSWER"

    choose_squash_comp || return 0
    SQUASH_COMP="$COMP_CHOICE"

    ask_string "$(t q_iso_target)" "" || return 0
    OUT="$ANSWER"

    local excl_input=""
    ask_string "$(t q_iso_excludes)" "" || return 0
    excl_input="$ANSWER"
    EXTRA_EXCLUDES=()
    if [[ -n "$excl_input" ]]; then
        read -r -a EXTRA_EXCLUDES <<< "$excl_input"
    fi

    txt "$(t iso_summary)"
    misc "$(t iso_sum_work "$(fstr "$WORK")")"
    misc "  Label:              $ISO_LABEL"
    misc "  Kompression:        $SQUASH_COMP (SquashFS)"
    misc "$(t iso_sum_target "$(fstr "${OUT:-$WORK/ubuntulive.iso}")")"
    if [[ "${#EXTRA_EXCLUDES[@]}" -gt 0 ]]; then
        misc "$(t iso_sum_excludes "${EXTRA_EXCLUDES[*]}")"
    else
        misc "$(t iso_sum_no_excludes)"
    fi

    confirm_yes "$(t q_iso_start_build)" || { misc "$(t info_aborted)"; return 0; }
    do_iso_build
}

#@@ENDBLOCK:ISO

# ============================================================
# Hauptmenü
# ============================================================

main_menu() {
    INTERACTIVE="j"
    while :; do
        if menu_select "$(t menu_main_title "$SCRIPT_NAME" "$VERSION")" \
            "$(t menu_main_iso)" \
            "$(t menu_main_install)" \
            "$(t menu_main_part)" \
            "$(t menu_main_cleanup)" \
            "$(t menu_main_targets)" \
            "$(t menu_main_export)"; then
            case "$MENU_NR" in
                1) require_root --action iso_interactive
                   run_action iso_interactive ;;
                2) require_root --action install_interactive
                   run_action install_interactive ;;
                3) require_root --action part_menu
                   run_action part_menu ;;
                4) require_root --action do_iso_cleanup_interactive
                   run_action do_iso_cleanup_interactive ;;
                5) run_action show_targets_menu ;;
                6) run_action cmd_export ;;
            esac
        else
            misc "$(t info_done)"
            return 0
        fi
    done
}

show_targets_menu() {
    show_targets
}

do_iso_cleanup_interactive() {
    (
        ask_string "$(t word_workdir)" "$(invoking_home)/remastern" || exit 0
        WORK="$ANSWER"
        confirm_yes "$(t q_iso_cleanup "$(fstr "$WORK")")" || exit 0
        do_iso_cleanup
    )
}

# ============================================================
# Einzelskripte exportieren (Teile als eigenständige Scripts)
# ============================================================

EXPORT_NAME[1]="ubuntulive-part.sh"
EXPORT_NAME[2]="ubuntulive-iso.sh"
EXPORT_NAME[3]="ubuntulive-install.sh"
EXPORT_DESC[1]="$(t exp_desc_part)"
EXPORT_DESC[2]="$(t exp_desc_iso)"
EXPORT_DESC[3]="$(t exp_desc_install)"
EXPORT_SEL=()

usage_export() {
    case "$SPRACHE" in
        EN)
            cat <<HILFE
${C_HEAD}$SCRIPT_NAME export - output parts as standalone scripts${C_OFF}

${C_MISC}Writes the chosen parts of $SCRIPT_NAME as standalone runnable
scripts (each with all required helper functions and its own help):

  ${C_FILE}1${C_MISC} = Partitioner -> ${C_FILE}ubuntulive-part.sh${C_OFF}
  ${C_FILE}2${C_MISC} = ISO creation -> ${C_FILE}ubuntulive-iso.sh${C_OFF}
  ${C_FILE}3${C_MISC} = Installation  -> ${C_FILE}ubuntulive-install.sh${C_OFF}
        ${C_MISC}(also contains the partitioner - because of "partition
        first" in the installation menu)

Usage:
  ${C_FILE}$SCRIPT_NAME export [-s LIST] [-o DIR]${C_OFF}
  ${C_FILE}$SCRIPT_NAME -x DIR${C_OFF}            ${C_MISC}short form: export all three to DIR

Options:
  ${C_FILE}-s, --scripts LIST${C_OFF}  ${C_MISC}parts to export, comma separated
                        (e.g. ${C_FILE}1,2,3${C_MISC}); without -s an interactive prompt appears
  ${C_FILE}-o, --output DIR${C_OFF}    ${C_MISC}target directory
                        [default: directory of $SCRIPT_NAME]
  ${C_FILE}-nc, --no-color${C_OFF}            ${C_MISC}disable colors
  ${C_FILE}-h, --help${C_OFF}           ${C_MISC}this help

Examples:
  ${C_FILE}$SCRIPT_NAME export -s 1,2,3${C_OFF}
  ${C_FILE}$SCRIPT_NAME export -s 2 -o /mnt/usb${C_OFF}
HILFE
            ;;
        *)
    cat <<HILFE
${C_HEAD}$SCRIPT_NAME export - Teile als eigenständige Skripte ausgeben${C_OFF}

${C_MISC}Schreibt gewählte Teile von $SCRIPT_NAME als eigenständig lauffähige
Skripte (jeweils mit allen benötigten Hilfsfunktionen und eigener Hilfe):

  ${C_FILE}1${C_MISC} = Partitionierer -> ${C_FILE}ubuntulive-part.sh${C_OFF}
  ${C_FILE}2${C_MISC} = ISO-Erstellung -> ${C_FILE}ubuntulive-iso.sh${C_OFF}
  ${C_FILE}3${C_MISC} = Installation   -> ${C_FILE}ubuntulive-install.sh${C_OFF}
        ${C_MISC}(enthält auch den Partitionierer - wegen "Zuerst
        partitionieren" im Installations-Menü)

Aufruf:
  ${C_FILE}$SCRIPT_NAME export [-s LISTE] [-o VERZ]${C_OFF}
  ${C_FILE}$SCRIPT_NAME -x VERZ${C_OFF}            ${C_MISC}Kurzform: alle drei nach VERZ ausgeben

Optionen:
  ${C_FILE}-s, --scripts LISTE${C_OFF}  ${C_MISC}zu exportierende Teile, kommasepariert
                        (z. B. ${C_FILE}1,2,3${C_MISC}); ohne -s wird interaktiv gefragt
  ${C_FILE}-o, --output VERZ${C_OFF}    ${C_MISC}Zielverzeichnis
                        [Standard: Verzeichnis des $SCRIPT_NAME]
  ${C_FILE}-nc, --no-color${C_OFF}            ${C_MISC}Farben abschalten
  ${C_FILE}-h, --help${C_OFF}           ${C_MISC}diese Hilfe

Beispiele:
  ${C_FILE}$SCRIPT_NAME export -s 1,2,3${C_OFF}
  ${C_FILE}$SCRIPT_NAME export -s 2 -o /mnt/usb${C_OFF}
HILFE
            ;;
    esac
}

export_parse_sel() {
    EXPORT_SEL=()
    local raw p q dup
    local -a teile=()
    IFS=',' read -r -a teile <<< "$1"
    for p in "${teile[@]}"; do
        raw="${p//[[:space:]]/}"
        case "$raw" in
            1|2|3) ;;
            *) return 1 ;;
        esac
        dup="n"
        for q in "${EXPORT_SEL[@]}"; do
            if [[ "$q" == "$raw" ]]; then
                dup="j"
            fi
        done
        if [[ "$dup" == "n" ]]; then
            EXPORT_SEL+=("$raw")
        fi
    done
    if (( ${#EXPORT_SEL[@]} == 0 )); then
        return 1
    fi
    return 0
}

export_interactive() {
    local nr
    head_msg "$(t exp_title)"
    for nr in 1 2 3; do
        misc "  ${nr}) ${EXPORT_DESC[$nr]}  ->  ${EXPORT_NAME[$nr]}"
    done
    while :; do
        printf '%s' "${C_TEXT}$(t exp_which_parts)${C_MISC}[$(t exp_parts_hint)]: ${C_OFF}"
        get_input || return 1
        if [[ -z "$INPUT" ]]; then
            EXPORT_SEL=(1 2 3)
            return 0
        fi
        case "$INPUT" in
            00) quit_all ;;
            0|q|Q) return 1 ;;
        esac
        if export_parse_sel "$INPUT"; then
            return 0
        fi
        misc "$(t exp_sel_invalid)"
    done
}

export_extract_fn() {
    awk -v fn="$1" '
        !drin && $0 == fn "() {" { drin = 1 }
        drin { print }
        drin && $0 == "}" { exit }
    ' "$SCRIPT_PATH"
}

export_block() {
    local start ende
    start="$(grep -n "^#@@BLOCK:$1\$" "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    ende="$(grep -n "^#@@ENDBLOCK:$1\$" "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    if [[ -z "$start" || -z "$ende" ]]; then
        die "$(t err_exp_no_marker "$1" "$SCRIPT_PATH")"
    fi
    sed -n "$((start + 1)),$((ende - 1))p" "$SCRIPT_PATH"
}

export_header() {
    local nr="$1" zweck tools
    case "$nr" in
        1)
            zweck="Interaktiver Partitionierer (sfdisk-Basis)"
            tools="bash >= 4.4, GNU coreutils, util-linux (sfdisk, lsblk, findmnt, blockdev, wipefs), udev; zum Formatieren dosfstools/e2fsprogs/ntfs-3g (FAT32 notfalls eingebauter Formatierer)" ;;
        2)
            zweck="Live-ISO vom laufenden System erstellen"
            tools="bash >= 4.4, GNU coreutils, util-linux, apt-get, squashfs-tools, grub-common + grub-pc-bin + grub-efi-amd64-bin, xorriso, mtools, casper + initramfs-tools (fehlende werden nachinstalliert)" ;;
        3)
            zweck="Gebootetes Live-System auf Festplatte/Partition installieren"
            tools="bash >= 4.4, GNU coreutils, util-linux, systemd; läuft im gebooteten Ubuntu-Live-System und braucht Root" ;;
    esac
    cat <<KOPF
#!/usr/bin/env bash
#
# ${EXPORT_NAME[$nr]} - $zweck
#
# Eigenständig lauffähiger Teil von $SCRIPT_NAME $VERSION, erzeugt mit
# "$SCRIPT_NAME export". Enthält alle benötigten Hilfsfunktionen.
#
# Verwendung:
#   ohne Argumente  interaktiv (wie im Hauptmenü von $SCRIPT_NAME;
#                   bei ISO ohne Terminal: Direktstart mit Standardwerten)
#   -h | --help     Hilfe
#   -V | --version  Version
#
# Benötigte Tools:
#   $tools
#
# Exit-Codes: 0 = Erfolg, 2 = falsche Argumente, 3 = Fehler/Abbruch.
# Farben: wie das Erzeuger-Script (--no-color oder NO_COLOR=1).
KOPF
    if [[ "$nr" == "2" ]]; then
        printf '%s\n' \
            '# MENU_NR setzt menu_select (mitgeliefertes Menü-Fundament),' \
            '# im ISO-Teil wird sie nie gelesen.' \
            '# shellcheck disable=SC2034'
    fi
}

export_epilog_part() {
    cat <<'EPILOG'
usage_part() {
    case "$SPRACHE" in
    EN)
        cat <<HILFE
${C_HEAD}${SCRIPT_NAME} - interactive partitioner (sfdisk-based)${C_OFF}

${C_MISC}Usage:
  ${C_FILE}${SCRIPT_NAME}${C_OFF}

${C_MISC}Interactive partition manager with number selection: new
partition table (GPT/MBR), create partitions (purpose presets),
delete, format, set type (ESP/BIOS boot/swap), boot flag.

  ${C_FILE}-nc, --no-color${C_OFF}   ${C_MISC}turn colors off
  ${C_FILE}-h, --help${C_OFF}    ${C_MISC}this help
  ${C_FILE}-V, --version${C_OFF} ${C_MISC}version

${C_TEXT}WARNING: Partitioning deletes data irreversibly!${C_OFF}
HILFE
        ;;
    *)
        cat <<HILFE
${C_HEAD}${SCRIPT_NAME} - interaktiver Partitionierer (sfdisk-Basis)${C_OFF}

${C_MISC}Aufruf:
  ${C_FILE}${SCRIPT_NAME}${C_OFF}

${C_MISC}Interaktiver Partitionsmanager mit Zahlen-Auswahl: neue
Partitionstabelle (GPT/MBR), Partitionen erstellen (Zweck-Presets),
löschen, formatieren, Typ setzen (ESP/BIOS-Boot/Swap), Boot-Flag.

  ${C_FILE}-nc, --no-color${C_OFF}   ${C_MISC}Farben abschalten
  ${C_FILE}-h, --help${C_OFF}    ${C_MISC}diese Hilfe
  ${C_FILE}-V, --version${C_OFF} ${C_MISC}Version

${C_TEXT}ACHTUNG: Partitionieren löscht Daten unwiderruflich!${C_OFF}
HILFE
        ;;
    esac
}

main() {
    local cmd="${1:-}"
    case "$cmd" in
        "")
            require_root
            INTERACTIVE="j"
            part_menu ;;
        -h|--help|help)
            usage_part
            exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        -de|-en)
            shift
            main "$@" ;;
        --no-color)
            shift
            main "$@" ;;
        *)
            err "Unbekanntes Argument: $cmd (Hilfe: ${SCRIPT_NAME} -h)"
            usage_part
            exit 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
EPILOG
}

export_epilog_iso() {
    cat <<'EPILOG'
main() {
    local cmd="${1:-}"
    case "$cmd" in
        -h|--help|help)
            usage_iso
            exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        -de|-en)
            shift
            main "$@" ;;
        --no-color)
            shift
            main "$@" ;;
        "")
            if [[ -t 0 ]]; then
                require_root
                INTERACTIVE="j"
                iso_interactive
            else
                cmd_iso
            fi ;;
        *)
            cmd_iso "$@" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
EPILOG
}

export_epilog_install() {
    cat <<'EPILOG'
main() {
    local cmd="${1:-}"
    case "$cmd" in
        -h|--help|help)
            usage_install
            exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        -de|-en)
            shift
            main "$@" ;;
        --no-color)
            shift
            main "$@" ;;
        "")
            cmd_install ;;
        *)
            cmd_install "$@" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
EPILOG
}

export_generate() {
    local nr="$1" ziel="$2"
    local ln_set ln_common
    ln_set="$(grep -n '^set -euo pipefail$' "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    ln_common="$(grep -n '^#@@BLOCK:COMMON$' "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    if [[ -z "$ln_set" || -z "$ln_common" ]]; then
        die "$(t err_exp_no_core "$SCRIPT_PATH")"
    fi

    {
        export_header "$nr"
        printf '\n'
        sed -n "${ln_set},$((ln_common - 1))p" "$SCRIPT_PATH"
        printf '\n'
        export_block COMMON
        printf '\n'
        case "$nr" in
            1)
                export_block PART
                printf '\n'
                export_epilog_part
                ;;
            2)
                export_block ISO
                printf '\n'
                export_extract_fn usage_iso | sed "s/\\\$SCRIPT_NAME iso/\\\$SCRIPT_NAME/g"
                export_extract_fn cmd_iso | sed "s/\\\$SCRIPT_NAME iso/\\\$SCRIPT_NAME/g"
                printf '\n'
                export_epilog_iso
                ;;
            3)
                export_block PART
                printf '\n'
                export_block INSTALL
                printf '\n'
                export_extract_fn usage_install | sed "s/\\\$SCRIPT_NAME install/\\\$SCRIPT_NAME/g"
                export_extract_fn cmd_install | sed "s/\\\$SCRIPT_NAME install/\\\$SCRIPT_NAME/g"
                printf '\n'
                export_epilog_install
                ;;
        esac
    } > "$ziel"
}

cmd_export() {
    local sel="" outdir="" nr ziel
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage_export
                exit 0 ;;
            -s|--scripts)
                if [[ $# -lt 2 ]]; then
                    err "$(t err_exp_need_sel "$1")"
                    usage_export
                    exit 2
                fi
                sel="$2"
                shift 2 ;;
            -o|--output)
                if [[ $# -lt 2 ]]; then
                    err "$(t err_need_dir "$1")"
                    usage_export
                    exit 2
                fi
                outdir="$2"
                shift 2 ;;
            -de|-en)
                shift ;;
            --no-color)
                shift ;;
            *)
                err "$(t err_unknown_arg "$1" "$SCRIPT_NAME export -h")"
                usage_export
                exit 2 ;;
        esac
    done

    if [[ -n "$sel" ]]; then
        if ! export_parse_sel "$sel"; then
            err "$(t err_exp_bad_sel "$sel")"
            exit 2
        fi
    else
        if ! export_interactive; then
            misc "$(t info_done)"
            return 0
        fi
    fi

    if [[ -z "$outdir" ]]; then
        outdir="$(dirname "$SCRIPT_PATH")"
    fi
    if [[ ! -d "$outdir" ]]; then
        mkdir -p "$outdir" || die "$(t err_exp_outdir "$outdir")"
    fi

    if [[ -z "$sel" ]]; then
        for nr in "${EXPORT_SEL[@]}"; do
            if [[ -e "$outdir/${EXPORT_NAME[$nr]}" ]]; then
                confirm_ja_nein "$(t q_exp_overwrite "$outdir")" || {
                    misc "$(t info_done)"
                    return 0
                }
                break
            fi
        done
    fi

    for nr in "${EXPORT_SEL[@]}"; do
        ziel="$outdir/${EXPORT_NAME[$nr]}"
        export_generate "$nr" "$ziel"
        chmod 755 "$ziel" || die "$(t err_exp_chmod "$ziel")"
    done

    local fehler=0
    for nr in "${EXPORT_SEL[@]}"; do
        ziel="$outdir/${EXPORT_NAME[$nr]}"
        if ! bash -n "$ziel"; then
            err "$(t err_exp_invalid_script "$ziel")"
            rm -f -- "$ziel"
            fehler=1
        fi
    done
    if (( fehler != 0 )); then
        die "$(t err_exp_aborted)"
    fi

    head_msg "$(t exp_done)"
    for nr in "${EXPORT_SEL[@]}"; do
        ziel="$outdir/${EXPORT_NAME[$nr]}"
        misc "  ${EXPORT_NAME[$nr]} (${EXPORT_DESC[$nr]}) -> ${ziel}"
    done
}

# ============================================================
# Hilfe
# ============================================================

usage() {
    case "$SPRACHE" in
        EN)
            cat <<HILFE
${C_HEAD}$SCRIPT_NAME $VERSION - build Ubuntu live ISO + install + partition${C_OFF}

${C_TEXT}One tool for everything around the Ubuntu live ISO:${C_OFF}
${C_MISC}  - create a live ISO of the RUNNING system (BIOS + UEFI bootable)
  - install the booted live system to a disk or partition
    (incl. bootloader, BIOS + UEFI automatically detected)
  - partition disks (interactive, number selection)

${C_HEAD}Usage${C_OFF}
${C_MISC}  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME")${C_OFF}${C_MISC}interactive main menu
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME iso [OPTIONS] [TARGET]")${C_OFF}${C_MISC}create live ISO
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME install -d DEVICE [-y]")${C_OFF}${C_MISC}install the live system
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME part")${C_OFF}${C_MISC}partitioner (interactive)
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME cleanup [-w DIR]")${C_OFF}${C_MISC}remove ISO build artifacts
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME targets")${C_OFF}${C_MISC}show installation targets
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME export [-s 1,2,3]")${C_OFF}${C_MISC}export individual scripts
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME -x DIR")${C_OFF}${C_MISC}short form: export all three
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME -V")${C_OFF}${C_MISC}version

${C_HEAD}Exit codes${C_OFF}
${C_MISC}  0 = success, 2 = wrong arguments, 3 = error/abort.

${C_HEAD}install - install the live system${C_OFF}
${C_MISC}  Runs INSIDE the booted Ubuntu live system and needs root.
  Without ${C_FILE}-d${C_MISC} a target is asked interactively in the terminal.
  For a partition ONLY that partition is formatted - the partition
  table stays unchanged. Requirements:
  UEFI: ESP on the same disk; BIOS + GPT: BIOS boot partition.

  Options:
    ${C_FILE}-d, --disk DEVICE${C_OFF}  ${C_MISC}whole disk OR single partition
    ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}skip confirmation prompt (server use)
    ${C_FILE}-h, --help${C_OFF}         ${C_MISC}this help

  Examples (server, no prompts):
    ${C_FILE}$SCRIPT_NAME install -d /dev/sda -y${C_OFF}
    ${C_FILE}$SCRIPT_NAME install -d /dev/nvme0n1p2 -y${C_OFF}

${C_HEAD}iso - Ubuntu live ISO from the running system${C_OFF}
${C_MISC}  Creates a bootable live ISO of the RUNNING system (root,
  Ubuntu system, work directory without spaces).

  Options:
    ${C_FILE}-w, --work DIR${C_OFF}        ${C_MISC}work directory [default: ~/remastern]
    ${C_FILE}-o, --output PATH${C_OFF}     ${C_MISC}target path/directory of the ISO (like TARGET)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}volume label [default: UBUNTULIVE]
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}squashfs compression [default: zstd]
    ${C_FILE}-e, --exclude PATHS${C_OFF}   ${C_MISC}exclude additionally (space separated)

  Examples:
    ${C_FILE}$SCRIPT_NAME iso /srv/iso/rescue.iso${C_OFF}
    ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_OFF}

${C_HEAD}cleanup / part / targets${C_OFF}
${C_MISC}  ${C_FILE}cleanup${C_MISC} unmounts mounts and deletes build artifacts (${C_FILE}-w DIR${C_MISC}).
  ${C_FILE}part${C_MISC}     interactive partitioner: new table (GPT/MBR),
           create partitions (purpose presets), delete, format,
           set type (ESP/BIOS boot/swap), boot flag - all by number.
  ${C_FILE}targets${C_MISC}  lists possible installation targets (read-only).

${C_HEAD}export - output parts as individual scripts${C_OFF}
${C_MISC}  Writes the parts as standalone runnable scripts:
  ${C_FILE}1${C_MISC} = partitioner (${C_FILE}ubuntulive-part.sh${C_MISC}), ${C_FILE}2${C_MISC} = ISO creation
  (${C_FILE}ubuntulive-iso.sh${C_MISC}), ${C_FILE}3${C_MISC} = installation (${C_FILE}ubuntulive-install.sh${C_MISC}).
  Selection via ${C_FILE}-s 1,2,3${C_MISC} or interactive, target via ${C_FILE}-o DIR${C_MISC}
  [default: directory of $SCRIPT_NAME].

${C_HEAD}Color scheme${C_OFF}
${C_MISC}  headings light cyan, text light yellow, files/paths light magenta,
  everything else light green (errors red). Disable: ${C_FILE}-nc, --no-color${C_MISC} or ${C_FILE}NO_COLOR=1${C_OFF}

${C_TEXT}ATTENTION: Installing and partitioning delete data irreversibly!${C_OFF}
HILFE
            ;;
        *)
    cat <<HILFE
${C_HEAD}$SCRIPT_NAME $VERSION - Ubuntu-Live-ISO bauen + installieren + partitionieren${C_OFF}

${C_TEXT}Ein Werkzeug für alle Aufgaben rund um die Ubuntu-Live-ISO:${C_OFF}
${C_MISC}  - Live-ISO vom LAUFENDEN System erstellen (BIOS + UEFI bootbar)
  - das gebootete Live-System auf eine Festplatte oder Partition
    installieren (inkl. Bootloader, BIOS + UEFI automatisch)
  - Festplatten partitionieren (interaktiv, Zahlen-Auswahl)

${C_HEAD}Aufruf${C_OFF}
${C_MISC}  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME")${C_OFF}${C_MISC}interaktives Hauptmenü
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME iso [OPTIONEN] [ZIEL]")${C_OFF}${C_MISC}Live-ISO erstellen
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME install -d GERÄT [-y]")${C_OFF}${C_MISC}Live-System installieren
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME part")${C_OFF}${C_MISC}Partitionierer (interaktiv)
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME cleanup [-w VERZ]")${C_OFF}${C_MISC}ISO-Bau-Artefakte entfernen
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME targets")${C_OFF}${C_MISC}Installationsziele anzeigen
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME export [-s 1,2,3]")${C_OFF}${C_MISC}Einzelskripte ausgeben
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME -x VERZ")${C_OFF}${C_MISC}Kurzform: alle drei ausgeben
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME -V")${C_OFF}${C_MISC}Version

${C_HEAD}Exit-Codes${C_OFF}
${C_MISC}  0 = Erfolg, 2 = falsche Argumente, 3 = Fehler/Abbruch.

${C_HEAD}install - Live-System installieren${C_OFF}
${C_MISC}  Läuft INNERHALB des gebooteten Ubuntu-Live-Systems und braucht Root.
  Ohne ${C_FILE}-d${C_MISC} wird im Terminal interaktiv ein Ziel abgefragt.
  Bei einer Partition wird NUR diese Partition formatiert - die
  Partitionstabelle bleibt unverändert. Voraussetzungen:
  UEFI: ESP auf derselben Platte; BIOS + GPT: BIOS-Boot-Partition.

  Optionen:
    ${C_FILE}-d, --disk GERÄT${C_OFF}   ${C_MISC}komplette Festplatte ODER einzelne Partition
    ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}Sicherheitsabfrage überspringen (Server-Einsatz)
    ${C_FILE}-h, --help${C_OFF}         ${C_MISC}diese Hilfe

  Beispiele (Server, ohne Rückfragen):
    ${C_FILE}$SCRIPT_NAME install -d /dev/sda -y${C_OFF}
    ${C_FILE}$SCRIPT_NAME install -d /dev/nvme0n1p2 -y${C_OFF}

${C_HEAD}iso - Ubuntu-Live-ISO vom laufenden System${C_OFF}
${C_MISC}  Erstellt eine bootbare Live-ISO des LAUFENDEN Systems (Root-Rechte,
  Ubuntu-System, Arbeitsverzeichnis ohne Leerzeichen).

  Optionen:
    ${C_FILE}-w, --work VERZ${C_OFF}       ${C_MISC}Arbeitsverzeichnis [Standard: ~/remastern]
    ${C_FILE}-o, --output PFAD${C_OFF}     ${C_MISC}Zielpfad/Verzeichnis der ISO (wie ZIEL)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}Volume-Label [Standard: UBUNTULIVE]
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}SquashFS-Kompression [Standard: zstd]
    ${C_FILE}-e, --exclude PFADE${C_OFF}   ${C_MISC}zusätzlich ausschließen (leerzeichengetrennt)

  Beispiele:
    ${C_FILE}$SCRIPT_NAME iso /srv/iso/rescue.iso${C_OFF}
    ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_OFF}

${C_HEAD}cleanup / part / targets${C_OFF}
${C_MISC}  ${C_FILE}cleanup${C_MISC} löst Mounts und löscht Build-Artefakte (${C_FILE}-w VERZ${C_MISC}).
  ${C_FILE}part${C_MISC}     interaktiver Partitionierer: neue Tabelle (GPT/MBR),
           Partitionen erstellen (Zweck-Presets), löschen, formatieren,
           Typ setzen (ESP/BIOS-Boot/Swap), Boot-Flag - alles per Zahl.
  ${C_FILE}targets${C_MISC}  listet mögliche Installationsziele (read-only).

${C_HEAD}export - Teile als Einzelskripte ausgeben${C_OFF}
${C_MISC}  Schreibt die Teile als eigenständig lauffähige Skripte:
  ${C_FILE}1${C_MISC} = Partitionierer (${C_FILE}ubuntulive-part.sh${C_MISC}), ${C_FILE}2${C_MISC} = ISO-Erstellung
  (${C_FILE}ubuntulive-iso.sh${C_MISC}), ${C_FILE}3${C_MISC} = Installation (${C_FILE}ubuntulive-install.sh${C_MISC}).
  Auswahl per ${C_FILE}-s 1,2,3${C_MISC} oder interaktiv, Ziel per ${C_FILE}-o VERZ${C_MISC}
  [Standard: Verzeichnis des $SCRIPT_NAME].

${C_HEAD}Farbschema${C_OFF}
${C_MISC}  Überschriften hell-cyan, Text hell-gelb, Dateien/Pfade hell-lila,
  alles andere hell-grün (Fehler rot). Abschalten: ${C_FILE}-nc, --no-color${C_MISC} oder ${C_FILE}NO_COLOR=1${C_OFF}

${C_TEXT}ACHTUNG: Installation und Partitionieren löschen Daten unwiderruflich!${C_OFF}
HILFE
            ;;
    esac
}

usage_install() {
    case "$SPRACHE" in
        EN)
            cat <<HILFE
${C_HEAD}$SCRIPT_NAME install - installs the booted live system${C_OFF}

${C_MISC}Usage:
  ${C_FILE}$SCRIPT_NAME install -d DEVICE [-y]${C_OFF}

${C_MISC}Options:
  ${C_FILE}-d, --disk DEVICE${C_OFF}  ${C_MISC}whole disk OR single partition
                      (without ${C_FILE}-d${C_MISC} a target is asked interactively)
  ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}skip confirmation prompt
  ${C_FILE}-h, --help${C_OFF}         ${C_MISC}this help

${C_MISC}For a partition ONLY that partition is formatted - the disk's
partition table stays unchanged. Requirements:
UEFI: ESP on the same disk; BIOS + GPT: BIOS boot partition.

${C_TEXT}ATTENTION: All data on the target device is irreversibly deleted!${C_OFF}
HILFE
            ;;
        *)
    cat <<HILFE
${C_HEAD}$SCRIPT_NAME install - installiert das gebootete Live-System${C_OFF}

${C_MISC}Aufruf:
  ${C_FILE}$SCRIPT_NAME install -d GERÄT [-y]${C_OFF}

${C_MISC}Optionen:
  ${C_FILE}-d, --disk GERÄT${C_OFF}   ${C_MISC}komplette Festplatte ODER einzelne Partition
                      (ohne ${C_FILE}-d${C_MISC} wird interaktiv ein Ziel abgefragt)
  ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}Sicherheitsabfrage überspringen
  ${C_FILE}-h, --help${C_OFF}         ${C_MISC}diese Hilfe

${C_MISC}Bei einer Partition wird NUR diese Partition formatiert - die
Partitionstabelle der Platte bleibt unverändert. Voraussetzungen:
UEFI: ESP auf derselben Platte; BIOS + GPT: BIOS-Boot-Partition.

${C_TEXT}ACHTUNG: Alle Daten auf dem Zielgerät werden unwiderruflich gelöscht!${C_OFF}
HILFE
            ;;
    esac
}

usage_iso() {
    case "$SPRACHE" in
        EN)
            cat <<HILFE
${C_HEAD}$SCRIPT_NAME iso - Ubuntu live ISO from the running system${C_OFF}

${C_MISC}Usage:
  ${C_FILE}$SCRIPT_NAME iso [OPTIONS] [TARGET]${C_OFF}

${C_MISC}TARGET                  Target path of the ISO: file (ends in ${C_FILE}.iso${C_MISC}) or
                        directory (receives ${C_FILE}ubuntulive.iso${C_MISC}).
                        If omitted: <work directory>/ubuntulive.iso

Options:
  ${C_FILE}-w, --work DIR${C_OFF}        ${C_MISC}work directory for the build [default: ~/remastern]
  ${C_FILE}-o, --output PATH${C_OFF}     ${C_MISC}target path/directory of the ISO (like TARGET)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}volume label of the ISO [default: UBUNTULIVE]
                        (max. 32 characters, A-Z 0-9 . _ -)
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}squashfs compression: xz, zstd, lzma,
                        gzip, lzo, lz4 [default: zstd, configurable in the
                        script via SQUASH_COMP=...]
  ${C_FILE}-e, --exclude PATHS${C_OFF}   ${C_MISC}additional exclusions, space separated,
                        e.g. ${C_FILE}-e "/home/user/data /opt/big"${C_MISC}
  ${C_FILE}-nc, --no-color${C_OFF}            ${C_MISC}disable colors
  ${C_FILE}-h, --help${C_OFF}            ${C_MISC}this help

Examples:
  ${C_FILE}$SCRIPT_NAME iso /srv/iso/test.iso${C_MISC}
  ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_MISC}
HILFE
            ;;
        *)
    cat <<HILFE
${C_HEAD}$SCRIPT_NAME iso - Ubuntu-Live-ISO vom laufenden System${C_OFF}

${C_MISC}Aufruf:
  ${C_FILE}$SCRIPT_NAME iso [OPTIONEN] [ZIEL]${C_OFF}

${C_MISC}ZIEL                    Zielpfad der ISO: Datei (endet auf ${C_FILE}.iso${C_MISC}) oder
                        Verzeichnis (dort landet ${C_FILE}ubuntulive.iso${C_MISC}).
                        Ohne Angabe: <Arbeitsverzeichnis>/ubuntulive.iso

Optionen:
  ${C_FILE}-w, --work VERZ${C_OFF}       ${C_MISC}Arbeitsverzeichnis für den Bau [Standard: ~/remastern]
  ${C_FILE}-o, --output PFAD${C_OFF}     ${C_MISC}Zielpfad/Verzeichnis der ISO (wie ZIEL)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}Volume-Label der ISO [Standard: UBUNTULIVE]
                        (max. 32 Zeichen, A-Z 0-9 . _ -)
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}SquashFS-Kompression: xz, zstd, lzma,
                        gzip, lzo, lz4 [Standard: zstd, im Script einstellbar
                        über SQUASH_COMP=...]
  ${C_FILE}-e, --exclude PFADE${C_OFF}   ${C_MISC}Zusätzliche Ausschlüsse, leerzeichengetrennt,
                        z. B. ${C_FILE}-e "/home/user/Daten /opt/gross"${C_MISC}
  ${C_FILE}-nc, --no-color${C_OFF}            ${C_MISC}Farben abschalten
  ${C_FILE}-h, --help${C_OFF}            ${C_MISC}diese Hilfe

Beispiele:
  ${C_FILE}$SCRIPT_NAME iso /srv/iso/test.iso${C_MISC}
  ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_MISC}
HILFE
            ;;
    esac
}

# ============================================================
# Befehls-Zerlegung
# ============================================================

cmd_iso() {
    local iso_target="" excl_input=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage_iso; exit 0 ;;
            -w|--work)
                if [[ $# -lt 2 ]]; then err "$(t err_need_dir "$1")"; usage_iso; exit 2; fi
                WORK="$2"; shift 2 ;;
            -o|--output)
                if [[ $# -lt 2 ]]; then err "$(t err_need_path "$1")"; usage_iso; exit 2; fi
                OUT="$2"; shift 2 ;;
            -l|--label)
                if [[ $# -lt 2 ]]; then err "$(t err_need_label "$1")"; usage_iso; exit 2; fi
                ISO_LABEL="$2"; shift 2 ;;
            -c|--compression)
                if [[ $# -lt 2 ]]; then err "$(t err_need_algo "$1")"; usage_iso; exit 2; fi
                SQUASH_COMP="$2"; shift 2 ;;
            -e|--exclude)
                if [[ $# -lt 2 ]]; then err "$(t err_need_excludes "$1")"; usage_iso; exit 2; fi
                excl_input="$2"
                if [[ -n "$excl_input" ]]; then
                    local -a parsed=()
                    read -r -a parsed <<< "$excl_input"
                    EXTRA_EXCLUDES+=("${parsed[@]}")
                fi
                shift 2 ;;
            -de|-en) shift ;;
            --no-color) shift ;;
            -*)
                err "$(t err_unknown_opt "$1" "$SCRIPT_NAME iso -h")"
                usage_iso
                exit 2 ;;
            *)
                if [[ -n "$iso_target" ]]; then
                    err "$(t err_iso_one_target)"
                    exit 2
                fi
                iso_target="$1"; shift ;;
        esac
    done
    if [[ -n "$iso_target" ]]; then
        OUT="$iso_target"
    fi

    INTERACTIVE="n"
    do_iso_build
}

cmd_install() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage_install; exit 0 ;;
            -d|--disk)
                if [[ $# -lt 2 ]]; then err "$(t err_need_device "$1")"; usage_install; exit 2; fi
                DISK="$2"; shift 2 ;;
            -y|--yes) ASSUME_YES="j"; shift ;;
            -de|-en) shift ;;
            --no-color) shift ;;
            *)
                err "$(t err_unknown_arg "$1" "$SCRIPT_NAME install -h")"
                usage_install
                exit 2 ;;
        esac
    done

    require_root
    INTERACTIVE="n"

    if [[ -z "$DISK" && -t 0 ]]; then
        INTERACTIVE="j"
        choose_install_target || exit 3
    fi

    do_install
}

cmd_part() {
    require_root
    INTERACTIVE="j"
    part_menu
}

cmd_cleanup() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w|--work)
                if [[ $# -lt 2 ]]; then err "$(t err_need_dir "$1")"; usage; exit 2; fi
                WORK="$2"; shift 2 ;;
            -de|-en) shift ;;
            --no-color) shift ;;
            -h|--help) usage; exit 0 ;;
            *)
                err "$(t err_unknown_arg "$1" "$SCRIPT_NAME -h")"
                exit 2 ;;
        esac
    done
    do_iso_cleanup
}

cmd_targets() {
    show_targets
}

# ============================================================
# main
# ============================================================

main() {
    local cmd="menu"
    local -a rest=()
    local a
    for a in "$@"; do
        case "$a" in
            -de|-en) ;;
            *) rest+=("$a") ;;
        esac
    done
    set -- "${rest[@]}"
    if [[ $# -gt 0 ]]; then
        cmd="$1"
        shift
    fi

    case "$cmd" in
        --action)
            if [[ -n "${1:-}" ]]; then
                run_action "$1"
                exit $?
            fi
            usage
            exit 2 ;;
        menu)                       main_menu ;;
        iso)                        cmd_iso "$@" ;;
        install)                    cmd_install "$@" ;;
        part|partition|partitioner) cmd_part ;;
        cleanup)                    cmd_cleanup "$@" ;;
        targets|ziele)              cmd_targets ;;
        export|scripts|skripte)     cmd_export "$@" ;;
        -x|--extract)
            if [[ $# -lt 1 ]]; then
                err "$(t err_need_dir "$cmd")"
                usage
                exit 2
            fi
            cmd_export -s 1,2,3 -o "$1" ;;
        help|-h|--help)             usage; exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        --no-color)
            main_menu ;;
        *)
            err "$(t err_unknown_cmd "$cmd")"
            usage
            exit 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
#@@@END:ubuntu/ubuntulive-tool@@@
#@@@SCRIPT:debian/debianlive-tool@@@
#!/usr/bin/env bash
#
# debianlive-tool 1.2 - Debian-Live-ISO bauen + gebootetes Live-System
# installieren (Debian-Fork von debianlive-tool 3.1: live-boot wurde durch
# live-boot/live-config/live-tools ersetzt - Kernel-Parameter boot=live,
# ISO-Ordner /live/, Live-Autologin ueber live-config-Boot-Parameter)
#                       + interaktiver Partitionierer (sfdisk-Basis)
#
# Zweck:
#   Ein einziges Werkzeug für alle Aufgaben rund um die eigene Debian-Live-ISO:
#     - Live-ISO vom LAUFENDEN System erstellen (BIOS + UEFI bootbar, live-boot)
#     - das gebootete Live-System auf Festplatte oder Partition installieren
#       (inkl. GRUB, BIOS + UEFI automatisch erkannt)
#     - Festplatten interaktiv partitionieren (Zahlen-Auswahl)
#
# Verwendung:
#   debianlive-tool                       interaktives Hauptmenü
#   debianlive-tool iso [OPTIONEN] [ZIEL] Live-ISO erstellen
#   debianlive-tool install -d GERÄT [-y] Live-System installieren
#   debianlive-tool part                  Partitionierer (interaktiv)
#   debianlive-tool cleanup [-w VERZ]     ISO-Bau-Artefakte entfernen
#   debianlive-tool targets               mögliche Installationsziele zeigen
#   debianlive-tool export [-s 1,2,3] [-o VERZ]
#                                         Teile als Einzelskripte ausgeben
#   debianlive-tool help | -V             Hilfe / Version
#
# Benötigte Tools:
#   bash >= 4.4, GNU coreutils, util-linux (Pakete util-linux/fdisk), udev,
#   je nach Aktion apt-get, squashfs-tools, grub-common + grub-pc-bin +
#   grub-efi-amd64-bin, xorriso, mtools, live-boot + live-config + live-tools + initramfs-tools (werden
#   bei Bedarf nachinstalliert), dosfstools/e2fsprogs/ntfs-3g fürs Formatieren.
#
# Exit-Codes:
#   0  Erfolg
#   2  Falsche Argumente / unbekannter Befehl (Usage wird ausgegeben)
#   3  Fataler Fehler ("die") oder Abbruch durch den Benutzer
#   130/143/129  SIGINT/SIGTERM/SIGHUP (Aufräumarbeiten laufen vorher)
#
# Farben: Überschriften hell-cyan, Text hell-gelb, Dateien/Pfade hell-lila,
#         alles andere hell-grün (Fehler rot). Abschaltbar mit --no-color
#         oder der Umgebungsvariable NO_COLOR.
#
# Zweisprachig DE/EN: Sprache oben über SPRACHE einstellbar (AUTO = Systemsprache).
# -de/-en-Flags und language.ini (sprache=de|en) setzen die Sprache ebenfalls.
#
set -euo pipefail

VERSION="1.5"
SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || true)"
if [[ -z "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$0"
fi
ORIG_ARGS=("$@")
SCRIPT_NAME="${ULTOOL_SELF_NAME:-$(basename -- "$0")}"

# ==================== SPRACHE / LANGUAGE ====================
# Sprache aller Meldungen: AUTO (Systemsprache, Voreinstellung), DE oder EN.
# Zum Festlegen den Wert unten eintragen, z. B.:  SPRACHE=DE   bzw.   SPRACHE=EN
# Startet man das Skript aus der LinuxLiveTool-GUI, gewinnt die dort gewaehlte
# Sprache (Umgebungsvariable LLT_LANG = DE oder EN) ueber dieser Einstellung.
SPRACHE=DE
case "${LLT_LANG:-}" in
    DE|EN) SPRACHE="$LLT_LANG" ;;
esac

# Kompatibilitaet: die Flags -de/-en setzen die Sprache explizit.
SPRACHE_GESETZT="n"
for a in "$@"; do
    case "$a" in
        -de) SPRACHE=DE; SPRACHE_GESETZT="j" ;;
        -en) SPRACHE=EN; SPRACHE_GESETZT="j" ;;
    esac
done

# language.ini (Legacy): die Marker-Zeile in Zeile 1 erkennt die eigene
# Sprachdatei; sie setzt nur noch die Sprache (sprache=de|en).
if [[ "$SPRACHE_GESETZT" == "n" && -z "${LLT_LANG:-}" ]]; then
    ini_kandidat="$(dirname -- "$SCRIPT_PATH")/language.ini"
    if [[ -f "$ini_kandidat" ]] \
        && [[ "$(head -n1 -- "$ini_kandidat" 2>/dev/null)" == "[debianlive-tool-sprache]" ]]; then
        ini_code="$(sed -n 's/^[[:space:]]*sprache=[[:space:]]*//p' -- "$ini_kandidat" | head -n1)"
        case "${ini_code,,}" in
            de) SPRACHE=DE ;;
            en) SPRACHE=EN ;;
        esac
    fi
fi
case "$SPRACHE" in
    AUTO) case "${LC_ALL:-${LANG:-}}" in de*|DE*) SPRACHE=DE ;; *) SPRACHE=EN ;; esac ;;
esac

# Textkatalog: alle Meldungen in DE und EN (keine Extradatei).
#   t  KEY [ARGS...]  -> Meldung nach stdout
#   te KEY [ARGS...]  -> Meldung nach stderr
#   td KEY [ARGS...]  -> Meldung nach stderr + Abbruch (exit 1)
# ARGS werden per printf %s in die Meldung eingesetzt (%s-Platzhalter im Text).
t() {
    local key=$1; shift
    case "$key:$SPRACHE" in
    word_error:EN) printf '%s\n' "ERROR" ;;
    word_error:*)  printf '%s\n' "FEHLER" ;;
    word_warning:EN) printf '%s\n' "Warning" ;;
    word_warning:*)  printf '%s\n' "Warnung" ;;
    word_unknown:EN) printf '%s\n' "unknown" ;;
    word_unknown:*)  printf '%s\n' "unbekannt" ;;
    word_label:EN) printf '%s\n' "label" ;;
    word_label:*)  printf '%s\n' "Label" ;;
    word_mounted:EN) printf '%s\n' "mounted" ;;
    word_mounted:*)  printf '%s\n' "eingehängt" ;;
    word_current:EN) printf '%s\n' "currently" ;;
    word_current:*)  printf '%s\n' "aktuell" ;;
    word_mounted_protected:EN) printf '%s\n' "MOUNTED - delete-protected" ;;
    word_mounted_protected:*)  printf '%s\n' "EINGEHÄNGT - löschgeschützt" ;;
    word_raw:EN) printf '%s\n' "raw" ;;
    word_raw:*)  printf '%s\n' "roh" ;;
    word_no_table:EN) printf '%s\n' "no table" ;;
    word_no_table:*)  printf '%s\n' "keine Tabelle" ;;
    word_not_detected:EN) printf '%s\n' "NOT DETECTED" ;;
    word_not_detected:*)  printf '%s\n' "NICHT ERKANNT" ;;
    word_workdir:EN) printf '%s\n' "Work directory" ;;
    word_workdir:*)  printf '%s\n' "Arbeitsverzeichnis" ;;
    word_output_dir:EN) printf '%s\n' "Output directory" ;;
    word_output_dir:*)  printf '%s\n' "Ausgabeordner" ;;
    word_partitioner:EN) printf '%s\n' "Partitioner" ;;
    word_partitioner:*)  printf '%s\n' "Partitionierer" ;;
    menu_choice:EN) printf '%s\n' "Choice " ;;
    menu_choice:*)  printf '%s\n' "Auswahl " ;;
    menu_abort_quit:EN) printf '%s\n' "0=Back, 00=Quit" ;;
    menu_abort_quit:*)  printf '%s\n' "0=Abbrechen, 00=Ende" ;;
    menu_enter_number:EN) printf '%s\n' "Please enter a NUMBER." ;;
    menu_enter_number:*)  printf '%s\n' "Bitte eine ZAHL eingeben." ;;
    menu_invalid_number:EN) printf 'Invalid number (1-%s).\n'  "$1" ;;
    menu_invalid_number:*) printf 'Ungültige Nummer (1-%s).\n'  "$1" ;;
    menu_main_title:EN) printf '%s %s - main menu\n'  "$1" "$2" ;;
    menu_main_title:*) printf '%s %s - Hauptmenü\n'  "$1" "$2" ;;
    menu_main_iso:EN) printf '%s\n' "Create live ISO from the running system" ;;
    menu_main_iso:*)  printf '%s\n' "Live-ISO vom laufenden System erstellen" ;;
    menu_main_install:EN) printf '%s\n' "Install the live system to disk/partition" ;;
    menu_main_install:*)  printf '%s\n' "Live-System auf Festplatte/Partition installieren" ;;
    menu_main_part:EN) printf '%s\n' "Open the partitioner (manage disks/partitions)" ;;
    menu_main_part:*)  printf '%s\n' "Partitionierer öffnen (Platten/Partitionen verwalten)" ;;
    menu_main_cleanup:EN) printf '%s\n' "Cleanup (remove ISO build artifacts)" ;;
    menu_main_cleanup:*)  printf '%s\n' "Aufräumen (ISO-Bau-Artefakte entfernen)" ;;
    menu_main_targets:EN) printf '%s\n' "Show possible installation targets" ;;
    menu_main_targets:*)  printf '%s\n' "Mögliche Installationsziele anzeigen" ;;
    menu_main_export:EN) printf '%s\n' "Export individual scripts (partitioner/ISO/installation)" ;;
    menu_main_export:*)  printf '%s\n' "Einzelskripte exportieren (Partitionierer/ISO/Installation)" ;;
    q_jn:EN) printf '%s\n' "Y/n" ;;
    q_jn:*)  printf '%s\n' "J/n" ;;
    q_jn_lower:EN) printf '%s\n' "Y/n" ;;
    q_jn_lower:*)  printf '%s\n' "j/n" ;;
    q_confirm_continue:EN) printf '%s\n' "Confirm to continue" ;;
    q_confirm_continue:*)  printf '%s\n' "Zum Fortfahren bestätigen" ;;
    q_empty_abort:EN) printf '%s\n' "Aborted (empty input)." ;;
    q_empty_abort:*)  printf '%s\n' "Abgebrochen (leere Eingabe)." ;;
    q_yes_no_please:EN) printf '%s\n' "Please answer y (yes) or n (no)." ;;
    q_yes_no_please:*)  printf '%s\n' "Bitte j (ja) oder n (nein) antworten." ;;
    q_tool_missing_install:EN) printf '%s is missing (package %s). Install now via apt-get?\n'  "$1" "$2" ;;
    q_tool_missing_install:*) printf '%s fehlt (Paket %s). Jetzt per apt-get nachinstallieren?\n'  "$1" "$2" ;;
    q_install_now:EN) printf '%s\n' "Install now via apt-get?" ;;
    q_install_now:*)  printf '%s\n' "Jetzt per apt-get nachinstallieren?" ;;
    q_format_now:EN) printf 'Format with %s now?\n'  "$1" ;;
    q_format_now:*) printf 'Jetzt mit %s formatieren?\n'  "$1" ;;
    q_iso_label:EN) printf '%s\n' "Volume label (max. 32 characters, A-Z 0-9 . _ -)" ;;
    q_iso_label:*)  printf '%s\n' "Volume-Label (max. 32 Zeichen, A-Z 0-9 . _ -)" ;;
    q_iso_target:EN) printf '%s\n' "ISO target (.iso file or directory, empty = <work directory>/debianlive.iso)" ;;
    q_iso_target:*)  printf '%s\n' "ISO-Ziel (Datei .iso oder Verzeichnis, leer = <Arbeitsverzeichnis>/debianlive.iso)" ;;
    q_iso_excludes:EN) printf '%s\n' "Additional exclusions (space separated, empty = none)" ;;
    q_iso_excludes:*)  printf '%s\n' "Zusätzliche Ausschlüsse (leerzeichengetrennt, leer = keine)" ;;
    q_iso_start_build:EN) printf '%s\n' "Start the ISO build now (several GB, takes a long time)?" ;;
    q_iso_start_build:*)  printf '%s\n' "ISO-Bau jetzt starten (mehrere GB, dauert lange)?" ;;
    q_iso_cleanup:EN) printf 'Really remove build artifacts in %s?\n'  "$1" ;;
    q_iso_cleanup:*) printf 'Build-Artefakte in %s wirklich entfernen?\n'  "$1" ;;
    q_iso_liveboot_restore:EN) printf '%s\n' "Restore live-boot files from the current live-boot package (network required)?" ;;
    q_iso_liveboot_restore:*)  printf '%s\n' "live-boot-Dateien aus dem aktuellen live-boot-Paket wiederherstellen (Netzwerk nötig)?" ;;
    q_exp_overwrite:EN) printf "At least one target file already exists in '%s' - overwrite?\n"  "$1" ;;
    q_exp_overwrite:*) printf "Mindestens eine Zieldatei existiert in '%s' - überschreiben?\n"  "$1" ;;
    info_done:EN) printf '%s\n' "Done." ;;
    info_done:*)  printf '%s\n' "Ende." ;;
    info_aborted:EN) printf '%s\n' "Aborted." ;;
    info_aborted:*)  printf '%s\n' "Abgebrochen." ;;
    info_press_enter:EN) printf '%s\n' "[Press Enter to continue]" ;;
    info_press_enter:*)  printf '%s\n' "[Weiter mit Enter]" ;;
    info_requesting_root:EN) printf '%s\n' "Requesting root privileges (sudo)..." ;;
    info_requesting_root:*)  printf '%s\n' "Fordere Root-Rechte an (sudo)..." ;;
    info_nothing_changed:EN) printf '%s\n' "Aborted - nothing changed." ;;
    info_nothing_changed:*)  printf '%s\n' "Abgebrochen - nichts verändert." ;;
    info_installing_pkg:EN) printf 'Installing package %s (network required)...\n'  "$1" ;;
    info_installing_pkg:*) printf 'Installiere Paket %s (Netzwerk nötig)...\n'  "$1" ;;
    info_retry_apt_update:EN) printf '%s\n' "Retrying with 'apt-get update' (refreshing the package database)..." ;;
    info_retry_apt_update:*)  printf '%s\n' "Neuer Versuch mit 'apt-get update' (Paketdatenbank auffrischen)..." ;;
    info_tool_now_available:EN) printf '%s is now available.\n'  "$1" ;;
    info_tool_now_available:*) printf '%s ist jetzt verfügbar.\n'  "$1" ;;
    info_remove_autologin:EN) printf '%s\n' "Removing autologin configuration - the fresh system starts with the login screen." ;;
    info_remove_autologin:*)  printf '%s\n' "Entferne Autologin-Konfiguration - das frische System startet mit dem Login-Bildschirm." ;;
    info_remove_live_user:EN) printf "Removing live session user '%s' (blank password, sudo grant sudoers.d/live-boot).\n"  "$1" ;;
    info_remove_live_user:*) printf "Entferne Live-Sitzungs-Benutzer '%s' (leeres Passwort, sudo-Freischaltung sudoers.d/live-boot).\n"  "$1" ;;
    info_remove_liveboot_divert_initrd:EN) printf '%s\n' "Removing the live-boot diversion of update-initramfs (otherwise initramfs builds and kernel updates have no effect)." ;;
    info_remove_liveboot_divert_initrd:*)  printf '%s\n' "Entferne live-boot-Divert von update-initramfs (sonst bleiben Initramfs-Bau und Kernel-Updates wirkungslos)." ;;
    info_remove_liveboot_divert_anacron:EN) printf '%s\n' "Removing the live-boot diversion of anacron (live system)." ;;
    info_remove_liveboot_divert_anacron:*)  printf '%s\n' "Entferne live-boot-Divert von anacron (Live-System)." ;;
    info_kernel_cmdline:EN) printf '%s\n' "Kernel command line:" ;;
    info_kernel_cmdline:*)  printf '%s\n' "Kernel command line:" ;;
    warn_ctx_aborted:EN) printf '%s aborted - %s is still missing.\n'  "$1" "$2" ;;
    warn_ctx_aborted:*) printf '%s abgebrochen - %s fehlt weiterhin.\n'  "$1" "$2" ;;
    warn_fat32_few_clusters:EN) printf 'FAT32: only %s clusters (small volume) - creating it anyway.\n'  "$1" ;;
    warn_fat32_few_clusters:*) printf 'FAT32: nur %s Cluster (kleines Volume) - wird trotzdem angelegt.\n'  "$1" ;;
    warn_part_multi_gaps:EN) printf '%s\n' "Multiple free areas - automatically using the largest." ;;
    warn_part_multi_gaps:*)  printf '%s\n' "Mehrere freie Bereiche - verwende automatisch den größten." ;;
    warn_part_dev_not_yet:EN) printf 'Device node %s has not appeared yet (waiting for udev).\n'  "$1" ;;
    warn_part_dev_not_yet:*) printf 'Gerätedatei %s ist noch nicht erschienen (udev braucht momentan).\n'  "$1" ;;
    warn_part_created_anyway:EN) printf '%s\n' "sfdisk reported an error; the partition is nevertheless on the disk. sfdisk reports:" ;;
    warn_part_created_anyway:*)  printf '%s\n' "sfdisk meldete einen Fehler; die Partition liegt aber auf der Platte. sfdisk meldet:" ;;
    warn_part_newtable_wipe:EN) printf 'ATTENTION: ALL partitions and data on %s will be deleted!\n'  "$1" ;;
    warn_part_newtable_wipe:*) printf 'ACHTUNG: ALLE Partitionen und Daten auf %s werden gelöscht!\n'  "$1" ;;
    warn_part_delete_wipe:EN) printf 'Partition %s is being DELETED - all data on it is irretrievably lost!\n'  "$1" ;;
    warn_part_delete_wipe:*) printf 'Partition %s wird GELÖSCHT - alle Daten darauf sind unwiederbringlich verloren!\n'  "$1" ;;
    warn_part_format_wipe:EN) printf '%s is being formatted with %s - ALL data on it will be lost!\n'  "$1" "$2" ;;
    warn_part_format_wipe:*) printf '%s wird mit %s formatiert - ALLE Daten darauf gehen verloren!\n'  "$1" "$2" ;;
    warn_part_live_excluded:EN) printf 'Live medium %s is excluded from the selection.\n'  "$1" ;;
    warn_part_live_excluded:*) printf 'Live-Medium %s ist von der Auswahl ausgeschlossen.\n'  "$1" ;;
    warn_inst_live_unknown:EN) printf '%s\n' "The live medium could not be determined automatically." ;;
    warn_inst_live_unknown:*)  printf '%s\n' "Das Live-Medium konnte nicht automatisch bestimmt werden." ;;
    warn_inst_moddir_missing:EN) printf '%s/%s does not exist.\n'  "$1" "$2" ;;
    warn_inst_moddir_missing:*) printf '%s/%s existiert nicht.\n'  "$1" "$2" ;;
    warn_inst_uefi_std_failed:EN) printf '%s\n' "Standard UEFI installation (EFI/debian + NVRAM entry) failed -
using the portable fallback path EFI/BOOT without an NVRAM entry." ;;
    warn_inst_uefi_std_failed:*)  printf '%s\n' "Standard-UEFI-Installation (EFI/debian + NVRAM-Eintrag) fehlgeschlagen -
verwende den portablen Fallback-Pfad EFI/BOOT ohne NVRAM-Eintrag." ;;
    warn_inst_uefi_portable_failed:EN) printf '%s\n' "Portable EFI/BOOT path could not be created -
the standard path EFI/debian is installed anyway." ;;
    warn_inst_uefi_portable_failed:*)  printf '%s\n' "Portabler EFI/BOOT-Pfad konnte nicht angelegt werden -
der Standardpfad EFI/debian ist trotzdem installiert." ;;
    warn_secure_boot:EN) printf '%s\n' "Disable Secure Boot in the UEFI (GRUB is unsigned, just like the live ISO)." ;;
    warn_secure_boot:*)  printf '%s\n' "Secure Boot im UEFI deaktivieren (GRUB ist nicht signiert, wie schon die Live-ISO)." ;;
    warn_iso_mount_blocked:EN) printf "'%s' is blocked. These processes are holding it:\n"  "$1" ;;
    warn_iso_mount_blocked:*) printf "'%s' blockiert. Diese Prozesse halten es fest:\n"  "$1" ;;
    warn_iso_lazy_umount:EN) printf "'%s' was unmounted lazily.\n"  "$1" ;;
    warn_iso_lazy_umount:*) printf "'%s' wurde verzögert (lazy) ausgehängt.\n"  "$1" ;;
    warn_iso_user_unknown:EN) printf "User '%s' not found - ownership was not changed.\n"  "$1" ;;
    warn_iso_user_unknown:*) printf "Benutzer '%s' nicht gefunden - Eigentümer wurde nicht geändert.\n"  "$1" ;;
    warn_iso_no_unmkinitramfs:EN) printf '%s\n' "unmkinitramfs missing - structural initramfs check skipped (provided by package initramfs-tools)." ;;
    warn_iso_no_unmkinitramfs:*)  printf '%s\n' "unmkinitramfs fehlt - strukturelle Initramfs-Prüfung übersprungen (Paket initramfs-tools bringt es)." ;;
    warn_iso_low_space:EN) printf 'Only about %s GB free in %s - roughly 8 GB recommended.\n'  "$1" "$2" ;;
    warn_iso_low_space:*) printf 'Nur ca. %s GB frei in %s - grob 8 GB empfohlen.\n'  "$1" "$2" ;;
    warn_iso_kernel_no_modules:EN) printf '%s\n' "Running kernel %s has NO modules (only metadata - typically after
a kernel update without reboot). Using kernel %s instead (modules present)." "$1" "$2" ;;
    warn_iso_kernel_no_modules:*)  printf '%s\n' "Laufender Kernel %s hat KEINE Module (nur Metadaten - typisch nach
Kernel-Update ohne Neustart). Verwende stattdessen Kernel %s (Module vorhanden)." "$1" "$2" ;;
    warn_iso_no_live_user:EN) printf '%s\n' "No user of the secured system could be determined - the live system starts with the login screen without autologin." ;;
    warn_iso_no_live_user:*)  printf '%s\n' "Kein Benutzer des gesicherten Systems ermittelbar - das Live-System startet ohne Autologin in den Login-Bildschirm." ;;
    warn_iso_no_sddm_session:EN) printf '%s\n' "No default SDDM session could be determined - the live autologin may fail (login screen). Please start the desired session once on the source system so that /var/lib/sddm/state.conf records it." ;;
    warn_iso_no_sddm_session:*)  printf '%s\n' "Keine Standard-SDDM-Sitzung ermittelbar - der Live-Autologin kann scheitern (Login-Bildschirm). Bitte im Quellsystem einmal die gewünschte Sitzung starten, damit /var/lib/sddm/state.conf sie festhält." ;;
    warn_iso_own_partitions:EN) printf '%s\n' "These directories are separate partitions and will NOT be in the image:" ;;
    warn_iso_own_partitions:*)  printf '%s\n' "Diese Verzeichnisse sind eigene Partitionen und landen NICHT im Abbild:" ;;
    warn_iso_no_network:EN) printf '%s\n' "Neither NetworkManager nor systemd-networkd in the image - live networking then depends on
the network configuration of the source system (often MAC-bound) and may only work on identical hardware." ;;
    warn_iso_no_network:*)  printf '%s\n' "NetworkManager und systemd-networkd fehlen im Abbild - Live-Netzwerk hängt an der
Netzwerkkonfiguration des Quell-Systems (oft MAC-gebunden) und funktioniert evtl. nur auf identischer Hardware." ;;
    warn_iso_manifest:EN) printf '%s\n' "Manifest could not be created." ;;
    warn_iso_manifest:*)  printf '%s\n' "Manifest konnte nicht erstellt werden." ;;
    warn_iso_secure_boot:EN) printf '%s\n' "ISO is not Secure-Boot signed -> disable Secure Boot in the UEFI." ;;
    warn_iso_secure_boot:*)  printf '%s\n' "ISO nicht Secure-Boot-signiert -> Secure Boot im UEFI deaktivieren." ;;
    warn_iso_arch:EN) printf 'Architecture %s - BIOS boot may not be available; ISO may be UEFI-bootable only.\n'  "$1" ;;
    warn_iso_arch:*) printf 'Architektur %s - BIOS-Boot steht evtl. nicht bereit; ISO ggf. nur UEFI-bootbar.\n'  "$1" ;;
    err_fat32_sector_size:EN) printf 'FAT32: sector size %s is not supported.\n'  "$1" ;;
    err_fat32_sector_size:*) printf 'FAT32: Sektorgröße %s wird nicht unterstützt.\n'  "$1" ;;
    err_fat32_size_unknown:EN) printf 'FAT32: could not determine the size of %s.\n'  "$1" ;;
    err_fat32_size_unknown:*) printf 'FAT32: Größe von %s konnte nicht ermittelt werden.\n'  "$1" ;;
    err_fat32_too_large:EN) printf 'FAT32: device too large for FAT32 (%s bytes).\n'  "$1" ;;
    err_fat32_too_large:*) printf 'FAT32: Gerät zu groß für FAT32 (%s Bytes).\n'  "$1" ;;
    err_fat32_cluster_invalid:EN) printf 'FAT32: cluster size invalid for sector size %s.\n'  "$1" ;;
    err_fat32_cluster_invalid:*) printf 'FAT32: Clustergröße für Sektorgröße %s ungültig.\n'  "$1" ;;
    err_fat32_too_small:EN) printf '%s\n' "FAT32: device too small for a FAT32." ;;
    err_fat32_too_small:*)  printf '%s\n' "FAT32: Gerät zu klein für ein FAT32." ;;
    err_fat32_many_clusters:EN) printf 'FAT32: too many clusters (%s).\n'  "$1" ;;
    err_fat32_many_clusters:*) printf 'FAT32: zu viele Cluster (%s).\n'  "$1" ;;
    err_fat32_create_failed:EN) printf 'FAT32 could not be created on %s.\n'  "$1" ;;
    err_fat32_create_failed:*) printf 'FAT32 konnte auf %s nicht angelegt werden.\n'  "$1" ;;
    err_dev_mounted_unplug:EN) printf '%s is mounted - unmount it first.\n'  "$1" ;;
    err_dev_mounted_unplug:*) printf '%s ist eingehängt - bitte zuerst aushängen.\n'  "$1" ;;
    err_mkfs_ext4_missing:EN) printf '%s\n' "mkfs.ext4 missing (package e2fsprogs) - cannot format ext4." ;;
    err_mkfs_ext4_missing:*)  printf '%s\n' "mkfs.ext4 fehlt (Paket e2fsprogs) - ext4 kann nicht formatiert werden." ;;
    err_mkswap_missing:EN) printf '%s\n' "mkswap missing (package util-linux)." ;;
    err_mkswap_missing:*)  printf '%s\n' "mkswap fehlt (Paket util-linux)." ;;
    err_mkfs_ntfs_missing:EN) printf '%s\n' "mkfs.ntfs missing (package ntfs-3g) - cannot format NTFS." ;;
    err_mkfs_ntfs_missing:*)  printf '%s\n' "mkfs.ntfs fehlt (Paket ntfs-3g) - NTFS kann nicht formatiert werden." ;;
    err_format_fat32_failed:EN) printf 'Formatting %s with FAT32 failed.\n'  "$1" ;;
    err_format_fat32_failed:*) printf 'Formatieren von %s mit FAT32 fehlgeschlagen.\n'  "$1" ;;
    info_fs_vfat_builtin:EN) printf 'Filesystem vfat (FAT32) created on %s (built-in formatter).\n'  "$1" ;;
    info_fs_vfat_builtin:*) printf 'Dateisystem vfat (FAT32) auf %s angelegt (eingebauter Formatierer).\n'  "$1" ;;
    info_formatting:EN) printf 'Formatting %s with %s ...\n'  "$1" "$2" ;;
    info_formatting:*) printf 'Formatiere %s mit %s ...\n'  "$1" "$2" ;;
    info_fs_created:EN) printf 'Filesystem %s created on %s.\n'  "$1" "$2" ;;
    info_fs_created:*) printf 'Dateisystem %s auf %s angelegt.\n'  "$1" "$2" ;;
    err_format_failed:EN) printf 'Formatting %s with %s failed.\n'  "$1" "$2" ;;
    err_format_failed:*) printf 'Formatieren von %s mit %s fehlgeschlagen.\n'  "$1" "$2" ;;
    info_fat32_builtin:EN) printf 'FAT32 (built-in): cluster %s bytes, %s clusters, 2 FATs of %s KiB\n'  "$1" "$2" "$3" ;;
    info_fat32_builtin:*) printf 'FAT32 (eingebaut): Cluster %s Bytes, %s Cluster, 2 FATs à %s KiB\n'  "$1" "$2" "$3" ;;
    err_tool_install_failed:EN) printf '%s\n' "%s could not be installed (package %s).
Check the network - inside the live system 'apt-get update' usually helps." "$1" "$2" ;;
    err_tool_install_failed:*)  printf '%s\n' "%s konnte nicht installiert werden (Paket %s).
Netzwerk prüfen - im Live-System hilft meist 'apt-get update'." "$1" "$2" ;;
    err_tool_install_failed_short:EN) printf '%s could not be installed (package %s).\n'  "$1" "$2" ;;
    err_tool_install_failed_short:*) printf '%s konnte nicht installiert werden (Paket %s).\n'  "$1" "$2" ;;
    err_action_failed:EN) printf '%s\n' "Action failed/aborted - back to the menu." ;;
    err_action_failed:*)  printf '%s\n' "Aktion fehlgeschlagen/abgebrochen - zurück zum Menü." ;;
    part_overview_title:EN) printf 'Overview: %s\n'  "$1" ;;
    part_overview_title:*) printf 'Übersicht: %s\n'  "$1" ;;
    err_part_no_table:EN) printf 'No partition table on %s.\n'  "$1" ;;
    err_part_no_table:*) printf 'Keine Partitionstabelle auf %s.\n'  "$1" ;;
    info_part_use_menu2:EN) printf '%s\n' "Use menu item 2 to create a new table (GPT or MBR)." ;;
    info_part_use_menu2:*)  printf '%s\n' "Über Menüpunkt 2 eine neue Tabelle anlegen (GPT oder MBR)." ;;
    part_table_info:EN) printf 'Table: %s   Sector size: %s B\n'  "$1" "$2" ;;
    part_table_info:*) printf 'Tabelle: %s   Sektorgröße: %s B\n'  "$1" "$2" ;;
    part_free_areas:EN) printf '%s\n' "  Free areas:" ;;
    part_free_areas:*)  printf '%s\n' "  Freie Bereiche:" ;;
    part_gap_line:EN) printf '     %s free - %s\n'  "$1" "$2" ;;
    part_gap_line:*) printf '     %s frei – %s\n'  "$1" "$2" ;;
    part_none:EN) printf '%s\n' "     (none)" ;;
    part_none:*)  printf '%s\n' "     (keine)" ;;
    part_gap_between:EN) printf 'between partitions %s and %s\n'  "$1" "$2" ;;
    part_gap_between:*) printf 'zwischen Partition %s und %s\n'  "$1" "$2" ;;
    part_gap_after:EN) printf 'after partition %s\n'  "$1" ;;
    part_gap_after:*) printf 'nach Partition %s\n'  "$1" ;;
    part_gap_before:EN) printf 'before partition %s\n'  "$1" ;;
    part_gap_before:*) printf 'vor Partition %s\n'  "$1" ;;
    part_gap_empty:EN) printf '%s\n' "on an empty disk" ;;
    part_gap_empty:*)  printf '%s\n' "auf leerer Platte" ;;
    part_newtable_title:EN) printf 'New partition table: %s\n'  "$1" ;;
    part_newtable_title:*) printf 'Neue Partitionstabelle: %s\n'  "$1" ;;
    part_choose_table:EN) printf '%s\n' "Choose partition table" ;;
    part_choose_table:*)  printf '%s\n' "Partitionstabelle wählen" ;;
    part_table_gpt:EN) printf '%s\n' "GPT (modern, for UEFI; any number of partitions)" ;;
    part_table_gpt:*)  printf '%s\n' "GPT (modern, für UEFI; beliebig viele Partitionen)" ;;
    part_table_mbr:EN) printf '%s\n' "MBR / msdos (classic, max. 4 primary)" ;;
    part_table_mbr:*)  printf '%s\n' "MBR / msdos (klassisch, max. 4 primäre)" ;;
    part_wiping_disk:EN) printf '%s\n' "Cleaning disk (wipefs)..." ;;
    part_wiping_disk:*)  printf '%s\n' "Säubere Platte (wipefs)..." ;;
    part_creating_gpt:EN) printf '%s\n' "Creating GPT..." ;;
    part_creating_gpt:*)  printf '%s\n' "Lege GPT an..." ;;
    err_gpt_failed:EN) printf '%s\n' "GPT could not be created - sfdisk reports:" ;;
    err_gpt_failed:*)  printf '%s\n' "GPT konnte nicht angelegt werden - sfdisk meldet:" ;;
    part_creating_mbr:EN) printf '%s\n' "Creating MBR (dos)..." ;;
    part_creating_mbr:*)  printf '%s\n' "Lege MBR (dos) an..." ;;
    err_mbr_failed:EN) printf '%s\n' "MBR could not be created - sfdisk reports:" ;;
    err_mbr_failed:*)  printf '%s\n' "MBR konnte nicht angelegt werden - sfdisk meldet:" ;;
    part_table_done:EN) printf '%s\n' "New partition table in place." ;;
    part_table_done:*)  printf '%s\n' "Neue Partitionstabelle steht." ;;
    part_create_title:EN) printf 'Create partition: %s\n'  "$1" ;;
    part_create_title:*) printf 'Partition erstellen: %s\n'  "$1" ;;
    err_part_no_table_first:EN) printf '%s\n' "No partition table - use menu item 2 first (new table)." ;;
    err_part_no_table_first:*)  printf '%s\n' "Keine Partitionstabelle - zuerst Menüpunkt 2 (neue Tabelle)." ;;
    part_purpose_linux:EN) printf '%s\n' "Linux data partition (ext4)" ;;
    part_purpose_linux:*)  printf '%s\n' "Linux-Datenpartition (ext4)" ;;
    part_purpose_esp:EN) printf '%s\n' "EFI system partition (FAT32, ESP, 512 MiB)" ;;
    part_purpose_esp:*)  printf '%s\n' "EFI-Systempartition (FAT32, ESP, 512 MiB)" ;;
    part_purpose_extended:EN) printf '%s\n' "Extended partition (container for logical)" ;;
    part_purpose_extended:*)  printf '%s\n' "Erweiterte Partition (Container für logische)" ;;
    part_purpose_swap:EN) printf '%s\n' "Swap" ;;
    part_purpose_swap:*)  printf '%s\n' "Swap" ;;
    part_purpose_ntfs:EN) printf '%s\n' "NTFS (Windows compatible)" ;;
    part_purpose_ntfs:*)  printf '%s\n' "NTFS (Windows-kompatibel)" ;;
    part_purpose_fat32:EN) printf '%s\n' "FAT32 (data)" ;;
    part_purpose_fat32:*)  printf '%s\n' "FAT32 (Daten)" ;;
    part_purpose_raw:EN) printf '%s\n' "No filesystem (raw)" ;;
    part_purpose_raw:*)  printf '%s\n' "Ohne Dateisystem (roh)" ;;
    part_choose_purpose:EN) printf '%s\n' "Purpose of the new partition" ;;
    part_choose_purpose:*)  printf '%s\n' "Zweck der neuen Partition" ;;
    err_part_no_free:EN) printf 'No free area on %s.\n'  "$1" ;;
    err_part_no_free:*) printf 'Kein freier Bereich auf %s.\n'  "$1" ;;
    part_gap_auto:EN) printf 'Free area (automatic): %s - %s\n'  "$1" "$2" ;;
    part_gap_auto:*) printf 'Freier Bereich (automatisch): %s – %s\n'  "$1" "$2" ;;
    err_part_gap_too_small:EN) printf '%s\n' "Free area too small - a 1 MiB reserve always stays free,
so at least 2 MiB (1 MiB partition + 1 MiB reserve) must be free." ;;
    err_part_gap_too_small:*)  printf '%s\n' "Freier Bereich zu klein - es bleiben immer 1 MiB Reserve frei,
daher müssen mindestens 2 MiB (1 MiB Partition + 1 MiB Reserve) frei sein." ;;
    part_q_size:EN) printf 'Size in MiB/GiB (empty = automatic, max. %s)\n'  "$1" ;;
    part_q_size:*) printf 'Größe in MiB/GiB (leer = automatisch, max. %s)\n'  "$1" ;;
    part_q_size_invalid:EN) printf '%s\n' "Invalid input - e.g. 512, 20G or 1.5T." ;;
    part_q_size_invalid:*)  printf '%s\n' "Ungültige Angabe - z. B. 512, 20G oder 1.5T." ;;
    err_part_size_no_fit:EN) printf '%s\n' "Size does not fit - at least 1 MiB always stays free
(max. %s in this area)." "$1" ;;
    err_part_size_no_fit:*)  printf '%s\n' "Größe passt nicht - es bleiben immer mindestens 1 MiB frei
(max. %s in diesem Bereich)." "$1" ;;
    err_part_mbr_slots_full:EN) printf '%s\n' "MBR: all 4 primary slots used and no extended partition present.
Create an 'extended partition' first, then logical partitions inside it." ;;
    err_part_mbr_slots_full:*)  printf '%s\n' "MBR: alle 4 primären Slots belegt und keine erweiterte Partition vorhanden.
Zuerst eine 'Erweiterte Partition' anlegen, dann logische Partitionen darin erstellen." ;;
    part_creating_line:EN) printf 'Creating partition: %s\n'  "$1" ;;
    part_creating_line:*) printf 'Lege Partition an: %s\n'  "$1" ;;
    err_part_create_failed:EN) printf '%s\n' "sfdisk could not create the partition - sfdisk reports:" ;;
    err_part_create_failed:*)  printf '%s\n' "sfdisk konnte die Partition nicht anlegen - sfdisk meldet:" ;;
    err_part_no_new_nr:EN) printf '%s\n' "Could not determine the new partition number." ;;
    err_part_no_new_nr:*)  printf '%s\n' "Neue Partitionsnummer konnte nicht ermittelt werden." ;;
    part_created:EN) printf 'Created: %s\n'  "$1" ;;
    part_created:*) printf 'Neu angelegt: %s\n'  "$1" ;;
    part_delete_title:EN) printf 'Delete partition: %s\n'  "$1" ;;
    part_delete_title:*) printf 'Partition löschen: %s\n'  "$1" ;;
    part_no_partitions:EN) printf '%s\n' "No partitions present." ;;
    part_no_partitions:*)  printf '%s\n' "Keine Partitionen vorhanden." ;;
    part_choose_delete:EN) printf '%s\n' "Partition to delete" ;;
    part_choose_delete:*)  printf '%s\n' "Zu löschende Partition" ;;
    err_part_mounted_nodelete:EN) printf '%s is mounted and cannot be deleted.\n'  "$1" ;;
    err_part_mounted_nodelete:*) printf '%s ist eingehängt und kann nicht gelöscht werden.\n'  "$1" ;;
    part_deleted:EN) printf '%s\n' "Partition deleted." ;;
    part_deleted:*)  printf '%s\n' "Partition gelöscht." ;;
    err_part_delete_failed:EN) printf '%s\n' "Deleting failed." ;;
    err_part_delete_failed:*)  printf '%s\n' "Löschen fehlgeschlagen." ;;
    part_format_title:EN) printf 'Format partition: %s\n'  "$1" ;;
    part_format_title:*) printf 'Partition formatieren: %s\n'  "$1" ;;
    part_no_formattable:EN) printf '%s\n' "No formattable partitions." ;;
    part_no_formattable:*)  printf '%s\n' "Keine formatierbaren Partitionen." ;;
    part_choose_format:EN) printf '%s\n' "Partition to format" ;;
    part_choose_format:*)  printf '%s\n' "Zu formatierende Partition" ;;
    err_dev_mounted:EN) printf '%s is mounted.\n'  "$1" ;;
    err_dev_mounted:*) printf '%s ist eingehängt.\n'  "$1" ;;
    part_choose_fs:EN) printf '%s\n' "Filesystem" ;;
    part_choose_fs:*)  printf '%s\n' "Dateisystem" ;;
    part_settype_title:EN) printf 'Set partition type: %s\n'  "$1" ;;
    part_settype_title:*) printf 'Partitionstyp setzen: %s\n'  "$1" ;;
    part_choose_partition:EN) printf '%s\n' "Partition" ;;
    part_choose_partition:*)  printf '%s\n' "Partition" ;;
    part_newtype_gpt:EN) printf '%s\n' "New type (GPT)" ;;
    part_newtype_gpt:*)  printf '%s\n' "Neuer Typ (GPT)" ;;
    part_type_esp:EN) printf '%s\n' "EFI system partition (ESP)" ;;
    part_type_esp:*)  printf '%s\n' "EFI-Systempartition (ESP)" ;;
    part_type_biosboot:EN) printf '%s\n' "BIOS boot partition (GRUB in BIOS mode)" ;;
    part_type_biosboot:*)  printf '%s\n' "BIOS-Boot-Partition (GRUB im BIOS-Modus)" ;;
    part_type_linux:EN) printf '%s\n' "Linux filesystem" ;;
    part_type_linux:*)  printf '%s\n' "Linux-Dateisystem" ;;
    part_type_linux_swap:EN) printf '%s\n' "Linux swap" ;;
    part_type_linux_swap:*)  printf '%s\n' "Linux-Swap" ;;
    part_type_msft:EN) printf '%s\n' "Microsoft Basic Data (Windows/NTFS)" ;;
    part_type_msft:*)  printf '%s\n' "Microsoft Basic Data (Windows/NTFS)" ;;
    part_type_lvm:EN) printf '%s\n' "Linux LVM" ;;
    part_type_lvm:*)  printf '%s\n' "Linux-LVM" ;;
    part_newtype_mbr:EN) printf '%s\n' "New type (MBR)" ;;
    part_newtype_mbr:*)  printf '%s\n' "Neuer Typ (MBR)" ;;
    part_type_linux83:EN) printf '%s\n' "Linux (83)" ;;
    part_type_linux83:*)  printf '%s\n' "Linux (83)" ;;
    part_type_efi_ef:EN) printf '%s\n' "EFI system (ef)" ;;
    part_type_efi_ef:*)  printf '%s\n' "EFI-System (ef)" ;;
    part_type_fat32lba:EN) printf '%s\n' "FAT32 LBA (0c)" ;;
    part_type_fat32lba:*)  printf '%s\n' "FAT32 LBA (0c)" ;;
    part_type_swap82:EN) printf '%s\n' "Swap (82)" ;;
    part_type_swap82:*)  printf '%s\n' "Swap (82)" ;;
    part_type_ntfs07:EN) printf '%s\n' "NTFS/HPFS (07)" ;;
    part_type_ntfs07:*)  printf '%s\n' "NTFS/HPFS (07)" ;;
    part_type_ext05:EN) printf '%s\n' "Extended (05)" ;;
    part_type_ext05:*)  printf '%s\n' "Erweitert (05)" ;;
    part_type_set:EN) printf 'Type set: %s on %s\n'  "$1" "$2" ;;
    part_type_set:*) printf 'Typ gesetzt: %s auf %s\n'  "$1" "$2" ;;
    err_part_type_failed:EN) printf '%s\n' "Type could not be set." ;;
    err_part_type_failed:*)  printf '%s\n' "Typ konnte nicht gesetzt werden." ;;
    err_part_bootflag_gpt:EN) printf '%s\n' "Boot flag only exists on MBR tables (GPT: use partition type ESP)." ;;
    err_part_bootflag_gpt:*)  printf '%s\n' "Boot-Flag gibt es nur bei MBR-Tabellen (GPT: Partitionstyp ESP verwenden)." ;;
    part_bootflag_title:EN) printf 'Set boot flag (MBR): %s\n'  "$1" ;;
    part_bootflag_title:*) printf 'Boot-Flag setzen (MBR): %s\n'  "$1" ;;
    part_choose_bootflag:EN) printf '%s\n' "Partition (gets boot flag, all others lose it)" ;;
    part_choose_bootflag:*)  printf '%s\n' "Partition (erhält Boot-Flag, alle anderen verlieren es)" ;;
    part_bootflag_set:EN) printf 'Boot flag set on %s\n'  "$1" ;;
    part_bootflag_set:*) printf 'Boot-Flag gesetzt auf %s\n'  "$1" ;;
    err_part_bootflag_failed:EN) printf '%s\n' "Boot flag could not be set." ;;
    err_part_bootflag_failed:*)  printf '%s\n' "Boot-Flag konnte nicht gesetzt werden." ;;
    err_part_missing_tools:EN) printf 'The partitioner is missing tools: %s\n'  "$1" ;;
    err_part_missing_tools:*) printf 'Für den Partitionierer fehlen Werkzeuge: %s\n'  "$1" ;;
    err_part_needs:EN) printf 'The partitioner needs: %s\n'  "$1" ;;
    err_part_needs:*) printf 'Der Partitionierer braucht: %s\n'  "$1" ;;
    part_menu_disk_title:EN) printf '%s\n' "Partitioner - disk selection" ;;
    part_menu_disk_title:*)  printf '%s\n' "Partitionierer - Plattenauswahl" ;;
    err_part_no_disk:EN) printf '%s\n' "No suitable disk found." ;;
    err_part_no_disk:*)  printf '%s\n' "Keine passende Festplatte gefunden." ;;
    part_choose_disk:EN) printf '%s\n' "Choose disk" ;;
    part_choose_disk:*)  printf '%s\n' "Festplatte wählen" ;;
    part_menu_title:EN) printf 'Partitioning: %s\n'  "$1" ;;
    part_menu_title:*) printf 'Partitionieren: %s\n'  "$1" ;;
    part_menu_overview:EN) printf '%s\n' "Show overview (partitions + free areas)" ;;
    part_menu_overview:*)  printf '%s\n' "Übersicht anzeigen (Partitionen + freie Bereiche)" ;;
    part_menu_newtable:EN) printf '%s\n' "Create new partition table (DELETES EVERYTHING on the disk)" ;;
    part_menu_newtable:*)  printf '%s\n' "Neue Partitionstabelle anlegen (LÖSCHT ALLES auf der Platte)" ;;
    part_menu_create:EN) printf '%s\n' "Create partition" ;;
    part_menu_create:*)  printf '%s\n' "Partition erstellen" ;;
    part_menu_delete:EN) printf '%s\n' "Delete partition" ;;
    part_menu_delete:*)  printf '%s\n' "Partition löschen" ;;
    part_menu_format:EN) printf '%s\n' "Format partition (ext4/FAT32/swap/NTFS)" ;;
    part_menu_format:*)  printf '%s\n' "Partition formatieren (ext4/FAT32/swap/NTFS)" ;;
    part_menu_settype:EN) printf '%s\n' "Set partition type (ESP, BIOS boot, swap ...)" ;;
    part_menu_settype:*)  printf '%s\n' "Partitionstyp setzen (ESP, BIOS-Boot, Swap ...)" ;;
    part_menu_bootflag:EN) printf '%s\n' "Set boot flag (MBR only)" ;;
    part_menu_bootflag:*)  printf '%s\n' "Boot-Flag setzen (nur MBR)" ;;
    inst_whole_disk:EN) printf '%s\n' "- WHOLE DISK - " ;;
    inst_whole_disk:*)  printf '%s\n' "- GANZE PLATTE - " ;;
    inst_will_repart:EN) printf '%s\n' "[will be repartitioned]" ;;
    inst_will_repart:*)  printf '%s\n' "[wird neu partitioniert]" ;;
    inst_extended_skipped:EN) printf '%s\n' "- extended partition (skipped)" ;;
    inst_extended_skipped:*)  printf '%s\n' "- erweiterte Partition (übersprungen)" ;;
    inst_partition:EN) printf '%s\n' "- partition - " ;;
    inst_partition:*)  printf '%s\n' "- Partition - " ;;
    inst_targets_title:EN) printf '%s\n' "Possible installation targets" ;;
    inst_targets_title:*)  printf '%s\n' "Mögliche Installationsziele" ;;
    inst_live_excluded:EN) printf 'The live medium %s and its partitions are excluded.\n'  "$1" ;;
    inst_live_excluded:*) printf 'Das Live-Medium %s und seine Partitionen sind ausgeschlossen.\n'  "$1" ;;
    err_inst_no_targets:EN) printf '%s\n' "No suitable targets found." ;;
    err_inst_no_targets:*)  printf '%s\n' "Keine geeigneten Ziele gefunden." ;;
    inst_choose_target:EN) printf '%s\n' "Choose installation target" ;;
    inst_choose_target:*)  printf '%s\n' "Installationsziel wählen" ;;
    inst_title:EN) printf '%s\n' "DebianLive installer - installs the booted live system" ;;
    inst_title:*)  printf '%s\n' "DebianLive-Installer - installiert das gebootete Live-System" ;;
    err_inst_not_block:EN) printf 'Not a block device: %s\n'  "$1" ;;
    err_inst_not_block:*) printf 'Kein Blockgerät: %s\n'  "$1" ;;
    err_inst_no_parent:EN) printf "Could not determine the parent disk of '%s'.\n"  "$1" ;;
    err_inst_no_parent:*) printf "Übergeordnete Festplatte von '%s' konnte nicht ermittelt werden.\n"  "$1" ;;
    err_inst_extended:EN) printf "An extended partition ('%s') cannot be an installation target.\n"  "$1" ;;
    err_inst_extended:*) printf "Eine erweiterte Partition ('%s') kann kein Installationsziel sein.\n"  "$1" ;;
    err_inst_neither:EN) printf "'%s' is neither a whole disk nor a partition.\n"  "$1" ;;
    err_inst_neither:*) printf "'%s' ist weder eine komplette Festplatte noch eine Partition.\n"  "$1" ;;
    err_inst_unsuitable:EN) printf "'%s' is not a suitable installation target.\n"  "$1" ;;
    err_inst_unsuitable:*) printf "'%s' ist kein geeignetes Installationsziel.\n"  "$1" ;;
    inst_session_mode:EN) printf 'Session mode: %s - the installation will be for %s.\n'  "$1" "$2" ;;
    inst_session_mode:*) printf 'Sitzungs-Modus: %s - die Installation erfolgt für %s.\n'  "$1" "$2" ;;
    inst_boot_bios:EN) printf '%s\n' "For a BIOS installation, boot the ISO in BIOS/CSM mode." ;;
    inst_boot_bios:*)  printf '%s\n' "Für eine BIOS-Installation das ISO im BIOS-/CSM-Modus starten." ;;
    inst_boot_uefi:EN) printf '%s\n' "For a UEFI installation, boot the ISO in UEFI mode." ;;
    inst_boot_uefi:*)  printf '%s\n' "Für eine UEFI-Installation das ISO im UEFI-Modus starten." ;;
    err_inst_arch:EN) printf 'Only x86_64 is supported (found: %s).\n'  "$1" ;;
    err_inst_arch:*) printf 'Nur x86_64 wird unterstützt (gefunden: %s).\n'  "$1" ;;
    err_inst_no_live_system:EN) printf '%s\n' "No Debian live system detected (/cdrom missing) -
is the script running inside the booted live system?" ;;
    err_inst_no_live_system:*)  printf '%s\n' "Kein Debian-Live-System erkannt (/cdrom fehlt) -
läuft das Script im gebooteten Live-System?" ;;
    err_inst_no_squash:EN) printf '%s\n' "No Debian SquashFS found - diagnostics:" ;;
    err_inst_no_squash:*)  printf '%s\n' "Kein Debian-SquashFS gefunden - Diagnose:" ;;
    inst_files_under_cdrom:EN) printf '%s\n' "Files under /cdrom:" ;;
    inst_files_under_cdrom:*)  printf '%s\n' "Dateien unter /cdrom:" ;;
    err_inst_no_squashfs:EN) printf '%s\n' "No Debian live system detected (filesystem.squashfs missing).
Please start this program from inside the booted live ISO." ;;
    err_inst_no_squashfs:*)  printf '%s\n' "Kein Debian-Live-System erkannt (filesystem.squashfs fehlt).
Bitte dieses Programm innerhalb der gebooteten Live-ISO starten." ;;
    inst_squashfs:EN) printf 'SquashFS:    %s\n'  "$1" ;;
    inst_squashfs:*) printf 'SquashFS:    %s\n'  "$1" ;;
    err_inst_on_live_medium:EN) printf "'%s' lies on the live medium the system was just booted from!\n"  "$1" ;;
    err_inst_on_live_medium:*) printf "'%s' liegt auf dem Live-Medium, von dem gerade gebootet wurde!\n"  "$1" ;;
    inst_target:EN) printf 'Target:      %s\n'  "$1" ;;
    inst_target:*) printf 'Ziel:        %s\n'  "$1" ;;
    inst_mode_part:EN) printf 'Mode:        partition (disk: %s, no repartitioning)\n'  "$1" ;;
    inst_mode_part:*) printf 'Modus:       Partition (Platte: %s, keine Neupartitionierung)\n'  "$1" ;;
    inst_mode_disk:EN) printf '%s\n' "Mode:        whole disk (will be repartitioned)" ;;
    inst_mode_disk:*)  printf '%s\n' "Modus:       Gesamte Festplatte (wird neu partitioniert)" ;;
    inst_live_medium:EN) printf 'Live medium: %s\n'  "$1" ;;
    inst_live_medium:*) printf 'Live-Medium: %s\n'  "$1" ;;
    err_inst_still_mounted:EN) printf "File systems are still mounted on '%s'.\n"  "$1" ;;
    err_inst_still_mounted:*) printf "Auf '%s' sind noch Dateisysteme eingehängt.\n"  "$1" ;;
    err_inst_too_small:EN) printf 'Target too small: %s MB. At least 8 GB.\n'  "$1" ;;
    err_inst_too_small:*) printf 'Ziel zu klein: %s MB. Mindestens 8 GB.\n'  "$1" ;;
    inst_size:EN) printf 'Size:        %s MB\n'  "$1" ;;
    inst_size:*) printf 'Größe:       %s MB\n'  "$1" ;;
    inst_model:EN) printf 'Model:       %s\n'  "$1" ;;
    inst_model:*) printf 'Modell:      %s\n'  "$1" ;;
    inst_warn_wipe:EN) printf 'ATTENTION - ALL DATA ON %s WILL BE DELETED!\n'  "$1" ;;
    inst_warn_wipe:*) printf 'ACHTUNG - ALLE DATEN AUF %s WERDEN GELÖSCHT!\n'  "$1" ;;
    inst_missing_tools:EN) printf '%s\n' "Missing tools - installing packages (network required):" ;;
    inst_missing_tools:*)  printf '%s\n' "Fehlende Werkzeuge - installiere Pakete (Netzwerk nötig):" ;;
    err_inst_missing_pkgs:EN) printf '%s\n' "Missing packages: %s
Please install: apt-get install %s" "$1" "$2" ;;
    err_inst_missing_pkgs:*)  printf '%s\n' "Fehlende Pakete: %s
Bitte installieren: apt-get install %s" "$1" "$2" ;;
    err_inst_pkgs_failed:EN) printf '%s\n' "Packages could not be installed (network? did you run 'apt-get update'?)" ;;
    err_inst_pkgs_failed:*)  printf '%s\n' "Pakete konnten nicht installiert werden (Netzwerk? 'apt-get update' ausgeführt?)" ;;
    err_inst_pkg_still_missing:EN) printf "Package for '%s' is still missing.\n"  "$1" ;;
    err_inst_pkg_still_missing:*) printf "Paket für '%s' fehlt weiterhin.\n"  "$1" ;;
    err_inst_mkfsvfat_missing:EN) printf '%s\n' "mkfs.vfat is still missing (package dosfstools)." ;;
    err_inst_mkfsvfat_missing:*)  printf '%s\n' "mkfs.vfat fehlt weiterhin (Paket dosfstools)." ;;
    err_inst_grub_bios_missing:EN) printf '%s\n' "GRUB modules for BIOS (i386-pc) are missing from the live system.
On the source machine run 'sudo apt-get install grub-pc-bin' and rebuild the ISO." ;;
    err_inst_grub_bios_missing:*)  printf '%s\n' "grub-Module für BIOS (i386-pc) fehlen im Live-System.
Auf dem Quellrechner 'sudo apt-get install grub-pc-bin' ausführen und die ISO neu bauen." ;;
    err_inst_grub_uefi_missing:EN) printf '%s\n' "GRUB modules for UEFI (x86_64-efi) are missing from the live system.
On the source machine run 'sudo apt-get install grub-efi-amd64-bin' and rebuild the ISO." ;;
    err_inst_grub_uefi_missing:*)  printf '%s\n' "grub-Module für UEFI (x86_64-efi) fehlen im Live-System.
Auf dem Quellrechner 'sudo apt-get install grub-efi-amd64-bin' ausführen und die ISO neu bauen." ;;
    err_inst_no_kernel:EN) printf '%s\n' "No kernel found (neither in the live system nor on the medium)." ;;
    err_inst_no_kernel:*)  printf '%s\n' "Kein Kernel gefunden (weder im Live-System noch auf dem Medium)." ;;
    inst_kernel_source:EN) printf 'Kernel source: %s\n'  "$1" ;;
    inst_kernel_source:*) printf 'Kernel-Quelle: %s\n'  "$1" ;;
    inst_part_mode_note1:EN) printf '%s\n' "Target is a single partition - the partition table" ;;
    inst_part_mode_note1:*)  printf '%s\n' "Ziel ist eine einzelne Partition - die Partitionstabelle" ;;
    inst_part_mode_note2:EN) printf 'of %s will NOT be changed.\n'  "$1" ;;
    inst_part_mode_note2:*) printf 'von %s wird NICHT verändert.\n'  "$1" ;;
    inst_partitioning:EN) printf 'Partitioning %s (%s) - all data will be deleted...\n'  "$1" "$2" ;;
    inst_partitioning:*) printf 'Partitioniere %s (%s) - alle Daten werden gelöscht...\n'  "$1" "$2" ;;
    inst_creating_gpt:EN) printf '%s\n' "Creating GPT with 512 MiB EFI + root (sfdisk)..." ;;
    inst_creating_gpt:*)  printf '%s\n' "Erstelle GPT mit 512-MiB-EFI + Root (sfdisk)..." ;;
    err_inst_part_gpt:EN) printf '%s\n' "Partitioning (GPT) failed." ;;
    err_inst_part_gpt:*)  printf '%s\n' "Partitionierung (GPT) fehlgeschlagen." ;;
    inst_creating_mbr:EN) printf '%s\n' "Creating MBR with a bootable root partition (sfdisk)..." ;;
    inst_creating_mbr:*)  printf '%s\n' "Erstelle MBR mit einer bootbaren Root-Partition (sfdisk)..." ;;
    err_inst_part_mbr:EN) printf '%s\n' "Partitioning (MBR) failed." ;;
    err_inst_part_mbr:*)  printf '%s\n' "Partitionierung (MBR) fehlgeschlagen." ;;
    err_inst_p1_missing:EN) printf 'Partition %s was not found.\n'  "$1" ;;
    err_inst_p1_missing:*) printf 'Partition %s wurde nicht gefunden.\n'  "$1" ;;
    err_inst_p2_missing:EN) printf 'Partition %s was not found.\n'  "$1" ;;
    err_inst_p2_missing:*) printf 'Partition %s wurde nicht gefunden.\n'  "$1" ;;
    inst_partitions:EN) printf '%s\n' "Partitions:" ;;
    inst_partitions:*)  printf '%s\n' "Partitionen:" ;;
    inst_formatting:EN) printf '%s\n' "Formatting..." ;;
    inst_formatting:*)  printf '%s\n' "Formatiere..." ;;
    inst_formatting_part:EN) printf 'Formatting %s (ext4) - all data on this partition will be deleted...\n'  "$1" ;;
    inst_formatting_part:*) printf 'Formatiere %s (ext4) - alle Daten auf dieser Partition werden gelöscht...\n'  "$1" ;;
    inst_swap_off:EN) printf '%s\n' "Partition is active as swap - switching it off..." ;;
    inst_swap_off:*)  printf '%s\n' "Partition ist als Swap aktiv - schalte sie aus..." ;;
    err_inst_swap_off_failed:EN) printf '%s is active as swap and could not be switched off.\n'  "$1" ;;
    err_inst_swap_off_failed:*) printf '%s ist als Swap aktiv und konnte nicht ausgeschaltet werden.\n'  "$1" ;;
    err_inst_format_target:EN) printf '%s\n' "Target partition could not be formatted." ;;
    err_inst_format_target:*)  printf '%s\n' "Ziel-Partition konnte nicht formatiert werden." ;;
    inst_search_esp:EN) printf 'Looking for EFI system partition on %s...\n'  "$1" ;;
    inst_search_esp:*) printf 'Suche EFI-Systempartition auf %s...\n'  "$1" ;;
    inst_partlist:EN) printf 'Partition list of %s (type/FSTYPE):\n'  "$1" ;;
    inst_partlist:*) printf 'Partitionsliste von %s (Typ/FSTYPE):\n'  "$1" ;;
    err_inst_no_esp:EN) printf '%s\n' "UEFI mode: no EFI system partition (ESP) was found on
%s (see the partition list above).

Please create an ESP with the partitioner ('%s part') -
use the preset 'EFI system partition (FAT32, ESP, 512 MiB)'.
The 2 MiB 'BIOS boot' partition is for BIOS mode only, not for UEFI.
If the disk is MBR: use GPT + ESP in UEFI mode, or boot the ISO
in BIOS/CSM mode for an MBR/BIOS installation." "$1" "$2" ;;
    err_inst_no_esp:*)  printf '%s\n' "UEFI-Modus: Es wurde keine EFI-Systempartition (ESP) auf
%s gefunden (siehe Partitionsliste oben).

Bitte über den Partitionierer ('%s part') eine ESP anlegen -
Preset 'EFI-Systempartition (FAT32, ESP, 512 MiB)' verwenden.
Die 2-MiB-'BIOS-Boot'-Partition ist nur für den BIOS-Modus, nicht für UEFI.
Ist die Platte MBR: im UEFI-Modus GPT + ESP verwenden, oder das ISO
für eine MBR/BIOS-Installation im BIOS-/CSM-Modus starten." "$1" "$2" ;;
    inst_esp_unformatted:EN) printf 'ESP %s is unformatted - creating FAT32...\n'  "$1" ;;
    inst_esp_unformatted:*) printf 'ESP %s ist unformatiert - lege FAT32 an...\n'  "$1" ;;
    err_inst_esp_format:EN) printf '%s\n' "ESP could not be formatted." ;;
    err_inst_esp_format:*)  printf '%s\n' "ESP konnte nicht formatiert werden." ;;
    err_inst_esp_wrong_fs:EN) printf "%s is marked as ESP but contains '%s' instead of vfat.\n"  "$1" "$2" ;;
    err_inst_esp_wrong_fs:*) printf "%s ist als ESP markiert, enthält aber '%s' statt vfat.\n"  "$1" "$2" ;;
    err_inst_bios_gpt_no_biosboot:EN) printf '%s\n' "BIOS mode with GPT partition table: %s is missing
a BIOS boot partition (1-2 MiB, type 'BIOS boot').

In the partitioner: create a 2 MiB partition 'No filesystem (raw)' and in
the 'Set type' menu choose 'BIOS boot partition (GRUB in BIOS mode)' -
or use an MBR table." "$1" ;;
    err_inst_bios_gpt_no_biosboot:*)  printf '%s\n' "BIOS-Modus mit GPT-Partitionstabelle: Auf %s fehlt
eine BIOS-Boot-Partition (1-2 MiB, Typ 'BIOS boot').

Im Partitionierer: 2-MiB-Partition 'Ohne Dateisystem (roh)' anlegen und im
'Typ setzen'-Menü 'BIOS-Boot-Partition (GRUB im BIOS-Modus)' wählen -
oder eine MBR-Tabelle verwenden." "$1" ;;
    err_inst_esp_format2:EN) printf '%s\n' "EFI system partition could not be formatted." ;;
    err_inst_esp_format2:*)  printf '%s\n' "EFI-Systempartition konnte nicht formatiert werden." ;;
    err_inst_root_format:EN) printf '%s\n' "Root partition could not be formatted." ;;
    err_inst_root_format:*)  printf '%s\n' "Root-Partition konnte nicht formatiert werden." ;;
    err_inst_root_uuid:EN) printf '%s\n' "UUID of the root partition could not be determined." ;;
    err_inst_root_uuid:*)  printf '%s\n' "UUID der Root-Partition konnte nicht ermittelt werden." ;;
    err_inst_esp_uuid:EN) printf '%s\n' "UUID of the EFI partition could not be determined." ;;
    err_inst_esp_uuid:*)  printf '%s\n' "UUID der EFI-Partition konnte nicht ermittelt werden." ;;
    inst_mounting:EN) printf '%s\n' "Mounting the target system..." ;;
    inst_mounting:*)  printf '%s\n' "Mounte Zielsystem..." ;;
    err_inst_mnt_mounted:EN) printf '%s\n' "/mnt is already mounted - please reboot the live system." ;;
    err_inst_mnt_mounted:*)  printf '%s\n' "/mnt ist bereits eingehängt - bitte Live-System neu starten." ;;
    inst_clean_mnt:EN) printf '%s\n' "Cleaning leftovers in /mnt..." ;;
    inst_clean_mnt:*)  printf '%s\n' "Räume Reste in /mnt weg..." ;;
    err_inst_root_mount:EN) printf '%s\n' "Root partition could not be mounted." ;;
    err_inst_root_mount:*)  printf '%s\n' "Root-Partition konnte nicht gemountet werden." ;;
    inst_extracting:EN) printf 'Extracting the live system to %s (source: %s MB compressed)...\n'  "$1" "$2" ;;
    inst_extracting:*) printf 'Entpacke das Live-System nach %s (Quelle: %s MB komprimiert)...\n'  "$1" "$2" ;;
    inst_extracting_long:EN) printf 'Extracting the live system to %s - depending on the ISO this takes minutes...\n'  "$1" ;;
    inst_extracting_long:*) printf 'Entpacke das Live-System nach %s - je nach ISO mehrere Minuten...\n'  "$1" ;;
    err_inst_unsquash:EN) printf '%s\n' "unsquashfs failed." ;;
    err_inst_unsquash:*)  printf '%s\n' "unsquashfs fehlgeschlagen." ;;
    err_inst_esp_mount:EN) printf '%s\n' "EFI partition could not be mounted." ;;
    err_inst_esp_mount:*)  printf '%s\n' "EFI-Partition konnte nicht gemountet werden." ;;
    inst_free_after:EN) printf 'Free space after extraction: %s MB\n'  "$1" ;;
    inst_free_after:*) printf 'Freier Speicher nach dem Entpacken: %s MB\n'  "$1" ;;
    err_inst_low_space:EN) printf '%s\n' "Too little free space on the target partition." ;;
    err_inst_low_space:*)  printf '%s\n' "Zu wenig freier Speicher auf der Zielpartition." ;;
    inst_remove_bootloader:EN) printf '%s\n' "Removing inherited bootloader leftovers..." ;;
    inst_remove_bootloader:*)  printf '%s\n' "Entferne übernommene Bootloader-Reste..." ;;
    inst_checking_kernel:EN) printf '%s\n' "Checking kernel..." ;;
    inst_checking_kernel:*)  printf '%s\n' "Prüfe Kernel..." ;;
    err_inst_kernel_copy:EN) printf '%s\n' "Kernel could not be copied." ;;
    err_inst_kernel_copy:*)  printf '%s\n' "Kernel konnte nicht kopiert werden." ;;
    inst_kernel_copied:EN) printf 'Kernel copied: %s\n'  "$1" ;;
    inst_kernel_copied:*) printf 'Kernel kopiert: %s\n'  "$1" ;;
    inst_kernel:EN) printf 'Kernel: %s\n'  "$1" ;;
    inst_kernel:*) printf 'Kernel: %s\n'  "$1" ;;
    err_inst_no_modbase:EN) printf '%s\n' "No kernel modules in the installed system (/lib/modules missing)." ;;
    err_inst_no_modbase:*)  printf '%s\n' "Keine Kernelmodule im installierten System (/lib/modules fehlt)." ;;
    err_inst_no_kver:EN) printf '%s\n' "No kernel version found in the installed system." ;;
    err_inst_no_kver:*)  printf '%s\n' "Keine Kernel-Version im installierten System gefunden." ;;
    err_inst_no_matching_modules:EN) printf '%s\n' "Matching kernel modules were not found." ;;
    err_inst_no_matching_modules:*)  printf '%s\n' "Passende Kernelmodule wurden nicht gefunden." ;;
    inst_creating_fstab:EN) printf '%s\n' "Creating /etc/fstab..." ;;
    inst_creating_fstab:*)  printf '%s\n' "Erzeuge /etc/fstab..." ;;
    inst_creating_machine_id:EN) printf '%s\n' "Creating a new machine-id..." ;;
    inst_creating_machine_id:*)  printf '%s\n' "Erzeuge neue machine-id..." ;;
    err_inst_machine_id:EN) printf '%s\n' "machine-id could not be created." ;;
    err_inst_machine_id:*)  printf '%s\n' "machine-id konnte nicht erzeugt werden." ;;
    err_inst_dm_broken:EN) printf '%s\n' "display-manager.service points to a nonexistent unit (%s) -
the installation is aborted so that no unbootable system can result." "$1" ;;
    err_inst_dm_broken:*)  printf '%s\n' "display-manager.service zeigt auf eine nicht existierende Unit (%s) -
die Installation wird abgebrochen, damit kein unbootbares System entsteht." "$1" ;;
    inst_set_dm:EN) printf 'Setting /etc/X11/default-display-manager to the installed display manager: %s\n'  "$1" ;;
    inst_set_dm:*) printf 'Setze /etc/X11/default-display-manager auf den installierten Display-Manager: %s\n'  "$1" ;;
    inst_building_initramfs:EN) printf '%s\n' "Building initramfs for the installed system..." ;;
    inst_building_initramfs:*)  printf '%s\n' "Baue Initramfs für das installierte System..." ;;
    err_inst_update_initramfs:EN) printf '%s\n' "update-initramfs failed" ;;
    err_inst_update_initramfs:*)  printf '%s\n' "update-initramfs fehlgeschlagen" ;;
    inst_fallback_updategrub:EN) printf '%s\n' "Fallback: GRUB configuration the normal way (update-grub)..." ;;
    inst_fallback_updategrub:*)  printf '%s\n' "Fallback: GRUB-Konfiguration auf dem normalen Weg (update-grub)..." ;;
    inst_updategrub_done:EN) printf '%s\n' "GRUB configuration generated via update-grub (normal way)." ;;
    inst_updategrub_done:*)  printf '%s\n' "GRUB-Konfiguration per update-grub erzeugt (normaler Weg)." ;;
    err_inst_updategrub_failed:EN) printf '%s\n' "update-grub failed - generating a minimal GRUB configuration. Message:" ;;
    err_inst_updategrub_failed:*)  printf '%s\n' "update-grub fehlgeschlagen - es wird eine minimale GRUB-Konfiguration erzeugt. Meldung:" ;;
    inst_installing_grub:EN) printf 'Installing GRUB (%s)...\n'  "$1" ;;
    inst_installing_grub:*) printf 'Installiere GRUB (%s)...\n'  "$1" ;;
    err_inst_grub_bios:EN) printf '%s\n' "grub-install BIOS failed." ;;
    err_inst_grub_bios:*)  printf '%s\n' "grub-install BIOS fehlgeschlagen." ;;
    err_inst_esp_not_mounted:EN) printf '%s\n' "EFI system partition is not mounted - aborting before grub-install." ;;
    err_inst_esp_not_mounted:*)  printf '%s\n' "EFI-Systempartition ist nicht eingehängt - Abbruch vor grub-install." ;;
    err_inst_grub_uefi:EN) printf '%s\n' "grub-install UEFI failed." ;;
    err_inst_grub_uefi:*)  printf '%s\n' "grub-install UEFI fehlgeschlagen." ;;
    inst_creating_grubcfg:EN) printf '%s\n' "Creating GRUB configuration..." ;;
    inst_creating_grubcfg:*)  printf '%s\n' "Erzeuge GRUB-Konfiguration..." ;;
    err_inst_no_bootloader_files:EN) printf '%s\n' "Neither BOOTX64.EFI nor EFI/debian/grubx64.efi was created by grub-install" ;;
    err_inst_no_bootloader_files:*)  printf '%s\n' "Weder BOOTX64.EFI noch EFI/debian/grubx64.efi wurden vom grub-install erstellt" ;;
    err_inst_autologin_survived:EN) printf '%s\n' "An autologin configuration was still found in the target system
(sddm.conf or sddm.conf.d) - the installation is aborted so that
no system with a broken autologin can result." ;;
    err_inst_autologin_survived:*)  printf '%s\n' "Es wurde noch eine Autologin-Konfiguration im Zielsystem gefunden
(sddm.conf oder sddm.conf.d) - die Installation wird abgebrochen, damit
kein System mit defektem Autologin entstehen kann." ;;
    inst_success:EN) printf '%s\n' "INSTALLATION SUCCESSFUL" ;;
    inst_success:*)  printf '%s\n' "INSTALLATION ERFOLGREICH" ;;
    inst_done_target:EN) printf 'Target:     %s\n'  "$1" ;;
    inst_done_target:*) printf 'Ziel:       %s\n'  "$1" ;;
    inst_done_root:EN) printf 'Root:       %s\n'  "$1" ;;
    inst_done_root:*) printf 'Root:       %s\n'  "$1" ;;
    inst_now_do:EN) printf '%s\n' "Now please:" ;;
    inst_now_do:*)  printf '%s\n' "Bitte jetzt:" ;;
    inst_step1:EN) printf '%s\n' "  1. Remove the USB stick / live medium" ;;
    inst_step1:*)  printf '%s\n' "  1. USB-Stick / Live-Medium entfernen" ;;
    inst_step2:EN) printf '%s\n' "  2. Reboot the machine" ;;
    inst_step2:*)  printf '%s\n' "  2. Rechner neu starten" ;;
    inst_step3:EN) printf '%s\n' "  3. Boot from the installed disk" ;;
    inst_step3:*)  printf '%s\n' "  3. Von der installierten Festplatte booten" ;;
    inst_login_screen_info:EN) printf '%s\n' "The installed system starts with the login screen
(autologin is not carried over, just like a normal installation;
it can be re-enabled in the SDDM/login settings)." ;;
    inst_login_screen_info:*)  printf '%s\n' "Das installierte System startet mit dem Login-Bildschirm
(Autologin wird wie bei einer normalen Installation nicht
übernommen - in den SDDM-/Login-Einstellungen wieder aktivierbar)." ;;
    inst_menu_title:EN) printf '%s\n' "Install the live system" ;;
    inst_menu_title:*)  printf '%s\n' "Live-System installieren" ;;
    inst_menu:EN) printf '%s\n' "Installation" ;;
    inst_menu:*)  printf '%s\n' "Installation" ;;
    inst_menu_choose:EN) printf '%s\n' "Choose target and install" ;;
    inst_menu_choose:*)  printf '%s\n' "Ziel wählen und installieren" ;;
    inst_menu_show:EN) printf '%s\n' "Show possible targets" ;;
    inst_menu_show:*)  printf '%s\n' "Mögliche Ziele anzeigen" ;;
    inst_menu_partition:EN) printf '%s\n' "Partition first (open the partitioner)" ;;
    inst_menu_partition:*)  printf '%s\n' "Zuerst partitionieren (Partitionierer öffnen)" ;;
    err_iso_system_area:EN) printf "%s '%s' lies in the system/boot area - aborted (data-loss protection).\n"  "$1" "$2" ;;
    err_iso_system_area:*) printf "%s '%s' liegt im System-/Boot-Bereich - abgebrochen (Schutz vor Datenverlust).\n"  "$1" "$2" ;;
    err_iso_fat_area:EN) printf '%s\n' "%s '%s' lies on a FAT/EFI partition - aborted.
Multi-GB files and boot trees do not belong there -
the computer's boot files would otherwise have been overwritten." "$1" "$2" ;;
    err_iso_fat_area:*)  printf '%s\n' "%s '%s' liegt auf einer FAT/EFI-Partition - abgebrochen.
Dorthin gehören keine mehr-GB-Dateien und keine Boot-Bäume - die
Boot-Dateien des Rechners wären sonst überschrieben worden." "$1" "$2" ;;
    iso_cleaning:EN) printf '%s\n' "Cleaning up..." ;;
    iso_cleaning:*)  printf '%s\n' "Räume auf..." ;;
    err_iso_work_invalid:EN) printf "Work directory '%s' invalid.\n"  "$1" ;;
    err_iso_work_invalid:*) printf "Arbeitsverzeichnis '%s' ungültig.\n"  "$1" ;;
    iso_cleanup_title:EN) printf 'Cleanup: unmounting mounts and removing build artifacts under %s\n'  "$1" ;;
    iso_cleanup_title:*) printf 'Aufräumen: löse Mounts und entferne Build-Artefakte unter %s\n'  "$1" ;;
    err_iso_artifacts_delete:EN) printf '%s\n' "Build artifacts could not be deleted" ;;
    err_iso_artifacts_delete:*)  printf '%s\n' "Build-Artefakte konnten nicht gelöscht werden" ;;
    iso_cleanup_done:EN) printf '%s\n' "Done. Work directory emptied (finished ISO is kept)." ;;
    iso_cleanup_done:*)  printf '%s\n' "Fertig. Arbeitsverzeichnis geleert (fertige ISO bleibt erhalten)." ;;
    iso_owner_set:EN) printf 'Owner of %s: %s\n'  "$1" "$2" ;;
    iso_owner_set:*) printf 'Eigentümer von %s: %s\n'  "$1" "$2" ;;
    iso_owner_failed:EN) printf "Owner of %s could not be changed to '%s' - manually: sudo chown -R \"%s:\" \"%s\"\n"  "$1" "$2" "$3" "$4" ;;
    iso_owner_failed:*) printf "Eigentümer von %s konnte nicht auf '%s' geändert werden - manuell: sudo chown -R \"%s:\" \"%s\"\n"  "$1" "$2" "$3" "$4" ;;
    err_iso_initrd_empty:EN) printf "Initramfs '%s' is empty.\n"  "$1" ;;
    err_iso_initrd_empty:*) printf "Initramfs '%s' ist leer.\n"  "$1" ;;
    err_iso_initrd_unmk:EN) printf '%s\n' "Initramfs cannot be unpacked (unmkinitramfs)." ;;
    err_iso_initrd_unmk:*)  printf '%s\n' "Initramfs lässt sich nicht entpacken (unmkinitramfs)." ;;
    err_iso_initrd_incomplete:EN) printf 'Initramfs is incomplete, missing:%s\n'  "$1" ;;
    err_iso_initrd_incomplete:*) printf 'Initramfs ist unvollständig, es fehlen:%s\n'  "$1" ;;
    err_iso_initrd_truncated:EN) printf '%s\n' "Initramfs main segment does not decompress completely (truncated/broken archive)." ;;
    err_iso_initrd_truncated:*)  printf '%s\n' "Initramfs-Hauptsegment lässt sich nicht vollständig dekomprimieren (abgeschnittenes/defektes Archiv)." ;;
    err_iso_work_spaces:EN) printf 'The work directory must not contain spaces: %s\n'  "$1" ;;
    err_iso_work_spaces:*) printf 'Das Arbeitsverzeichnis darf keine Leerzeichen enthalten: %s\n'  "$1" ;;
    err_iso_outdir_create:EN) printf 'Output directory %s could not be created\n'  "$1" ;;
    err_iso_outdir_create:*) printf 'Ausgabeordner %s konnte nicht angelegt werden\n'  "$1" ;;
    iso_missing_pkgs_title:EN) printf '%s\n' "Missing packages for the ISO build:" ;;
    iso_missing_pkgs_title:*)  printf '%s\n' "Fehlende Pakete für den ISO-Bau:" ;;
    err_iso_missing_pkgs:EN) printf '%s\n' "Missing packages: %s
Please install: apt-get install %s" "$1" "$2" ;;
    err_iso_missing_pkgs:*)  printf '%s\n' "Fehlende Pakete: %s
Bitte installieren: apt-get install %s" "$1" "$2" ;;
    iso_installing_pkgs:EN) printf 'Installing missing packages: %s ...\n'  "$1" ;;
    iso_installing_pkgs:*) printf 'Installiere fehlende Pakete: %s ...\n'  "$1" ;;
    err_iso_pkgs_failed:EN) printf '%s\n' "Packages could not be installed.
Please run 'sudo apt-get update' (refresh package lists) first
and restart the build afterwards." ;;
    err_iso_pkgs_failed:*)  printf '%s\n' "Pakete konnten nicht installiert werden.
Bitte zuerst 'sudo apt-get update' (Paketlisten auffrischen) ausführen
und den Bau danach erneut starten." ;;
    err_iso_tool_missing:EN) printf '%s not found - please install package(s): %s\n'  "$1" "$2" ;;
    err_iso_tool_missing:*) printf '%s nicht gefunden - bitte Paket(e) installieren: %s\n'  "$1" "$2" ;;
    info_iso_liveboot_missing:EN) printf '%s\n' "live-boot files are missing (hooks/live or scripts/live) - typically on an
installed copy from an older tool version (the installer used to remove them)." ;;
    info_iso_liveboot_missing:*)  printf '%s\n' "live-boot-Dateien fehlen (hooks/live oder scripts/live) - typisch bei einer
installierten Kopie aus einer älteren Tool-Version (der Installer entfernte sie früher)." ;;
    err_iso_liveboot_missing_fatal:EN) printf '%s\n' "live-boot files are missing - the build would produce an unbootable ISO.
Manually: download and extract the live-boot package, then copy to /usr/share/initramfs-tools/:
  cd /tmp && apt-get download live-boot && dpkg-deb -x live-boot_*.deb live-boot-x
  sudo cp -a live-boot-x/usr/share/initramfs-tools/hooks/live /usr/share/initramfs-tools/hooks/
  sudo cp -a live-boot-x/usr/share/initramfs-tools/scripts/. /usr/share/initramfs-tools/scripts/" ;;
    err_iso_liveboot_missing_fatal:*)  printf '%s\n' "live-boot-Dateien fehlen - der Bau würde eine unbootbare ISO erzeugen.
Manuell: das live-boot-Paket laden und entpacken, dann nach /usr/share/initramfs-tools/ kopieren:
  cd /tmp && apt-get download live-boot && dpkg-deb -x live-boot_*.deb live-boot-x
  sudo cp -a live-boot-x/usr/share/initramfs-tools/hooks/live /usr/share/initramfs-tools/hooks/
  sudo cp -a live-boot-x/usr/share/initramfs-tools/scripts/. /usr/share/initramfs-tools/scripts/" ;;
    err_iso_liveboot_download:EN) printf '%s\n' "apt-get download live-boot failed (network/archive reachable?).
Manually: sudo apt-get update, then apt-get download live-boot; extract the deb with
dpkg-deb -x and copy hooks/live + scripts/. to /usr/share/initramfs-tools/." ;;
    err_iso_liveboot_download:*)  printf '%s\n' "apt-get download live-boot fehlgeschlagen (Netzwerk/Archive erreichbar?).
Manuell: sudo apt-get update, dann apt-get download live-boot; die Deb-Datei mit
dpkg-deb -x entpacken und hooks/live + scripts/. nach /usr/share/initramfs-tools/ kopieren." ;;
    err_iso_liveboot_download_short:EN) printf '%s\n' "apt-get download live-boot failed (network/archive reachable?)." ;;
    err_iso_liveboot_download_short:*)  printf '%s\n' "apt-get download live-boot fehlgeschlagen (Netzwerk/Archive erreichbar?)." ;;
    err_iso_liveboot_extract:EN) printf '%s\n' "dpkg-deb -x could not extract the live-boot package (download broken?)." ;;
    err_iso_liveboot_extract:*)  printf '%s\n' "dpkg-deb -x konnte das live-boot-Paket nicht entpacken (Download defekt?)." ;;
    err_iso_liveboot_restore_failed:EN) printf '%s\n' "live-boot files could not be restored (unexpected package layout).
See the message above for manual steps." ;;
    err_iso_liveboot_restore_failed:*)  printf '%s\n' "live-boot-Dateien konnten nicht wiederhergestellt werden (unerwartetes Paket-Layout).
Manuell siehe Meldung oben." ;;
    info_iso_liveboot_restored:EN) printf '%s\n' "live-boot files restored (from the current live-boot package)." ;;
    info_iso_liveboot_restored:*)  printf '%s\n' "live-boot-Dateien wiederhergestellt (aus dem aktuellen live-boot-Paket)." ;;
    err_iso_low_space:EN) printf '%s\n' "Only about %s GB free in %s - too little!
The build needs at least about 2 GB, sensibly 8+ GB.
Please choose a different work directory (e.g. an external disk)." "$1" "$2" ;;
    err_iso_low_space:*)  printf '%s\n' "Nur ca. %s GB frei in %s - zu wenig!
Für den Bau werden mindestens ca. 2 GB, sinnvoll 8+ GB gebraucht.
Bitte ein anderes Arbeitsverzeichnis wählen (z. B. externe Festplatte)." "$1" "$2" ;;
    err_iso_no_overlay:EN) printf '%s\n' "Kernel module 'overlay' is not available!
Running kernel: %s
This usually happens when the kernel was updated but NOT yet rebooted
and the modules of the running kernel are then missing from /lib/modules.
-> Please reboot once and run the builder again." "$1" ;;
    err_iso_no_overlay:*)  printf '%s\n' "Kernelmodul 'overlay' ist nicht verfügbar!
Laufender Kernel: %s
Das passiert meist, wenn der Kernel aktualisiert, aber noch NICHT neu gestartet
wurde - die Module des laufenden Kernels fehlen dann in /lib/modules.
-> Bitte einmal NEU STARTEN und den Builder erneut ausführen." "$1" ;;
    err_iso_label_empty:EN) printf '%s\n' "Volume label is empty" ;;
    err_iso_label_empty:*)  printf '%s\n' "Volume-Label ist leer" ;;
    err_iso_label_long:EN) printf 'Volume label too long (max. 32 characters): %s\n'  "$1" ;;
    err_iso_label_long:*) printf 'Volume-Label zu lang (max. 32 Zeichen): %s\n'  "$1" ;;
    err_iso_label_chars:EN) printf 'Volume label contains invalid characters (only A-Z 0-9 . _ -): %s\n'  "$1" ;;
    err_iso_label_chars:*) printf 'Volume-Label enthält ungültige Zeichen (nur A-Z 0-9 . _ -): %s\n'  "$1" ;;
    err_iso_bad_comp:EN) printf '%s\n' "Invalid squashfs compression: '%s'
Allowed: xz, zstd, lzma, gzip, lzo, lz4 (configurable in the script: SQUASH_COMP=...)" "$1" ;;
    err_iso_bad_comp:*)  printf '%s\n' "Ungültige SquashFS-Kompression: '%s'
Erlaubt: xz, zstd, lzma, gzip, lzo, lz4 (Standard im Script einstellbar: SQUASH_COMP=...)" "$1" ;;
    iso_comp:EN) printf 'SquashFS compression: %s\n'  "$1" ;;
    iso_comp:*) printf 'SquashFS-Kompression: %s\n'  "$1" ;;
    err_iso_workdirs:EN) printf '%s\n' "Work directories could not be created" ;;
    err_iso_workdirs:*)  printf '%s\n' "Arbeitsverzeichnisse konnten nicht angelegt werden" ;;
    err_iso_no_kernel_modules:EN) printf '%s\n' "No kernel with modules found!
Most common cause: kernel updated but NOT rebooted yet - the modules
of the running kernel are then missing from /lib/modules.
-> Please reboot once and run the builder again.
(If still missing after the reboot: sudo apt-get install --reinstall linux-modules-\$(uname -r))" ;;
    err_iso_no_kernel_modules:*)  printf '%s\n' "Kein Kernel mit Modulen gefunden!
Häufigste Ursache: Kernel aktualisiert, aber noch NICHT neu gestartet - die Module
des laufenden Kernels fehlen dann in /lib/modules.
-> Bitte einmal NEU STARTEN und den Builder erneut ausführen.
(Falls nach dem Neustart weiterhin fehlend: sudo apt-get install --reinstall linux-modules-\$(uname -r))" ;;
    err_iso_kernel_file_missing:EN) printf 'No kernel found (/boot/vmlinuz-%s missing)!\n'  "$1" ;;
    err_iso_kernel_file_missing:*) printf 'Kein Kernel gefunden (/boot/vmlinuz-%s fehlt)!\n'  "$1" ;;
    iso_using_kernel:EN) printf 'Using kernel: %s (%s)\n'  "$1" "$2" ;;
    iso_using_kernel:*) printf 'Verwende Kernel: %s (%s)\n'  "$1" "$2" ;;
    iso_copying_kernel:EN) printf '%s\n' "Copying kernel..." ;;
    iso_copying_kernel:*)  printf '%s\n' "Kopiere Kernel..." ;;
    err_iso_kernel_copy:EN) printf '%s\n' "Kernel copy failed" ;;
    err_iso_kernel_copy:*)  printf '%s\n' "Kernel-Kopie fehlgeschlagen" ;;
    iso_live_autologin_user:EN) printf "Live autologin as the secured system's user: %s (username= boot parameter).\n"  "$1" ;;
    iso_live_autologin_user:*) printf 'Live-Autologin als Benutzer des gesicherten Systems: %s (username= Boot-Parameter).\n'  "$1" ;;
    iso_dm_session:EN) printf '%s session adopted for the live autologin: %s\n'  "$1" "$2" ;;
    iso_dm_session:*) printf '%s-Sitzung für den Live-Autologin übernommen: %s\n'  "$1" "$2" ;;
    warn_iso_no_dm_session:EN) printf 'No default %s session could be determined - the live autologin may fail (login screen). Please log out once in the source system, choose the desired session and rebuild the ISO.\n'  "$1" ;;
    warn_iso_no_dm_session:*) printf 'Keine Standard-Sitzung des Display-Managers (%s) ermittelbar - der Live-Autologin kann scheitern (Login-Bildschirm). Bitte im Quell-System einmal abmelden, die gewünschte Sitzung wählen und die ISO neu bauen.\n'  "$1" ;;
    iso_lightdm_block_written:EN) printf 'LightDM autologin block written into the image: user %s, session %s.\n'  "$1" "$2" ;;
    iso_lightdm_block_written:*) printf 'LightDM-Autologin-Block ins Abbild geschrieben: Benutzer %s, Sitzung %s.\n'  "$1" "$2" ;;
    iso_gdm_session_set:EN) printf 'GDM: session for the live autologin available via AccountsService: %s\n'  "$1" ;;
    iso_gdm_session_set:*) printf 'GDM: Sitzung für den Live-Autologin über AccountsService bereit: %s\n'  "$1" ;;
    iso_disable_autologin:EN) printf '%s\n' "Disabling live-boot autologin in the live system (login screen instead of automatic login)..." ;;
    iso_disable_autologin:*)  printf '%s\n' "Deaktiviere live-boot-Autologin im Live-System (Login-Bildschirm statt automatischer Anmeldung)..." ;;
    iso_fallback_initramfs:EN) printf '%s\n' "Fallback (older Debian version): building the initramfs the normal way (system configuration)..." ;;
    iso_fallback_initramfs:*)  printf '%s\n' "Fallback (ältere Debian-Version): baue Initramfs auf dem normalen Weg (Systemkonfiguration)..." ;;
    iso_building_initramfs:EN) printf '%s\n' "Building initramfs with live-boot (all drivers, may take several minutes)..." ;;
    iso_building_initramfs:*)  printf '%s\n' "Baue Initramfs mit live-boot (alle Treiber, kann einige Minuten dauern)..." ;;
    err_iso_mkinitramfs_failed:EN) printf '%s\n' "mkinitramfs failed - message from mkinitramfs:" ;;
    err_iso_mkinitramfs_failed:*)  printf '%s\n' "mkinitramfs fehlgeschlagen - Meldung von mkinitramfs:" ;;
    iso_check_pkgs:EN) printf '%s\n' "Check packages: live-boot initramfs-tools busybox-initramfs" ;;
    iso_check_pkgs:*)  printf '%s\n' "Pakete prüfen: live-boot initramfs-tools busybox-initramfs" ;;
    err_iso_initrd_failed:EN) printf '%s\n' "Could not create the initramfs - see the message above." ;;
    err_iso_initrd_failed:*)  printf '%s\n' "Initramfs konnte nicht erstellt werden - siehe Meldung oben." ;;
    err_iso_initrd_broken:EN) printf '%s\n' "The built initramfs is incomplete/broken - aborting so that no
unbootable ISO is produced. Please check: kernel modules (ls /lib/modules/%s/kernel),
live-boot package (hooks/live + scripts/live) and free disk space; then rebuild." "$1" ;;
    err_iso_initrd_broken:*)  printf '%s\n' "Das gebaute Initramfs ist unvollständig/defekt - Abbruch, damit keine
unbootbare ISO entsteht. Bitte prüfen: Kernel-Module (ls /lib/modules/%s/kernel),
live-boot-Paket (hooks/live + scripts/live) und freien Speicherplatz; dann neu bauen." "$1" ;;
    iso_mounting_overlay:EN) printf '%s\n' "Mounting root filesystem (read-only overlay)..." ;;
    iso_mounting_overlay:*)  printf '%s\n' "Hänge Root-Dateisystem (read-only Overlay) ein..." ;;
    err_iso_overlay_dirs:EN) printf '%s\n' "Overlay directories failed" ;;
    err_iso_overlay_dirs:*)  printf '%s\n' "Overlay-Verzeichnisse fehlgeschlagen" ;;
    err_iso_overlay_mount:EN) printf '%s\n' "Overlay mount failed" ;;
    err_iso_overlay_mount:*)  printf '%s\n' "Overlay-Mount fehlgeschlagen" ;;
    err_iso_overlay_incomplete:EN) printf '%s\n' "Overlay content incomplete" ;;
    err_iso_overlay_incomplete:*)  printf '%s\n' "Overlay-Inhalt unvollständig" ;;
    err_iso_no_systemd:EN) printf '%s\n' "systemd missing from the image - are / or /usr on a separate partition?" ;;
    err_iso_no_systemd:*)  printf '%s\n' "systemd fehlt im Abbild - liegt / oder /usr auf einer eigenen Partition?" ;;
    iso_nm_enabled:EN) printf '%s\n' "Network: NetworkManager enabled for all devices in the image." ;;
    iso_nm_enabled:*)  printf '%s\n' "Netzwerk: NetworkManager im Abbild für alle Geräte freigegeben." ;;
    iso_networkd_fallback:EN) printf '%s\n' "Network: systemd-networkd DHCP fallback for foreign hardware added to the image." ;;
    iso_networkd_fallback:*)  printf '%s\n' "Netzwerk: systemd-networkd-DHCP-Fallback für fremde Hardware ins Abbild übernommen." ;;
    iso_sddm_block_written:EN) printf 'SDDM autologin block written into the image: user %s, session %s.\n'  "$1" "$2" ;;
    iso_sddm_block_written:*) printf 'SDDM-Autologin-Block ins Abbild geschrieben: Benutzer %s, Sitzung %s.\n'  "$1" "$2" ;;
    iso_sddm_fallback:EN) printf "SDDM session fallback set in the image's /var/lib/sddm/state.conf: %s\n"  "$1" ;;
    iso_sddm_fallback:*) printf 'SDDM-Sitzungs-Fallback in /var/lib/sddm/state.conf des Abbilds gesetzt: %s\n'  "$1" ;;
    iso_close_apps:EN) printf '%s\n' "Important: close other applications if possible so the image is consistent." ;;
    iso_close_apps:*)  printf '%s\n' "Wichtig: Schließe möglichst andere Anwendungen, damit das Abbild konsistent ist." ;;
    iso_creating_squash_slow:EN) printf 'Creating SquashFS (%s - highest compression, may take a long time)...\n'  "$1" ;;
    iso_creating_squash_slow:*) printf 'Erstelle SquashFS (%s - höchste Kompression, kann lange dauern)...\n'  "$1" ;;
    iso_creating_squash:EN) printf 'Creating SquashFS (%s)...\n'  "$1" ;;
    iso_creating_squash:*) printf 'Erstelle SquashFS (%s)...\n'  "$1" ;;
    err_iso_mksquashfs:EN) printf '%s\n' "mksquashfs failed" ;;
    err_iso_mksquashfs:*)  printf '%s\n' "mksquashfs fehlgeschlagen" ;;
    err_iso_squash_move:EN) printf '%s\n' "applying the SquashFS failed" ;;
    err_iso_squash_move:*)  printf '%s\n' "SquashFS übernehmen fehlgeschlagen" ;;
    iso_creating_iso:EN) printf 'Creating ISO with grub-mkrescue (BIOS + UEFI bootable): %s\n'  "$1" ;;
    iso_creating_iso:*) printf 'Erstelle ISO mit grub-mkrescue (BIOS + UEFI bootbar): %s\n'  "$1" ;;
    err_iso_grubmkrescue:EN) printf '%s\n' "grub-mkrescue failed.
Common causes: mtools missing or broken (apt-get install mtools),
insufficient disk space for the temporary files, or the
output ISO resides in the same directory as the source files." ;;
    err_iso_grubmkrescue:*)  printf '%s\n' "grub-mkrescue fehlgeschlagen.
Häufige Ursachen: mtools fehlt oder ist defekt (apt-get install mtools),
zu wenig Speicherplatz für die temporären Dateien, oder die
Ausgabe-ISO liegt im selben Verzeichnis wie die Quelldateien." ;;
    err_iso_not_created:EN) printf '%s\n' "ISO was not created!" ;;
    err_iso_not_created:*)  printf '%s\n' "ISO wurde nicht erstellt!" ;;
    iso_success:EN) printf '%s\n' "SUCCESS: ISO CREATED" ;;
    iso_success:*)  printf '%s\n' "ERFOLG: ISO ERSTELLT" ;;
    iso_done_close:EN) printf '%s\n' "DONE - The ISO has been created. You can close this tool now." ;;
    iso_done_close:*)  printf '%s\n' "FERTIG - Die ISO ist erstellt. Sie können dieses Tool jetzt schließen." ;;
    iso_output_path:EN) printf 'Output path: %s (%s MB)\n'  "$1" "$2" ;;
    iso_output_path:*) printf 'Ausgabepfad: %s (%s MB)\n'  "$1" "$2" ;;
    iso_autologin_user_session:EN) printf 'Live autologin: %s, session %s (user of the secured system)\n'  "$1" "$2" ;;
    iso_autologin_user_session:*) printf 'Live-Autologin: %s, Sitzung %s (Benutzer des gesicherten Systems)\n'  "$1" "$2" ;;
    iso_autologin_user:EN) printf 'Live autologin: %s (user of the secured system)\n'  "$1" ;;
    iso_autologin_user:*) printf 'Live-Autologin: %s (Benutzer des gesicherten Systems)\n'  "$1" ;;
    iso_autologin_none:EN) printf '%s\n' "Live system starts with the login screen (autologin not possible)." ;;
    iso_autologin_none:*)  printf '%s\n' "Live-System startet mit dem Login-Bildschirm (kein Autologin möglich)." ;;
    iso_comp_xz:EN) printf '%s\n' "smallest size, slowest build + unpacking" ;;
    iso_comp_xz:*)  printf '%s\n' "kleinste Größe, langsamster Bau + Entpacken" ;;
    iso_comp_zstd:EN) printf '%s\n' "very fast build + unpacking, good size" ;;
    iso_comp_zstd:*)  printf '%s\n' "sehr schneller Bau + Entpacken, gute Größe" ;;
    iso_comp_lzma:EN) printf '%s\n' "small size, slow build" ;;
    iso_comp_lzma:*)  printf '%s\n' "kleine Größe, langsamer Bau" ;;
    iso_comp_gzip:EN) printf '%s\n' "fast, classic format" ;;
    iso_comp_gzip:*)  printf '%s\n' "schnell, klassisches Format" ;;
    iso_comp_lzo:EN) printf '%s\n' "very fast build, larger images" ;;
    iso_comp_lzo:*)  printf '%s\n' "sehr schneller Bau, größere Images" ;;
    iso_comp_lz4:EN) printf '%s\n' "fastest method, largest images" ;;
    iso_comp_lz4:*)  printf '%s\n' "schnellstes Verfahren, größte Images" ;;
    iso_comp_default:EN) printf '%s\n' "   [default]" ;;
    iso_comp_default:*)  printf '%s\n' "   [Standard]" ;;
    iso_choose_comp:EN) printf '%s\n' "Choose SquashFS compression" ;;
    iso_choose_comp:*)  printf '%s\n' "SquashFS-Kompression wählen" ;;
    iso_comp_invalid:EN) printf 'Invalid input (1-%s or empty).\n'  "$1" ;;
    iso_comp_invalid:*) printf 'Ungültige Eingabe (1-%s oder leer).\n'  "$1" ;;
    iso_menu_title:EN) printf '%s\n' "Create live ISO from the running system" ;;
    iso_menu_title:*)  printf '%s\n' "Live-ISO vom laufenden System erstellen" ;;
    iso_summary:EN) printf '%s\n' "Summary:" ;;
    iso_summary:*)  printf '%s\n' "Zusammenfassung:" ;;
    iso_sum_work:EN) printf '  Work directory: %s\n'  "$1" ;;
    iso_sum_work:*) printf '  Arbeitsverzeichnis: %s\n'  "$1" ;;
    iso_sum_target:EN) printf '  Target:             %s\n'  "$1" ;;
    iso_sum_target:*) printf '  Ziel:               %s\n'  "$1" ;;
    iso_sum_excludes:EN) printf '  Exclusions:         %s\n'  "$1" ;;
    iso_sum_excludes:*) printf '  Ausschlüsse:        %s\n'  "$1" ;;
    iso_sum_no_excludes:EN) printf '%s\n' "  Exclusions:         (none)" ;;
    iso_sum_no_excludes:*)  printf '%s\n' "  Ausschlüsse:        (keine)" ;;
    exp_desc_part:EN) printf '%s\n' "Partitioner" ;;
    exp_desc_part:*)  printf '%s\n' "Partitionierer" ;;
    exp_desc_iso:EN) printf '%s\n' "ISO creation" ;;
    exp_desc_iso:*)  printf '%s\n' "ISO-Erstellung" ;;
    exp_desc_install:EN) printf '%s\n' "Installation" ;;
    exp_desc_install:*)  printf '%s\n' "Installation" ;;
    exp_title:EN) printf '%s\n' "Export individual scripts" ;;
    exp_title:*)  printf '%s\n' "Einzelskripte exportieren" ;;
    exp_which_parts:EN) printf '%s\n' "Which parts? " ;;
    exp_which_parts:*)  printf '%s\n' "Welche Teile? " ;;
    exp_parts_hint:EN) printf '%s\n' "e.g. 2 or 1,3; Enter = all three, 0 = Back, 00 = Quit" ;;
    exp_parts_hint:*)  printf '%s\n' "z. B. 2 oder 1,3; Enter = alle drei, 0 = Abbrechen, 00 = Ende" ;;
    exp_sel_invalid:EN) printf '%s\n' "Invalid input - allowed: 1, 2 or 3, comma separated (e.g. 1,3)." ;;
    exp_sel_invalid:*)  printf '%s\n' "Ungültige Eingabe - erlaubt: 1, 2 oder 3, kommasepariert (z. B. 1,3)." ;;
    err_exp_no_marker:EN) printf "Block marker '%s' not found in '%s'.\n"  "$1" "$2" ;;
    err_exp_no_marker:*) printf "Blockmarkierung '%s' in '%s' nicht gefunden.\n"  "$1" "$2" ;;
    err_exp_no_core:EN) printf "Core header not found in '%s' - export not possible.\n"  "$1" ;;
    err_exp_no_core:*) printf "Kernkopf in '%s' nicht gefunden - Export nicht möglich.\n"  "$1" ;;
    err_exp_need_sel:EN) printf '%s is missing the selection (e.g. 1,2,3).\n'  "$1" ;;
    err_exp_need_sel:*) printf 'Für %s fehlt die Auswahl (z. B. 1,2,3).\n'  "$1" ;;
    err_need_dir:EN) printf '%s is missing a directory.\n'  "$1" ;;
    err_need_dir:*) printf 'Für %s fehlt ein Verzeichnis.\n'  "$1" ;;
    err_need_path:EN) printf '%s is missing a path.\n'  "$1" ;;
    err_need_path:*) printf 'Für %s fehlt ein Pfad.\n'  "$1" ;;
    err_need_label:EN) printf '%s is missing a label.\n'  "$1" ;;
    err_need_label:*) printf 'Für %s fehlt ein Label.\n'  "$1" ;;
    err_need_algo:EN) printf '%s is missing an algorithm (xz, zstd, lzma, gzip, lzo, lz4).\n'  "$1" ;;
    err_need_algo:*) printf 'Für %s fehlt ein Algorithmus (xz, zstd, lzma, gzip, lzo, lz4).\n'  "$1" ;;
    err_need_excludes:EN) printf '%s is missing the exclusions.\n'  "$1" ;;
    err_need_excludes:*) printf 'Für %s fehlen die Ausschlüsse.\n'  "$1" ;;
    err_need_device:EN) printf '%s is missing a device.\n'  "$1" ;;
    err_need_device:*) printf 'Für %s fehlt ein Gerät.\n'  "$1" ;;
    err_unknown_arg:EN) printf 'Unknown argument: %s (help: %s)\n'  "$1" "$2" ;;
    err_unknown_arg:*) printf 'Unbekanntes Argument: %s (Hilfe: %s)\n'  "$1" "$2" ;;
    err_unknown_opt:EN) printf 'Unknown option: %s (help: %s)\n'  "$1" "$2" ;;
    err_unknown_opt:*) printf 'Unbekannte Option: %s (Hilfe: %s)\n'  "$1" "$2" ;;
    err_unknown_cmd:EN) printf 'Unknown command: %s\n'  "$1" ;;
    err_unknown_cmd:*) printf 'Unbekannter Befehl: %s\n'  "$1" ;;
    err_exp_bad_sel:EN) printf "Invalid selection: '%s' (allowed: 1, 2, 3 - e.g. -s 1,2,3)\n"  "$1" ;;
    err_exp_bad_sel:*) printf "Ungültige Auswahl: '%s' (erlaubt: 1, 2, 3 - z. B. -s 1,2,3)\n"  "$1" ;;
    err_exp_outdir:EN) printf "Target directory '%s' could not be created.\n"  "$1" ;;
    err_exp_outdir:*) printf "Zielverzeichnis '%s' konnte nicht angelegt werden.\n"  "$1" ;;
    err_exp_chmod:EN) printf 'chmod failed: %s\n'  "$1" ;;
    err_exp_chmod:*) printf 'chmod fehlgeschlagen: %s\n'  "$1" ;;
    err_exp_invalid_script:EN) printf 'Generated script is invalid and will be removed: %s\n'  "$1" ;;
    err_exp_invalid_script:*) printf 'Erzeugtes Skript ist ungültig und wird entfernt: %s\n'  "$1" ;;
    err_exp_aborted:EN) printf '%s\n' "Export aborted - at least one script was faulty." ;;
    err_exp_aborted:*)  printf '%s\n' "Export abgebrochen - mindestens ein Skript war fehlerhaft." ;;
    exp_done:EN) printf '%s\n' "Export finished" ;;
    exp_done:*)  printf '%s\n' "Export abgeschlossen" ;;
    err_iso_one_target:EN) printf '%s\n' "Only one ISO target may be given." ;;
    err_iso_one_target:*)  printf '%s\n' "Nur ein ISO-Ziel angeben." ;;
    err_iso_umount_failed:EN) printf "'%s' could not be unmounted!\n"  "$1" ;;
    err_iso_umount_failed:*) printf "'%s' konnte nicht ausgehängt werden!\n"  "$1" ;;
    grub_std:EN) printf '%s\n' "Standard (quiet splash)" ;;
    grub_std:*)  printf '%s\n' "Standard (quiet splash)" ;;
    grub_verbose:EN) printf '%s\n' "verbose (error diagnosis)" ;;
    grub_verbose:*)  printf '%s\n' "ausführlich (Fehlerdiagnose)" ;;
    grub_toram:EN) printf '%s\n' "load completely into RAM (toram)" ;;
    grub_toram:*)  printf '%s\n' "vollständig in den RAM laden (toram)" ;;
    grub_nomodeset:EN) printf '%s\n' "bypass graphics problems (nomodeset)" ;;
    grub_nomodeset:*)  printf '%s\n' "Grafikprobleme umgehen (nomodeset)" ;;
    *) printf '%s\n' "$key" ;;
    esac
}
te() { t "$@" >&2; }
td() { te "$@"; exit 1; }



#@@BLOCK:COMMON
# ============================================================
# Farben
# ============================================================

USE_COLOR="j"

# -nc / --no-color: Farben abschalten; Flags aus den Argumenten entfernen
no_color_args=()
for a in "$@"; do
    if [[ "$a" == "--no-color" || "$a" == "-nc" ]]; then
        USE_COLOR="n"
    else
        no_color_args+=("$a")
    fi
done
set -- "${no_color_args[@]}"

# FALLBACK_MODUS - Kompatibilitätsweg für ältere Debian-Versionen (vor 25.04,
# live-boot schreibt dort andere Autologin-/Sitzungsformate):
#   auto (Standard) = ältere Version automatisch erkennen und für sie den
#     normalen Weg nutzen (offizielles Initramfs des Live-Mediums bzw.
#     Systemkonfiguration; update-grub im Installer); neuere Versionen wie
#     bisher (Mini-Confdir, handgeschriebene grub.cfg)
#   an = Fallback erzwingen; aus = Fallback niemals verwenden
FALLBACK_MODUS="auto"

# ist_altes_debian - wahr für Debian-Versionen vor 25.04 (altes live-boot-
# Autologin-/Sitzungsformat), gelesen aus /etc/os-release des laufenden
# Systems (= das Quell-System des Abbilds)
ist_altes_debian() {
    local vid
    vid="$(sed -n 's/^VERSION_ID="\?\([^"]*\)"\?$/\1/p' /etc/os-release 2>/dev/null | head -n1 || true)"
    [[ -n "$vid" ]] || return 1
    awk -v v="$vid" 'BEGIN {
        split(v, a, ".")
        exit !((a[1] + 0) < 25 || ((a[1] + 0) == 25 && (a[2] + 0) < 4))
    }'
}

# fallback_aktiv - entscheidet anhand FALLBACK_MODUS und Debian-Version
fallback_aktiv() {
    case "$FALLBACK_MODUS" in
        an) return 0 ;;
        aus) return 1 ;;
        *) ist_altes_debian ;;
    esac
}

# init_colors - Farbcodes je nach Terminal und NO_COLOR setzen
init_colors() {
    if [[ "$USE_COLOR" == "j" && -t 1 && -z "${NO_COLOR:-}" ]]; then
        C_HEAD=$'\e[1;36m'
        C_TEXT=$'\e[1;33m'
        C_FILE=$'\e[1;35m'
        C_MISC=$'\e[1;32m'
        C_ERR=$'\e[1;31m'
        C_OFF=$'\e[0m'
    else
        C_HEAD=""
        C_TEXT=""
        C_FILE=""
        C_MISC=""
        C_ERR=""
        C_OFF=""
    fi
}

init_colors

# ---------- Ausgabe-Helfer ----------

head_msg() { printf '\n%s\n' "${C_HEAD}=== $* ===${C_OFF}"; }

txt()   { printf '%s\n' "${C_TEXT}$*${C_OFF}"; }
misc()  { printf '%s\n' "${C_MISC}$*${C_OFF}"; }
warn()  { printf '%s\n' "${C_TEXT}$(t word_warning): $*${C_OFF}"; }
err()   { printf '%s\n' "${C_ERR}>>> $*${C_OFF}" >&2; }

fstr()  { printf '%s' "${C_FILE}$*${C_OFF}"; }

die() {
    printf '\n%s\n' "${C_ERR}>>> $(t word_error): $*${C_OFF}" >&2
    exit 3
}

dump_misc() { "$@" 2>&1 | sed "s/^/${C_MISC}/; s/$/${C_OFF}/"; }

# ---------- Eingabe-Helfer (Zahlen-Auswahl) ----------

INTERACTIVE="n"
INPUT=""
USER_ABORTED="n"

get_input() {
    INPUT=""
    if [[ -t 0 ]]; then
        read -r INPUT && return 0
    else
        read -r INPUT </dev/tty 2>/dev/null && return 0
    fi
    return 1
}

quit_all() {
    # 00 = GESAMTES Skript SOFORT beenden (42 = Quit-All-Signal, wird von
    # run_action durchgereicht und vom aufrufenden Bündel-Skript ausgewertet)
    exit 42
}

menu_select() {
    local title="$1"
    shift
    local -a opts=("$@")
    local o pick

    head_msg "$title"
    local i=1
    for o in "${opts[@]}"; do
        misc "  ${i}) ${o}"
        i=$((i + 1))
    done
    while :; do
        printf '%s' "${C_TEXT}$(t menu_choice)${C_MISC}[1-${#opts[@]}, $(t menu_abort_quit)]: ${C_OFF}"
        get_input || { USER_ABORTED="j"; return 1; }
        pick="${INPUT:-0}"
        case "$pick" in
            00) quit_all ;;
            0|q|Q) USER_ABORTED="j"; return 1 ;;
        esac
        if [[ ! "$pick" =~ ^[0-9]+$ ]]; then
            misc "$(t menu_enter_number)"
            continue
        fi
        if (( pick >= 1 && pick <= ${#opts[@]} )); then
            MENU_NR="$pick"
            USER_ABORTED="n"
            return 0
        fi
        misc "$(t menu_invalid_number "${#opts[@]}")"
    done
}

ask_string() {
    local prompt="$1" def="${2:-}"
    if [[ -n "$def" ]]; then
        printf '%s' "${C_TEXT}${prompt} ${C_MISC}[${def}]: ${C_OFF}"
    else
        printf '%s' "${C_TEXT}${prompt}: ${C_OFF}"
    fi
    get_input || return 1
    ANSWER="${INPUT:-$def}"
    return 0
}

confirm_yes() {
    if [[ "${ASSUME_YES:-n}" == "j" ]]; then
        return 0
    fi
    printf '%s' "${C_TEXT}$1 ${C_MISC}[$(t q_jn)]: ${C_OFF}"
    get_input || return 1
    case "${INPUT,,}" in
        ""|j|ja|y|yes) return 0 ;;
        *) return 1 ;;
    esac
}

confirm_ja_nein() {
    if [[ "${ASSUME_YES:-n}" == "j" ]]; then
        return 0
    fi
    while :; do
        printf '%s' "${C_TEXT}$(t q_confirm_continue) ${C_MISC}[$(t q_jn_lower)]: ${C_OFF}"
        get_input || return 1
        case "${INPUT,,}" in
            j|ja|y|yes) return 0 ;;
            n|nein|no) return 1 ;;
            "")
                # DEBIAN: Enter = bestatigen (Anzeige zeigt [Y/n])
                return 0 ;;
            *)
                misc "$(t q_yes_no_please)"
                continue ;;
        esac
    done
}

pause_key() {
    printf '%s' "${C_TEXT}$(t info_press_enter)${C_OFF}"
    get_input >/dev/null 2>&1 || true
    printf '\n'
}

# ---------- Root / Umgebung ----------

invoking_home() {
    local u="${SUDO_USER:-}" h=""
    if [[ -n "$u" ]]; then
        h="$(getent passwd "$u" 2>/dev/null | cut -d: -f6 || true)"
    fi
    if [[ -z "$h" ]]; then
        h="${HOME:-/root}"
    fi
    printf '%s\n' "$h"
}

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        txt "$(t info_requesting_root)"
        # Zusatzargumente (z. B. --action <funktion>) durchreichen: nach dem
        # Root-Wechsel wird die GEWAEHLTE Aktion direkt ausgefuehrt, ohne
        # erneutes Menue (Regel Nutzer).
        exec sudo bash "$SCRIPT_PATH" "${ORIG_ARGS[@]}" "$@"
    fi
}

# ============================================================
# Geräte-Grundlagen (sfdisk/lsblk, alles read-only)
# ============================================================

sfdisk_dump() {
    sfdisk -d "$1" 2>/dev/null || true
}

disk_table() {
    sfdisk_dump "$1" | sed -n 's/^label: *//p' | head -n1
}

disk_is_gpt() {
    [[ "$(disk_table "$1")" == "gpt" ]]
}

disk_has_biosboot() {
    sfdisk_dump "$1" | grep -qi "21686148-6449-6e6f-744e-656564454649" || return 1
    return 0
}

part_regions() {
    local disk="$1" base
    base="${disk##*/}"
    sfdisk_dump "$disk" | while IFS= read -r line; do
        local dev start size nr
        [[ "$line" == *" : start="* ]] || continue
        dev="${line%% :*}"
        dev="${dev##*/}"
        start="$(printf '%s\n' "$line" | sed -n 's/.*start= *\([0-9]*\),.*/\1/p')"
        size="$(printf '%s\n' "$line" | sed -n 's/.*size= *\([0-9]*\),.*/\1/p')"
        nr="${dev#"$base"}"
        nr="${nr#p}"
        [[ "$nr" =~ ^[0-9]+$ ]] || continue
        [[ -n "$start" && -n "$size" ]] || continue
        printf '%s %s %s\n' "$start" "$size" "$nr"
    done | sort -n
}

part_nrs() {
    local start size nr
    part_regions "$1" | while read -r start size nr; do
        printf '%s\n' "$nr"
    done | sort -n
}

sector_size() {
    local s
    s="$(blockdev --getss "$1" 2>/dev/null)" || s=""
    if [[ ! "$s" =~ ^[0-9]+$ ]] || (( s < 512 )); then
        s=512
    fi
    printf '%s\n' "$s"
}

part_prefix() {
    local dev="$1"
    case "$dev" in
        *[0-9]) printf '%sp\n' "$dev" ;;
        *) printf '%s\n' "$dev" ;;
    esac
}

compute_gaps() {
    local disk="$1"
    local SECTOR ALIGN first last total_bytes
    SECTOR="$(sector_size "$disk")"
    ALIGN=$((1048576 / SECTOR))

    first="$(sfdisk_dump "$disk" | sed -n 's/^first-lba: *//p' | head -n1)"
    last="$(sfdisk_dump "$disk" | sed -n 's/^last-lba: *//p' | head -n1)"
    if [[ -z "$first" || -z "$last" ]]; then
        total_bytes="$(blockdev --getsize64 "$disk" 2>/dev/null)" || return 1
        [[ "$total_bytes" =~ ^[0-9]+$ ]] || return 1
        first="$ALIGN"
        last=$((total_bytes / SECTOR - 1))
    fi

    local -a occ=()
    local s sz nr dev e
    while read -r s sz nr; do
        [[ -n "$s" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        if part_is_extended "$dev"; then
            continue
        fi
        e=$((s + sz - 1))
        s=$((s / ALIGN * ALIGN))
        if (( e % ALIGN )); then
            e=$(( (e / ALIGN + 1) * ALIGN - 1 ))
        fi
        if (( e >= s )); then
            occ+=("$s $e")
        fi
    done < <(part_regions "$disk")

    first=$(((first + ALIGN - 1) / ALIGN * ALIGN))
    last=$((last / ALIGN * ALIGN))

    local cur="$first" r
    for r in "${occ[@]}"; do
        [[ -n "$r" ]] || continue
        s="${r% *}"
        e="${r#* }"
        if (( s > cur )); then
            printf '%s %s\n' "$cur" $((s - 1))
        fi
        if (( e >= cur )); then
            cur=$((e + 1))
        fi
    done
    if (( last >= cur )); then
        printf '%s %s\n' "$cur" "$last"
    fi
    return 0
}

fmt_mib() {
    local mib="$1"
    if (( mib >= 1024 )); then
        awk -v m="$mib" 'BEGIN{printf "%.1f GiB", m/1024}'
    else
        printf '%s MiB' "$mib"
    fi
}

sectors_to_mib() {
    printf '%s\n' $((($1 * $2) / 1048576))
}

lsblk_val() {
    local v
    v="$(lsblk -nro "$1" "$2" 2>/dev/null | head -n1 || true)"
    printf '%s' "${v//\\x20/ }"
}

part_is_extended() {
    local t
    t="$(lsblk_val PARTTYPE "$1")"
    case "$t" in
        0x5|0x05|0x0f|0x0F|0x85|5|f|F|85) return 0 ;;
    esac
    case "$(lsblk_val PARTTYPENAME "$1")" in
        *[Ee]xtended*) return 0 ;;
    esac
    return 1
}

dev_is_mounted() {
    findmnt -rn -S "$1" >/dev/null 2>&1
}

gap_lage() {
    local disk="$1" gs="$2" ge="$3"
    local start size nr before="" after="" end
    while read -r start size nr; do
        [[ -n "$nr" ]] || continue
        end=$((start + size - 1))
        if (( end < gs )); then
            before="$nr"
        fi
        if [[ -z "$after" ]] && (( start > ge )); then
            after="$nr"
        fi
    done < <(part_regions "$disk")

    if [[ -n "$before" && -n "$after" ]]; then
        printf '%s' "$(t part_gap_between "$before" "$after")"
    elif [[ -n "$before" ]]; then
        printf '%s' "$(t part_gap_after "$before")"
    elif [[ -n "$after" ]]; then
        printf '%s' "$(t part_gap_before "$after")"
    else
        printf '%s' "$(t part_gap_empty)"
    fi
    return 0
}

# ============================================================
# Live-Medium erkennen (3-stufig)
# ============================================================

resolve_disk() {
    local dev="$1" real pk
    [[ -n "$dev" ]] || return 1
    case "$dev" in
        LABEL=*) real="$(blkid -L "${dev#LABEL=}" 2>/dev/null || true)" ;;
        UUID=*) real="$(blkid -U "${dev#UUID=}" 2>/dev/null || true)" ;;
        PARTUUID=*) real="$(blkid -t "$dev" -o device 2>/dev/null | head -n1 || true)" ;;
        *) real="$dev" ;;
    esac
    [[ -n "$real" ]] || return 1
    if [[ -e "$real" ]]; then
        real="$(readlink -f "$real" 2>/dev/null || true)"
        [[ -n "$real" ]] || return 1
    fi
    [[ -b "$real" ]] || return 1
    if [[ "$(lsblk -ndo TYPE "$real" 2>/dev/null)" == "disk" ]]; then
        printf '%s\n' "$real"
        return 0
    fi
    pk="$(lsblk -nro PKNAME "$real" 2>/dev/null | head -n1 || true)"
    [[ -n "$pk" ]] || return 1
    printf '/dev/%s\n' "$pk"
}

live_medium_from_bootmnt() {
    local src
    src="$(findmnt -nro SOURCE /cdrom 2>/dev/null || true)"
    if [[ -z "$src" ]]; then
        src="$(findmnt -nro SOURCE /run/live/medium 2>/dev/null || true)"
    fi
    [[ -n "$src" ]] || return 1
    resolve_disk "$src"
}

live_medium_from_squash() {
    local src back dev
    while read -r src; do
        [[ "$src" == /dev/loop* ]] || continue
        back="$(losetup -no BACK-FILE "$src" 2>/dev/null || true)"
        case "$back" in
            */filesystem.squashfs|*/live-boot/*.squashfs|*/live/*.squashfs) ;;
            *) continue ;;
        esac
        dev="$(findmnt -nro SOURCE -T "$back" 2>/dev/null || true)"
        [[ -n "$dev" ]] || continue
        if resolve_disk "$dev"; then
            return 0
        fi
    done < <(findmnt -rn -o SOURCE -t squashfs 2>/dev/null)
    return 1
}

live_medium_from_iso9660() {
    local dev dtype fstype pk
    while read -r dev dtype fstype; do
        [[ -n "$dev" ]] || continue
        [[ "$fstype" == "iso9660" ]] || continue
        if [[ "$dtype" == "disk" ]]; then
            printf '%s\n' "$dev"
            return 0
        fi
        pk="$(lsblk -nro PKNAME "$dev" 2>/dev/null | head -n1 || true)"
        if [[ -n "$pk" ]]; then
            printf '/dev/%s\n' "$pk"
        else
            printf '%s\n' "$dev"
        fi
        return 0
    done < <(lsblk -pnrno NAME,TYPE,FSTYPE 2>/dev/null)
    return 1
}

detect_live_medium() {
    local dev
    dev="$(live_medium_from_bootmnt || true)"
    if [[ -z "$dev" ]]; then dev="$(live_medium_from_squash || true)"; fi
    if [[ -z "$dev" ]]; then dev="$(live_medium_from_iso9660 || true)"; fi
    if [[ -n "$dev" ]]; then
        printf '%s\n' "$dev"
    fi
    return 0
}

# ============================================================
# Paket-Backend (apt/dpkg) + Formatieren
# ============================================================

ensure_tool() {
    local tool="$1" pkg="$2" kontext="${3:-Aktion}"
    if command -v "$tool" >/dev/null 2>&1; then
        return 0
    fi

    if [[ "$INTERACTIVE" == "j" ]]; then
        if ! confirm_yes "$(t q_tool_missing_install "$tool" "$pkg")"; then
            warn "$(t warn_ctx_aborted "$kontext" "$tool")"
            return 1
        fi
    fi

    misc "$(t info_installing_pkg "$pkg")"
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >/dev/null 2>&1; then
        misc "$(t info_retry_apt_update)"
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >/dev/null 2>&1; then
            err "$(t err_tool_install_failed "$tool" "$pkg")"
            return 1
        fi
    fi

    if command -v "$tool" >/dev/null 2>&1; then
        misc "$(t info_tool_now_available "$tool")"
        return 0
    fi
    err "$(t err_tool_install_failed_short "$tool" "$pkg")"
    return 1
}

pkg_missing() {
    local p st
    for p in "$@"; do
        st="$(dpkg-query -W -f="\${db:Status-Abbrev}" "$p" 2>/dev/null || true)"
        if [[ "$st" != ii* ]]; then
            printf '%s\n' "$p"
        fi
    done
}

# ---------- Eingebauter FAT32-Formatierer (Ersatz für mkfs.vfat) ----------

fat_le16() {
    printf '%b' \
        "\\x$(printf '%02x' $(( $1 & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 256) & 255 )))"
}

fat_le32() {
    printf '%b' \
        "\\x$(printf '%02x' $(( $1 & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 256) & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 65536) & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 16777216) & 255 )))"
}

mkfs_fat32_builtin() {
    local dev="$1" label="${2:-NO NAME}"
    local SS bytes total_sect sc fat_sz reserved=32 nfats=2
    local data_start clusters cluster_bytes

    SS="$(sector_size "$dev")"
    case "$SS" in
        512|1024|2048|4096) : ;;
        *)
            err "$(t err_fat32_sector_size "$SS")"
            return 1 ;;
    esac

    bytes="$(blockdev --getsize64 "$dev" 2>/dev/null)" || bytes=""
    if [[ ! "$bytes" =~ ^[0-9]+$ ]] || (( bytes == 0 )); then
        bytes="$(stat -c%s "$dev" 2>/dev/null)" || bytes=""
    fi
    if [[ ! "$bytes" =~ ^[0-9]+$ ]] || (( bytes == 0 )); then
        err "$(t err_fat32_size_unknown "$dev")"
        return 1
    fi
    total_sect=$((bytes / SS))
    if (( total_sect >= 4294967296 )); then
        err "$(t err_fat32_too_large "$bytes")"
        return 1
    fi

    if   (( bytes <= 272629760 ));   then cluster_bytes=$SS
    elif (( bytes <= 8589934592 ));  then cluster_bytes=4096
    elif (( bytes <= 17179869184 )); then cluster_bytes=8192
    elif (( bytes <= 34359738368 )); then cluster_bytes=16384
    elif (( bytes <= 549755813888 )); then cluster_bytes=32768
    else cluster_bytes=65536
    fi
    if (( cluster_bytes < SS )); then
        cluster_bytes=$SS
    fi
    sc=$((cluster_bytes / SS))
    if (( sc > 128 )); then
        err "$(t err_fat32_cluster_invalid "$SS")"
        return 1
    fi

    fat_sz=$(( (total_sect / sc) * 4 / SS + 2 ))
    local needed i
    for i in 1 2 3 4 5 6 7 8; do
        data_start=$(( reserved + fat_sz * nfats ))
        if (( data_start + sc > total_sect )); then
            err "$(t err_fat32_too_small)"
            return 1
        fi
        clusters=$(( (total_sect - data_start) / sc ))
        needed=$(( ( (clusters + 2) * 4 + SS - 1 ) / SS ))
        fat_sz=$needed
    done
    data_start=$(( reserved + fat_sz * nfats ))
    clusters=$(( (total_sect - data_start) / sc ))
    if (( clusters < 65525 )); then
        warn "$(t warn_fat32_few_clusters "$clusters")"
    fi
    if (( clusters > 268435446 )); then
        err "$(t err_fat32_many_clusters "$clusters")"
        return 1
    fi

    misc "$(t info_fat32_builtin "$cluster_bytes" "$clusters" "$((fat_sz * SS / 1024))")"

    if ! (
        tmpdir="$(mktemp -d)" || exit 1
        trap 'rm -rf "$tmpdir"' EXIT

        boot="$tmpdir/boot"
        {
            printf '\xeb\x3c\x90'
            printf 'UBUNTULIVE'
            fat_le16 "$SS"
            case "$sc" in
                1) printf '\x01' ;;
                2) printf '\x02' ;;
                4) printf '\x04' ;;
                8) printf '\x08' ;;
                16) printf '\x10' ;;
                32) printf '\x20' ;;
                64) printf '\x40' ;;
                128) printf '\x80' ;;
            esac
            fat_le16 32
            printf '\x02'
            fat_le16 0
            if (( total_sect < 65536 )); then
                fat_le16 "$total_sect"
            else
                fat_le16 0
            fi
            printf '\xf8'
            fat_le16 0
            fat_le16 63
            fat_le16 255
            fat_le32 0
            if (( total_sect >= 65536 )); then
                fat_le32 "$total_sect"
            else
                fat_le32 0
            fi
            fat_le32 "$fat_sz"
            fat_le16 0
            fat_le16 0
            fat_le32 2
            fat_le16 1
            fat_le16 6
            dd if=/dev/zero bs=1 count=12 2>/dev/null
            printf '\x80\x00\x29'
            head -c 4 /dev/urandom
            printf '%-11.11s' "$label"
            printf 'FAT32   '
            dd if=/dev/zero bs=1 count=420 2>/dev/null
            printf '\x55\xaa'
        } > "$boot"
        [[ "$(stat -c%s "$boot")" -eq 512 ]] || exit 1

        fsinfo="$tmpdir/fsinfo"
        {
            printf '\x52\x52\x61\x41'
            dd if=/dev/zero bs=1 count=480 2>/dev/null
            printf '\x72\x72\x41\x61'
            fat_le32 $((clusters - 1))
            fat_le32 3
            dd if=/dev/zero bs=1 count=14 2>/dev/null
            printf '\x55\xaa'
        } > "$fsinfo"
        [[ "$(stat -c%s "$fsinfo")" -eq 512 ]] || exit 1

        fat="$tmpdir/fat"
        printf '\xf8\xff\xff\x0f\xff\xff\xff\x0f\xff\xff\xff\x0f' > "$fat" || exit 1
        truncate -s $((fat_sz * SS)) "$fat" || exit 1
        dd if="$boot" of="$dev" bs="$SS" seek=0 conv=notrunc 2>/dev/null || exit 1
        dd if="$fsinfo" of="$dev" bs="$SS" seek=1 conv=notrunc 2>/dev/null || exit 1
        dd if="$boot" of="$dev" bs="$SS" seek=6 conv=notrunc 2>/dev/null || exit 1
        dd if="$fsinfo" of="$dev" bs="$SS" seek=7 conv=notrunc 2>/dev/null || exit 1
        dd if="$fat" of="$dev" bs="$SS" seek=$reserved conv=notrunc 2>/dev/null || exit 1
        dd if="$fat" of="$dev" bs="$SS" seek=$((reserved + fat_sz)) conv=notrunc 2>/dev/null || exit 1
        if [[ "$label" != "NO NAME" ]]; then
            rootfile="$tmpdir/root"
            {
                printf '%-11.11s' "$label"
                printf '\x08'
                dd if=/dev/zero bs=1 count=$((SS - 12)) 2>/dev/null
            } > "$rootfile"
            [[ "$(stat -c%s "$rootfile")" -eq "$SS" ]] || exit 1
            dd if="$rootfile" of="$dev" bs="$SS" seek=$data_start count=1 conv=notrunc 2>/dev/null || exit 1
            if (( sc > 1 )); then
                dd if=/dev/zero of="$dev" bs="$SS" seek=$((data_start + 1)) count=$((sc - 1)) conv=notrunc 2>/dev/null || exit 1
            fi
        else
            dd if=/dev/zero of="$dev" bs="$SS" seek=$data_start count=$sc conv=notrunc 2>/dev/null || exit 1
        fi
    ); then
        err "$(t err_fat32_create_failed "$dev")"
        return 1
    fi

    sync
    return 0
}

make_fs() {
    local dev="$1" fs="$2"
    local -a mkfs_cmd=()

    if dev_is_mounted "$dev"; then
        err "$(t err_dev_mounted_unplug "$(fstr "$dev")")"
        return 1
    fi

    wipefs -a "$dev" >/dev/null 2>&1 || true

    case "$fs" in
        ext4)
            if ! command -v mkfs.ext4 >/dev/null 2>&1; then
                err "$(t err_mkfs_ext4_missing)"
                return 1
            fi
            mkfs_cmd=(mkfs.ext4 -q -F "$dev") ;;
        vfat)
            if command -v mkfs.vfat >/dev/null 2>&1; then
                mkfs_cmd=(mkfs.vfat -F32 "$dev")
            elif command -v mkfs.fat >/dev/null 2>&1; then
                mkfs_cmd=(mkfs.fat -F32 "$dev")
            else
                if mkfs_fat32_builtin "$dev"; then
                    misc "$(t info_fs_vfat_builtin "$(fstr "$dev")")"
                    return 0
                fi
                err "$(t err_format_fat32_failed "$dev")"
                return 1
            fi ;;
        swap)
            if ! command -v mkswap >/dev/null 2>&1; then
                err "$(t err_mkswap_missing)"
                return 1
            fi
            mkfs_cmd=(mkswap "$dev") ;;
        ntfs)
            if ! command -v mkfs.ntfs >/dev/null 2>&1; then
                err "$(t err_mkfs_ntfs_missing)"
                return 1
            fi
            mkfs_cmd=(mkfs.ntfs -f "$dev") ;;
        *) return 1 ;;
    esac

    misc "$(t info_formatting "$(fstr "$dev")" "$fs")"
    if "${mkfs_cmd[@]}" >/dev/null 2>&1; then
        misc "$(t info_fs_created "$fs" "$(fstr "$dev")")"
        return 0
    fi
    err "$(t err_format_failed "$dev" "$fs")"
    return 1
}

# liveboot_live_cleanup - entfernt live-boot-Reste der Live-Sitzung aus einem
# Systembaum ($1 = Wurzel, z. B. /mnt oder "$MERGED"). Struktur-Garantie
# (Änderung 41): Autologin-Konfiguration wird KOMPLETT entfernt (sddm inkl.
# conf.d, lightdm, gdm3) - ein frisch installiertes System startet immer
# mit dem Login-Bildschirm, ganz gleich welche live-boot-Version welche
# [Autologin]-Blöcke (Live-Benutzer-Phantom, eigene Blöcke) hinterlassen
# hat; genau wie bei einer normalen Debian-Installation. Das Live-System
# selbst setzt sein Autologin bei jedem Boot neu (live-boot 15autologin) -
# die Bereinigung stoert die Live-Sitzung nicht. Dazu: der Live-Benutzer
# (leeres Passwort, passwortloses sudo via /etc/sudoers.d/live-boot) wird
# entfernt und die live-boot-Diverts (update-initramfs-Stub, anacron) werden
# rueckgebaut, damit Initramfs-Bau und Kernel-Updates funktionieren.
liveboot_live_cleanup() {
    local root="$1"
    [[ -n "$root" && "$root" != "/" && -d "$root/etc" && -f "$root/etc/passwd" ]] || return 0

    # Live-Benutzer erkennen: GECOS "Live session user" (live-boot setz den
    # Namen zur Bootzeit je nach Flavour, der GECOS bleibt konstant)
    local live_user=""
    live_user="$(awk -F: '$5 == "Live session user" || $5 == "Debian Live user" { print $1; exit }' \
        "$root/etc/passwd" 2>/dev/null || true)"
    if [[ -z "$live_user" && -f "$root/etc/live-boot.conf" ]]; then
        local conf_user
        conf_user="$(sed -n 's/^export USERNAME="\([^"]*\)"$/\1/p' \
            "$root/etc/live-boot.conf" 2>/dev/null | head -n1 || true)"
        if [[ -n "$conf_user" ]] && grep -qs "^${conf_user}:" "$root/etc/passwd"; then
            live_user="$conf_user"
        fi
    fi

    local tmp
    tmp="$(mktemp /tmp/ultool-cln-XXXXXX)"

    # sddm: /etc/sddm.conf UND alle Drop-ins in /etc/sddm.conf.d/ - ALLE
    # [Autologin]-Abschnitte kommen weg, ohne Rücksicht auf den Inhalt.
    # Begründung (Struktur-Garantie, siehe Änderung 41): SDDM merged alle
    # Dateien/Abschnitte, der LETZTE Block gewinnt - ein einziger
    # überlebender oder später geschriebener Block (Live-Benutzer-Phantom
    # von irgendeiner live-boot-Version) macht das System unbenutzbar. Eine
    # frische Installation zeigt deshalb IMMER den Login-Bildschirm, wie
    # bei einer normalen Debian-Installation; Autologin kann der Benutzer
    # danach selbst wieder aktivieren. [Users] nur ganz entfernen, wenn
    # er nur aus MinimumUid=999 (live-boot-Fingerabdruck) besteht.
    local sddm_file
    for sddm_file in "$root/etc/sddm.conf" "$root"/etc/sddm.conf.d/*.conf; do
        [[ -f "$sddm_file" ]] || continue
        if awk '
            function flush() { if (!drop && buf != "") printf "%s", buf; buf = "" }
            /^\[/ {
                flush()
                if ($0 == "[Autologin]") { drop = 1; kind = "auto" }
                else if ($0 == "[Users]") { drop = 1; kind = "users" }
                else { drop = 0; kind = "" }
                buf = $0 "\n"
                next
            }
            {
                buf = buf $0 "\n"
                if (kind == "users" && $0 !~ /^[[:space:]]*$/ && $0 !~ /^MinimumUid=999$/) {
                    drop = 0
                }
            }
            END { flush() }
        ' "$sddm_file" > "$tmp"; then
            if ! cmp -s "$tmp" "$sddm_file"; then
                cat "$tmp" > "$sddm_file"
                misc "$(t info_remove_autologin)"
            fi
        fi
    done

    # lightdm: alle Autologin-Zeilen weg (gleiche Struktur-Garantie)
    local ldm
    for ldm in "$root/etc/lightdm/lightdm.conf" "$root"/etc/lightdm/lightdm.conf.d/*.conf; do
        [[ -f "$ldm" ]] || continue
        if grep -qs '^autologin-user=' "$ldm"; then
            grep -vE '^autologin-user=|^autologin-user-timeout=|^autologin-guest=|^autologin-session=' \
                "$ldm" > "$tmp" || true
            cat "$tmp" > "$ldm"
            misc "$(t info_remove_autologin)"
        fi
    done

    # gdm3: AutomaticLogin-Zeilen auskommentieren (gleiche Struktur-Garantie)
    local gdm
    gdm="$root/etc/gdm3/custom.conf"
    if [[ -f "$gdm" ]] && grep -qs '^AutomaticLogin' "$gdm"; then
        sed -e 's/^AutomaticLoginEnable=true$/#AutomaticLoginEnable=true/' \
            -e 's/^AutomaticLogin=/#AutomaticLogin=/' "$gdm" > "$tmp" || true
        cat "$tmp" > "$gdm"
        misc "$(t info_remove_autologin)"
    fi

    if [[ -n "$live_user" ]]; then
        local acct
        for acct in passwd shadow group gshadow; do
            [[ -f "$root/etc/$acct" ]] || continue
            grep -v "^${live_user}:" "$root/etc/$acct" > "$tmp" || true
            if ! cmp -s "$tmp" "$root/etc/$acct"; then
                cat "$tmp" > "$root/etc/$acct"
            fi
        done
        rm -f -- "$root/etc/sudoers.d/live-boot" "$root/etc/sudoers.d/live-config" "$root/etc/sudoers.d/admin" "$root/var/mail/$live_user" \
            "$root/var/spool/mail/$live_user" 2>/dev/null || true
        if [[ -d "$root/home/$live_user" ]]; then
            rm -rf -- "${root:?}/home/${live_user:?}"
        fi
        misc "$(t info_remove_live_user "$live_user")"
    fi

    # Diverts rueckbauen, die live-boot zur Live-Boot-Zeit anlegt
    # (43disable_updateinitramfs / 25configure_init): ohne Rueckbau ist
    # update-initramfs auf dem Zielsystem ein Stub (kein Initramfs-Bau,
    # Kernel-Updates ins Leere) und anacron tot.
    if [[ -e "$root/usr/sbin/update-initramfs.distrib" ]] \
        && { [[ -L "$root/usr/sbin/update-initramfs" ]] \
            || grep -qs "update-initramfs is disabled" "$root/usr/sbin/update-initramfs" 2>/dev/null; }; then
        misc "$(t info_remove_liveboot_divert_initrd)"
        chroot "$root" dpkg-divert --remove --rename --quiet /usr/sbin/update-initramfs 2>/dev/null \
            || mv -f "$root/usr/sbin/update-initramfs.distrib" "$root/usr/sbin/update-initramfs"
    fi
    if [[ -L "$root/usr/sbin/anacron" && -e "$root/usr/sbin/anacron.distrib" ]] \
        && [[ "$(readlink "$root/usr/sbin/anacron" 2>/dev/null)" == "/bin/true" ]]; then
        misc "$(t info_remove_liveboot_divert_anacron)"
        chroot "$root" dpkg-divert --remove --rename --quiet /usr/sbin/anacron 2>/dev/null \
            || mv -f "$root/usr/sbin/anacron.distrib" "$root/usr/sbin/anacron"
    fi

    rm -f -- "$tmp"
    return 0
}

run_action() {
    local status=0
    (
        USER_ABORTED="n"
        rc=0
        "$@" || rc=$?
        if [[ "$USER_ABORTED" == "j" ]]; then
            exit 4
        fi
        exit "$rc"
    ) || status=$?
    if [[ "$status" -eq 4 ]]; then
        return 0
    fi
    if [[ "$status" -eq 42 ]]; then
        # 00-Signal: gesamtes Skript SOFORT beenden
        exit 42
    fi
    if [[ "$status" -ne 0 ]]; then
        err "$(t err_action_failed)"
    fi
    pause_key
}

#@@ENDBLOCK:COMMON

#@@BLOCK:PART
# ============================================================
# Partitionierer (interaktiv, Zahlen-Auswahl)
# ============================================================

PART_DISK=""

part_overview() {
    local disk="$PART_DISK"
    local SECTOR table fstype label tname mntp mib start size nr dev

    SECTOR="$(sector_size "$disk")"
    table="$(disk_table "$disk")"

    head_msg "$(t part_overview_title "$disk")"
    if [[ -z "$table" ]]; then
        err "$(t err_part_no_table "$disk")"
        misc "$(t info_part_use_menu2)"
        return 0
    fi
    misc "$(t part_table_info "$(fstr "$table")" "$SECTOR")"

    while read -r start size nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        mib="$(sectors_to_mib "$size" "$SECTOR")"
        fstype="$(lsblk_val FSTYPE "$dev")"
        label="$(lsblk_val LABEL "$dev")"
        tname="$(lsblk_val PARTTYPENAME "$dev")"
        mntp="$(findmnt -nro TARGET -S "$dev" 2>/dev/null | head -n1 || true)"
        txt "  $nr) $(fstr "$dev")  $(fmt_mib "$mib")  ${fstype:-raw}  ${tname:-$(t word_unknown)}${label:+ ($(t word_label): $label)}${mntp:+ [$(t word_mounted): $mntp]}"
    done < <(part_regions "$disk")

    misc "$(t part_free_areas)"
    local gcount=0 gs ge gmib
    while read -r gs ge; do
        [[ -n "$gs" ]] || continue
        gcount=$((gcount + 1))
        gmib="$(sectors_to_mib $((ge - gs + 1)) "$SECTOR")"
        misc "$(t part_gap_line "$(fmt_mib "$gmib")" "$(gap_lage "$disk" "$gs" "$ge")")"
    done < <(compute_gaps "$disk" || true)
    if (( gcount == 0 )); then
        misc "$(t part_none)"
    fi
    return 0
}

part_reread() {
    local disk="$PART_DISK"
    udevadm settle 2>/dev/null || true
    blockdev --rereadpt "$disk" 2>/dev/null || true
    partprobe "$disk" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
}

part_newtable() {
    local disk="$PART_DISK"
    head_msg "$(t part_newtable_title "$disk")"

    if ! menu_select "$(t part_choose_table)" \
        "$(t part_table_gpt)" \
        "$(t part_table_mbr)"; then
        return 0
    fi
    local kind="$MENU_NR"

    err "$(t warn_part_newtable_wipe "$(fstr "$disk")")"
    confirm_ja_nein || { misc "$(t info_nothing_changed)"; return 0; }

    misc "$(t part_wiping_disk)"
    wipefs --all --force "$disk" >/dev/null 2>&1 || true

    local sfd_out=""
    case "$kind" in
        1)
            misc "$(t part_creating_gpt)"
            if ! sfd_out="$(printf 'label: gpt\n' | sfdisk --force --no-reread --no-tell-kernel "$disk" 2>&1)"; then
                err "$(t err_gpt_failed)"
                printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
                return 1
            fi ;;
        2)
            misc "$(t part_creating_mbr)"
            if ! sfd_out="$(printf 'label: dos\n' | sfdisk --force --no-reread --no-tell-kernel "$disk" 2>&1)"; then
                err "$(t err_mbr_failed)"
                printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
                return 1
            fi ;;
    esac

    part_reread

    misc "$(t part_table_done)"
    part_overview
}

parse_size_sectors() {
    local s="$1" ALIGN="$2" SECTOR="$3" unit="" num mult
    while [[ -n "$s" ]]; do
        case "${s: -1}" in
            [0-9.,]) break ;;
            *) unit="${s: -1}$unit"; s="${s%?}" ;;
        esac
    done
    if [[ -z "$s" || "$s" == *[!0-9.,]* ]]; then
        return 1
    fi
    num="${s//,/.}"
    case "$unit" in
        ''|M|m|Mi|MiB|mi|mb) mult=1 ;;
        G|g|Gi|GiB|gi|gib) mult=1024 ;;
        T|t|Ti|TiB|ti|tib) mult=1048576 ;;
        K|k|Ki|KiB) mult=0.0009765625 ;;
        *) return 1 ;;
    esac
    local mib sect
    mib="$(awk -v n="$num" -v m="$mult" 'BEGIN{printf "%.3f", n*m}')"
    sect="$(awk -v m="$mib" -v sec="$SECTOR" 'BEGIN{printf "%d", int(m*1048576/sec)}')"
    [[ "$sect" =~ ^[0-9]+$ ]] || return 1
    sect=$((sect / ALIGN * ALIGN))
    if (( sect < ALIGN )); then
        return 1
    fi
    SIZE_SECTORS="$sect"
    return 0
}

part_create() {
    local disk="$PART_DISK"
    head_msg "$(t part_create_title "$disk")"

    local table
    table="$(disk_table "$disk")"
    if [[ -z "$table" ]]; then
        err "$(t err_part_no_table_first)"
        return 1
    fi

    local SECTOR ALIGN
    SECTOR="$(sector_size "$disk")"
    ALIGN=$((1048576 / SECTOR))

    local -a purposes=() pids=()
    purposes+=("$(t part_purpose_linux)"); pids+=(1)
    if [[ "$table" == "gpt" ]]; then
        purposes+=("$(t part_purpose_esp)"); pids+=(2)
    fi
    if [[ "$table" != "gpt" ]]; then
        purposes+=("$(t part_purpose_extended)"); pids+=(3)
    fi
    purposes+=("$(t part_purpose_swap)"); pids+=(4)
    purposes+=("$(t part_purpose_ntfs)"); pids+=(5)
    purposes+=("$(t part_purpose_fat32)"); pids+=(6)
    purposes+=("$(t part_purpose_raw)"); pids+=(7)

    menu_select "$(t part_choose_purpose)" "${purposes[@]}" || return 0
    local purpose="${pids[MENU_NR - 1]}"

    local -a gapstarts=() gapends=()
    local gs ge
    while read -r gs ge; do
        [[ -n "$gs" ]] || continue
        gapstarts+=("$gs")
        gapends+=("$ge")
    done < <(compute_gaps "$disk" || true)

    if [[ "${#gapstarts[@]}" -eq 0 ]]; then
        err "$(t err_part_no_free "$disk")"
        return 1
    fi

    local gsel=0 gsize=$((gapends[0] - gapstarts[0]))
    local idx
    for idx in "${!gapstarts[@]}"; do
        if (( gapends[idx] - gapstarts[idx] > gsize )); then
            gsel="$idx"
            gsize=$((gapends[idx] - gapstarts[idx]))
        fi
    done
    if [[ "${#gapstarts[@]}" -gt 1 ]]; then
        warn "$(t warn_part_multi_gaps)"
    fi
    local gstart="${gapstarts[$gsel]}" gend="${gapends[$gsel]}"
    local gmib
    gmib="$(sectors_to_mib $((gend - gstart + 1)) "$SECTOR")"
    misc "$(t part_gap_auto "$(fmt_mib "$gmib")" "$(gap_lage "$disk" "$gstart" "$gend")")"

    local def_mib="" ptype="" fs=""
    case "$purpose" in
        1)
            if [[ "$table" == "gpt" ]]; then ptype="0FC63DAF-8483-4772-8E79-3D69D8477DE4"; else ptype="83"; fi
            fs="ext4" ;;
        2)
            if [[ "$table" == "gpt" ]]; then ptype="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"; else ptype="ef"; fi
            def_mib="512" fs="vfat" ;;
        3)
            ptype="5" ;;
        4)
            if [[ "$table" == "gpt" ]]; then ptype="0657FD6D-A4AB-43C4-84E5-0933C84B4F4F"; else ptype="82"; fi
            fs="swap" ;;
        5)
            if [[ "$table" == "gpt" ]]; then ptype="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"; else ptype="07"; fi
            fs="ntfs" ;;
        6)
            if [[ "$table" == "gpt" ]]; then ptype="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"; else ptype="0c"; fi
            fs="vfat" ;;
        7)
            if [[ "$table" == "gpt" ]]; then ptype="0FC63DAF-8483-4772-8E79-3D69D8477DE4"; else ptype="83"; fi
            fs="" ;;
    esac

    local max_sect=$((gend - gstart + 1))
    local usable_sect=$(((max_sect - ALIGN) / ALIGN * ALIGN))
    if (( usable_sect < ALIGN )); then
        err "$(t err_part_gap_too_small)"
        return 1
    fi
    local max_mib
    max_mib="$(sectors_to_mib "$usable_sect" "$SECTOR")"
    local size_input="" sect
    while :; do
        ask_string "$(t part_q_size "$(fmt_mib "$max_mib")")" "$def_mib" || return 0
        size_input="$ANSWER"
        if [[ -z "$size_input" ]]; then
            sect="$usable_sect"
            break
        fi
        if parse_size_sectors "$size_input" "$ALIGN" "$SECTOR"; then
            sect="$SIZE_SECTORS"
            break
        fi
        misc "$(t part_q_size_invalid)"
    done
    if (( sect > usable_sect )); then
        err "$(t err_part_size_no_fit "$(fmt_mib "$max_mib")")"
        return 1
    fi

    local start="$gstart"

    local sfd_line="start=$start, size=$sect, type=$ptype"
    if [[ "$table" != "gpt" && "$ptype" != "5" ]]; then
        local nprim=0 has_ext="n" nr
        while read -r nr; do
            [[ -n "$nr" ]] || continue
            if (( nr <= 4 )); then
                nprim=$((nprim + 1))
                if part_is_extended "$(part_prefix "$disk")$nr"; then has_ext="j"; fi
            fi
        done < <(part_nrs "$disk")
        if (( nprim >= 4 )) && [[ "$has_ext" != "j" ]]; then
            err "$(t err_part_mbr_slots_full)"
            return 1
        fi
    fi

    local nrs_before new_nr="" new_dev
    nrs_before="$(part_nrs "$disk")"

    misc "$(t part_creating_line "$sfd_line")"
    local sfd_out=""
    if ! sfd_out="$(printf '%s\n' "$sfd_line" | sfdisk --force --no-reread --no-tell-kernel --append "$disk" 2>&1)"; then
        part_reread
        if [[ -z "$(comm -13 <(printf '%s\n' "$nrs_before") <(part_nrs "$disk") || true)" ]]; then
            err "$(t err_part_create_failed)"
            printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
            return 1
        fi
        warn "$(t warn_part_created_anyway)"
        printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
    fi
    part_reread

    local new_list nr
    new_list="$(comm -13 <(printf '%s\n' "$nrs_before") <(part_nrs "$disk") || true)"
    while read -r nr; do
        new_nr="$nr"
    done <<< "$new_list"
    if [[ -z "$new_nr" ]]; then
        while read -r nr; do
            new_nr="$nr"
        done < <(part_nrs "$disk")
    fi
    if [[ -z "$new_nr" ]]; then
        err "$(t err_part_no_new_nr)"
        return 1
    fi
    new_dev="$(part_prefix "$disk")$new_nr"

    local i
    for i in {1..20}; do
        if [[ -b "$new_dev" ]]; then break; fi
        sleep 1
        part_reread
    done
    if [[ ! -b "$new_dev" ]]; then
        warn "$(t warn_part_dev_not_yet "$(fstr "$new_dev")")"
    fi

    misc "$(t part_created "$(fstr "$new_dev")")"

    # Alte Dateisystem-Reste der vorherigen Partitionierung entfernen - sonst
    # zeigt blkid/lsblk das alte FS an und find_esp_on_disk überspringt eine
    # frische ESP, deren Blöcke noch eine alte ext4-Signatur tragen
    wipefs --all --force "$new_dev" >/dev/null 2>&1 || true

    if [[ -n "$fs" ]]; then
        if confirm_yes "$(t q_format_now "$fs")"; then
            make_fs "$new_dev" "$fs"
        fi
    fi

    part_overview
}

part_delete() {
    local disk="$PART_DISK"
    head_msg "$(t part_delete_title "$disk")"

    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_no_partitions)"
        return 0
    fi

    local -a opts=() nrsel=()
    local nr dev mib SECTOR fstype sz
    SECTOR="$(sector_size "$disk")"
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        if dev_is_mounted "$dev"; then
            opts+=("$dev  ($(t word_mounted_protected))")
        else
            sz="$(part_regions "$disk" | awk -v n="$nr" '$3 == n {print $2; exit}')"
            [[ "$sz" =~ ^[0-9]+$ ]] || sz=0
            mib="$(sectors_to_mib "$sz" "$SECTOR")"
            fstype="$(lsblk_val FSTYPE "$dev")"
            opts+=("$dev  $(fmt_mib "$mib")  ${fstype:-raw}")
        fi
        nrsel+=("$nr")
    done <<< "$nrs"

    menu_select "$(t part_choose_delete)" "${opts[@]}" || return 0
    local sel_nr="${nrsel[$((MENU_NR - 1))]}"
    local sel_dev
    sel_dev="$(part_prefix "$disk")$sel_nr"

    if dev_is_mounted "$sel_dev"; then
        err "$(t err_part_mounted_nodelete "$(fstr "$sel_dev")")"
        return 1
    fi

    err "$(t warn_part_delete_wipe "$(fstr "$sel_dev")")"
    confirm_ja_nein || { misc "$(t info_aborted)"; return 0; }

    if sfdisk --force --no-reread --no-tell-kernel --delete "$disk" "$sel_nr" >/dev/null 2>&1; then
        part_reread
        misc "$(t part_deleted)"
    else
        err "$(t err_part_delete_failed)"
    fi
    part_overview
}

part_format() {
    local disk="$PART_DISK"
    head_msg "$(t part_format_title "$disk")"

    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_no_partitions)"
        return 0
    fi

    local -a opts=() devs=()
    local nr dev fstype
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        if part_is_extended "$dev"; then continue; fi
        fstype="$(lsblk_val FSTYPE "$dev")"
        opts+=("$dev  ${fstype:-raw}")
        devs+=("$dev")
    done <<< "$nrs"
    if [[ "${#devs[@]}" -eq 0 ]]; then
        misc "$(t part_no_formattable)"
        return 0
    fi

    menu_select "$(t part_choose_format)" "${opts[@]}" || return 0
    dev="${devs[$((MENU_NR - 1))]}"

    if dev_is_mounted "$dev"; then
        err "$(t err_dev_mounted "$(fstr "$dev")")"
        return 1
    fi

    menu_select "$(t part_choose_fs)" "ext4" "FAT32" "swap" "NTFS" || return 0
    local fs
    case "$MENU_NR" in
        1) fs="ext4" ;;
        2) fs="vfat" ;;
        3) fs="swap" ;;
        4) fs="ntfs" ;;
    esac

    err "$(t warn_part_format_wipe "$(fstr "$dev")" "$fs")"
    confirm_ja_nein || { misc "$(t info_aborted)"; return 0; }

    make_fs "$dev" "$fs"
    part_overview
}

part_settype() {
    local disk="$PART_DISK"
    head_msg "$(t part_settype_title "$disk")"

    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_no_partitions)"
        return 0
    fi

    local -a opts=() devs=()
    local nr dev type tname nr_new
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        tname="$(lsblk_val PARTTYPENAME "$dev")"
        opts+=("$dev  $(t word_current): ${tname:-$(t word_unknown)}")
        devs+=("$dev")
    done <<< "$nrs"

    menu_select "$(t part_choose_partition)" "${opts[@]}" || return 0
    dev="${devs[$((MENU_NR - 1))]}"
    nr_new="$(lsblk -nro PARTN "$dev" 2>/dev/null || true)"
    if [[ -z "$nr_new" ]]; then
        nr_new="${dev##*[a-z]}"
    fi

    if disk_is_gpt "$disk"; then
        menu_select "$(t part_newtype_gpt)" \
            "$(t part_type_esp)" \
            "$(t part_type_biosboot)" \
            "$(t part_type_linux)" \
            "$(t part_type_linux_swap)" \
            "$(t part_type_msft)" \
            "$(t part_type_lvm)" || return 0
        case "$MENU_NR" in
            1) type="C12A7328-F81F-11D2-BA4B-00A0C93EC93B" ;;
            2) type="21686148-6449-6E6F-744E-656564454649" ;;
            3) type="0FC63DAF-8483-4772-8E79-3D69D8477DE4" ;;
            4) type="0657FD6D-A4AB-43C4-84E5-0933C84B4F4F" ;;
            5) type="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" ;;
            6) type="E6D6D379-F507-44C2-A23C-238F2A3DF928" ;;
        esac
    else
        menu_select "$(t part_newtype_mbr)" \
            "$(t part_type_linux83)" \
            "$(t part_type_efi_ef)" \
            "$(t part_type_fat32lba)" \
            "$(t part_type_swap82)" \
            "$(t part_type_ntfs07)" \
            "$(t part_type_ext05)" || return 0
        case "$MENU_NR" in
            1) type="83" ;;
            2) type="ef" ;;
            3) type="0c" ;;
            4) type="82" ;;
            5) type="07" ;;
            6) type="05" ;;
        esac
    fi

    if sfdisk --force --no-reread --no-tell-kernel --part-type "$disk" "$nr_new" "$type" >/dev/null 2>&1; then
        part_reread
        misc "$(t part_type_set "$(fstr "$type")" "$(fstr "$dev")")"
    else
        err "$(t err_part_type_failed)"
    fi
    part_overview
}

part_bootflag() {
    local disk="$PART_DISK"
    if disk_is_gpt "$disk"; then
        err "$(t err_part_bootflag_gpt)"
        return 1
    fi

    head_msg "$(t part_bootflag_title "$disk")"
    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_no_partitions)"
        return 0
    fi

    local -a opts=() nrsel=()
    local nr dev
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        opts+=("$dev")
        nrsel+=("$nr")
    done <<< "$nrs"

    menu_select "$(t part_choose_bootflag)" "${opts[@]}" || return 0
    local nr_sel="${nrsel[$((MENU_NR - 1))]}"

    if sfdisk --force --no-reread --no-tell-kernel --activate "$disk" "$nr_sel" >/dev/null 2>&1; then
        part_reread
        misc "$(t part_bootflag_set "$(fstr "$(part_prefix "$disk")$nr_sel")")"
    else
        err "$(t err_part_bootflag_failed)"
    fi
    part_overview
}

part_check_tools() {
    local -a need=(sfdisk:fdisk wipefs:util-linux lsblk:util-linux
        findmnt:util-linux blockdev:util-linux udevadm:udev)
    local -a missing=()
    local entry cmd pkg list=""

    for entry in "${need[@]}"; do
        cmd="${entry%%:*}"
        pkg="${entry#*:}"
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$entry")
            list+="$cmd (Paket $pkg) "
        fi
    done
    if [[ "${#missing[@]}" -eq 0 ]]; then
        return 0
    fi

    err "$(t err_part_missing_tools "$list")"
    for entry in "${missing[@]}"; do
        if ! ensure_tool "${entry%%:*}" "${entry#*:}" "$(t word_partitioner)"; then
            die "$(t err_part_needs "$list")"
        fi
    done
    return 0
}

part_menu() {
    head_msg "$(t part_menu_disk_title)"

    part_check_tools

    local live_dev
    live_dev="$(detect_live_medium || true)"

    local -a disks=() dopts=()
    local d size model table
    while read -r d size model; do
        [[ -n "$d" ]] || continue
        if [[ -n "$live_dev" && "$d" == "$live_dev" ]]; then continue; fi
        case "${d##*/}" in
            loop*|zram*|ram*|sr*|fd*|dm-*|md*) continue ;;
        esac
        disks+=("$d")
        table="$(disk_table "$d")"
        dopts+=("$d  $size  ${model:-}  (${table:-$(t word_no_table)})")
    done < <(lsblk -dpnro NAME,SIZE,MODEL 2>/dev/null)

    if [[ "${#disks[@]}" -eq 0 ]]; then
        err "$(t err_part_no_disk)"
        return 1
    fi

    menu_select "$(t part_choose_disk)" "${dopts[@]}" || return 0
    PART_DISK="${disks[$((MENU_NR - 1))]}"

    if [[ -n "$live_dev" ]]; then
        warn "$(t warn_part_live_excluded "$(fstr "$live_dev")")"
    fi

    while :; do
        if menu_select "$(t part_menu_title "$PART_DISK")" \
            "$(t part_menu_overview)" \
            "$(t part_menu_newtable)" \
            "$(t part_menu_create)" \
            "$(t part_menu_delete)" \
            "$(t part_menu_format)" \
            "$(t part_menu_settype)" \
            "$(t part_menu_bootflag)"; then
            case "$MENU_NR" in
                1) part_overview ;;
                2) part_newtable ;;
                3) part_create ;;
                4) part_delete ;;
                5) part_format ;;
                6) part_settype ;;
                7) part_bootflag ;;
            esac
        else
            return 0
        fi
    done
}

#@@ENDBLOCK:PART

#@@BLOCK:INSTALL
# ============================================================
# Installer (installiert das gebootete Live-System)
# ============================================================

DISK=""
ASSUME_YES="n"

root_overlay_lowerdirs() {
    local opts
    opts="$(findmnt -nro OPTIONS / 2>/dev/null || true)"
    if [[ -z "$opts" ]]; then
        return 1
    fi
    printf '%s\n' "$opts" | tr ',' '\n' | sed -n 's/^lowerdir=//p' | tr ':' '\n'
}

squash_from_overlay() {
    local mnt src back
    while IFS= read -r mnt; do
        [[ -n "$mnt" ]] || continue
        case "$mnt" in /*) ;; *) continue ;; esac
        [[ -d "$mnt" ]] || continue
        src="$(findmnt -no SOURCE --target "$mnt" 2>/dev/null || true)"
        [[ -n "$src" ]] || continue
        case "$src" in
            /dev/loop*) back="$(losetup -no BACK-FILE "$src" 2>/dev/null || true)" ;;
            *) back="$src" ;;
        esac
        if [[ -n "$back" && -f "$back" ]]; then
            printf '%s\n' "$back"
            return 0
        fi
    done < <(root_overlay_lowerdirs)
    return 1
}

find_esp_on_disk() {
    local disk="$1" line dev ptype fstype
    while IFS= read -r line; do
        [[ "$line" == *" : start="* ]] || continue
        dev="${line%% :*}"
        ptype="$(printf '%s\n' "$line" | sed -n 's/.*[ ,]type=\([^,]*\).*/\1/p' | tr '[:lower:]' '[:upper:]')"
        case "$ptype" in
            C12A7328-F81F-11D2-BA4B-00A0C93EC93B|EF|0XEF) ;;
            *) continue ;;
        esac
        [[ -b "$dev" ]] || continue
        fstype="$(lsblk -nro FSTYPE "$dev" 2>/dev/null | head -n1 || true)"
        if [[ -n "$fstype" && "$fstype" != "vfat" ]]; then
            continue
        fi
        printf '%s\n' "$dev"
        return 0
    done < <(sfdisk_dump "$disk")
    return 1
}

build_install_targets() {
    TARGETS=()
    TARGET_DESCR=()

    local live_dev
    live_dev="$(detect_live_medium || true)"

    local d dsize model p psize pfstype ptname pk m
    while read -r d dsize model; do
        [[ -n "$d" ]] || continue
        model="${model//\\x20/ }"
        case "${d##*/}" in
            loop*|zram*|ram*|sr*|fd*|dm-*|md*) continue ;;
        esac
        if [[ -n "$live_dev" && "$d" == "$live_dev" ]]; then
            continue
        fi

        TARGETS+=("$d")
        TARGET_DESCR+=("$(fstr "$d") $(t inst_whole_disk) $dsize ${model:+($model)} $(t inst_will_repart)")

        while read -r p; do
            [[ -n "$p" ]] || continue
            pk="$(lsblk -nro PKNAME "$p" 2>/dev/null | head -n1 || true)"
            if [[ "/dev/$pk" != "$d" ]]; then continue; fi
            if part_is_extended "$p"; then
                TARGET_DESCR+=("  $(fstr "$p") $(t inst_extended_skipped)")
                TARGETS+=("")
                continue
            fi
            if [[ -n "$live_dev" ]]; then
                case "$p" in
                    "$live_dev"*) continue ;;
                esac
            fi
            psize="$(lsblk -nro SIZE "$p" 2>/dev/null | head -n1 || true)"
            pfstype="$(lsblk_val FSTYPE "$p")"
            ptname="$(lsblk_val PARTTYPENAME "$p")"
            m="$(findmnt -nro TARGET -S "$p" 2>/dev/null | head -n1 || true)"
            m="${m//\\x20/ }"
            TARGETS+=("$p")
            TARGET_DESCR+=("  $(fstr "$p") $(t inst_partition) $psize - ${pfstype:-$(t word_raw)} - ${ptname:--}${m:+ [$(t word_mounted): $m]}")
        done < <(lsblk -pnro NAME "$d" 2>/dev/null)
    done < <(lsblk -dpnro NAME,SIZE,MODEL 2>/dev/null)
    return 0
}

show_targets() {
    build_install_targets
    head_msg "$(t inst_targets_title)"
    local i n=0
    for i in "${!TARGETS[@]}"; do
        if [[ -n "${TARGETS[$i]}" ]]; then
            n=$((n + 1))
            misc "  $n  ${TARGET_DESCR[$i]}"
        else
            txt "     ${TARGET_DESCR[$i]}"
        fi
    done
    local live_dev
    live_dev="$(detect_live_medium || true)"
    if [[ -n "$live_dev" ]]; then
        txt "$(t inst_live_excluded "$(fstr "$live_dev")")"
    fi
    return 0
}

choose_install_target() {
    build_install_targets

    local -a devs=() descs=()
    local i
    for i in "${!TARGETS[@]}"; do
        if [[ -n "${TARGETS[$i]}" ]]; then
            devs+=("${TARGETS[$i]}")
            descs+=("${TARGET_DESCR[$i]}")
        fi
    done

    if [[ "${#descs[@]}" -eq 0 ]]; then
        err "$(t err_inst_no_targets)"
        return 1
    fi

    menu_select "$(t inst_choose_target)" "${descs[@]}" || return 1
    DISK="${devs[$((MENU_NR - 1))]}"
    return 0
}

do_install() {
    head_msg "$(t inst_title)"

    if [[ -z "$DISK" ]]; then
        usage_install
        exit 2
    fi

    if [[ ! -b "$DISK" ]]; then
        die "$(t err_inst_not_block "$DISK")"
    fi
    DISK="$(readlink -f "$DISK")"

    local disk_type
    disk_type="$(lsblk -ndo TYPE "$DISK" 2>/dev/null || true)"

    PART_MODE="no"
    INSTALL_DISK="$DISK"

    case "$disk_type" in
        disk)
            PART_MODE="no" ;;
        part)
            PART_MODE="yes"
            INSTALL_DISK="$(lsblk -npro PKNAME "$DISK" 2>/dev/null | head -n1 || true)"
            if [[ -z "$INSTALL_DISK" || ! -b "$INSTALL_DISK" ]]; then
                die "$(t err_inst_no_parent "$DISK")"
            fi
            case "$(lsblk -nro PARTTYPENAME "$DISK" 2>/dev/null || true)" in
                *[Ee]xtended*)
                    die "$(t err_inst_extended "$DISK")" ;;
            esac ;;
        *)
            die "$(t err_inst_neither "$DISK")" ;;
    esac

    case "${INSTALL_DISK##*/}" in
        loop*|zram*|ram*|sr*|fd*|dm-*|md*)
            die "$(t err_inst_unsuitable "$INSTALL_DISK")" ;;
    esac

    FIRMWARE="BIOS"
    if [[ -d /sys/firmware/efi ]]; then
        FIRMWARE="UEFI"
    fi
    txt "$(t inst_session_mode "$FIRMWARE" "$FIRMWARE")"
    if [[ "$FIRMWARE" == "UEFI" ]]; then
        misc "$(t inst_boot_bios)"
    else
        misc "$(t inst_boot_uefi)"
    fi

    ARCH="$(uname -m)"
    [[ "$ARCH" == "x86_64" ]] || die "$(t err_inst_arch "$ARCH")"

    if [[ ! -d /cdrom && ! -d /run/live ]]; then
        die "$(t err_inst_no_live_system)"
    fi

    SQUASH="$(squash_from_overlay || true)"
    if [[ -z "$SQUASH" ]]; then
        SQUASH="$(find /cdrom /run/live -maxdepth 6 -type f -name '*.squashfs' -print 2>/dev/null | head -n1 || true)"
    fi
    if [[ -z "$SQUASH" || ! -f "$SQUASH" ]]; then
        err "$(t err_inst_no_squash)"
        misc "$(t info_kernel_cmdline)"
        dump_misc cat /proc/cmdline
        misc "$(t inst_files_under_cdrom)"
        find /cdrom -maxdepth 6 -print 2>/dev/null | head -n 50 | sed 's/^/  /' || true
        die "$(t err_inst_no_squashfs)"
    fi
    txt "$(t inst_squashfs "$(fstr "$SQUASH")")"

    LIVE_DEV="$(live_medium_from_bootmnt || true)"
    if [[ -z "$LIVE_DEV" ]]; then LIVE_DEV="$(live_medium_from_squash || true)"; fi
    if [[ -z "$LIVE_DEV" ]]; then LIVE_DEV="$(live_medium_from_iso9660 || true)"; fi

    if [[ -n "$LIVE_DEV" && "$INSTALL_DISK" == "$LIVE_DEV" ]]; then
        die "$(t err_inst_on_live_medium "$DISK")"
    fi

    txt "$(t inst_target "$(fstr "$DISK")")"
    if [[ "$PART_MODE" == "yes" ]]; then
        txt "$(t inst_mode_part "$(fstr "$INSTALL_DISK")")"
    else
        txt "$(t inst_mode_disk)"
    fi
    txt "Firmware:    $FIRMWARE"
    txt "Architektur: $ARCH"
    txt "$(t inst_live_medium "$(fstr "${LIVE_DEV:-$(t word_not_detected)}")")"

    if [[ -z "$LIVE_DEV" ]]; then
        warn "$(t warn_inst_live_unknown)"
        dump_misc cat /proc/cmdline
    fi

    if findmnt -rn -o SOURCE 2>/dev/null | grep -Eq "^${DISK}($|[0-9])"; then
        die "$(t err_inst_still_mounted "$DISK")"
    fi

    local size_bytes size_mb=0 disk_model
    size_bytes="$(lsblk -dnbro SIZE "$DISK" 2>/dev/null | head -n1 || true)"
    if [[ "$size_bytes" =~ ^[0-9]+$ ]]; then
        size_mb=$((size_bytes / 1000000))
    fi
    (( size_mb >= 8000 )) || die "$(t err_inst_too_small "$size_mb")"

    disk_model="$(lsblk -dno MODEL "$DISK" 2>/dev/null | sed 's/[[:space:]]*$//' || true)"
    txt "$(t inst_size "$size_mb")"
    txt "$(t inst_model "${disk_model:-$(t word_unknown)}")"

    head_msg "$(t inst_warn_wipe "$(fstr "$DISK")")"
    confirm_ja_nein || die "$(t info_aborted)"

    local -a pkgs=()
    need_pkg() {
        if ! command -v "$1" >/dev/null 2>&1; then
            case " ${pkgs[*]} " in
                *" $2 "*) ;;
                *) pkgs+=("$2") ;;
            esac
        fi
    }
    need_pkg unsquashfs squashfs-tools
    need_pkg mkfs.ext4 e2fsprogs
    need_pkg wipefs util-linux
    need_pkg blkid util-linux
    need_pkg lsblk util-linux
    need_pkg blockdev util-linux
    need_pkg mount util-linux
    need_pkg umount util-linux
    need_pkg findmnt util-linux
    need_pkg losetup util-linux
    need_pkg sfdisk fdisk
    need_pkg udevadm udev
    need_pkg grub-install grub-common
    need_pkg chroot coreutils
    need_pkg update-initramfs initramfs-tools
    need_pkg systemd-machine-id-setup systemd
    need_pkg sync coreutils
    if [[ "$FIRMWARE" == "UEFI" ]]; then
        need_pkg mkfs.vfat dosfstools
        need_pkg efibootmgr efibootmgr
    fi
    if [[ "$FIRMWARE" == "BIOS" && ! -d /usr/lib/grub/i386-pc ]]; then
        pkgs+=("grub-pc-bin")
    fi
    if [[ "$FIRMWARE" == "UEFI" && ! -d /usr/lib/grub/x86_64-efi ]]; then
        pkgs+=("grub-efi-amd64-bin")
    fi

    if [[ "${#pkgs[@]}" -gt 0 ]]; then
        txt "$(t inst_missing_tools)"
        misc "  ${pkgs[*]}"
        if ! confirm_yes "$(t q_install_now)"; then
            die "$(t err_inst_missing_pkgs "${pkgs[*]}")"
        fi
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"; then
            misc "$(t info_retry_apt_update)"
            apt-get update >/dev/null 2>&1 || true
            DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}" \
                || die "$(t err_inst_pkgs_failed)"
        fi
    fi

    local c
    for c in unsquashfs mkfs.ext4 wipefs blkid lsblk blockdev \
             findmnt losetup sfdisk udevadm grub-install chroot; do
        if ! command -v "$c" >/dev/null 2>&1; then
            die "$(t err_inst_pkg_still_missing "$c")"
        fi
    done
    if [[ "$FIRMWARE" == "UEFI" ]] && ! command -v mkfs.vfat >/dev/null 2>&1; then
        die "$(t err_inst_mkfsvfat_missing)"
    fi

    if [[ "$FIRMWARE" == "BIOS" && ! -d /usr/lib/grub/i386-pc ]]; then
        die "$(t err_inst_grub_bios_missing)"
    fi
    if [[ "$FIRMWARE" == "UEFI" && ! -d /usr/lib/grub/x86_64-efi ]]; then
        die "$(t err_inst_grub_uefi_missing)"
    fi

    KVER="$(uname -r)"
    if [[ ! -d "/lib/modules/$KVER" ]]; then
        KVER="$(find /lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
            | grep -Ev 'extramodules|^build$|^source$' | sort -V | tail -n1 || true)"
    fi
    HOST_KERNEL="/boot/vmlinuz-${KVER}"
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="/cdrom/live/vmlinuz"
    fi
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="$(find /cdrom /run/live -maxdepth 6 -type f -name 'vmlinuz*' -print 2>/dev/null | head -n1 || true)"
    fi
    if [[ -z "$HOST_KERNEL" || ! -e "$HOST_KERNEL" ]]; then
        die "$(t err_inst_no_kernel)"
    fi
    txt "$(t inst_kernel_source "$(fstr "$HOST_KERNEL")")"

    if [[ "$PART_MODE" == "yes" ]]; then
        txt "$(t inst_part_mode_note1)"
        txt "$(t inst_part_mode_note2 "$(fstr "$INSTALL_DISK")")"
    else
        PART_PREFIX="$(part_prefix "$DISK")"
        P1="${PART_PREFIX}1"
        P2="${PART_PREFIX}2"

        txt "$(t inst_partitioning "$(fstr "$DISK")" "$FIRMWARE")"
        wipefs --all --force "$DISK" >/dev/null 2>&1 || true

        if [[ "$FIRMWARE" == "UEFI" ]]; then
            misc "$(t inst_creating_gpt)"
            if ! printf 'label: gpt\nname="ESP", size=512MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\nname="Root", type=0FC63DAF-8483-4772-8E79-3D69D8477DE4\n' \
                | sfdisk --force --no-reread --no-tell-kernel "$DISK" >/dev/null; then
                die "$(t err_inst_part_gpt)"
            fi
        else
            misc "$(t inst_creating_mbr)"
            if ! printf 'label: dos\nstart=1MiB, type=83, bootable\n' \
                | sfdisk --force --no-reread --no-tell-kernel "$DISK" >/dev/null; then
                die "$(t err_inst_part_mbr)"
            fi
        fi

        sync
        udevadm settle 2>/dev/null || true
        blockdev --rereadpt "$DISK" >/dev/null 2>&1 || true
        local i
        for i in {1..20}; do
            if [[ -b "$P1" ]]; then break; fi
            sleep 1
            udevadm settle 2>/dev/null || true
            blockdev --rereadpt "$DISK" >/dev/null 2>&1 || true
        done
        [[ -b "$P1" ]] || die "$(t err_inst_p1_missing "$P1")"
        if [[ "$FIRMWARE" == "UEFI" && ! -b "$P2" ]]; then
            die "$(t err_inst_p2_missing "$P2")"
        fi

        misc "$(t inst_partitions)"
        dump_misc lsblk -o NAME,SIZE,FSTYPE,TYPE "$DISK"
    fi

    txt "$(t inst_formatting)"

    if [[ "$PART_MODE" == "yes" ]]; then
        txt "$(t inst_formatting_part "$(fstr "$DISK")")"

        if swapon --show=NAME --noheadings 2>/dev/null | grep -Fxq "$DISK"; then
            misc "$(t inst_swap_off)"
            if ! swapoff "$DISK" 2>/dev/null; then
                die "$(t err_inst_swap_off_failed "$DISK")"
            fi
        fi

        wipefs -a "$DISK" >/dev/null 2>&1 || true
        mkfs.ext4 -q -F -L debianroot "$DISK" \
            || die "$(t err_inst_format_target)"

        ROOT_PART="$DISK"
        ESP_PART=""

        if [[ "$FIRMWARE" == "UEFI" ]]; then
            misc "$(t inst_search_esp "$(fstr "$INSTALL_DISK")")"
            ESP_PART="$(find_esp_on_disk "$INSTALL_DISK" || true)"
            if [[ -z "$ESP_PART" ]]; then
                misc "$(t inst_partlist "$(fstr "$INSTALL_DISK")")"
                dump_misc lsblk -o NAME,SIZE,PARTTYPENAME,FSTYPE "$INSTALL_DISK"
                die "$(t err_inst_no_esp "$INSTALL_DISK" "$SCRIPT_NAME")"
            fi
            local esp_fstype
            esp_fstype="$(lsblk -nro FSTYPE "$ESP_PART" 2>/dev/null | head -n1 || true)"
            if [[ -z "$esp_fstype" ]]; then
                misc "$(t inst_esp_unformatted "$(fstr "$ESP_PART")")"
                mkfs.vfat -F32 "$ESP_PART" || die "$(t err_inst_esp_format)"
            elif [[ "$esp_fstype" != "vfat" ]]; then
                die "$(t err_inst_esp_wrong_fs "$ESP_PART" "$esp_fstype")"
            fi
        else
            if disk_is_gpt "$INSTALL_DISK" && ! disk_has_biosboot "$INSTALL_DISK"; then
                die "$(t err_inst_bios_gpt_no_biosboot "$INSTALL_DISK")"
            fi
        fi
    else
        if [[ "$FIRMWARE" == "UEFI" ]]; then
            wipefs -a "$P1" >/dev/null 2>&1 || true
            mkfs.vfat -F32 -n ARCHESP "$P1" || die "$(t err_inst_esp_format2)"
            wipefs -a "$P2" >/dev/null 2>&1 || true
            mkfs.ext4 -q -F -L debianroot "$P2" || die "$(t err_inst_root_format)"
            ROOT_PART="$P2"
            ESP_PART="$P1"
        else
            wipefs -a "$P1" >/dev/null 2>&1 || true
            mkfs.ext4 -q -F -L debianroot "$P1" || die "$(t err_inst_root_format)"
            ROOT_PART="$P1"
            ESP_PART=""
        fi
    fi

    ROOT_UUID="$(blkid -s UUID -o value "$ROOT_PART" 2>/dev/null || true)"
    [[ -n "$ROOT_UUID" ]] || die "$(t err_inst_root_uuid)"
    txt "Root UUID: $ROOT_UUID"

    if [[ -n "$ESP_PART" ]]; then
        ESP_UUID="$(blkid -s UUID -o value "$ESP_PART" 2>/dev/null || true)"
        [[ -n "$ESP_UUID" ]] || die "$(t err_inst_esp_uuid)"
        txt "ESP UUID:  $ESP_UUID"
    fi

    txt "$(t inst_mounting)"

    if mountpoint -q /mnt 2>/dev/null; then
        die "$(t err_inst_mnt_mounted)"
    fi

    mkdir -p /mnt
    umount /mnt/boot/efi 2>/dev/null || true
    umount /mnt/boot 2>/dev/null || true
    if [[ -n "$(ls -A /mnt 2>/dev/null || true)" ]]; then
        misc "$(t inst_clean_mnt)"
        find /mnt -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
    fi

    mount "$ROOT_PART" /mnt || die "$(t err_inst_root_mount)"

    ROOT_MOUNTED="yes"
    ESP_MOUNTED=""
    CHROOT_MOUNTED=""

    cleanup_mounts() {
        sync 2>/dev/null || true
        if [[ "${CHROOT_MOUNTED:-}" == "yes" ]]; then
            umount /mnt/dev /mnt/sys /mnt/proc 2>/dev/null || true
        fi
        if [[ "${ESP_MOUNTED:-}" == "yes" ]]; then umount /mnt/boot/efi 2>/dev/null || true; fi
        if [[ "${ROOT_MOUNTED:-}" == "yes" ]]; then umount /mnt 2>/dev/null || true; fi
    }
    trap cleanup_mounts EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP

    local squash_mb=0
    squash_mb="$(du -m -- "$SQUASH" 2>/dev/null | cut -f1 || true)"
    if [[ "$squash_mb" =~ ^[0-9]+$ && "$squash_mb" -gt 0 ]]; then
        txt "$(t inst_extracting "$(fstr "/mnt")" "$squash_mb")"
    else
        txt "$(t inst_extracting_long "$(fstr "/mnt")")"
    fi
    unsquashfs -no-progress -f -d /mnt "$SQUASH" || die "$(t err_inst_unsquash)"

    if [[ -n "$ESP_PART" ]]; then
        rm -rf -- /mnt/boot/efi
        mkdir -p /mnt/boot/efi
        mount "$ESP_PART" /mnt/boot/efi || die "$(t err_inst_esp_mount)"
        ESP_MOUNTED="yes"
    fi

    local avail_kb avail_mb=0
    avail_kb="$(df -Pk /mnt 2>/dev/null | awk 'NR==2 {print $4}' || true)"
    if [[ "$avail_kb" =~ ^[0-9]+$ ]]; then
        avail_mb=$((avail_kb / 1024))
    fi
    txt "$(t inst_free_after "$avail_mb")"
    (( avail_mb >= 300 )) || die "$(t err_inst_low_space)"

    if [[ "$PART_MODE" == "no" && -d /mnt/boot/efi ]]; then
        misc "$(t inst_remove_bootloader)"
        find /mnt/boot/efi -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
    fi

    txt "$(t inst_checking_kernel)"
    TARGET_KERNEL="/mnt/boot/vmlinuz-${KVER}"
    if [[ ! -e "$TARGET_KERNEL" ]]; then
        mkdir -p /mnt/boot
        cp -L "$HOST_KERNEL" "$TARGET_KERNEL" || die "$(t err_inst_kernel_copy)"
        misc "$(t inst_kernel_copied "$(fstr "$HOST_KERNEL")")"
    fi
    txt "$(t inst_kernel "$(fstr "$TARGET_KERNEL")")"

    local modbase=""
    if [[ -d /mnt/lib/modules ]]; then modbase="/mnt/lib/modules"; fi
    if [[ -z "$modbase" && -d /mnt/usr/lib/modules ]]; then modbase="/mnt/usr/lib/modules"; fi
    if [[ -z "$modbase" ]]; then
        die "$(t err_inst_no_modbase)"
    fi

    local kver_list
    kver_list="$(find "$modbase" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
        | grep -Ev 'extramodules|^build$|^source$' | sort -V || true)"

    KVER="$(uname -r)"
    if ! printf '%s\n' "$kver_list" | grep -qxF "$KVER"; then
        KVER="$(printf '%s\n' "$kver_list" | tail -n1 || true)"
    fi
    if [[ -z "$KVER" ]]; then
        die "$(t err_inst_no_kver)"
    fi
    txt "Kernel-Version: $KVER"

    if [[ ! -d "$modbase/$KVER" ]]; then
        warn "$(t warn_inst_moddir_missing "$modbase" "$KVER")"
        find "$modbase" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null || true
        die "$(t err_inst_no_matching_modules)"
    fi

    txt "$(t inst_creating_fstab)"
    mkdir -p /mnt/etc
    {
        printf '# /etc/fstab\n'
        printf '# Erzeugt vom %s %s\n\n' "$SCRIPT_NAME" "$VERSION"
        printf 'UUID=%s  /  ext4  defaults  0 1\n' "$ROOT_UUID"
        if [[ -n "$ESP_PART" ]]; then
            printf 'UUID=%s  /boot/efi  vfat  umask=0077,nofail  0 0\n' "$ESP_UUID"
        fi
    } > /mnt/etc/fstab

    txt "$(t inst_creating_machine_id)"
    rm -f -- /mnt/etc/machine-id
    if command -v systemd-machine-id-setup >/dev/null 2>&1; then
        systemd-machine-id-setup --root=/mnt >/dev/null 2>&1 || true
    fi

    if [[ ! -s /mnt/etc/machine-id ]]; then
        MACHINE_ID="$(tr -d '-' < /proc/sys/kernel/random/uuid 2>/dev/null || true)"
        if [[ -z "$MACHINE_ID" ]]; then
            MACHINE_ID="$(head -c 16 /dev/urandom 2>/dev/null | od -An -tx1 | tr -d ' \n' || true)"
        fi
        if [[ -n "$MACHINE_ID" ]]; then
            printf '%s\n' "$MACHINE_ID" > /mnt/etc/machine-id
        fi
    fi
    [[ -s /mnt/etc/machine-id ]] || die "$(t err_inst_machine_id)"
    chmod 444 /mnt/etc/machine-id

    if [[ -e /mnt/var/lib/dbus/machine-id && ! -L /mnt/var/lib/dbus/machine-id ]]; then
        cp -f /mnt/etc/machine-id /mnt/var/lib/dbus/machine-id 2>/dev/null || true
    fi
    rm -f -- /mnt/var/lib/systemd/random-seed 2>/dev/null || true

    liveboot_live_cleanup /mnt

    # display-manager-Kette konsistent machen: der Symlink muss auf eine
    # existierende Unit zeigen und /etc/X11/default-display-manager auf
    # deren Binary (sddms ExecStartPre bricht sonst den Start ab)
    local dm_target
    dm_target="$(readlink /mnt/etc/systemd/system/display-manager.service 2>/dev/null || true)"
    if [[ -n "$dm_target" ]]; then
        local dm_bin=""
        case "$(basename -- "$dm_target")" in
            sddm.service) dm_bin="/usr/bin/sddm" ;;
            lightdm.service) dm_bin="/usr/sbin/lightdm" ;;
            gdm3.service) dm_bin="/usr/sbin/gdm3" ;;
        esac
        if [[ -L /mnt/etc/systemd/system/display-manager.service \
            && ! -e /mnt/etc/systemd/system/display-manager.service ]]; then
            die "$(t err_inst_dm_broken "$dm_target")"
        fi
        if [[ -n "$dm_bin" && -e "/mnt$dm_bin" ]]; then
            local ddm
            ddm="$(cat /mnt/etc/X11/default-display-manager 2>/dev/null || true)"
            if [[ "$ddm" != "$dm_bin" ]]; then
                mkdir -p /mnt/etc/X11
                printf '%s\n' "$dm_bin" > /mnt/etc/X11/default-display-manager
                misc "$(t inst_set_dm "$dm_bin")"
            fi
        fi
    fi

    txt "$(t inst_building_initramfs)"
    # live-boot-Dateien (hooks/live, scripts/live, live-boot-helpers) werden
    # bewusst NICHT mehr aus dem Zielsystem entfernt: initramfs-tools
    # sourced /scripts/live nur bei boot=live-boot - ohne den Kernel-
    # Parameter (installierte Systeme) ist live-boot dort toter Code. Die
    # Anwesenheit macht jede installierte Kopie DAUERHAFT ISO-baufähig
    # (früher: Bau von der installierten Kopie scheiterte an fehlenden
    # live-boot-Dateien -> unbootbare ISOs mit Kernel-Panik). Nebeneffekt:
    # künftige update-initramfs-Läufe binden die inerten live-boot-Skripte
    # ein - harmlos, live-boot exitet ohne boot=live-boot.

    mkdir -p /mnt/proc /mnt/sys /mnt/dev
    mount -o bind /proc /mnt/proc 2>/dev/null || true
    mount -o bind /sys /mnt/sys 2>/dev/null || true
    mount -o bind /dev /mnt/dev 2>/dev/null || true
    CHROOT_MOUNTED="yes"

    if [[ -f "/mnt/boot/initrd.img-$KVER" ]]; then
        chroot /mnt update-initramfs -u -k "$KVER" || die "$(t err_inst_update_initramfs)"
    else
        chroot /mnt update-initramfs -c -k "$KVER" || die "$(t err_inst_update_initramfs)"
    fi

    local grub_cfg_done="n"
    if fallback_aktiv; then
        # Fallback für ältere Debian-Versionen: der normale Weg - update-grub
        # erzeugt die Konfiguration aus /etc/default/grub + /etc/grub.d des
        # Zielsystems (getestete Kernel-Kommandozeile, Standard-Menü wie bei
        # einer normalen Installation). Läuft mit gebundenen /proc,/sys,/dev.
        mkdir -p /mnt/boot/grub
        local ug_log
        ug_log="$(mktemp /tmp/ultool-updgrub.XXXXXX)"
        txt "$(t inst_fallback_updategrub)"
        if chroot /mnt update-grub > "$ug_log" 2>&1; then
            grub_cfg_done="j"
            misc "$(t inst_updategrub_done)"
        else
            {
                printf '%s\n' "$(t err_inst_updategrub_failed)"
                sed 's/^/   /' "$ug_log"
            } >&2
        fi
        rm -f "$ug_log"
    fi

    umount /mnt/dev /mnt/sys /mnt/proc 2>/dev/null || true
    CHROOT_MOUNTED=""

    txt "$(t inst_installing_grub "$FIRMWARE")"
    mkdir -p /mnt/boot/grub

    if [[ "$FIRMWARE" == "BIOS" ]]; then
        grub-install \
            --target=i386-pc \
            --recheck \
            --boot-directory=/mnt/boot \
            "$INSTALL_DISK" || die "$(t err_inst_grub_bios)"
    else
        [[ "${ESP_MOUNTED:-}" == "yes" ]] \
            || die "$(t err_inst_esp_not_mounted)"
        local efi_std_ok=n
        # Standardpfad EFI/debian + NVRAM-Eintrag: ueberschreibt Bootloader-Reste
        # einer frueheren Installation und gibt der Firmware den richtigen Verweis
        if grub-install \
            --target=x86_64-efi \
            --recheck \
            --efi-directory=/mnt/boot/efi \
            --boot-directory=/mnt/boot \
            --bootloader-id=Debian \
            "$INSTALL_DISK"; then
            efi_std_ok=j
        else
            warn "$(t warn_inst_uefi_std_failed)"
        fi
        # Portabler Fallback-Pfad EFI/BOOT (Firmware ohne NVRAM-Zugriff/Boot-Menu)
        if ! grub-install \
            --target=x86_64-efi \
            --recheck \
            --efi-directory=/mnt/boot/efi \
            --boot-directory=/mnt/boot \
            --bootloader-id=Debian \
            --removable \
            --no-nvram \
            "$INSTALL_DISK"; then
            if [[ "$efi_std_ok" == "j" ]]; then
                warn "$(t warn_inst_uefi_portable_failed)"
            else
                die "$(t err_inst_grub_uefi)"
            fi
        fi
    fi

    if [[ "$grub_cfg_done" != "j" ]]; then
        txt "$(t inst_creating_grubcfg)"
        {
            printf 'set timeout=5\nset default=0\n\n'
            printf 'menuentry "Debian (%s)" {\n' "$KVER"
            printf '    linux /boot/vmlinuz-%s root=UUID=%s rw\n' "$KVER" "$ROOT_UUID"
            printf '    initrd /boot/initrd.img-%s\n}\n\n' "$KVER"
            printf 'menuentry "Debian (%s) - Fallback" {\n' "$KVER"
            printf '    linux /boot/vmlinuz-%s root=UUID=%s rw\n' "$KVER" "$ROOT_UUID"
            printf '    initrd /boot/initrd.img-%s\n}\n' "$KVER"
        } > /mnt/boot/grub/grub.cfg
    fi

    if [[ "$FIRMWARE" == "UEFI" && ! -f /mnt/boot/efi/EFI/BOOT/BOOTX64.EFI \
        && ! -f /mnt/boot/efi/EFI/debian/grubx64.efi \
        && ! -f /mnt/boot/efi/EFI/debian/shimx64.efi ]]; then
        die "$(t err_inst_no_bootloader_files)"
    fi

    sync

    # Boot-Garantie (Struktur-Pruefung): es darf KEINE Autologin-
    # Konfiguration im Zielsystem ueberleben - das frische System zeigt
    # immer den Login-Bildschirm. Falls doch etwas ueberlebt hat, wird
    # hier hart abgebrochen statt ein System mit defektem Autologin
    # auszuliefern.
    if grep -qs '^\[Autologin\]' /mnt/etc/sddm.conf /mnt/etc/sddm.conf.d/*.conf 2>/dev/null; then
        die "$(t err_inst_autologin_survived)"
    fi

    head_msg "$(t inst_success)"
    txt "$(t inst_done_target "$(fstr "$DISK")")"
    txt "Firmware:   $FIRMWARE"
    txt "$(t inst_done_root "$(fstr "$ROOT_PART")")"
    txt "Root UUID:  $ROOT_UUID"
    txt ""
    txt "$(t inst_now_do)"
    misc "$(t inst_step1)"
    misc "$(t inst_step2)"
    misc "$(t inst_step3)"
    txt ""
    misc "$(t inst_login_screen_info)"
    txt ""
    warn "$(t warn_secure_boot)"
    return 0
}

install_interactive() {
    head_msg "$(t inst_menu_title)"

    while :; do
        if menu_select "$(t inst_menu)" \
            "$(t inst_menu_choose)" \
            "$(t inst_menu_show)" \
            "$(t inst_menu_partition)"; then
            case "$MENU_NR" in
                1)
                    if choose_install_target; then
                        if do_install; then
                            # Installation erfolgreich: Menue verlassen
                            # - das Tool endet mit 0 statt erneut zu
                            # fragen (Nutzer-Befund, siehe TASK.md).
                            return 0
                        fi
                    fi ;;
                2) show_targets ;;
                3) part_menu ;;
            esac
        else
            return 0
        fi
    done
}

#@@ENDBLOCK:INSTALL

#@@BLOCK:ISO
# ============================================================
# ISO-Builder (Live-ISO vom laufenden System, live-boot)
# ============================================================

WORK=""
OUT=""
ISO_LABEL="DEBIANLIVE"
SQUASH_COMP="zstd"
EXTRA_EXCLUDES=()

LIVE_TREE=""
MERGED=""
OVL_UPPER="/run/liveiso-overlay-upper"
OVL_WORK="/run/liveiso-overlay-work"

iso_check_target() {
    local kind="$1" path="$2" fst
    if [[ -z "$path" ]]; then
        return 0
    fi
    mkdir -p "$path" 2>/dev/null || true
    case "$path" in
        /|/boot|/boot/*|/efi|/efi/*|/etc|/etc/*|/usr|/usr/*|/var|/var/*|/bin|/bin/*|/sbin|/sbin/*|/lib|/lib/*|/lib64|/lib64/*|/root|/root/*|/dev|/dev/*|/proc|/proc/*|/sys|/sys/*)
            die "$(t err_iso_system_area "$kind" "$path")" ;;
    esac
    fst="$(findmnt -nro FSTYPE --target "$path" 2>/dev/null || true)"
    case "$fst" in
        vfat|msdos|fat*|exfat)
            die "$(t err_iso_fat_area "$kind" "$path")" ;;
    esac
}

kill_mount_users() {
    local base="$1" pid root cwd pidpath
    if [[ -z "$base" || ! -d "$base" ]]; then
        return 0
    fi
    for pidpath in /proc/[0-9]*; do
        [[ -d "$pidpath" ]] || continue
        pid="${pidpath#/proc/}"
        if [[ "$pid" == "$$" ]]; then continue; fi
        root="$(readlink "$pidpath/root" 2>/dev/null)" || continue
        case "$root" in
            "$base"|"$base"/*) kill -9 "$pid" 2>/dev/null || true; continue ;;
        esac
        cwd="$(readlink "$pidpath/cwd" 2>/dev/null)" || continue
        case "$cwd" in
            "$base"|"$base"/*) kill -9 "$pid" 2>/dev/null || true ;;
        esac
    done
    return 0
}

do_umount() {
    local m="$1" i
    mountpoint -q "$m" 2>/dev/null || return 0
    for i in 1 2 3; do
        if umount "$m" 2>/dev/null; then
            return 0
        fi
        sleep 1
    done
    warn "$(t warn_iso_mount_blocked "$m")"
    if command -v fuser >/dev/null 2>&1; then fuser -vm "$m" 2>&1 || true; fi
    if umount -l "$m" 2>/dev/null; then
        warn "$(t warn_iso_lazy_umount "$m")"
    else
        err "$(t err_iso_umount_failed "$m")"
    fi
    return 0
}

iso_cleanup_mounts() {
    txt "$(t iso_cleaning)"
    pkill -9 -f "mksquashfs.*$MERGED" 2>/dev/null || true
    kill_mount_users "$MERGED"
    do_umount "$MERGED"
    rm -rf -- "$OVL_UPPER" "$OVL_WORK" 2>/dev/null || true
    sync
}

do_iso_cleanup() {
    require_root
    if [[ -z "$WORK" ]]; then
        WORK="$(invoking_home)/remastern"
    fi
    if [[ -z "$WORK" || "$WORK" == "/" ]]; then
        die "$(t err_iso_work_invalid "$WORK")"
    fi
    LIVE_TREE="$WORK/live-iso-tree"
    MERGED="$WORK/MERGED"

    head_msg "$(t iso_cleanup_title "$(fstr "$WORK")")"
    iso_cleanup_mounts
    rm -rf -- "${LIVE_TREE:?}" "$OVL_UPPER" "$OVL_WORK" "$WORK/initramfs-live-conf" \
        || die "$(t err_iso_artifacts_delete)"
    rmdir "$WORK" 2>/dev/null || true
    sync
    misc "$(t iso_cleanup_done)"
}

give_back_ownership() {
    local user="${SUDO_USER:-}"
    if [[ -z "$user" ]]; then
        return 0
    fi
    if ! getent passwd "$user" >/dev/null; then
        warn "$(t warn_iso_user_unknown "$user")"
        return 0
    fi
    local pfad
    for pfad in "$@"; do
        pfad="${pfad:?}"
        if [[ ! -e "$pfad" ]]; then
            continue
        fi
        if chown -R -- "$user:" "$pfad" 2>/dev/null; then
            misc "$(t iso_owner_set "$(fstr "$pfad")" "$user")"
        else
            err "$(t iso_owner_failed "$(fstr "$pfad")" "$user" "$user" "$pfad")"
        fi
    done
}

# initramfs_verifizieren - Sicherheitsnetz nach dem mkinitramfs-Lauf
# (Wiedereinbau der Erkenntnisse aus Änderung 46): entpackt das gebaute
# Initramfs und prüft die Bestandteile, ohne die das Live-System nicht
# booten kann - /init, das live-boot-Hauptskript, die Konfiguration und der
# kernel/-Modulbaum (ein /lib/modules/$kver mit NUR Metadaten lieferte
# früher unbootbare ISOs mit Kernel-Panik). Im Stub-Fall zusätzlich die
# neutralisierte 15autologin. Dazu Truncations-Erkennung: das Hauptsegment
# muss sich VOLLSTÄNDIG dekomprimieren lassen. Rückgabe 0 = OK, 1 = Defekt
# (Aufrufer bricht dann ab - der Bau liefert keine unbootbare ISO).
# Aufruf: initramfs_verifizieren <initrd> <kver> <stub_aktiv j|n>
initramfs_verifizieren() {
    local initrd="$1" kver="$2" stub="$3"
    if [[ ! -s "$initrd" ]]; then
        err "$(t err_iso_initrd_empty "$initrd")"
        return 1
    fi

    if command -v unmkinitramfs >/dev/null 2>&1; then
        local vdir base fehl="" mod_quelle=""
        vdir="$(mktemp -d /tmp/ultool-verify-XXXXXX)"
        if ! unmkinitramfs "$initrd" "$vdir" 2>/dev/null; then
            rm -rf -- "$vdir"
            err "$(t err_iso_initrd_unmk)"
            return 1
        fi
        # Layout je nach initramfs-tools-Version: alles unter main/ oder
        # direkt; NOBLE-/24.04-SPECIAL: die Kernelmodule liegen im EARLY-
        # Segment (unkomprimiert, VOR dem komprimierten Hauptsegment) -
        # der Kernel entpackt beim Boot ALLE Segmente ins rootfs, ein
        # solches Initramfs ist völlig in Ordnung (im Docker noble-
        # Container nachgewiesen: 148 Module, alle in early/). Deshalb:
        # init/conf nur in main (dort gehören sie hin), Module und
        # live-boot-Skripte ÜBERALL suchen (early*/main/direct).
        if [[ -d "$vdir/main" ]]; then base="$vdir/main"; else base="$vdir"; fi
        [[ -e "$base/init" ]] || fehl="$fehl init"
        [[ -e "$base/conf/initramfs.conf" ]] || fehl="$fehl conf/initramfs.conf"
        local liveboot_gefunden=""
        liveboot_gefunden="$(find "$vdir" -type f -path "*/scripts/live" -print -quit 2>/dev/null || true)"
        [[ -n "$liveboot_gefunden" ]] || fehl="$fehl scripts/live (live-boot-Hauptskript)"
        mod_quelle="$(find "$vdir" -type d -path "*/modules/$kver/kernel" -print -quit 2>/dev/null || true)"
        if [[ -z "$mod_quelle" ]] \
            || [[ -z "$(find "$mod_quelle" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
            fehl="$fehl lib/modules/$kver/kernel (Kernelmodule)"
        fi
        if [[ "$stub" == "j" ]] && ! grep -qs "debianlive-tool deaktiviert" \
            "$(find "$vdir" -type f -path "*/live-boot-bottom/15autologin" -print -quit 2>/dev/null)" 2>/dev/null; then
            fehl="$fehl 15autologin-Stub"
        fi
        rm -rf -- "$vdir"
        if [[ -n "$fehl" ]]; then
            err "$(t err_iso_initrd_incomplete "$fehl")"
            return 1
        fi
    else
        warn "$(t warn_iso_no_unmkinitramfs)"
    fi

    # Truncations-Erkennung: das Hauptsegment beginnt nach den (unkomprimierten)
    # Mikrocode-cpio-Segmenten - frühestes Kompressions-Magic an 4-Byte-
    # ausgerichteter Position suchen (Segmentgrenzen sind 4-aligned); ab dem
    # Kandidaten muss der Rest VOLLSTÄNDIG dekomprimieren (-t bestätigt den
    # echten Magie-Treffer und weist falsche zurück). Ein Datei ohne jedes
    # Kompressions-Magic, die mit dem newc-cpio-Magic beginnt, ist
    # unkomprimiert und damit bootbar. Über stdin lesen - grep -abo auf eine
    # Datei würde "datei:offset:treffer" ausgeben.
    local pat hex tool off gefunden=""
    for pat in 'zstd:\x28\xb5\x2f\xfd' 'xz:\xfd\x37\x7a\x58\x5a' 'lz4:\x04\x22\x4d\x18' \
        'lzop:\x89\x4c\x5a\x4f' 'gzip:\x1f\x8b' 'bzip2:\x42\x5a\x68'; do
        tool="${pat%%:*}"
        hex="${pat#*:}"
        while read -r off; do
            [[ -n "$off" ]] || continue
            case "$tool" in
                zstd)  tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | zstd -t >/dev/null 2>&1 || continue ;;
                xz)    tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | xz -t >/dev/null 2>&1 || continue ;;
                lz4)   tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | lz4 -t >/dev/null 2>&1 || continue ;;
                lzop)  tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | lzop -t >/dev/null 2>&1 || continue ;;
                gzip)  tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | gzip -t >/dev/null 2>&1 || continue ;;
                bzip2) tail -c +"$((off + 1))" -- "$initrd" 2>/dev/null | bzip2 -t >/dev/null 2>&1 || continue ;;
            esac
            gefunden="$off"
            break
        done < <(LC_ALL=C grep -abo -F -- "$(printf "$hex")" < "$initrd" 2>/dev/null \
            | awk -F: '$1 ~ /^[0-9]+$/ && NF >= 2 && $1 % 4 == 0 {print $1}' || true)
        [[ -n "$gefunden" ]] && break
    done
    if [[ -z "$gefunden" && "$(head -c6 -- "$initrd" 2>/dev/null)" != "070701" ]]; then
        err "$(t err_iso_initrd_truncated)"
        return 1
    fi
    return 0
}

do_iso_build() {
    require_root

    if [[ -z "$WORK" ]]; then
        WORK="$(invoking_home)/remastern"
    fi
    if [[ -z "$WORK" || "$WORK" == "/" ]]; then
        die "$(t err_iso_work_invalid "$WORK")"
    fi
    case "$WORK" in
        *[[:space:]]*) die "$(t err_iso_work_spaces "$WORK")" ;;
    esac

    LIVE_TREE="$WORK/live-iso-tree"
    MERGED="$WORK/MERGED"

    local iso_name="debianlive.iso" outdir="$WORK"
    if [[ -n "$OUT" ]]; then
        case "$OUT" in
            */) outdir="${OUT%/}" ;;
            *.iso|*.ISO|*.Iso)
                outdir="$(dirname -- "$OUT")"
                iso_name="$(basename -- "$OUT")" ;;
            *) outdir="$OUT" ;;
        esac
    fi
    iso_name="${iso_name##*/}"
    case "$iso_name" in
        *.iso|*.ISO|*.Iso) : ;;
        *) iso_name="${iso_name}.iso" ;;
    esac
    ISO_LABEL="${ISO_LABEL^^}"
    local output_iso="$outdir/$iso_name"

    iso_check_target "$(t word_workdir)" "$WORK"
    iso_check_target "$(t word_output_dir)" "$outdir"

    mkdir -p "$outdir" || die "$(t err_iso_outdir_create "$outdir")"

    trap iso_cleanup_mounts EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP

    local -a build_pkgs=(live-boot live-config live-tools initramfs-tools squashfs-tools grub-common
        grub-pc-bin grub-efi-amd64-bin xorriso mtools)
    local missing
    missing="$(pkg_missing "${build_pkgs[@]}" | tr '\n' ' ' || true)"
    missing="${missing% }"
    if [[ -n "$missing" ]]; then
        local -a missing_arr=()
        read -r -a missing_arr <<< "$missing"
        txt "$(t iso_missing_pkgs_title)"
        misc "  ${missing_arr[*]}"
        if ! confirm_yes "$(t q_install_now)"; then
            die "$(t err_iso_missing_pkgs "${missing_arr[*]}")"
        fi
        txt "$(t iso_installing_pkgs "${missing_arr[*]}")"
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_arr[@]}"; then
            misc "$(t info_retry_apt_update)"
            apt-get update >/dev/null 2>&1 || true
            DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_arr[@]}" \
                || die "$(t err_iso_pkgs_failed)"
        fi
    fi

    local t
    local -A tool_pkg=(
        [mksquashfs]="squashfs-tools"
        [mkinitramfs]="initramfs-tools"
        [grub-mkrescue]="grub-common"
        [xorriso]="xorriso"
        [mformat]="mtools"
        [mcopy]="mtools"
    )
    for t in mksquashfs mkinitramfs grub-mkrescue xorriso mformat mcopy; do
        if ! command -v "$t" >/dev/null 2>&1; then
            die "$(t err_iso_tool_missing "$t" "${tool_pkg[$t]}")"
        fi
    done
    # live-boot-Dateien prüfen: hooks/live UND scripts/live müssen
    # existieren (beide fehlen in installierten Kopien älterer Installer-
    # Versionen, die sie entfernten). KEIN --reinstall: das scheitert, sobald
    # die exakt installierte Version aus dem Archiv rotiert ist (Versionen
    # werden laufend ersetzt) - stattdessen das AKTUELLE live-boot-Paket per
    # apt-get download ziehen und die Dateien per dpkg-deb -x extrahieren.
    # Die Datei-Existenz wird VOR dem mkinitramfs sichergestellt (der
    # frühere stille Fehler - Initramfs ohne live-boot -> Kernel-Panik - ist
    # damit strukturell ausgeschlossen; Rest absichert initramfs_verifizieren).
    if [[ ! -e /usr/share/initramfs-tools/hooks/live \
        || ! -e /usr/share/initramfs-tools/scripts/live ]]; then
        misc "$(t info_iso_liveboot_missing)"
        if ! confirm_yes "$(t q_iso_liveboot_restore)"; then
            die "$(t err_iso_liveboot_missing_fatal)"
        fi
        local liveboot_tmp liveboot_deb=""
        liveboot_tmp="$(mktemp -d /tmp/ultool-liveboot-XXXXXX)"
        # Quelle 1: bereits geladenes Deb im apt-Cache (kein Netzwerk nötig)
        local cachef
        for cachef in /var/cache/apt/archives/live-boot_*.deb; do
            [[ -e "$cachef" ]] || continue
            liveboot_deb="$cachef"
            break
        done
        # Quelle 2: aktuelles Archiv. apt-get download hängt an der Version
        # der LOKALEN Paketlisten - ist die installierte Version (z. B. 1.498)
        # inzwischen aus dem Archiv rotiert, schlägt es fehl ("keine Quelle
        # gefunden"); dann Listen auffrischen und erneut versuchen.
        if [[ -z "$liveboot_deb" ]]; then
            if ! (cd "$liveboot_tmp" && apt-get download live-boot >/dev/null 2>&1); then
                misc "$(t info_retry_apt_update)"
                apt-get update >/dev/null 2>&1 || true
                if ! (cd "$liveboot_tmp" && apt-get download live-boot); then
                    rm -rf -- "$liveboot_tmp"
                    die "$(t err_iso_liveboot_download)"
                fi
            fi
            liveboot_deb="$(find "$liveboot_tmp" -maxdepth 1 -name 'live-boot_*.deb' -print -quit)"
        fi
        if [[ -z "$liveboot_deb" ]]; then
            rm -rf -- "$liveboot_tmp"
            die "$(t err_iso_liveboot_download_short)"
        fi
        if ! dpkg-deb -x "$liveboot_deb" "$liveboot_tmp/x"; then
            rm -rf -- "$liveboot_tmp"
            die "$(t err_iso_liveboot_extract)"
        fi
        mkdir -p /usr/share/initramfs-tools/hooks /usr/share/initramfs-tools/scripts
        cp -a -- "$liveboot_tmp/x/usr/share/initramfs-tools/hooks/live" \
            /usr/share/initramfs-tools/hooks/ 2>/dev/null || true
        # live-boot-bottom als GESAMTES Verzeichnis ersetzen (alte Reste würden
        # mit neuen Helfern mischen), dazu live-boot-Hauptskript und Helfer
        rm -rf -- /usr/share/initramfs-tools/scripts/live-bottom
        cp -a -- "$liveboot_tmp/x/usr/share/initramfs-tools/scripts/." \
            /usr/share/initramfs-tools/scripts/
        rm -rf -- "$liveboot_tmp"
        if [[ ! -e /usr/share/initramfs-tools/hooks/live \
            || ! -e /usr/share/initramfs-tools/scripts/live ]]; then
            die "$(t err_iso_liveboot_restore_failed)"
        fi
        misc "$(t info_iso_liveboot_restored)"
    fi

    local free_gb
    free_gb="$(df -Pk "$WORK" 2>/dev/null | awk 'NR==2{print int($4/1048576)}' || true)"
    if [[ "$free_gb" =~ ^[0-9]+$ ]]; then
        if (( free_gb < 2 )); then
            die "$(t err_iso_low_space "$free_gb" "$WORK")"
        elif (( free_gb < 8 )); then
            warn "$(t warn_iso_low_space "$free_gb" "$WORK")"
        fi
    fi

    if ! grep -qw overlay /proc/filesystems 2>/dev/null; then
        modprobe overlay 2>/dev/null || true
    fi
    if ! grep -qw overlay /proc/filesystems 2>/dev/null; then
        die "$(t err_iso_no_overlay "$(uname -r)")"
    fi

    [[ -n "$ISO_LABEL" ]] || die "$(t err_iso_label_empty)"
    [[ "${#ISO_LABEL}" -le 32 ]] || die "$(t err_iso_label_long "$ISO_LABEL")"
    case "$ISO_LABEL" in
        *[!A-Za-z0-9._-]*) die "$(t err_iso_label_chars "$ISO_LABEL")" ;;
    esac

    case "$SQUASH_COMP" in
        xz|zstd|lzma|gzip|lzo|lz4) : ;;
        *) die "$(t err_iso_bad_comp "$SQUASH_COMP")" ;;
    esac
    txt "$(t iso_comp "$SQUASH_COMP")"

    mkdir -p "$WORK" "$LIVE_TREE/live" "$LIVE_TREE/boot/grub" \
        || die "$(t err_iso_workdirs)"

    local MACH
    MACH="$(uname -m)"
    if [[ "$MACH" != "x86_64" ]]; then
        warn "$(t warn_iso_arch "$MACH")"
    fi

    # Kernel-Auswahl: ein KVER zählt NUR mit nicht-leerem kernel/-Baum in
    # /lib/modules - ein Verzeichnis mit NUR Metadaten (modules.alias/dep,
    # passiert nach Kernel-Update OHNE Reboot: die Module des laufenden
    # Kernels sind dann entfernt) liefert ein Initramfs OHNE Treiber ->
    # Kernel-Panik beim Boot der ISO (früherer Defekt, Änderung 46).
    KVER="$(uname -r)"
    local -a module_kernels=()
    local mk
    while read -r mk; do
        [[ -n "$mk" ]] || continue
        if [[ -n "$(find "/lib/modules/$mk/kernel" -mindepth 1 -print -quit 2>/dev/null || true)" ]]; then
            module_kernels+=("$mk")
        fi
    done < <(find /lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
        | grep -Ev 'extramodules|^build$|^source$' | sort -V || true)
    if [[ -n "$(find "/lib/modules/$KVER/kernel" -mindepth 1 -print -quit 2>/dev/null || true)" ]]; then
        : # laufender Kernel hat Module - bester Kandidat
    elif [[ "${#module_kernels[@]}" -gt 0 ]]; then
        local old_kver="$KVER"
        KVER="${module_kernels[${#module_kernels[@]}-1]}"
        warn "$(t warn_iso_kernel_no_modules "$old_kver" "$KVER")"
    else
        die "$(t err_iso_no_kernel_modules)"
    fi
    HOST_KERNEL="/boot/vmlinuz-$KVER"
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="/cdrom/live/vmlinuz"
    fi
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="$(find /cdrom /run/live -maxdepth 6 -type f -name 'vmlinuz*' -print 2>/dev/null | head -n1 || true)"
    fi
    if [[ -z "$HOST_KERNEL" || ! -e "$HOST_KERNEL" ]]; then
        die "$(t err_iso_kernel_file_missing "$KVER")"
    fi
    txt "$(t iso_using_kernel "$KVER" "$(fstr "$HOST_KERNEL")")"

    misc "$(t iso_copying_kernel)"
    cp "$HOST_KERNEL" "$LIVE_TREE/live/vmlinuz" || die "$(t err_iso_kernel_copy)"

    # Quell-Benutzer für den Live-Autologin ermitteln (Änderung 44): live-boot
    # schreibt bei jedem Live-Boot einen [Autologin]-Block mit SEINEM
    # Benutzernamen (Standard "debian", wenn keine Flavour-Info vorliegt) -
    # dieser existiert im kopierten System meist NICHT (UID-1000-Konflikt
    # bei 25adduser) -> Anmelde-Schleife, schwarzer Bildschirm. Über den
    # Boot-Parameter username= (live-config username=/autologin) meldet sich das
    # Live-System stattdessen als der Benutzer des gesicherten Systems an,
    # der im kopierten System ja existiert. Reihenfolge: Autologin-Config
    # des Quell-Systems, sonst kleinste UID >= 1000. Ein gefundener Name
    # wird gegen /etc/passwd geprüft (live-boot-Appends mit Phantom-Namen
    # fallen so weg).
    local live_benutzer=""
    live_benutzer="$(grep -hs '^User=' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null | tail -n1 | cut -d= -f2 || true)"
    if [[ -z "$live_benutzer" ]]; then
        live_benutzer="$(grep -hs '^autologin-user=' /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.d/*.conf 2>/dev/null | tail -n1 | cut -d= -f2 || true)"
    fi
    if [[ -z "$live_benutzer" ]]; then
        live_benutzer="$(grep -hs '^AutomaticLogin=' /etc/gdm3/custom.conf 2>/dev/null | tail -n1 | cut -d= -f2 || true)"
    fi
    if [[ -n "$live_benutzer" ]] && ! grep -qs "^${live_benutzer}:" /etc/passwd; then
        live_benutzer=""
    fi
    if [[ -z "$live_benutzer" ]]; then
        live_benutzer="$(awk -F: '$3 >= 1000 && $3 < 65534 { if (!min || $3 < min) { min = $3; u = $1 } } END { print u }' /etc/passwd 2>/dev/null || true)"
    fi
    if [[ -n "$live_benutzer" ]]; then
        txt "$(t iso_live_autologin_user "$live_benutzer")"
    else
        warn "$(t warn_iso_no_live_user)"
    fi

    # Standard-Sitzung des Quell-Systems ermitteln - JE NACH DISPLAY-
    # MANAGER (Debian-Flavours: GNOME=gdm3, Kdebian/Ldebian-Neu=sddm,
    # Xdebian/Ldebian-Alt=lightdm). live-boot (1.498) schreibt in seinen
    # [Autologin]-Block Session= LEER - die Flavour-Marker-Dateien
    # (*-live-environment.desktop, plasma.desktop) existieren nur auf
    # Live-Medien, nicht in der kopierten Installation. SDDM findet dann
    # keine Sitzung ("Unable to find autologin session entry"), bricht den
    # Autologin ab und zeigt den Greeter mit vorausgewähltem Benutzer -
    # Anmeldung nur von Hand. Deshalb die Standard-Sitzung des Quell-
    # Systems je DM beim Bau ermitteln und ins Abbild schreiben.
    # WICHTIG (Nutzerbefund): geschrieben wird der Sitzungsname OHNE
    # ".desktop" (z. B. "Ldebian", nicht "Ldebian.desktop") - mit Suffix
    # schlägt der Live-Autologin fehl und es bleibt nur der Passwort-
    # Login. Die .desktop-Endung wird NUR zur Existenzprüfung ergänzt.
    local dm_name=""
    local dm_read
    dm_read="$(cat /etc/X11/default-display-manager 2>/dev/null || true)"
    case "$dm_read" in
        *lightdm) dm_name="LightDM" ;;
        *sddm)    dm_name="SDDM" ;;
        *gdm3)    dm_name="GDM" ;;
    esac
    if [[ -z "$dm_name" ]]; then
        if [[ -e /usr/sbin/lightdm ]]; then
            dm_name="LightDM"
        elif [[ -e /usr/bin/sddm ]]; then
            dm_name="SDDM"
        elif [[ -e /usr/sbin/gdm3 ]]; then
            dm_name="GDM"
        fi
    fi

    local sddm_session=""
    local sess_kandidat
    if [[ -n "$live_benutzer" && -n "$dm_name" ]]; then
        case "$dm_name" in
            SDDM)
                # Reihenfolge: letzte genutzte Sitzung (state.conf [Last]
                # Session, alt: [General] LastSession), Session= der
                # Autologin-Config.
                sess_kandidat="$(awk -F= '/^\[/{inlast=($0 ~ /^\[Last\]/); next} inlast && $1 ~ /^[[:space:]]*Session[[:space:]]*$/ {gsub(/[[:space:]]/, "", $2); v=$2} END {print v}' /var/lib/sddm/state.conf 2>/dev/null || true)"
                if [[ -z "$sess_kandidat" ]]; then
                    sess_kandidat="$(awk -F= '/^\[/{ingen=($0 ~ /^\[General\]/); next} ingen && $1 ~ /^[[:space:]]*LastSession[[:space:]]*$/ {gsub(/[[:space:]]/, "", $2); v=$2} END {print v}' /var/lib/sddm/state.conf 2>/dev/null || true)"
                fi
                sess_kandidat="${sess_kandidat##*/}"
                if [[ -n "$sess_kandidat" && "$sess_kandidat" != *.desktop ]]; then
                    sess_kandidat="${sess_kandidat}.desktop"
                fi
                if [[ -n "$sess_kandidat" && ! -e "/usr/share/xsessions/$sess_kandidat" \
                    && ! -e "/usr/share/wayland-sessions/$sess_kandidat" ]]; then
                    sess_kandidat=""
                fi
                if [[ -z "$sess_kandidat" ]]; then
                    sess_kandidat="$(grep -hs '^Session=' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null \
                        | tail -n1 | cut -d= -f2- | tr -d '[:space:]' || true)"
                    case "$sess_kandidat" in
                        *.desktop)
                            if [[ ! -e "/usr/share/xsessions/$sess_kandidat" \
                                && ! -e "/usr/share/wayland-sessions/$sess_kandidat" ]]; then
                                sess_kandidat=""
                            fi ;;
                        *) sess_kandidat="" ;;
                    esac
                fi
                ;;
            LightDM)
                # autologin-session= steht ohne .desktop in der Config.
                sess_kandidat="$(grep -hs '^autologin-session=' /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.d/*.conf 2>/dev/null \
                    | tail -n1 | cut -d= -f2- | tr -d '[:space:]' || true)"
                if [[ -n "$sess_kandidat" \
                    && ! -e "/usr/share/xsessions/$sess_kandidat.desktop" \
                    && ! -e "/usr/share/wayland-sessions/$sess_kandidat.desktop" ]]; then
                    sess_kandidat=""
                fi
                ;;
            GDM)
                # GDM liest die Sitzung aus AccountsService (ohne .desktop;
                # manche Versionen tragen das Suffix - hier abschneiden).
                sess_kandidat="$(awk -F= '$1 ~ /^[[:space:]]*Session[[:space:]]*$/ {gsub(/[[:space:]]/, "", $2); v=$2} END {print v}' \
                    "/var/lib/AccountsService/users/$live_benutzer" 2>/dev/null || true)"
                sess_kandidat="${sess_kandidat%.desktop}"
                if [[ -n "$sess_kandidat" \
                    && ! -e "/usr/share/xsessions/$sess_kandidat.desktop" \
                    && ! -e "/usr/share/wayland-sessions/$sess_kandidat.desktop" ]]; then
                    sess_kandidat=""
                fi
                ;;
        esac
        # Gemeinsamer Fallback (alle DMs): genau EINE vorhandene
        # Sitzung -> deren Name (ohne .desktop).
        if [[ -z "$sess_kandidat" ]]; then
            local -a sess_dateien=()
            local sf
            for sf in /usr/share/xsessions/*.desktop /usr/share/wayland-sessions/*.desktop; do
                if [[ -e "$sf" ]]; then
                    sess_dateien+=("${sf##*/}")
                fi
            done
            if [[ "${#sess_dateien[@]}" -eq 1 ]]; then
                sess_kandidat="${sess_dateien[0]}"
            fi
        fi
        sddm_session="${sess_kandidat%.desktop}"
        if [[ -n "$sddm_session" ]]; then
            txt "$(t iso_dm_session "$dm_name" "$sddm_session")"
        else
            warn "$(t warn_iso_no_dm_session "$dm_name")"
        fi
    fi

    local confdir="$WORK/initramfs-live-conf"
    mkdir -p "$confdir/conf.d"
    # mkinitramfs liest mit -d nur diese Datei - ohne COMPRESS bricht es ab
    {
        printf 'MODULES=most\n'
        printf 'BUSYBOX=auto\n'
        printf 'COMPRESS=zstd\n'
        printf 'DEVICE=\n'
        printf 'NFSROOT=auto\n'
        printf 'RUNSIZE=10%%\n'
        printf 'FSTYPE=auto\n'
        printf 'RESUME=none\n'
    } > "$confdir/initramfs.conf"

    # live-boot-Autologin NUR neutralisieren, wenn kein Quell-Benutzer
    # ermittelbar war: sonst schreibt 15autologin beim Live-Boot einen
    # [Autologin]-Block auf ein Phantom (SDDM-Anmelde-Schleife, schwarzer
    # Bildschirm). Mit Benutzer UND erkannter SDDM-Sitzung läuft 15autologin
    # unangetastet - sein Session= LEER ist dann harmlos, weil die Sitzung
    # über /var/lib/sddm/state.conf im Abbild bereitsteht (SDDM-Fallback,
    # siehe unten). Das Skript wird nur für die Dauer des mkinitramfs-Laufs
    # neutralisiert (Original wird danach zurückgestellt); das laufende
    # System ist danach unangetastet.
    # DEBIAN: live-boot kennt kein live-boot-bottom/15autologin - der Stub
    # ist hier ein No-op; Autologin steuern wir ueber live-config-
    # Boot-Parameter (live-config.autologin / live-config.nologin).
    local al_script="/usr/share/initramfs-tools/scripts/live-bottom/15autologin"
    local al_backup="${al_script}.ultool-orig"
    local al_neutralisiert="n"
    if [[ -z "$live_benutzer" ]]; then
        if [[ -f "$al_backup" ]]; then
            # Absturz-Recovery: Backup eines früheren Laufs zurückstellen
            mv -f -- "$al_backup" "$al_script"
        fi
        if [[ -f "$al_script" ]]; then
            cp -a -- "$al_script" "$al_backup"
            cat > "$al_script" <<'ALSTUB'
#!/bin/sh
# live-boot-Autologin durch debianlive-tool deaktiviert: das Live-System
# startet mit dem SDDM-Login-Bildschirm statt Autologin.
PREREQ=""
prereqs() { echo "$PREREQ"; }
case $1 in
    prereqs) prereqs; exit 0 ;;
esac
ALSTUB
            al_neutralisiert="j"
            txt "$(t iso_disable_autologin)"
        fi
    fi

    local mki_log
    mki_log="$(mktemp /tmp/ultool-mkinitramfs.XXXXXX)"
    local -a mki_args=(-o "$LIVE_TREE/live/initrd" "$KVER")
    if fallback_aktiv; then
        # Fallback für ältere Debian-Versionen: der normale Weg -
        # mkinitramfs mit der Systemkonfiguration statt Mini-Confdir.
        txt "$(t iso_fallback_initramfs)"
    else
        mki_args=(-d "$confdir" "${mki_args[@]}")
        txt "$(t iso_building_initramfs)"
    fi
    if ! mkinitramfs "${mki_args[@]}" 2> "$mki_log"; then
        if [[ "$al_neutralisiert" == "j" ]]; then
            mv -f -- "$al_backup" "$al_script"
        fi
        {
            printf '%s\n' "$(t err_iso_mkinitramfs_failed)"
            sed 's/^/   /' "$mki_log"
            printf '\n%s\n' "$(t iso_check_pkgs)"
        } >&2
        rm -f "$mki_log"
        die "$(t err_iso_initrd_failed)"
    fi
    rm -f "$mki_log"
    if [[ "$al_neutralisiert" == "j" ]]; then
        mv -f -- "$al_backup" "$al_script"
    fi
    chmod 644 "$LIVE_TREE/live/vmlinuz" "$LIVE_TREE/live/initrd"

    # Sicherheitsnetz (Änderung 46/50): das gebaute Initramfs muss bootbar
    # sein - Init, live-boot-Hauptskript, Konfiguration, kernel/-Modulbaum;
    # im Stub-Fall zusätzlich der neutralisierte 15autologin; dazu
    # Truncations-Erkennung. Defekt -> Abbruch statt unbootbarer ISO.
    if ! initramfs_verifizieren "$LIVE_TREE/live/initrd" "$KVER" "$al_neutralisiert"; then
        die "$(t err_iso_initrd_broken "$KVER")"
    fi

    local base_params="boot=live"
    if [[ -n "$live_benutzer" ]]; then
        base_params="$base_params live-config.username=$live_benutzer live-config.autologin"
    else
        # Kein Quell-Benutzer: live-config-Autologin abschalten
        base_params="$base_params live-config.nologin"
    fi

    add_entry() {
        local title="$1" extra="$2"
        {
            printf '\nmenuentry "Debian Live - %s" {\n' "$title"
            printf '    linux /live/vmlinuz %s %s\n' "$base_params" "$extra"
            printf '    initrd /live/initrd\n}\n' 
        } >> "$LIVE_TREE/boot/grub/grub.cfg"
    }

    {
        printf 'insmod all_video\n'
        printf 'insmod gzio\n'
        printf 'set timeout=10\n'
        printf 'set default=0\n'
    } > "$LIVE_TREE/boot/grub/grub.cfg"

    add_entry "$(t grub_std)" "quiet splash"
    add_entry "$(t grub_verbose)" "loglevel=7"
    add_entry "$(t grub_toram)" "toram"
    add_entry "$(t grub_nomodeset)" "nomodeset"

    txt "$(t iso_mounting_overlay)"
    rm -rf -- "$OVL_UPPER" "$OVL_WORK"
    mkdir -p "$OVL_UPPER" "$OVL_WORK" "$MERGED" || die "$(t err_iso_overlay_dirs)"
    if ! mount -t overlay overlay \
        -o "lowerdir=/,upperdir=$OVL_UPPER,workdir=$OVL_WORK" "$MERGED"; then
        die "$(t err_iso_overlay_mount)"
    fi
    if [[ ! -e "$MERGED/usr/bin" ]]; then
        do_umount "$MERGED"
        die "$(t err_iso_overlay_incomplete)"
    fi
    if [[ ! -e "$MERGED/sbin/init" && ! -e "$MERGED/usr/lib/systemd/systemd" ]]; then
        do_umount "$MERGED"
        die "$(t err_iso_no_systemd)"
    fi

    local other_parts
    other_parts="$(findmnt -rn -o TARGET,FSTYPE 2>/dev/null | awk \
        '$2 !~ /^(proc|sysfs|tmpfs|devtmpfs|devpts|squashfs|efivarfs|cgroup2|securityfs|pstore|bpf|debugfs|tracefs|configfs|mqueue|hugetlbfs|ramfs|autofs|binfmt_misc|overlay|fusectl|nsfs|vfat|iso9660)$/ && $1 ~ /^\/[^\/]/ && $1 != "/boot/efi" {print $1}' || true)"
    if [[ -n "$other_parts" ]]; then
        warn "$(t warn_iso_own_partitions)"
        printf '%s\n' "$other_parts" | sed 's/^/   - /'
    fi

    printf '# Live-System: Root wird vom live-boot-Hook eingebunden, fstab absichtlich leer.\n' \
        > "$MERGED/etc/fstab"
    if [[ -e "$MERGED/etc/crypttab" ]]; then
        : > "$MERGED/etc/crypttab"
    fi
    : > "$MERGED/etc/machine-id"
    if [[ -d "$MERGED/var/lib/dbus" ]]; then
        rm -f -- "$MERGED/var/lib/dbus/machine-id"
        ln -sf /etc/machine-id "$MERGED/var/lib/dbus/machine-id"
    fi

    # Netzwerk live-tauglich machen (nur im Abbild). NM-Pfad: das network-
    # manager-Paket schraenkt Ethernet in /usr/lib/NetworkManager/conf.d ein -
    # die leere /etc-Override schattet sie aus (Mechanik der offiziellen
    # Live-Images, die sonst nur der Installer anlegt). Das udev-Regelfile
    # sortiert nach netplans 90-/99-Regeln (zz-) und hebt deren NM_UNMANAGED=1
    # auf. networkd-Pfad (Server-Quellen ohne NM): netplan rendert zu
    # systemd-networkd, ist aber meist MAC-gebunden (cloud-init) - auf fremder
    # Hardware matcht kein Eintrag -> kein DHCP. networkd nimmt das ERSTE
    # matchende .network-File; netplan-Files heissen 10-netplan-*, der
    # Fallback 85-live-dhcp.network greift also nur dort, wo netplan nichts
    # matcht.
    if [[ -d "$MERGED/etc/NetworkManager" ]]; then
        mkdir -p "$MERGED/etc/NetworkManager/conf.d"
        : > "$MERGED/etc/NetworkManager/conf.d/10-globally-managed-devices.conf"
        rm -f -- "$MERGED/var/lib/NetworkManager/NetworkManager-intern.conf"
        mkdir -p "$MERGED/etc/udev/rules.d"
        {
            printf '# Live-ISO: nach netplans 90-/99-Regeln (zz- sortiert zuletzt);\n'
            printf '# hebt NM_UNMANAGED=1 fuer fremde Geraete (andere MAC) auf.\n'
            printf 'ACTION=="add|change", SUBSYSTEM=="net", ENV{NM_UNMANAGED}="0"\n'
        } > "$MERGED/etc/udev/rules.d/zz-debianlive-nm.rules"
        txt "$(t iso_nm_enabled)"
    fi
    if [[ -e "$MERGED/usr/lib/systemd/system/systemd-networkd.service" ]]; then
        mkdir -p "$MERGED/etc/systemd/network"
        {
            printf '# Live-ISO-Fallback: DHCP fuer Geraete ohne netplan-Match\n'
            printf '# (fremde MAC/Hardware); netplan-Files (10-*) haben Vorrang.\n'
            printf '[Match]\n'
            printf 'Name=e* eth*\n'
            printf '\n[Network]\n'
            printf 'DHCP=yes\n'
        } > "$MERGED/etc/systemd/network/85-live-dhcp.network"
        if [[ ! -d "$MERGED/etc/NetworkManager" ]]; then
            local nd_wants="$MERGED/etc/systemd/system/multi-user.target.wants"
            if [[ ! -e "$nd_wants/systemd-networkd.service" && \
                ! -L "$nd_wants/systemd-networkd.service" ]]; then
                mkdir -p "$nd_wants"
                ln -sf /usr/lib/systemd/system/systemd-networkd.service \
                    "$nd_wants/systemd-networkd.service"
            fi
            txt "$(t iso_networkd_fallback)"
        fi
    fi
    if [[ ! -d "$MERGED/etc/NetworkManager" && \
        ! -e "$MERGED/usr/lib/systemd/system/systemd-networkd.service" ]]; then
        warn "$(t warn_iso_no_network)"
    fi

    liveboot_live_cleanup "$MERGED"

    # Eigener SDDM-Autologin ins Abbild (nur wenn Benutzer UND Sitzung
    # ermittelt). Zwei Dateien, zwei Aufgaben:
    # - /etc/sddm.conf [Autologin] User= + Session=: bewirkt, dass SDDM den
    #   Autologin VERSUCHT. live-boots 15autologin hängt beim Live-Boot einen
    #   weiteren Block mit Session= LEER an (QSettings: letzter gewinnt) -
    #   dieser falls live-boot fehlt unverzichtbare Block wird dadurch zwar
    #   neutralisiert, aber:
    # - /var/lib/sddm/state.conf [Last] Session=: SDDMs offizieller Fallback
    #   bei leerer Autologin-Session (Display.cpp: attemptAutologin liest
    #   stateConfig.Last.Session). Diese Datei trägt die Sitzung durch
    #   live-boots Append hindurch. Beide Formate ([Last] neu ab sddm 0.19/0.20,
    #   [General] LastSession alt) werden geschrieben - QSettings ignoriert
    #   unbekannte Sektionen/Keys, unbekannte Teile sind harmlos.
    # live-boots 15autologin bleibt dafür UNANGETASTET (kein Initramfs-Eingriff
    # mehr im Normalfall); alte [Autologin]-Blöcke hat liveboot_live_cleanup
    # direkt oben entfernt.
    if [[ -n "$live_benutzer" && -n "$sddm_session" ]]; then
        # sddm_session traegt die je DM ermittelte Sitzung (ohne .desktop).
        case "$dm_name" in
            SDDM)
                # Zwei Dateien, zwei Aufgaben:
                # - /etc/sddm.conf [Autologin] User= + Session=: bewirkt,
                #   dass SDDM den Autologin VERSUCHT. live-boots 15autologin
                #   haengt beim Live-Boot einen weiteren Block mit Session=
                #   LEER an (QSettings: letzter gewinnt).
                # - /var/lib/sddm/state.conf [Last] Session=: SDDMs
                #   offizieller Fallback bei leerer Autologin-Session
                #   (Display.cpp: attemptAutologin liest
                #   stateConfig.Last.Session). Diese Datei traegt die
                #   Sitzung durch live-boots Append hindurch. Beide Formate
                #   ([Last] neu ab sddm 0.19/0.20, [General] LastSession
                #   alt) werden geschrieben.
                {
                    printf '# Live-Autologin (debianlive-tool): Sitzungs-Fallback in\n'
                    printf '# /var/lib/sddm/state.conf hält die Sitzung, falls live-boot\n'
                    printf '# seinen [Autologin]-Block mit leerer Session= anhängt.\n'
                    printf '[Autologin]\n'
                    printf 'User=%s\n' "$live_benutzer"
                    printf 'Session=%s\n' "$sddm_session"
                } >> "$MERGED/etc/sddm.conf"
                mkdir -p "$MERGED/var/lib/sddm"
                {
                    printf '[Last]\n'
                    printf 'User=%s\n' "$live_benutzer"
                    printf 'Session=%s\n' "$sddm_session"
                    printf '[General]\n'
                    printf 'LastUser=%s\n' "$live_benutzer"
                    printf 'LastSession=%s\n' "$sddm_session"
                } > "$MERGED/var/lib/sddm/state.conf"
                # Eigentümer am sddm-Account des ABBILDS ausrichten
                # (numerisch, der Host kennt den Bild-Benutzer nicht).
                local sddm_uid sddm_gid
                sddm_uid="$(awk -F: '$1 == "sddm" {print $3; exit}' "$MERGED/etc/passwd" 2>/dev/null || true)"
                sddm_gid="$(awk -F: '$1 == "sddm" {print $3; exit}' "$MERGED/etc/group" 2>/dev/null || true)"
                if [[ "$sddm_uid" =~ ^[0-9]+$ && "$sddm_gid" =~ ^[0-9]+$ ]]; then
                    chown "$sddm_uid:$sddm_gid" "$MERGED/var/lib/sddm/state.conf" 2>/dev/null || true
                fi
                chmod 600 "$MERGED/var/lib/sddm/state.conf"
                txt "$(t iso_sddm_block_written "$live_benutzer" "$sddm_session")"
                txt "$(t iso_sddm_fallback "$sddm_session")"
                ;;
            LightDM)
                # autologin-session= erwartet den Sitzungsnamen ohne
                # .desktop - exakt das hier geschriebene Format.
                mkdir -p "$MERGED/etc/lightdm/lightdm.conf.d"
                {
                    printf '# Live-Autologin (debianlive-tool): Benutzer und\n'
                    printf '# Sitzung des gesicherten Systems.\n'
                    printf '[Seat:*]\n'
                    printf 'autologin-user=%s\n' "$live_benutzer"
                    printf 'autologin-session=%s\n' "$sddm_session"
                } > "$MERGED/etc/lightdm/lightdm.conf.d/50-debianlive-autologin.conf"
                txt "$(t iso_lightdm_block_written "$live_benutzer" "$sddm_session")"
                ;;
            GDM)
                # GDM liest die Sitzung aus AccountsService; die kopierte
                # Installation bringt sie meist selbst mit - nur ergänzen,
                # wenn im Abbild keine Session= steht.
                local gdm_user_file="$MERGED/var/lib/AccountsService/users/$live_benutzer"
                if [[ -f "$gdm_user_file" ]] && grep -qs '^Session=' "$gdm_user_file"; then
                    :
                else
                    mkdir -p "$MERGED/var/lib/AccountsService/users"
                    {
                        printf '[User]\n'
                        printf 'Session=%s\n' "$sddm_session"
                    } > "$gdm_user_file"
                fi
                txt "$(t iso_gdm_session_set "$sddm_session")"
                ;;
        esac
    fi

    local -a excl=( "proc/*" "sys/*" "dev/*" "run/*" "tmp/*" "mnt/*" "media/*"
        "var/tmp/*" "var/log/*" "var/crash/*" "var/lib/systemd/coredump/*"
        "var/cache/apt/archives/*" "var/lib/apt/lists/*"
        "var/lib/systemd/random-seed"
        "lost+found" "cdrom" "swapfile" "swap.img" )

    local work_rel="${WORK#/}"
    if [[ -n "$work_rel" ]]; then
        excl+=("$work_rel")
    fi
    local p
    for p in "${EXTRA_EXCLUDES[@]}"; do
        excl+=("${p#/}")
    done

    txt "$(t iso_close_apps)"
    case "$SQUASH_COMP" in
        xz|lzma) txt "$(t iso_creating_squash_slow "$SQUASH_COMP")" ;;
        *) txt "$(t iso_creating_squash "$SQUASH_COMP")" ;;
    esac
    local new_squash="$LIVE_TREE/live/filesystem.squashfs.new"
    rm -f -- "$new_squash"
    if ! mksquashfs "$MERGED" "$new_squash" -noappend -comp "$SQUASH_COMP" -b 1M -no-recovery \
        -wildcards -e "${excl[@]}"; then
        do_umount "$MERGED"
        die "$(t err_iso_mksquashfs)"
    fi
    sync
    mv -f "$new_squash" "$LIVE_TREE/live/filesystem.squashfs" \
        || die "$(t err_iso_squash_move)"

    if ! dpkg-query -W -f="\${Package}\t\${Version}\n" > "$LIVE_TREE/live/filesystem.manifest" 2>/dev/null; then
        warn "$(t warn_iso_manifest)"
    fi

    do_umount "$MERGED"
    rm -rf -- "$OVL_UPPER" "$OVL_WORK"

    txt "$(t iso_creating_iso "$(fstr "$output_iso")")"
    rm -f -- "$output_iso"
    if ! grub-mkrescue -o "$output_iso" "$LIVE_TREE" -volid "$ISO_LABEL" -iso-level 3 -J -R; then
        die "$(t err_iso_grubmkrescue)"
    fi
    [[ -s "$output_iso" ]] || die "$(t err_iso_not_created)"

    give_back_ownership "$WORK"
    if [[ "$output_iso" != "$WORK"/* ]]; then
        give_back_ownership "$output_iso"
    fi

    local iso_mb
    iso_mb="$(du -m "$output_iso" 2>/dev/null | cut -f1 || true)"
    head_msg "$(t iso_success)"
    txt "$(t iso_output_path "$(fstr "$output_iso")" "${iso_mb:-?}")"
    txt "Kernel:      $KVER"
    # SHA256 der ISO ausgeben (Änderung 46/50): Kopien/USB-Übertragungen
    # lassen sich damit prüfen - dieselbe Schadstelle (abgeschnittene
    # Datei) kann auch beim Kopieren entstehen.
    if command -v sha256sum >/dev/null 2>&1; then
        local iso_sha
        iso_sha="$(sha256sum -- "$output_iso" 2>/dev/null | awk '{print $1}' || true)"
        if [[ -n "$iso_sha" ]]; then
            txt "SHA256:      $iso_sha"
        fi
    fi
    txt "Label:       $ISO_LABEL"
    if [[ -n "$live_benutzer" && -n "$sddm_session" ]]; then
        misc "$(t iso_autologin_user_session "$live_benutzer" "$sddm_session")"
    elif [[ -n "$live_benutzer" ]]; then
        misc "$(t iso_autologin_user "$live_benutzer")"
    else
        misc "$(t iso_autologin_none)"
    fi
    warn "$(t warn_iso_secure_boot)"
    printf '\n'
    head_msg "$(t iso_done_close)"
    return 0
}

choose_squash_comp() {
    local -a comp_algos=(xz zstd lzma gzip lzo lz4)
    local -a comp_descr=(
        "$(t iso_comp_xz)"
        "$(t iso_comp_zstd)"
        "$(t iso_comp_lzma)"
        "$(t iso_comp_gzip)"
        "$(t iso_comp_lzo)"
        "$(t iso_comp_lz4)"
    )
    local -a opts=()
    local i mark pick
    for i in "${!comp_algos[@]}"; do
        mark=""
        if [[ "${comp_algos[$i]}" == "$SQUASH_COMP" ]]; then
            mark="$(t iso_comp_default)"
        fi
        opts+=("$(printf '%-5s %s' "${comp_algos[$i]}" "${comp_descr[$i]}")${mark}")
    done
    head_msg "$(t iso_choose_comp)"
    i=1
    for opt in "${opts[@]}"; do
        misc "  ${i}) ${opt}"
        i=$((i + 1))
    done
    while :; do
        printf '%s' "${C_TEXT}$(t menu_choice)${C_MISC}[1-${#comp_algos[@]}, Enter=${SQUASH_COMP}]: ${C_OFF}"
        get_input || return 1
        pick="${INPUT:-}"
        if [[ -z "$pick" ]]; then
            COMP_CHOICE="$SQUASH_COMP"
            return 0
        fi
        if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#comp_algos[@]} )); then
            COMP_CHOICE="${comp_algos[$((pick - 1))]}"
            return 0
        fi
        misc "$(t iso_comp_invalid "${#comp_algos[@]}")"
    done
}

iso_interactive() {
    head_msg "$(t iso_menu_title)"

    ask_string "$(t word_workdir)" "$(invoking_home)/remastern" || return 0
    WORK="$ANSWER"

    ask_string "$(t q_iso_label)" "UBUNTULIVE" || return 0
    ISO_LABEL="$ANSWER"

    choose_squash_comp || return 0
    SQUASH_COMP="$COMP_CHOICE"

    ask_string "$(t q_iso_target)" "" || return 0
    OUT="$ANSWER"

    local excl_input=""
    ask_string "$(t q_iso_excludes)" "" || return 0
    excl_input="$ANSWER"
    EXTRA_EXCLUDES=()
    if [[ -n "$excl_input" ]]; then
        read -r -a EXTRA_EXCLUDES <<< "$excl_input"
    fi

    txt "$(t iso_summary)"
    misc "$(t iso_sum_work "$(fstr "$WORK")")"
    misc "  Label:              $ISO_LABEL"
    misc "  Kompression:        $SQUASH_COMP (SquashFS)"
    misc "$(t iso_sum_target "$(fstr "${OUT:-$WORK/debianlive.iso}")")"
    if [[ "${#EXTRA_EXCLUDES[@]}" -gt 0 ]]; then
        misc "$(t iso_sum_excludes "${EXTRA_EXCLUDES[*]}")"
    else
        misc "$(t iso_sum_no_excludes)"
    fi

    confirm_yes "$(t q_iso_start_build)" || { misc "$(t info_aborted)"; return 0; }
    do_iso_build
}

#@@ENDBLOCK:ISO

# ============================================================
# Hauptmenü
# ============================================================

main_menu() {
    INTERACTIVE="j"
    while :; do
        if menu_select "$(t menu_main_title "$SCRIPT_NAME" "$VERSION")" \
            "$(t menu_main_iso)" \
            "$(t menu_main_install)" \
            "$(t menu_main_part)" \
            "$(t menu_main_cleanup)" \
            "$(t menu_main_targets)" \
            "$(t menu_main_export)"; then
            case "$MENU_NR" in
                1) require_root --action iso_interactive
                   run_action iso_interactive ;;
                2) require_root --action install_interactive
                   run_action install_interactive ;;
                3) require_root --action part_menu
                   run_action part_menu ;;
                4) require_root --action do_iso_cleanup_interactive
                   run_action do_iso_cleanup_interactive ;;
                5) run_action show_targets_menu ;;
                6) run_action cmd_export ;;
            esac
        else
            misc "$(t info_done)"
            return 0
        fi
    done
}

show_targets_menu() {
    show_targets
}

do_iso_cleanup_interactive() {
    (
        ask_string "$(t word_workdir)" "$(invoking_home)/remastern" || exit 0
        WORK="$ANSWER"
        confirm_yes "$(t q_iso_cleanup "$(fstr "$WORK")")" || exit 0
        do_iso_cleanup
    )
}

# ============================================================
# Einzelskripte exportieren (Teile als eigenständige Scripts)
# ============================================================

EXPORT_NAME[1]="debianlive-part.sh"
EXPORT_NAME[2]="debianlive-iso.sh"
EXPORT_NAME[3]="debianlive-install.sh"
EXPORT_DESC[1]="$(t exp_desc_part)"
EXPORT_DESC[2]="$(t exp_desc_iso)"
EXPORT_DESC[3]="$(t exp_desc_install)"
EXPORT_SEL=()

usage_export() {
    case "$SPRACHE" in
        EN)
            cat <<HILFE
${C_HEAD}$SCRIPT_NAME export - output parts as standalone scripts${C_OFF}

${C_MISC}Writes the chosen parts of $SCRIPT_NAME as standalone runnable
scripts (each with all required helper functions and its own help):

  ${C_FILE}1${C_MISC} = Partitioner -> ${C_FILE}debianlive-part.sh${C_OFF}
  ${C_FILE}2${C_MISC} = ISO creation -> ${C_FILE}debianlive-iso.sh${C_OFF}
  ${C_FILE}3${C_MISC} = Installation  -> ${C_FILE}debianlive-install.sh${C_OFF}
        ${C_MISC}(also contains the partitioner - because of "partition
        first" in the installation menu)

Usage:
  ${C_FILE}$SCRIPT_NAME export [-s LIST] [-o DIR]${C_OFF}
  ${C_FILE}$SCRIPT_NAME -x DIR${C_OFF}            ${C_MISC}short form: export all three to DIR

Options:
  ${C_FILE}-s, --scripts LIST${C_OFF}  ${C_MISC}parts to export, comma separated
                        (e.g. ${C_FILE}1,2,3${C_MISC}); without -s an interactive prompt appears
  ${C_FILE}-o, --output DIR${C_OFF}    ${C_MISC}target directory
                        [default: directory of $SCRIPT_NAME]
  ${C_FILE}-nc, --no-color${C_OFF}            ${C_MISC}disable colors
  ${C_FILE}-h, --help${C_OFF}           ${C_MISC}this help

Examples:
  ${C_FILE}$SCRIPT_NAME export -s 1,2,3${C_OFF}
  ${C_FILE}$SCRIPT_NAME export -s 2 -o /mnt/usb${C_OFF}
HILFE
            ;;
        *)
    cat <<HILFE
${C_HEAD}$SCRIPT_NAME export - Teile als eigenständige Skripte ausgeben${C_OFF}

${C_MISC}Schreibt gewählte Teile von $SCRIPT_NAME als eigenständig lauffähige
Skripte (jeweils mit allen benötigten Hilfsfunktionen und eigener Hilfe):

  ${C_FILE}1${C_MISC} = Partitionierer -> ${C_FILE}debianlive-part.sh${C_OFF}
  ${C_FILE}2${C_MISC} = ISO-Erstellung -> ${C_FILE}debianlive-iso.sh${C_OFF}
  ${C_FILE}3${C_MISC} = Installation   -> ${C_FILE}debianlive-install.sh${C_OFF}
        ${C_MISC}(enthält auch den Partitionierer - wegen "Zuerst
        partitionieren" im Installations-Menü)

Aufruf:
  ${C_FILE}$SCRIPT_NAME export [-s LISTE] [-o VERZ]${C_OFF}
  ${C_FILE}$SCRIPT_NAME -x VERZ${C_OFF}            ${C_MISC}Kurzform: alle drei nach VERZ ausgeben

Optionen:
  ${C_FILE}-s, --scripts LISTE${C_OFF}  ${C_MISC}zu exportierende Teile, kommasepariert
                        (z. B. ${C_FILE}1,2,3${C_MISC}); ohne -s wird interaktiv gefragt
  ${C_FILE}-o, --output VERZ${C_OFF}    ${C_MISC}Zielverzeichnis
                        [Standard: Verzeichnis des $SCRIPT_NAME]
  ${C_FILE}-nc, --no-color${C_OFF}            ${C_MISC}Farben abschalten
  ${C_FILE}-h, --help${C_OFF}           ${C_MISC}diese Hilfe

Beispiele:
  ${C_FILE}$SCRIPT_NAME export -s 1,2,3${C_OFF}
  ${C_FILE}$SCRIPT_NAME export -s 2 -o /mnt/usb${C_OFF}
HILFE
            ;;
    esac
}

export_parse_sel() {
    EXPORT_SEL=()
    local raw p q dup
    local -a teile=()
    IFS=',' read -r -a teile <<< "$1"
    for p in "${teile[@]}"; do
        raw="${p//[[:space:]]/}"
        case "$raw" in
            1|2|3) ;;
            *) return 1 ;;
        esac
        dup="n"
        for q in "${EXPORT_SEL[@]}"; do
            if [[ "$q" == "$raw" ]]; then
                dup="j"
            fi
        done
        if [[ "$dup" == "n" ]]; then
            EXPORT_SEL+=("$raw")
        fi
    done
    if (( ${#EXPORT_SEL[@]} == 0 )); then
        return 1
    fi
    return 0
}

export_interactive() {
    local nr
    head_msg "$(t exp_title)"
    for nr in 1 2 3; do
        misc "  ${nr}) ${EXPORT_DESC[$nr]}  ->  ${EXPORT_NAME[$nr]}"
    done
    while :; do
        printf '%s' "${C_TEXT}$(t exp_which_parts)${C_MISC}[$(t exp_parts_hint)]: ${C_OFF}"
        get_input || return 1
        if [[ -z "$INPUT" ]]; then
            EXPORT_SEL=(1 2 3)
            return 0
        fi
        case "$INPUT" in
            00) quit_all ;;
            0|q|Q) return 1 ;;
        esac
        if export_parse_sel "$INPUT"; then
            return 0
        fi
        misc "$(t exp_sel_invalid)"
    done
}

export_extract_fn() {
    awk -v fn="$1" '
        !drin && $0 == fn "() {" { drin = 1 }
        drin { print }
        drin && $0 == "}" { exit }
    ' "$SCRIPT_PATH"
}

export_block() {
    local start ende
    start="$(grep -n "^#@@BLOCK:$1\$" "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    ende="$(grep -n "^#@@ENDBLOCK:$1\$" "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    if [[ -z "$start" || -z "$ende" ]]; then
        die "$(t err_exp_no_marker "$1" "$SCRIPT_PATH")"
    fi
    sed -n "$((start + 1)),$((ende - 1))p" "$SCRIPT_PATH"
}

export_header() {
    local nr="$1" zweck tools
    case "$nr" in
        1)
            zweck="Interaktiver Partitionierer (sfdisk-Basis)"
            tools="bash >= 4.4, GNU coreutils, util-linux (sfdisk, lsblk, findmnt, blockdev, wipefs), udev; zum Formatieren dosfstools/e2fsprogs/ntfs-3g (FAT32 notfalls eingebauter Formatierer)" ;;
        2)
            zweck="Live-ISO vom laufenden System erstellen"
            tools="bash >= 4.4, GNU coreutils, util-linux, apt-get, squashfs-tools, grub-common + grub-pc-bin + grub-efi-amd64-bin, xorriso, mtools, live-boot + live-config + live-tools + initramfs-tools (fehlende werden nachinstalliert)" ;;
        3)
            zweck="Gebootetes Live-System auf Festplatte/Partition installieren"
            tools="bash >= 4.4, GNU coreutils, util-linux, systemd; läuft im gebooteten Debian-Live-System und braucht Root" ;;
    esac
    cat <<KOPF
#!/usr/bin/env bash
#
# ${EXPORT_NAME[$nr]} - $zweck
#
# Eigenständig lauffähiger Teil von $SCRIPT_NAME $VERSION, erzeugt mit
# "$SCRIPT_NAME export". Enthält alle benötigten Hilfsfunktionen.
#
# Verwendung:
#   ohne Argumente  interaktiv (wie im Hauptmenü von $SCRIPT_NAME;
#                   bei ISO ohne Terminal: Direktstart mit Standardwerten)
#   -h | --help     Hilfe
#   -V | --version  Version
#
# Benötigte Tools:
#   $tools
#
# Exit-Codes: 0 = Erfolg, 2 = falsche Argumente, 3 = Fehler/Abbruch.
# Farben: wie das Erzeuger-Script (--no-color oder NO_COLOR=1).
KOPF
    if [[ "$nr" == "2" ]]; then
        printf '%s\n' \
            '# MENU_NR setzt menu_select (mitgeliefertes Menü-Fundament),' \
            '# im ISO-Teil wird sie nie gelesen.' \
            '# shellcheck disable=SC2034'
    fi
}

export_epilog_part() {
    cat <<'EPILOG'
usage_part() {
    case "$SPRACHE" in
    EN)
        cat <<HILFE
${C_HEAD}${SCRIPT_NAME} - interactive partitioner (sfdisk-based)${C_OFF}

${C_MISC}Usage:
  ${C_FILE}${SCRIPT_NAME}${C_OFF}

${C_MISC}Interactive partition manager with number selection: new
partition table (GPT/MBR), create partitions (purpose presets),
delete, format, set type (ESP/BIOS boot/swap), boot flag.

  ${C_FILE}-nc, --no-color${C_OFF}   ${C_MISC}turn colors off
  ${C_FILE}-h, --help${C_OFF}    ${C_MISC}this help
  ${C_FILE}-V, --version${C_OFF} ${C_MISC}version

${C_TEXT}WARNING: Partitioning deletes data irreversibly!${C_OFF}
HILFE
        ;;
    *)
        cat <<HILFE
${C_HEAD}${SCRIPT_NAME} - interaktiver Partitionierer (sfdisk-Basis)${C_OFF}

${C_MISC}Aufruf:
  ${C_FILE}${SCRIPT_NAME}${C_OFF}

${C_MISC}Interaktiver Partitionsmanager mit Zahlen-Auswahl: neue
Partitionstabelle (GPT/MBR), Partitionen erstellen (Zweck-Presets),
löschen, formatieren, Typ setzen (ESP/BIOS-Boot/Swap), Boot-Flag.

  ${C_FILE}-nc, --no-color${C_OFF}   ${C_MISC}Farben abschalten
  ${C_FILE}-h, --help${C_OFF}    ${C_MISC}diese Hilfe
  ${C_FILE}-V, --version${C_OFF} ${C_MISC}Version

${C_TEXT}ACHTUNG: Partitionieren löscht Daten unwiderruflich!${C_OFF}
HILFE
        ;;
    esac
}

main() {
    local cmd="${1:-}"
    case "$cmd" in
        "")
            require_root
            INTERACTIVE="j"
            part_menu ;;
        -h|--help|help)
            usage_part
            exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        -de|-en)
            shift
            main "$@" ;;
        --no-color)
            shift
            main "$@" ;;
        *)
            err "Unbekanntes Argument: $cmd (Hilfe: ${SCRIPT_NAME} -h)"
            usage_part
            exit 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
EPILOG
}

export_epilog_iso() {
    cat <<'EPILOG'
main() {
    local cmd="${1:-}"
    case "$cmd" in
        -h|--help|help)
            usage_iso
            exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        -de|-en)
            shift
            main "$@" ;;
        --no-color)
            shift
            main "$@" ;;
        "")
            if [[ -t 0 ]]; then
                require_root
                INTERACTIVE="j"
                iso_interactive
            else
                cmd_iso
            fi ;;
        *)
            cmd_iso "$@" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
EPILOG
}

export_epilog_install() {
    cat <<'EPILOG'
main() {
    local cmd="${1:-}"
    case "$cmd" in
        -h|--help|help)
            usage_install
            exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        -de|-en)
            shift
            main "$@" ;;
        --no-color)
            shift
            main "$@" ;;
        "")
            cmd_install ;;
        *)
            cmd_install "$@" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
EPILOG
}

export_generate() {
    local nr="$1" ziel="$2"
    local ln_set ln_common
    ln_set="$(grep -n '^set -euo pipefail$' "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    ln_common="$(grep -n '^#@@BLOCK:COMMON$' "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    if [[ -z "$ln_set" || -z "$ln_common" ]]; then
        die "$(t err_exp_no_core "$SCRIPT_PATH")"
    fi

    {
        export_header "$nr"
        printf '\n'
        sed -n "${ln_set},$((ln_common - 1))p" "$SCRIPT_PATH"
        printf '\n'
        export_block COMMON
        printf '\n'
        case "$nr" in
            1)
                export_block PART
                printf '\n'
                export_epilog_part
                ;;
            2)
                export_block ISO
                printf '\n'
                export_extract_fn usage_iso | sed "s/\\\$SCRIPT_NAME iso/\\\$SCRIPT_NAME/g"
                export_extract_fn cmd_iso | sed "s/\\\$SCRIPT_NAME iso/\\\$SCRIPT_NAME/g"
                printf '\n'
                export_epilog_iso
                ;;
            3)
                export_block PART
                printf '\n'
                export_block INSTALL
                printf '\n'
                export_extract_fn usage_install | sed "s/\\\$SCRIPT_NAME install/\\\$SCRIPT_NAME/g"
                export_extract_fn cmd_install | sed "s/\\\$SCRIPT_NAME install/\\\$SCRIPT_NAME/g"
                printf '\n'
                export_epilog_install
                ;;
        esac
    } > "$ziel"
}

cmd_export() {
    local sel="" outdir="" nr ziel
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage_export
                exit 0 ;;
            -s|--scripts)
                if [[ $# -lt 2 ]]; then
                    err "$(t err_exp_need_sel "$1")"
                    usage_export
                    exit 2
                fi
                sel="$2"
                shift 2 ;;
            -o|--output)
                if [[ $# -lt 2 ]]; then
                    err "$(t err_need_dir "$1")"
                    usage_export
                    exit 2
                fi
                outdir="$2"
                shift 2 ;;
            -de|-en)
                shift ;;
            --no-color)
                shift ;;
            *)
                err "$(t err_unknown_arg "$1" "$SCRIPT_NAME export -h")"
                usage_export
                exit 2 ;;
        esac
    done

    if [[ -n "$sel" ]]; then
        if ! export_parse_sel "$sel"; then
            err "$(t err_exp_bad_sel "$sel")"
            exit 2
        fi
    else
        if ! export_interactive; then
            misc "$(t info_done)"
            return 0
        fi
    fi

    if [[ -z "$outdir" ]]; then
        outdir="$(dirname "$SCRIPT_PATH")"
    fi
    if [[ ! -d "$outdir" ]]; then
        mkdir -p "$outdir" || die "$(t err_exp_outdir "$outdir")"
    fi

    if [[ -z "$sel" ]]; then
        for nr in "${EXPORT_SEL[@]}"; do
            if [[ -e "$outdir/${EXPORT_NAME[$nr]}" ]]; then
                confirm_ja_nein "$(t q_exp_overwrite "$outdir")" || {
                    misc "$(t info_done)"
                    return 0
                }
                break
            fi
        done
    fi

    for nr in "${EXPORT_SEL[@]}"; do
        ziel="$outdir/${EXPORT_NAME[$nr]}"
        export_generate "$nr" "$ziel"
        chmod 755 "$ziel" || die "$(t err_exp_chmod "$ziel")"
    done

    local fehler=0
    for nr in "${EXPORT_SEL[@]}"; do
        ziel="$outdir/${EXPORT_NAME[$nr]}"
        if ! bash -n "$ziel"; then
            err "$(t err_exp_invalid_script "$ziel")"
            rm -f -- "$ziel"
            fehler=1
        fi
    done
    if (( fehler != 0 )); then
        die "$(t err_exp_aborted)"
    fi

    head_msg "$(t exp_done)"
    for nr in "${EXPORT_SEL[@]}"; do
        ziel="$outdir/${EXPORT_NAME[$nr]}"
        misc "  ${EXPORT_NAME[$nr]} (${EXPORT_DESC[$nr]}) -> ${ziel}"
    done
}

# ============================================================
# Hilfe
# ============================================================

usage() {
    case "$SPRACHE" in
        EN)
            cat <<HILFE
${C_HEAD}$SCRIPT_NAME $VERSION - build Debian live ISO + install + partition${C_OFF}

${C_TEXT}One tool for everything around the Debian live ISO:${C_OFF}
${C_MISC}  - create a live ISO of the RUNNING system (BIOS + UEFI bootable)
  - install the booted live system to a disk or partition
    (incl. bootloader, BIOS + UEFI automatically detected)
  - partition disks (interactive, number selection)

${C_HEAD}Usage${C_OFF}
${C_MISC}  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME")${C_OFF}${C_MISC}interactive main menu
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME iso [OPTIONS] [TARGET]")${C_OFF}${C_MISC}create live ISO
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME install -d DEVICE [-y]")${C_OFF}${C_MISC}install the live system
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME part")${C_OFF}${C_MISC}partitioner (interactive)
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME cleanup [-w DIR]")${C_OFF}${C_MISC}remove ISO build artifacts
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME targets")${C_OFF}${C_MISC}show installation targets
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME export [-s 1,2,3]")${C_OFF}${C_MISC}export individual scripts
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME -x DIR")${C_OFF}${C_MISC}short form: export all three
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME -V")${C_OFF}${C_MISC}version

${C_HEAD}Exit codes${C_OFF}
${C_MISC}  0 = success, 2 = wrong arguments, 3 = error/abort.

${C_HEAD}install - install the live system${C_OFF}
${C_MISC}  Runs INSIDE the booted Debian live system and needs root.
  Without ${C_FILE}-d${C_MISC} a target is asked interactively in the terminal.
  For a partition ONLY that partition is formatted - the partition
  table stays unchanged. Requirements:
  UEFI: ESP on the same disk; BIOS + GPT: BIOS boot partition.

  Options:
    ${C_FILE}-d, --disk DEVICE${C_OFF}  ${C_MISC}whole disk OR single partition
    ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}skip confirmation prompt (server use)
    ${C_FILE}-h, --help${C_OFF}         ${C_MISC}this help

  Examples (server, no prompts):
    ${C_FILE}$SCRIPT_NAME install -d /dev/sda -y${C_OFF}
    ${C_FILE}$SCRIPT_NAME install -d /dev/nvme0n1p2 -y${C_OFF}

${C_HEAD}iso - Debian live ISO from the running system${C_OFF}
${C_MISC}  Creates a bootable live ISO of the RUNNING system (root,
  Debian system, work directory without spaces).

  Options:
    ${C_FILE}-w, --work DIR${C_OFF}        ${C_MISC}work directory [default: ~/remastern]
    ${C_FILE}-o, --output PATH${C_OFF}     ${C_MISC}target path/directory of the ISO (like TARGET)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}volume label [default: UBUNTULIVE]
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}squashfs compression [default: zstd]
    ${C_FILE}-e, --exclude PATHS${C_OFF}   ${C_MISC}exclude additionally (space separated)

  Examples:
    ${C_FILE}$SCRIPT_NAME iso /srv/iso/rescue.iso${C_OFF}
    ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_OFF}

${C_HEAD}cleanup / part / targets${C_OFF}
${C_MISC}  ${C_FILE}cleanup${C_MISC} unmounts mounts and deletes build artifacts (${C_FILE}-w DIR${C_MISC}).
  ${C_FILE}part${C_MISC}     interactive partitioner: new table (GPT/MBR),
           create partitions (purpose presets), delete, format,
           set type (ESP/BIOS boot/swap), boot flag - all by number.
  ${C_FILE}targets${C_MISC}  lists possible installation targets (read-only).

${C_HEAD}export - output parts as individual scripts${C_OFF}
${C_MISC}  Writes the parts as standalone runnable scripts:
  ${C_FILE}1${C_MISC} = partitioner (${C_FILE}debianlive-part.sh${C_MISC}), ${C_FILE}2${C_MISC} = ISO creation
  (${C_FILE}debianlive-iso.sh${C_MISC}), ${C_FILE}3${C_MISC} = installation (${C_FILE}debianlive-install.sh${C_MISC}).
  Selection via ${C_FILE}-s 1,2,3${C_MISC} or interactive, target via ${C_FILE}-o DIR${C_MISC}
  [default: directory of $SCRIPT_NAME].

${C_HEAD}Color scheme${C_OFF}
${C_MISC}  headings light cyan, text light yellow, files/paths light magenta,
  everything else light green (errors red). Disable: ${C_FILE}-nc, --no-color${C_MISC} or ${C_FILE}NO_COLOR=1${C_OFF}

${C_TEXT}ATTENTION: Installing and partitioning delete data irreversibly!${C_OFF}
HILFE
            ;;
        *)
    cat <<HILFE
${C_HEAD}$SCRIPT_NAME $VERSION - Debian-Live-ISO bauen + installieren + partitionieren${C_OFF}

${C_TEXT}Ein Werkzeug für alle Aufgaben rund um die Debian-Live-ISO:${C_OFF}
${C_MISC}  - Live-ISO vom LAUFENDEN System erstellen (BIOS + UEFI bootbar)
  - das gebootete Live-System auf eine Festplatte oder Partition
    installieren (inkl. Bootloader, BIOS + UEFI automatisch)
  - Festplatten partitionieren (interaktiv, Zahlen-Auswahl)

${C_HEAD}Aufruf${C_OFF}
${C_MISC}  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME")${C_OFF}${C_MISC}interaktives Hauptmenü
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME iso [OPTIONEN] [ZIEL]")${C_OFF}${C_MISC}Live-ISO erstellen
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME install -d GERÄT [-y]")${C_OFF}${C_MISC}Live-System installieren
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME part")${C_OFF}${C_MISC}Partitionierer (interaktiv)
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME cleanup [-w VERZ]")${C_OFF}${C_MISC}ISO-Bau-Artefakte entfernen
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME targets")${C_OFF}${C_MISC}Installationsziele anzeigen
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME export [-s 1,2,3]")${C_OFF}${C_MISC}Einzelskripte ausgeben
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME -x VERZ")${C_OFF}${C_MISC}Kurzform: alle drei ausgeben
  ${C_FILE}$(printf '%-37s' "$SCRIPT_NAME -V")${C_OFF}${C_MISC}Version

${C_HEAD}Exit-Codes${C_OFF}
${C_MISC}  0 = Erfolg, 2 = falsche Argumente, 3 = Fehler/Abbruch.

${C_HEAD}install - Live-System installieren${C_OFF}
${C_MISC}  Läuft INNERHALB des gebooteten Debian-Live-Systems und braucht Root.
  Ohne ${C_FILE}-d${C_MISC} wird im Terminal interaktiv ein Ziel abgefragt.
  Bei einer Partition wird NUR diese Partition formatiert - die
  Partitionstabelle bleibt unverändert. Voraussetzungen:
  UEFI: ESP auf derselben Platte; BIOS + GPT: BIOS-Boot-Partition.

  Optionen:
    ${C_FILE}-d, --disk GERÄT${C_OFF}   ${C_MISC}komplette Festplatte ODER einzelne Partition
    ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}Sicherheitsabfrage überspringen (Server-Einsatz)
    ${C_FILE}-h, --help${C_OFF}         ${C_MISC}diese Hilfe

  Beispiele (Server, ohne Rückfragen):
    ${C_FILE}$SCRIPT_NAME install -d /dev/sda -y${C_OFF}
    ${C_FILE}$SCRIPT_NAME install -d /dev/nvme0n1p2 -y${C_OFF}

${C_HEAD}iso - Debian-Live-ISO vom laufenden System${C_OFF}
${C_MISC}  Erstellt eine bootbare Live-ISO des LAUFENDEN Systems (Root-Rechte,
  Debian-System, Arbeitsverzeichnis ohne Leerzeichen).

  Optionen:
    ${C_FILE}-w, --work VERZ${C_OFF}       ${C_MISC}Arbeitsverzeichnis [Standard: ~/remastern]
    ${C_FILE}-o, --output PFAD${C_OFF}     ${C_MISC}Zielpfad/Verzeichnis der ISO (wie ZIEL)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}Volume-Label [Standard: UBUNTULIVE]
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}SquashFS-Kompression [Standard: zstd]
    ${C_FILE}-e, --exclude PFADE${C_OFF}   ${C_MISC}zusätzlich ausschließen (leerzeichengetrennt)

  Beispiele:
    ${C_FILE}$SCRIPT_NAME iso /srv/iso/rescue.iso${C_OFF}
    ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_OFF}

${C_HEAD}cleanup / part / targets${C_OFF}
${C_MISC}  ${C_FILE}cleanup${C_MISC} löst Mounts und löscht Build-Artefakte (${C_FILE}-w VERZ${C_MISC}).
  ${C_FILE}part${C_MISC}     interaktiver Partitionierer: neue Tabelle (GPT/MBR),
           Partitionen erstellen (Zweck-Presets), löschen, formatieren,
           Typ setzen (ESP/BIOS-Boot/Swap), Boot-Flag - alles per Zahl.
  ${C_FILE}targets${C_MISC}  listet mögliche Installationsziele (read-only).

${C_HEAD}export - Teile als Einzelskripte ausgeben${C_OFF}
${C_MISC}  Schreibt die Teile als eigenständig lauffähige Skripte:
  ${C_FILE}1${C_MISC} = Partitionierer (${C_FILE}debianlive-part.sh${C_MISC}), ${C_FILE}2${C_MISC} = ISO-Erstellung
  (${C_FILE}debianlive-iso.sh${C_MISC}), ${C_FILE}3${C_MISC} = Installation (${C_FILE}debianlive-install.sh${C_MISC}).
  Auswahl per ${C_FILE}-s 1,2,3${C_MISC} oder interaktiv, Ziel per ${C_FILE}-o VERZ${C_MISC}
  [Standard: Verzeichnis des $SCRIPT_NAME].

${C_HEAD}Farbschema${C_OFF}
${C_MISC}  Überschriften hell-cyan, Text hell-gelb, Dateien/Pfade hell-lila,
  alles andere hell-grün (Fehler rot). Abschalten: ${C_FILE}-nc, --no-color${C_MISC} oder ${C_FILE}NO_COLOR=1${C_OFF}

${C_TEXT}ACHTUNG: Installation und Partitionieren löschen Daten unwiderruflich!${C_OFF}
HILFE
            ;;
    esac
}

usage_install() {
    case "$SPRACHE" in
        EN)
            cat <<HILFE
${C_HEAD}$SCRIPT_NAME install - installs the booted live system${C_OFF}

${C_MISC}Usage:
  ${C_FILE}$SCRIPT_NAME install -d DEVICE [-y]${C_OFF}

${C_MISC}Options:
  ${C_FILE}-d, --disk DEVICE${C_OFF}  ${C_MISC}whole disk OR single partition
                      (without ${C_FILE}-d${C_MISC} a target is asked interactively)
  ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}skip confirmation prompt
  ${C_FILE}-h, --help${C_OFF}         ${C_MISC}this help

${C_MISC}For a partition ONLY that partition is formatted - the disk's
partition table stays unchanged. Requirements:
UEFI: ESP on the same disk; BIOS + GPT: BIOS boot partition.

${C_TEXT}ATTENTION: All data on the target device is irreversibly deleted!${C_OFF}
HILFE
            ;;
        *)
    cat <<HILFE
${C_HEAD}$SCRIPT_NAME install - installiert das gebootete Live-System${C_OFF}

${C_MISC}Aufruf:
  ${C_FILE}$SCRIPT_NAME install -d GERÄT [-y]${C_OFF}

${C_MISC}Optionen:
  ${C_FILE}-d, --disk GERÄT${C_OFF}   ${C_MISC}komplette Festplatte ODER einzelne Partition
                      (ohne ${C_FILE}-d${C_MISC} wird interaktiv ein Ziel abgefragt)
  ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}Sicherheitsabfrage überspringen
  ${C_FILE}-h, --help${C_OFF}         ${C_MISC}diese Hilfe

${C_MISC}Bei einer Partition wird NUR diese Partition formatiert - die
Partitionstabelle der Platte bleibt unverändert. Voraussetzungen:
UEFI: ESP auf derselben Platte; BIOS + GPT: BIOS-Boot-Partition.

${C_TEXT}ACHTUNG: Alle Daten auf dem Zielgerät werden unwiderruflich gelöscht!${C_OFF}
HILFE
            ;;
    esac
}

usage_iso() {
    case "$SPRACHE" in
        EN)
            cat <<HILFE
${C_HEAD}$SCRIPT_NAME iso - Debian live ISO from the running system${C_OFF}

${C_MISC}Usage:
  ${C_FILE}$SCRIPT_NAME iso [OPTIONS] [TARGET]${C_OFF}

${C_MISC}TARGET                  Target path of the ISO: file (ends in ${C_FILE}.iso${C_MISC}) or
                        directory (receives ${C_FILE}debianlive.iso${C_MISC}).
                        If omitted: <work directory>/debianlive.iso

Options:
  ${C_FILE}-w, --work DIR${C_OFF}        ${C_MISC}work directory for the build [default: ~/remastern]
  ${C_FILE}-o, --output PATH${C_OFF}     ${C_MISC}target path/directory of the ISO (like TARGET)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}volume label of the ISO [default: UBUNTULIVE]
                        (max. 32 characters, A-Z 0-9 . _ -)
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}squashfs compression: xz, zstd, lzma,
                        gzip, lzo, lz4 [default: zstd, configurable in the
                        script via SQUASH_COMP=...]
  ${C_FILE}-e, --exclude PATHS${C_OFF}   ${C_MISC}additional exclusions, space separated,
                        e.g. ${C_FILE}-e "/home/user/data /opt/big"${C_MISC}
  ${C_FILE}-nc, --no-color${C_OFF}            ${C_MISC}disable colors
  ${C_FILE}-h, --help${C_OFF}            ${C_MISC}this help

Examples:
  ${C_FILE}$SCRIPT_NAME iso /srv/iso/test.iso${C_MISC}
  ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_MISC}
HILFE
            ;;
        *)
    cat <<HILFE
${C_HEAD}$SCRIPT_NAME iso - Debian-Live-ISO vom laufenden System${C_OFF}

${C_MISC}Aufruf:
  ${C_FILE}$SCRIPT_NAME iso [OPTIONEN] [ZIEL]${C_OFF}

${C_MISC}ZIEL                    Zielpfad der ISO: Datei (endet auf ${C_FILE}.iso${C_MISC}) oder
                        Verzeichnis (dort landet ${C_FILE}debianlive.iso${C_MISC}).
                        Ohne Angabe: <Arbeitsverzeichnis>/debianlive.iso

Optionen:
  ${C_FILE}-w, --work VERZ${C_OFF}       ${C_MISC}Arbeitsverzeichnis für den Bau [Standard: ~/remastern]
  ${C_FILE}-o, --output PFAD${C_OFF}     ${C_MISC}Zielpfad/Verzeichnis der ISO (wie ZIEL)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}Volume-Label der ISO [Standard: UBUNTULIVE]
                        (max. 32 Zeichen, A-Z 0-9 . _ -)
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}SquashFS-Kompression: xz, zstd, lzma,
                        gzip, lzo, lz4 [Standard: zstd, im Script einstellbar
                        über SQUASH_COMP=...]
  ${C_FILE}-e, --exclude PFADE${C_OFF}   ${C_MISC}Zusätzliche Ausschlüsse, leerzeichengetrennt,
                        z. B. ${C_FILE}-e "/home/user/Daten /opt/gross"${C_MISC}
  ${C_FILE}-nc, --no-color${C_OFF}            ${C_MISC}Farben abschalten
  ${C_FILE}-h, --help${C_OFF}            ${C_MISC}diese Hilfe

Beispiele:
  ${C_FILE}$SCRIPT_NAME iso /srv/iso/test.iso${C_MISC}
  ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_MISC}
HILFE
            ;;
    esac
}

# ============================================================
# Befehls-Zerlegung
# ============================================================

cmd_iso() {
    local iso_target="" excl_input=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage_iso; exit 0 ;;
            -w|--work)
                if [[ $# -lt 2 ]]; then err "$(t err_need_dir "$1")"; usage_iso; exit 2; fi
                WORK="$2"; shift 2 ;;
            -o|--output)
                if [[ $# -lt 2 ]]; then err "$(t err_need_path "$1")"; usage_iso; exit 2; fi
                OUT="$2"; shift 2 ;;
            -l|--label)
                if [[ $# -lt 2 ]]; then err "$(t err_need_label "$1")"; usage_iso; exit 2; fi
                ISO_LABEL="$2"; shift 2 ;;
            -c|--compression)
                if [[ $# -lt 2 ]]; then err "$(t err_need_algo "$1")"; usage_iso; exit 2; fi
                SQUASH_COMP="$2"; shift 2 ;;
            -e|--exclude)
                if [[ $# -lt 2 ]]; then err "$(t err_need_excludes "$1")"; usage_iso; exit 2; fi
                excl_input="$2"
                if [[ -n "$excl_input" ]]; then
                    local -a parsed=()
                    read -r -a parsed <<< "$excl_input"
                    EXTRA_EXCLUDES+=("${parsed[@]}")
                fi
                shift 2 ;;
            -de|-en) shift ;;
            --no-color) shift ;;
            -*)
                err "$(t err_unknown_opt "$1" "$SCRIPT_NAME iso -h")"
                usage_iso
                exit 2 ;;
            *)
                if [[ -n "$iso_target" ]]; then
                    err "$(t err_iso_one_target)"
                    exit 2
                fi
                iso_target="$1"; shift ;;
        esac
    done
    if [[ -n "$iso_target" ]]; then
        OUT="$iso_target"
    fi

    INTERACTIVE="n"
    do_iso_build
}

cmd_install() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage_install; exit 0 ;;
            -d|--disk)
                if [[ $# -lt 2 ]]; then err "$(t err_need_device "$1")"; usage_install; exit 2; fi
                DISK="$2"; shift 2 ;;
            -y|--yes) ASSUME_YES="j"; shift ;;
            -de|-en) shift ;;
            --no-color) shift ;;
            *)
                err "$(t err_unknown_arg "$1" "$SCRIPT_NAME install -h")"
                usage_install
                exit 2 ;;
        esac
    done

    require_root
    INTERACTIVE="n"

    if [[ -z "$DISK" && -t 0 ]]; then
        INTERACTIVE="j"
        choose_install_target || exit 3
    fi

    do_install
}

cmd_part() {
    require_root
    INTERACTIVE="j"
    part_menu
}

cmd_cleanup() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w|--work)
                if [[ $# -lt 2 ]]; then err "$(t err_need_dir "$1")"; usage; exit 2; fi
                WORK="$2"; shift 2 ;;
            -de|-en) shift ;;
            --no-color) shift ;;
            -h|--help) usage; exit 0 ;;
            *)
                err "$(t err_unknown_arg "$1" "$SCRIPT_NAME -h")"
                exit 2 ;;
        esac
    done
    do_iso_cleanup
}

cmd_targets() {
    show_targets
}

# ============================================================
# main
# ============================================================

main() {
    local cmd="menu"
    local -a rest=()
    local a
    for a in "$@"; do
        case "$a" in
            -de|-en) ;;
            *) rest+=("$a") ;;
        esac
    done
    set -- "${rest[@]}"
    if [[ $# -gt 0 ]]; then
        cmd="$1"
        shift
    fi

    case "$cmd" in
        --action)
            if [[ -n "${1:-}" ]]; then
                run_action "$1"
                exit $?
            fi
            usage
            exit 2 ;;
        menu)                       main_menu ;;
        iso)                        cmd_iso "$@" ;;
        install)                    cmd_install "$@" ;;
        part|partition|partitioner) cmd_part ;;
        cleanup)                    cmd_cleanup "$@" ;;
        targets|ziele)              cmd_targets ;;
        export|scripts|skripte)     cmd_export "$@" ;;
        -x|--extract)
            if [[ $# -lt 1 ]]; then
                err "$(t err_need_dir "$cmd")"
                usage
                exit 2
            fi
            cmd_export -s 1,2,3 -o "$1" ;;
        help|-h|--help)             usage; exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        --no-color)
            main_menu ;;
        *)
            err "$(t err_unknown_cmd "$cmd")"
            usage
            exit 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
#@@@END:debian/debianlive-tool@@@
#@@@SCRIPT:arch/archlive-tool@@@
#!/usr/bin/env bash
#
# archlive-tool 2.0 - Live-ISO bauen + gebootetes Live-System installieren
#                     + interaktiver Partitionierer (sfdisk-Basis)
#
# Zweck:
#   Ein einziges Werkzeug für alle Aufgaben rund um die eigene Arch-Live-ISO:
#     - Live-ISO vom LAUFENDEN System erstellen (BIOS + UEFI bootbar)
#     - das gebootete Live-System auf Festplatte oder Partition installieren
#       (inkl. GRUB, BIOS + UEFI automatisch erkannt)
#     - Festplatten interaktiv partitionieren (Zahlen-Auswahl)
#
# Verwendung:
#   archlive-tool                       interaktives Hauptmenü
#   archlive-tool iso [OPTIONEN] [ZIEL] Live-ISO erstellen
#   archlive-tool install -d GERÄT [-y] Live-System installieren
#   archlive-tool part                  Partitionierer (interaktiv)
#   archlive-tool cleanup [-w VERZ]     ISO-Bau-Artefakte entfernen
#   archlive-tool targets               mögliche Installationsziele zeigen
#   archlive-tool help | -V             Hilfe / Version
#
# Benötigte Tools:
#   bash >= 4.4, GNU coreutils, util-linux (sfdisk, lsblk, findmnt, ...),
#   systemd (udevadm), je nach Aktion pacman, squashfs-tools, grub, mtools,
#   libisoburn, mkinitcpio + mkinitcpio-archiso (werden bei Bedarf
#   nachinstalliert), dosfstools/e2fsprogs/ntfs-3g fürs Formatieren.
#
# Exit-Codes:
#   0  Erfolg
#   2  Falsche Argumente / unbekannter Befehl (Usage wird ausgegeben)
#   3  Fataler Fehler ("die") oder Abbruch durch den Benutzer
#   130/143/129  SIGINT/SIGTERM/SIGHUP (Aufräumarbeiten laufen vorher)
#
# Farben: Überschriften hell-cyan, Text hell-gelb, Dateien/Pfade hell-lila,
#         alles andere hell-grün (Fehler rot). Abschaltbar mit --no-color
#         oder der Umgebungsvariable NO_COLOR.
#
# Zweisprachig DE/EN: Sprache oben über SPRACHE einstellbar
# (AUTO = Systemsprache); LLT_LANG=DE|EN aus der GUI hat Vorrang.
#
set -euo pipefail

VERSION="3.2"
# Anzeigename = tatsaechlicher Dateiname (umbenennbar);
# per Umgebungsvariablen ueberschreibbar.
SCRIPT_NAME="${ARCHLIVE_SELF_NAME:-$(basename -- "$0")}"
SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || true)"
if [[ -z "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$0"
fi
ORIG_ARGS=("$@")

#@@BLOCK:COMMON
# ==================== SPRACHE / LANGUAGE ====================
# Sprache aller Meldungen: AUTO (Systemsprache, Voreinstellung), DE oder EN.
# Zum Festlegen den Wert unten eintragen, z. B.:  SPRACHE=DE   bzw.   SPRACHE=EN
# Startet man das Skript aus der LinuxLiveTool-GUI, gewinnt die dort gewaehlte
# Sprache (Umgebungsvariable LLT_LANG = DE oder EN) ueber dieser Einstellung.
SPRACHE=DE
# Flags -de/-en: Sprache explizit setzen (gewinnt ueber AUTO, nicht
# ueber LLT_LANG der GUI); die Flags werden aus den Argumenten entfernt.
for sprache_a in "$@"; do
    case "$sprache_a" in
        -de) SPRACHE=DE ;;
        -en) SPRACHE=EN ;;
        *) args_neu+=("$sprache_a") ;;
    esac
done
set -- "${args_neu[@]}"
case "${LLT_LANG:-}" in
    DE|EN) SPRACHE="$LLT_LANG" ;;
esac
case "$SPRACHE" in
    AUTO) case "${LC_ALL:-${LANG:-}}" in de*|DE*) SPRACHE=DE ;; *) SPRACHE=EN ;; esac ;;
esac

# Textkatalog: alle Meldungen in DE und EN (keine Extradatei).
#   t  KEY [ARGS...]  -> Meldung nach stdout
#   te KEY [ARGS...]  -> Meldung nach stderr
#   td KEY [ARGS...]  -> Meldung nach stderr + Abbruch (exit 1)
# ARGS werden per printf %s in die Meldung eingesetzt (%s-Platzhalter im Text).
t() {
    local key=$1; shift
    case "$key:$SPRACHE" in
        # ---------- Allgemeine Ausgabe-Helfer ----------
        ui_continue_enter:EN) printf '%s\n' "Press Enter to continue" ;;
        ui_continue_enter:*)  printf '%s\n' "Weiter mit Enter" ;;
        ui_aborted:EN) printf '%s\n' "Aborted." ;;
        ui_aborted:*)  printf '%s\n' "Abgebrochen." ;;
        err_aborted:EN) printf '%s\n' "ERROR: Aborted." ;;
        err_aborted:*)  printf '%s\n' "FEHLER: Abgebrochen." ;;
        menu_prompt_choice:EN) printf '%s\n' "Choice" ;;
        menu_prompt_choice:*)  printf '%s\n' "Auswahl" ;;
        menu_prompt_range:EN) printf '[1-%s, 0=Back, 00=Quit]: \n'  "$1" ;;
        menu_prompt_range:*) printf '[1-%s, 0=Zurück, 00=Beenden]: \n'  "$1" ;;
        menu_quit:EN) printf '%s\n' "Quit" ;;
        menu_quit:*)  printf '%s\n' "Beenden" ;;
        menu_err_notanumber:EN) printf '%s\n' "Please enter a NUMBER." ;;
        menu_err_notanumber:*)  printf '%s\n' "Bitte eine ZAHL eingeben." ;;
        menu_err_bad_number:EN) printf 'Invalid number (1-%s).\n'  "$1" ;;
        menu_err_bad_number:*) printf 'Ungültige Nummer (1-%s).\n'  "$1" ;;
        q_jn:EN) printf '%s\n' "Y/n" ;;
        q_jn:*)  printf '%s\n' "J/n" ;;
        q_confirm_continue:EN) printf '%s\n' "Continue? [y/n]" ;;
        q_confirm_continue:*)  printf '%s\n' "Fortfahren? [j/n]" ;;
        q_abort_empty:EN) printf '%s\n' "Aborted (empty input)." ;;
        q_abort_empty:*)  printf '%s\n' "Abgebrochen (leere Eingabe)." ;;
        q_answer_ja_nein:EN) printf '%s\n' "Please answer with y or n." ;;
        q_answer_ja_nein:*)  printf '%s\n' "Bitte mit j oder n antworten." ;;
        info_requesting_root:EN) printf '%s\n' "Requesting root privileges (sudo)..." ;;
        info_requesting_root:*)  printf '%s\n' "Fordere Root-Rechte an (sudo)..." ;;
        # ---------- Werkzeuge nachinstallieren (ensure_tool) ----------
        q_install_missing_tool:EN) printf '%s is missing (package %s). Install it now via pacman?\n'  "$1" "$2" ;;
        q_install_missing_tool:*) printf '%s fehlt (Paket %s). Jetzt per pacman nachinstallieren?\n'  "$1" "$2" ;;
        warn_tool_missing_aborted:EN) printf 'Warning: %s aborted - %s is still missing.\n'  "$1" "$2" ;;
        warn_tool_missing_aborted:*) printf 'Warnung: %s abgebrochen - %s fehlt weiterhin.\n'  "$1" "$2" ;;
        info_installing_pkg:EN) printf 'Installing package %s (network required)...\n'  "$1" ;;
        info_installing_pkg:*) printf 'Installiere Paket %s (Netzwerk nötig)...\n'  "$1" ;;
        info_pacman_retry:EN) printf '%s\n' "Retrying with 'pacman -Sy' (refreshing the package database)..." ;;
        info_pacman_retry:*)  printf '%s\n' "Neuer Versuch mit 'pacman -Sy' (Paketdatenbank auffrischen)..." ;;
        err_tool_install_failed:EN) printf 'ERROR: Could not install %s (package %s).\n'  "$1" "$2" ;;
        err_tool_install_failed:*) printf 'FEHLER: %s konnte nicht installiert werden (Paket %s).\n'  "$1" "$2" ;;
        err_tool_install_failed2:EN) printf '%s\n' "ERROR: Could not install %s (package %s).
Check network/mirrors - in the live system 'pacman -Sy' usually helps." "$1" "$2" ;;
        err_tool_install_failed2:*)  printf '%s\n' "FEHLER: %s konnte nicht installiert werden (Paket %s).
Netzwerk/Spiegel prüfen - im Live-System hilft meist 'pacman -Sy'." "$1" "$2" ;;
        info_tool_available:EN) printf '%s is now available.\n'  "$1" ;;
        info_tool_available:*) printf '%s ist jetzt verfügbar.\n'  "$1" ;;
        ensure_default_context:EN) printf '%s\n' "action" ;;
        ensure_default_context:*)  printf '%s\n' "Aktion" ;;
        # ---------- Dateisysteme / FAT32 ----------
        err_fat_sectorsize:EN) printf 'ERROR: FAT32: sector size %s is not supported.\n'  "$1" ;;
        err_fat_sectorsize:*) printf 'FEHLER: FAT32: Sektorgröße %s wird nicht unterstützt.\n'  "$1" ;;
        err_fat_size:EN) printf 'ERROR: FAT32: could not determine the size of %s.\n'  "$1" ;;
        err_fat_size:*) printf 'FEHLER: FAT32: Größe von %s konnte nicht ermittelt werden.\n'  "$1" ;;
        err_fat_too_big:EN) printf 'ERROR: FAT32: device too large for FAT32 (%s bytes).\n'  "$1" ;;
        err_fat_too_big:*) printf 'FEHLER: FAT32: Gerät zu groß für FAT32 (%s Bytes).\n'  "$1" ;;
        err_fat_cluster:EN) printf 'ERROR: FAT32: invalid cluster size for sector size %s.\n'  "$1" ;;
        err_fat_cluster:*) printf 'FEHLER: FAT32: Clustergröße für Sektorgröße %s ungültig.\n'  "$1" ;;
        err_fat_too_small:EN) printf '%s\n' "ERROR: FAT32: device too small for a FAT32." ;;
        err_fat_too_small:*)  printf '%s\n' "FEHLER: FAT32: Gerät zu klein für ein FAT32." ;;
        warn_fat_few_clusters:EN) printf 'Warning: FAT32: only %s clusters (small volume) - creating it anyway.\n'  "$1" ;;
        warn_fat_few_clusters:*) printf 'Warnung: FAT32: nur %s Cluster (kleines Volume) - wird trotzdem angelegt.\n'  "$1" ;;
        err_fat_many_clusters:EN) printf 'ERROR: FAT32: too many clusters (%s).\n'  "$1" ;;
        err_fat_many_clusters:*) printf 'FEHLER: FAT32: zu viele Cluster (%s).\n'  "$1" ;;
        info_fat_created:EN) printf 'FAT32 (built-in): %s-byte clusters, %s clusters, 2 FATs of %s KiB each\n'  "$1" "$2" "$3" ;;
        info_fat_created:*) printf 'FAT32 (eingebaut): Cluster %s Bytes, %s Cluster, 2 FATs à %s KiB\n'  "$1" "$2" "$3" ;;
        err_fat_failed:EN) printf 'ERROR: Could not create FAT32 on %s.\n'  "$1" ;;
        err_fat_failed:*) printf 'FEHLER: FAT32 konnte auf %s nicht angelegt werden.\n'  "$1" ;;
        err_dev_mounted:EN) printf 'ERROR: %s is mounted - unmount it first.\n'  "$1" ;;
        err_dev_mounted:*) printf 'FEHLER: %s ist eingehängt - bitte zuerst aushängen.\n'  "$1" ;;
        err_no_mkfs_ext4:EN) printf '%s\n' "ERROR: mkfs.ext4 is missing (package e2fsprogs) - cannot format ext4." ;;
        err_no_mkfs_ext4:*)  printf '%s\n' "FEHLER: mkfs.ext4 fehlt (Paket e2fsprogs) - ext4 kann nicht formatiert werden." ;;
        info_fs_created_builtin:EN) printf 'Created vfat (FAT32) filesystem on %s (built-in formatter).\n'  "$1" ;;
        info_fs_created_builtin:*) printf 'Dateisystem vfat (FAT32) auf %s angelegt (eingebauter Formatierer).\n'  "$1" ;;
        err_format_failed:EN) printf 'ERROR: Formatting %s as %s failed.\n'  "$1" "$2" ;;
        err_format_failed:*) printf 'FEHLER: Formatieren von %s mit %s fehlgeschlagen.\n'  "$1" "$2" ;;
        err_no_mkswap:EN) printf '%s\n' "ERROR: mkswap is missing (package util-linux)." ;;
        err_no_mkswap:*)  printf '%s\n' "FEHLER: mkswap fehlt (Paket util-linux)." ;;
        err_no_mkfs_ntfs:EN) printf '%s\n' "ERROR: mkfs.ntfs is missing (package ntfs-3g) - cannot format NTFS." ;;
        err_no_mkfs_ntfs:*)  printf '%s\n' "FEHLER: mkfs.ntfs fehlt (Paket ntfs-3g) - NTFS kann nicht formatiert werden." ;;
        info_formatting:EN) printf 'Formatting %s as %s ...\n'  "$1" "$2" ;;
        info_formatting:*) printf 'Formatiere %s mit %s ...\n'  "$1" "$2" ;;
        info_fs_created:EN) printf 'Created %s filesystem on %s.\n'  "$1" "$2" ;;
        info_fs_created:*) printf 'Dateisystem %s auf %s angelegt.\n'  "$1" "$2" ;;
        err_action_failed:EN) printf '%s\n' "ERROR: Action failed/aborted - back to the menu." ;;
        err_action_failed:*)  printf '%s\n' "FEHLER: Aktion fehlgeschlagen/abgebrochen - zurück zum Menü." ;;
        # ---------- Lage freier Bereiche (gap_lage) ----------
        gap_between:EN) printf 'between partition %s and %s\n'  "$1" "$2" ;;
        gap_between:*) printf 'zwischen Partition %s und %s\n'  "$1" "$2" ;;
        gap_after:EN) printf 'after partition %s\n'  "$1" ;;
        gap_after:*) printf 'nach Partition %s\n'  "$1" ;;
        gap_before:EN) printf 'before partition %s\n'  "$1" ;;
        gap_before:*) printf 'vor Partition %s\n'  "$1" ;;
        gap_empty_disk:EN) printf '%s\n' "on an empty disk" ;;
        gap_empty_disk:*)  printf '%s\n' "auf leerer Platte" ;;
        # ---------- Partitionierer: Übersicht ----------
        part_overview_title:EN) printf 'Overview: %s\n'  "$1" ;;
        part_overview_title:*) printf 'Übersicht: %s\n'  "$1" ;;
        part_err_no_table:EN) printf 'ERROR: No partition table on %s.\n'  "$1" ;;
        part_err_no_table:*) printf 'FEHLER: Keine Partitionstabelle auf %s.\n'  "$1" ;;
        part_info_create_table_hint:EN) printf '%s\n' "Use menu item 2 to create a new table (GPT or MBR)." ;;
        part_info_create_table_hint:*)  printf '%s\n' "Über Menüpunkt 2 eine neue Tabelle anlegen (GPT oder MBR)." ;;
        part_info_table:EN) printf 'Table: %s   sector size: %s B\n'  "$1" "$2" ;;
        part_info_table:*) printf 'Tabelle: %s   Sektorgröße: %s B\n'  "$1" "$2" ;;
        part_line:*) printf '  %s) %s  %s  %s  %s%s%s\n'  "$1" "$2" "$3" "$4" "$5" "$6" "$7" ;;
        part_unknown:EN) printf '%s\n' "unknown" ;;
        part_unknown:*)  printf '%s\n' "unbekannt" ;;
        part_label:EN) printf ' (label: %s)\n'  "$1" ;;
        part_label:*) printf ' (Label: %s)\n'  "$1" ;;
        part_mounted:EN) printf ' [mounted: %s]\n'  "$1" ;;
        part_mounted:*) printf ' [eingehängt: %s]\n'  "$1" ;;
        part_free_areas:EN) printf '%s\n' "  Free areas:" ;;
        part_free_areas:*)  printf '%s\n' "  Freie Bereiche:" ;;
        part_free_line:EN) printf '     %s free – %s\n'  "$1" "$2" ;;
        part_free_line:*) printf '     %s frei – %s\n'  "$1" "$2" ;;
        part_no_free:EN) printf '%s\n' "     (none)" ;;
        part_no_free:*)  printf '%s\n' "     (keine)" ;;
        # ---------- Partitionierer: neue Tabelle ----------
        part_newtable_title:EN) printf 'New partition table: %s\n'  "$1" ;;
        part_newtable_title:*) printf 'Neue Partitionstabelle: %s\n'  "$1" ;;
        part_menu_table_type:EN) printf '%s\n' "Choose partition table" ;;
        part_menu_table_type:*)  printf '%s\n' "Partitionstabelle wählen" ;;
        part_opt_gpt:EN) printf '%s\n' "GPT (modern, for UEFI; any number of partitions)" ;;
        part_opt_gpt:*)  printf '%s\n' "GPT (modern, für UEFI; beliebig viele Partitionen)" ;;
        part_opt_mbr:EN) printf '%s\n' "MBR / msdos (classic, max. 4 primary)" ;;
        part_opt_mbr:*)  printf '%s\n' "MBR / msdos (klassisch, max. 4 primäre)" ;;
        part_err_wipe:EN) printf 'ERROR: WARNING: ALL partitions and data on %s will be deleted!\n'  "$1" ;;
        part_err_wipe:*) printf 'FEHLER: ACHTUNG: ALLE Partitionen und Daten auf %s werden gelöscht!\n'  "$1" ;;
        part_abort_nothing:EN) printf '%s\n' "Aborted - nothing changed." ;;
        part_abort_nothing:*)  printf '%s\n' "Abgebrochen - nichts verändert." ;;
        part_info_wiping:EN) printf '%s\n' "Wiping disk (wipefs)..." ;;
        part_info_wiping:*)  printf '%s\n' "Säubere Platte (wipefs)..." ;;
        part_info_creating_gpt:EN) printf '%s\n' "Creating GPT..." ;;
        part_info_creating_gpt:*)  printf '%s\n' "Lege GPT an..." ;;
        part_err_gpt_failed:EN) printf '%s\n' "ERROR: Could not create GPT - sfdisk reports:" ;;
        part_err_gpt_failed:*)  printf '%s\n' "FEHLER: GPT konnte nicht angelegt werden - sfdisk meldet:" ;;
        part_info_creating_mbr:EN) printf '%s\n' "Creating MBR (dos)..." ;;
        part_info_creating_mbr:*)  printf '%s\n' "Lege MBR (dos) an..." ;;
        part_err_mbr_failed:EN) printf '%s\n' "ERROR: Could not create MBR - sfdisk reports:" ;;
        part_err_mbr_failed:*)  printf '%s\n' "FEHLER: MBR konnte nicht angelegt werden - sfdisk meldet:" ;;
        part_info_table_done:EN) printf '%s\n' "New partition table is in place." ;;
        part_info_table_done:*)  printf '%s\n' "Neue Partitionstabelle steht." ;;
        # ---------- Partitionierer: Partition erstellen ----------
        part_create_title:EN) printf 'Create partition: %s\n'  "$1" ;;
        part_create_title:*) printf 'Partition erstellen: %s\n'  "$1" ;;
        part_err_no_table2:EN) printf '%s\n' "ERROR: No partition table - use menu item 2 first (new table)." ;;
        part_err_no_table2:*)  printf '%s\n' "FEHLER: Keine Partitionstabelle - zuerst Menüpunkt 2 (neue Tabelle)." ;;
        part_purpose_linux_data:EN) printf '%s\n' "Linux data partition (ext4)" ;;
        part_purpose_linux_data:*)  printf '%s\n' "Linux-Datenpartition (ext4)" ;;
        part_purpose_esp:EN) printf '%s\n' "EFI system partition (FAT32, ESP, 512 MiB)" ;;
        part_purpose_esp:*)  printf '%s\n' "EFI-Systempartition (FAT32, ESP, 512 MiB)" ;;
        part_purpose_biosboot:EN) printf '%s\n' "BIOS boot partition (2 MiB, for GRUB in BIOS mode)" ;;
        part_purpose_biosboot:*)  printf '%s\n' "BIOS-Boot-Partition (2 MiB, für GRUB im BIOS-Modus)" ;;
        part_purpose_extended:EN) printf '%s\n' "Extended partition (container for logical)" ;;
        part_purpose_extended:*)  printf '%s\n' "Erweiterte Partition (Container für logische)" ;;
        part_purpose_swap:*)  printf '%s\n' "Swap" ;;
        part_purpose_ntfs:EN) printf '%s\n' "NTFS (Windows compatible)" ;;
        part_purpose_ntfs:*)  printf '%s\n' "NTFS (Windows-kompatibel)" ;;
        part_purpose_fat32:EN) printf '%s\n' "FAT32 (data)" ;;
        part_purpose_fat32:*)  printf '%s\n' "FAT32 (Daten)" ;;
        part_purpose_raw:EN) printf '%s\n' "No filesystem (raw)" ;;
        part_purpose_raw:*)  printf '%s\n' "Ohne Dateisystem (roh)" ;;
        part_menu_purpose:EN) printf '%s\n' "Purpose of the new partition" ;;
        part_menu_purpose:*)  printf '%s\n' "Zweck der neuen Partition" ;;
        part_err_no_free:EN) printf 'ERROR: No free area on %s.\n'  "$1" ;;
        part_err_no_free:*) printf 'FEHLER: Kein freier Bereich auf %s.\n'  "$1" ;;
        part_warn_multiple_gaps:EN) printf '%s\n' "Warning: Multiple free areas - automatically using the largest." ;;
        part_warn_multiple_gaps:*)  printf '%s\n' "Warnung: Mehrere freie Bereiche - verwende automatisch den größten." ;;
        part_info_free_auto:EN) printf 'Free area (automatic): %s – %s\n'  "$1" "$2" ;;
        part_info_free_auto:*) printf 'Freier Bereich (automatisch): %s – %s\n'  "$1" "$2" ;;
        part_err_gap_too_small:EN) printf '%s\n' "ERROR: Free area too small - a 1 MiB reserve always stays free,
so at least 2 MiB (1 MiB partition + 1 MiB reserve) must be free." ;;
        part_err_gap_too_small:*)  printf '%s\n' "FEHLER: Freier Bereich zu klein - es bleiben immer 1 MiB Reserve frei,
daher müssen mindestens 2 MiB (1 MiB Partition + 1 MiB Reserve) frei sein." ;;
        part_q_size:EN) printf 'Size in MiB/GiB (empty = automatic, max. %s)\n'  "$1" ;;
        part_q_size:*) printf 'Größe in MiB/GiB (leer = automatisch, max. %s)\n'  "$1" ;;
        part_err_bad_size:EN) printf '%s\n' "ERROR: Invalid input - e.g. 512, 20G or 1.5T." ;;
        part_err_bad_size:*)  printf '%s\n' "FEHLER: Ungültige Angabe - z. B. 512, 20G oder 1.5T." ;;
        part_err_size_too_big:EN) printf '%s\n' "ERROR: Size does not fit - at least 1 MiB always stays free
(max. %s in this area)." "$1" ;;
        part_err_size_too_big:*)  printf '%s\n' "FEHLER: Größe passt nicht - es bleiben immer mindestens 1 MiB frei
(max. %s in diesem Bereich)." "$1" ;;
        part_err_mbr_slots:EN) printf '%s\n' "ERROR: MBR: all 4 primary slots used and no extended partition present.
Create an 'Extended partition' first, then create logical partitions inside it." ;;
        part_err_mbr_slots:*)  printf '%s\n' "FEHLER: MBR: alle 4 primären Slots belegt und keine erweiterte Partition vorhanden.
Zuerst eine 'Erweiterte Partition' anlegen, dann logische Partitionen darin erstellen." ;;
        part_info_creating_part:EN) printf 'Creating partition: %s\n'  "$1" ;;
        part_info_creating_part:*) printf 'Lege Partition an: %s\n'  "$1" ;;
        part_err_sfdisk_failed:EN) printf '%s\n' "ERROR: sfdisk could not create the partition - sfdisk reports:" ;;
        part_err_sfdisk_failed:*)  printf '%s\n' "FEHLER: sfdisk konnte die Partition nicht anlegen - sfdisk meldet:" ;;
        part_warn_sfdisk_anyway:EN) printf '%s\n' "Warning: sfdisk reported an error; the partition is on the disk, though. sfdisk reports:" ;;
        part_warn_sfdisk_anyway:*)  printf '%s\n' "Warnung: sfdisk meldete einen Fehler; die Partition liegt aber auf der Platte. sfdisk meldet:" ;;
        part_err_new_nr:EN) printf '%s\n' "ERROR: Could not determine the new partition number." ;;
        part_err_new_nr:*)  printf '%s\n' "FEHLER: Neue Partitionsnummer konnte nicht ermittelt werden." ;;
        part_warn_devnode:EN) printf 'Warning: Device node %s has not appeared yet (udev needs a moment).\n'  "$1" ;;
        part_warn_devnode:*) printf 'Warnung: Gerätedatei %s ist noch nicht erschienen (udev braucht momentan).\n'  "$1" ;;
        part_info_new_part:EN) printf 'Newly created: %s\n'  "$1" ;;
        part_info_new_part:*) printf 'Neu angelegt: %s\n'  "$1" ;;
        part_q_format_now:EN) printf 'Format with %s now?\n'  "$1" ;;
        part_q_format_now:*) printf 'Jetzt mit %s formatieren?\n'  "$1" ;;
        # ---------- Partitionierer: löschen/formatieren/Typ/Boot-Flag ----------
        part_delete_title:EN) printf 'Delete partition: %s\n'  "$1" ;;
        part_delete_title:*) printf 'Partition löschen: %s\n'  "$1" ;;
        part_info_no_parts:EN) printf '%s\n' "No partitions present." ;;
        part_info_no_parts:*)  printf '%s\n' "Keine Partitionen vorhanden." ;;
        part_opt_mounted_ro:EN) printf '%s  (MOUNTED - delete protected)\n'  "$1" ;;
        part_opt_mounted_ro:*) printf '%s  (EINGEHÄNGT - löschgeschützt)\n'  "$1" ;;
        part_menu_delete:EN) printf '%s\n' "Partition to delete" ;;
        part_menu_delete:*)  printf '%s\n' "Zu löschende Partition" ;;
        part_err_mounted_delete:EN) printf 'ERROR: %s is mounted and cannot be deleted.\n'  "$1" ;;
        part_err_mounted_delete:*) printf 'FEHLER: %s ist eingehängt und kann nicht gelöscht werden.\n'  "$1" ;;
        part_err_deleting:EN) printf 'ERROR: Partition %s will be DELETED - all data on it will be irretrievably lost!\n'  "$1" ;;
        part_err_deleting:*) printf 'FEHLER: Partition %s wird GELÖSCHT - alle Daten darauf sind unwiederbringlich verloren!\n'  "$1" ;;
        part_info_deleted:EN) printf '%s\n' "Partition deleted." ;;
        part_info_deleted:*)  printf '%s\n' "Partition gelöscht." ;;
        part_err_delete_failed:EN) printf '%s\n' "Deletion failed." ;;
        part_err_delete_failed:*)  printf '%s\n' "Löschen fehlgeschlagen." ;;
        part_format_title:EN) printf 'Format partition: %s\n'  "$1" ;;
        part_format_title:*) printf 'Partition formatieren: %s\n'  "$1" ;;
        part_info_no_formatable:EN) printf '%s\n' "No formattable partitions." ;;
        part_info_no_formatable:*)  printf '%s\n' "Keine formatierbaren Partitionen." ;;
        part_menu_format:EN) printf '%s\n' "Partition to format" ;;
        part_menu_format:*)  printf '%s\n' "Zu formatierende Partition" ;;
        part_err_mounted:EN) printf 'ERROR: %s is mounted.\n'  "$1" ;;
        part_err_mounted:*) printf 'FEHLER: %s ist eingehängt.\n'  "$1" ;;
        part_menu_fs:EN) printf '%s\n' "Filesystem" ;;
        part_menu_fs:*)  printf '%s\n' "Dateisystem" ;;
        part_err_formatting:EN) printf 'ERROR: %s will be formatted as %s - ALL data on it will be lost!\n'  "$1" "$2" ;;
        part_err_formatting:*) printf 'FEHLER: %s wird mit %s formatiert - ALLE Daten darauf gehen verloren!\n'  "$1" "$2" ;;
        part_settype_title:EN) printf 'Set partition type: %s\n'  "$1" ;;
        part_settype_title:*) printf 'Partitionstyp setzen: %s\n'  "$1" ;;
        part_opt_current:EN) printf '%s  current: %s\n'  "$1" "$2" ;;
        part_opt_current:*) printf '%s  aktuell: %s\n'  "$1" "$2" ;;
        part_menu_partition:*)  printf '%s\n' "Partition" ;;
        part_menu_type_gpt:EN) printf '%s\n' "New type (GPT)" ;;
        part_menu_type_gpt:*)  printf '%s\n' "Neuer Typ (GPT)" ;;
        part_type_gpt_esp:EN) printf '%s\n' "EFI system partition (ESP)" ;;
        part_type_gpt_esp:*)  printf '%s\n' "EFI-Systempartition (ESP)" ;;
        part_type_gpt_bios:EN) printf '%s\n' "BIOS boot partition (GRUB in BIOS mode)" ;;
        part_type_gpt_bios:*)  printf '%s\n' "BIOS-Boot-Partition (GRUB im BIOS-Modus)" ;;
        part_type_gpt_linux:EN) printf '%s\n' "Linux filesystem" ;;
        part_type_gpt_linux:*)  printf '%s\n' "Linux-Dateisystem" ;;
        part_type_gpt_swap:*)  printf '%s\n' "Linux-Swap" ;;
        part_type_gpt_msdata:*)  printf '%s\n' "Microsoft Basic Data (Windows/NTFS)" ;;
        part_type_gpt_lvm:*)  printf '%s\n' "Linux-LVM" ;;
        part_menu_type_mbr:EN) printf '%s\n' "New type (MBR)" ;;
        part_menu_type_mbr:*)  printf '%s\n' "Neuer Typ (MBR)" ;;
        part_type_mbr_linux:*)  printf '%s\n' "Linux (83)" ;;
        part_type_mbr_efi:*)  printf '%s\n' "EFI-System (ef)" ;;
        part_type_mbr_fat32:*)  printf '%s\n' "FAT32 LBA (0c)" ;;
        part_type_mbr_swap:*)  printf '%s\n' "Swap (82)" ;;
        part_type_mbr_ntfs:*)  printf '%s\n' "NTFS/HPFS (07)" ;;
        part_type_mbr_ext:EN) printf '%s\n' "Extended (05)" ;;
        part_type_mbr_ext:*)  printf '%s\n' "Erweitert (05)" ;;
        part_info_type_set:EN) printf 'Type set: %s on %s\n'  "$1" "$2" ;;
        part_info_type_set:*) printf 'Typ gesetzt: %s auf %s\n'  "$1" "$2" ;;
        part_err_type_failed:EN) printf '%s\n' "ERROR: Could not set the type." ;;
        part_err_type_failed:*)  printf '%s\n' "FEHLER: Typ konnte nicht gesetzt werden." ;;
        part_err_bootflag_gpt:EN) printf '%s\n' "ERROR: Boot flag only exists on MBR tables (GPT: use the ESP partition type)." ;;
        part_err_bootflag_gpt:*)  printf '%s\n' "FEHLER: Boot-Flag gibt es nur bei MBR-Tabellen (GPT: Partitionstyp ESP verwenden)." ;;
        part_bootflag_title:EN) printf 'Set boot flag (MBR): %s\n'  "$1" ;;
        part_bootflag_title:*) printf 'Boot-Flag setzen (MBR): %s\n'  "$1" ;;
        part_menu_bootflag:EN) printf '%s\n' "Partition (gets the boot flag, all others lose it)" ;;
        part_menu_bootflag:*)  printf '%s\n' "Partition (erhält Boot-Flag, alle anderen verlieren es)" ;;
        part_info_bootflag_set:EN) printf 'Boot flag set on %s\n'  "$1" ;;
        part_info_bootflag_set:*) printf 'Boot-Flag gesetzt auf %s\n'  "$1" ;;
        part_err_bootflag_failed:EN) printf '%s\n' "ERROR: Could not set the boot flag." ;;
        part_err_bootflag_failed:*)  printf '%s\n' "FEHLER: Boot-Flag konnte nicht gesetzt werden." ;;
        # ---------- Partitionierer: Werkzeuge/Menü ----------
        part_context:EN) printf '%s\n' "partitioner" ;;
        part_context:*)  printf '%s\n' "Partitionierer" ;;
        part_tool_pkg:EN) printf '%s (package %s) \n'  "$1" "$2" ;;
        part_tool_pkg:*) printf '%s (Paket %s) \n'  "$1" "$2" ;;
        part_err_missing_tools:EN) printf 'ERROR: Tools missing for the partitioner: %s\n'  "$1" ;;
        part_err_missing_tools:*) printf 'FEHLER: Für den Partitionierer fehlen Werkzeuge: %s\n'  "$1" ;;
        part_err_needs_tools:EN) printf 'ERROR: The partitioner requires: %s\n'  "$1" ;;
        part_err_needs_tools:*) printf 'FEHLER: Der Partitionierer braucht: %s\n'  "$1" ;;
        part_menu_title:EN) printf '%s\n' "Partitioner - disk selection" ;;
        part_menu_title:*)  printf '%s\n' "Partitionierer - Plattenauswahl" ;;
        part_no_table:EN) printf '%s\n' "no table" ;;
        part_no_table:*)  printf '%s\n' "keine Tabelle" ;;
        part_opt_disk:*) printf '%s  %s  %s  (%s)\n'  "$1" "$2" "$3" "$4" ;;
        part_err_no_disk:EN) printf '%s\n' "ERROR: No suitable disk found." ;;
        part_err_no_disk:*)  printf '%s\n' "FEHLER: Keine passende Festplatte gefunden." ;;
        part_menu_select_disk:EN) printf '%s\n' "Choose disk" ;;
        part_menu_select_disk:*)  printf '%s\n' "Festplatte wählen" ;;
        part_warn_live_excluded:EN) printf 'Live medium %s is excluded from the selection.\n'  "$1" ;;
        part_warn_live_excluded:*) printf 'Live-Medium %s ist von der Auswahl ausgeschlossen.\n'  "$1" ;;
        part_menu_main_title:EN) printf 'Partition: %s\n'  "$1" ;;
        part_menu_main_title:*) printf 'Partitionieren: %s\n'  "$1" ;;
        part_menu_opt_overview:EN) printf '%s\n' "Show overview (partitions + free areas)" ;;
        part_menu_opt_overview:*)  printf '%s\n' "Übersicht anzeigen (Partitionen + freie Bereiche)" ;;
        part_menu_opt_newtable:EN) printf '%s\n' "Create new partition table (DELETES EVERYTHING on the disk)" ;;
        part_menu_opt_newtable:*)  printf '%s\n' "Neue Partitionstabelle anlegen (LÖSCHT ALLES auf der Platte)" ;;
        part_menu_opt_create:EN) printf '%s\n' "Create partition" ;;
        part_menu_opt_create:*)  printf '%s\n' "Partition erstellen" ;;
        part_menu_opt_delete:EN) printf '%s\n' "Delete partition" ;;
        part_menu_opt_delete:*)  printf '%s\n' "Partition löschen" ;;
        part_menu_opt_format:EN) printf '%s\n' "Format partition (ext4/FAT32/swap/NTFS)" ;;
        part_menu_opt_format:*)  printf '%s\n' "Partition formatieren (ext4/FAT32/swap/NTFS)" ;;
        part_menu_opt_settype:EN) printf '%s\n' "Set partition type (ESP, BIOS boot, swap ...)" ;;
        part_menu_opt_settype:*)  printf '%s\n' "Partitionstyp setzen (ESP, BIOS-Boot, Swap ...)" ;;
        part_menu_opt_bootflag:EN) printf '%s\n' "Set boot flag (MBR only)" ;;
        part_menu_opt_bootflag:*)  printf '%s\n' "Boot-Flag setzen (nur MBR)" ;;
        # ---------- Installer: Zielwahl ----------
        install_descr_disk:EN) printf '%s - WHOLE DISK - %s %s [will be repartitioned]\n'  "$1" "$2" "$3" ;;
        install_descr_disk:*) printf '%s - GANZE PLATTE - %s %s [wird neu partitioniert]\n'  "$1" "$2" "$3" ;;
        install_descr_extended:EN) printf '  %s - extended partition (skipped)\n'  "$1" ;;
        install_descr_extended:*) printf '  %s - erweiterte Partition (übersprungen)\n'  "$1" ;;
        install_raw:EN) printf '%s\n' "raw" ;;
        install_raw:*)  printf '%s\n' "roh" ;;
        install_descr_part:EN) printf '  %s - partition - %s - %s - %s%s\n'  "$1" "$2" "$3" "$4" "$5" ;;
        install_descr_part:*) printf '  %s - Partition - %s - %s - %s%s\n'  "$1" "$2" "$3" "$4" "$5" ;;
        install_targets_title:EN) printf '%s\n' "Possible installation targets" ;;
        install_targets_title:*)  printf '%s\n' "Mögliche Installationsziele" ;;
        install_info_live_excluded:EN) printf 'The live medium %s and its partitions are excluded.\n'  "$1" ;;
        install_info_live_excluded:*) printf 'Das Live-Medium %s und seine Partitionen sind ausgeschlossen.\n'  "$1" ;;
        install_err_no_targets:EN) printf '%s\n' "No suitable targets found." ;;
        install_err_no_targets:*)  printf '%s\n' "Keine geeigneten Ziele gefunden." ;;
        install_menu_choose_target:EN) printf '%s\n' "Choose installation target" ;;
        install_menu_choose_target:*)  printf '%s\n' "Installationsziel wählen" ;;
        # ---------- Installer: Ablauf ----------
        install_title:EN) printf '%s\n' "ArchLive installer - installs the booted live system" ;;
        install_title:*)  printf '%s\n' "ArchLive-Installer - installiert das gebootete Live-System" ;;
        install_err_not_block:EN) printf 'ERROR: Not a block device: %s\n'  "$1" ;;
        install_err_not_block:*) printf 'FEHLER: Kein Blockgerät: %s\n'  "$1" ;;
        install_err_parent:EN) printf "ERROR: Could not determine the parent disk of '%s'.\n"  "$1" ;;
        install_err_parent:*) printf "FEHLER: Übergeordnete Festplatte von '%s' konnte nicht ermittelt werden.\n"  "$1" ;;
        install_err_extended:EN) printf "ERROR: An extended partition ('%s') cannot be an installation target.\n"  "$1" ;;
        install_err_extended:*) printf "FEHLER: Eine erweiterte Partition ('%s') kann kein Installationsziel sein.\n"  "$1" ;;
        install_err_neither:EN) printf "ERROR: '%s' is neither a whole disk nor a partition.\n"  "$1" ;;
        install_err_neither:*) printf "FEHLER: '%s' ist weder eine komplette Festplatte noch eine Partition.\n"  "$1" ;;
        install_err_unsuitable:EN) printf "ERROR: '%s' is not a suitable installation target.\n"  "$1" ;;
        install_err_unsuitable:*) printf "FEHLER: '%s' ist kein geeignetes Installationsziel.\n"  "$1" ;;
        install_err_arch:EN) printf 'ERROR: Only x86_64 is supported (found: %s).\n'  "$1" ;;
        install_err_arch:*) printf 'FEHLER: Nur x86_64 wird unterstützt (gefunden: %s).\n'  "$1" ;;
        install_err_no_archiso:EN) printf '%s\n' "ERROR: No archiso live system detected (/run/archiso missing) -
is the script running inside the booted live system?" ;;
        install_err_no_archiso:*)  printf '%s\n' "FEHLER: Kein archiso-Live-System erkannt (/run/archiso fehlt) -
läuft das Script im gebooteten Live-System?" ;;
        install_err_no_squash:EN) printf '%s\n' "ERROR: No archiso squashfs found - diagnostics:" ;;
        install_err_no_squash:*)  printf '%s\n' "FEHLER: Kein archiso-SquashFS gefunden - Diagnose:" ;;
        install_info_cmdline:*)  printf '%s\n' "Kernel command line:" ;;
        install_info_files:EN) printf '%s\n' "Files under /run/archiso:" ;;
        install_info_files:*)  printf '%s\n' "Dateien unter /run/archiso:" ;;
        install_err_no_airootfs:EN) printf '%s\n' "ERROR: No archiso live system detected (airootfs.sfs missing).
Please start this program inside the booted live ISO." ;;
        install_err_no_airootfs:*)  printf '%s\n' "FEHLER: Kein archiso-Live-System erkannt (airootfs.sfs fehlt).
Bitte dieses Programm innerhalb der gebooteten Live-ISO starten." ;;
        install_info_squash:*) printf 'SquashFS:    %s\n'  "$1" ;;
        install_err_live_disk:EN) printf "ERROR: '%s' is on the live medium the system was booted from!\n"  "$1" ;;
        install_err_live_disk:*) printf "FEHLER: '%s' liegt auf dem Live-Medium, von dem gerade gebootet wurde!\n"  "$1" ;;
        install_info_target:EN) printf 'Target:      %s\n'  "$1" ;;
        install_info_target:*) printf 'Ziel:        %s\n'  "$1" ;;
        install_info_mode_part:EN) printf 'Mode:        Partition (disk: %s, no repartitioning)\n'  "$1" ;;
        install_info_mode_part:*) printf 'Modus:       Partition (Platte: %s, keine Neupartitionierung)\n'  "$1" ;;
        install_info_mode_disk:EN) printf '%s\n' "Mode:        Entire disk (will be repartitioned)" ;;
        install_info_mode_disk:*)  printf '%s\n' "Modus:       Gesamte Festplatte (wird neu partitioniert)" ;;
        install_info_firmware:*) printf 'Firmware:    %s\n'  "$1" ;;
        install_info_arch:EN) printf 'Architecture: %s\n'  "$1" ;;
        install_info_arch:*) printf 'Architektur: %s\n'  "$1" ;;
        install_not_detected:EN) printf '%s\n' "NOT DETECTED" ;;
        install_not_detected:*)  printf '%s\n' "NICHT ERKANNT" ;;
        install_info_live:EN) printf 'Live medium: %s\n'  "$1" ;;
        install_info_live:*) printf 'Live-Medium: %s\n'  "$1" ;;
        install_warn_live_unknown:EN) printf '%s\n' "Warning: The live medium could not be determined automatically." ;;
        install_warn_live_unknown:*)  printf '%s\n' "Warnung: Das Live-Medium konnte nicht automatisch bestimmt werden." ;;
        install_err_mounted:EN) printf "ERROR: There are still filesystems mounted on '%s'.\n"  "$1" ;;
        install_err_mounted:*) printf "FEHLER: Auf '%s' sind noch Dateisysteme eingehängt.\n"  "$1" ;;
        install_err_too_small:EN) printf 'ERROR: Target too small: %s MB. At least 8 GB.\n'  "$1" ;;
        install_err_too_small:*) printf 'FEHLER: Ziel zu klein: %s MB. Mindestens 8 GB.\n'  "$1" ;;
        install_info_size:EN) printf 'Size:        %s MB\n'  "$1" ;;
        install_info_size:*) printf 'Größe:       %s MB\n'  "$1" ;;
        install_info_model:EN) printf 'Model:       %s\n'  "$1" ;;
        install_info_model:*) printf 'Modell:      %s\n'  "$1" ;;
        install_head_all_data:EN) printf 'WARNING - ALL DATA ON %s WILL BE DELETED!\n'  "$1" ;;
        install_head_all_data:*) printf 'ACHTUNG - ALLE DATEN AUF %s WERDEN GELÖSCHT!\n'  "$1" ;;
        install_info_missing_tools:EN) printf '%s\n' "Missing tools - installing packages (network required):" ;;
        install_info_missing_tools:*)  printf '%s\n' "Fehlende Werkzeuge - installiere Pakete (Netzwerk nötig):" ;;
        install_err_pkg_fail:EN) printf '%s\n' "ERROR: Packages could not be installed (network? pacman -Syu run?)" ;;
        install_err_pkg_fail:*)  printf '%s\n' "FEHLER: Pakete konnten nicht installiert werden (Netzwerk? pacman -Syu ausgeführt?)" ;;
        install_err_pkg_still:EN) printf "ERROR: Package for '%s' is still missing.\n"  "$1" ;;
        install_err_pkg_still:*) printf "FEHLER: Paket für '%s' fehlt weiterhin.\n"  "$1" ;;
        install_err_mkvfat_still:EN) printf '%s\n' "ERROR: mkfs.vfat is still missing (package dosfstools)." ;;
        install_err_mkvfat_still:*)  printf '%s\n' "FEHLER: mkfs.vfat fehlt weiterhin (Paket dosfstools)." ;;
        install_err_grub_bios:EN) printf '%s\n' "ERROR: grub modules for BIOS (i386-pc) are missing in the live system.
Run 'sudo pacman -S grub' on the source machine and rebuild the ISO." ;;
        install_err_grub_bios:*)  printf '%s\n' "FEHLER: grub-Module für BIOS (i386-pc) fehlen im Live-System.
Auf dem Quellrechner 'sudo pacman -S grub' ausführen und die ISO neu bauen." ;;
        install_err_grub_uefi:EN) printf '%s\n' "ERROR: grub modules for UEFI (x86_64-efi) are missing in the live system.
Run 'sudo pacman -S grub' on the source machine and rebuild the ISO." ;;
        install_err_grub_uefi:*)  printf '%s\n' "FEHLER: grub-Module für UEFI (x86_64-efi) fehlen im Live-System.
Auf dem Quellrechner 'sudo pacman -S grub' ausführen und die ISO neu bauen." ;;
        install_err_no_kernel:EN) printf '%s\n' "ERROR: No kernel found (neither in the live system nor on the medium)." ;;
        install_err_no_kernel:*)  printf '%s\n' "FEHLER: Kein Kernel gefunden (weder im Live-System noch auf dem Medium)." ;;
        install_info_kernel_src:EN) printf 'Kernel source: %s\n'  "$1" ;;
        install_info_kernel_src:*) printf 'Kernel-Quelle: %s\n'  "$1" ;;
        install_info_kpkg:EN) printf 'Kernel package: %s\n'  "$1" ;;
        install_info_kpkg:*) printf 'Kernel-Paket: %s\n'  "$1" ;;
        install_info_partmode_l1:EN) printf '%s\n' "Target is a single partition - the partition table" ;;
        install_info_partmode_l1:*)  printf '%s\n' "Ziel ist eine einzelne Partition - die Partitionstabelle" ;;
        install_info_partmode_l2:EN) printf 'of %s will NOT be changed.\n'  "$1" ;;
        install_info_partmode_l2:*) printf 'von %s wird NICHT verändert.\n'  "$1" ;;
        install_info_partitioning:EN) printf 'Partitioning %s (%s) - all data will be deleted...\n'  "$1" "$2" ;;
        install_info_partitioning:*) printf 'Partitioniere %s (%s) - alle Daten werden gelöscht...\n'  "$1" "$2" ;;
        install_info_gpt_auto:EN) printf '%s\n' "Creating GPT with 512-MiB EFI + root (sfdisk)..." ;;
        install_info_gpt_auto:*)  printf '%s\n' "Erstelle GPT mit 512-MiB-EFI + Root (sfdisk)..." ;;
        install_err_part_gpt:EN) printf '%s\n' "ERROR: Partitioning (GPT) failed." ;;
        install_err_part_gpt:*)  printf '%s\n' "FEHLER: Partitionierung (GPT) fehlgeschlagen." ;;
        install_info_mbr_auto:EN) printf '%s\n' "Creating MBR with one bootable root partition (sfdisk)..." ;;
        install_info_mbr_auto:*)  printf '%s\n' "Erstelle MBR mit einer bootbaren Root-Partition (sfdisk)..." ;;
        install_err_part_mbr:EN) printf '%s\n' "ERROR: Partitioning (MBR) failed." ;;
        install_err_part_mbr:*)  printf '%s\n' "FEHLER: Partitionierung (MBR) fehlgeschlagen." ;;
        install_err_p_missing:EN) printf 'ERROR: Partition %s was not found.\n'  "$1" ;;
        install_err_p_missing:*) printf 'FEHLER: Partition %s wurde nicht gefunden.\n'  "$1" ;;
        install_info_partitions:EN) printf '%s\n' "Partitions:" ;;
        install_info_partitions:*)  printf '%s\n' "Partitionen:" ;;
        install_info_formatting:EN) printf '%s\n' "Formatting..." ;;
        install_info_formatting:*)  printf '%s\n' "Formatiere..." ;;
        install_info_formatting_part:EN) printf 'Formatting %s (ext4) - all data on this partition will be deleted...\n'  "$1" ;;
        install_info_formatting_part:*) printf 'Formatiere %s (ext4) - alle Daten auf dieser Partition werden gelöscht...\n'  "$1" ;;
        install_info_swap_off:EN) printf '%s\n' "Partition is active as swap - switching it off..." ;;
        install_info_swap_off:*)  printf '%s\n' "Partition ist als Swap aktiv - schalte sie aus..." ;;
        install_err_swap_off:EN) printf 'ERROR: %s is active as swap and could not be switched off.\n'  "$1" ;;
        install_err_swap_off:*) printf 'FEHLER: %s ist als Swap aktiv und konnte nicht ausgeschaltet werden.\n'  "$1" ;;
        install_err_format_target:EN) printf '%s\n' "ERROR: Target partition could not be formatted." ;;
        install_err_format_target:*)  printf '%s\n' "FEHLER: Ziel-Partition konnte nicht formatiert werden." ;;
        install_info_search_esp:EN) printf 'Looking for an EFI system partition on %s...\n'  "$1" ;;
        install_info_search_esp:*) printf 'Suche EFI-Systempartition auf %s...\n'  "$1" ;;
        install_err_no_esp:EN) printf '%s\n' "ERROR: UEFI mode: no EFI system partition (ESP) found on
%s.

Please create an ESP with the partitioner ('$SCRIPT_NAME part')
(e.g. 512 MiB, FAT32, type 'EFI System')." "$1" ;;
        install_err_no_esp:*)  printf '%s\n' "FEHLER: UEFI-Modus: Es wurde keine EFI-Systempartition (ESP) auf
%s gefunden.

Bitte über den Partitionierer ('$SCRIPT_NAME part') eine ESP anlegen
(z. B. 512 MiB, FAT32, Typ 'EFI System')." "$1" ;;
        install_info_esp_unformatted:EN) printf 'ESP %s is unformatted - creating FAT32...\n'  "$1" ;;
        install_info_esp_unformatted:*) printf 'ESP %s ist unformatiert - lege FAT32 an...\n'  "$1" ;;
        install_err_esp_format:EN) printf '%s\n' "ERROR: ESP could not be formatted." ;;
        install_err_esp_format:*)  printf '%s\n' "FEHLER: ESP konnte nicht formatiert werden." ;;
        install_err_esp_fstype:EN) printf "ERROR: %s is marked as ESP but contains '%s' instead of vfat.\n"  "$1" "$2" ;;
        install_err_esp_fstype:*) printf "FEHLER: %s ist als ESP markiert, enthält aber '%s' statt vfat.\n"  "$1" "$2" ;;
        install_err_no_biosboot:EN) printf '%s\n' "ERROR: BIOS mode with GPT partition table: %s lacks a
BIOS boot partition (1-2 MiB, type 'BIOS boot').

Please create one with the partitioner or use an MBR table." "$1" ;;
        install_err_no_biosboot:*)  printf '%s\n' "FEHLER: BIOS-Modus mit GPT-Partitionstabelle: Auf %s fehlt
eine BIOS-Boot-Partition (1-2 MiB, Typ 'BIOS boot').

Bitte über den Partitionierer anlegen oder eine MBR-Tabelle verwenden." "$1" ;;
        install_err_esp_format2:EN) printf '%s\n' "ERROR: EFI system partition could not be formatted." ;;
        install_err_esp_format2:*)  printf '%s\n' "FEHLER: EFI-Systempartition konnte nicht formatiert werden." ;;
        install_err_root_format:EN) printf '%s\n' "ERROR: Root partition could not be formatted." ;;
        install_err_root_format:*)  printf '%s\n' "FEHLER: Root-Partition konnte nicht formatiert werden." ;;
        install_err_root_uuid:EN) printf '%s\n' "ERROR: Could not determine the UUID of the root partition." ;;
        install_err_root_uuid:*)  printf '%s\n' "FEHLER: UUID der Root-Partition konnte nicht ermittelt werden." ;;
        install_info_root_uuid:*) printf 'Root UUID: %s\n'  "$1" ;;
        install_err_esp_uuid:EN) printf '%s\n' "ERROR: Could not determine the UUID of the EFI partition." ;;
        install_err_esp_uuid:*)  printf '%s\n' "FEHLER: UUID der EFI-Partition konnte nicht ermittelt werden." ;;
        install_info_esp_uuid:*) printf 'ESP UUID:  %s\n'  "$1" ;;
        install_info_mounting:EN) printf '%s\n' "Mounting target system..." ;;
        install_info_mounting:*)  printf '%s\n' "Mounte Zielsystem..." ;;
        install_err_mnt_mounted:EN) printf '%s\n' "ERROR: /mnt is already mounted - please reboot the live system." ;;
        install_err_mnt_mounted:*)  printf '%s\n' "FEHLER: /mnt ist bereits eingehängt - bitte Live-System neu starten." ;;
        install_info_clean_mnt:EN) printf '%s\n' "Cleaning up leftovers in /mnt..." ;;
        install_info_clean_mnt:*)  printf '%s\n' "Räume Reste in /mnt weg..." ;;
        install_err_root_mount:EN) printf '%s\n' "ERROR: Root partition could not be mounted." ;;
        install_err_root_mount:*)  printf '%s\n' "FEHLER: Root-Partition konnte nicht gemountet werden." ;;
        install_err_esp_mount:EN) printf '%s\n' "ERROR: EFI partition could not be mounted." ;;
        install_err_esp_mount:*)  printf '%s\n' "FEHLER: EFI-Partition konnte nicht gemountet werden." ;;
        install_info_unpack:EN) printf 'Extracting the live system to %s - depending on the ISO this takes minutes...\n'  "$1" ;;
        install_info_unpack:*) printf 'Entpacke das Live-System nach %s - je nach ISO mehrere Minuten...\n'  "$1" ;;
        install_err_unsquash:EN) printf '%s\n' "ERROR: unsquashfs failed." ;;
        install_err_unsquash:*)  printf '%s\n' "FEHLER: unsquashfs fehlgeschlagen." ;;
        install_info_free_space:EN) printf 'Free space after extraction: %s MB\n'  "$1" ;;
        install_info_free_space:*) printf 'Freier Speicher nach dem Entpacken: %s MB\n'  "$1" ;;
        install_err_low_space:EN) printf '%s\n' "ERROR: Not enough free space on the target partition." ;;
        install_err_low_space:*)  printf '%s\n' "FEHLER: Zu wenig freier Speicher auf der Zielpartition." ;;
        install_info_remove_bootrest:EN) printf '%s\n' "Removing carried-over bootloader remains..." ;;
        install_info_remove_bootrest:*)  printf '%s\n' "Entferne übernommene Bootloader-Reste..." ;;
        install_info_check_kernel:EN) printf '%s\n' "Checking kernel..." ;;
        install_info_check_kernel:*)  printf '%s\n' "Prüfe Kernel..." ;;
        install_err_kernel_copy:EN) printf '%s\n' "ERROR: Kernel could not be copied." ;;
        install_err_kernel_copy:*)  printf '%s\n' "FEHLER: Kernel konnte nicht kopiert werden." ;;
        install_info_kernel_copied:EN) printf 'Kernel copied: %s\n'  "$1" ;;
        install_info_kernel_copied:*) printf 'Kernel kopiert: %s\n'  "$1" ;;
        install_info_kernel:*) printf 'Kernel: %s\n'  "$1" ;;
        install_err_no_mods:EN) printf '%s\n' "ERROR: No kernel modules in the installed system (/usr/lib/modules missing)." ;;
        install_err_no_mods:*)  printf '%s\n' "FEHLER: Keine Kernelmodule im installierten System (/usr/lib/modules fehlt)." ;;
        install_err_no_kver:EN) printf '%s\n' "ERROR: No kernel version found in the installed system." ;;
        install_err_no_kver:*)  printf '%s\n' "FEHLER: Keine Kernel-Version im installierten System gefunden." ;;
        install_info_kver:EN) printf 'Kernel version: %s\n'  "$1" ;;
        install_info_kver:*) printf 'Kernel-Version: %s\n'  "$1" ;;
        install_warn_no_moddir:EN) printf 'Warning: %s does not exist.\n'  "$1" ;;
        install_warn_no_moddir:*) printf 'Warnung: %s existiert nicht.\n'  "$1" ;;
        install_err_no_matching_mods:EN) printf '%s\n' "ERROR: Matching kernel modules were not found." ;;
        install_err_no_matching_mods:*)  printf '%s\n' "FEHLER: Passende Kernelmodule wurden nicht gefunden." ;;
        install_info_fstab:EN) printf '%s\n' "Creating /etc/fstab..." ;;
        install_info_fstab:*)  printf '%s\n' "Erzeuge /etc/fstab..." ;;
        install_info_machineid:EN) printf '%s\n' "Creating new machine-id..." ;;
        install_info_machineid:*)  printf '%s\n' "Erzeuge neue machine-id..." ;;
        install_err_machineid:EN) printf '%s\n' "ERROR: machine-id could not be created." ;;
        install_err_machineid:*)  printf '%s\n' "FEHLER: machine-id konnte nicht erzeugt werden." ;;
        install_warn_bad_hooks:EN) printf 'Warning: Non-existent hooks in the carried-over configuration: %s\n'  "$1" ;;
        install_warn_bad_hooks:*) printf 'Warnung: Nicht vorhandene Hooks in der übernommenen Konfiguration: %s\n'  "$1" ;;
        install_warn_hooks_removed:EN) printf '%s\n' "Warning: They would break the next kernel update on the target system - removing them." ;;
        install_warn_hooks_removed:*)  printf '%s\n' "Warnung: Sie würden den nächsten Kernel-Update auf dem Zielsystem brechen - werden entfernt." ;;
        install_info_build_initramfs:EN) printf '%s\n' "Building initramfs for the installed system..." ;;
        install_info_build_initramfs:*)  printf '%s\n' "Baue Initramfs für das installierte System..." ;;
        install_info_retry_hooks:EN) printf '%s\n' "Retrying with default hooks ..." ;;
        install_info_retry_hooks:*)  printf '%s\n' "Erneuter Versuch mit Standard-Hooks ..." ;;
        install_err_mkinitcpio:EN) printf '%s\n' "ERROR: mkinitcpio failed" ;;
        install_err_mkinitcpio:*)  printf '%s\n' "FEHLER: mkinitcpio fehlgeschlagen" ;;
        install_err_fallback:EN) printf '%s\n' "ERROR: Fallback initramfs failed" ;;
        install_err_fallback:*)  printf '%s\n' "FEHLER: Fallback-Initramfs fehlgeschlagen" ;;
        install_info_grub:EN) printf 'Installing GRUB (%s)...\n'  "$1" ;;
        install_info_grub:*) printf 'Installiere GRUB (%s)...\n'  "$1" ;;
        install_err_grub_bios_fail:EN) printf '%s\n' "ERROR: grub-install BIOS failed." ;;
        install_err_grub_bios_fail:*)  printf '%s\n' "FEHLER: grub-install BIOS fehlgeschlagen." ;;
        install_err_grub_uefi_fail:EN) printf '%s\n' "ERROR: grub-install UEFI failed." ;;
        install_err_grub_uefi_fail:*)  printf '%s\n' "FEHLER: grub-install UEFI fehlgeschlagen." ;;
        install_info_grubcfg:EN) printf '%s\n' "Creating GRUB configuration..." ;;
        install_info_grubcfg:*)  printf '%s\n' "Erzeuge GRUB-Konfiguration..." ;;
        install_err_bootx64:EN) printf '%s\n' "ERROR: BOOTX64.EFI was not created by grub-install" ;;
        install_err_bootx64:*)  printf '%s\n' "FEHLER: BOOTX64.EFI wurde vom grub-install nicht erstellt" ;;
        install_success:EN) printf '%s\n' "INSTALLATION SUCCESSFUL" ;;
        install_success:*)  printf '%s\n' "INSTALLATION ERFOLGREICH" ;;
        install_done_target:EN) printf 'Target:     %s\n'  "$1" ;;
        install_done_target:*) printf 'Ziel:       %s\n'  "$1" ;;
        install_done_firmware:*) printf 'Firmware:   %s\n'  "$1" ;;
        install_done_root:*) printf 'Root:       %s\n'  "$1" ;;
        install_done_root_uuid:*) printf 'Root UUID:  %s\n'  "$1" ;;
        install_done_next:EN) printf '%s\n' "Please now:" ;;
        install_done_next:*)  printf '%s\n' "Bitte jetzt:" ;;
        install_done_step1:EN) printf '%s\n' "  1. Remove the USB stick / live medium" ;;
        install_done_step1:*)  printf '%s\n' "  1. USB-Stick / Live-Medium entfernen" ;;
        install_done_step2:EN) printf '%s\n' "  2. Reboot the machine" ;;
        install_done_step2:*)  printf '%s\n' "  2. Rechner neu starten" ;;
        install_done_step3:EN) printf '%s\n' "  3. Boot from the installed disk" ;;
        install_done_step3:*)  printf '%s\n' "  3. Von der installierten Festplatte booten" ;;
        install_warn_secureboot:EN) printf '%s\n' "Warning: Disable Secure Boot in the UEFI (GRUB is unsigned, just like the live ISO)." ;;
        install_warn_secureboot:*)  printf '%s\n' "Warnung: Secure Boot im UEFI deaktivieren (GRUB ist nicht signiert, wie schon die Live-ISO)." ;;
        install_menu_title:EN) printf '%s\n' "Install live system" ;;
        install_menu_title:*)  printf '%s\n' "Live-System installieren" ;;
        install_menu_main:*)  printf '%s\n' "Installation" ;;
        install_menu_opt_install:EN) printf '%s\n' "Choose target and install" ;;
        install_menu_opt_install:*)  printf '%s\n' "Ziel wählen und installieren" ;;
        install_menu_opt_show:EN) printf '%s\n' "Show possible targets" ;;
        install_menu_opt_show:*)  printf '%s\n' "Mögliche Ziele anzeigen" ;;
        install_menu_opt_partfirst:EN) printf '%s\n' "Partition first (open the partitioner)" ;;
        install_menu_opt_partfirst:*)  printf '%s\n' "Zuerst partitionieren (Partitionierer öffnen)" ;;
        # ---------- ISO-Builder ----------
        iso_kind_workdir:EN) printf '%s\n' "working directory" ;;
        iso_kind_workdir:*)  printf '%s\n' "Arbeitsverzeichnis" ;;
        iso_kind_outdir:EN) printf '%s\n' "output directory" ;;
        iso_kind_outdir:*)  printf '%s\n' "Ausgabeordner" ;;
        iso_err_system_path:EN) printf "ERROR: %s '%s' is in the system/boot area - aborting (data-loss protection).\n"  "$1" "$2" ;;
        iso_err_system_path:*) printf "FEHLER: %s '%s' liegt im System-/Boot-Bereich - abgebrochen (Schutz vor Datenverlust).\n"  "$1" "$2" ;;
        iso_err_fat_path:EN) printf '%s\n' "ERROR: %s '%s' is on a FAT/EFI partition - aborting.
Multi-GB files and boot trees do not belong there - otherwise the
machine's boot files would have been overwritten." "$1" "$2" ;;
        iso_err_fat_path:*)  printf '%s\n' "FEHLER: %s '%s' liegt auf einer FAT/EFI-Partition - abgebrochen.
Dorthin gehören keine mehr-GB-Dateien und keine Boot-Bäume - die
Boot-Dateien des Rechners wären sonst überschrieben worden." "$1" "$2" ;;
        iso_warn_mount_busy:EN) printf "Warning: '%s' is busy. These processes are holding it:\n"  "$1" ;;
        iso_warn_mount_busy:*) printf "Warnung: '%s' blockiert. Diese Prozesse halten es fest:\n"  "$1" ;;
        iso_warn_lazy_umount:EN) printf "Warning: '%s' was unmounted lazily (deferred).\n"  "$1" ;;
        iso_warn_lazy_umount:*) printf "Warnung: '%s' wurde verzögert (lazy) ausgehängt.\n"  "$1" ;;
        iso_err_umount:EN) printf "ERROR: Could not unmount '%s'!\n"  "$1" ;;
        iso_err_umount:*) printf "FEHLER: '%s' konnte nicht ausgehängt werden!\n"  "$1" ;;
        iso_info_cleanup:EN) printf '%s\n' "Cleaning up..." ;;
        iso_info_cleanup:*)  printf '%s\n' "Räume auf..." ;;
        iso_warn_user_missing:EN) printf "Warning: User '%s' not found - owner was not changed.\n"  "$1" ;;
        iso_warn_user_missing:*) printf "Warnung: Benutzer '%s' nicht gefunden - Eigentümer wurde nicht geändert.\n"  "$1" ;;
        iso_info_owner:EN) printf 'Owner of %s: %s\n'  "$1" "$2" ;;
        iso_info_owner:*) printf 'Eigentümer von %s: %s\n'  "$1" "$2" ;;
        iso_err_owner:EN) printf "ERROR: Could not change owner of %s to '%s' - manually: sudo chown -R \"%s:\" \"%s\"\n"  "$1" "$2" "$3" "$4" ;;
        iso_err_owner:*) printf "FEHLER: Eigentümer von %s konnte nicht auf '%s' geändert werden - manuell: sudo chown -R \"%s:\" \"%s\"\n"  "$1" "$2" "$3" "$4" ;;
        iso_err_workdir_invalid:EN) printf "ERROR: Working directory '%s' is invalid.\n"  "$1" ;;
        iso_err_workdir_invalid:*) printf "FEHLER: Arbeitsverzeichnis '%s' ungültig.\n"  "$1" ;;
        iso_cleanup_title:EN) printf 'Cleanup: releasing mounts and removing build artifacts under %s\n'  "$1" ;;
        iso_cleanup_title:*) printf 'Aufräumen: löse Mounts und entferne Build-Artefakte unter %s\n'  "$1" ;;
        iso_err_rm_artifacts:EN) printf '%s\n' "ERROR: Could not delete build artifacts" ;;
        iso_err_rm_artifacts:*)  printf '%s\n' "FEHLER: Build-Artefakte konnten nicht gelöscht werden" ;;
        iso_info_cleanup_done:EN) printf '%s\n' "Done. Working directory emptied (the finished ISO is kept)." ;;
        iso_info_cleanup_done:*)  printf '%s\n' "Fertig. Arbeitsverzeichnis geleert (fertige ISO bleibt erhalten)." ;;
        iso_err_workdir_spaces:EN) printf 'ERROR: The working directory must not contain spaces: %s\n'  "$1" ;;
        iso_err_workdir_spaces:*) printf 'FEHLER: Das Arbeitsverzeichnis darf keine Leerzeichen enthalten: %s\n'  "$1" ;;
        iso_err_mkdir_outdir:EN) printf 'ERROR: Could not create output directory %s\n'  "$1" ;;
        iso_err_mkdir_outdir:*) printf 'FEHLER: Ausgabeordner %s konnte nicht angelegt werden\n'  "$1" ;;
        iso_info_install_pkgs:EN) printf 'Installing missing packages: %s ...\n'  "$1" ;;
        iso_info_install_pkgs:*) printf 'Installiere fehlende Pakete: %s ...\n'  "$1" ;;
        iso_err_pkg_fail:EN) printf '%s\n' "ERROR: Packages could not be installed.
Please run 'sudo pacman -Syu' (full system update) first
and start the build again afterwards." ;;
        iso_err_pkg_fail:*)  printf '%s\n' "FEHLER: Pakete konnten nicht installiert werden.
Bitte zuerst 'sudo pacman -Syu' (vollständiges Systemupdate) ausführen
und den Bau danach erneut starten." ;;
        iso_err_tool_missing:EN) printf 'ERROR: %s not found\n'  "$1" ;;
        iso_err_tool_missing:*) printf 'FEHLER: %s nicht gefunden\n'  "$1" ;;
        iso_err_archiso_hooks:EN) printf '%s\n' "ERROR: archiso hooks missing - please install the 'mkinitcpio-archiso' package" ;;
        iso_err_archiso_hooks:*)  printf '%s\n' "FEHLER: archiso-Hooks fehlen - bitte Paket 'mkinitcpio-archiso' installieren" ;;
        iso_err_low_space:EN) printf '%s\n' "ERROR: Only about %s GB free in %s - not enough!
The build needs at least about 2 GB, sensibly 8+ GB.
Please choose a different working directory (e.g. an external disk)." "$1" "$2" ;;
        iso_err_low_space:*)  printf '%s\n' "FEHLER: Nur ca. %s GB frei in %s - zu wenig!
Für den Bau werden mindestens ca. 2 GB, sinnvoll 8+ GB gebraucht.
Bitte ein anderes Arbeitsverzeichnis wählen (z. B. externe Festplatte)." "$1" "$2" ;;
        iso_warn_low_space:EN) printf 'Warning: Only about %s GB free in %s - roughly 8 GB recommended.\n'  "$1" "$2" ;;
        iso_warn_low_space:*) printf 'Warnung: Nur ca. %s GB frei in %s - grob 8 GB empfohlen.\n'  "$1" "$2" ;;
        iso_err_overlay:EN) printf '%s\n' "ERROR: Kernel module 'overlay' is not available!
Running kernel: %s
This usually happens when the kernel was updated but NOT yet rebooted -
the modules of the running kernel are then missing in /usr/lib/modules.
-> Please REBOOT once and run the builder again." "$1" ;;
        iso_err_overlay:*)  printf '%s\n' "FEHLER: Kernelmodul 'overlay' ist nicht verfügbar!
Laufender Kernel: %s
Das passiert meist, wenn der Kernel aktualisiert, aber noch NICHT neu gestartet
wurde - die Module des laufenden Kernels fehlen dann in /usr/lib/modules.
-> Bitte einmal NEU STARTEN und den Builder erneut ausführen." "$1" ;;
        iso_err_label_empty:EN) printf '%s\n' "ERROR: Volume label is empty" ;;
        iso_err_label_empty:*)  printf '%s\n' "FEHLER: Volume-Label ist leer" ;;
        iso_err_label_long:EN) printf 'ERROR: Volume label too long (max. 32 characters): %s\n'  "$1" ;;
        iso_err_label_long:*) printf 'FEHLER: Volume-Label zu lang (max. 32 Zeichen): %s\n'  "$1" ;;
        iso_err_label_chars:EN) printf 'ERROR: Volume label contains invalid characters (only A-Z 0-9 . _ -): %s\n'  "$1" ;;
        iso_err_label_chars:*) printf 'FEHLER: Volume-Label enthält ungültige Zeichen (nur A-Z 0-9 . _ -): %s\n'  "$1" ;;
        iso_err_bad_comp:EN) printf '%s\n' "ERROR: Invalid squashfs compression: '%s'
Allowed: xz, zstd, lzma, gzip, lzo, lz4 (script default configurable: SQUASH_COMP=...)" "$1" ;;
        iso_err_bad_comp:*)  printf '%s\n' "FEHLER: Ungültige SquashFS-Kompression: '%s'
Erlaubt: xz, zstd, lzma, gzip, lzo, lz4 (Standard im Script einstellbar: SQUASH_COMP=...)" "$1" ;;
        iso_info_comp:EN) printf 'SquashFS compression: %s\n'  "$1" ;;
        iso_info_comp:*) printf 'SquashFS-Kompression: %s\n'  "$1" ;;
        iso_err_mkdir_work:EN) printf '%s\n' "ERROR: Could not create working directories" ;;
        iso_err_mkdir_work:*)  printf '%s\n' "FEHLER: Arbeitsverzeichnisse konnten nicht angelegt werden" ;;
        iso_warn_arch:EN) printf 'Warning: Architecture %s - BIOS boot may not be available; ISO may be UEFI-bootable only.\n'  "$1" ;;
        iso_warn_arch:*) printf 'Warnung: Architektur %s - BIOS-Boot steht evtl. nicht bereit; ISO ggf. nur UEFI-bootbar.\n'  "$1" ;;
        iso_err_tree:EN) printf '%s\n' "ERROR: Could not create the ISO tree" ;;
        iso_err_tree:*)  printf '%s\n' "FEHLER: ISO-Baum konnte nicht angelegt werden" ;;
        iso_warn_kernel_fallback:EN) printf 'Warning: Running kernel %s has no modules directory - using kernel %s\n'  "$1" "$2" ;;
        iso_warn_kernel_fallback:*) printf 'Warnung: Laufender Kernel %s hat kein Modules-Verzeichnis - verwende Kernel %s\n'  "$1" "$2" ;;
        iso_err_no_kernel:EN) printf 'ERROR: No kernel found (/usr/lib/modules/%s/vmlinuz missing)!\n'  "$1" ;;
        iso_err_no_kernel:*) printf 'FEHLER: Kein Kernel gefunden (/usr/lib/modules/%s/vmlinuz fehlt)!\n'  "$1" ;;
        iso_info_kernel:EN) printf 'Using kernel: %s (%s)\n'  "$1" "$2" ;;
        iso_info_kernel:*) printf 'Verwende Kernel: %s (%s)\n'  "$1" "$2" ;;
        iso_info_copy_kernel:EN) printf '%s\n' "Copying kernel..." ;;
        iso_info_copy_kernel:*)  printf '%s\n' "Kopiere Kernel..." ;;
        iso_err_kernel_copy:EN) printf '%s\n' "ERROR: Kernel copy failed" ;;
        iso_err_kernel_copy:*)  printf '%s\n' "FEHLER: Kernel-Kopie fehlgeschlagen" ;;
        iso_info_initramfs:EN) printf '%s\n' "Building initramfs with the archiso hook (all drivers, may take minutes)..." ;;
        iso_info_initramfs:*)  printf '%s\n' "Baue Initramfs mit archiso-Hook (alle Treiber, kann einige Minuten dauern)..." ;;
        iso_err_mkinitcpio:EN) printf '%s\n' "ERROR: mkinitcpio failed - is the 'mkinitcpio-archiso' package installed correctly?" ;;
        iso_err_mkinitcpio:*)  printf '%s\n' "FEHLER: mkinitcpio fehlgeschlagen - ist das Paket 'mkinitcpio-archiso' korrekt installiert?" ;;
        iso_info_overlay:EN) printf '%s\n' "Mounting root filesystem (read-only overlay)..." ;;
        iso_info_overlay:*)  printf '%s\n' "Hänge Root-Dateisystem (read-only Overlay) ein..." ;;
        iso_err_overlay_dirs:EN) printf '%s\n' "ERROR: Overlay directories failed" ;;
        iso_err_overlay_dirs:*)  printf '%s\n' "FEHLER: Overlay-Verzeichnisse fehlgeschlagen" ;;
        iso_err_overlay_mount:EN) printf '%s\n' "ERROR: Overlay mount failed" ;;
        iso_err_overlay_mount:*)  printf '%s\n' "FEHLER: Overlay-Mount fehlgeschlagen" ;;
        iso_err_overlay_incomplete:EN) printf '%s\n' "ERROR: Overlay content incomplete" ;;
        iso_err_overlay_incomplete:*)  printf '%s\n' "FEHLER: Overlay-Inhalt unvollständig" ;;
        iso_err_systemd:EN) printf '%s\n' "ERROR: systemd missing in the image - are / or /usr on a separate partition?" ;;
        iso_err_systemd:*)  printf '%s\n' "FEHLER: systemd fehlt im Abbild - liegt / oder /usr auf einer eigenen Partition?" ;;
        iso_warn_other_parts:EN) printf '%s\n' "Warning: These directories are separate partitions and will NOT be in the image:" ;;
        iso_warn_other_parts:*)  printf '%s\n' "Warnung: Diese Verzeichnisse sind eigene Partitionen und landen NICHT im Abbild:" ;;
        iso_err_cow_service:EN) printf '%s\n' "ERROR: Could not enable the overlay-size service" ;;
        iso_err_cow_service:*)  printf '%s\n' "FEHLER: Overlay-Größen-Service konnte nicht aktiviert werden" ;;
        iso_info_close_apps:EN) printf '%s\n' "Important: close other applications if possible so the image is consistent." ;;
        iso_info_close_apps:*)  printf '%s\n' "Wichtig: Schließe möglichst andere Anwendungen, damit das Abbild konsistent ist." ;;
        iso_info_squash_xz:EN) printf 'Creating squashfs (%s - highest compression, may take a long time)...\n'  "$1" ;;
        iso_info_squash_xz:*) printf 'Erstelle SquashFS (%s - höchste Kompression, kann lange dauern)...\n'  "$1" ;;
        iso_info_squash:EN) printf 'Creating squashfs (%s)...\n'  "$1" ;;
        iso_info_squash:*) printf 'Erstelle SquashFS (%s)...\n'  "$1" ;;
        iso_err_mksquashfs:EN) printf '%s\n' "ERROR: mksquashfs failed" ;;
        iso_err_mksquashfs:*)  printf '%s\n' "FEHLER: mksquashfs fehlgeschlagen" ;;
        iso_err_squash_mv:EN) printf '%s\n' "ERROR: Moving squashfs into place failed" ;;
        iso_err_squash_mv:*)  printf '%s\n' "FEHLER: SquashFS übernehmen fehlgeschlagen" ;;
        iso_warn_manifest:EN) printf '%s\n' "Warning: Manifest could not be created." ;;
        iso_warn_manifest:*)  printf '%s\n' "Warnung: Manifest konnte nicht erstellt werden." ;;
        iso_info_iso:EN) printf 'Creating ISO with grub-mkrescue (BIOS + UEFI bootable): %s\n'  "$1" ;;
        iso_info_iso:*) printf 'Erstelle ISO mit grub-mkrescue (BIOS + UEFI bootbar): %s\n'  "$1" ;;
        iso_err_mkrescue:EN) printf '%s\n' "ERROR: grub-mkrescue failed" ;;
        iso_err_mkrescue:*)  printf '%s\n' "FEHLER: grub-mkrescue fehlgeschlagen" ;;
        iso_err_no_iso:EN) printf '%s\n' "ERROR: ISO was not created!" ;;
        iso_err_no_iso:*)  printf '%s\n' "FEHLER: ISO wurde nicht erstellt!" ;;
        iso_success:EN) printf '%s\n' "SUCCESS: ISO CREATED" ;;
        iso_success:*)  printf '%s\n' "ERFOLG: ISO ERSTELLT" ;;
        iso_done_close:EN) printf '%s\n' "DONE - The ISO has been created. You can close this tool now." ;;
        iso_done_close:*)  printf '%s\n' "FERTIG - Die ISO ist erstellt. Sie können dieses Tool jetzt schließen." ;;
        iso_info_outpath:EN) printf 'Output path: %s (%s MB)\n'  "$1" "$2" ;;
        iso_info_outpath:*) printf 'Ausgabepfad: %s (%s MB)\n'  "$1" "$2" ;;
        iso_info_done_kernel:*) printf 'Kernel:      %s\n'  "$1" ;;
        iso_info_done_label:*) printf 'Label:       %s\n'  "$1" ;;
        iso_warn_secureboot:EN) printf '%s\n' "Warning: ISO not Secure-Boot signed -> disable Secure Boot in the UEFI." ;;
        iso_warn_secureboot:*)  printf '%s\n' "Warnung: ISO nicht Secure-Boot-signiert -> Secure Boot im UEFI deaktivieren." ;;
        # ---------- SquashFS-Kompression wählen ----------
        comp_desc_xz:EN) printf '%s\n' "smallest size, slowest build + extraction" ;;
        comp_desc_xz:*)  printf '%s\n' "kleinste Größe, langsamster Bau + Entpacken" ;;
        comp_desc_zstd:EN) printf '%s\n' "very fast build + extraction, good size" ;;
        comp_desc_zstd:*)  printf '%s\n' "sehr schneller Bau + Entpacken, gute Größe" ;;
        comp_desc_lzma:EN) printf '%s\n' "small size, slow build" ;;
        comp_desc_lzma:*)  printf '%s\n' "kleine Größe, langsamer Bau" ;;
        comp_desc_gzip:EN) printf '%s\n' "fast, classic format" ;;
        comp_desc_gzip:*)  printf '%s\n' "schnell, klassisches Format" ;;
        comp_desc_lzo:EN) printf '%s\n' "very fast build, larger images" ;;
        comp_desc_lzo:*)  printf '%s\n' "sehr schneller Bau, größere Images" ;;
        comp_desc_lz4:EN) printf '%s\n' "fastest method, largest images" ;;
        comp_desc_lz4:*)  printf '%s\n' "schnellstes Verfahren, größte Images" ;;
        comp_default_mark:EN) printf '%s\n' "   [default]" ;;
        comp_default_mark:*)  printf '%s\n' "   [Standard]" ;;
        comp_menu_title:EN) printf '%s\n' "Choose squashfs compression" ;;
        comp_menu_title:*)  printf '%s\n' "SquashFS-Kompression wählen" ;;
        comp_prompt_range:EN) printf '[1-%s, Enter=%s, 00=Quit]: \n'  "$1" "$2" ;;
        comp_prompt_range:*) printf '[1-%s, Enter=%s, 00=Beenden]: \n'  "$1" "$2" ;;
        comp_err_bad:EN) printf 'Invalid input (1-%s or empty).\n'  "$1" ;;
        comp_err_bad:*) printf 'Ungültige Eingabe (1-%s oder leer).\n'  "$1" ;;
        # ---------- ISO interaktiv ----------
        iso_menu_title:EN) printf '%s\n' "Create live ISO from the running system" ;;
        iso_menu_title:*)  printf '%s\n' "Live-ISO vom laufenden System erstellen" ;;
        iso_q_workdir:EN) printf '%s\n' "Working directory" ;;
        iso_q_workdir:*)  printf '%s\n' "Arbeitsverzeichnis" ;;
        iso_q_label:EN) printf '%s\n' "Volume label (max. 32 characters, A-Z 0-9 . _ -)" ;;
        iso_q_label:*)  printf '%s\n' "Volume-Label (max. 32 Zeichen, A-Z 0-9 . _ -)" ;;
        iso_q_out:EN) printf '%s\n' "ISO target (.iso file or directory, empty = <working directory>/archlive.iso)" ;;
        iso_q_out:*)  printf '%s\n' "ISO-Ziel (Datei .iso oder Verzeichnis, leer = <Arbeitsverzeichnis>/archlive.iso)" ;;
        iso_q_excludes:EN) printf '%s\n' "Additional excludes (space separated, empty = none)" ;;
        iso_q_excludes:*)  printf '%s\n' "Zusätzliche Ausschlüsse (leerzeichengetrennt, leer = keine)" ;;
        iso_info_summary:EN) printf '%s\n' "Summary:" ;;
        iso_info_summary:*)  printf '%s\n' "Zusammenfassung:" ;;
        iso_sum_workdir:EN) printf '  Working directory:  %s\n'  "$1" ;;
        iso_sum_workdir:*) printf '  Arbeitsverzeichnis: %s\n'  "$1" ;;
        iso_sum_label:*) printf '  Label:              %s\n'  "$1" ;;
        iso_sum_comp:EN) printf '  Compression:        %s (squashfs)\n'  "$1" ;;
        iso_sum_comp:*) printf '  Kompression:        %s (SquashFS)\n'  "$1" ;;
        iso_sum_target:EN) printf '  Target:             %s\n'  "$1" ;;
        iso_sum_target:*) printf '  Ziel:               %s\n'  "$1" ;;
        iso_sum_excludes:EN) printf '  Excludes:           %s\n'  "$1" ;;
        iso_sum_excludes:*) printf '  Ausschlüsse:        %s\n'  "$1" ;;
        iso_sum_no_excludes:EN) printf '%s\n' "  Excludes:           (none)" ;;
        iso_sum_no_excludes:*)  printf '%s\n' "  Ausschlüsse:        (keine)" ;;
        iso_q_start:EN) printf '%s\n' "Start the ISO build now (several GB, takes a long time)?" ;;
        iso_q_start:*)  printf '%s\n' "ISO-Bau jetzt starten (mehrere GB, dauert lange)?" ;;
        cleanup_q_confirm:EN) printf 'Really remove build artifacts in %s?\n'  "$1" ;;
        cleanup_q_confirm:*) printf 'Build-Artefakte in %s wirklich entfernen?\n'  "$1" ;;
        # ---------- Hauptmenü / Kommandozeile ----------
        exp_err_bad_dir:EN) printf 'Invalid target directory: %s\n'  "$1" ;;
        exp_err_bad_dir:*)  printf 'Ungültiges Zielverzeichnis: %s\n'  "$1" ;;
        exp_err_outdir:EN) printf 'Could not create directory: %s\n'  "$1" ;;
        exp_err_outdir:*)  printf 'Verzeichnis konnte nicht angelegt werden: %s\n'  "$1" ;;
        exp_err_chmod:EN) printf 'Could not make executable: %s\n'  "$1" ;;
        exp_err_chmod:*)  printf 'Konnte Datei nicht ausführbar machen: %s\n'  "$1" ;;
        exp_err_invalid_script:EN) printf 'ERROR: Generated script does not pass bash -n: %s\n'  "$1" ;;
        exp_err_invalid_script:*)  printf 'FEHLER: Erzeugtes Skript besteht bash -n nicht: %s\n'  "$1" ;;
        exp_err_no_core:EN) printf 'ERROR: Core markers not found in %s.\n'  "$1" ;;
        exp_err_no_core:*)  printf 'FEHLER: Kern-Markierungen in %s nicht gefunden.\n'  "$1" ;;
        exp_err_no_marker:EN) printf 'ERROR: Block marker %s not found in %s.\n'  "$1" "$2" ;;
        exp_err_no_marker:*)  printf 'FEHLER: Block-Markierung %s nicht gefunden in %s.\n'  "$1" "$2" ;;
        exp_info_done:EN) printf 'Done: 3 standalone scripts written to %s (%s).\n'  "$1" "${EXPORT_NAME[*]}" ;;
        exp_info_done:*)  printf 'Fertig: 3 eigenständige Skripte nach %s geschrieben (%s).\n'  "$1" "${EXPORT_NAME[*]}" ;;
        menu_main_title:EN) printf '%s %s - main menu\n'  "$SCRIPT_NAME" "$1" ;;
        menu_main_title:*) printf '%s %s - Hauptmenü\n'  "$SCRIPT_NAME" "$1" ;;
        menu_opt_iso:EN) printf '%s\n' "Create live ISO from the running system" ;;
        menu_opt_iso:*)  printf '%s\n' "Live-ISO vom laufenden System erstellen" ;;
        menu_opt_install:EN) printf '%s\n' "Install live system to disk/partition" ;;
        menu_opt_install:*)  printf '%s\n' "Live-System auf Festplatte/Partition installieren" ;;
        menu_opt_part:EN) printf '%s\n' "Open the partitioner (manage disks/partitions)" ;;
        menu_opt_part:*)  printf '%s\n' "Partitionierer öffnen (Platten/Partitionen verwalten)" ;;
        menu_opt_cleanup:EN) printf '%s\n' "Clean up (remove ISO build artifacts)" ;;
        menu_opt_cleanup:*)  printf '%s\n' "Aufräumen (ISO-Bau-Artefakte entfernen)" ;;
        menu_opt_targets:EN) printf '%s\n' "Show possible installation targets" ;;
        menu_opt_targets:*)  printf '%s\n' "Mögliche Installationsziele anzeigen" ;;
        menu_bye:EN) printf '%s\n' "Exiting." ;;
        menu_bye:*)  printf '%s\n' "Ende." ;;
        cli_err_missing_dir:EN) printf 'ERROR: Missing directory for %s.\n'  "$1" ;;
        cli_err_missing_dir:*) printf 'FEHLER: Für %s fehlt ein Verzeichnis.\n'  "$1" ;;
        cli_err_missing_path:EN) printf 'ERROR: Missing path for %s.\n'  "$1" ;;
        cli_err_missing_path:*) printf 'FEHLER: Für %s fehlt ein Pfad.\n'  "$1" ;;
        cli_err_missing_label:EN) printf 'ERROR: Missing label for %s.\n'  "$1" ;;
        cli_err_missing_label:*) printf 'FEHLER: Für %s fehlt ein Label.\n'  "$1" ;;
        cli_err_missing_algo:EN) printf 'ERROR: Missing algorithm for %s (xz, zstd, lzma, gzip, lzo, lz4).\n'  "$1" ;;
        cli_err_missing_algo:*) printf 'FEHLER: Für %s fehlt ein Algorithmus (xz, zstd, lzma, gzip, lzo, lz4).\n'  "$1" ;;
        cli_err_missing_excludes:EN) printf 'ERROR: Missing excludes for %s.\n'  "$1" ;;
        cli_err_missing_excludes:*) printf 'FEHLER: Für %s fehlen die Ausschlüsse.\n'  "$1" ;;
        cli_err_missing_dev:EN) printf 'ERROR: Missing device for %s.\n'  "$1" ;;
        cli_err_missing_dev:*) printf 'FEHLER: Für %s fehlt ein Gerät.\n'  "$1" ;;
        cli_err_unknown_opt:EN) printf 'ERROR: Unknown option: %s (help: %s iso -h)\n'  "$1" "$SCRIPT_NAME" ;;
        cli_err_unknown_opt:*) printf 'FEHLER: Unbekannte Option: %s (Hilfe: %s iso -h)\n'  "$1" "$SCRIPT_NAME" ;;
        cli_err_unknown_arg:EN) printf 'ERROR: Unknown argument: %s (help: %s)\n'  "$1" "$2" ;;
        cli_err_unknown_arg:*) printf 'FEHLER: Unbekanntes Argument: %s (Hilfe: %s)\n'  "$1" "$2" ;;
        cli_err_one_target:EN) printf '%s\n' "ERROR: Specify only one ISO target." ;;
        cli_err_one_target:*)  printf '%s\n' "FEHLER: Nur ein ISO-Ziel angeben." ;;
        cli_err_unknown_cmd:EN) printf 'ERROR: Unknown command: %s\n'  "$1" ;;
        cli_err_unknown_cmd:*) printf 'FEHLER: Unbekannter Befehl: %s\n'  "$1" ;;
        grub_std:EN) printf '%s\n' "Standard" ;;
        grub_std:*)  printf '%s\n' "Standard" ;;
        grub_verbose:EN) printf '%s\n' "verbose (error diagnosis)" ;;
        grub_verbose:*)  printf '%s\n' "ausführlich (Fehlerdiagnose)" ;;
        grub_copytoram:EN) printf '%s\n' "load completely into RAM (copytoram)" ;;
        grub_copytoram:*)  printf '%s\n' "vollständig in den RAM laden (copytoram)" ;;
        grub_nomodeset:EN) printf '%s\n' "bypass graphics problems (nomodeset)" ;;
        grub_nomodeset:*)  printf '%s\n' "Grafikprobleme umgehen (nomodeset)" ;;
        *) printf '%s\n' "$key" ;;
    esac
}
te() { t "$@" >&2; }
td() { te "$@"; exit 1; }

# ============================================================
# Farben
# ============================================================

USE_COLOR="j"

# -nc / --no-color: Farben abschalten; Flags aus den Argumenten entfernen
no_color_args=()
for a in "$@"; do
    if [[ "$a" == "--no-color" || "$a" == "-nc" ]]; then
        USE_COLOR="n"
    else
        no_color_args+=("$a")
    fi
done
set -- "${no_color_args[@]}"

init_colors() {
    if [[ "$USE_COLOR" == "j" && -t 1 && -z "${NO_COLOR:-}" ]]; then
        C_HEAD=$'\e[1;96m'   # hell cyan   - Überschriften (DESIGN.md)
        C_TEXT=$'\e[1;93m'   # hell gelb   - normaler Text (DESIGN.md)
        C_FILE=$'\e[1;35m'   # hell lila   - Dateien/Pfade/Geräte (DESIGN.md)
        C_MISC=$'\e[1;92m'   # hell grün   - alles andere (DESIGN.md)
        C_ERR=$'\e[1;91m'    # HELLROT     - Fehler UND Warnungen (DESIGN.md)
        C_OFF=$'\e[0m'
    else
        C_HEAD=""
        C_TEXT=""
        C_FILE=""
        C_MISC=""
        C_ERR=""
        C_OFF=""
    fi
}

init_colors

# ---------- Ausgabe-Helfer ----------
# Wichtig: bewusst NICHT "head" genannt - eine Funktion dieses Namens würde
# das Programm /usr/bin/head überschatten (Funktionen haben Vorrang).

head_msg() { printf '\n%s\n' "${C_HEAD}=== $* ===${C_OFF}"; }

txt()   { printf '%s\n' "${C_TEXT}$*${C_OFF}"; }
misc()  { printf '%s\n' "${C_MISC}$*${C_OFF}"; }
warn()  { printf '%s\n' "${C_ERR}$*${C_OFF}"; }   # Warnungen = HELLROT (DESIGN.md)
err()   { printf '%s\n' "${C_ERR}>>> $*${C_OFF}" >&2; }

fstr()  { printf '%s' "${C_FILE}$*${C_OFF}"; }   # Pfad inline (ohne Zeilenumbruch)

die() {
    printf '\n%s\n' "${C_ERR}>>> $*${C_OFF}" >&2
    exit 3
}

# Kommando-Ausgaben (lsblk & Co.) grün einfärben
dump_misc() { "$@" 2>&1 | sed "s/^/${C_MISC}/; s/$/${C_OFF}/"; }

# ---------- Eingabe-Helfer (Zahlen-Auswahl) ----------

INTERACTIVE="n"
INPUT=""
# Wurde das letzte Menü mit 0/q/EOF verlassen? (keine Enter-Pause nötig)
USER_ABORTED="n"

# Liest eine Zeile. stdin kein Terminal (Pipe/SSH-Job) -> /dev/tty.
# Rückgabe 1 bei EOF (Abbruch). Ergebnis in INPUT.
get_input() {
    INPUT=""
    if [[ -t 0 ]]; then
        read -r INPUT && return 0
    else
        read -r INPUT </dev/tty 2>/dev/null && return 0
    fi
    return 1
}

# Skript komplett beenden (00) - 42 = Quit-All-Signal, das run_action
# durchreicht und das aufrufende Bündel-Skript auswertet
quit_all() {
    exit 42
}

# menu_select "Titel" "Option 1" "Option 2" ...
#   -> MENU_NR (1..n); Rückgabe 1 = Abbruch (0/q/EOF); 00 = Beenden (quit_all)
menu_select() {
    local title="$1"
    shift
    local -a opts=("$@")
    local o pick

    head_msg "$title"
    local i=1
    for o in "${opts[@]}"; do
        misc "  ${i}) ${o}"
        i=$((i + 1))
    done
    while :; do
        printf '%s' "${C_TEXT}$(t menu_prompt_choice) ${C_MISC}$(t menu_prompt_range "${#opts[@]}")${C_OFF}"
        get_input || { USER_ABORTED="j"; return 1; }
        pick="${INPUT:-0}"
        case "$pick" in
            00) quit_all ;;
            0|q|Q) USER_ABORTED="j"; return 1 ;;
        esac
        if [[ ! "$pick" =~ ^[0-9]+$ ]]; then
            misc "$(t menu_err_notanumber)"
            continue
        fi
        if (( pick >= 1 && pick <= ${#opts[@]} )); then
            MENU_NR="$pick"
            USER_ABORTED="n"
            return 0
        fi
        misc "$(t menu_err_bad_number "${#opts[@]}")"
    done
}

# ask_string "Prompt" "Vorgabe"  -> ANSWER (leere Eingabe = Vorgabe)
ask_string() {
    local prompt="$1" def="${2:-}"
    if [[ -n "$def" ]]; then
        printf '%s' "${C_TEXT}${prompt} ${C_MISC}[${def}]: ${C_OFF}"
    else
        printf '%s' "${C_TEXT}${prompt}: ${C_OFF}"
    fi
    get_input || return 1
    ANSWER="${INPUT:-$def}"
    return 0
}

# confirm_yes "Frage?"  -> 0=ja (Vorgabe ja); -y beantwortet automatisch
confirm_yes() {
    if [[ "${ASSUME_YES:-n}" == "j" ]]; then
        return 0
    fi
    printf '%s' "${C_TEXT}$1 ${C_MISC}[$(t q_jn)]: ${C_OFF}"
    get_input || return 1
    local ans="${INPUT,,}"
    case "${ans:-j}" in
        j|y|ja|yes) return 0 ;;
        *) return 1 ;;
    esac
}

# Destruktive Aktion bestätigen lassen; -y überspringt.
# Ja:  JA / ja / J / j / Y / y / YES / yes
# Nein: NEIN / nein / N / n / NO / no - leere Eingabe wird erneut
# abgefragt (kein Abbruch), alles andere mit Hinweis ebenfalls.
confirm_ja_nein() {
    if [[ "${ASSUME_YES:-n}" == "j" ]]; then
        return 0
    fi
    while :; do
        printf '%s' "${C_TEXT}$(t q_confirm_continue): ${C_OFF}"
        get_input || return 1
        case "${INPUT,,}" in
            ja|j|y|yes) return 0 ;;
            nein|n|no) return 1 ;;
            "")
                # leere Eingabe: erneut fragen (kein Abbruch)
                misc "$(t q_answer_ja_nein)"
                continue ;;
            *)
                misc "$(t q_answer_ja_nein)"
                continue ;;
        esac
    done
}

pause_key() {
    printf '%s' "${C_TEXT}[$(t ui_continue_enter)]${C_OFF}"
    get_input >/dev/null 2>&1 || true
    printf '\n'
}

# ---------- Root / Umgebung ----------

invoking_home() {
    local u="${SUDO_USER:-}" h=""
    if [[ -n "$u" ]]; then
        h="$(getent passwd "$u" 2>/dev/null | cut -d: -f6 || true)"
    fi
    if [[ -z "$h" ]]; then
        h="${HOME:-/root}"
    fi
    printf '%s\n' "$h"
}

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        txt "$(t info_requesting_root)"
        exec sudo bash "$SCRIPT_PATH" "${ORIG_ARGS[@]}"
    fi
}

# ============================================================
# Geräte-Grundlagen (sfdisk/lsblk, alles read-only)
# ============================================================

# sfdisk -d ist auf Platten ohne Partitionstabelle fehlerhaft - immer 0
# zurückgeben, Aufrufer entscheiden anhand der leeren Ausgabe.
sfdisk_dump() {
    sfdisk -d "$1" 2>/dev/null || true
}

disk_table() {
    sfdisk_dump "$1" | sed -n 's/^label: *//p' | head -n1
}

disk_is_gpt() {
    [[ "$(disk_table "$1")" == "gpt" ]]
}

disk_has_biosboot() {
    sfdisk_dump "$1" | grep -qi "21686148-6449-6e6f-744e-656564454649" || return 1
    return 0
}

# Partitionszeilen aus "sfdisk -d": "start size nr" je Zeile, nach Start
# sortiert. sfdisk padt die Zahlen (start=%12ju, size=%12ju im Quellcode),
# deshalb "start= *" mit Leerzeichen matchen. Die Nummer ergibt sich als
# Suffix der Disk-Basisbezeichnung (nvme0n1p1 -> Disk nvme0n1 -> 1).
part_regions() {
    local disk="$1" base
    base="${disk##*/}"
    sfdisk_dump "$disk" | while IFS= read -r line; do
        local dev start size nr
        [[ "$line" == *" : start="* ]] || continue
        dev="${line%% :*}"
        dev="${dev##*/}"
        start="$(printf '%s\n' "$line" | sed -n 's/.*start= *\([0-9]*\),.*/\1/p')"
        size="$(printf '%s\n' "$line" | sed -n 's/.*size= *\([0-9]*\),.*/\1/p')"
        nr="${dev#"$base"}"
        nr="${nr#p}"
        [[ "$nr" =~ ^[0-9]+$ ]] || continue
        [[ -n "$start" && -n "$size" ]] || continue
        printf '%s %s %s\n' "$start" "$size" "$nr"
    done | sort -n
}

part_nrs() {
    local start size nr
    part_regions "$1" | while read -r start size nr; do
        printf '%s\n' "$nr"
    done | sort -n
}

sector_size() {
    local s
    s="$(blockdev --getss "$1" 2>/dev/null)" || s=""
    if [[ ! "$s" =~ ^[0-9]+$ ]] || (( s < 512 )); then
        s=512
    fi
    printf '%s\n' "$s"
}

# Partitionsprefix: ganze Platten, deren Name auf eine Ziffer endet
# (nvme0n1, mmcblk0, md0, ...), bekommen "p" vor die Partitionsnummer.
part_prefix() {
    local dev="$1"
    case "$dev" in
        *[0-9]) printf '%sp\n' "$dev" ;;
        *) printf '%s\n' "$dev" ;;
    esac
}

# Freie Bereiche: "start end"-Zeilen (Sektoren, 1-MiB-ausgerichtet).
# Erweiterte Partitionen (MBR) gelten als "frei innen", damit logische
# Partitionen darin anlegbar sind.
compute_gaps() {
    local disk="$1"
    local SECTOR ALIGN first last total_bytes
    SECTOR="$(sector_size "$disk")"
    ALIGN=$((1048576 / SECTOR))

    first="$(sfdisk_dump "$disk" | sed -n 's/^first-lba: *//p' | head -n1)"
    last="$(sfdisk_dump "$disk" | sed -n 's/^last-lba: *//p' | head -n1)"
    if [[ -z "$first" || -z "$last" ]]; then
        # MBR-Dumps kennen kein first-/last-lba -> aus der Plattengröße ableiten
        total_bytes="$(blockdev --getsize64 "$disk" 2>/dev/null)" || return 1
        [[ "$total_bytes" =~ ^[0-9]+$ ]] || return 1
        first="$ALIGN"
        last=$((total_bytes / SECTOR - 1))
    fi

    local -a occ=()
    local s sz nr dev e
    while read -r s sz nr; do
        [[ -n "$s" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        if part_is_extended "$dev"; then
            continue
        fi
        e=$((s + sz - 1))
        # Belegte Bereiche konservativ auf das 1-MiB-Raster ERWEITERN
        # (Start abrunden, Ende aufrunden), damit keine berechnete Lücke
        # einen echten Partitionsteil überlappt.
        s=$((s / ALIGN * ALIGN))
        if (( e % ALIGN )); then
            e=$(( (e / ALIGN + 1) * ALIGN - 1 ))
        fi
        if (( e >= s )); then
            occ+=("$s $e")
        fi
    done < <(part_regions "$disk")

    first=$(((first + ALIGN - 1) / ALIGN * ALIGN))
    last=$((last / ALIGN * ALIGN))

    local cur="$first" r
    for r in "${occ[@]}"; do
        [[ -n "$r" ]] || continue
        s="${r% *}"
        e="${r#* }"
        if (( s > cur )); then
            printf '%s %s\n' "$cur" $((s - 1))
        fi
        if (( e >= cur )); then
            cur=$((e + 1))
        fi
    done
    if (( last >= cur )); then
        printf '%s %s\n' "$cur" "$last"
    fi
    return 0
}

# Anzeige-Hilfen
fmt_mib() {
    local mib="$1"
    if (( mib >= 1024 )); then
        awk -v m="$mib" 'BEGIN{printf "%.1f GiB", m/1024}'
    else
        printf '%s MiB' "$mib"
    fi
}

sectors_to_mib() {
    # $1 = Sektoren, $2 = Sektorgröße
    printf '%s\n' $((($1 * $2) / 1048576))
}

lsblk_val() {
    lsblk -nro "$1" "$2" 2>/dev/null | head -n1 || true
}

# Erweiterte Partition? (dos: Typ 5/f/85 laut lsblk PARTTYPE/PARTTYPENAME)
part_is_extended() {
    local t
    t="$(lsblk_val PARTTYPE "$1")"
    case "$t" in
        0x5|0x05|0x0f|0x0F|0x85|5|f|F|85) return 0 ;;
    esac
    case "$(lsblk_val PARTTYPENAME "$1")" in
        *[Ee]xtended*) return 0 ;;
    esac
    return 1
}

dev_is_mounted() {
    findmnt -rn -S "$1" >/dev/null 2>&1
}

# Lage eines freien Bereichs in Worten ("auf leerer Platte",
# "vor Partition 1", "zwischen Partition 2 und 3", "nach Partition 4").
# Anzeige-Hilfe - bewusst ohne Sektorenzahlen. part_regions liefert die
# Partitionen nach Start sortiert, daher ist die zuletzt gefundene
# Partition vor dem Bereich die richtige "vor"-Referenz.
gap_lage() {
    local disk="$1" gs="$2" ge="$3"
    local start size nr before="" after="" end
    while read -r start size nr; do
        [[ -n "$nr" ]] || continue
        end=$((start + size - 1))
        if (( end < gs )); then
            before="$nr"
        fi
        if [[ -z "$after" ]] && (( start > ge )); then
            after="$nr"
        fi
    done < <(part_regions "$disk")

    if [[ -n "$before" && -n "$after" ]]; then
        t gap_between "$before" "$after"
    elif [[ -n "$before" ]]; then
        t gap_after "$before"
    elif [[ -n "$after" ]]; then
        t gap_before "$after"
    else
        t gap_empty_disk
    fi
    return 0
}

# ============================================================
# Live-Medium erkennen (3-stufig)
# ============================================================

resolve_disk() {
    local dev="$1" real pk
    [[ -n "$dev" ]] || return 1
    case "$dev" in
        LABEL=*) real="$(blkid -L "${dev#LABEL=}" 2>/dev/null || true)" ;;
        UUID=*) real="$(blkid -U "${dev#UUID=}" 2>/dev/null || true)" ;;
        PARTUUID=*) real="$(blkid -t "$dev" -o device 2>/dev/null | head -n1 || true)" ;;
        *) real="$dev" ;;
    esac
    [[ -n "$real" ]] || return 1
    if [[ -e "$real" ]]; then
        real="$(readlink -f "$real" 2>/dev/null || true)"
        [[ -n "$real" ]] || return 1
    fi
    [[ -b "$real" ]] || return 1
    if [[ "$(lsblk -ndo TYPE "$real" 2>/dev/null)" == "disk" ]]; then
        printf '%s\n' "$real"
        return 0
    fi
    pk="$(lsblk -nro PKNAME "$real" 2>/dev/null | head -n1 || true)"
    [[ -n "$pk" ]] || return 1
    printf '/dev/%s\n' "$pk"
}

live_medium_from_bootmnt() {
    local src
    src="$(findmnt -nro SOURCE /run/archiso/bootmnt 2>/dev/null || true)"
    [[ -n "$src" ]] || return 1
    resolve_disk "$src"
}

live_medium_from_label() {
    local iso_label disk dtype
    iso_label="$(sed -n 's/.*archisolabel=\([^ ]*\).*/\1/p' /proc/cmdline 2>/dev/null || true)"
    [[ -n "$iso_label" ]] || return 1
    while read -r disk dtype; do
        [[ "$dtype" == "disk" ]] || continue
        if lsblk -nro LABEL "/dev/$disk" 2>/dev/null | grep -qxF "$iso_label"; then
            printf '/dev/%s\n' "$disk"
            return 0
        fi
    done < <(lsblk -nrdo NAME,TYPE 2>/dev/null)
    return 1
}

live_medium_from_iso9660() {
    local dev dtype fstype pk
    while read -r dev dtype fstype; do
        [[ -n "$dev" ]] || continue
        [[ "$fstype" == "iso9660" ]] || continue
        if [[ "$dtype" == "disk" ]]; then
            printf '%s\n' "$dev"
            return 0
        fi
        pk="$(lsblk -nro PKNAME "$dev" 2>/dev/null | head -n1 || true)"
        if [[ -n "$pk" ]]; then
            printf '/dev/%s\n' "$pk"
        else
            printf '%s\n' "$dev"
        fi
        return 0
    done < <(lsblk -pnrno NAME,TYPE,FSTYPE 2>/dev/null)
    return 1
}

detect_live_medium() {
    local dev
    dev="$(live_medium_from_bootmnt || true)"
    if [[ -z "$dev" ]]; then dev="$(live_medium_from_label || true)"; fi
    if [[ -z "$dev" ]]; then dev="$(live_medium_from_iso9660 || true)"; fi
    if [[ -n "$dev" ]]; then
        printf '%s\n' "$dev"
    fi
    return 0
}

# ============================================================
# Formatieren (FAT32 eingebaut - kein Nachinstallieren nötig)
# ============================================================

# Fehlendes Werkzeug auf Wunsch per pacman nachinstallieren (nur für
# Sonderfälle wie die Partitions-Grundwerkzeuge in part_check_tools).
# $1 = Befehl, $2 = Paket, $3 = Kontext für die Abbruchmeldung
ensure_tool() {
    local tool="$1" pkg="$2" kontext="${3:-$(t ensure_default_context)}"
    if command -v "$tool" >/dev/null 2>&1; then
        return 0
    fi

    if [[ "$INTERACTIVE" == "j" ]]; then
        if ! confirm_yes "$(t q_install_missing_tool "$tool" "$pkg")"; then
            warn "$(t warn_tool_missing_aborted "$kontext" "$tool")"
            return 1
        fi
    fi

    misc "$(t info_installing_pkg "$pkg")"
    if ! pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
        misc "$(t info_pacman_retry)"
        if ! pacman -Sy --needed --noconfirm "$pkg" >/dev/null 2>&1; then
            err "$(t err_tool_install_failed2 "$tool" "$pkg")"
            return 1
        fi
    fi

    if command -v "$tool" >/dev/null 2>&1; then
        misc "$(t info_tool_available "$tool")"
        return 0
    fi
    err "$(t err_tool_install_failed "$tool" "$pkg")"
    return 1
}

# ---------- Eingebauter FAT32-Formatierer (Ersatz für mkfs.vfat) ----------
# Legt ein vollständiges FAT32 nach der Microsoft-FAT-Spezifikation an:
# Bootsektor mit BPB, FSInfo-Sektor, Backup-Bootsektor (Sektor 6/7),
# zwei FATs und das Root-Verzeichnis als Cluster 2. Damit funktioniert
# das Formatieren von FAT32/ESP auch ohne dosfstools - es muss nichts
# nachinstalliert werden. Ist mkfs.vfat vorhanden, benutzt make_fs
# stattdessen das Original.

# 16-/32-Bit-Werte little-endian binär nach stdout schreiben.
# Wichtig: die \xNN-Escapes müssen im ARGUMENT stehen und über %b
# ausgewertet werden - im Formatstring würde \x vor dem %-Platzhalter
# stehen und printf einen Fehler werfen ("fehlende hexadezimale Ziffer").
fat_le16() {
    printf '%b' \
        "\\x$(printf '%02x' $(( $1 & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 256) & 255 )))"
}

fat_le32() {
    printf '%b' \
        "\\x$(printf '%02x' $(( $1 & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 256) & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 65536) & 255 )))" \
        "\\x$(printf '%02x' $(( ($1 / 16777216) & 255 )))"
}

# $1 = Gerät, $2 = Volume-Label (optional, max. 11 Zeichen, Default "NO NAME")
mkfs_fat32_builtin() {
    local dev="$1" label="${2:-NO NAME}"
    local SS bytes total_sect sc fat_sz reserved=32 nfats=2
    local data_start clusters cluster_bytes

    SS="$(sector_size "$dev")"
    case "$SS" in
        512|1024|2048|4096) : ;;
        *)
            err "$(t err_fat_sectorsize "$SS")"
            return 1 ;;
    esac

    bytes="$(blockdev --getsize64 "$dev" 2>/dev/null)" || bytes=""
    if [[ ! "$bytes" =~ ^[0-9]+$ ]] || (( bytes == 0 )); then
        # Fallback (z. B. Imagedateien): Größe über stat ermitteln
        bytes="$(stat -c%s "$dev" 2>/dev/null)" || bytes=""
    fi
    if [[ ! "$bytes" =~ ^[0-9]+$ ]] || (( bytes == 0 )); then
        err "$(t err_fat_size "$dev")"
        return 1
    fi
    total_sect=$((bytes / SS))
    # Das Sektorfeld im BPB ist 32 Bit breit - bei 512-Byte-Sektoren ist
    # FAT32 damit auf 2 TiB begrenzt.
    if (( total_sect >= 4294967296 )); then
        err "$(t err_fat_too_big "$bytes")"
        return 1
    fi

    # Clustergröße nach Volume-Größe wählen (Kleine Volumes kleine
    # Cluster, sonst 4-64 KiB - sinngemäß wie mkfs.fat)
    if   (( bytes <= 272629760 ));   then cluster_bytes=$SS        # ≤ 260 MiB
    elif (( bytes <= 8589934592 ));  then cluster_bytes=4096       # ≤ 8 GiB
    elif (( bytes <= 17179869184 )); then cluster_bytes=8192       # ≤ 16 GiB
    elif (( bytes <= 34359738368 )); then cluster_bytes=16384      # ≤ 32 GiB
    elif (( bytes <= 549755813888 )); then cluster_bytes=32768     # ≤ 512 GiB
    else cluster_bytes=65536
    fi
    if (( cluster_bytes < SS )); then
        cluster_bytes=$SS
    fi
    sc=$((cluster_bytes / SS))
    if (( sc > 128 )); then
        err "$(t err_fat_cluster "$SS")"
        return 1
    fi

    # FAT-Größe iterativ bestimmen (4 Byte je Cluster-Eintrag)
    fat_sz=$(( (total_sect / sc) * 4 / SS + 2 ))
    local needed i
    for i in 1 2 3 4 5 6 7 8; do
        data_start=$(( reserved + fat_sz * nfats ))
        if (( data_start + sc > total_sect )); then
            err "$(t err_fat_too_small)"
            return 1
        fi
        clusters=$(( (total_sect - data_start) / sc ))
        needed=$(( ( (clusters + 2) * 4 + SS - 1 ) / SS ))
        fat_sz=$needed
    done
    data_start=$(( reserved + fat_sz * nfats ))
    clusters=$(( (total_sect - data_start) / sc ))
    if (( clusters < 65525 )); then
        warn "$(t warn_fat_few_clusters "$clusters")"
    fi
    if (( clusters > 268435446 )); then
        err "$(t err_fat_many_clusters "$clusters")"
        return 1
    fi

    misc "$(t info_fat_created "$cluster_bytes" "$clusters" "$((fat_sz * SS / 1024))")"

    # Schreibarbeit in einem Subshell mit eigenem Aufräum-Trap (EXIT des
    # Subshells berührt keine globalen Traps). Alle Schritte ausdrücklich
    # mit "|| exit 1" gesichert, da Errexit in Bedingungskontexten ruht.
    if ! (
        tmpdir="$(mktemp -d)" || exit 1
        trap 'rm -rf "$tmpdir"' EXIT

        # Bootsektor (BPB) + Backup, FSInfo + Backup
        boot="$tmpdir/boot"
        {
            printf '\xeb\x3c\x90'                          # jmp
            printf 'ARCHLIVE'                              # OEM-Name (8 B)
            fat_le16 "$SS"                                 # Bytes/Sektor
            case "$sc" in
                1) printf '\x01' ;;
                2) printf '\x02' ;;
                4) printf '\x04' ;;
                8) printf '\x08' ;;
                16) printf '\x10' ;;
                32) printf '\x20' ;;
                64) printf '\x40' ;;
                128) printf '\x80' ;;
            esac
            fat_le16 32                                    # reservierte Sektoren
            printf '\x02'                                  # Anzahl FATs
            fat_le16 0                                     # Root-Einträge (FAT32: 0)
            if (( total_sect < 65536 )); then
                fat_le16 "$total_sect"                     # Sektoren (16 Bit)
            else
                fat_le16 0
            fi
            printf '\xf8'                                  # Media-Deskriptor
            fat_le16 0                                     # FAT-Größe (16 Bit, FAT32: 0)
            fat_le16 63                                    # Sektoren/Spur
            fat_le16 255                                   # Köpfe
            fat_le32 0                                     # versteckte Sektoren
            if (( total_sect >= 65536 )); then
                fat_le32 "$total_sect"                     # Sektoren (32 Bit)
            else
                fat_le32 0
            fi
            fat_le32 "$fat_sz"                             # FAT-Größe (32 Bit)
            fat_le16 0                                     # Ext-Flags
            fat_le16 0                                     # FS-Version
            fat_le32 2                                     # Root-Cluster
            fat_le16 1                                     # FSInfo-Sektor (16 Bit!)
            fat_le16 6                                     # Backup-Bootsektor (16 Bit!)
            dd if=/dev/zero bs=1 count=12 2>/dev/null      # reserviert (12 B, Offset 52-63)
            printf '\x80\x00\x29'                          # Drive, reserviert, ext. Boot-Sig. (64-66)
            head -c 4 /dev/urandom                         # Volume-ID (67-70)
            printf '%-11.11s' "$label"                     # Volume-Label (71-81)
            printf 'FAT32   '                              # FS-Typ (82-89)
            dd if=/dev/zero bs=1 count=420 2>/dev/null     # Boot-Code-Bereich (90-509)
            printf '\x55\xaa'                              # Boot-Signatur
        } > "$boot"
        [[ "$(stat -c%s "$boot")" -eq 512 ]] || exit 1

        fsinfo="$tmpdir/fsinfo"
        {
            printf '\x52\x52\x61\x41'                      # LeadSig "RRaA" (0x41615252 LE)
            dd if=/dev/zero bs=1 count=480 2>/dev/null
            printf '\x72\x72\x41\x61'                      # StrucSig "rrAa" (0x61417272 LE)
            fat_le32 $((clusters - 1))                     # freie Cluster (nur Root belegt)
            fat_le32 3                                     # nächstes freies Cluster
            dd if=/dev/zero bs=1 count=14 2>/dev/null      # reserviert
            printf '\x55\xaa'
        } > "$fsinfo"
        [[ "$(stat -c%s "$fsinfo")" -eq 512 ]] || exit 1

        # FAT: Einträge 0/1/2 vorbesetzt, Rest Nullen (Sparse-Datei liest
        # sich als Nullen); zwei identische Kopien auf das Gerät
        fat="$tmpdir/fat"
        printf '\xf8\xff\xff\x0f\xff\xff\xff\x0f\xff\xff\xff\x0f' > "$fat" || exit 1
        truncate -s $((fat_sz * SS)) "$fat" || exit 1
        dd if="$boot" of="$dev" bs="$SS" seek=0 conv=notrunc 2>/dev/null || exit 1
        dd if="$fsinfo" of="$dev" bs="$SS" seek=1 conv=notrunc 2>/dev/null || exit 1
        dd if="$boot" of="$dev" bs="$SS" seek=6 conv=notrunc 2>/dev/null || exit 1
        dd if="$fsinfo" of="$dev" bs="$SS" seek=7 conv=notrunc 2>/dev/null || exit 1
        dd if="$fat" of="$dev" bs="$SS" seek=$reserved conv=notrunc 2>/dev/null || exit 1
        dd if="$fat" of="$dev" bs="$SS" seek=$((reserved + fat_sz)) conv=notrunc 2>/dev/null || exit 1
        # Root-Verzeichnis (Cluster 2): bei gesetztem Label einen Volume-
        # Label-Eintrag schreiben (wie mkfs.fat), sonst alles leer lassen
        if [[ "$label" != "NO NAME" ]]; then
            rootfile="$tmpdir/root"
            {
                printf '%-11.11s' "$label"                 # Name (11 B)
                printf '\x08'                              # ATTR_VOLUME_ID
                dd if=/dev/zero bs=1 count=$((SS - 12)) 2>/dev/null
            } > "$rootfile"
            [[ "$(stat -c%s "$rootfile")" -eq "$SS" ]] || exit 1
            dd if="$rootfile" of="$dev" bs="$SS" seek=$data_start count=1 conv=notrunc 2>/dev/null || exit 1
            if (( sc > 1 )); then
                dd if=/dev/zero of="$dev" bs="$SS" seek=$((data_start + 1)) count=$((sc - 1)) conv=notrunc 2>/dev/null || exit 1
            fi
        else
            dd if=/dev/zero of="$dev" bs="$SS" seek=$data_start count=$sc conv=notrunc 2>/dev/null || exit 1
        fi
    ); then
        err "$(t err_fat_failed "$dev")"
        return 1
    fi

    sync
    return 0
}

make_fs() {
    # $1 = Gerät, $2 = ext4|vfat|swap|ntfs
    # Bewusst KEINE Nachinstall-Frage: Partitionieren und Formatieren
    # funktionieren ohne zusätzliche Pakete. FAT32 wird notfalls mit dem
    # eingebauten Formatierer angelegt; für ext4/NTFS gibt es eine klare
    # Fehlermeldung, wenn das Werkzeug wirklich fehlt.
    local dev="$1" fs="$2"
    local -a mkfs_cmd=()

    if dev_is_mounted "$dev"; then
        err "$(t err_dev_mounted "$(fstr "$dev")")"
        return 1
    fi

    wipefs -a "$dev" >/dev/null 2>&1 || true

    case "$fs" in
        ext4)
            if ! command -v mkfs.ext4 >/dev/null 2>&1; then
                err "$(t err_no_mkfs_ext4)"
                return 1
            fi
            mkfs_cmd=(mkfs.ext4 -q -F "$dev") ;;
        vfat)
            if command -v mkfs.vfat >/dev/null 2>&1; then
                mkfs_cmd=(mkfs.vfat -F32 "$dev")
            elif command -v mkfs.fat >/dev/null 2>&1; then
                mkfs_cmd=(mkfs.fat -F32 "$dev")
            else
                # Eingebauter Formatierer - dosfstools wird nicht gebraucht
                if mkfs_fat32_builtin "$dev"; then
                    misc "$(t info_fs_created_builtin "$(fstr "$dev")")"
                    return 0
                fi
                err "$(t err_format_failed "$dev" "FAT32")"
                return 1
            fi ;;
        swap)
            if ! command -v mkswap >/dev/null 2>&1; then
                err "$(t err_no_mkswap)"
                return 1
            fi
            mkfs_cmd=(mkswap "$dev") ;;
        ntfs)
            if ! command -v mkfs.ntfs >/dev/null 2>&1; then
                err "$(t err_no_mkfs_ntfs)"
                return 1
            fi
            mkfs_cmd=(mkfs.ntfs -f "$dev") ;;
        *) return 1 ;;
    esac

    misc "$(t info_formatting "$(fstr "$dev")" "$fs")"
    if "${mkfs_cmd[@]}" >/dev/null 2>&1; then
        misc "$(t info_fs_created "$fs" "$(fstr "$dev")")"
        return 0
    fi
    err "$(t err_format_failed "$dev" "$fs")"
    return 1
}

# Aktion im Subshell-Kontext: ein Abbruch (die/exit) beendet nur die
# Aktion, nicht das Menü. Mount-Traps laufen im Subshell-EXIT an.
# Der Subshell-Exit kodiert 4 für "Benutzer hat das Menü mit 0/q
# verlassen" (interner Code, wird nie zum Script-Exitcode) - dann ohne
# Enter-Pause und ohne Fehlermeldung zurück zum Menü.
# Liegt im COMMON-Block, damit auch die extrahierten Einzelscripte
# die Abbruch-Kennung auswerten können.
run_action() {
    local status=0
    (
        USER_ABORTED="n"
        rc=0
        "$@" || rc=$?
        if [[ "$USER_ABORTED" == "j" ]]; then
            exit 4
        fi
        exit "$rc"
    ) || status=$?
    if [[ "$status" -eq 4 ]]; then
        return 0
    fi
    if [[ "$status" -eq 42 ]]; then
        # 00-Signal: gesamtes Skript SOFORT beenden
        exit 42
    fi
    if [[ "$status" -ne 0 ]]; then
        err "$(t err_action_failed)"
    fi
    pause_key
}

#@@ENDBLOCK:COMMON
#@@BLOCK:PART
# ============================================================
# Partitionierer (interaktiv, Zahlen-Auswahl)
# ============================================================

PART_DISK=""

part_overview() {
    local disk="$PART_DISK"
    local SECTOR table fstype label tname mntp mib start size nr dev

    SECTOR="$(sector_size "$disk")"
    table="$(disk_table "$disk")"

    head_msg "$(t part_overview_title "$disk")"
    if [[ -z "$table" ]]; then
        err "$(t part_err_no_table "$disk")"
        misc "$(t part_info_create_table_hint)"
        return 0
    fi
    misc "$(t part_info_table "$(fstr "$table")" "$SECTOR")"

    while read -r start size nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        mib="$(sectors_to_mib "$size" "$SECTOR")"
        fstype="$(lsblk_val FSTYPE "$dev")"
        label="$(lsblk_val LABEL "$dev")"
        tname="$(lsblk_val PARTTYPENAME "$dev")"
        mntp="$(findmnt -nro TARGET -S "$dev" 2>/dev/null | head -n1 || true)"
        txt "$(t part_line "$nr" "$(fstr "$dev")" "$(fmt_mib "$mib")" "${fstype:-raw}" "${tname:-$(t part_unknown)}${label:+$(t part_label "$label")}${mntp:+$(t part_mounted "$mntp")}")"
    done < <(part_regions "$disk")

    misc "$(t part_free_areas)"
    local gcount=0 gs ge gmib
    while read -r gs ge; do
        [[ -n "$gs" ]] || continue
        gcount=$((gcount + 1))
        gmib="$(sectors_to_mib $((ge - gs + 1)) "$SECTOR")"
        misc "$(t part_free_line "$(fmt_mib "$gmib")" "$(gap_lage "$disk" "$gs" "$ge")")"
    done < <(compute_gaps "$disk" || true)
    if (( gcount == 0 )); then
        misc "$(t part_no_free)"
    fi
    return 0
}

part_reread() {
    local disk="$PART_DISK"
    udevadm settle 2>/dev/null || true
    blockdev --rereadpt "$disk" 2>/dev/null || true
    partprobe "$disk" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
}

part_newtable() {
    local disk="$PART_DISK"
    head_msg "$(t part_newtable_title "$disk")"

    if ! menu_select "$(t part_menu_table_type)" \
        "$(t part_opt_gpt)" \
        "$(t part_opt_mbr)"; then
        return 0
    fi
    local kind="$MENU_NR"

    err "$(t part_err_wipe "$(fstr "$disk")")"
    confirm_ja_nein || { misc "$(t part_abort_nothing)"; return 0; }

    misc "$(t part_info_wiping)"
    wipefs --all --force "$disk" >/dev/null 2>&1 || true

    # Wichtig: die Tabelle über eine "label:"-Scriptzeile auf stdin anlegen.
    # "sfdisk --label <typ> <gerät>" mit leerem stdin (EOF) bricht mit
    # Fehler ab (exit 1), statt eine leere Tabelle zu erzeugen.
    # --no-reread/--no-tell-kernel: sfdisk schreibt nur auf die Platte; die
    # Kernel-Synchronisation übernimmt part_reread. Sonst bricht sfdisk ab,
    # wenn noch alte Partitionen im Kernel belegt sind (exit 1, obwohl die
    # Tabelle bereits korrekt geschrieben wurde).
    local sfd_out=""
    case "$kind" in
        1)
            misc "$(t part_info_creating_gpt)"
            if ! sfd_out="$(printf 'label: gpt\n' | sfdisk --force --no-reread --no-tell-kernel "$disk" 2>&1)"; then
                err "$(t part_err_gpt_failed)"
                printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
                return 1
            fi ;;
        2)
            misc "$(t part_info_creating_mbr)"
            if ! sfd_out="$(printf 'label: dos\n' | sfdisk --force --no-reread --no-tell-kernel "$disk" 2>&1)"; then
                err "$(t part_err_mbr_failed)"
                printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
                return 1
            fi ;;
    esac

    part_reread

    misc "$(t part_info_table_done)"
    part_overview
}

# Größe "512", "20G", "1.5T" -> Sektoren (Vielfaches von ALIGN); Ergebnis in SIZE_SECTORS
parse_size_sectors() {
    local s="$1" ALIGN="$2" SECTOR="$3" unit="" num mult
    while [[ -n "$s" ]]; do
        case "${s: -1}" in
            [0-9.,]) break ;;
            *) unit="${s: -1}$unit"; s="${s%?}" ;;
        esac
    done
    if [[ -z "$s" || "$s" == *[!0-9.,]* ]]; then
        return 1
    fi
    num="${s//,/.}"
    case "$unit" in
        ''|M|m|Mi|MiB|mi|mb) mult=1 ;;
        G|g|Gi|GiB|gi|gib) mult=1024 ;;
        T|t|Ti|TiB|ti|tib) mult=1048576 ;;
        K|k|Ki|KiB) mult=0.0009765625 ;;
        *) return 1 ;;
    esac
    local mib sect
    mib="$(awk -v n="$num" -v m="$mult" 'BEGIN{printf "%.3f", n*m}')"
    sect="$(awk -v m="$mib" -v sec="$SECTOR" 'BEGIN{printf "%d", int(m*1048576/sec)}')"
    [[ "$sect" =~ ^[0-9]+$ ]] || return 1
    sect=$((sect / ALIGN * ALIGN))
    if (( sect < ALIGN )); then
        return 1
    fi
    SIZE_SECTORS="$sect"
    return 0
}

part_create() {
    local disk="$PART_DISK"
    head_msg "$(t part_create_title "$disk")"

    local table
    table="$(disk_table "$disk")"
    if [[ -z "$table" ]]; then
        err "$(t part_err_no_table2)"
        return 1
    fi

    local SECTOR ALIGN
    SECTOR="$(sector_size "$disk")"
    ALIGN=$((1048576 / SECTOR))

    # ---- Zweck (Presets) ----
    local -a purposes=()
    purposes+=("$(t part_purpose_linux_data)")
    purposes+=("$(t part_purpose_esp)")
    if [[ "$table" == "gpt" ]]; then
        purposes+=("$(t part_purpose_biosboot)")
    else
        purposes+=("$(t part_purpose_extended)")
    fi
    purposes+=("$(t part_purpose_swap)")
    purposes+=("$(t part_purpose_ntfs)")
    purposes+=("$(t part_purpose_fat32)")
    purposes+=("$(t part_purpose_raw)")

    menu_select "$(t part_menu_purpose)" "${purposes[@]}" || return 0
    local purpose="$MENU_NR"

    # ---- freien Bereich automatisch wählen ----
    # Keine Auswahl mehr: das Script benutzt automatisch den größten
    # freien Bereich (die Übersicht zeigt alle freien Bereiche).
    local -a gapstarts=() gapends=()
    local gs ge
    while read -r gs ge; do
        [[ -n "$gs" ]] || continue
        gapstarts+=("$gs")
        gapends+=("$ge")
    done < <(compute_gaps "$disk" || true)

    if [[ "${#gapstarts[@]}" -eq 0 ]]; then
        err "$(t part_err_no_free "$disk")"
        return 1
    fi

    local gsel=0 gsize=$((gapends[0] - gapstarts[0]))
    local idx
    for idx in "${!gapstarts[@]}"; do
        if (( gapends[idx] - gapstarts[idx] > gsize )); then
            gsel="$idx"
            gsize=$((gapends[idx] - gapstarts[idx]))
        fi
    done
    if [[ "${#gapstarts[@]}" -gt 1 ]]; then
        warn "$(t part_warn_multiple_gaps)"
    fi
    local gstart="${gapstarts[$gsel]}" gend="${gapends[$gsel]}"
    local gmib
    gmib="$(sectors_to_mib $((gend - gstart + 1)) "$SECTOR")"
    misc "$(t part_info_free_auto "$(fmt_mib "$gmib")" "$(gap_lage "$disk" "$gstart" "$gend")")"

    # ---- Zweck-Vorgaben (GPT-GUIDs bzw. MBR-Typcodes) ----
    local def_mib="" ptype="" fs=""
    case "$purpose" in
        1)
            if [[ "$table" == "gpt" ]]; then ptype="0FC63DAF-8483-4772-8E79-3D69D8477DE4"; else ptype="83"; fi
            fs="ext4" ;;
        2)
            if [[ "$table" == "gpt" ]]; then ptype="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"; else ptype="ef"; fi
            def_mib="512" fs="vfat" ;;
        3)
            if [[ "$table" == "gpt" ]]; then
                def_mib="2" ptype="21686148-6449-6E6F-744E-656564454649"
            else
                ptype="5"
            fi ;;
        4)
            if [[ "$table" == "gpt" ]]; then ptype="0657FD6D-A4AB-43C4-84E5-0933C84B4F4F"; else ptype="82"; fi
            fs="swap" ;;
        5)
            if [[ "$table" == "gpt" ]]; then ptype="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"; else ptype="07"; fi
            fs="ntfs" ;;
        6)
            if [[ "$table" == "gpt" ]]; then ptype="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"; else ptype="0c"; fi
            fs="vfat" ;;
        7)
            if [[ "$table" == "gpt" ]]; then ptype="0FC63DAF-8483-4772-8E79-3D69D8477DE4"; else ptype="83"; fi
            fs="" ;;
    esac

    # ---- Größe ----
    # Sicherheitsreserve: es bleibt IMMER mindestens 1 MiB (ALIGN Sektoren)
    # unangetastet frei. Partitionen, die exakt bis an das Ende des freien
    # Bereichs bzw. der Platte reichen, führen sonst zu sfdisk-/mkfs-Fehlern.
    local max_sect=$((gend - gstart + 1))
    local usable_sect=$(((max_sect - ALIGN) / ALIGN * ALIGN))
    if (( usable_sect < ALIGN )); then
        err "$(t part_err_gap_too_small)"
        return 1
    fi
    local max_mib
    max_mib="$(sectors_to_mib "$usable_sect" "$SECTOR")"
    local size_input="" sect
    while :; do
        ask_string "$(t part_q_size "$(fmt_mib "$max_mib")")" "$def_mib" || return 0
        size_input="$ANSWER"
        if [[ -z "$size_input" ]]; then
            sect="$usable_sect"
            break
        fi
        if parse_size_sectors "$size_input" "$ALIGN" "$SECTOR"; then
            sect="$SIZE_SECTORS"
            break
        fi
        misc "$(t part_err_bad_size)"
    done
    if (( sect > usable_sect )); then
        err "$(t part_err_size_too_big "$(fmt_mib "$max_mib")")"
        return 1
    fi

    # ---- Position: automatisch am Anfang des freien Bereichs ----
    local start="$gstart"

    # ---- MBR: primär/logisch/erweitert prüfen ----
    local sfd_line="start=$start, size=$sect, type=$ptype"
    if [[ "$table" != "gpt" && "$ptype" != "5" ]]; then
        local nprim=0 has_ext="n" nr
        while read -r nr; do
            [[ -n "$nr" ]] || continue
            if (( nr <= 4 )); then
                nprim=$((nprim + 1))
                if part_is_extended "$(part_prefix "$disk")$nr"; then has_ext="j"; fi
            fi
        done < <(part_nrs "$disk")
        if (( nprim >= 4 )) && [[ "$has_ext" != "j" ]]; then
            err "$(t part_err_mbr_slots)"
            return 1
        fi
        # Start im erweiterten Bereich -> sfdisk legt automatisch logisch an
    fi

    # ---- anlegen ----
    local nrs_before new_nr="" new_dev
    nrs_before="$(part_nrs "$disk")"

    misc "$(t part_info_creating_part "$sfd_line")"
    # --no-reread/--no-tell-kernel: sfdisk schreibt nur auf die Platte; die
    # Kernel-Synchronisation übernimmt part_reread danach. Sonst bricht
    # sfdisk ab, wenn noch alte Partitionen im Kernel belegt sind
    # (exit 1, obwohl die Tabelle bereits korrekt geschrieben wurde).
    local sfd_out=""
    if ! sfd_out="$(printf '%s\n' "$sfd_line" | sfdisk --force --no-reread --no-tell-kernel --append "$disk" 2>&1)"; then
        part_reread
        # Auch bei sfdisk-Fehler kann die Partition bereits auf der Platte
        # liegen (z. B. wenn nur der Kernel-Sync fehlschlug) - nachsehen.
        if [[ -z "$(comm -13 <(printf '%s\n' "$nrs_before") <(part_nrs "$disk") || true)" ]]; then
            err "$(t part_err_sfdisk_failed)"
            printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
            return 1
        fi
        warn "$(t part_warn_sfdisk_anyway)"
        printf '%s\n' "$sfd_out" | sed 's/^/  /' >&2
    fi
    part_reread

    # neue Nummer ermitteln (Differenz der Nummernmengen)
    local new_list nr
    new_list="$(comm -13 <(printf '%s\n' "$nrs_before") <(part_nrs "$disk") || true)"
    while read -r nr; do
        new_nr="$nr"
    done <<< "$new_list"
    if [[ -z "$new_nr" ]]; then
        while read -r nr; do
            new_nr="$nr"
        done < <(part_nrs "$disk")
    fi
    if [[ -z "$new_nr" ]]; then
        err "$(t part_err_new_nr)"
        return 1
    fi
    new_dev="$(part_prefix "$disk")$new_nr"

    # auf Erscheinen des Geräteknotens warten
    local i
    for i in {1..20}; do
        if [[ -b "$new_dev" ]]; then break; fi
        sleep 1
        part_reread
    done
    if [[ ! -b "$new_dev" ]]; then
        warn "$(t part_warn_devnode "$(fstr "$new_dev")")"
    fi

    misc "$(t part_info_new_part "$(fstr "$new_dev")")"

    # ---- Dateisystem ----
    if [[ -n "$fs" ]]; then
        if confirm_yes "$(t part_q_format_now "$fs")"; then
            make_fs "$new_dev" "$fs"
        fi
    fi

    part_overview
}

part_delete() {
    local disk="$PART_DISK"
    head_msg "$(t part_delete_title "$disk")"

    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_info_no_parts)"
        return 0
    fi

    local -a opts=() nrsel=()
    local nr dev mib SECTOR fstype sz
    SECTOR="$(sector_size "$disk")"
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        if dev_is_mounted "$dev"; then
            opts+=("$(t part_opt_mounted_ro "$dev")")
        else
            sz="$(part_regions "$disk" | awk -v n="$nr" '$3 == n {print $2; exit}')"
            [[ "$sz" =~ ^[0-9]+$ ]] || sz=0
            mib="$(sectors_to_mib "$sz" "$SECTOR")"
            fstype="$(lsblk_val FSTYPE "$dev")"
            opts+=("$dev  $(fmt_mib "$mib")  ${fstype:-raw}")
        fi
        nrsel+=("$nr")
    done <<< "$nrs"

    menu_select "$(t part_menu_delete)" "${opts[@]}" || return 0
    local sel_nr="${nrsel[$((MENU_NR - 1))]}"
    local sel_dev
    sel_dev="$(part_prefix "$disk")$sel_nr"

    if dev_is_mounted "$sel_dev"; then
        err "$(t part_err_mounted_delete "$(fstr "$sel_dev")")"
        return 1
    fi

    err "$(t part_err_deleting "$(fstr "$sel_dev")")"
    confirm_ja_nein || { misc "$(t ui_aborted)"; return 0; }

    if sfdisk --force --no-reread --no-tell-kernel --delete "$disk" "$sel_nr" >/dev/null 2>&1; then
        part_reread
        misc "$(t part_info_deleted)"
    else
        err "$(t part_err_delete_failed)"
    fi
    part_overview
}

part_format() {
    local disk="$PART_DISK"
    head_msg "$(t part_format_title "$disk")"

    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_info_no_parts)"
        return 0
    fi

    local -a opts=() devs=()
    local nr dev fstype
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        if part_is_extended "$dev"; then continue; fi
        fstype="$(lsblk_val FSTYPE "$dev")"
        opts+=("$dev  ${fstype:-raw}")
        devs+=("$dev")
    done <<< "$nrs"
    if [[ "${#devs[@]}" -eq 0 ]]; then
        misc "$(t part_info_no_formatable)"
        return 0
    fi

    menu_select "$(t part_menu_format)" "${opts[@]}" || return 0
    dev="${devs[$((MENU_NR - 1))]}"

    if dev_is_mounted "$dev"; then
        err "$(t part_err_mounted "$(fstr "$dev")")"
        return 1
    fi

    menu_select "$(t part_menu_fs)" "ext4" "FAT32" "swap" "NTFS" || return 0
    local fs
    case "$MENU_NR" in
        1) fs="ext4" ;;
        2) fs="vfat" ;;
        3) fs="swap" ;;
        4) fs="ntfs" ;;
    esac

    err "$(t part_err_formatting "$(fstr "$dev")" "$fs")"
    confirm_ja_nein || { misc "$(t ui_aborted)"; return 0; }

    make_fs "$dev" "$fs"
    part_overview
}

part_settype() {
    local disk="$PART_DISK"
    head_msg "$(t part_settype_title "$disk")"

    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_info_no_parts)"
        return 0
    fi

    local -a opts=() devs=()
    local nr dev type tname nr_new
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        tname="$(lsblk_val PARTTYPENAME "$dev")"
        opts+=("$(t part_opt_current "$dev" "${tname:-$(t part_unknown)}")")
        devs+=("$dev")
    done <<< "$nrs"

    menu_select "$(t part_menu_partition)" "${opts[@]}" || return 0
    dev="${devs[$((MENU_NR - 1))]}"
    nr_new="$(lsblk -nro PARTN "$dev" 2>/dev/null || true)"
    if [[ -z "$nr_new" ]]; then
        nr_new="${dev##*[a-z]}"
    fi

    if disk_is_gpt "$disk"; then
        menu_select "$(t part_menu_type_gpt)" \
            "$(t part_type_gpt_esp)" \
            "$(t part_type_gpt_bios)" \
            "$(t part_type_gpt_linux)" \
            "$(t part_type_gpt_swap)" \
            "$(t part_type_gpt_msdata)" \
            "$(t part_type_gpt_lvm)" || return 0
        case "$MENU_NR" in
            1) type="C12A7328-F81F-11D2-BA4B-00A0C93EC93B" ;;
            2) type="21686148-6449-6E6F-744E-656564454649" ;;
            3) type="0FC63DAF-8483-4772-8E79-3D69D8477DE4" ;;
            4) type="0657FD6D-A4AB-43C4-84E5-0933C84B4F4F" ;;
            5) type="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" ;;
            6) type="E6D6D379-F507-44C2-A23C-238F2A3DF928" ;;
        esac
    else
        menu_select "$(t part_menu_type_mbr)" \
            "$(t part_type_mbr_linux)" \
            "$(t part_type_mbr_efi)" \
            "$(t part_type_mbr_fat32)" \
            "$(t part_type_mbr_swap)" \
            "$(t part_type_mbr_ntfs)" \
            "$(t part_type_mbr_ext)" || return 0
        case "$MENU_NR" in
            1) type="83" ;;
            2) type="ef" ;;
            3) type="0c" ;;
            4) type="82" ;;
            5) type="07" ;;
            6) type="05" ;;
        esac
    fi

    if sfdisk --force --no-reread --no-tell-kernel --part-type "$disk" "$nr_new" "$type" >/dev/null 2>&1; then
        part_reread
        misc "$(t part_info_type_set "$(fstr "$type")" "$(fstr "$dev")")"
    else
        err "$(t part_err_type_failed)"
    fi
    part_overview
}

part_bootflag() {
    local disk="$PART_DISK"
    if disk_is_gpt "$disk"; then
        err "$(t part_err_bootflag_gpt)"
        return 1
    fi

    head_msg "$(t part_bootflag_title "$disk")"
    local nrs
    nrs="$(part_nrs "$disk")"
    if [[ -z "$nrs" ]]; then
        misc "$(t part_info_no_parts)"
        return 0
    fi

    local -a opts=() nrsel=()
    local nr dev
    while read -r nr; do
        [[ -n "$nr" ]] || continue
        dev="$(part_prefix "$disk")$nr"
        opts+=("$dev")
        nrsel+=("$nr")
    done <<< "$nrs"

    menu_select "$(t part_menu_bootflag)" "${opts[@]}" || return 0
    local nr_sel="${nrsel[$((MENU_NR - 1))]}"

    if sfdisk --force --no-reread --no-tell-kernel --activate "$disk" "$nr_sel" >/dev/null 2>&1; then
        part_reread
        misc "$(t part_info_bootflag_set "$(fstr "$(part_prefix "$disk")$nr_sel")")"
    else
        err "$(t part_err_bootflag_failed)"
    fi
    part_overview
}

# Werkzeuge des Partitionierers vorab prüfen; fehlende auf Wunsch
# per pacman nachinstallieren (Pakete: util-linux bzw. systemd).
part_check_tools() {
    local -a need=(sfdisk:util-linux wipefs:util-linux lsblk:util-linux
        findmnt:util-linux blockdev:util-linux udevadm:systemd)
    local -a missing=()
    local entry cmd pkg list=""

    for entry in "${need[@]}"; do
        cmd="${entry%%:*}"
        pkg="${entry#*:}"
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$entry")
            list+="$(t part_tool_pkg "$cmd" "$pkg")"
        fi
    done
    if [[ "${#missing[@]}" -eq 0 ]]; then
        return 0
    fi

    err "$(t part_err_missing_tools "$list")"
    for entry in "${missing[@]}"; do
        if ! ensure_tool "${entry%%:*}" "${entry#*:}" "$(t part_context)"; then
            die "$(t part_err_needs_tools "$list")"
        fi
    done
    return 0
}

part_menu() {
    # Plattenauswahl
    head_msg "$(t part_menu_title)"

    part_check_tools

    local live_dev
    live_dev="$(detect_live_medium || true)"

    local -a disks=() dopts=()
    local d size model table
    while read -r d size model; do
        [[ -n "$d" ]] || continue
        model="${model//\\x20/ }"
        if [[ -n "$live_dev" && "$d" == "$live_dev" ]]; then continue; fi
        case "${d##*/}" in
            loop*|zram*|ram*|sr*|fd*|dm-*|md*) continue ;;
        esac
        disks+=("$d")
        table="$(disk_table "$d")"
        dopts+=("$(t part_opt_disk "$d" "$size" "${model:-}" "${table:-$(t part_no_table)}")")
    done < <(lsblk -dpnro NAME,SIZE,MODEL 2>/dev/null)

    if [[ "${#disks[@]}" -eq 0 ]]; then
        err "$(t part_err_no_disk)"
        return 1
    fi

    menu_select "$(t part_menu_select_disk)" "${dopts[@]}" || return 0
    PART_DISK="${disks[$((MENU_NR - 1))]}"

    if [[ -n "$live_dev" ]]; then
        warn "$(t part_warn_live_excluded "$(fstr "$live_dev")")"
    fi

    while :; do
        if menu_select "$(t part_menu_main_title "$PART_DISK")" \
            "$(t part_menu_opt_overview)" \
            "$(t part_menu_opt_newtable)" \
            "$(t part_menu_opt_create)" \
            "$(t part_menu_opt_delete)" \
            "$(t part_menu_opt_format)" \
            "$(t part_menu_opt_settype)" \
            "$(t part_menu_opt_bootflag)"; then
            case "$MENU_NR" in
                1) part_overview ;;
                2) part_newtable ;;
                3) part_create ;;
                4) part_delete ;;
                5) part_format ;;
                6) part_settype ;;
                7) part_bootflag ;;
            esac
        else
            return 0
        fi
    done
}

#@@ENDBLOCK:PART
#@@BLOCK:INSTALL
# ============================================================
# Installer (installiert das gebootete Live-System)
# ============================================================

DISK=""
ASSUME_YES="n"

# SquashFS des Live-Systems finden (OverlayFS-Kette, dann /run/archiso)
root_overlay_lowerdirs() {
    local opts
    opts="$(findmnt -nro OPTIONS / 2>/dev/null || true)"
    if [[ -z "$opts" ]]; then
        return 1
    fi
    printf '%s\n' "$opts" | tr ',' '\n' | sed -n 's/^lowerdir=//p' | tr ':' '\n'
}

squash_from_overlay() {
    local mnt src back
    while IFS= read -r mnt; do
        [[ -n "$mnt" ]] || continue
        case "$mnt" in /*) ;; *) continue ;; esac
        [[ -d "$mnt" ]] || continue
        src="$(findmnt -no SOURCE --target "$mnt" 2>/dev/null || true)"
        [[ -n "$src" ]] || continue
        case "$src" in
            /dev/loop*) back="$(losetup -no BACK-FILE "$src" 2>/dev/null || true)" ;;
            *) back="$src" ;;
        esac
        if [[ -n "$back" && -f "$back" ]]; then
            printf '%s\n' "$back"
            return 0
        fi
    done < <(root_overlay_lowerdirs)
    return 1
}

find_esp_on_disk() {
    local disk="$1" line dev ptype fstype
    while IFS= read -r line; do
        [[ "$line" == *" : start="* ]] || continue
        dev="${line%% :*}"
        ptype="$(printf '%s\n' "$line" | sed -n 's/.*[ ,]type=\([^,]*\).*/\1/p' | tr '[:lower:]' '[:upper:]')"
        case "$ptype" in
            C12A7328-F81F-11D2-BA4B-00A0C93EC93B|EF|0XEF) ;;
            *) continue ;;
        esac
        [[ -b "$dev" ]] || continue
        fstype="$(lsblk -nro FSTYPE "$dev" 2>/dev/null | head -n1 || true)"
        if [[ -n "$fstype" && "$fstype" != "vfat" ]]; then
            continue
        fi
        printf '%s\n' "$dev"
        return 0
    done < <(sfdisk_dump "$disk")
    return 1
}

# Installationsziele auflisten (Platten + Partitionen, Live-Medium raus)
build_install_targets() {
    TARGETS=()
    TARGET_DESCR=()

    local live_dev
    live_dev="$(detect_live_medium || true)"

    local d dsize model p psize pfstype ptname pk m
    while read -r d dsize model; do
        [[ -n "$d" ]] || continue
        model="${model//\\x20/ }"
        case "${d##*/}" in
            loop*|zram*|ram*|sr*|fd*|dm-*|md*) continue ;;
        esac
        if [[ -n "$live_dev" && "$d" == "$live_dev" ]]; then
            continue
        fi

        TARGETS+=("$d")
        TARGET_DESCR+=("$(t install_descr_disk "$(fstr "$d")" "$dsize" "${model:+($model)}")")

        while read -r p; do
            [[ -n "$p" ]] || continue
            pk="$(lsblk -nro PKNAME "$p" 2>/dev/null | head -n1 || true)"
            if [[ "/dev/$pk" != "$d" ]]; then continue; fi
            if part_is_extended "$p"; then
                TARGET_DESCR+=("$(t install_descr_extended "$(fstr "$p")")")
                TARGETS+=("")
                continue
            fi
            if [[ -n "$live_dev" ]]; then
                case "$p" in
                    "$live_dev"*) continue ;;
                esac
            fi
            psize="$(lsblk -nro SIZE "$p" 2>/dev/null | head -n1 || true)"
            pfstype="$(lsblk -nro FSTYPE "$p" 2>/dev/null | head -n1 || true)"
            ptname="$(lsblk -nro PARTTYPENAME "$p" 2>/dev/null | head -n1 || true)"
            m="$(findmnt -nro TARGET -S "$p" 2>/dev/null | head -n1 || true)"
            TARGETS+=("$p")
            TARGET_DESCR+=("$(t install_descr_part "$(fstr "$p")" "$psize" "${pfstype:-$(t install_raw)}" "${ptname:--}" "${m:+$(t part_mounted "$m")}")")
        done < <(lsblk -pnro NAME "$d" 2>/dev/null)
    done < <(lsblk -dpnro NAME,SIZE,MODEL 2>/dev/null)
    return 0
}

show_targets() {
    build_install_targets
    head_msg "$(t install_targets_title)"
    local i n=0
    for i in "${!TARGETS[@]}"; do
        if [[ -n "${TARGETS[$i]}" ]]; then
            n=$((n + 1))
            misc "  $n  ${TARGET_DESCR[$i]}"
        else
            txt "     ${TARGET_DESCR[$i]}"
        fi
    done
    local live_dev
    live_dev="$(detect_live_medium || true)"
    if [[ -n "$live_dev" ]]; then
        txt "$(t install_info_live_excluded "$(fstr "$live_dev")")"
    fi
    return 0
}

choose_install_target() {
    build_install_targets

    local -a devs=() descs=()
    local i
    for i in "${!TARGETS[@]}"; do
        if [[ -n "${TARGETS[$i]}" ]]; then
            devs+=("${TARGETS[$i]}")
            descs+=("${TARGET_DESCR[$i]}")
        fi
    done

    if [[ "${#descs[@]}" -eq 0 ]]; then
        err "$(t install_err_no_targets)"
        return 1
    fi

    menu_select "$(t install_menu_choose_target)" "${descs[@]}" || return 1
    DISK="${devs[$((MENU_NR - 1))]}"
    return 0
}

do_install() {
    head_msg "$(t install_title)"

    if [[ -z "$DISK" ]]; then
        usage_install
        exit 2
    fi

    if [[ ! -b "$DISK" ]]; then
        die "$(t install_err_not_block "$DISK")"
    fi
    DISK="$(readlink -f "$DISK")"

    # Ziel: ganze Platte ODER einzelne Partition (lsblk TYPE entscheidet)
    local disk_type
    disk_type="$(lsblk -ndo TYPE "$DISK" 2>/dev/null || true)"

    PART_MODE="no"
    INSTALL_DISK="$DISK"

    case "$disk_type" in
        disk)
            PART_MODE="no" ;;
        part)
            PART_MODE="yes"
            INSTALL_DISK="$(lsblk -npro PKNAME "$DISK" 2>/dev/null | head -n1 || true)"
            if [[ -z "$INSTALL_DISK" || ! -b "$INSTALL_DISK" ]]; then
                die "$(t install_err_parent "$DISK")"
            fi
            case "$(lsblk -nro PARTTYPENAME "$DISK" 2>/dev/null || true)" in
                *[Ee]xtended*)
                    die "$(t install_err_extended "$DISK")" ;;
            esac ;;
        *)
            die "$(t install_err_neither "$DISK")" ;;
    esac

    case "${INSTALL_DISK##*/}" in
        loop*|zram*|ram*|sr*|fd*|dm-*|md*)
            die "$(t install_err_unsuitable "$INSTALL_DISK")" ;;
    esac

    # Firmware + Architektur
    FIRMWARE="BIOS"
    if [[ -d /sys/firmware/efi ]]; then
        FIRMWARE="UEFI"
    fi

    ARCH="$(uname -m)"
    [[ "$ARCH" == "x86_64" ]] || die "$(t install_err_arch "$ARCH")"

    # archiso-Live-System?
    if [[ ! -d /run/archiso ]]; then
        die "$(t install_err_no_archiso)"
    fi

    # SquashFS finden
    SQUASH="$(squash_from_overlay || true)"
    if [[ -z "$SQUASH" ]]; then
        SQUASH="$(find /run/archiso -maxdepth 6 -type f -name '*.sfs' -print 2>/dev/null | head -n1 || true)"
    fi
    if [[ -z "$SQUASH" || ! -f "$SQUASH" ]]; then
        err "$(t install_err_no_squash)"
        misc "$(t install_info_cmdline)"
        dump_misc cat /proc/cmdline
        misc "$(t install_info_files)"
        find /run/archiso -maxdepth 6 -print 2>/dev/null | head -n 50 | sed 's/^/  /' || true
        die "$(t install_err_no_airootfs)"
    fi
    txt "$(t install_info_squash "$(fstr "$SQUASH")")"

    # Live-Medium erkennen (3-stufig)
    LIVE_DEV="$(live_medium_from_bootmnt || true)"
    if [[ -z "$LIVE_DEV" ]]; then LIVE_DEV="$(live_medium_from_label || true)"; fi
    if [[ -z "$LIVE_DEV" ]]; then LIVE_DEV="$(live_medium_from_iso9660 || true)"; fi

    if [[ -n "$LIVE_DEV" && "$INSTALL_DISK" == "$LIVE_DEV" ]]; then
        die "$(t install_err_live_disk "$DISK")"
    fi

    txt "$(t install_info_target "$(fstr "$DISK")")"
    if [[ "$PART_MODE" == "yes" ]]; then
        txt "$(t install_info_mode_part "$(fstr "$INSTALL_DISK")")"
    else
        txt "$(t install_info_mode_disk)"
    fi
    txt "$(t install_info_firmware "$FIRMWARE")"
    txt "$(t install_info_arch "$ARCH")"
    txt "$(t install_info_live "$(fstr "${LIVE_DEV:-$(t install_not_detected)}")")"

    if [[ -z "$LIVE_DEV" ]]; then
        warn "$(t install_warn_live_unknown)"
        dump_misc cat /proc/cmdline
    fi

    # Ziel darf nicht gemountet sein
    if findmnt -rn -o SOURCE 2>/dev/null | grep -Eq "^${DISK}($|[0-9])"; then
        die "$(t install_err_mounted "$DISK")"
    fi

    # Größe
    local size_bytes size_mb=0 disk_model
    size_bytes="$(lsblk -dnbro SIZE "$DISK" 2>/dev/null | head -n1 || true)"
    if [[ "$size_bytes" =~ ^[0-9]+$ ]]; then
        size_mb=$((size_bytes / 1000000))
    fi
    (( size_mb >= 8000 )) || die "$(t install_err_too_small "$size_mb")"

    disk_model="$(lsblk -dno MODEL "$DISK" 2>/dev/null | sed 's/[[:space:]]*$//' || true)"
    txt "$(t install_info_size "$size_mb")"
    txt "$(t install_info_model "${disk_model:-$(t part_unknown)}")"

    # Sicherheitsabfrage
    head_msg "$(t install_head_all_data "$(fstr "$DISK")")"
    confirm_ja_nein || die "$(t err_aborted)"

    # Werkzeuge nachinstallieren (Paketnamen, keine Dubletten)
    local -a pkgs=()
    need_pkg() {
        # $1 = Befehl, $2 = Paket
        if ! command -v "$1" >/dev/null 2>&1; then
            case " ${pkgs[*]} " in
                *" $2 "*) ;;
                *) pkgs+=("$2") ;;
            esac
        fi
    }
    need_pkg unsquashfs squashfs-tools
    need_pkg mkfs.ext4 e2fsprogs
    need_pkg wipefs util-linux
    need_pkg blkid util-linux
    need_pkg lsblk util-linux
    need_pkg blockdev util-linux
    need_pkg mount util-linux
    need_pkg umount util-linux
    need_pkg findmnt util-linux
    need_pkg losetup util-linux
    need_pkg sfdisk util-linux
    need_pkg udevadm systemd
    need_pkg mkinitcpio mkinitcpio
    need_pkg grub-install grub
    need_pkg systemd-machine-id-setup systemd
    need_pkg sync coreutils
    if [[ "$FIRMWARE" == "UEFI" ]]; then
        need_pkg mkfs.vfat dosfstools
    fi

    if [[ "${#pkgs[@]}" -gt 0 ]]; then
        txt "$(t install_info_missing_tools)"
        misc "  pacman -S --needed --noconfirm ${pkgs[*]}"
        if ! pacman -S --needed --noconfirm "${pkgs[@]}"; then
            misc "$(t info_pacman_retry)"
            pacman -Sy --needed --noconfirm "${pkgs[@]}" \
                || die "$(t install_err_pkg_fail)"
        fi
    fi

    local c
    for c in unsquashfs mkfs.ext4 wipefs blkid lsblk blockdev \
             findmnt losetup sfdisk mkinitcpio grub-install; do
        if ! command -v "$c" >/dev/null 2>&1; then
            die "$(t install_err_pkg_still "$c")"
        fi
    done
    if [[ "$FIRMWARE" == "UEFI" ]] && ! command -v mkfs.vfat >/dev/null 2>&1; then
        die "$(t install_err_mkvfat_still)"
    fi

    # GRUB-Plattform
    if [[ "$FIRMWARE" == "BIOS" && ! -d /usr/lib/grub/i386-pc ]]; then
        die "$(t install_err_grub_bios)"
    fi
    if [[ "$FIRMWARE" == "UEFI" && ! -d /usr/lib/grub/x86_64-efi ]]; then
        die "$(t install_err_grub_uefi)"
    fi

    # Kernel-Quelle als Fallback
    KVER="$(uname -r)"
    if [[ ! -d "/usr/lib/modules/$KVER" ]]; then
        KVER="$(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
            | grep -Ev 'extramodules|^build$|^source$' | sort -V | tail -n1 || true)"
    fi
    HOST_KERNEL="/usr/lib/modules/${KVER}/vmlinuz"
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="/run/archiso/bootmnt/arch/boot/$(uname -m)/vmlinuz-linux"
    fi
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="$(find /run/archiso -maxdepth 6 -type f -name 'vmlinuz-linux' -print 2>/dev/null | head -n1 || true)"
    fi
    if [[ -z "$HOST_KERNEL" || ! -e "$HOST_KERNEL" ]]; then
        die "$(t install_err_no_kernel)"
    fi
    txt "$(t install_info_kernel_src "$(fstr "$HOST_KERNEL")")"

    # Kernel-Flavor bestimmen (linux / linux-lts / linux-hardened / linux-zen):
    # Die Dateinamen in /boot, das mkinitcpio-Preset und die GRUB-Menüeinträge
    # müssen zum Kernel-PAKET des Quell-Systems passen. Mit fest verdrahteten
    # generischen Namen (vmlinuz-linux) überlebt der erste Kernel-Update auf
    # dem Ziel nicht: pacman schreibt den neuen Kernel als
    # vmlinuz-linux-<flavor> und löscht die alten Module, während GRUB weiter
    # die alt gebliebene Kopie vmlinuz-linux bootet -> laufender Kernel ohne
    # passende Module (ufw: "Failed to initialize nft: Protocol not supported").
    local kpkg="linux" vmlinuz_name="vmlinuz-linux"
    local initramfs_name="initramfs-linux.img" fallback_name="initramfs-linux-fallback.img"
    local preset_name="linux.preset"
    case "$KVER" in
        *-hardened*)
            kpkg="linux-hardened" vmlinuz_name="vmlinuz-linux-hardened"
            initramfs_name="initramfs-linux-hardened.img"
            fallback_name="initramfs-linux-hardened-fallback.img"
            preset_name="linux-hardened.preset" ;;
        *-lts)
            kpkg="linux-lts" vmlinuz_name="vmlinuz-linux-lts"
            initramfs_name="initramfs-linux-lts.img"
            fallback_name="initramfs-linux-lts-fallback.img"
            preset_name="linux-lts.preset" ;;
        *-zen*)
            kpkg="linux-zen" vmlinuz_name="vmlinuz-linux-zen"
            initramfs_name="initramfs-linux-zen.img"
            fallback_name="initramfs-linux-zen-fallback.img"
            preset_name="linux-zen.preset" ;;
    esac
    txt "$(t install_info_kpkg "$kpkg")"

    # ---------------- Partitionieren (nur ganze Platte) ----------------
    if [[ "$PART_MODE" == "yes" ]]; then
        txt "$(t install_info_partmode_l1)"
        txt "$(t install_info_partmode_l2 "$(fstr "$INSTALL_DISK")")"
    else
        PART_PREFIX="$(part_prefix "$DISK")"
        P1="${PART_PREFIX}1"
        P2="${PART_PREFIX}2"

        txt "$(t install_info_partitioning "$(fstr "$DISK")" "$FIRMWARE")"
        wipefs --all --force "$DISK" >/dev/null 2>&1 || true

        if [[ "$FIRMWARE" == "UEFI" ]]; then
            misc "$(t install_info_gpt_auto)"
            if ! printf 'label: gpt\nname="ESP", size=512MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\nname="Root", type=0FC63DAF-8483-4772-8E79-3D69D8477DE4\n' \
                | sfdisk --force --no-reread --no-tell-kernel "$DISK" >/dev/null; then
                die "$(t install_err_part_gpt)"
            fi
        else
            misc "$(t install_info_mbr_auto)"
            if ! printf 'label: dos\nstart=1MiB, type=83, bootable\n' \
                | sfdisk --force --no-reread --no-tell-kernel "$DISK" >/dev/null; then
                die "$(t install_err_part_mbr)"
            fi
        fi

        sync
        udevadm settle 2>/dev/null || true
        blockdev --rereadpt "$DISK" >/dev/null 2>&1 || true
        local i
        for i in {1..20}; do
            if [[ -b "$P1" ]]; then break; fi
            sleep 1
            udevadm settle 2>/dev/null || true
            blockdev --rereadpt "$DISK" >/dev/null 2>&1 || true
        done
        [[ -b "$P1" ]] || die "$(t install_err_p_missing "$P1")"
        if [[ "$FIRMWARE" == "UEFI" && ! -b "$P2" ]]; then
            die "$(t install_err_p_missing "$P2")"
        fi

        misc "$(t install_info_partitions)"
        dump_misc lsblk -o NAME,SIZE,FSTYPE,TYPE "$DISK"
    fi

    # ---------------- Formatieren ----------------
    txt "$(t install_info_formatting)"

    if [[ "$PART_MODE" == "yes" ]]; then
        txt "$(t install_info_formatting_part "$(fstr "$DISK")")"

        if swapon --show=NAME --noheadings 2>/dev/null | grep -Fxq "$DISK"; then
            misc "$(t install_info_swap_off)"
            if ! swapoff "$DISK" 2>/dev/null; then
                die "$(t install_err_swap_off "$DISK")"
            fi
        fi

        wipefs -a "$DISK" >/dev/null 2>&1 || true
        mkfs.ext4 -q -F -L archroot "$DISK" \
            || die "$(t install_err_format_target)"

        ROOT_PART="$DISK"
        ESP_PART=""

        if [[ "$FIRMWARE" == "UEFI" ]]; then
            misc "$(t install_info_search_esp "$(fstr "$INSTALL_DISK")")"
            ESP_PART="$(find_esp_on_disk "$INSTALL_DISK" || true)"
            if [[ -z "$ESP_PART" ]]; then
                die "$(t install_err_no_esp "$INSTALL_DISK")"
            fi
            local esp_fstype
            esp_fstype="$(lsblk -nro FSTYPE "$ESP_PART" 2>/dev/null | head -n1 || true)"
            if [[ -z "$esp_fstype" ]]; then
                misc "$(t install_info_esp_unformatted "$(fstr "$ESP_PART")")"
                mkfs.vfat -F32 "$ESP_PART" || die "$(t install_err_esp_format)"
            elif [[ "$esp_fstype" != "vfat" ]]; then
                die "$(t install_err_esp_fstype "$ESP_PART" "$esp_fstype")"
            fi
        else
            if disk_is_gpt "$INSTALL_DISK" && ! disk_has_biosboot "$INSTALL_DISK"; then
                die "$(t install_err_no_biosboot "$INSTALL_DISK")"
            fi
        fi
    else
        if [[ "$FIRMWARE" == "UEFI" ]]; then
            wipefs -a "$P1" >/dev/null 2>&1 || true
            mkfs.vfat -F32 -n ARCHESP "$P1" || die "$(t install_err_esp_format2)"
            wipefs -a "$P2" >/dev/null 2>&1 || true
            mkfs.ext4 -q -F -L archroot "$P2" || die "$(t install_err_root_format)"
            ROOT_PART="$P2"
            ESP_PART="$P1"
        else
            wipefs -a "$P1" >/dev/null 2>&1 || true
            mkfs.ext4 -q -F -L archroot "$P1" || die "$(t install_err_root_format)"
            ROOT_PART="$P1"
            ESP_PART=""
        fi
    fi

    ROOT_UUID="$(blkid -s UUID -o value "$ROOT_PART" 2>/dev/null || true)"
    [[ -n "$ROOT_UUID" ]] || die "$(t install_err_root_uuid)"
    txt "$(t install_info_root_uuid "$ROOT_UUID")"

    if [[ -n "$ESP_PART" ]]; then
        ESP_UUID="$(blkid -s UUID -o value "$ESP_PART" 2>/dev/null || true)"
        [[ -n "$ESP_UUID" ]] || die "$(t install_err_esp_uuid)"
        txt "$(t install_info_esp_uuid "$ESP_UUID")"
    fi

    # ---------------- Mount ----------------
    txt "$(t install_info_mounting)"

    if mountpoint -q /mnt 2>/dev/null; then
        die "$(t install_err_mnt_mounted)"
    fi

    mkdir -p /mnt
    # Hängen gebliebene Teil-Mounts eines abgebrochenen Versuchs lösen.
    umount /mnt/boot/efi 2>/dev/null || true
    umount /mnt/boot 2>/dev/null || true
    if [[ -n "$(ls -A /mnt 2>/dev/null || true)" ]]; then
        misc "$(t install_info_clean_mnt)"
        find /mnt -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
    fi

    mount "$ROOT_PART" /mnt || die "$(t install_err_root_mount)"

    ROOT_MOUNTED="yes"
    ESP_MOUNTED=""

    cleanup_mounts() {
        sync 2>/dev/null || true
        if [[ "${ESP_MOUNTED:-}" == "yes" ]]; then umount /mnt/boot/efi 2>/dev/null || true; fi
        if [[ "${ROOT_MOUNTED:-}" == "yes" ]]; then umount /mnt 2>/dev/null || true; fi
    }
    trap cleanup_mounts EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP

    # ---------------- Entpacken ----------------
    txt "$(t install_info_unpack "$(fstr "/mnt")")"
    unsquashfs -no-progress -f -d /mnt "$SQUASH" || die "$(t install_err_unsquash)"

    # ESP erst JETZT einhängen (nach dem Entpacken); übernommene
    # ESP-Inhalte des Quellsystems vorher vom Root-FS entfernen.
    if [[ -n "$ESP_PART" ]]; then
        rm -rf -- /mnt/boot/efi
        mkdir -p /mnt/boot/efi
        mount "$ESP_PART" /mnt/boot/efi || die "$(t install_err_esp_mount)"
        ESP_MOUNTED="yes"
    fi

    # ---------------- Speicherplatz ----------------
    local avail_kb avail_mb=0
    avail_kb="$(df -Pk /mnt 2>/dev/null | awk 'NR==2 {print $4}' || true)"
    if [[ "$avail_kb" =~ ^[0-9]+$ ]]; then
        avail_mb=$((avail_kb / 1024))
    fi
    txt "$(t install_info_free_space "$avail_mb")"
    (( avail_mb >= 300 )) || die "$(t install_err_low_space)"

    # ---------------- Bootloader-Reste ----------------
    if [[ "$PART_MODE" == "no" && -d /mnt/boot/efi ]]; then
        misc "$(t install_info_remove_bootrest)"
        find /mnt/boot/efi -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
    fi

    # Live-Reste entfernen (in beiden Modi)
    rm -f -- /mnt/usr/local/bin/live-cow-resize \
        /mnt/etc/systemd/system/live-cow-resize.service \
        /mnt/etc/systemd/system/multi-user.target.wants/live-cow-resize.service 2>/dev/null || true

    # ---------------- Kernel sicherstellen ----------------
    txt "$(t install_info_check_kernel)"
    TARGET_KERNEL="/mnt/boot/$vmlinuz_name"
    if [[ ! -e "$TARGET_KERNEL" ]]; then
        mkdir -p /mnt/boot
        cp -L "$HOST_KERNEL" "$TARGET_KERNEL" || die "$(t install_err_kernel_copy)"
        misc "$(t install_info_kernel_copied "$(fstr "$HOST_KERNEL")")"
    fi
    txt "$(t install_info_kernel "$(fstr "$TARGET_KERNEL")")"

    local modbase=""
    if [[ -d /mnt/usr/lib/modules ]]; then modbase="/mnt/usr/lib/modules"; fi
    if [[ -z "$modbase" && -d /mnt/lib/modules ]]; then modbase="/mnt/lib/modules"; fi
    if [[ -z "$modbase" ]]; then
        die "$(t install_err_no_mods)"
    fi

    local kver_list
    kver_list="$(find "$modbase" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
        | grep -Ev 'extramodules|^build$|^source$' | sort -V || true)"

    KVER="$(uname -r)"
    if ! printf '%s\n' "$kver_list" | grep -qxF "$KVER"; then
        KVER="$(printf '%s\n' "$kver_list" | tail -n1 || true)"
    fi
    if [[ -z "$KVER" ]]; then
        die "$(t install_err_no_kver)"
    fi
    txt "$(t install_info_kver "$KVER")"

    if [[ ! -d "$modbase/$KVER" ]]; then
        warn "$(t install_warn_no_moddir "$modbase/$KVER")"
        find "$modbase" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null || true
        die "$(t install_err_no_matching_mods)"
    fi

    # ---------------- fstab ----------------
    txt "$(t install_info_fstab)"
    mkdir -p /mnt/etc
    {
        printf '# /etc/fstab\n'
        printf '# Erzeugt vom %s %s\n\n' "$SCRIPT_NAME" "$VERSION"
        printf 'UUID=%s  /  ext4  defaults  0 1\n' "$ROOT_UUID"
        if [[ -n "$ESP_PART" ]]; then
            # nofail + passno 0: Das Zielsystem ist eine Kopie des
            # Quell-Systems und hat moglicherweise kein fsck.vfat
            # (dosfstools) - ein Boot-fsck der ESP lieferte sonst
            # "Failed to mount /boot/efi" + "Dependency failed for Local
            # File Systems" und warf das System in den Emergency-Modus.
            # Die ESP wird nach der Installation nur vom Bootloader
            # gebraucht (GRUB liest sie selbst, vor systemd) und bei
            # Kernel-Updates nicht angetastet; sollte sie doch einmal
            # nicht einhängbar sein, bootet das System weiter.
            printf 'UUID=%s  /boot/efi  vfat  umask=0077,nofail  0 0\n' "$ESP_UUID"
        fi
    } > /mnt/etc/fstab

    # ---------------- machine-id ----------------
    txt "$(t install_info_machineid)"
    rm -f -- /mnt/etc/machine-id
    if command -v systemd-machine-id-setup >/dev/null 2>&1; then
        systemd-machine-id-setup --root=/mnt >/dev/null 2>&1 || true
    fi

    if [[ ! -s /mnt/etc/machine-id ]]; then
        MACHINE_ID="$(tr -d '-' < /proc/sys/kernel/random/uuid 2>/dev/null || true)"
        if [[ -z "$MACHINE_ID" ]]; then
            MACHINE_ID="$(head -c 16 /dev/urandom 2>/dev/null | od -An -tx1 | tr -d ' \n' || true)"
        fi
        if [[ -n "$MACHINE_ID" ]]; then
            printf '%s\n' "$MACHINE_ID" > /mnt/etc/machine-id
        fi
    fi
    [[ -s /mnt/etc/machine-id ]] || die "$(t install_err_machineid)"
    chmod 444 /mnt/etc/machine-id

    if [[ -e /mnt/var/lib/dbus/machine-id && ! -L /mnt/var/lib/dbus/machine-id ]]; then
        cp -f /mnt/etc/machine-id /mnt/var/lib/dbus/machine-id 2>/dev/null || true
    fi
    rm -f -- /mnt/var/lib/systemd/random-seed 2>/dev/null || true

    # ---------------- mkinitcpio ----------------
    if [[ -f /mnt/etc/mkinitcpio.conf ]]; then
        cp /mnt/etc/mkinitcpio.conf /mnt/etc/mkinitcpio.conf.archlive-orig
    fi
    rm -rf -- /mnt/etc/mkinitcpio.conf.d
    mkdir -p /mnt/etc/mkinitcpio.d

    cat > "/mnt/etc/mkinitcpio.d/$preset_name" <<PRESETEOF
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/$vmlinuz_name"
PRESETS=('default' 'fallback')
default_image="/boot/$initramfs_name"
fallback_image="/boot/$fallback_name"
fallback_options="-S autodetect"
PRESETEOF

    txt "$(t install_info_build_initramfs)"
    write_mki_conf() {
        # $1 = HOOKS-Liste
        {
            printf 'MODULES=()\nBINARIES=()\nFILES=()\n'
            printf 'HOOKS=(%s)\n' "$1"
            printf 'COMPRESSION="xz"\n'
        } > /mnt/etc/mkinitcpio.conf
    }

    # Hooks der Ziel-Konfiguration bereinigen: Die übernommene
    # /mnt/etc/mkinitcpio.conf bleibt auf dem ZIEL-System liegen. Steht
    # dort ein Hook, dessen Dateien im Zielsystem fehlen (z. B. ein
    # plymouth-Rest, dessen Paket entfernt wurde), schlägt der erste
    # Kernel-Update auf dem Zielsystem mit "Hook ... not found" fehl und
    # das System bootet nicht mehr. Deshalb: effektive HOOKS lesen und
    # gegen das Ziel-Dateisystem prüfen; fehlende Hooks entfernen,
    # gültige eigene Hooks (encrypt, btrfs, ...) erhalten.
    read_target_hooks() {
        # Läuft in einer Subshell (Prozess-Substitution), damit die
        # gesourcete Konfiguration keine Variablen des Installers ändert.
        # mkinitcpio wertet genau diese Dateien genauso aus (source).
        set -u
        HOOKS=()
        local f
        # Reihenfolge wie mkinitcpio: Hauptkonfiguration, dann Drop-ins
        # (mkinitcpio leitet das .d-Verzeichnis aus dem -c-Pfad ab).
        for f in /mnt/etc/mkinitcpio.conf /mnt/etc/mkinitcpio.conf.d/*.conf; do
            [[ -f "$f" ]] || continue
            # Quellpfad ist variabel - die Dateien sind die mkinitcpio-
            # Konfiguration, die mkinitcpio selbst ebenfalls source't.
            # shellcheck disable=SC1090
            source "$f"
        done
        printf '%s\n' "${HOOKS[@]:-}"
    }
    local -a target_hooks=() missing_hooks=() kept_hooks=()
    local h mh skip
    while read -r h; do
        [[ -n "$h" ]] || continue
        target_hooks+=("$h")
    done < <(read_target_hooks 2>/dev/null || true)

    for h in "${target_hooks[@]}"; do
        if [[ ! -e "/mnt/usr/lib/initcpio/install/$h" && ! -e "/mnt/etc/initcpio/install/$h" ]]; then
            missing_hooks+=("$h")
        fi
    done

    if [[ ${#missing_hooks[@]} -gt 0 ]]; then
        warn "$(t install_warn_bad_hooks "${missing_hooks[*]}")"
        warn "$(t install_warn_hooks_removed)"
        for h in "${target_hooks[@]}"; do
            skip="n"
            for mh in "${missing_hooks[@]}"; do
                if [[ "$h" == "$mh" ]]; then
                    skip="j"
                    break
                fi
            done
            if [[ "$skip" != "j" ]]; then
                kept_hooks+=("$h")
            fi
        done
        if [[ ${#kept_hooks[@]} -eq 0 ]]; then
            kept_hooks=("base" "udev" "autodetect" "modconf" "kms" "block" "filesystems" "keyboard" "fsck")
        fi
        write_mki_conf "${kept_hooks[*]}"
    fi

    if ! mkinitcpio -c /mnt/etc/mkinitcpio.conf -g "/mnt/boot/$initramfs_name" -k "$KVER"; then
        misc "$(t install_info_retry_hooks)"
        write_mki_conf "base udev autodetect modconf kms block filesystems keyboard fsck"
        mkinitcpio -c /mnt/etc/mkinitcpio.conf -g "/mnt/boot/$initramfs_name" -k "$KVER" \
            || die "$(t install_err_mkinitcpio)"
    fi

    mkinitcpio -c /mnt/etc/mkinitcpio.conf -g "/mnt/boot/$fallback_name" -k "$KVER" -S autodetect \
        || die "$(t install_err_fallback)"

    # ---------------- GRUB ----------------
    txt "$(t install_info_grub "$FIRMWARE")"
    mkdir -p /mnt/boot/grub

    if [[ "$FIRMWARE" == "BIOS" ]]; then
        grub-install \
            --target=i386-pc \
            --recheck \
            --boot-directory=/mnt/boot \
            "$INSTALL_DISK" || die "$(t install_err_grub_bios_fail)"
    else
        grub-install \
            --target=x86_64-efi \
            --efi-directory=/mnt/boot/efi \
            --boot-directory=/mnt/boot \
            --bootloader-id=ArchLive \
            --removable \
            --no-nvram \
            "$INSTALL_DISK" || die "$(t install_err_grub_uefi_fail)"
    fi

    txt "$(t install_info_grubcfg)"
    {
        printf 'set timeout=5\nset default=0\n\n'
        printf 'menuentry "Arch Linux (%s)" {\n' "$KVER"
        printf '    linux /boot/%s root=UUID=%s rw\n' "$vmlinuz_name" "$ROOT_UUID"
        printf '    initrd /boot/%s\n}\n\n' "$initramfs_name"
        printf 'menuentry "Arch Linux (%s) - Fallback" {\n' "$KVER"
        printf '    linux /boot/%s root=UUID=%s rw\n' "$vmlinuz_name" "$ROOT_UUID"
        printf '    initrd /boot/%s\n}\n' "$fallback_name"
    } > /mnt/boot/grub/grub.cfg

    if [[ "$FIRMWARE" == "UEFI" && ! -f /mnt/boot/efi/EFI/BOOT/BOOTX64.EFI ]]; then
        die "$(t install_err_bootx64)"
    fi

    sync

    head_msg "$(t install_success)"
    txt "$(t install_done_target "$(fstr "$DISK")")"
    txt "$(t install_done_firmware "$FIRMWARE")"
    txt "$(t install_done_root "$(fstr "$ROOT_PART")")"
    txt "$(t install_done_root_uuid "$ROOT_UUID")"
    txt ""
    txt "$(t install_done_next)"
    misc "$(t install_done_step1)"
    misc "$(t install_done_step2)"
    misc "$(t install_done_step3)"
    txt ""
    warn "$(t install_warn_secureboot)"
    return 0
}

install_interactive() {
    head_msg "$(t install_menu_title)"

    while :; do
        if menu_select "$(t install_menu_main)" \
            "$(t install_menu_opt_install)" \
            "$(t install_menu_opt_show)" \
            "$(t install_menu_opt_partfirst)"; then
            case "$MENU_NR" in
                1)
                    if choose_install_target; then
                        do_install
                    fi ;;
                2) show_targets ;;
                3) part_menu ;;
            esac
        else
            return 0
        fi
    done
}

#@@ENDBLOCK:INSTALL
#@@BLOCK:ISO
# ============================================================
# ISO-Builder (Live-ISO vom laufenden System)
# ============================================================

WORK=""
OUT=""
ISO_LABEL="ARCHLIVE"
# SquashFS-Kompression für den ISO-Bau.
# Erlaubt: xz, zstd, lzma, gzip, lzo, lz4
# Dieser Wert ist der Standard überall (interaktive Auswahl per Enter,
# Kommandozeile ohne -c). Hier direkt ändern, um den Standard festzulegen.
SQUASH_COMP="zstd"
EXTRA_EXCLUDES=()

LIVE_TREE=""
MERGED=""
OVL_UPPER="/run/liveiso-overlay-upper"
OVL_WORK="/run/liveiso-overlay-work"

iso_check_target() {
    local kind="$1" path="$2" fst
    if [[ -z "$path" ]]; then
        return 0
    fi
    mkdir -p "$path" 2>/dev/null || true
    case "$path" in
        # /boot/efi ist durch /boot/* bereits abgedeckt
        /|/boot|/boot/*|/efi|/efi/*|/etc|/etc/*|/usr|/usr/*|/var|/var/*|/bin|/bin/*|/sbin|/sbin/*|/lib|/lib/*|/lib64|/lib64/*|/root|/root/*|/dev|/dev/*|/proc|/proc/*|/sys|/sys/*)
            die "$(t iso_err_system_path "$kind" "$path")" ;;
    esac
    fst="$(findmnt -nro FSTYPE --target "$path" 2>/dev/null || true)"
    case "$fst" in
        vfat|msdos|fat*|exfat)
            die "$(t iso_err_fat_path "$kind" "$path")" ;;
    esac
}

kill_mount_users() {
    local base="$1" pid root cwd pidpath
    if [[ -z "$base" || ! -d "$base" ]]; then
        return 0
    fi
    for pidpath in /proc/[0-9]*; do
        [[ -d "$pidpath" ]] || continue
        pid="${pidpath#/proc/}"
        if [[ "$pid" == "$$" ]]; then continue; fi
        root="$(readlink "$pidpath/root" 2>/dev/null)" || continue
        case "$root" in
            "$base"|"$base"/*) kill -9 "$pid" 2>/dev/null || true; continue ;;
        esac
        cwd="$(readlink "$pidpath/cwd" 2>/dev/null)" || continue
        case "$cwd" in
            "$base"|"$base"/*) kill -9 "$pid" 2>/dev/null || true ;;
        esac
    done
    return 0
}

do_umount() {
    local m="$1" i
    mountpoint -q "$m" 2>/dev/null || return 0
    for i in 1 2 3; do
        if umount "$m" 2>/dev/null; then
            return 0
        fi
        sleep 1
    done
    warn "$(t iso_warn_mount_busy "$m")"
    if command -v fuser >/dev/null 2>&1; then fuser -vm "$m" 2>&1 || true; fi
    if umount -l "$m" 2>/dev/null; then
        warn "$(t iso_warn_lazy_umount "$m")"
    else
        err "$(t iso_err_umount "$m")"
    fi
    return 0
}

iso_cleanup_mounts() {
    txt "$(t iso_info_cleanup)"
    pkill -9 -f "mksquashfs.*$MERGED" 2>/dev/null || true
    kill_mount_users "$MERGED"
    do_umount "$MERGED"
    rm -rf -- "$OVL_UPPER" "$OVL_WORK" 2>/dev/null || true
    sync
}

# Eigentümer-Rechte nach dem Bau an den aufrufenden Nutzer zurückgeben
# (der Bau läuft als root - ohne chown liesen sich ISO und Ordner nicht
# umbenennen/verschieben). "$user:" setzt auch die Login-Gruppe.
give_back_ownership() {
    local user="${SUDO_USER:-}"
    if [[ -z "$user" ]]; then
        return 0
    fi
    if ! getent passwd "$user" >/dev/null; then
        warn "$(t iso_warn_user_missing "$user")"
        return 0
    fi
    local pfad
    for pfad in "$@"; do
        pfad="${pfad:?}"
        if [[ ! -e "$pfad" ]]; then
            continue
        fi
        if chown -R -- "$user:" "$pfad" 2>/dev/null; then
            misc "$(t iso_info_owner "$(fstr "$pfad")" "$user")"
        else
            err "$(t iso_err_owner "$(fstr "$pfad")" "$user" "$user" "$pfad")"
        fi
    done
}

do_iso_cleanup() {
    require_root
    if [[ -z "$WORK" ]]; then
        WORK="$(invoking_home)/remastern"
    fi
    if [[ -z "$WORK" || "$WORK" == "/" ]]; then
        die "$(t iso_err_workdir_invalid "$WORK")"
    fi
    LIVE_TREE="$WORK/live-iso-tree"
    MERGED="$WORK/MERGED"

    head_msg "$(t iso_cleanup_title "$(fstr "$WORK")")"
    iso_cleanup_mounts
    rm -rf -- "${LIVE_TREE:?}" "$OVL_UPPER" "$OVL_WORK" "$WORK/mkinitcpio-live.conf" \
        || die "$(t iso_err_rm_artifacts)"
    rmdir "$WORK" 2>/dev/null || true
    sync
    misc "$(t iso_info_cleanup_done)"
}

do_iso_build() {
    require_root

    if [[ -z "$WORK" ]]; then
        WORK="$(invoking_home)/remastern"
    fi
    if [[ -z "$WORK" || "$WORK" == "/" ]]; then
        die "$(t iso_err_workdir_invalid "$WORK")"
    fi
    case "$WORK" in
        *[[:space:]]*) die "$(t iso_err_workdir_spaces "$WORK")" ;;
    esac

    LIVE_TREE="$WORK/live-iso-tree"
    MERGED="$WORK/MERGED"

    # ISO-Ziel auflösen (VOR der Sicherheitsprüfung)
    local iso_name="archlive.iso" outdir="$WORK"
    if [[ -n "$OUT" ]]; then
        case "$OUT" in
            */) outdir="${OUT%/}" ;;
            *.iso|*.ISO|*.Iso)
                outdir="$(dirname -- "$OUT")"
                iso_name="$(basename -- "$OUT")" ;;
            *) outdir="$OUT" ;;
        esac
    fi
    iso_name="${iso_name##*/}"
    case "$iso_name" in
        *.iso|*.ISO|*.Iso) : ;;
        *) iso_name="${iso_name}.iso" ;;
    esac
    ISO_LABEL="${ISO_LABEL^^}"
    local output_iso="$outdir/$iso_name"

    iso_check_target "$(t iso_kind_workdir)" "$WORK"
    iso_check_target "$(t iso_kind_outdir)" "$outdir"

    mkdir -p "$outdir" || die "$(t iso_err_mkdir_outdir "$outdir")"

    trap iso_cleanup_mounts EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP

    # Pakete
    local -a build_pkgs=(mkinitcpio mkinitcpio-archiso squashfs-tools libisoburn grub mtools)
    local missing
    missing="$(pacman -T "${build_pkgs[@]}" 2>/dev/null || true)"
    if [[ -n "$missing" ]]; then
        local -a missing_arr=()
        read -r -a missing_arr <<< "$missing"
        txt "$(t iso_info_install_pkgs "${missing_arr[*]}")"
        if ! pacman -S --needed --noconfirm "${missing_arr[@]}"; then
            misc "$(t info_pacman_retry)"
            pacman -Sy --needed --noconfirm "${missing_arr[@]}" \
                || die "$(t iso_err_pkg_fail)"
        fi
    fi

    local t
    for t in mksquashfs mkinitcpio grub-mkrescue xorriso; do
        if ! command -v "$t" >/dev/null 2>&1; then
            die "$(t iso_err_tool_missing "$t")"
        fi
    done
    if [[ ! -e /usr/lib/initcpio/install/archiso || ! -e /usr/lib/initcpio/hooks/archiso ]]; then
        die "$(t iso_err_archiso_hooks)"
    fi

    # Freiplatz prüfen (nach mkdir, damit df das Ziel kennt)
    local free_gb
    free_gb="$(df -Pk "$WORK" 2>/dev/null | awk 'NR==2{print int($4/1048576)}' || true)"
    if [[ "$free_gb" =~ ^[0-9]+$ ]]; then
        if (( free_gb < 2 )); then
            die "$(t iso_err_low_space "$free_gb" "$WORK")"
        elif (( free_gb < 8 )); then
            warn "$(t iso_warn_low_space "$free_gb" "$WORK")"
        fi
    fi

    # OverlayFS verfügbar? (Kernel-Update ohne Neustart)
    if ! grep -qw overlay /proc/filesystems 2>/dev/null; then
        modprobe overlay 2>/dev/null || true
    fi
    if ! grep -qw overlay /proc/filesystems 2>/dev/null; then
        die "$(t iso_err_overlay "$(uname -r)")"
    fi

    # Volume-Label prüfen
    [[ -n "$ISO_LABEL" ]] || die "$(t iso_err_label_empty)"
    [[ "${#ISO_LABEL}" -le 32 ]] || die "$(t iso_err_label_long "$ISO_LABEL")"
    case "$ISO_LABEL" in
        *[!A-Za-z0-9._-]*) die "$(t iso_err_label_chars "$ISO_LABEL")" ;;
    esac

    # SquashFS-Kompression prüfen (einheitlich an einer Stelle, gilt für
    # Script-Standard, interaktive Auswahl und Kommandozeile)
    case "$SQUASH_COMP" in
        xz|zstd|lzma|gzip|lzo|lz4) : ;;
        *) die "$(t iso_err_bad_comp "$SQUASH_COMP")" ;;
    esac
    txt "$(t iso_info_comp "$SQUASH_COMP")"

    mkdir -p "$WORK" "$LIVE_TREE/boot/grub" \
        || die "$(t iso_err_mkdir_work)"

    MACH="$(uname -m)"
    if [[ "$MACH" != "x86_64" ]]; then
        warn "$(t iso_warn_arch "$MACH")"
    fi
    mkdir -p "$LIVE_TREE/arch/boot/$MACH" "$LIVE_TREE/arch/$MACH" \
        || die "$(t iso_err_tree)"

    # Kernel
    KVER="$(uname -r)"
    if [[ ! -d "/usr/lib/modules/$KVER" ]]; then
        local old_kver="$KVER"
        KVER="$(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
            | grep -Ev 'extramodules|^build$|^source$' | sort -V | tail -n1 || true)"
        warn "$(t iso_warn_kernel_fallback "$old_kver" "$KVER")"
    fi
    HOST_KERNEL="/usr/lib/modules/$KVER/vmlinuz"
    if [[ ! -e "$HOST_KERNEL" ]]; then
        HOST_KERNEL="/boot/vmlinuz-$KVER"
    fi
    if [[ ! -e "$HOST_KERNEL" ]]; then
        die "$(t iso_err_no_kernel "$KVER")"
    fi
    txt "$(t iso_info_kernel "$KVER" "$(fstr "$HOST_KERNEL")")"

    # Initramfs (archiso-Hook)
    misc "$(t iso_info_copy_kernel)"
    cp "$HOST_KERNEL" "$LIVE_TREE/arch/boot/$MACH/vmlinuz-linux" || die "$(t iso_err_kernel_copy)"

    local mki_conf="$WORK/mkinitcpio-live.conf"
    cat > "$mki_conf" <<MKIEOF
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev microcode modconf archiso block filesystems keyboard)
COMPRESSION="xz"
MKIEOF

    txt "$(t iso_info_initramfs)"
    mkinitcpio -c "$mki_conf" -g "$LIVE_TREE/arch/boot/$MACH/initramfs-linux.img" -k "$KVER" \
        || die "$(t iso_err_mkinitcpio)"
    chmod 644 "$LIVE_TREE/arch/boot/$MACH/vmlinuz-linux" "$LIVE_TREE/arch/boot/$MACH/initramfs-linux.img"

    # GRUB-Menü (kein "quiet"; archisolabel MUSS zum -volid passen)
    local base_params="archisobasedir=arch archisolabel=$ISO_LABEL noresume"

    add_entry() {
        local title="$1" extra="$2"
        {
            printf '\nmenuentry "Arch Linux Live - %s" {\n' "$title"
            printf '    linux /arch/boot/%s/vmlinuz-linux %s %s\n' "$MACH" "$base_params" "$extra"
            printf '    initrd /arch/boot/%s/initramfs-linux.img\n}\n' "$MACH"
        } >> "$LIVE_TREE/boot/grub/grub.cfg"
    }

    {
        printf 'insmod all_video\n'
        printf 'insmod gzio\n'
        printf 'set timeout=10\n'
        printf 'set default=0\n'
    } > "$LIVE_TREE/boot/grub/grub.cfg"

    add_entry "$(t grub_std)" ""
    add_entry "$(t grub_verbose)" "loglevel=7 ignore_loglevel"
    add_entry "$(t grub_copytoram)" "copytoram"
    add_entry "$(t grub_nomodeset)" "nomodeset"

    # OverlayFS (Schreibebenen im RAM - nie auf der echten Platte)
    txt "$(t iso_info_overlay)"
    rm -rf -- "$OVL_UPPER" "$OVL_WORK"
    mkdir -p "$OVL_UPPER" "$OVL_WORK" "$MERGED" || die "$(t iso_err_overlay_dirs)"
    if ! mount -t overlay overlay \
        -o "lowerdir=/,upperdir=$OVL_UPPER,workdir=$OVL_WORK" "$MERGED"; then
        die "$(t iso_err_overlay_mount)"
    fi
    if [[ ! -e "$MERGED/usr/bin" ]]; then
        do_umount "$MERGED"
        die "$(t iso_err_overlay_incomplete)"
    fi
    if [[ ! -e "$MERGED/sbin/init" && ! -e "$MERGED/usr/lib/systemd/systemd" ]]; then
        do_umount "$MERGED"
        die "$(t iso_err_systemd)"
    fi

    local other_parts
    other_parts="$(findmnt -rn -o TARGET,FSTYPE 2>/dev/null | awk \
        '$2 !~ /^(proc|sysfs|tmpfs|devtmpfs|devpts|squashfs|efivarfs|cgroup2|securityfs|pstore|bpf|debugfs|tracefs|configfs|mqueue|hugetlbfs|ramfs|autofs|binfmt_misc|overlay|fusectl|nsfs|vfat|iso9660)$/ && $1 ~ /^\/[^\/]/ && $1 != "/boot/efi" {print $1}' || true)"
    if [[ -n "$other_parts" ]]; then
        warn "$(t iso_warn_other_parts)"
        printf '%s\n' "$other_parts" | sed 's/^/   - /'
    fi

    # Bereinigungen nur im Image. KEIN Root-Eintrag in der fstab!
    printf '# Live-System: Root wird vom archiso-Hook eingebunden, fstab absichtlich leer.\n' \
        > "$MERGED/etc/fstab"
    if [[ -e "$MERGED/etc/crypttab" ]]; then
        : > "$MERGED/etc/crypttab"
    fi
    : > "$MERGED/etc/machine-id"
    if [[ -d "$MERGED/var/lib/dbus" ]]; then
        rm -f -- "$MERGED/var/lib/dbus/machine-id"
        ln -sf /etc/machine-id "$MERGED/var/lib/dbus/machine-id"
    fi

    # Overlay-Größen-Service (62,5 % RAM als cowspace)
    mkdir -p "$MERGED/usr/local/bin" "$MERGED/etc/systemd/system/multi-user.target.wants"
    cat > "$MERGED/usr/local/bin/live-cow-resize" <<'RSIZE'
#!/bin/bash
# Passt die Groesse des Live-Overlays an den vorhandenen RAM an.
total=$(awk '/MemTotal:/{print $2}' /proc/meminfo 2>/dev/null)
[ -n "$total" ] || exit 0
size=$(( total * 5 / 8 ))               # 62,5 % des RAM
[ "$size" -lt 262144 ] && size=262144   # mindestens 256 MB
mount -o remount,size="${size}k" /run/archiso/cowspace 2>/dev/null && \
    echo "Live-Overlay-Groesse: $(( size / 1024 )) MB"
RSIZE
    chmod 755 "$MERGED/usr/local/bin/live-cow-resize"
    cat > "$MERGED/etc/systemd/system/live-cow-resize.service" <<'RSVC'
[Unit]
Description=Live-Overlay-Groesse an den RAM anpassen
After=systemd-tmpfiles-setup.service
ConditionPathExists=/run/archiso/cowspace
[Service]
Type=oneshot
ExecStart=/usr/local/bin/live-cow-resize
[Install]
WantedBy=multi-user.target
RSVC
    ln -sf /etc/systemd/system/live-cow-resize.service \
        "$MERGED/etc/systemd/system/multi-user.target.wants/live-cow-resize.service" \
        || die "$(t iso_err_cow_service)"

    # SquashFS
    local -a excl=( "proc/*" "sys/*" "dev/*" "run/*" "tmp/*" "mnt/*" "media/*"
        "var/tmp/*" "var/log/*" "var/crash/*" "var/lib/systemd/coredump/*"
        "var/cache/pacman/pkg/*" "var/lib/systemd/random-seed"
        "lost+found" "cdrom" "swapfile" "swap.img" )

    local work_rel="${WORK#/}"
    if [[ -n "$work_rel" ]]; then
        excl+=("$work_rel")
    fi
    local p
    for p in "${EXTRA_EXCLUDES[@]}"; do
        excl+=("${p#/}")
    done

    txt "$(t iso_info_close_apps)"
    case "$SQUASH_COMP" in
        xz|lzma) txt "$(t iso_info_squash_xz "$SQUASH_COMP")" ;;
        *) txt "$(t iso_info_squash "$SQUASH_COMP")" ;;
    esac
    local new_squash="$LIVE_TREE/arch/$MACH/airootfs.sfs.new"
    rm -f -- "$new_squash"
    if ! mksquashfs "$MERGED" "$new_squash" -noappend -comp "$SQUASH_COMP" -b 1M -no-recovery \
        -wildcards -e "${excl[@]}"; then
        do_umount "$MERGED"
        die "$(t iso_err_mksquashfs)"
    fi
    sync
    mv -f "$new_squash" "$LIVE_TREE/arch/$MACH/airootfs.sfs" \
        || die "$(t iso_err_squash_mv)"

    if ! pacman -Q > "$LIVE_TREE/pacman-manifest.txt" 2>/dev/null; then
        warn "$(t iso_warn_manifest)"
    fi

    do_umount "$MERGED"
    rm -rf -- "$OVL_UPPER" "$OVL_WORK"

    # ISO bauen (kein "--" vor den xorriso-Optionen - s. grub-mkrescue --help;
    # unbekannte Argumente reicht grub-mkrescue an xorriso durch)
    txt "$(t iso_info_iso "$(fstr "$output_iso")")"
    rm -f -- "$output_iso"
    grub-mkrescue -o "$output_iso" "$LIVE_TREE" -volid "$ISO_LABEL" -iso-level 3 -J -R \
        || die "$(t iso_err_mkrescue)"
    [[ -s "$output_iso" ]] || die "$(t iso_err_no_iso)"

    # Besitzrechte: der GESAMTE Arbeitsordner (~/remastern inkl. aller
    # Unterordner und Dateien) gehört danach dem aufrufenden Nutzer -
    # liegt die ISO außerhalb (eigenes ISO-Ziel), bekommt auch sie die
    # Rechte. Die GUI macht nach dem Lauf zusätzlich ein chown auf
    # ~/remastern (Sicherheitsnetz, falls ein anderes WORK gewählt war).
    give_back_ownership "$WORK"
    if [[ "$output_iso" != "$WORK"/* ]]; then
        give_back_ownership "$output_iso"
    fi

    local iso_mb
    iso_mb="$(du -m "$output_iso" 2>/dev/null | cut -f1 || true)"
    head_msg "$(t iso_success)"
    txt "$(t iso_info_outpath "$(fstr "$output_iso")" "${iso_mb:-?}")"
    txt "$(t iso_info_done_kernel "$KVER")"
    txt "$(t iso_info_done_label "$ISO_LABEL")"
    warn "$(t iso_warn_secureboot)"
    printf '\n'
    head_msg "$(t iso_done_close)"
    return 0
}

# SquashFS-Kompression interaktiv wählen. Leerer Eingabedruck = Standard
# (SQUASH_COMP, im Script-Kopf einstellbar). Ergebnis in COMP_CHOICE.
choose_squash_comp() {
    local -a comp_algos=(xz zstd lzma gzip lzo lz4)
    local -a comp_descr=(
        "$(t comp_desc_xz)"
        "$(t comp_desc_zstd)"
        "$(t comp_desc_lzma)"
        "$(t comp_desc_gzip)"
        "$(t comp_desc_lzo)"
        "$(t comp_desc_lz4)"
    )
    local -a opts=()
    local i mark pick
    for i in "${!comp_algos[@]}"; do
        mark=""
        if [[ "${comp_algos[$i]}" == "$SQUASH_COMP" ]]; then
            mark="$(t comp_default_mark)"
        fi
        opts+=("$(printf '%-5s %s' "${comp_algos[$i]}" "${comp_descr[$i]}")${mark}")
    done
    head_msg "$(t comp_menu_title)"
    i=1
    for opt in "${opts[@]}"; do
        misc "  ${i}) ${opt}"
        i=$((i + 1))
    done
    misc "  00) $(t menu_quit)"
    while :; do
        printf '%s' "${C_TEXT}$(t menu_prompt_choice) ${C_MISC}$(t comp_prompt_range "${#comp_algos[@]}" "$SQUASH_COMP")${C_OFF}"
        get_input || return 1
        pick="${INPUT:-}"
        if [[ "$pick" == "00" ]]; then
            # 00 = GESAMTES Skript SOFORT beenden (Quit-All-Signal 42)
            quit_all
        fi
        if [[ -z "$pick" ]]; then
            COMP_CHOICE="$SQUASH_COMP"
            return 0
        fi
        if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#comp_algos[@]} )); then
            COMP_CHOICE="${comp_algos[$((pick - 1))]}"
            return 0
        fi
        misc "$(t comp_err_bad "${#comp_algos[@]}")"
    done
}

iso_interactive() {
    head_msg "$(t iso_menu_title)"

    ask_string "$(t iso_q_workdir)" "$(invoking_home)/remastern" || return 0
    WORK="$ANSWER"

    ask_string "$(t iso_q_label)" "ARCHLIVE" || return 0
    ISO_LABEL="$ANSWER"

    choose_squash_comp || return 0
    SQUASH_COMP="$COMP_CHOICE"

    ask_string "$(t iso_q_out)" "" || return 0
    OUT="$ANSWER"

    local excl_input=""
    ask_string "$(t iso_q_excludes)" "" || return 0
    excl_input="$ANSWER"
    EXTRA_EXCLUDES=()
    if [[ -n "$excl_input" ]]; then
        read -r -a EXTRA_EXCLUDES <<< "$excl_input"
    fi

    txt "$(t iso_info_summary)"
    misc "$(t iso_sum_workdir "$(fstr "$WORK")")"
    misc "$(t iso_sum_label "$ISO_LABEL")"
    misc "$(t iso_sum_comp "$SQUASH_COMP")"
    misc "$(t iso_sum_target "$(fstr "${OUT:-$WORK/archlive.iso}")")"
    if [[ "${#EXTRA_EXCLUDES[@]}" -gt 0 ]]; then
        misc "$(t iso_sum_excludes "${EXTRA_EXCLUDES[*]}")"
    else
        misc "$(t iso_sum_no_excludes)"
    fi

    confirm_yes "$(t iso_q_start)" || { misc "$(t ui_aborted)"; return 0; }
    do_iso_build
}

#@@ENDBLOCK:ISO
# ============================================================
# Hauptmenü
# ============================================================

main_menu() {
    INTERACTIVE="j"
    while :; do
        if menu_select "$(t menu_main_title "$VERSION")" \
            "$(t menu_opt_iso)" \
            "$(t menu_opt_install)" \
            "$(t menu_opt_part)" \
            "$(t menu_opt_cleanup)" \
            "$(t menu_opt_targets)"; then
            case "$MENU_NR" in
                1) run_action iso_interactive ;;
                2) run_action install_interactive ;;
                3) run_action part_menu ;;
                4) run_action do_iso_cleanup_interactive ;;
                5) run_action show_targets_menu ;;
            esac
        else
            misc "$(t menu_bye)"
            return 0
        fi
    done
}

show_targets_menu() {
    show_targets
}

do_iso_cleanup_interactive() {
    (
        ask_string "$(t iso_q_workdir)" "$(invoking_home)/remastern" || exit 0
        WORK="$ANSWER"
        confirm_yes "$(t cleanup_q_confirm "$(fstr "$WORK")")" || exit 0
        do_iso_cleanup
    )
}

# ============================================================
# Hilfe
# ============================================================

usage() {
    case "$SPRACHE" in
    EN)
        cat <<HILFE
${C_HEAD}$SCRIPT_NAME $VERSION - build live ISO + install + partition${C_OFF}

${C_TEXT}One tool for everything around the Arch live ISO:${C_OFF}
${C_MISC}  - create a live ISO of the RUNNING system (BIOS + UEFI bootable)
  - install the booted live system to a disk or partition
    (incl. bootloader, BIOS + UEFI automatically)
  - partition disks (interactive, number selection)

${C_HEAD}Usage${C_OFF}
${C_MISC}  ${C_FILE}$SCRIPT_NAME${C_OFF}${C_MISC}                       interactive main menu
  ${C_FILE}$SCRIPT_NAME iso [OPTIONS] [TARGET]     create live ISO
  ${C_FILE}$SCRIPT_NAME install -d DEVICE [-y]     install live system
  ${C_FILE}$SCRIPT_NAME part                      partitioner (interactive)
  ${C_FILE}$SCRIPT_NAME cleanup [-w DIR]         remove ISO build artifacts
  ${C_FILE}$SCRIPT_NAME targets                   show installation targets
  ${C_FILE}$SCRIPT_NAME -x DIR${C_OFF}${C_MISC}                   extract part/iso/install
                                        as standalone scripts
  ${C_FILE}$SCRIPT_NAME -V${C_MISC}                       version

${C_HEAD}Exit codes${C_OFF}
${C_MISC}  0 = success, 2 = wrong arguments, 3 = error/abort.

${C_HEAD}install - install the live system${C_OFF}
${C_MISC}  Runs INSIDE the booted archiso live system and needs root.
  Without ${C_FILE}-d${C_MISC} a target is asked for interactively in the terminal.
  For a partition, ONLY that partition is formatted - the
  partition table stays unchanged. Requirements:
  UEFI: ESP on the same disk; BIOS + GPT: BIOS boot partition.

  Options:
    ${C_FILE}-d, --disk DEVICE${C_OFF}   ${C_MISC}whole disk OR single partition
    ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}skip the confirmation prompt (server use)
    ${C_FILE}-h, --help${C_OFF}         ${C_MISC}this help

  Examples (server, without prompts):
    ${C_FILE}$SCRIPT_NAME install -d /dev/sda -y${C_OFF}
    ${C_FILE}$SCRIPT_NAME install -d /dev/nvme0n1p2 -y${C_OFF}

${C_HEAD}iso - create the live ISO${C_OFF}
${C_MISC}  Creates a bootable live ISO of the RUNNING system (root privileges,
  Arch-based system, working directory without spaces).

  Options:
    ${C_FILE}-w, --work DIR${C_OFF}       ${C_MISC}working directory [default: ~/remastern]
    ${C_FILE}-o, --output PATH${C_OFF}     ${C_MISC}target path/directory of the ISO (like TARGET)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}volume label [default: ARCHLIVE]
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}squashfs compression [default: gzip]
    ${C_FILE}-e, --exclude PATHS${C_OFF}   ${C_MISC}additionally exclude (space-separated)

  Examples:
    ${C_FILE}$SCRIPT_NAME iso /srv/iso/rescue.iso${C_OFF}
    ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_OFF}

${C_HEAD}cleanup / part / targets${C_OFF}
${C_MISC}  ${C_FILE}cleanup${C_MISC} unmounts mounts and deletes build artifacts (${C_FILE}-w DIR${C_MISC}).
  ${C_FILE}part${C_MISC}     interactive partitioner: new table (GPT/MBR),
           create partitions (purpose presets), delete, format,
           set type (ESP/BIOS boot/swap), boot flag - all by number.
  ${C_FILE}targets${C_MISC}  lists possible installation targets (read-only).

${C_HEAD}Color scheme${C_OFF}
${C_MISC}  Headings bright cyan, text bright yellow, files/paths bright magenta,
  everything else bright green (errors red). Turn off: ${C_FILE}-nc, --no-color${C_MISC} or ${C_FILE}NO_COLOR=1${C_OFF}

${C_TEXT}WARNING: Installation and partitioning delete data irreversibly!${C_OFF}
HILFE
        ;;
    *)
        cat <<HILFE
${C_HEAD}$SCRIPT_NAME $VERSION - Live-ISO bauen + installieren + partitionieren${C_OFF}

${C_TEXT}Ein Werkzeug für alle Aufgaben rund um die Arch-Live-ISO:${C_OFF}
${C_MISC}  - Live-ISO vom LAUFENDEN System erstellen (BIOS + UEFI bootbar)
  - das gebootete Live-System auf eine Festplatte oder Partition
    installieren (inkl. Bootloader, BIOS + UEFI automatisch)
  - Festplatten partitionieren (interaktiv, Zahlen-Auswahl)

${C_HEAD}Aufruf${C_OFF}
${C_MISC}  ${C_FILE}$SCRIPT_NAME${C_OFF}${C_MISC}                       interaktives Hauptmenü
  ${C_FILE}$SCRIPT_NAME iso [OPTIONEN] [ZIEL]     Live-ISO erstellen
  ${C_FILE}$SCRIPT_NAME install -d GERÄT [-y]     Live-System installieren
  ${C_FILE}$SCRIPT_NAME part                      Partitionierer (interaktiv)
  ${C_FILE}$SCRIPT_NAME cleanup [-w VERZ]         ISO-Bau-Artefakte entfernen
  ${C_FILE}$SCRIPT_NAME targets                   Installationsziele anzeigen
  ${C_FILE}$SCRIPT_NAME -x VERZ${C_OFF}${C_MISC}                  part/iso/install als
                                        eigenständige Skripte ausgeben
  ${C_FILE}$SCRIPT_NAME -V${C_MISC}                       Version

${C_HEAD}Exit-Codes${C_OFF}
${C_MISC}  0 = Erfolg, 2 = falsche Argumente, 3 = Fehler/Abbruch.

${C_HEAD}install - Live-System installieren${C_OFF}
${C_MISC}  Läuft INNERHALB des gebooteten archiso-Live-Systems und braucht Root.
  Ohne ${C_FILE}-d${C_MISC} wird im Terminal interaktiv ein Ziel abgefragt.
  Bei einer Partition wird NUR diese Partition formatiert - die
  Partitionstabelle bleibt unverändert. Voraussetzungen:
  UEFI: ESP auf derselben Platte; BIOS + GPT: BIOS-Boot-Partition.

  Optionen:
    ${C_FILE}-d, --disk GERÄT${C_OFF}   ${C_MISC}komplette Festplatte ODER einzelne Partition
    ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}Sicherheitsabfrage überspringen (Server-Einsatz)
    ${C_FILE}-h, --help${C_OFF}         ${C_MISC}diese Hilfe

  Beispiele (Server, ohne Rückfragen):
    ${C_FILE}$SCRIPT_NAME install -d /dev/sda -y${C_OFF}
    ${C_FILE}$SCRIPT_NAME install -d /dev/nvme0n1p2 -y${C_OFF}

${C_HEAD}iso - Live-ISO erstellen${C_OFF}
${C_MISC}  Erstellt eine bootbare Live-ISO des LAUFENDEN Systems (Root-Rechte,
  Arch-basiertes System, Arbeitsverzeichnis ohne Leerzeichen).

  Optionen:
    ${C_FILE}-w, --work VERZ${C_OFF}       ${C_MISC}Arbeitsverzeichnis [Standard: ~/remastern]
    ${C_FILE}-o, --output PFAD${C_OFF}     ${C_MISC}Zielpfad/Verzeichnis der ISO (wie ZIEL)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}Volume-Label [Standard: ARCHLIVE]
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}SquashFS-Kompression [Standard: gzip]
    ${C_FILE}-e, --exclude PFADE${C_OFF}   ${C_MISC}zusätzlich ausschließen (leerzeichengetrennt)

  Beispiele:
    ${C_FILE}$SCRIPT_NAME iso /srv/iso/rescue.iso${C_OFF}
    ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_OFF}

${C_HEAD}cleanup / part / targets${C_OFF}
${C_MISC}  ${C_FILE}cleanup${C_MISC} löst Mounts und löscht Build-Artefakte (${C_FILE}-w VERZ${C_MISC}).
  ${C_FILE}part${C_MISC}     interaktiver Partitionierer: neue Tabelle (GPT/MBR),
           Partitionen erstellen (Zweck-Presets), löschen, formatieren,
           Typ setzen (ESP/BIOS-Boot/Swap), Boot-Flag - alles per Zahl.
  ${C_FILE}targets${C_MISC}  listet mögliche Installationsziele (read-only).

${C_HEAD}Farbschema${C_OFF}
${C_MISC}  Überschriften hell-cyan, Text hell-gelb, Dateien/Pfade hell-lila,
  alles andere hell-grün (Fehler rot). Abschalten: ${C_FILE}-nc, --no-color${C_MISC} oder ${C_FILE}NO_COLOR=1${C_OFF}

${C_TEXT}ACHTUNG: Installation und Partitionieren löschen Daten unwiderruflich!${C_OFF}
HILFE
        ;;
    esac
}

usage_install() {
    case "$SPRACHE" in
    EN)
        cat <<HILFE
${C_HEAD}$SCRIPT_NAME install - installs the booted live system${C_OFF}

${C_MISC}Usage:
  ${C_FILE}$SCRIPT_NAME install -d DEVICE [-y]${C_OFF}

${C_MISC}Options:
  ${C_FILE}-d, --disk DEVICE${C_OFF}   ${C_MISC}whole disk OR single partition
                      (without ${C_FILE}-d${C_MISC} a target is asked for interactively)
  ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}skip the confirmation prompt
  ${C_FILE}-h, --help${C_OFF}         ${C_MISC}this help

${C_MISC}For a partition, ONLY that partition is formatted - the
partition table of the disk stays unchanged. Requirements:
UEFI: ESP on the same disk; BIOS + GPT: BIOS boot partition.

${C_TEXT}WARNING: All data on the target device will be irreversibly deleted!${C_OFF}
HILFE
        ;;
    *)
        cat <<HILFE
${C_HEAD}$SCRIPT_NAME install - installiert das gebootete Live-System${C_OFF}

${C_MISC}Aufruf:
  ${C_FILE}$SCRIPT_NAME install -d GERÄT [-y]${C_OFF}

${C_MISC}Optionen:
  ${C_FILE}-d, --disk GERÄT${C_OFF}   ${C_MISC}komplette Festplatte ODER einzelne Partition
                      (ohne ${C_FILE}-d${C_MISC} wird interaktiv ein Ziel abgefragt)
  ${C_FILE}-y, --yes${C_OFF}          ${C_MISC}Sicherheitsabfrage überspringen
  ${C_FILE}-h, --help${C_OFF}         ${C_MISC}diese Hilfe

${C_MISC}Bei einer Partition wird NUR diese Partition formatiert - die
Partitionstabelle der Platte bleibt unverändert. Voraussetzungen:
UEFI: ESP auf derselben Platte; BIOS + GPT: BIOS-Boot-Partition.

${C_TEXT}ACHTUNG: Alle Daten auf dem Zielgerät werden unwiderruflich gelöscht!${C_OFF}
HILFE
        ;;
    esac
}

usage_iso() {
    case "$SPRACHE" in
    EN)
        cat <<HILFE
${C_HEAD}$SCRIPT_NAME iso - Arch-Linux live ISO of the running system${C_OFF}

${C_MISC}Usage:
  ${C_FILE}$SCRIPT_NAME iso [OPTIONS] [TARGET]${C_OFF}

${C_MISC}TARGET                  target path of the ISO: file (ending in ${C_FILE}.iso${C_MISC}) or
                        directory (gets ${C_FILE}archlive.iso${C_MISC}).
                        Without it: <working directory>/archlive.iso

Options:
  ${C_FILE}-w, --work DIR${C_OFF}       ${C_MISC}working directory for the build [default: ~/remastern]
  ${C_FILE}-o, --output PATH${C_OFF}     ${C_MISC}target path/directory of the ISO (like TARGET)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}volume label of the ISO [default: ARCHLIVE]
                        (max. 32 chars, A-Z 0-9 . _ -)
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}squashfs compression: xz, zstd, lzma,
                        gzip, lzo, lz4 [default: gzip, configurable
                        in the script via SQUASH_COMP=...]
  ${C_FILE}-e, --exclude PATHS${C_OFF}   ${C_MISC}additionally exclude, space-separated,
                        e.g. ${C_FILE}-e "/home/user/Data /opt/big"${C_MISC}
  ${C_FILE}-nc, --no-color${C_OFF}            ${C_MISC}turn colors off
  ${C_FILE}-h, --help${C_OFF}            ${C_MISC}this help

Examples:
  ${C_FILE}$SCRIPT_NAME iso /srv/iso/test.iso${C_MISC}
  ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_MISC}
HILFE
        ;;
    *)
        cat <<HILFE
${C_HEAD}$SCRIPT_NAME iso - Arch-Linux-Live-ISO vom laufenden System${C_OFF}

${C_MISC}Aufruf:
  ${C_FILE}$SCRIPT_NAME iso [OPTIONEN] [ZIEL]${C_OFF}

${C_MISC}ZIEL                    Zielpfad der ISO: Datei (endet auf ${C_FILE}.iso${C_MISC}) oder
                        Verzeichnis (dort landet ${C_FILE}archlive.iso${C_MISC}).
                        Ohne Angabe: <Arbeitsverzeichnis>/archlive.iso

Optionen:
  ${C_FILE}-w, --work VERZ${C_OFF}       ${C_MISC}Arbeitsverzeichnis für den Bau [Standard: ~/remastern]
  ${C_FILE}-o, --output PFAD${C_OFF}     ${C_MISC}Zielpfad/Verzeichnis der ISO (wie ZIEL)
    ${C_FILE}-l, --label LABEL${C_OFF}     ${C_MISC}Volume-Label der ISO [Standard: ARCHLIVE]
                        (max. 32 Zeichen, A-Z 0-9 . _ -)
    ${C_FILE}-c, --compression ALGO${C_OFF} ${C_MISC}SquashFS-Kompression: xz, zstd, lzma,
                        gzip, lzo, lz4 [Standard: gzip, im Script einstellbar
                        über SQUASH_COMP=...]
  ${C_FILE}-e, --exclude PFADE${C_OFF}   ${C_MISC}Zusätzliche Ausschlüsse, leerzeichengetrennt,
                        z. B. ${C_FILE}-e "/home/user/Daten /opt/gross"${C_MISC}
  ${C_FILE}-nc, --no-color${C_OFF}            ${C_MISC}Farben abschalten
  ${C_FILE}-h, --help${C_OFF}            ${C_MISC}diese Hilfe

Beispiele:
  ${C_FILE}$SCRIPT_NAME iso /srv/iso/test.iso${C_MISC}
  ${C_FILE}$SCRIPT_NAME iso -l RESCUE-2026 -o /mnt/usb${C_MISC}
HILFE
        ;;
    esac
}


# ============================================================
# Einzelskripte extrahieren (-x VERZEICHNIS): part/iso/install
# als eigenstaendig lauffaehige Skripte (Block-Zusammensetzung,
# wie bei ubuntulive-tool). -e ist beim ISO-Bau bereits "exclude",
# deshalb der Buchstabe -x fuer extract.
# ============================================================

EXPORT_NAME[1]="${SCRIPT_NAME%.sh}-part.sh"
EXPORT_NAME[2]="${SCRIPT_NAME%.sh}-iso.sh"
EXPORT_NAME[3]="${SCRIPT_NAME%.sh}-install.sh"

export_block() {
    local start ende
    start="$(grep -n "^#@@BLOCK:$1\$" "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    ende="$(grep -n "^#@@ENDBLOCK:$1\$" "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    if [[ -z "$start" || -z "$ende" ]]; then
        die "$(t exp_err_no_marker "$1" "$SCRIPT_PATH")"
    fi
    sed -n "$((start + 1)),$((ende - 1))p" "$SCRIPT_PATH"
}

export_extract_fn() {
    awk -v fn="$1" '
        !drin && $0 == fn "() {" { drin = 1 }
        drin { print }
        drin && $0 == "}" { exit }
    ' "$SCRIPT_PATH"
}

export_header() {
    local nr="$1" zweck tools
    case "$nr" in
        1)
            zweck="Interaktiver Partitionierer (sfdisk-Basis)"
            tools="bash >= 4.4, GNU coreutils, util-linux (sfdisk, lsblk, findmnt, blockdev, wipefs), udev; zum Formatieren dosfstools/e2fsprogs/ntfs-3g" ;;
        2)
            zweck="Live-ISO vom laufenden System erstellen"
            tools="bash >= 4.4, GNU coreutils, util-linux, pacman, squashfs-tools, grub, mtools, libisoburn, mkinitcpio + mkinitcpio-archiso, dosfstools/e2fsprogs/ntfs-3g (fehlende werden bei Bedarf nachinstalliert)" ;;
        3)
            zweck="Gebootetes Live-System auf Festplatte/Partition installieren"
            tools="bash >= 4.4, GNU coreutils, util-linux, systemd; läuft im gebooteten Arch-Live-System und braucht Root" ;;
    esac
    cat <<KOPF
#!/usr/bin/env bash
#
# ${EXPORT_NAME[$nr]} - $zweck
#
# Eigenständig lauffähiger Teil von $SCRIPT_NAME $VERSION, erzeugt mit
# "$SCRIPT_NAME -x". Enthält alle benötigten Hilfsfunktionen.
#
# Verwendung:
#   ohne Argumente  interaktiv (wie im Hauptmenü von $SCRIPT_NAME;
#                   beim ISO-Bau ohne Terminal: Direktstart mit
#                   Standardwerten)
#   -h | --help     Hilfe
#   -V | --version  Version
#
# Benötigte Tools:
#   $tools
#
# Exit-Codes: 0 = Erfolg, 2 = falsche Argumente, 3 = Fehler/Abbruch.
# Farben: wie das Erzeuger-Script (--no-color oder NO_COLOR=1).
KOPF
    if [[ "$nr" == "2" ]]; then
        printf '%s\n' \
            '# MENU_NR setzt menu_select (mitgeliefertes Menü-Fundament),' \
            '# im ISO-Teil wird sie nie gelesen.' \
            '# shellcheck disable=SC2034'
    fi
}

export_epilog_part() {
    cat <<'EPILOG'
usage_part() {
    case "$SPRACHE" in
    EN)
        cat <<HILFE
${C_HEAD}${SCRIPT_NAME} - interactive partitioner (sfdisk-based)${C_OFF}

${C_MISC}Usage:
  ${C_FILE}${SCRIPT_NAME}${C_OFF}

${C_MISC}Interactive partition manager with number selection: new
partition table (GPT/MBR), create partitions (purpose presets),
delete, format, set type (ESP/BIOS boot/swap), boot flag.

  ${C_FILE}-nc, --no-color${C_OFF}   ${C_MISC}turn colors off
  ${C_FILE}-h, --help${C_OFF}    ${C_MISC}this help
  ${C_FILE}-V, --version${C_OFF} ${C_MISC}version

${C_TEXT}WARNING: Partitioning deletes data irreversibly!${C_OFF}
HILFE
        ;;
    *)
        cat <<HILFE
${C_HEAD}${SCRIPT_NAME} - interaktiver Partitionierer (sfdisk-Basis)${C_OFF}

${C_MISC}Aufruf:
  ${C_FILE}${SCRIPT_NAME}${C_OFF}

${C_MISC}Interaktiver Partitionsmanager mit Zahlen-Auswahl: neue
Partitionstabelle (GPT/MBR), Partitionen erstellen (Zweck-Presets),
löschen, formatieren, Typ setzen (ESP/BIOS-Boot/Swap), Boot-Flag.

  ${C_FILE}-nc, --no-color${C_OFF}   ${C_MISC}Farben abschalten
  ${C_FILE}-h, --help${C_OFF}    ${C_MISC}diese Hilfe
  ${C_FILE}-V, --version${C_OFF} ${C_MISC}Version

${C_TEXT}ACHTUNG: Partitionieren löscht Daten unwiderruflich!${C_OFF}
HILFE
        ;;
    esac
}

main() {
    local cmd="${1:-}"
    case "$cmd" in
        -h|--help|help)
            usage_part
            exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        --no-color)
            shift
            main "$@" ;;
        "")
            require_root
            INTERACTIVE="j"
            part_menu ;;
        *)
            cmd_part "$@" ;;
    esac
}
EPILOG
}

export_epilog_iso() {
    cat <<'EPILOG'
main() {
    local cmd="${1:-}"
    case "$cmd" in
        -h|--help|help)
            usage_iso
            exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        --no-color)
            shift
            main "$@" ;;
        "")
            if [[ -t 0 ]]; then
                require_root
                INTERACTIVE="j"
                iso_interactive
            else
                cmd_iso
            fi ;;
        *)
            cmd_iso "$@" ;;
    esac
}
EPILOG
}

export_epilog_install() {
    cat <<'EPILOG'
main() {
    local cmd="${1:-}"
    case "$cmd" in
        -h|--help|help)
            usage_install
            exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        --no-color)
            shift
            main "$@" ;;
        "")
            cmd_install ;;
        *)
            cmd_install "$@" ;;
    esac
}
EPILOG
}

export_generate() {
    local nr="$1" ziel="$2"
    local ln_set ln_common
    ln_set="$(grep -n '^set -euo pipefail$' "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    ln_common="$(grep -n '^#@@BLOCK:COMMON$' "$SCRIPT_PATH" | head -n1 | cut -d: -f1)"
    if [[ -z "$ln_set" || -z "$ln_common" ]]; then
        die "$(t exp_err_no_core "$SCRIPT_PATH")"
    fi

    {
        export_header "$nr"
        printf '\n'
        sed -n "${ln_set},$((ln_common - 1))p" "$SCRIPT_PATH"
        printf '\n'
        export_block COMMON
        printf '\n'
        case "$nr" in
            1)
                export_block PART
                printf '\n'
                export_epilog_part
                ;;
            2)
                export_block ISO
                printf '\n'
                export_extract_fn usage_iso | sed "s/\\\$SCRIPT_NAME iso/\\\$SCRIPT_NAME/g"
                export_extract_fn cmd_iso | sed "s/\\\$SCRIPT_NAME iso/\\\$SCRIPT_NAME/g"
                printf '\n'
                export_epilog_iso
                ;;
            3)
                export_block PART
                printf '\n'
                export_block INSTALL
                printf '\n'
                export_extract_fn usage_install | sed "s/\\\$SCRIPT_NAME install/\\\$SCRIPT_NAME/g"
                export_extract_fn cmd_install | sed "s/\\\$SCRIPT_NAME install/\\\$SCRIPT_NAME/g"
                printf '\n'
                export_epilog_install
                ;;
        esac
        printf '\n'
        printf 'if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then\n    main "$@"\nfi\n'
    } > "$ziel"
}

cmd_extract() {
    local dir="${1:-}"
    if [[ -z "$dir" || "$dir" == "/" ]]; then
        err "$(t exp_err_bad_dir "${dir:-}")"
        usage
        exit 2
    fi
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || die "$(t exp_err_outdir "$dir")"
    fi
    local nr ziel fehler=0
    for nr in 1 2 3; do
        ziel="$dir/${EXPORT_NAME[$nr]}"
        export_generate "$nr" "$ziel"
        chmod 755 "$ziel" || die "$(t exp_err_chmod "$ziel")"
    done
    for nr in 1 2 3; do
        ziel="$dir/${EXPORT_NAME[$nr]}"
        if ! bash -n "$ziel"; then
            err "$(t exp_err_invalid_script "$ziel")"
            rm -f -- "$ziel"
            fehler=1
        fi
    done
    if (( fehler )); then
        exit 3
    fi
    misc "$(t exp_info_done "$dir")"
}

# ============================================================
# Befehls-Zerlegung
# ============================================================

cmd_iso() {
    local iso_target="" excl_input=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage_iso; exit 0 ;;
            -de|-en) shift ;;
            -w|--work)
                if [[ $# -lt 2 ]]; then err "$(t cli_err_missing_dir "$1")"; usage_iso; exit 2; fi
                WORK="$2"; shift 2 ;;
            -o|--output)
                if [[ $# -lt 2 ]]; then err "$(t cli_err_missing_path "$1")"; usage_iso; exit 2; fi
                OUT="$2"; shift 2 ;;
            -l|--label)
                if [[ $# -lt 2 ]]; then err "$(t cli_err_missing_label "$1")"; usage_iso; exit 2; fi
                ISO_LABEL="$2"; shift 2 ;;
            -c|--compression)
                if [[ $# -lt 2 ]]; then err "$(t cli_err_missing_algo "$1")"; usage_iso; exit 2; fi
                SQUASH_COMP="$2"; shift 2 ;;
            -e|--exclude)
                if [[ $# -lt 2 ]]; then err "$(t cli_err_missing_excludes "$1")"; usage_iso; exit 2; fi
                excl_input="$2"
                if [[ -n "$excl_input" ]]; then
                    local -a parsed=()
                    read -r -a parsed <<< "$excl_input"
                    EXTRA_EXCLUDES+=("${parsed[@]}")
                fi
                shift 2 ;;
            --no-color) shift ;;
            -*)
                err "$(t cli_err_unknown_opt "$1")"
                usage_iso
                exit 2 ;;
            *)
                if [[ -n "$iso_target" ]]; then
                    err "$(t cli_err_one_target)"
                    exit 2
                fi
                iso_target="$1"; shift ;;
        esac
    done
    if [[ -n "$iso_target" ]]; then
        OUT="$iso_target"
    fi

    INTERACTIVE="n"
    do_iso_build
}

cmd_install() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage_install; exit 0 ;;
            -d|--disk)
                if [[ $# -lt 2 ]]; then err "$(t cli_err_missing_dev "$1")"; usage_install; exit 2; fi
                DISK="$2"; shift 2 ;;
            -y|--yes) ASSUME_YES="j"; shift ;;
            --no-color) shift ;;
            *)
                err "$(t cli_err_unknown_arg "$1" "$SCRIPT_NAME install -h")"
                usage_install
                exit 2 ;;
        esac
    done

    require_root
    INTERACTIVE="n"

    if [[ -z "$DISK" && -t 0 ]]; then
        # Terminal vorhanden, aber kein -d: interaktiv Ziel wählen
        INTERACTIVE="j"
        choose_install_target || exit 3
    fi

    do_install
}

cmd_part() {
    require_root
    INTERACTIVE="j"
    part_menu
}

cmd_cleanup() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w|--work)
                if [[ $# -lt 2 ]]; then err "$(t cli_err_missing_dir "$1")"; usage; exit 2; fi
                WORK="$2"; shift 2 ;;
            --no-color) shift ;;
            -h|--help) usage; exit 0 ;;
            *)
                err "$(t cli_err_unknown_arg "$1" "$SCRIPT_NAME -h")"
                exit 2 ;;
        esac
    done
    do_iso_cleanup
}

cmd_targets() {
    show_targets
}

# ============================================================
# main
# ============================================================

main() {
    local cmd="menu"
    if [[ $# -gt 0 ]]; then
        cmd="$1"
        shift
    fi

    case "$cmd" in
        menu)
            # Jede Menü-Aktion braucht Root - einmalig anfordern,
            # damit gesammelte Eingaben (ISO-Pfade usw.) erhalten bleiben.
            require_root
            main_menu ;;
        iso)                        cmd_iso "$@" ;;
        install)                    cmd_install "$@" ;;
        part|partition|partitioner) cmd_part ;;
        cleanup)                    cmd_cleanup "$@" ;;
        -x|--extract)               cmd_extract "$@" ;;
        targets|ziele)              cmd_targets ;;
        help|-h|--help)             usage; exit 0 ;;
        -V|--version)
            printf '%s Version %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0 ;;
        --no-color)
            # Beim Start bereits gefiltert - ohne weiteren Befehl: Menü
            require_root
            main_menu ;;
        *)
            err "$(t cli_err_unknown_cmd "$cmd")"
            usage
            exit 2 ;;
    esac
}

# Nur ausführen, nicht sourced (ermöglicht Funktionstests)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
#@@@END:arch/archlive-tool@@@
#@@@SCRIPT:alpine/alpinelive-tool@@@
#!/bin/sh
# ============================================================================
# alpinelive-tool - Alpine-Werkzeugkasten: Live-ISO, Installation,
# Partitionierung - in einem Skript (Vorbild: archlive-tool /
# ubuntulive-tool).
#
# Die drei Original-Werkzeuge sind byte-identisch eingebettet:
#   mkalpe-live.sh   Live-ISO eines installierten Alpine-Systems erzeugen
#   alpe-install.sh  die gebootete alpe-live-ISO auf Platte/Partitionen
#                    installieren
#   alpe-part        Partitionierer
# Beim Aufruf wird das gewaehlte Werkzeug in einen privaten Temp-Ordner
# entpackt und ausgefuehrt; alle Argumente werden durchgereicht, der
# Temp-Ordner automatisch geloescht. Mit -x VERZEICHNIS werden die drei
# Originale als eigenstaendige, ausfuehrbare Dateien ausgegeben.
#
# Verwendung:
#   alpinelive-tool                     Hauptmenue
#   alpinelive-tool iso [OPTIONEN]      mkalpe-live.sh (Live-ISO)
#   alpinelive-tool install [OPTIONEN]  alpe-install.sh (Installation)
#   alpinelive-tool part [OPTIONEN]     alpe-part (Partitionierer)
#   alpinelive-tool menu                Hauptmenue (wie ohne Befehl)
#   alpinelive-tool -x VERZEICHNIS      die 3 Original-Skripte ausgeben
#                                       (mkalpe-live.sh, alpe-install.sh,
#                                       alpe-part)
#   alpinelive-tool -h | --help         Hilfe
#   alpinelive-tool -V | --version      Version
#
# Befehls-Aliase: live=iso, inst=install, mkalpe=iso,
# alpe-install=install, alpe-part=part, partition=part.
#
# Sprache pro Aufruf: -de bzw. -en (vor dem Befehl angeben; sie wird
# auch an die eingebetteten Skripte vererbt). Voreinstellung AUTO =
# Systemsprache (LC_ALL/LANG); LLT_LANG aus der LinuxLiveTool-GUI hat
# Vorrang. Der angezeigte Name ist der tatsaechliche Dateiname - das
# Skript darf umbenannt werden.
#
# Benoetigte Tools: POSIX-sh (busybox-ash reicht), mktemp, cat, chmod.
# Exit-Codes: 0 = Erfolg; 1 = eigener Fehler bzw. Fehler eines
# eingebetteten Werkzeugs (dessen eigene Codes ab 3 werden
# durchgereicht).
# ============================================================================

(set -o pipefail) 2>/dev/null && set -o pipefail
set -eu

# Anzeigename = tatsaechlicher Dateiname (umbenennbar)
PROG="$(basename -- "$0")"
VERSION="2.4"

# ==================== SPRACHE / OPTIONEN ====================
# Sprache aller eigenen Meldungen: AUTO (Systemsprache, Voreinstellung),
# DE oder EN. Flags -de/-en setzen die Sprache explizit, -nc schaltet
# die Farben ab (NO_COLOR=1 wird an die eingebetteten Skripte
# vererbt); die Flags werden aus den Argumenten entfernt. LLT_LANG aus
# der GUI gewinnt ueber AUTO.
SPRACHE=DE
SPRACHE_FLAG=n
sprache_anzahl=$#
for sprache_a in "$@"; do
    case "$sprache_a" in
    -de) SPRACHE=DE; SPRACHE_FLAG=j ;;
    -en) SPRACHE=EN; SPRACHE_FLAG=j ;;
    -nc) NO_COLOR=1; export NO_COLOR ;;
    *)   set -- "$@" "$sprache_a" ;;
    esac
done
if [ "$sprache_anzahl" -gt 0 ]; then
    shift "$sprache_anzahl"
fi
case "${LLT_LANG:-}" in
DE|EN) SPRACHE="$LLT_LANG" ;;
esac
case "$SPRACHE" in
AUTO) case "${LC_ALL:-${LANG:-}}" in de*|DE*) SPRACHE=DE ;; *) SPRACHE=EN ;; esac ;;
esac
# Sprache IMMER an eingebettete Teile vererben (Regel: keine Mischsprachen)
LLT_LANG="$SPRACHE"
export LLT_LANG

# Farben gem. DESIGN.md (hell cyan/gelb/lila/gruen/rot, Fett = "1;3X").
# Der Block liegt NACH dem -de/-en/-nc-Vorscan, damit -nc wirkt
# (NO_COLOR wird unten an die eingebetteten Skripte vererbt).
# Echte ESC-Bytes: printf '%b' UND cat-Heredocs (usage) funktionieren.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    COLOR_ESC=$(printf '\033')
    COLOR_RESET="${COLOR_ESC}[0m"
    COLOR_HEAD="${COLOR_ESC}[1;96m"    # hell cyan   - Überschriften
    COLOR_TEXT="${COLOR_ESC}[1;93m"    # hell gelb   - normaler Text
    COLOR_FILE="${COLOR_ESC}[1;35m"    # hell lila   - Dateien/Befehle
    COLOR_MISC="${COLOR_ESC}[1;92m"    # hellgrün    - alles andere
    COLOR_WARN="${COLOR_ESC}[1;91m"    # hell rot    - Warnungen/Fehler
else
    COLOR_ESC=''
    COLOR_RESET=''
    COLOR_HEAD=''
    COLOR_TEXT=''
    COLOR_FILE=''
    COLOR_MISC=''
    COLOR_WARN=''
fi

# Textkatalog der eigenen Meldungen (Menue, Extraktion, Fehler).
# Parametrisierte Meldungen nutzen die Nachricht selbst als printf-
# Format (die Platzhalter-%s werden also wirklich ersetzt).
t() {
    local key=$1; shift
    case "$key:$SPRACHE" in
    err_unknown_arg:EN) printf 'Unknown argument: %s (help: -h)\n' "$1" ;;
    err_unknown_arg:*)  printf 'Unbekanntes Argument: %s (Hilfe: -h)\n' "$1" ;;
    err_extract_needs_dir:EN) printf '%s\n' "-x needs a target directory ($PROG -x DIRECTORY)." ;;
    err_extract_needs_dir:*)  printf '%s\n' "-x benoetigt ein Zielverzeichnis ($PROG -x VERZEICHNIS)." ;;
    err_dir_and_cmd:EN) printf '%s\n' "Please use either -x DIRECTORY or a command, not both." ;;
    err_dir_and_cmd:*)  printf '%s\n' "Bitte entweder -x VERZEICHNIS ODER einen Befehl angeben, nicht beides." ;;
    err_bad_dir:EN) printf 'Invalid target directory: %s\n' "$1" ;;
    err_bad_dir:*)  printf 'Ungueltiges Zielverzeichnis: %s\n' "$1" ;;
    err_mkdir:EN) printf 'Could not create directory: %s\n' "$1" ;;
    err_mkdir:*)  printf 'Verzeichnis konnte nicht angelegt werden: %s\n' "$1" ;;
    err_no_tmp:EN) printf '%s\n' "Could not create temporary file." ;;
    err_no_tmp:*)  printf '%s\n' "Temporaerdatei konnte nicht angelegt werden." ;;
    info_extract:EN) printf 'Extracting the three original scripts to %s ...\n' "$1" ;;
    info_extract:*)  printf 'Entpacke die drei Original-Skripte nach %s ...\n' "$1" ;;
    info_extract_done:EN) printf 'Done. The scripts also run standalone, e.g.: sh %s/mkalpe-live.sh -h\n' "$1" ;;
    info_extract_done:*)  printf 'Fertig. Die Skripte laufen nun auch einzeln, z. B.: sh %s/mkalpe-live.sh -h\n' "$1" ;;
    menu_title:EN) printf '%s %s - Alpine toolbox\n' "$PROG" "$1" ;;
    menu_title:*)  printf '%s %s - Alpine-Werkzeugkasten\n' "$PROG" "$1" ;;
    menu_iso:EN) printf '%s\n' "1) Create live ISO (mkalpe-live)" ;;
    menu_iso:*)  printf '%s\n' "1) Live-ISO erstellen (mkalpe-live)" ;;
    menu_install:EN) printf '%s\n' "2) Install Alpine (alpe-install)" ;;
    menu_install:*)  printf '%s\n' "2) Alpine installieren (alpe-install)" ;;
    menu_part:EN) printf '%s\n' "3) Partition disks (alpe-part)" ;;
    menu_part:*)  printf '%s\n' "3) Partitionieren (alpe-part)" ;;
    menu_back:EN)  printf '%s\n' "0) Back" ;;
    menu_back:*)   printf '%s\n' "0) Zurück" ;;
    menu_quit:EN) printf '%s\n' "00) Quit" ;;
    menu_quit:*)  printf '%s\n' "00) Beenden" ;;
    menu_prompt:EN) printf '%s\n' "Choice: " ;;
    menu_prompt:*)  printf '%s\n' "Auswahl: " ;;
    menu_bad:EN) printf 'Invalid choice: %s\n' "$1" ;;
    menu_bad:*)  printf 'Ungueltige Auswahl: %s\n' "$1" ;;
    *) printf '%s\n' "$key" ;;
    esac
}
te() { printf '%b\n' "${COLOR_WARN}$(t "$@")${COLOR_RESET}" >&2; }
td() { printf '%b\n' "${COLOR_WARN}$(t "$@")${COLOR_RESET}" >&2; exit 1; }

usage() {
    case "$SPRACHE" in
    EN)
        cat >&2 <<LLT_USAGE_EN
${COLOR_HEAD}$PROG $VERSION - Alpine toolbox: live ISO, installation, partitioning${COLOR_RESET}

${COLOR_HEAD}Usage:${COLOR_RESET}
  ${COLOR_FILE}$PROG${COLOR_MISC}                     main menu
  ${COLOR_FILE}$PROG iso [OPTIONS]${COLOR_MISC}       mkalpe-live.sh (create the live ISO)
  ${COLOR_FILE}$PROG install [OPTIONS]${COLOR_MISC}   alpe-install.sh (install the live system)
  ${COLOR_FILE}$PROG part [OPTIONS]${COLOR_MISC}      alpe-part (partitioner)
  ${COLOR_FILE}$PROG -x DIRECTORY${COLOR_MISC}        extract the 3 original scripts
                            (mkalpe-live.sh, alpe-install.sh, alpe-part)
  ${COLOR_FILE}$PROG -h | --help${COLOR_MISC}         help
  ${COLOR_FILE}$PROG -V | --version${COLOR_MISC}      version

${COLOR_HEAD}Options:${COLOR_RESET}
  ${COLOR_FILE}-de | -en${COLOR_MISC}                 force the language (German/English); it is
                            inherited by the embedded scripts
  ${COLOR_FILE}-nc${COLOR_MISC}                       turn colors off (no color)
  ${COLOR_FILE}-x, --extract DIRECTORY${COLOR_MISC}   write the three original scripts as
                            standalone executable files

${COLOR_TEXT}The embedded tools are byte-identical to the standalone scripts and
receive all arguments unchanged (e.g.: $PROG iso -c xz).${COLOR_RESET}
LLT_USAGE_EN
        ;;
    *)
        cat >&2 <<LLT_USAGE_DE
${COLOR_HEAD}$PROG $VERSION - Alpine-Werkzeugkasten: Live-ISO, Installation, Partitionierung${COLOR_RESET}

${COLOR_HEAD}Verwendung:${COLOR_RESET}
  ${COLOR_FILE}$PROG${COLOR_MISC}                     Hauptmenue
  ${COLOR_FILE}$PROG iso [OPTIONEN]${COLOR_MISC}      mkalpe-live.sh (Live-ISO erstellen)
  ${COLOR_FILE}$PROG install [OPTIONEN]${COLOR_MISC}  alpe-install.sh (Live-System installieren)
  ${COLOR_FILE}$PROG part [OPTIONEN]${COLOR_MISC}     alpe-part (Partitionierer)
  ${COLOR_FILE}$PROG -x VERZEICHNIS${COLOR_MISC}      die 3 Original-Skripte ausgeben
                            (mkalpe-live.sh, alpe-install.sh, alpe-part)
  ${COLOR_FILE}$PROG -h | --help${COLOR_MISC}         Hilfe
  ${COLOR_FILE}$PROG -V | --version${COLOR_MISC}      Version

${COLOR_HEAD}Optionen:${COLOR_RESET}
  ${COLOR_FILE}-de | -en${COLOR_MISC}                 Sprache fest erzwingen (Deutsch/Englisch);
                            wird an die eingebetteten Skripte vererbt
  ${COLOR_FILE}-nc${COLOR_MISC}                       Farben abschalten (no color)
  ${COLOR_FILE}-x, --extract VERZ${COLOR_MISC}        die drei Original-Skripte als eigenstaendige,
                            ausfuehrbare Dateien ausgeben

${COLOR_TEXT}Die eingebetteten Werkzeuge sind byte-identisch zu den Einzel-Skripten
und bekommen alle Argumente unveraendert durchgereicht
(z. B.: $PROG iso -c xz).${COLOR_RESET}
LLT_USAGE_DE
        ;;
    esac
}

# ---------------- Eingebettete Werkzeuge ----------------
# Jede emit_*-Funktion schreibt ein Original-Skript byte-identisch in
# die uebergebene Datei (Inhalt des Heredocs ist unverändert).

RUN_TMP=
run_cleanup() {
    [ -n "$RUN_TMP" ] && rm -rf "$RUN_TMP"
    return 0
}

run_embedded() {
    re_key=$1
    shift
    # Eigener Temp-Ordner mit kanonischem Namen: die eingebetteten
    # Skripte zeigen sonst ihren mktemp-Namen als Programmnamen.
    case "$re_key" in
    mkalpe)  re_name=mkalpe-live.sh ;;
    install) re_name=alpe-install.sh ;;
    part)    re_name=alpe-part ;;
    esac
    re_dir=$(mktemp -d "${TMPDIR:-/tmp}/alpinelive-tool.XXXXXX") || td err_no_tmp
    re_tmp="$re_dir/$re_name"
    RUN_TMP="$re_dir"
    trap run_cleanup EXIT INT TERM
    "emit_$re_key" "$re_tmp"
    chmod 700 "$re_tmp"
    re_rc=0
    sh "$re_tmp" "$@" || re_rc=$?
    rm -rf "$re_dir"
    RUN_TMP=
    trap run_cleanup EXIT INT TERM
    return "$re_rc"
}

main_menu() {
    while :; do
        printf '\n'
        printf '%b\n' "${COLOR_HEAD}$(t menu_title "$VERSION")${COLOR_RESET}"
        printf '%b\n' "${COLOR_MISC}$(t menu_iso)${COLOR_RESET}"
        printf '%b\n' "${COLOR_MISC}$(t menu_install)${COLOR_RESET}"
        printf '%b\n' "${COLOR_MISC}$(t menu_part)${COLOR_RESET}"
        printf '%b\n' "${COLOR_MISC}$(t menu_back)${COLOR_RESET}"
        printf '%b\n' "${COLOR_MISC}$(t menu_quit)${COLOR_RESET}"
        printf '%b\n' "${COLOR_TEXT}$(t menu_prompt)${COLOR_RESET}" >&2
        mm_choice=
        read -r mm_choice || exit 0
        case "$mm_choice" in
        1) alpe_rc=0; run_embedded mkalpe || alpe_rc=$?; if [ "$alpe_rc" -eq 42 ]; then exit 42; fi ;;
        2) alpe_rc=0; run_embedded install || alpe_rc=$?; if [ "$alpe_rc" -eq 42 ]; then exit 42; fi ;;
        3) alpe_rc=0; run_embedded part || alpe_rc=$?; if [ "$alpe_rc" -eq 42 ]; then exit 42; fi ;;
        0|"") exit 0 ;;
        00)   exit 42 ;;
        *) te menu_bad "$mm_choice" ;;
        esac
    done
}

extract_scripts() {
    ex_dir=$1
    case "$ex_dir" in
    ""|"/") td err_bad_dir "$ex_dir" ;;
    esac
    mkdir -p "$ex_dir" || td err_mkdir "$ex_dir"
    t info_extract "$ex_dir"
    emit_mkalpe "$ex_dir/mkalpe-live.sh"
    emit_install "$ex_dir/alpe-install.sh"
    emit_part "$ex_dir/alpe-part"
    chmod 755 "$ex_dir/mkalpe-live.sh" "$ex_dir/alpe-install.sh" \
        "$ex_dir/alpe-part"
    t info_extract_done "$ex_dir"
}

# ---- mkalpe-live.sh (byte-identisch eingebettet) ----
emit_mkalpe() {
    cat > "$1" <<'LLT_EMBED_MKALPE'
#!/bin/sh
# mkalpe-live.sh - Live-ISO einer installierten Alpine-Linux-Distribution erzeugen
#
# Erzeugt ein hybrid-faehiges Live-ISO (BIOS/syslinux + UEFI/grub) aus einem
# installierten Alpine-System. Der Boot-Weg entspricht dem der offiziellen
# Alpine-ISOs (Diskless-Boot):
#   - initramfs laedt das apkovl (die /etc-Konfiguration der Installation)
#   - die Pakete kommen aus dem auf dem ISO mitgelieferten /apks-Repository
#   - Kernel-Module + Firmware liegen im modloop (Squashfs, Kompression waehlbar)
# Funktioniert daher mit Minimal-/Server- wie auch Desktop-Installationen.
# Auf dem Zielsystem ist das ISO per setup-alpine/setup-disk offline
# installierbar (alle noetigen Pakete inkl. Kernel/Bootloader sind enthalten).
#
# Bezugs-Repository: standardmaessig wird der Branch des Quell-Systems
# uebernommen (z. B. 3.22 oder edge); mit -B/--branch laesst sich ein
# anderer Branch erzwingen (z. B. -B edge oder -B latest-stable). Die
# /etc-Konfiguration der Installation bleibt erhalten und wird dank des
# apk-Overlay-Mechanismus von Paket-Defaults nicht ueberschrieben.
#
# Benoetigte Pakete auf dem Bau-System (Alpine, ab ca. 3.19):
#   apk add xorriso squashfs-tools syslinux grub-efi mtools abuild openssl kmod mkinitfs
#   (zstd wird bei Bedarf per j/n-Frage nachinstalliert, xz ist optional und
#    macht das modloop nur kleiner)
# Fehlende Pakete werden beim Start erkannt und per J/n-Frage (Standard: J)
# automatisch nachinstalliert.
#
# Aufruf-Beispiele:
#   ./mkalpe-live.sh                          # -> ./alpe-live-<arch>-<datum>.iso (zstd)
#   ./mkalpe-live.sh -o /tmp/mein.iso -c xz   # Squashfs-Kompression xz
#   ./mkalpe-live.sh -I /home -I /opt         # zusaetzliche Verzeichnisse ins apkovl
#   ./mkalpe-live.sh -F                       # komplette linux-firmware einbetten
#   ./mkalpe-live.sh -B edge                  # Branch erzwingen (sonst wie Quell-System)
#
# Umgebungsvariablen:
#   ALPE_ROOT         Quell-System ("/" = laufendes System, oder eingehaengte
#                     Installation, z. B. "/mnt")           [Standard: /]
#   ALPE_EXTRA_REPOS  zusaetzliche Repository-URLs (Leerzeichen getrennt)
#   ALPE_KEYDIR       Ablage des Signier-Schluessels        [Standard: /etc/alpe]
#   ALPE_SYSLINUX_SHARE  syslinux-Dateien                   [Standard: /usr/share/syslinux]
#   ALPE_GRUB_LIB     grub-Modulverzeichnis                 [Standard: /usr/lib/grub]
#
# Hinweise:
#   - SSH-Host-Schluessel und weitere /etc-Inhalte der Quelle wandern ins ISO
#     (es ist ein Abbild des eigenen Systems).
#   - Das Live-System bootet mit dem Repository des Boot-Mediums; die
#     Netzwerk-Repos des Quell-Systems liegen unter
#     /etc/apk/repositories.alpe-network und werden vom installierten
#     System (alpe-install) automatisch gesetzt. Offline werden fehlende
#     HTTP-Repos nur als Warnung uebersprungen.
#   - /usr/local des Quell-Systems wird automatisch mitgenommen (wenn es
#     Inhalt hat). alpe-install ist optional: ohne es entsteht eine reine
#     Live-ISO ohne Installations-Hilfe.
#   - Muss auf einem Alpine-System gleicher Architektur ausgefuehrt werden.
#
# Zweisprachig (DE/EN): Alle Meldungen erscheinen in der Systemsprache.
# Fest erzwingen laesst sich die Sprache ueber die Variable SPRACHE am
# Dateianfang (Werte: AUTO = Systemsprache, DE oder EN) oder per
# Kommandozeilen-Flag -de bzw. -en.

set -eu

# Anzeigename = tatsaechlicher Dateiname (umbenennbar)
PROGRAM="$(basename -- "$0")"
VERSION=2.3.0

ALPE_ROOT="${ALPE_ROOT:-/}"
ALPE_EXTRA_REPOS="${ALPE_EXTRA_REPOS:-}"
ALPE_MIRROR="${ALPE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"
# BRANCH: leer = Repositories des Quell-Systems uebernehmen; sonst z. B.
# "edge", "latest-stable" oder eine feste Version wie "3.22"
BRANCH=""

KEYDIR="${ALPE_KEYDIR:-/etc/alpe}"
PRIVKEY="$KEYDIR/alpe-live.rsa"
PUBKEY_NAME="alpe-live.rsa.pub"
SYSLINUX_SHARE="${ALPE_SYSLINUX_SHARE:-/usr/share/syslinux}"
GRUB_LIB="${ALPE_GRUB_LIB:-/usr/lib/grub}"

BOOT_CMDLINE="modules=loop,squashfs,sd-mod,usb-storage quiet"
# Festes initfs-Feature-Set fuer Media-Boot (wie offizielles mkimage).
# NIEMALS die mkinitfs.conf des Quell-Systems uebernehmen: setup-disk schreibt
# dort features OHNE cdrom ("ata base ide scsi usb virtio ...") -- das
# ISO-initramfs koennte dann kein iso9660 mounten und der Boot endet in
# "Mounting boot media failed" (initramfs-Recovery-Shell).
INITFS_FEATURES="ata base cdrom ext4 kms mmc nvme raid scsi usb virtio squashfs"
# Module-Satz wie beim offiziellen ISO (mkimg.base.sh)
GRUB_MODS="all_video disk part_gpt part_msdos linux normal configfile search search_label efi_gop efi_uga fat iso9660 cat echo ls test true help gzio multiboot2"

OUTPUT=
COMPRESSION=zstd
FLAVOR=
INCLUDE_DIRS=
FULL_FIRMWARE=no
NO_HOME=no
WORK=
WORK_OWNED=no

# ==================== SPRACHE / LANGUAGE ====================
# Sprache aller Meldungen: AUTO (Systemsprache, Voreinstellung), DE oder EN.
# Zum Festlegen den Wert unten eintragen, z. B.:  SPRACHE=DE   bzw.   SPRACHE=EN
# Startet man das Skript aus der LinuxLiveTool-GUI, gewinnt die dort gewaehlte
# Sprache (Umgebungsvariable LLT_LANG = DE oder EN) ueber dieser Einstellung.
SPRACHE=DE
# Flags -de/-en: Sprache explizit setzen (gewinnt ueber AUTO, nicht
# ueber LLT_LANG der GUI); die Flags werden aus den Argumenten entfernt.
sprache_anzahl=$#
for sprache_a in "$@"; do
	case "$sprache_a" in
	-de) SPRACHE=DE ;;
	-en) SPRACHE=EN ;;
	-nc) NO_COLOR=1; export NO_COLOR ;;
	*)   set -- "$@" "$sprache_a" ;;
	esac
done
if [ "$sprache_anzahl" -gt 0 ]; then
	shift "$sprache_anzahl"
fi
case "${LLT_LANG:-}" in
DE|EN) SPRACHE="$LLT_LANG" ;;
esac
case "$SPRACHE" in
AUTO) case "${LC_ALL:-${LANG:-}}" in de*|DE*) SPRACHE=DE ;; *) SPRACHE=EN ;; esac ;;
esac

# Textkatalog: alle Meldungen in DE und EN (keine Extradatei).
#   t  KEY [ARGS...]  -> Meldung nach stdout
#   te KEY [ARGS...]  -> Meldung nach stderr (Warnung/Präfix im Text)
#   td KEY [ARGS...]  -> Meldung nach stderr + Abbruch (exit 1)
# ARGS fuellen die %s-Platzhalter im Text.
t() {
	local key=$1; shift
	case "$key:$SPRACHE" in
	err_bad_compression:EN) printf 'ERROR: Unknown squashfs compression: %s (zstd|gzip|xz|lzo|lz4)\n'  "$1" ;;
	err_bad_compression:*) printf 'FEHLER: Unbekannte Squashfs-Kompression: %s (zstd|gzip|xz|lzo|lz4)\n'  "$1" ;;
	err_bad_branch:EN) printf 'ERROR: Invalid branch: %s (letters, digits, . _ - only)\n'  "$1" ;;
	err_bad_branch:*) printf 'FEHLER: Unzulaessiger Branch: %s (nur Buchstaben, Ziffern, . _ -)\n'  "$1" ;;
	err_not_root:EN) printf '%s\n' "ERROR: This script must be run as root." ;;
	err_not_root:*)  printf '%s\n' "FEHLER: Dieses Skript muss als root ausgefuehrt werden." ;;
	err_not_alpine:EN) printf 'ERROR: %s is not an Alpine system (etc/alpine-release missing).\n'  "$1" ;;
	err_not_alpine:*) printf 'FEHLER: %s ist kein Alpine-System (etc/alpine-release fehlt).\n'  "$1" ;;
	err_print_arch:EN) printf '%s\n' "ERROR: apk --print-arch failed." ;;
	err_print_arch:*)  printf '%s\n' "FEHLER: apk --print-arch schlug fehl." ;;
	err_bad_arch:EN) printf 'ERROR: Architecture %s is not supported (only x86/x86_64 for BIOS+UEFI).\n'  "$1" ;;
	err_bad_arch:*) printf 'FEHLER: Architektur %s wird nicht unterstuetzt (nur x86/x86_64 fuer BIOS+UEFI).\n'  "$1" ;;
	warn_declined_install:EN) printf "Warning: Installation declined - continuing without '%s'.\n"  "$1" ;;
	warn_declined_install:*) printf "Warnung: Installation abgelehnt - es wird ohne '%s' weitergemacht.\n"  "$1" ;;
	warn_declined:EN) printf '%s\n' "Warning: Installation declined." ;;
	warn_declined:*)  printf '%s\n' "Warnung: Installation abgelehnt." ;;
	warn_apk_add_failed:EN) printf '%s\n' "Warning: apk add failed." ;;
	warn_apk_add_failed:*)  printf '%s\n' "Warnung: apk add fehlgeschlagen." ;;
	warn_no_zstd:EN) printf '%s\n' "Warning: Without zstd, .ko.zst modules stay compressed (functionally ok, modloop just gets larger)." ;;
	warn_no_zstd:*)  printf '%s\n' "Warnung: Ohne zstd bleiben .ko.zst-Module komprimiert (Funktionalitaet ok, modloop wird nur groesser)." ;;
	warn_no_xz:EN) printf '%s\n' "Warning: xz not installed - .ko.xz modules stay compressed (optional; 'apk add xz' makes the modloop smaller)." ;;
	warn_no_xz:*)  printf '%s\n' "Warnung: xz nicht installiert - .ko.xz-Module bleiben komprimiert (optional; 'apk add xz' macht das modloop kleiner)." ;;
	warn_no_firmware:EN) printf '%s\n' "Warning: No firmware references found." ;;
	warn_no_firmware:*)  printf '%s\n' "Warnung: Keine Firmware-Referenzen gefunden." ;;
	warn_no_modinfo:EN) printf '%s\n' "Warning: modinfo missing - firmware is not included in the modloop." ;;
	warn_no_modinfo:*)  printf '%s\n' "Warnung: modinfo fehlt - Firmware wird nicht in den modloop uebernommen." ;;
	warn_homes_big:EN) printf 'Warning: Home directories very large (%s kB) - the live system loads them into RAM (tmpfs); accordingly much memory is needed!\n'  "$1" ;;
	warn_homes_big:*) printf 'Warnung: Heimatverzeichnisse sehr gross (%s kB) - das Live-System laedt sie ins RAM (tmpfs), entsprechend viel Arbeitsspeicher noetig!\n'  "$1" ;;
	warn_inc_ignored:EN) printf 'Warning: -I %s ignored (not an absolute path)\n'  "$1" ;;
	warn_inc_ignored:*) printf 'Warnung: -I %s ignoriert (kein absoluter Pfad)\n'  "$1" ;;
	warn_inc_missing:EN) printf 'Warning: -I %s not found - skipped\n'  "$1" ;;
	warn_inc_missing:*) printf 'Warnung: -I %s nicht gefunden - uebersprungen\n'  "$1" ;;
	warn_interfaces:EN) printf '%s\n' "Warning: /etc/network/interfaces refers to the source hardware." ;;
	warn_interfaces:*)  printf '%s\n' "Warnung: Hinweis: /etc/network/interfaces bezieht sich auf die Quell-Hardware." ;;
	warn_no_alpe_install:EN) printf '%s\n' "Warning: alpe-install not found - a pure live ISO without installation helper is created." ;;
	warn_no_alpe_install:*)  printf '%s\n' "Warnung: alpe-install nicht gefunden - es entsteht eine reine Live-ISO ohne Installations-Hilfe." ;;
	err_missing_tools_final:EN) printf '%s\n' "ERROR: Missing tools: %s -- please install:
  apk add xorriso squashfs-tools syslinux grub-efi mtools abuild openssl kmod mkinitfs xz zstd" "$1" ;;
	err_missing_tools_final:*)  printf '%s\n' "FEHLER: Fehlende Werkzeuge: %s -- bitte installieren:
  apk add xorriso squashfs-tools syslinux grub-efi mtools abuild openssl kmod mkinitfs xz zstd" "$1" ;;
	err_no_modules:EN) printf 'ERROR: No kernel modules found in %s.\n'  "$1" ;;
	err_no_modules:*) printf 'FEHLER: Keine Kernel-Module in %s gefunden.\n'  "$1" ;;
	err_no_kvers:EN) printf 'ERROR: No kernel versions found in %s.\n'  "$1" ;;
	err_no_kvers:*) printf 'FEHLER: Keine Kernel-Versionen in %s gefunden.\n'  "$1" ;;
	err_no_kernel_flavor:EN) printf "ERROR: No kernel for flavor '%s' found in %s.\n"  "$1" "$2" ;;
	err_no_kernel_flavor:*) printf "FEHLER: Kein Kernel fuer Flavor '%s' in %s gefunden.\n"  "$1" "$2" ;;
	err_no_vmlinuz:EN) printf 'ERROR: No vmlinuz found in %s/boot (flavor %s).\n'  "$1" "$2" ;;
	err_no_vmlinuz:*) printf 'FEHLER: Kein vmlinuz in %s/boot gefunden (Flavor %s).\n'  "$1" "$2" ;;
	err_bad_workdir:EN) printf 'ERROR: Invalid working directory: %s\n'  "$1" ;;
	err_bad_workdir:*) printf 'FEHLER: Ungueltiges Arbeitsverzeichnis: %s\n'  "$1" ;;
	err_mkdir_workdir:EN) printf 'ERROR: Cannot create working directory %s.\n'  "$1" ;;
	err_mkdir_workdir:*) printf 'FEHLER: Kann Arbeitsverzeichnis %s nicht anlegen.\n'  "$1" ;;
	err_mktemp:EN) printf '%s\n' "ERROR: mktemp failed." ;;
	err_mktemp:*)  printf '%s\n' "FEHLER: mktemp fehlgeschlagen." ;;
	err_iso_in_workdir:EN) printf '%s\n' "ERROR: Target ISO must not be inside the working directory." ;;
	err_iso_in_workdir:*)  printf '%s\n' "FEHLER: Ziel-ISO darf nicht im Arbeitsverzeichnis liegen." ;;
	err_mkdir_iso:EN) printf '%s\n' "ERROR: Cannot create ISO directory structure." ;;
	err_mkdir_iso:*)  printf '%s\n' "FEHLER: Kann ISO-Verzeichnisstruktur nicht anlegen." ;;
	err_mkdir_keydir:EN) printf '%s\n' "ERROR: Cannot create key directory." ;;
	err_mkdir_keydir:*)  printf '%s\n' "FEHLER: Kann Schluesselverzeichnis nicht anlegen." ;;
	err_genrsa:EN) printf '%s\n' "ERROR: openssl genrsa failed." ;;
	err_genrsa:*)  printf '%s\n' "FEHLER: openssl genrsa fehlgeschlagen." ;;
	err_pubkey:EN) printf '%s\n' "ERROR: openssl rsa (public key) failed." ;;
	err_pubkey:*)  printf '%s\n' "FEHLER: openssl rsa (PubKey) fehlgeschlagen." ;;
	err_mkdir_modloop:EN) printf '%s\n' "ERROR: Cannot create modloop directory." ;;
	err_mkdir_modloop:*)  printf '%s\n' "FEHLER: Kann modloop-Verzeichnis nicht anlegen." ;;
	err_copy_modules:EN) printf '%s\n' "ERROR: Copying the kernel modules failed." ;;
	err_copy_modules:*)  printf '%s\n' "FEHLER: Kopieren der Kernel-Module fehlgeschlagen." ;;
	err_depmod:EN) printf '%s\n' "ERROR: depmod failed." ;;
	err_depmod:*)  printf '%s\n' "FEHLER: depmod fehlgeschlagen." ;;
	err_modloop_layout:EN) printf '%s\n' "ERROR: modloop layout failed." ;;
	err_modloop_layout:*)  printf '%s\n' "FEHLER: modloop-Layout fehlgeschlagen." ;;
	err_mksquashfs:EN) printf '%s\n' "ERROR: mksquashfs (modloop) failed." ;;
	err_mksquashfs:*)  printf '%s\n' "FEHLER: mksquashfs (modloop) fehlgeschlagen." ;;
	err_mkinitfs:EN) printf '%s\n' "ERROR: mkinitfs failed (kernel modules for the features present?)" ;;
	err_mkinitfs:*)  printf '%s\n' "FEHLER: mkinitfs fehlgeschlagen (Kernel-Module zu den Features vorhanden?)" ;;
	err_copy_kernel:EN) printf '%s\n' "ERROR: Copying the kernel failed." ;;
	err_copy_kernel:*)  printf '%s\n' "FEHLER: Kopieren des Kernels fehlgeschlagen." ;;
	err_no_world:EN) printf 'ERROR: %s not readable - not an installed apk system?\n'  "$1" ;;
	err_no_world:*) printf 'FEHLER: %s nicht lesbar - kein installiertes apk-System?\n'  "$1" ;;
	err_apk_update:EN) printf '%s\n' "ERROR: apk update failed (network access needed) - apk3 fetch does not re-download missing indexes by itself." ;;
	err_apk_update:*)  printf '%s\n' "FEHLER: apk update fehlgeschlagen (Netzzugang noetig) - apk3 fetch laedt fehlende Indizes nicht selbst nach." ;;
	err_apk_fetch:EN) printf '%s\n' "ERROR: apk fetch failed (network access to the chosen branch needed)." ;;
	err_apk_fetch:*)  printf '%s\n' "FEHLER: apk fetch fehlgeschlagen (Netzzugang zum gewaehlten Branch noetig)." ;;
	err_no_pkgs:EN) printf '%s\n' "ERROR: No packages downloaded - aborting." ;;
	err_no_pkgs:*)  printf '%s\n' "FEHLER: Keine Pakete geladen - Abbruch." ;;
	err_apk_index:EN) printf '%s\n' "ERROR: apk index failed (on UNTRUSTED: 'apk add --no-cache alpine-keys' and retry)." ;;
	err_apk_index:*)  printf '%s\n' "FEHLER: apk index fehlgeschlagen (bei UNTRUSTED: 'apk add --no-cache alpine-keys' und wiederholen)." ;;
	err_abuild_sign:EN) printf '%s\n' "ERROR: abuild-sign failed." ;;
	err_abuild_sign:*)  printf '%s\n' "FEHLER: abuild-sign fehlgeschlagen." ;;
	err_mkdir_apkovl:EN) printf '%s\n' "ERROR: Cannot create apkovl directory." ;;
	err_mkdir_apkovl:*)  printf '%s\n' "FEHLER: Kann apkovl-Verzeichnis nicht anlegen." ;;
	err_copy_etc:EN) printf '%s\n' "ERROR: Copying /etc failed." ;;
	err_copy_etc:*)  printf '%s\n' "FEHLER: Kopieren von /etc fehlgeschlagen." ;;
	err_copy_inc:EN) printf 'ERROR: Copying %s failed.\n'  "$1" ;;
	err_copy_inc:*) printf 'FEHLER: Kopieren von %s fehlgeschlagen.\n'  "$1" ;;
	err_copy_usrlocal:EN) printf '%s\n' "ERROR: Copying /usr/local failed." ;;
	err_copy_usrlocal:*)  printf '%s\n' "FEHLER: Kopieren von /usr/local fehlgeschlagen." ;;
	err_tar_apkovl:EN) printf '%s\n' "ERROR: Creating the apkovl failed." ;;
	err_tar_apkovl:*)  printf '%s\n' "FEHLER: Erzeugen des apkovl fehlgeschlagen." ;;
	err_internal_alpe:EN) printf '%s\n' "ERROR: Internal error: alpe-install missing in the apkovl." ;;
	err_internal_alpe:*)  printf '%s\n' "FEHLER: Interner Fehler: alpe-install fehlt im apkovl." ;;
	err_isolinux:EN) printf '%s\n' "ERROR: isolinux.bin missing (syslinux package)." ;;
	err_isolinux:*)  printf '%s\n' "FEHLER: isolinux.bin fehlt (syslinux-Paket)." ;;
	err_isohdpfx:EN) printf '%s\n' "ERROR: isohdpfx.bin missing (syslinux package)." ;;
	err_isohdpfx:*)  printf '%s\n' "FEHLER: isohdpfx.bin fehlt (syslinux-Paket)." ;;
	err_grub_mkimage:EN) printf '%s\n' "ERROR: grub-mkimage failed (grub-efi package installed correctly?)." ;;
	err_grub_mkimage:*)  printf '%s\n' "FEHLER: grub-mkimage fehlgeschlagen (grub-efi-Paket korrekt installiert?)." ;;
	err_efi_img:EN) printf '%s\n' "ERROR: Creating the EFI image failed." ;;
	err_efi_img:*)  printf '%s\n' "FEHLER: Erzeugen des EFI-Images fehlgeschlagen." ;;
	err_xorrisofs:EN) printf '%s\n' "ERROR: xorrisofs failed." ;;
	err_xorrisofs:*)  printf '%s\n' "FEHLER: xorrisofs fehlgeschlagen." ;;
	q_install_one:EN) printf "The package '%s' is needed for the build. Install it now? [Y/n]: \n"  "$1" ;;
	q_install_one:*) printf "Das Paket '%s' wird fuer den Bau benoetigt. Jetzt installieren? [J/n]: \n"  "$1" ;;
	q_install_pkgs:EN) printf 'Install missing packages (%s)? [Y/n]: \n'  "$1" ;;
	q_install_pkgs:*) printf 'Fehlende Pakete installieren (%s)? [J/n]: \n'  "$1" ;;
	info_missing_tools:EN) printf 'Missing tools: %s\n'  "$1" ;;
	info_missing_tools:*) printf 'Fehlende Werkzeuge: %s\n'  "$1" ;;
	info_installing:EN) printf 'Installing: %s\n'  "$1" ;;
	info_installing:*) printf 'Installiere: %s\n'  "$1" ;;
	info_pkg_installed:EN) printf 'Package %s installed.\n'  "$1" ;;
	info_pkg_installed:*) printf 'Paket %s installiert.\n'  "$1" ;;
	info_kernel:EN) printf 'Kernel: %s (flavor %s, arch %s)\n'  "$1" "$2" "$3" ;;
	info_kernel:*) printf 'Kernel: %s (Flavor %s, Arch %s)\n'  "$1" "$2" "$3" ;;
	info_using_key:EN) printf '%s\n' "Using existing signing key:" ;;
	info_using_key:*)  printf '%s\n' "Verwende vorhandenen Signier-Schluessel:" ;;
	info_gen_key:EN) printf '%s\n' "Generating new RSA signing key (2048 bit)" ;;
	info_gen_key:*)  printf '%s\n' "Erzeuge neuen RSA-Signier-Schluessel (2048 Bit)" ;;
	info_branch_from_source:EN) printf '%s\n' "taken from the source system" ;;
	info_branch_from_source:*)  printf '%s\n' "aus dem Quell-System uebernommen" ;;
	info_repo_branch:EN) printf 'Repository branch: %s\n'  "$1" ;;
	info_repo_branch:*) printf 'Repository-Branch: %s\n'  "$1" ;;
	info_source_branch:EN) printf '%s\n' "source system" ;;
	info_source_branch:*)  printf '%s\n' "Quell-System" ;;
	ph_modloop:EN) printf 'Building modloop (squashfs, compression: %s)\n'  "$1" ;;
	ph_modloop:*) printf 'Baue modloop (Squashfs, Kompression: %s)\n'  "$1" ;;
	ph_initramfs:EN) printf 'Building initramfs (features: %s)\n'  "$1" ;;
	ph_initramfs:*) printf 'Baue initramfs (Features: %s)\n'  "$1" ;;
	info_copy_kernel:EN) printf '%s\n' "Copying kernel" ;;
	info_copy_kernel:*)  printf '%s\n' "Kopiere Kernel" ;;
	ph_fetch_pkgs:EN) printf 'Collecting packages (branch: %s)\n'  "$1" ;;
	ph_fetch_pkgs:*) printf 'Sammle Pakete (Branch: %s)\n'  "$1" ;;
	info_update_indexes:EN) printf '%s\n' "Updating repository indexes" ;;
	info_update_indexes:*)  printf '%s\n' "Aktualisiere Repository-Indizes" ;;
	ph_apkindex:EN) printf '%s\n' "Creating and signing APKINDEX" ;;
	ph_apkindex:*)  printf '%s\n' "Erzeuge und signiere APKINDEX" ;;
	ph_apkovl:EN) printf '%s\n' "Building apkovl from the installation's /etc configuration" ;;
	ph_apkovl:*)  printf '%s\n' "Baue apkovl aus der /etc-Konfiguration der Installation" ;;
	info_homes:EN) printf 'Including home directories (%s kB):%s\n'  "$1" "$2" ;;
	info_homes:*) printf 'Nehme Heimatverzeichnisse auf (%s kB):%s\n'  "$1" "$2" ;;
	info_including:EN) printf '%s\n' "Including in apkovl:" ;;
	info_including:*)  printf '%s\n' "Nehme ins apkovl auf:" ;;
	info_usrlocal:EN) printf 'Including /usr/local in the apkovl (%s kB).\n'  "$1" ;;
	info_usrlocal:*) printf 'Nehme /usr/local ins apkovl auf (%s kB).\n'  "$1" ;;
	info_alpe_embedded:EN) printf '%s\n' "alpe-install embedded (apkovl + ISO root):" ;;
	info_alpe_embedded:*)  printf '%s\n' "alpe-install eingebettet (apkovl + ISO-Root):" ;;
	info_apkovl_ok:EN) printf '%s\n' "apkovl created and verified (alpe-install included)." ;;
	info_apkovl_ok:*)  printf '%s\n' "apkovl erzeugt und verifiziert (alpe-install enthalten)." ;;
	ph_syslinux:EN) printf '%s\n' "Building BIOS boot (syslinux)" ;;
	ph_syslinux:*)  printf '%s\n' "Baue BIOS-Boot (syslinux)" ;;
	ph_grub:EN) printf '%s\n' "Building UEFI boot (grub)" ;;
	ph_grub:*)  printf '%s\n' "Baue UEFI-Boot (grub)" ;;
	ph_hybrid:EN) printf '%s\n' "Building hybrid ISO (BIOS + UEFI)" ;;
	ph_hybrid:*)  printf '%s\n' "Baue Hybrid-ISO (BIOS + UEFI)" ;;
	info_done:EN) printf 'Done (%s):\n'  "$1" ;;
	info_done:*) printf 'Fertig (%s):\n'  "$1" ;;
	info_done_close:EN) printf '%s\n' "DONE - The ISO has been created. You can close this tool now." ;;
	info_done_close:*)  printf '%s\n' "FERTIG - Die ISO ist erstellt. Sie können dieses Tool jetzt schließen." ;;
	info_result:EN) printf 'Volume-ID: %s | Flavor: %s | Squashfs: %s\n'  "$1" "$2" "$3" ;;
	info_result:*) printf 'Volume-ID: %s | Flavor: %s | Squashfs: %s\n'  "$1" "$2" "$3" ;;
	info_boot:EN) printf 'Boot: BIOS (El Torito/isohybrid) and UEFI (grub, %s)\n'  "$1" ;;
	info_boot:*) printf 'Boot: BIOS (El Torito/isohybrid) und UEFI (grub, %s)\n'  "$1" ;;
	info_install_hint:EN) printf '%s\n' "Installation on a target system: boot the ISO, then 'alpe-install -d <disk>'" ;;
	info_install_hint:*)  printf '%s\n' "Installation auf Zielsystem: ISO booten, dann 'alpe-install -d <platte>'" ;;
	info_install_hint2:EN) printf '%s\n' "  (offline possible - kernel, bootloader and packages are included in the /apks repository;" ;;
	info_install_hint2:*)  printf '%s\n' "  (offline moeglich - Kernel, Bootloader und Pakete sind im /apks-Repository enthalten;" ;;
	info_install_hint3:EN) printf '%s\n' "   home directories and configuration are restored from the snapshot)" ;;
	info_install_hint3:*)  printf '%s\n' "   Heimatverzeichnisse und Konfiguration werden aus dem Snapshot wiederhergestellt)" ;;
	*) printf '%s\n' "$key" ;;
	esac
}
te() { t "$@" >&2; }
td() { t "$@" >&2; exit 1; }

# Farben gem. DESIGN.md (hell cyan/gelb/lila/rot/gruen, Fett = "1;3X").
# POSIX/ash-Umsetzung: [ -t 1 ] statt [[ -t 1 ]], printf '%b' statt echo -e.
# Der Block liegt NACH dem -de/-en/-nc-Vorscan, damit -nc wirkt.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
	# Echte ESC-Bytes: printf '%b' UND cat-Heredocs (usage) funktionieren.
	COLOR_ESC=$(printf '\033')
	readonly COLOR_ESC
	readonly COLOR_RESET="${COLOR_ESC}[0m"
	readonly COLOR_HEADING="${COLOR_ESC}[1;96m"  # Hell-Cyan: Ueberschriften
	readonly COLOR_TEXT="${COLOR_ESC}[1;93m"     # Hell-Gelb: normaler Text
	readonly COLOR_FILE="${COLOR_ESC}[1;35m"     # Hell-Lila: Dateien/Pfade/Befehle
	readonly COLOR_TXT="${COLOR_ESC}[1;91m"      # Hell-Rot: Warnungen/Fehler (.txt)
	readonly COLOR_OTHER="${COLOR_ESC}[1;92m"    # Hell-Gruen: alles andere
else
	readonly COLOR_ESC=''
	readonly COLOR_RESET=''
	readonly COLOR_HEADING=''
	readonly COLOR_TEXT=''
	readonly COLOR_FILE=''
	readonly COLOR_TXT=''
	readonly COLOR_OTHER=''
fi

print_heading() { printf '%b\n' "${COLOR_HEADING}$*${COLOR_RESET}"; }
print_text()    { printf '%b\n' "${COLOR_TEXT}$*${COLOR_RESET}"; }
print_text_n()  { printf '%b'   "${COLOR_TEXT}$*${COLOR_RESET}"; }
print_file()    { printf '%b\n' "${COLOR_FILE}$*${COLOR_RESET}"; }
print_txt()     { printf '%b\n' "${COLOR_TXT}$*${COLOR_RESET}"; }
print_other()   { printf '%b\n' "${COLOR_OTHER}$*${COLOR_RESET}"; }
print_path() {
	case "$1" in
	*.txt) print_txt "$1" ;;
	*)     print_file "$1" ;;
	esac
}
# Eine Zeile: gelber Text + Pfad in Design-Farbe ("Label: Pfad")
print_info_path() {
	printf '%b' "${COLOR_TEXT}$1 ${COLOR_RESET}"
	print_path "$2"
}

warn() { printf '%b\n' "${COLOR_TXT}WARNUNG: $*${COLOR_RESET}" >&2; }
die()  { printf '%b\n' "${COLOR_TXT}FEHLER: $*${COLOR_RESET}" >&2; exit 1; }

# Paket nach j/n-Rueckfrage installieren (AGENTS.md "Ask First").
# Wartet auf Eingabe; Standard (leere Eingabe/EOF) ist "Ja" [J/n].
# Rueckgabe 0 = installiert (oder bereits vorhanden), 1 = abgelehnt/fehler.
ask_install_pkg() {
	install_pkg=$1
	if command -v "$install_pkg" >/dev/null 2>&1; then
		return 0
	fi
	print_text_n "$(t q_install_one "$install_pkg")"
	read -r install_ans || install_ans=
	case "$install_ans" in
	n|N|nein|Nein|NEIN|no|No|NO)
		te warn_declined_install "$install_pkg"
		return 1 ;;
	*)
		apk add --no-cache "$install_pkg" || return 1
		print_other "$(t info_pkg_installed "$install_pkg")"
		return 0 ;;
	esac
}

usage() {
	case "$SPRACHE" in
	EN)
		cat >&2 <<-__EOF__
			${COLOR_HEADING}$PROGRAM $VERSION - Create a live ISO of an installed Alpine system${COLOR_RESET}

			${COLOR_HEADING}Usage:${COLOR_RESET} ${COLOR_TXT}$PROGRAM [options]${COLOR_RESET}

			${COLOR_HEADING}Options:${COLOR_RESET}
			  ${COLOR_FILE}-o, --output FILE${COLOR_OTHER}       Target ISO (default: ./alpe-live-<arch>-<date>.iso)
			  ${COLOR_FILE}-c, --compression MOD${COLOR_OTHER}   Squashfs compression of the modloop:
			                          zstd (default) | gzip | xz | lzo | lz4
			  ${COLOR_FILE}-f, --flavor NAME${COLOR_OTHER}       Kernel flavor (default: auto-detected)
			  ${COLOR_FILE}-I, --include DIR${COLOR_OTHER}       Include an additional directory in the apkovl
			                          (repeatable, e.g. -I /home -I /opt)
			  ${COLOR_FILE}-F, --full-firmware${COLOR_OTHER}     Put the complete linux-firmware into the
			                          /apks repository (larger, but offline universal)
			  ${COLOR_FILE}-B, --branch BRANCH${COLOR_OTHER}     Force the apk branch (edge, latest-stable, 3.22,
			                          ...). Without -B the branch of the source system
			                          is used.
			  ${COLOR_FILE}--no-home${COLOR_OTHER}               Do NOT automatically include home directories
			                          (default: home directories of all login users
			                          are backed up)
			  ${COLOR_FILE}-w, --workdir DIR${COLOR_OTHER}       Build directory (not deleted)
			  ${COLOR_FILE}-h, --help${COLOR_OTHER}              Show this help
			  ${COLOR_FILE}-V, --version${COLOR_OTHER}           Show version
			  ${COLOR_FILE}-de | -en${COLOR_OTHER}               Force the language (German/English)
			  ${COLOR_FILE}-nc${COLOR_OTHER}                     Turn colors off

			${COLOR_HEADING}Examples:${COLOR_RESET}
			  ${COLOR_FILE}$PROGRAM -o alpe.iso${COLOR_OTHER}
			  ${COLOR_FILE}$PROGRAM -c xz -I /home${COLOR_OTHER}
			  ${COLOR_FILE}$PROGRAM -F -w /tmp/alpe-build${COLOR_OTHER}

			${COLOR_TEXT}The ISO boots via BIOS and UEFI and can be installed offline on
			other machines with setup-alpine/setup-disk.${COLOR_RESET}
		__EOF__
		;;
	*)
		cat >&2 <<-__EOF__
			${COLOR_HEADING}$PROGRAM $VERSION - Live-ISO eines installierten Alpine-Systems erzeugen${COLOR_RESET}

			${COLOR_HEADING}Verwendung:${COLOR_RESET} ${COLOR_TXT}$PROGRAM [Optionen]${COLOR_RESET}

			${COLOR_HEADING}Optionen:${COLOR_RESET}
			  ${COLOR_FILE}-o, --output DATEI${COLOR_OTHER}      Ziel-ISO (Standard: ./alpe-live-<arch>-<datum>.iso)
			  ${COLOR_FILE}-c, --compression MOD${COLOR_OTHER}   Squashfs-Kompression des modloop:
			                          zstd (Standard) | gzip | xz | lzo | lz4
			  ${COLOR_FILE}-f, --flavor NAME${COLOR_OTHER}       Kernel-Flavor (Standard: automatisch erkannt)
			  ${COLOR_FILE}-I, --include DIR${COLOR_OTHER}       Zusaetzliches Verzeichnis ins apkovl aufnehmen
			                          (wiederholbar, z. B. -I /home -I /opt)
			  ${COLOR_FILE}-F, --full-firmware${COLOR_OTHER}     Komplette linux-firmware ins /apks-Repository
			                          legen (groesser, aber offline universeller)
			  ${COLOR_FILE}-B, --branch BRANCH${COLOR_OTHER}     apk-Branch erzwingen (edge, latest-stable, 3.22,
			                          ...). Ohne -B wird der Branch des Quell-Systems
			                          uebernommen.
			  ${COLOR_FILE}--no-home${COLOR_OTHER}               Heimatverzeichnisse NICHT automatisch
			                          aufnehmen (Standard: Home-Verzeichnisse aller
			                          Login-Benutzer werden mitgesichert)
			  ${COLOR_FILE}-w, --workdir DIR${COLOR_OTHER}       Bau-Verzeichnis (wird nicht geloescht)
			  ${COLOR_FILE}-h, --help${COLOR_OTHER}              Diese Hilfe anzeigen
			  ${COLOR_FILE}-V, --version${COLOR_OTHER}           Version anzeigen
			  ${COLOR_FILE}-de | -en${COLOR_OTHER}               Sprache fest erzwingen (Deutsch/Englisch)
			  ${COLOR_FILE}-nc${COLOR_OTHER}                     Farben abschalten

			${COLOR_HEADING}Beispiele:${COLOR_RESET}
			  ${COLOR_FILE}$PROGRAM -o alpe.iso${COLOR_OTHER}
			  ${COLOR_FILE}$PROGRAM -c xz -I /home${COLOR_OTHER}
			  ${COLOR_FILE}$PROGRAM -F -w /tmp/alpe-build${COLOR_OTHER}

			${COLOR_TEXT}Das ISO bootet per BIOS und UEFI und laesst sich auf anderen Rechnern
			mit setup-alpine/setup-disk offline installieren.${COLOR_RESET}
		__EOF__
		;;
	esac
}

cleanup() {
	if [ "$WORK_OWNED" = yes ] && [ -n "$WORK" ]; then
		rm -rf -- "$WORK" 2>/dev/null || :
	fi
}

# ---------------------------------------------------------------- Optionen --

OPTS=$(getopt -o o:c:f:I:FB:w:hV \
	-l output:,compression:,flavor:,include:,full-firmware,no-home,branch:,workdir:,help,version \
	-n "$PROGRAM" -- "$@") || usage
eval set -- "$OPTS"
while :; do
	case "$1" in
	-o|--output)        OUTPUT=$2; shift 2 ;;
	-c|--compression)   COMPRESSION=$2; shift 2 ;;
	-f|--flavor)        FLAVOR=$2; shift 2 ;;
	-I|--include)       INCLUDE_DIRS="$INCLUDE_DIRS $2"; shift 2 ;;
	-F|--full-firmware) FULL_FIRMWARE=yes; shift ;;
	--no-home)          NO_HOME=yes; shift ;;
	-B|--branch)        BRANCH=$2; shift 2 ;;
	-w|--workdir)       WORK=$2; WORK_OWNED=no; shift 2 ;;
	-h|--help)          usage; exit 0 ;;
	-V|--version)       echo "$PROGRAM $VERSION"; exit 0 ;;
	--)                 shift; break ;;
	*)                  usage; exit 1 ;;
	esac
done
[ $# -eq 0 ] || { usage; exit 1; }

print_heading "$PROGRAM $VERSION"

# ------------------------------------------------------------- Voraussetzungen --

case "$COMPRESSION" in
zstd|gzip|xz|lzo|lz4) ;;
*) td err_bad_compression "$COMPRESSION" ;;
esac

# Branch nur aus URL-sicheren Zeichen (wird Teil der Mirror-URL)
if [ -n "$BRANCH" ]; then
	case "$BRANCH" in
	*[!A-Za-z0-9._-]*) td err_bad_branch "$BRANCH" ;;
	esac
fi

# Root-Rechte: wenn nicht root, das Skript DIREKT per sudo/su als root neu
# starten (sudo fragt selbst nach dem Passwort) - noetig, wenn das Skript
# z. B. aus einem Menue heraus als normaler Benutzer gestartet wurde
if [ "$(id -u)" -ne 0 ]; then
	if [ "${MKALPE_SUDO_ASKED:-0}" = "1" ]; then
		# Fehlkonfiguration: sudo lief keine echte Root-Shell -> Abbruch statt Endlosschleife
		td err_not_root
	fi
	if command -v sudo >/dev/null 2>&1; then
		exec sudo env MKALPE_SUDO_ASKED=1 sh "$0"
	else
		# Alpine lebt oft ohne sudo - Rueckfallebene su
		exec su root -c "MKALPE_SUDO_ASKED=1 sh '$0'"
	fi
fi
[ -f "$ALPE_ROOT/etc/alpine-release" ] || td err_not_alpine "$ALPE_ROOT"

ARCH=$(apk --print-arch 2>/dev/null) || ARCH=
[ -n "$ARCH" ] || td err_print_arch
case "$ARCH" in
x86_64) EFI_FORMAT=x86_64-efi; EFI_BIN=bootx64.efi; BCJ=x86 ;;
x86)    EFI_FORMAT=i386-efi;   EFI_BIN=bootia32.efi; BCJ=x86 ;;
*) td err_bad_arch "$ARCH" ;;
esac

# apk-Paket zu einem benoetigten Werkzeug (fuer die Nachinstall-Frage)
pkg_for() {
	case "$1" in
	xorrisofs)     echo xorriso ;;
	mksquashfs)    echo squashfs-tools ;;
	mkinitfs)      echo mkinitfs ;;
	grub-mkimage)  echo grub ;;
	mformat|mcopy) echo mtools ;;
	abuild-sign)   echo abuild ;;
	openssl)       echo openssl ;;
	depmod)        echo kmod ;;
	syslinux)      echo syslinux ;;
	grub-efi)      echo grub-efi ;;
	*)             : ;;
	esac
}

# Liste fehlender Werkzeuge; "name(...)" = Kommando vorhanden, aber
# benoetigte Dateien fehlen (z. B. syslinux-Bootdateien)
missing_tools() {
	missing=
	for cmd in xorrisofs mksquashfs mkinitfs grub-mkimage mformat mcopy abuild-sign openssl depmod; do
		command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
	done
	[ -f "$SYSLINUX_SHARE/isohdpfx.bin" ] && [ -f "$SYSLINUX_SHARE/isolinux.bin" ] \
		&& [ -f "$SYSLINUX_SHARE/ldlinux.c32" ] || missing="$missing syslinux(Dateien)"
	[ -d "$GRUB_LIB/$EFI_FORMAT" ] || missing="$missing grub-efi($EFI_FORMAT)"
	printf '%s\n' "${missing# }"
}

MISSING=$(missing_tools)
if [ -n "$MISSING" ]; then
	print_text "$(t info_missing_tools "$MISSING")"
	# zugehoerige apk-Pakete sammeln (Dubletten entfernen)
	MISSING_PKGS=
	# shellcheck disable=SC2086
	for m_tool in $MISSING; do
		case "$m_tool" in
		*\(*) m_tool=${m_tool%%\(*} ;;
		esac
		m_pkg=$(pkg_for "$m_tool")
		[ -n "$m_pkg" ] || continue
		case " $MISSING_PKGS " in
		*" $m_pkg "*) continue ;;
		esac
		MISSING_PKGS="$MISSING_PKGS $m_pkg"
	done
	MISSING_PKGS=${MISSING_PKGS# }
	if [ -n "$MISSING_PKGS" ]; then
		# Standard ist "Ja": leere Eingabe/EOF installiert (AGENTS.md-Rueckfrage, Standard J/n)
		print_text_n "$(t q_install_pkgs "$MISSING_PKGS")"
		read -r install_ans || install_ans=
		case "$install_ans" in
		n|N|nein|Nein|NEIN|no|No|NO)
			te warn_declined ;;
		*)
			print_text "$(t info_installing "$MISSING_PKGS")"
			# shellcheck disable=SC2086
			apk add --no-cache $MISSING_PKGS || te warn_apk_add_failed
			;;
		esac
	fi
	MISSING=$(missing_tools)
	[ -z "$MISSING" ] || td err_missing_tools_final "$MISSING"
fi

# ------------------------------------------------------------- Kernel-Flavor --

MODBASE="$ALPE_ROOT/lib/modules"
[ -d "$MODBASE" ] || td err_no_modules "$MODBASE"

# Alle installierten Kernel-Versionen (Verzeichnisse beginnen mit der Version)
KVERS=
for k_dir in "$MODBASE"/*; do
	case "${k_dir##*/}" in
	[0-9]*) KVERS="$KVERS
${k_dir##*/}" ;;
	esac
done
KVERS=${KVERS#
}
[ -n "$KVERS" ] || td err_no_kvers "$MODBASE"

if [ -n "$FLAVOR" ]; then
	KVER=$(printf '%s\n' "$KVERS" | grep -E -- "-$FLAVOR\$" | sort -V | tail -n 1)
	[ -n "$KVER" ] || td err_no_kernel_flavor "$FLAVOR" "$MODBASE"
else
	# neueste Version waehlen, Flavor aus dem Suffix ableiten (z. B. 6.12.8-1-lts)
	KVER=$(printf '%s\n' "$KVERS" | sort -V | tail -n 1)
	FLAVOR=${KVER##*-}
fi
print_text "$(t info_kernel "$KVER" "$FLAVOR" "$ARCH")"

VMLINUZ=
for k_vmlinuz in "$ALPE_ROOT/boot/vmlinuz-$FLAVOR" "$ALPE_ROOT/boot/vmlinuz-$KVER" "$ALPE_ROOT/boot/vmlinuz"; do
	if [ -f "$k_vmlinuz" ]; then VMLINUZ=$k_vmlinuz; break; fi
done
[ -n "$VMLINUZ" ] || td err_no_vmlinuz "$ALPE_ROOT" "$FLAVOR"

# ------------------------------------------------------------- Arbeitsverzeichnis --

if [ -n "$WORK" ]; then
	case "$WORK" in
	/|"$ALPE_ROOT"|"$ALPE_ROOT"/) td err_bad_workdir "$WORK" ;;
	esac
	mkdir -p "$WORK" || td err_mkdir_workdir "$WORK"
else
	WORK=$(mktemp -d /tmp/mkalpe-live.XXXXXX) || td err_mktemp
	WORK_OWNED=yes
fi
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

if [ -z "$OUTPUT" ]; then
	OUTPUT="$PWD/alpe-live-$ARCH-$(date +%Y%m%d).iso"
fi
case "$OUTPUT" in
"$WORK"/*) td err_iso_in_workdir ;;
esac

ISODIR="$WORK/iso"
# Bei Wiederverwendung eines -w-Verzeichnisses alte Staging-Bestandteile entfernen
rm -rf "$ISODIR" "$WORK/apkovl" "$WORK/iso" "$WORK/repositories" \
	"$WORK/ko.list" "$WORK/fw.list" "$WORK/grub_early.cfg" 2>/dev/null || :
mkdir -p "$ISODIR/boot/syslinux" "$ISODIR/boot/grub" "$ISODIR/efi/boot" \
	"$ISODIR/apks/$ARCH" || td err_mkdir_iso

VOLID="alpe-live-$ARCH"

# ------------------------------------------------------------- Signier-Schluessel --

ensure_sign_key() {
	k_pub_target="$ALPE_ROOT/etc/apk/keys/$PUBKEY_NAME"
	if [ -f "$PRIVKEY" ] && [ -f "$k_pub_target" ]; then
		print_info_path "$(t info_using_key)" "$PRIVKEY"
		return 0
	fi
	mkdir -p "$KEYDIR" "$ALPE_ROOT/etc/apk/keys" || td err_mkdir_keydir
	print_text "$(t info_gen_key)"
	umask 077
	openssl genrsa -out "$PRIVKEY.new" 2048 >/dev/null 2>&1 \
		|| td err_genrsa
	mv -f "$PRIVKEY.new" "$PRIVKEY"
	openssl rsa -in "$PRIVKEY" -pubout -out "$k_pub_target.new" >/dev/null 2>&1 \
		|| td err_pubkey
	mv -f "$k_pub_target.new" "$k_pub_target"
	chmod 644 "$k_pub_target"
	umask 022
}

ensure_sign_key

# Der Schluessel muss VOR mkinitfs in den Keys liegen, damit er im initramfs
# landet und der initramfs-apk das /apks-Repository vertraut.

# ------------------------------------------------------------- Repositories --

# Spiegel-Strategie: Mit -B/--branch wird ein Branch erzwungen (z. B. edge
# oder 3.22); ohne -B werden die Repositories des Quell-Systems uebernommen
# (Mirror-Treue, warmer Index-Cache). Zusaetzliche Repos via ALPE_EXTRA_REPOS.
# URL-Besonderheit: stabile Branches tragen ein "v"-Praefix (/alpine/v3.22),
# edge und latest-stable nicht. "3.22" wird daher automatisch zu "v3.22".
copy_repositories() {
	{
		if [ -n "$BRANCH" ]; then
			b_url=$BRANCH
			case "$BRANCH" in
			[0-9]*) b_url="v$BRANCH" ;;
			esac
			echo "$ALPE_MIRROR/$b_url/main"
			echo "$ALPE_MIRROR/$b_url/community"
		elif [ -r "$ALPE_ROOT/etc/apk/repositories" ]; then
			grep -Ev '^[[:space:]]*(#|$)' "$ALPE_ROOT/etc/apk/repositories"
		else
			echo "$ALPE_MIRROR/edge/main"
			echo "$ALPE_MIRROR/edge/community"
		fi
		# shellcheck disable=SC2086
		for r in $ALPE_EXTRA_REPOS; do
			echo "$r"
		done
	}
}

FETCH_REPOS="$WORK/repositories"
copy_repositories > "$FETCH_REPOS"
print_text "$(t info_repo_branch "${BRANCH:-$(t info_branch_from_source)}")"
print_path "$FETCH_REPOS"

# ------------------------------------------------------------- modloop (Squashfs) --

print_heading "$(t ph_modloop "$COMPRESSION")"
ML_DIR="$WORK/modloop"
rm -rf "$ML_DIR"
# depmod -b erwartet BASE/lib/modules/$KVER; fertiges modloop braucht modules/ oben
mkdir -p "$ML_DIR/lib/modules/$KVER" || td err_mkdir_modloop
cp -a "$MODBASE/$KVER/." "$ML_DIR/lib/modules/$KVER/" \
	|| td err_copy_modules

# Komprimiert ausgelieferte Kernel-Module dekomprimieren (wie update-kernel);
# entpackte Module komprimieren sich im Squashfs deutlich besser. zstd ist
# Standard und wird bei Bedarf per j/n-Frage nachinstalliert, xz ist optional.
find "$ML_DIR/lib/modules/$KVER" -type f -name '*.ko.gz' -exec gzip -d -- {} + 2>/dev/null || :
kozst_probe=$(find "$ML_DIR/lib/modules/$KVER" -type f -name '*.ko.zst' 2>/dev/null | head -n 1)
if [ -n "$kozst_probe" ]; then
	if command -v zstd >/dev/null 2>&1; then
		find "$ML_DIR/lib/modules/$KVER" -type f -name '*.ko.zst' -exec zstd --rm -d -- {} + 2>/dev/null || :
	elif ask_install_pkg zstd; then
		find "$ML_DIR/lib/modules/$KVER" -type f -name '*.ko.zst' -exec zstd --rm -d -- {} + 2>/dev/null || :
	else
		te warn_no_zstd
	fi
fi
kozxz_probe=$(find "$ML_DIR/lib/modules/$KVER" -type f -name '*.ko.xz' 2>/dev/null | head -n 1)
if [ -n "$kozxz_probe" ]; then
	if command -v xz >/dev/null 2>&1; then
		find "$ML_DIR/lib/modules/$KVER" -type f -name '*.ko.xz' -exec xz -d -- {} + 2>/dev/null || :
	else
		te warn_no_xz
	fi
fi

depmod -b "$ML_DIR" "$KVER" || td err_depmod
mv "$ML_DIR/lib/modules" "$ML_DIR/modules" || td err_modloop_layout
rmdir "$ML_DIR/lib"

ML_MODULES="$ML_DIR/modules/$KVER"
ML_FIRMWARE="$ML_DIR/modules/firmware"

# Firmware: alle von Modulen referenzierten Dateien uebernehmen
mkdir -p "$ML_FIRMWARE"
if command -v modinfo >/dev/null 2>&1; then
	find "$ML_MODULES" -type f -name '*.ko*' -print > "$WORK/ko.list"
	while read -r ml_ko; do
		modinfo -F firmware "$ml_ko" 2>/dev/null || :
	done < "$WORK/ko.list" | sort -u > "$WORK/fw.list" || :
	while read -r ml_fw; do
		[ -n "$ml_fw" ] || continue
		for ml_src in \
			"$ALPE_ROOT/lib/firmware/$ml_fw" \
			"$ALPE_ROOT/lib/firmware/$ml_fw.xz" \
			"$ALPE_ROOT/lib/firmware/$ml_fw.zst"; do
			if [ -e "$ml_src" ]; then
				ml_dst="$ML_FIRMWARE/$ml_fw${ml_src#"$ALPE_ROOT"/lib/firmware/"$ml_fw"}"
				mkdir -p "${ml_dst%/*}"
				cp -a "$ml_src" "$ml_dst" || :
				break
			fi
		done
	done < "$WORK/fw.list"
	[ -s "$WORK/fw.list" ] || te warn_no_firmware
else
	te warn_no_modinfo
fi

# Wireless-Regulatory-DB (falls cfg80211 vorhanden)
if [ -d "$ML_MODULES/kernel/net/wireless" ]; then
	for ml_rdb in "$ALPE_ROOT"/lib/firmware/regulatory.db*; do
		[ -e "$ml_rdb" ] || continue
		cp -a "$ml_rdb" "$ML_FIRMWARE/" || :
	done
fi

SQUASH_OPTS="-comp $COMPRESSION -noappend -exit-on-error"
[ "$COMPRESSION" = xz ] && SQUASH_OPTS="$SQUASH_OPTS -Xbcj $BCJ"
# shellcheck disable=SC2086
mksquashfs "$ML_DIR" "$ISODIR/boot/modloop-$FLAVOR" $SQUASH_OPTS \
	|| td err_mksquashfs

# ------------------------------------------------------------- initramfs --

case "$ARCH" in
x86_64) INITFS_FEATURES="$INITFS_FEATURES nfit" ;;
esac

print_heading "$(t ph_initramfs "$INITFS_FEATURES")"
mkinitfs -q -b "$ALPE_ROOT" -F "$INITFS_FEATURES" \
	-o "$ISODIR/boot/initramfs-$FLAVOR" "$KVER" \
	|| td err_mkinitfs

# ------------------------------------------------------------- Kernel-Dateien --

print_text "$(t info_copy_kernel)"
cp "$VMLINUZ" "$ISODIR/boot/vmlinuz-$FLAVOR" || td err_copy_kernel
for k_file in config System.map; do
	if [ -f "$ALPE_ROOT/boot/$k_file-$FLAVOR" ]; then
		cp "$ALPE_ROOT/boot/$k_file-$FLAVOR" "$ISODIR/boot/" || :
	elif [ -f "$ALPE_ROOT/boot/$k_file-$KVER" ]; then
		cp "$ALPE_ROOT/boot/$k_file-$KVER" "$ISODIR/boot/" || :
	fi
done

# ------------------------------------------------------------- /apks-Repository --

print_heading "$(t ph_fetch_pkgs "${BRANCH:-$(t info_source_branch)}")"

WORLD_SRC="$ALPE_ROOT/etc/apk/world"
[ -r "$WORLD_SRC" ] || td err_no_world "$WORLD_SRC"
LIVE_WORLD=
while read -r w_pkg; do
	case "$w_pkg" in
	""|"#"*) continue ;;
	linux-*) continue ;;   # Kernel/Firmware: nur /apks, nicht ins RAM-System
	esac
	LIVE_WORLD="$LIVE_WORLD $w_pkg"
done < "$WORLD_SRC"

# Installations-Helfer: damit setup-alpine/setup-disk im Live-System offline laeuft
HELPER_PKGS="alpine-conf chrony openssh doas e2fsprogs dosfstools sfdisk parted util-linux mkinitfs grub-bios grub-efi syslinux linux-firmware-none"
FETCH_PKGS="$LIVE_WORLD $HELPER_PKGS alpine-base linux-$FLAVOR"
if [ "$FULL_FIRMWARE" = yes ]; then
	FETCH_PKGS="$FETCH_PKGS linux-firmware"
fi

APKDIR="$ISODIR/apks/$ARCH"
print_text "$(t info_update_indexes)"
apk --repositories-file "$FETCH_REPOS" update --quiet \
	|| td err_apk_update
# shellcheck disable=SC2086
apk --repositories-file "$FETCH_REPOS" fetch --recursive --output "$APKDIR" $FETCH_PKGS \
	|| td err_apk_fetch
ls "$APKDIR"/*.apk >/dev/null 2>&1 || td err_no_pkgs

touch "$ISODIR/apks/.boot_repository"

print_heading "$(t ph_apkindex)"
apk --keys-dir "$ALPE_ROOT/etc/apk/keys" index \
	--description "alpe-live $VERSION $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
	--rewrite-arch "$ARCH" \
	--output "$APKDIR/APKINDEX.tar.gz" \
	"$APKDIR"/*.apk || td err_apk_index
abuild-sign -k "$PRIVKEY" -p "$PUBKEY_NAME" "$APKDIR/APKINDEX.tar.gz" \
	|| td err_abuild_sign

# ------------------------------------------------------------- apkovl (/etc der Installation) --

print_heading "$(t ph_apkovl)"
OVL_DIR="$WORK/apkovl"
mkdir -p "$OVL_DIR/etc" || td err_mkdir_apkovl
cp -a "$ALPE_ROOT/etc/." "$OVL_DIR/etc/" || td err_copy_etc

# fstab fuer Diskless-Betrieb ersetzen
cat > "$OVL_DIR/etc/fstab" <<-__EOF__
	tmpfs / tmpfs defaults,mode=0755 0 0
	/dev/cdrom /media/cdrom iso9660 noauto,ro 0 0
	/dev/usbdisk /media/usb vfat noauto,ro 0 0
__EOF__

# Netzwerk-Repos NICHT als /etc/apk/repositories mitgeben: Das initramfs
# ersetzt eine vorhandene Datei nicht, und der Offline-Boot (--no-network)
# warnt fuer jede nicht erreichbare URL ("opening from cache ... No such
# file or directory"). Ohne Datei schreibt das initramfs automatisch nur das
# echte Boot-Medium hinein -> ruhiger Boot (Verhalten wie offizielles ISO).
# Die Netzwerk-Repos wandern als repositories.alpe-network mit; alpe-install
# stellt daraus /etc/apk/repositories des installierten Systems her.
rm -f "$OVL_DIR/etc/apk/repositories"
copy_repositories > "$OVL_DIR/etc/apk/repositories.alpe-network"

# world: gefilterte Paketliste + Installations-Helfer
{
	# shellcheck disable=SC2086
	for w_pkg in $LIVE_WORLD $HELPER_PKGS; do
		echo "$w_pkg"
	done
} > "$OVL_DIR/etc/apk/world"

# Boot-Services sicherstellen (identisch zum Standard-Diskless-Boot)
rc_ensure() {
	[ -e "$OVL_DIR/etc/init.d/$1" ] || return 0
	mkdir -p "$OVL_DIR/etc/runlevels/$2"
	ln -sf "/etc/init.d/$1" "$OVL_DIR/etc/runlevels/$2/$1"
}
for svc in devfs dmesg mdev hwdrivers modloop; do rc_ensure "$svc" sysinit; done
for svc in modules sysctl hostname bootmisc syslog hwclock; do rc_ensure "$svc" boot; done
for svc in mount-ro killprocs savecache; do rc_ensure "$svc" shutdown; done

# Heimatverzeichnisse aller Login-Benutzer automatisch aufnehmen (Aliase,
# Konfigurationen, Daten). Systemkonten (nologin/false) und /var-Daten werden
# uebersprungen; mit --no-home abschaltbar.
if [ "$NO_HOME" != yes ]; then
	p_home_list=
	# shellcheck disable=SC2034  # p_user ist Positions-Platzhalter im read
	while IFS=: read -r p_user _p_pw _p_uid _p_gid _p_gecos p_home p_shell; do
		case "$p_shell" in
		""|*/false|*/nologin|*/sync|*/shutdown|*/halt) continue ;;
		esac
		# Nur echte Nutzer-Verzeichnisse: /home/* und /root. Alles andere
		# (Systemkonten wie sync/halt/shutdown mit Home=/sbin o. a. Dienste)
		# ist System- und kein Nutzerinhalt; Sonderfaelle ueber -I.
		case "$p_home" in
		/home/*|/root) ;;
		*) continue ;;
		esac
		case " $INCLUDE_DIRS " in
		*" $p_home "*) continue ;;
		esac
		[ -d "$ALPE_ROOT$p_home" ] || continue
		p_home_list="$p_home_list $p_home"
	done < "$ALPE_ROOT/etc/passwd"
	# shellcheck disable=SC2086
	set -- $p_home_list
	if [ $# -gt 0 ]; then
		home_kb=$(du -sk "$@" 2>/dev/null | awk '{s += $1} END {print s + 0}')
		print_text "$(t info_homes "$home_kb" "$p_home_list")"
		if [ "$home_kb" -gt 1572864 ]; then
			te warn_homes_big "$home_kb"
		fi
		INCLUDE_DIRS="$INCLUDE_DIRS$p_home_list"
	fi
fi

# zusaetzliche Verzeichnisse (-I) ins apkovl uebernehmen
# shellcheck disable=SC2086
for inc in $INCLUDE_DIRS; do
	case "$inc" in
	/*) ;;
	*) te warn_inc_ignored "$inc"; continue ;;
	esac
	if [ -e "$ALPE_ROOT/$inc" ]; then
		print_info_path "$(t info_including)" "$inc"
		mkdir -p "$OVL_DIR/$inc"
		cp -a "$ALPE_ROOT/$inc/." "$OVL_DIR/$inc/" || td err_copy_inc "$inc"
	else
		te warn_inc_missing "$inc"
	fi
done

# Host-spezifische Netzwerk-Interfaces koennen auf anderer Hardware fehlen
[ -e "$OVL_DIR/etc/network/interfaces" ] && \
	te warn_interfaces

# /usr/local des Quell-Systems mitnehmen (manuell installierte Programme);
# nur wenn es ueberhaupt Inhalt hat (Dateien/Symlinks), sonst bleibt es weg.
if [ -d "$ALPE_ROOT/usr/local" ] \
	&& [ -n "$(find "$ALPE_ROOT/usr/local" -type f -o -type l 2>/dev/null | head -n 1)" ]; then
	mkdir -p "$OVL_DIR/usr"
	cp -a "$ALPE_ROOT/usr/local" "$OVL_DIR/usr/local" \
		|| td err_copy_usrlocal
	local_kb=$(du -sk "$OVL_DIR/usr/local" 2>/dev/null | awk '{print $1}')
	print_text "$(t info_usrlocal "${local_kb:-0}")"
fi

# alpe-install OPTIONAL einbetten (apkovl + ISO-Root). Ohne es entsteht eine
# reine Live-ISO. Akzeptierte Namen: alpe-install.sh / alpe-install, im
# Skript- oder Arbeitsverzeichnis.
case "$0" in
*/*) SCRIPT_DIR=${0%/*} ;;
*)   SCRIPT_DIR=. ;;
esac
alpe_install_src=
for alpe_cand in \
	"$SCRIPT_DIR/alpe-install.sh" "$SCRIPT_DIR/alpe-install" \
	"$PWD/alpe-install.sh" "$PWD/alpe-install"; do
	if [ -f "$alpe_cand" ]; then
		alpe_install_src=$alpe_cand
		break
	fi
done
if [ -n "$alpe_install_src" ]; then
	mkdir -p "$OVL_DIR/usr/local/bin"
	cp "$alpe_install_src" "$OVL_DIR/usr/local/bin/alpe-install"
	chmod 755 "$OVL_DIR/usr/local/bin/alpe-install"
	cp "$alpe_install_src" "$ISODIR/alpe-install.sh"
	print_info_path "$(t info_alpe_embedded)" "$alpe_install_src"
fi

tar -C "$OVL_DIR" -czf "$ISODIR/localhost.apkovl.tar.gz" . \
	|| td err_tar_apkovl

# Verifikation erst NACH der Archiv-Erzeugung (Bug #14: stand vorher davor)
if ! tar -tzf "$ISODIR/localhost.apkovl.tar.gz" | grep -q "usr/local/bin/alpe-install"; then
	td err_internal_alpe
fi
print_other "$(t info_apkovl_ok)"

# ------------------------------------------------------------- BIOS: syslinux --

print_heading "$(t ph_syslinux)"
for s_file in isolinux.bin isohdpfx.bin ldlinux.c32 libcom32.c32 libutil.c32; do
	if [ -f "$SYSLINUX_SHARE/$s_file" ]; then
		cp "$SYSLINUX_SHARE/$s_file" "$ISODIR/boot/syslinux/" || :
	fi
done
[ -f "$ISODIR/boot/syslinux/isolinux.bin" ] || td err_isolinux
[ -f "$ISODIR/boot/syslinux/isohdpfx.bin" ] || td err_isohdpfx

cat > "$ISODIR/boot/syslinux/syslinux.cfg" <<-__EOF__
	TIMEOUT 50
	PROMPT 1
	DEFAULT $FLAVOR

	LABEL $FLAVOR
		KERNEL /boot/vmlinuz-$FLAVOR
		INITRD /boot/initramfs-$FLAVOR
		APPEND $BOOT_CMDLINE
__EOF__

# ------------------------------------------------------------- UEFI: grub --

print_heading "$(t ph_grub)"
cat > "$WORK/grub_early.cfg" <<-__EOF__
	search --no-floppy --set=root --label $VOLID
	set prefix=(\$root)/boot/grub
__EOF__

# shellcheck disable=SC2086
grub-mkimage \
	--config "$WORK/grub_early.cfg" \
	--directory "$GRUB_LIB/$EFI_FORMAT" \
	--prefix "/boot/grub" \
	--output "$ISODIR/efi/boot/$EFI_BIN" \
	--format "$EFI_FORMAT" \
	--compression xz \
	$GRUB_MODS \
	|| td err_grub_mkimage
# Hinweis: $GRUB_MODS ist absichtlich ungequotet (Wortliste).

cat > "$ISODIR/boot/grub/grub.cfg" <<-__EOF__
	set timeout=3

	menuentry "alpe-live (Linux $FLAVOR)" {
		linux /boot/vmlinuz-$FLAVOR $BOOT_CMDLINE
		initrd /boot/initramfs-$FLAVOR
	}
__EOF__

# EFI-System-Partition-Image (1.44 MB) mit /efi/boot/$EFI_BIN
(
	cd "$ISODIR" || exit 1
	mformat -i boot/grub/efi.img -C -f 1440 -N 0 :: || exit 1
	mcopy -i boot/grub/efi.img -s efi :: || exit 1
) || td err_efi_img

# ------------------------------------------------------------- ISO bauen --

print_heading "$(t ph_hybrid)"
print_path "$OUTPUT"
xorrisofs -quiet \
	-output "$OUTPUT" \
	-full-iso9660-filenames \
	-joliet \
	-rational-rock \
	-sysid LINUX \
	-volid "$VOLID" \
	-isohybrid-mbr "$ISODIR/boot/syslinux/isohdpfx.bin" \
	-eltorito-boot boot/syslinux/isolinux.bin \
	-eltorito-catalog boot/syslinux/boot.cat \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	-eltorito-alt-boot \
	-e boot/grub/efi.img \
	-no-emul-boot \
	-isohybrid-gpt-basdat \
	-follow-links \
	"$ISODIR" || td err_xorrisofs

sync
iso_size=$(du -h "$OUTPUT" | cut -f1)
print_info_path "$(t info_done "$iso_size")" "$OUTPUT"
sha256sum "$OUTPUT"
print_other "$(t info_result "$VOLID" "$FLAVOR" "$COMPRESSION")"
print_other "$(t info_boot "$EFI_BIN")"
print_heading "$(t info_done_close)"
LLT_EMBED_MKALPE
}

# ---- alpe-install.sh (byte-identisch eingebettet) ----
emit_install() {
    cat > "$1" <<'LLT_EMBED_INSTALL'
#!/bin/sh
# alpe-install.sh - Installiert die alpe-live ISO auf eine Festplatte/SSD.
#
# Laeuft IM gebooteten Live-System (liegt auf dem ISO unter
# /usr/local/bin/alpe-install). Installiert offline mit setup-disk im
# 'sys'-Modus (alle Pakete kommen aus dem /apks-Repository des ISO), und
# stellt danach Heimatverzeichnisse sowie alle weiteren Snapshot-Daten
# (alles ausser /etc) auf das Ziel wieder her.
#
# Zwei Ziel-Modi:
# - Ganze Platte (-d bzw. Platte im interaktiven Menue): setup-disk
#   partitioniert und formatiert die Platte komplett neu.
# - Vorhandene Partitionen (-p bzw. Partition im interaktiven Menue):
#   setup-disk installiert in das eingehangene Root-Dateisystem
#   ('BOOTLOADER=grub setup-disk -m sys /mnt'). Optionale separate /boot-
#   und EFI-Partitionen (nur bei UEFI, -e bzw. Rueckfrage) werden mit
#   eingehangen; es wird nicht partitioniert (Vorab-Partitionieren mit
#   dem alpinen setup-disk bzw. fdisk). Als Bootloader wird grub
#   erzwungen (BOOTLOADER env, setup-disk hat dafuer keine Option):
#   grub-efi landet auf der ESP; im BIOS-Modus schreibt dieses Skript
#   danach den MBR der Trägerplatte nach, weil setup-disk im
#   Mounted-Root-Modus keinen MBR schreibt.
#
# Die Konfiguration (/etc: SSH-Port, Dienste, Netzwerk, Benutzer, Passwoerter)
# uebernimmt setup-disk selbst aus dem Live-System. Kernel werden von
# setup-disk installiert. LVM/RAID/LUKS werden nicht automatisch
# eingerichtet - fuer solche Setups setup-disk von Hand verwenden.
#
# Verwendung: alpe-install.sh [-d GERAET | -p PARTITION [-b PARTITION] [-e PARTITION]] [-y] [-h]
#   -d, --disk GERAET       Zielplatte fuer Komplett-Installation
#                           (/dev/vda, /dev/sda, ...; kurzer Name genuegt)
#   -p, --partition PART    Root-Partition fuer Partitions-Installation
#                           (Partition muss formatiert sein; ohne -y wird
#                           vor Installation ueberschreibende Abfragen
#                           gestellt)
#   -b, --boot PART         separate /boot-Partition (nur mit -p)
#   -e, --efi PART          EFI-Systempartition (nur mit -p und UEFI;
#                           wird sonst automatisch ermittelt bzw. erfragt)
#   -s, --swap GROESSE      nur mit -d: Swap-Groesse in MB (0 = kein Swap,
#                           "auto" = setup-disk rechnet)
#   -y, --yes               ohne Sicherheitsabfrage
#   -h, --help              Hilfe
#   -de, -en                Sprache fest erzwingen (Deutsch/Englisch)
#
# Swap: interaktiv wird "Swap anlegen? [J/n]" gestellt (Enter = J). Im
# Partitionsmodus wird bevorzugt eine vorhandene Swap-Partition angeboten,
# sonst kann eine Swap-Datei auf der Root-Partition angelegt werden
# ("Swap-Datei ... anlegen? [j/N]", Enter = N = kein Swap). Die
# Sicherheitsabfrage vor der Installation ("Weiter? [J/n]") nimmt j/n-
# Antworten, Enter = J.
#
# Zweisprachig (DE/EN): Alle Meldungen erscheinen in der Systemsprache.
# Fest erzwingen laesst sich die Sprache ueber die Variable SPRACHE am
# Dateianfang (Werte: AUTO = Systemsprache, DE oder EN) oder per
# Kommandozeilen-Flag -de bzw. -en.

set -eu

# Anzeigename = tatsaechlicher Dateiname (umbenennbar)
PROG="$(basename -- "$0")"
VERSION=1.8.0
MNT=/mnt
TARGET=
ROOT_PART=
BOOT_PART=
EFI_PART=
SWAP_PART=
SWAPFILE_MB=0
SWAP=
ASSUME_YES=no
FIRMWARE=bios
FORMAT_ROOT=no
FORMAT_BOOT=no
FORMAT_EFI=no
IS_TTY=no
[ -t 0 ] && IS_TTY=yes

# Farben gem. DESIGN.md (hell cyan/gelb/lila/rot/gruen, Fett = "1;3X").
# POSIX/ash-Umsetzung: [ -t 1 ] statt [[ -t 1 ]], printf '%b' statt echo -e.
# Die Zuweisung erfolgt in init_colors() und erst NACH dem -de/-en/-nc-
# Vorscan (unten), damit -nc die Farben wirklich abschalten kann.
init_colors() {
	if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
		# Echte ESC-Bytes: printf '%b' UND cat-Heredocs (usage) funktionieren.
		COLOR_ESC=$(printf '\033')
		COLOR_RESET="${COLOR_ESC}[0m"
		COLOR_HEADING="${COLOR_ESC}[1;96m"   # Hell-Cyan: Ueberschriften
		COLOR_TEXT="${COLOR_ESC}[1;93m"      # Hell-Gelb: normaler Text
		COLOR_FILE="${COLOR_ESC}[1;35m"      # Hell-Lila: Dateien/Pfade/Befehle
		COLOR_TXT="${COLOR_ESC}[1;91m"       # Hell-Rot: Warnungen/Fehler (.txt)
		COLOR_OTHER="${COLOR_ESC}[1;92m"     # Hell-Gruen: alles andere
	else
		COLOR_ESC=''
		COLOR_RESET=''
		COLOR_HEADING=''
		COLOR_TEXT=''
		COLOR_FILE=''
		COLOR_TXT=''
		COLOR_OTHER=''
	fi
}
# Leere Vorgabe (set -u): falls ein Helfer VOR init_colors laeuft.
COLOR_ESC=''; COLOR_RESET=''; COLOR_HEADING=''; COLOR_TEXT=''
COLOR_FILE=''; COLOR_TXT=''; COLOR_OTHER=''

print_heading() { printf '%b\n' "${COLOR_HEADING}$*${COLOR_RESET}"; }
print_text()    { printf '%b\n' "${COLOR_TEXT}$*${COLOR_RESET}"; }
print_file()    { printf '%b\n' "${COLOR_FILE}$*${COLOR_RESET}"; }
print_txt()     { printf '%b\n' "${COLOR_TXT}$*${COLOR_RESET}"; }
print_other()   { printf '%b\n' "${COLOR_OTHER}$*${COLOR_RESET}"; }
print_path() {
	case "$1" in
	*.txt) print_txt "$1" ;;
	*)     print_file "$1" ;;
	esac
}
# Eine Zeile: gelber Text + Pfad in Design-Farbe ("Label: Pfad")
print_info_path() {
	printf '%b' "${COLOR_TEXT}$1 ${COLOR_RESET}"
	print_path "$2"
}
# Prompt ohne Zeilenumbruch (interaktive Eingaben)
print_text_n() { printf '%b' "${COLOR_TEXT}$*${COLOR_RESET}"; }

die() { printf '%b\n' "${COLOR_TXT}FEHLER: $*${COLOR_RESET}" >&2; exit 1; }

# ==================== SPRACHE / LANGUAGE ====================
# Sprache aller Meldungen: AUTO (Systemsprache, Voreinstellung), DE oder EN.
# Zum Festlegen den Wert unten eintragen, z. B.:  SPRACHE=DE   bzw.   SPRACHE=EN
# Startet man das Skript aus der LinuxLiveTool-GUI, gewinnt die dort gewaehlte
# Sprache (Umgebungsvariable LLT_LANG = DE oder EN) ueber dieser Einstellung.
SPRACHE=DE
# Flags -de/-en: Sprache explizit setzen (gewinnt ueber AUTO, nicht
# ueber LLT_LANG der GUI); die Flags werden aus den Argumenten entfernt.
sprache_anzahl=$#
for sprache_a in "$@"; do
	case "$sprache_a" in
	-de) SPRACHE=DE ;;
	-en) SPRACHE=EN ;;
	-nc) NO_COLOR=1; export NO_COLOR ;;
	*)   set -- "$@" "$sprache_a" ;;
	esac
done
if [ "$sprache_anzahl" -gt 0 ]; then
	shift "$sprache_anzahl"
fi
case "${LLT_LANG:-}" in
DE|EN) SPRACHE="$LLT_LANG" ;;
esac
case "$SPRACHE" in
AUTO) case "${LC_ALL:-${LANG:-}}" in de*|DE*) SPRACHE=DE ;; *) SPRACHE=EN ;; esac ;;
esac

# Farben erst JETZT initialisieren: der Vorscan oben hat -nc (NO_COLOR)
# und -de/-en bereits verarbeitet (DESIGN.md).
init_colors

# Textkatalog: alle Meldungen in DE und EN (keine Extradatei).
#   t  KEY [ARGS...]  -> Meldung nach stdout
#   te KEY [ARGS...]  -> Meldung nach stderr (Praefix im Text)
#   td KEY [ARGS...]  -> Meldung nach stderr + Abbruch (exit 1)
# ARGS fuellen die %s-Platzhalter im Text.
t() {
	local key=$1; shift
	case "$key:$SPRACHE" in
	err_not_root:EN) printf '%s\n' "ERROR: Run as root (in the booted live system)." ;;
	err_not_root:*)  printf '%s\n' "FEHLER: Als root ausfuehren (im gebooteten Live-System)." ;;
	err_no_setup_disk:EN) printf '%s\n' "ERROR: setup-disk not found - please run inside the alpe-live system." ;;
	err_no_setup_disk:*)  printf '%s\n' "FEHLER: setup-disk nicht gefunden - bitte im alpe-live System ausfuehren." ;;
	err_no_apkovl:EN) printf '%s\n' "ERROR: No *.apkovl.tar.gz found under /media/* - please boot from the alpe-live ISO." ;;
	err_no_apkovl:*)  printf '%s\n' "FEHLER: Kein *.apkovl.tar.gz unter /media/* gefunden - bitte von der alpe-live ISO booten." ;;
	info_snapshot:EN) printf '%s\n' "Snapshot:" ;;
	info_snapshot:*)  printf '%s\n' "Snapshot:" ;;
	info_recreate_dev:EN) printf 'Device node %s is missing - recreating it ...\n'  "$1" ;;
	info_recreate_dev:*) printf 'Geraeteknoten %s fehlt - lege ihn neu an ...\n'  "$1" ;;
	err_dev_missing:EN) printf "ERROR: %s: %s does not exist (not in sysfs either) - device plugged in/partition table current? If needed, run 'mdev -s'.\n"  "$1" "$2" ;;
	err_dev_missing:*) printf "FEHLER: %s: %s existiert nicht (auch nicht im sysfs) - Geraet angesteckt/Partitionstabelle aktuell? Ggf. 'mdev -s' ausfuehren.\n"  "$1" "$2" ;;
	err_not_blockdev:EN) printf 'ERROR: %s: %s is not a block device file.\n'  "$1" "$2" ;;
	err_not_blockdev:*) printf 'FEHLER: %s: %s ist keine Blockgeraetedatei.\n'  "$1" "$2" ;;
	err_not_partition:EN) printf 'ERROR: %s: %s is not a partition (use -d for a whole disk).\n'  "$1" "$2" ;;
	err_not_partition:*) printf 'FEHLER: %s: %s ist keine Partition (ganze Platte mit -d angeben).\n'  "$1" "$2" ;;
	err_is_boot_medium:EN) printf 'ERROR: %s: %s is the boot medium - choose another target.\n'  "$1" "$2" ;;
	err_is_boot_medium:*) printf 'FEHLER: %s: %s ist das Boot-Medium - anderes Ziel waehlen.\n'  "$1" "$2" ;;
	err_boot_medium:EN) printf 'ERROR: %s is the boot medium - choose another target.\n'  "$1" ;;
	err_boot_medium:*) printf 'FEHLER: %s ist das Boot-Medium - anderes Ziel waehlen.\n'  "$1" ;;
	info_answer_yn:EN) printf '%s\n' "Please answer with y or n." ;;
	info_answer_yn:*)  printf '%s\n' "Bitte mit j oder n antworten." ;;
	info_unknown:EN) printf '%s\n' "unknown" ;;
	info_unknown:*)  printf '%s\n' "unbekannt" ;;
	ph_disk_menu:EN) printf '%s\n' "Available disks and partitions:" ;;
	ph_disk_menu:*)  printf '%s\n' "Verfuegbare Platten und Partitionen:" ;;
	info_boot_medium_skipped:EN) printf '(boot medium skipped: /dev/%s)\n'  "$1" ;;
	info_boot_medium_skipped:*) printf '(Boot-Medium uebersprungen: /dev/%s)\n'  "$1" ;;
	info_esp_candidate:EN) printf '%s\n' "vfat (ESP candidate)" ;;
	info_esp_candidate:*)  printf '%s\n' "vfat (ESP-Kandidat)" ;;
	info_no_fs:EN) printf '%s\n' "no filesystem" ;;
	info_no_fs:*)  printf '%s\n' "kein Dateisystem" ;;
	menu_disk:EN) printf 'Disk (%s)\n'  "$1" ;;
	menu_disk:*) printf 'Platte (%s)\n'  "$1" ;;
	err_excl_dp:EN) printf '%s\n' "ERROR: -d (whole disk) and -p (partition) are mutually exclusive." ;;
	err_excl_dp:*)  printf '%s\n' "FEHLER: -d (ganze Platte) und -p (Partition) sind gegenseitig ausschliessend." ;;
	err_be_needs_p:EN) printf '%s\n' "ERROR: -b/-e are only allowed together with -p (partition installation)." ;;
	err_be_needs_p:*)  printf '%s\n' "FEHLER: -b/-e sind nur zusammen mit -p (Partitions-Installation) erlaubt." ;;
	err_s_needs_d:EN) printf '%s\n' "ERROR: -s is only allowed together with -d (full installation)." ;;
	err_s_needs_d:*)  printf '%s\n' "FEHLER: -s ist nur zusammen mit -d (Komplett-Installation) erlaubt." ;;
	q_target_pick:EN) printf '%s\n' 'Target (number or device; disk = whole disk, partition = only the partition), empty to abort: ' ;;
	q_target_pick:*)  printf '%s\n' 'Ziel (Nummer oder Geraet; Platte = ganze Platte, Partition = nur Partition), leer zum Abbrechen: ' ;;
	err_aborted:EN) printf '%s\n' "ERROR: Aborted." ;;
	err_aborted:*)  printf '%s\n' "FEHLER: Abgebrochen." ;;
	err_bad_choice:EN) printf 'ERROR: Invalid choice: %s\n'  "$1" ;;
	err_bad_choice:*) printf 'FEHLER: Ungueltige Auswahl: %s\n'  "$1" ;;
	err_bad_swap:EN) printf "ERROR: Invalid swap size: %s (MB number, 0 or \"auto\")\n"  "$1" ;;
	err_bad_swap:*) printf "FEHLER: Ungueltige Swap-Groesse: %s (MB-Zahl, 0 oder \"auto\")\n"  "$1" ;;
	err_bad_swap2:EN) printf 'ERROR: Invalid swap size: %s (MB number)\n'  "$1" ;;
	err_bad_swap2:*) printf 'FEHLER: Ungueltige Swap-Groesse: %s (MB-Zahl)\n'  "$1" ;;
	err_swap_zero:EN) printf '%s\n' "ERROR: Swap size 0 - please answer n to the previous question instead." ;;
	err_swap_zero:*)  printf '%s\n' "FEHLER: Swap-Groesse 0 - bitte bei der vorherigen Frage mit n antworten." ;;
	err_boot_is_root:EN) printf '%s\n' "ERROR: The /boot partition must not be the root partition." ;;
	err_boot_is_root:*)  printf '%s\n' "FEHLER: /boot-Partition darf nicht die Root-Partition sein." ;;
	err_efi_is_root:EN) printf '%s\n' "ERROR: The EFI partition must not be the root partition." ;;
	err_efi_is_root:*)  printf '%s\n' "FEHLER: EFI-Partition darf nicht die Root-Partition sein." ;;
	err_boot_ne_efi:EN) printf '%s\n' "ERROR: The /boot and EFI partitions must be different." ;;
	err_boot_ne_efi:*)  printf '%s\n' "FEHLER: /boot- und EFI-Partition muessen verschieden sein." ;;
	err_boot_is_efi:EN) printf '%s\n' "ERROR: The /boot partition must not be the EFI partition." ;;
	err_boot_is_efi:*)  printf '%s\n' "FEHLER: /boot-Partition darf nicht die EFI-Partition sein." ;;
	info_uefi:EN) printf '%s\n' "Firmware: UEFI detected." ;;
	info_uefi:*)  printf '%s\n' "Firmware: UEFI erkannt." ;;
	info_bios:EN) printf '%s\n' "Firmware: BIOS (no UEFI detected) - no ESP needed." ;;
	info_bios:*)  printf '%s\n' "Firmware: BIOS (kein UEFI erkannt) - keine ESP noetig." ;;
	err_efi_no_uefi:EN) printf '%s\n' "ERROR: -e (EFI partition) given, but the system is not booted in UEFI mode." ;;
	err_efi_no_uefi:*)  printf '%s\n' "FEHLER: -e (EFI-Partition) angegeben, aber das System ist nicht im UEFI-Modus gebootet." ;;
	ph_esp_list:EN) printf '%s\n' "Possible EFI system partitions (ESP):" ;;
	ph_esp_list:*)  printf '%s\n' "Moegliche EFI-Systempartitionen (ESP):" ;;
	info_no_fat:EN) printf '%s\n' "No FAT candidate detected - offering all partitions:" ;;
	info_no_fat:*)  printf '%s\n' "Kein FAT-Kandidat erkannt - biete alle Partitionen an:" ;;
	err_no_esp:EN) printf '%s\n' "ERROR: No partition found as ESP candidate - specify the ESP with -e PARTITION (device nodes/partition table current? 'mdev -s' or 'partprobe /dev/DISK' help)." ;;
	err_no_esp:*)  printf '%s\n' "FEHLER: Keine Partition als ESP-Kandidat gefunden - ESP mit -e PARTITION angeben (Geraeteknoten/Partitionstabelle aktuell? 'mdev -s' bzw. 'partprobe /dev/PLATTE' helfen)." ;;
	q_esp_pick:EN) printf '%s\n' 'EFI system partition (number or device), empty to abort: ' ;;
	q_esp_pick:*)  printf '%s\n' 'EFI-Systempartition (Nummer oder Geraet), leer zum Abbrechen: ' ;;
	info_esp_auto:EN) printf 'EFI system partition chosen automatically: %s (only ESP candidate).\n'  "$1" ;;
	info_esp_auto:*) printf 'EFI-Systempartition automatisch gewaehlt: %s (einziger ESP-Kandidat).\n'  "$1" ;;
	err_esp_ambiguous:EN) printf '%s\n' "ERROR: ESP not clearly recognizable as FAT - please specify -e PARTITION." ;;
	err_esp_ambiguous:*)  printf '%s\n' "FEHLER: ESP nicht eindeutig als FAT erkennbar - bitte -e PARTITION angeben." ;;
	ph_boot_list:EN) printf '%s\n' "Candidates for a separate /boot partition:" ;;
	ph_boot_list:*)  printf '%s\n' "Kandidaten fuer eine separate /boot-Partition:" ;;
	q_boot_pick:EN) printf '%s\n' 'Separate /boot partition (number or device, empty = /boot on root): ' ;;
	q_boot_pick:*)  printf '%s\n' 'Separate /boot-Partition (Nummer oder Geraet, leer = /boot liegt auf Root): ' ;;
	info_fmt_root_auto:EN) printf '%s has no filesystem - will be formatted as ext4.\n'  "$1" ;;
	info_fmt_root_auto:*) printf '%s hat kein Dateisystem - wird als ext4 formatiert.\n'  "$1" ;;
	q_fmt_root:EN) printf 'Format the root partition? [Y/n] (currently: %s): \n'  "$1" ;;
	q_fmt_root:*) printf 'Root-Partition formatieren? [J/n] (aktuell: %s): \n'  "$1" ;;
	info_fmt_root_no:EN) printf 'Root partition will NOT be formatted (installing over %s).\n'  "$1" ;;
	info_fmt_root_no:*) printf 'Root-Partition wird NICHT formatiert (installiert ueber %s).\n'  "$1" ;;
	info_fmt_root_nontty:EN) printf 'Root partition installed without formatting over %s.\n'  "$1" ;;
	info_fmt_root_nontty:*) printf 'Root-Partition wird ohne Formatierung ueber %s installiert.\n'  "$1" ;;
	info_fmt_boot_auto:EN) printf '%s has no filesystem - will be formatted as ext4.\n'  "$1" ;;
	info_fmt_boot_auto:*) printf '%s hat kein Dateisystem - wird als ext4 formatiert.\n'  "$1" ;;
	q_fmt_boot:EN) printf 'Format the /boot partition? [Y/n] (currently: %s): \n'  "$1" ;;
	q_fmt_boot:*) printf '/boot-Partition formatieren? [J/n] (aktuell: %s): \n'  "$1" ;;
	info_fmt_boot_no:EN) printf '/boot partition will NOT be formatted (stays %s).\n'  "$1" ;;
	info_fmt_boot_no:*) printf '/boot-Partition wird NICHT formatiert (bleibt %s).\n'  "$1" ;;
	q_fmt_esp:EN) printf '%s\n' 'Format the EFI partition? [y/N] (careful: may contain other bootloaders): ' ;;
	q_fmt_esp:*)  printf '%s\n' 'EFI-Partition formatieren? [j/N] (Achtung: kann andere Bootloader enthalten): ' ;;
	q_fmt_esp_fat:EN) printf 'EFI partition has no FAT filesystem (currently: %s) - format as FAT32? [Y/n]: \n'  "$1" ;;
	q_fmt_esp_fat:*) printf 'EFI-Partition hat kein FAT-Dateisystem (aktuell: %s) - als FAT32 formatieren? [J/n]: \n'  "$1" ;;
	err_esp_not_fat:EN) printf '%s\n' "ERROR: EFI partition must be FAT - aborted." ;;
	err_esp_not_fat:*)  printf '%s\n' "FEHLER: EFI-Partition muss FAT sein - Abgebrochen." ;;
	err_esp_not_fat_nontty:EN) printf 'ERROR: EFI partition %s is not FAT (currently: %s) - please format as FAT32 or correct -e.\n'  "$1" "$2" ;;
	err_esp_not_fat_nontty:*) printf 'FEHLER: EFI-Partition %s ist kein FAT (aktuell: %s) - bitte als FAT32 formatieren oder -e korrigieren.\n'  "$1" "$2" ;;
	ph_swap_list:EN) printf '%s\n' "Available swap partitions:" ;;
	ph_swap_list:*)  printf '%s\n' "Verfuegbare Swap-Partitionen:" ;;
	q_swap_existing:EN) printf '%s\n' 'Use an existing swap partition? [Y/n]: ' ;;
	q_swap_existing:*)  printf '%s\n' 'Vorhandene Swap-Partition verwenden? [J/n]: ' ;;
	q_swap_pick:EN) printf '%s\n' 'Swap partition (number or device), empty to abort: ' ;;
	q_swap_pick:*)  printf '%s\n' 'Swap-Partition (Nummer oder Geraet), leer zum Abbrechen: ' ;;
	info_swap_part:EN) printf '%s\n' "Swap partition:" ;;
	info_swap_part:*)  printf '%s\n' "Swap-Partition:" ;;
	info_swap_auto:EN) printf 'Existing swap partition chosen automatically: %s.\n'  "$1" ;;
	info_swap_auto:*) printf 'Vorhandene Swap-Partition automatisch gewaehlt: %s.\n'  "$1" ;;
	q_swap_create:EN) printf '%s\n' 'Create swap? [Y/n]: ' ;;
	q_swap_create:*)  printf '%s\n' 'Swap anlegen? [J/n]: ' ;;
	q_swap_size:EN) printf '%s\n' 'Swap size in MB ("auto" = automatic, empty = auto): ' ;;
	q_swap_size:*)  printf '%s\n' 'Swap-Groesse in MB ("auto" = automatisch, leer = auto): ' ;;
	q_swapfile:EN) printf '%s\n' 'Create a swap file on the root partition? [y/N]: ' ;;
	q_swapfile:*)  printf '%s\n' 'Swap-Datei auf der Root-Partition anlegen? [j/N]: ' ;;
	q_swapfile_size:EN) printf '%s\n' 'Swap size in MB (empty = 512): ' ;;
	q_swapfile_size:*)  printf '%s\n' 'Swap-Groesse in MB (leer = 512): ' ;;
	warn_targets:EN) printf '%s\n' "WARNING: The live system will be installed to the following targets (data will be lost!):" ;;
	warn_targets:*)  printf '%s\n' "ACHTUNG: Auf die folgenden Ziele wird das Live-System installiert (Daten gehen verloren!):" ;;
	info_target_disk:EN) printf '%s\n' "  Whole disk (will be repartitioned):" ;;
	info_target_disk:*)  printf '%s\n' "  Ganze Platte (wird neu partitioniert):" ;;
	info_target_root:EN) printf '%s\n' "  Root partition:" ;;
	info_target_root:*)  printf '%s\n' "  Root-Partition:" ;;
	info_target_boot:EN) printf '%s\n' "  /boot partition:" ;;
	info_target_boot:*)  printf '%s\n' "  /boot-Partition:" ;;
	info_target_efi:EN) printf '%s\n' "  EFI partition:" ;;
	info_target_efi:*)  printf '%s\n' "  EFI-Partition:" ;;
	info_target_swap:EN) printf '%s\n' "  Swap partition:" ;;
	info_target_swap:*)  printf '%s\n' "  Swap-Partition:" ;;
	info_target_swapfile:EN) printf '  Swap file: %s MB on %s\n'  "$1" "$2" ;;
	info_target_swapfile:*) printf '  Swap-Datei: %s MB auf %s\n'  "$1" "$2" ;;
	ph_disk_list:EN) printf '%s\n' "Available disks:" ;;
	ph_disk_list:*)  printf '%s\n' "Verfuegbare Platten:" ;;
	q_continue:EN) printf '%s\n' 'Continue? [Y/n]: ' ;;
	q_continue:*)  printf '%s\n' 'Weiter? [J/n]: ' ;;
	ph_install_disk:EN) printf 'Installing Alpine on %s (sys mode, offline from /apks)\n'  "$1" ;;
	ph_install_disk:*) printf 'Installiere Alpine auf %s (sys-Modus, offline aus /apks)\n'  "$1" ;;
	ph_install_part:EN) printf 'Installing Alpine on %s (sys mode, offline from /apks)\n'  "$1" ;;
	ph_install_part:*) printf 'Installiere Alpine auf %s (sys-Modus, offline aus /apks)\n'  "$1" ;;
	info_swap_auto_mode:EN) printf '%s\n' "Swap: automatic (setup-disk calculates)" ;;
	info_swap_auto_mode:*)  printf '%s\n' "Swap: automatisch (setup-disk berechnet)" ;;
	info_swap_none:EN) printf '%s\n' "Swap: none" ;;
	info_swap_none:*)  printf '%s\n' "Swap: keiner" ;;
	info_swap_mb:EN) printf 'Swap: %s MB\n'  "$1" ;;
	info_swap_mb:*) printf 'Swap: %s MB\n'  "$1" ;;
	err_setup_disk:EN) printf '%s\n' "ERROR: setup-disk failed." ;;
	err_setup_disk:*)  printf '%s\n' "FEHLER: setup-disk fehlgeschlagen." ;;
	info_fw_bootloader:EN) printf 'Firmware: %s - bootloader: grub\n'  "$1" ;;
	info_fw_bootloader:*) printf 'Firmware: %s - Bootloader: grub\n'  "$1" ;;
	err_no_mkfs_ext4:EN) printf '%s\n' "ERROR: mkfs.ext4 not found - e2fsprogs missing in the live system." ;;
	err_no_mkfs_ext4:*)  printf '%s\n' "FEHLER: mkfs.ext4 nicht gefunden - e2fsprogs fehlen im Live-System." ;;
	info_formatting_root:EN) printf 'Formatting root partition as ext4: %s\n'  "$1" ;;
	info_formatting_root:*) printf 'Formatiere Root-Partition als ext4: %s\n'  "$1" ;;
	err_format_failed:EN) printf 'ERROR: Formatting %s failed.\n'  "$1" ;;
	err_format_failed:*) printf 'FEHLER: Formatieren von %s fehlgeschlagen.\n'  "$1" ;;
	info_formatting_boot:EN) printf 'Formatting /boot partition as ext4: %s\n'  "$1" ;;
	info_formatting_boot:*) printf 'Formatiere /boot-Partition als ext4: %s\n'  "$1" ;;
	err_no_mkfs_vfat:EN) printf '%s\n' "ERROR: mkfs.vfat not found - dosfstools missing in the live system." ;;
	err_no_mkfs_vfat:*)  printf '%s\n' "FEHLER: mkfs.vfat nicht gefunden - dosfstools fehlen im Live-System." ;;
	info_formatting_efi:EN) printf 'Formatting EFI partition as FAT32: %s\n'  "$1" ;;
	info_formatting_efi:*) printf 'Formatiere EFI-Partition als FAT32: %s\n'  "$1" ;;
	err_mount_root:EN) printf 'ERROR: Could not mount root partition %s.\n'  "$1" ;;
	err_mount_root:*) printf 'FEHLER: Konnte Root-Partition %s nicht mounten.\n'  "$1" ;;
	err_mount_boot:EN) printf 'ERROR: Could not mount /boot partition %s.\n'  "$1" ;;
	err_mount_boot:*) printf 'FEHLER: Konnte /boot-Partition %s nicht mounten.\n'  "$1" ;;
	err_mount_efi:EN) printf 'ERROR: Could not mount EFI partition %s.\n'  "$1" ;;
	err_mount_efi:*) printf 'FEHLER: Konnte EFI-Partition %s nicht mounten.\n'  "$1" ;;
	err_parent_disk:EN) printf 'ERROR: Could not determine the parent disk of %s.\n'  "$1" ;;
	err_parent_disk:*) printf 'FEHLER: Konnte uebergeordnete Platte von %s nicht bestimmen.\n'  "$1" ;;
	info_bootloader_disk:EN) printf '%s\n' "Bootloader target disk:" ;;
	info_bootloader_disk:*)  printf '%s\n' "Bootloader-Zielplatte:" ;;
	err_no_grub_install:EN) printf '%s\n' "ERROR: grub-install not found - grub-bios missing in the live system." ;;
	err_no_grub_install:*)  printf '%s\n' "FEHLER: grub-install nicht gefunden - grub-bios fehlt im Live-System." ;;
	err_no_devnode:EN) printf 'ERROR: Device node /dev/%s is missing - cannot write the MBR.\n'  "$1" ;;
	err_no_devnode:*) printf 'FEHLER: Geraeteknoten /dev/%s fehlt - MBR kann nicht geschrieben werden.\n'  "$1" ;;
	info_writing_mbr:EN) printf 'Writing MBR (grub i386-pc) to /dev/%s ...\n'  "$1" ;;
	info_writing_mbr:*) printf 'Schreibe MBR (grub i386-pc) auf /dev/%s ...\n'  "$1" ;;
	err_grub_install_failed:EN) printf 'ERROR: grub-install to /dev/%s failed (on GPT a BIOS boot partition may be missing).\n'  "$1" ;;
	err_grub_install_failed:*) printf 'FEHLER: grub-install auf /dev/%s fehlgeschlagen (bei GPT fehlt evtl. eine BIOS-Boot-Partition).\n'  "$1" ;;
	info_restore:EN) printf '%s\n' "Restoring home directories and other snapshot data ..." ;;
	info_restore:*)  printf '%s\n' "Stelle Heimatverzeichnisse und weitere Snapshot-Daten wieder her ..." ;;
	err_find_root:EN) printf 'ERROR: Could not find/mount the root partition of %s.\n'  "$1" ;;
	err_find_root:*) printf 'FEHLER: Konnte die Root-Partition von %s nicht finden/mounten.\n'  "$1" ;;
	info_root_part:EN) printf '%s\n' "Root partition:" ;;
	info_root_part:*)  printf '%s\n' "Root-Partition:" ;;
	err_restore_failed:EN) printf '%s\n' "ERROR: Restoring the snapshot data failed." ;;
	err_restore_failed:*)  printf '%s\n' "FEHLER: Wiederherstellen der Snapshot-Daten fehlgeschlagen." ;;
	info_homes_list:EN) printf 'Home directories: %s\n'  "$1" ;;
	info_homes_list:*) printf 'Heimatverzeichnisse: %s\n'  "$1" ;;
	info_net_repos:EN) printf '%s\n' "Network repositories restored from the snapshot." ;;
	info_net_repos:*)  printf '%s\n' "Netzwerk-Repositories aus dem Snapshot wiederhergestellt." ;;
	info_swap_fstab:EN) printf 'Swap partition written to fstab: %s\n'  "$1" ;;
	info_swap_fstab:*) printf 'Swap-Partition in die fstab eingetragen: %s\n'  "$1" ;;
	info_creating_swapfile:EN) printf 'Creating swap file (%s MB) ...\n'  "$1" ;;
	info_creating_swapfile:*) printf 'Lege Swap-Datei an (%s MB) ...\n'  "$1" ;;
	err_swapfile_failed:EN) printf '%s\n' "ERROR: Creating the swap file failed." ;;
	err_swapfile_failed:*)  printf '%s\n' "FEHLER: Anlegen der Swap-Datei fehlgeschlagen." ;;
	info_swapfile_done:EN) printf '%s\n' "Swap file created and written to fstab: /swapfile" ;;
	info_swapfile_done:*)  printf '%s\n' "Swap-Datei angelegt und in die fstab eingetragen: /swapfile" ;;
	info_done_disk:EN) printf 'Done - system installed on %s.\n'  "$1" ;;
	info_done_disk:*) printf 'Fertig - System auf %s installiert.\n'  "$1" ;;
	info_done_part:EN) printf 'Done - system installed on %s.\n'  "$1" ;;
	info_done_part:*) printf 'Fertig - System auf %s installiert.\n'  "$1" ;;
	info_reboot:EN) printf '%s\n' "Rebooting without the ISO starts the installed system" ;;
	info_reboot:*)  printf '%s\n' "Reboot ohne die ISO startet das installierte System" ;;
	info_login:EN) printf '%s\n' "  (Login: user/password as in the live system)." ;;
	info_login:*)  printf '%s\n' "  (Login: Benutzer/Passwort wie im Live-System)." ;;
	zweck_target_disk:EN) printf '%s\n' "Target disk" ;;
	zweck_target_disk:*)  printf '%s\n' "Zielplatte" ;;
	zweck_root:EN) printf '%s\n' "Root partition" ;;
	zweck_root:*)  printf '%s\n' "Root-Partition" ;;
	zweck_boot:EN) printf '%s\n' "/boot partition" ;;
	zweck_boot:*)  printf '%s\n' "/boot-Partition" ;;
	zweck_efi:EN) printf '%s\n' "EFI partition" ;;
	zweck_efi:*)  printf '%s\n' "EFI-Partition" ;;
	*) printf '%s\n' "$key" ;;
	esac
}
te() { printf '%b\n' "${COLOR_TXT}$(t "$@")${COLOR_RESET}" >&2; }
td() { printf '%b\n' "${COLOR_TXT}$(t "$@")${COLOR_RESET}" >&2; exit 1; }

usage() {
	case "$SPRACHE" in
	EN)
		cat >&2 <<-__EOF__
			${COLOR_HEADING}$PROG - install the alpe-live ISO to a disk or existing partitions${COLOR_RESET}

			${COLOR_HEADING}Usage:${COLOR_RESET} ${COLOR_TXT}$PROG [-d DEVICE | -p PARTITION [-b PARTITION] [-e PARTITION]] [-s SIZE] [-y]${COLOR_RESET}

			${COLOR_HEADING}Options:${COLOR_RESET}
			  ${COLOR_FILE}-d, --disk DEVICE${COLOR_OTHER}     install to a whole disk (/dev/vda, ...)
			  ${COLOR_FILE}-p, --partition PART${COLOR_OTHER}  install into an existing root partition
			                        (create partitions beforehand; the alpine
			                        setup-disk is recommended for partitioning)
			  ${COLOR_FILE}-b, --boot PART${COLOR_OTHER}       separate /boot partition (only with -p)
			  ${COLOR_FILE}-e, --efi PART${COLOR_OTHER}        EFI system partition (only with -p and UEFI)
			  ${COLOR_FILE}-s, --swap SIZE${COLOR_OTHER}       only with -d: swap in MB (0 = no swap,
			                        "auto" = setup-disk calculates automatically)
			  ${COLOR_FILE}-y, --yes${COLOR_OTHER}             without confirmation prompt
			  ${COLOR_FILE}-h, --help${COLOR_OTHER}            help
			  ${COLOR_FILE}-de | -en${COLOR_OTHER}             force the language (German/English)
			  ${COLOR_FILE}-nc${COLOR_OTHER}                   turn colors off

			${COLOR_TEXT}Runs in the booted live system. Installs offline via setup-disk
			and restores home directories from the snapshot.
			Interactively the target (disk or partition) is chosen via a menu;
			with UEFI the EFI system partition is asked for as well.
			Swap is offered via "Create swap? [Y/n]" (Enter = Y).${COLOR_RESET}
		__EOF__
		;;
	*)
		cat >&2 <<-__EOF__
			${COLOR_HEADING}$PROG - alpe-live ISO auf eine Platte oder vorhandene Partitionen installieren${COLOR_RESET}

			${COLOR_HEADING}Verwendung:${COLOR_RESET} ${COLOR_TXT}$PROG [-d GERAET | -p PARTITION [-b PARTITION] [-e PARTITION]] [-s GROESSE] [-y]${COLOR_RESET}

			${COLOR_HEADING}Optionen:${COLOR_RESET}
			  ${COLOR_FILE}-d, --disk GERAET${COLOR_OTHER}     ganze Platte installieren (/dev/vda, ...)
			  ${COLOR_FILE}-p, --partition PART${COLOR_OTHER}  in vorhandene Root-Partition installieren
			                        (Partitionen vorher anlegen; zum
			                        Partitionieren ist das alpine-eigene
			                        setup-disk zu empfehlen)
			  ${COLOR_FILE}-b, --boot PART${COLOR_OTHER}       separate /boot-Partition (nur mit -p)
			  ${COLOR_FILE}-e, --efi PART${COLOR_OTHER}        EFI-Systempartition (nur mit -p und UEFI)
			  ${COLOR_FILE}-s, --swap GROESSE${COLOR_OTHER}    nur mit -d: Swap in MB (0 = kein Swap,
			                        "auto" = setup-disk rechnet automatisch)
			  ${COLOR_FILE}-y, --yes${COLOR_OTHER}             ohne Sicherheitsabfrage
			  ${COLOR_FILE}-h, --help${COLOR_OTHER}            Hilfe
			  ${COLOR_FILE}-de | -en${COLOR_OTHER}             Sprache fest erzwingen (Deutsch/Englisch)
			  ${COLOR_FILE}-nc${COLOR_OTHER}                   Farben abschalten

			${COLOR_TEXT}Laeuft im gebooteten Live-System. Installiert offline via setup-disk
			und stellt Heimatverzeichnisse aus dem Snapshot wieder her.
			Interaktiv wird das Ziel (Platte oder Partition) per Menue gewaehlt;
			bei UEFI wird zusaetzlich nach der EFI-Systempartition gefragt.
			Swap wird per "Swap anlegen? [J/n]" angeboten (Enter = J).${COLOR_RESET}
		__EOF__
		;;
	esac
}

# ------------------------------------------------------------- Optionen --

OPTS=$(getopt -o d:p:b:e:s:yh -l disk:,partition:,boot:,efi:,swap:,yes,help -n "$PROG" -- "$@") || usage
eval set -- "$OPTS"
while :; do
	case "$1" in
	-d|--disk)      TARGET=$2; shift 2 ;;
	-p|--partition) ROOT_PART=$2; shift 2 ;;
	-b|--boot)      BOOT_PART=$2; shift 2 ;;
	-e|--efi)       EFI_PART=$2; shift 2 ;;
	-s|--swap)      SWAP=$2; shift 2 ;;
	-y|--yes)       ASSUME_YES=yes; shift ;;
	-h|--help)      usage; exit 0 ;;
	--)             shift; break ;;
	*)              usage; exit 1 ;;
	esac
done
[ $# -eq 0 ] || { usage; exit 1; }

# ------------------------------------------------------------- Voraussetzungen --

# Root-Rechte: wenn nicht root, das Skript DIREKT per sudo/su als root neu
# starten (sudo fragt selbst nach dem Passwort) - kein Abbruch, keine Nachfrage
if [ "$(id -u)" -ne 0 ]; then
	if [ "${ALPE_SUDO_ASKED:-0}" = "1" ]; then
		# Fehlkonfiguration: sudo lief keine echte Root-Shell -> Abbruch statt Endlosschleife
		td err_not_root
	fi
	if command -v sudo >/dev/null 2>&1; then
		exec sudo env ALPE_SUDO_ASKED=1 sh "$0"
	else
		# Alpine lebt oft ohne sudo - Rueckfallebene su
		exec su root -c "ALPE_SUDO_ASKED=1 sh '$0'"
	fi
fi
command -v setup-disk >/dev/null 2>&1 \
	|| td err_no_setup_disk

# ------------------------------------------------------------- Snapshot finden --

APKOVL=
for cand in /media/*/*.apkovl.tar.gz; do
	if [ -f "$cand" ]; then
		APKOVL=$cand
		break
	fi
done
[ -n "$APKOVL" ] || td err_no_apkovl
print_info_path "$(t info_snapshot)" "$APKOVL"

# ------------------------------------------------------------- Geraete-Hilfen --

# Kurzen Namen zu /dev/GERAET ergaenzen
normalize_dev() {
	case "$1" in
	/dev/*) printf '%s\n' "$1" ;;
	*)      printf '%s\n' "/dev/$1" ;;
	esac
}

# Ist das Geraet eine Partition (keine ganze Platte)?
is_partition() { [ -e "/sys/class/block/$(basename "$1")/partition" ]; }

# Uebergeordnete Platte einer Partition (Name ohne /dev/); rc 1 bei Platten.
# Exakt ueber sysfs: die aufgeloeste Partitions-Adresse muss genau unter
# der aufgeloesten Adresse eines /sys/block-Eintrags liegen (funktioniert
# auch bei nvme0n1p1/mmcblk0p1; dirname-Heuristik wuerde hier - bzw. bei
# ganzen Platten "block" bzw. den NVMe-Controller - liefern).
parent_disk() {
	pd_name=$(basename "$1")
	pd_sys=$(readlink -f "/sys/class/block/$pd_name" 2>/dev/null) || return 1
	[ -n "$pd_sys" ] || return 1
	[ -e "/sys/class/block/$pd_name/partition" ] || return 1
	for pd_d in /sys/block/*; do
		pd_cand=${pd_d##*/}
		pd_cand_sys=$(readlink -f "$pd_d") || continue
		case "$pd_sys" in
		"$pd_cand_sys/$pd_name") printf '%s\n' "$pd_cand"; return 0 ;;
		esac
	done
	return 1
}

# Fehlender /dev-Knoten wird nachgelegt, wenn sysfs das Geraet kennt
# (erst 'mdev -s', dann ggf. Partitionstabelle der Trägerplatte neu
# einlesen, dann mknod mit major:minor aus sysfs). rc 1, wenn das Geraet
# auch danach unbekannt ist - der Vorgang bricht nicht mehr einfach ab,
# sondern der Knoten wird soweit moeglich wiederhergestellt.
ensure_dev_node() {
	ed_name=${1##*/}
	ed_quiet=${2:-}
	ed_dev=/dev/$ed_name
	[ -e "$ed_dev" ] && return 0
	ed_ids=$(cat "/sys/class/block/$ed_name/dev" 2>/dev/null) || return 1
	[ "$ed_quiet" = quiet ] \
		|| print_text "$(t info_recreate_dev "$ed_dev")"
	mdev -s 2>/dev/null || :
	[ -e "$ed_dev" ] && return 0
	# Partition: Kernel die Partitionstabelle der Trägerplatte neu
	# einlesen lassen, damit fehlende Partitions-Geraeteknoten
	# auftauchen (Teil des bekannten Geräteknoten-Problems)
	ed_pd=$(parent_disk "$ed_name" 2>/dev/null || :)
	if [ -n "$ed_pd" ] && [ "$ed_pd" != "$ed_name" ] \
		&& command -v partprobe >/dev/null 2>&1; then
		partprobe "/dev/$ed_pd" 2>/dev/null || :
		mdev -s 2>/dev/null || :
		[ -e "$ed_dev" ] && return 0
	fi
	ed_major=${ed_ids%%:*}
	ed_minor=${ed_ids##*:}
	mknod "$ed_dev" b "$ed_major" "$ed_minor" 2>/dev/null || return 1
	[ -b "$ed_dev" ]
}

# Blockgeraet verlangen; gibt normiertes Geraet aus
require_block_dev() {
	r_dev=$1
	r_zweck=$2
	case "$r_dev" in
	/dev/*) ;;
	*)      r_dev=/dev/$r_dev ;;
	esac
	if [ ! -b "$r_dev" ]; then
		ensure_dev_node "$r_dev" || \
			td err_dev_missing "$r_zweck" "$r_dev"
		[ -b "$r_dev" ] || td err_not_blockdev "$r_zweck" "$r_dev"
	fi
	printf '%s\n' "$r_dev"
}

# Groesse in MB (Geraetename ohne Pfad)
dev_size_mb() {
	sz=$(cat "/sys/class/block/$1/size" 2>/dev/null || printf '0')
	printf '%s\n' $((sz / 2048))
}

# Dateisystem-Typ per blkid (leer = keins erkannt). Anker mit Leerzeichen,
# damit der gierige Match nicht PARTTYPE/PARTUUID-artige Felder erwischt.
fs_type() {
	blkid "$1" 2>/dev/null | sed -n 's/^.* TYPE="\([^"]*\)".*/\1/p'
}

# UUID per blkid (leer = keine)
dev_uuid() {
	blkid "$1" 2>/dev/null | sed -n 's/^.* UUID="\([^"]*\)".*/\1/p'
}

# ------------------------------------------------------------- Boot-Medium-Schutz --

# Namen aller Geraete des Boot-Mediums (auch uebergeordnete Platte) sammeln.
# Boot-Medien sind die Geraete, auf denen der Snapshot (APKOVL) bzw. das
# apk-Repository des Live-Systems liegt - nicht jeder Mount unter /media
# (manuell gemountete Ziel-Partitionen wuerden sonst faelschlich aus allen
# Menues verschwinden). Fallback, wenn keines ermittelbar ist: alle
# /media-Mounts sperren (altes Verhalten).
boot_names=

# Geraet, das das Verzeichnis $1 (laengster Mount-Praefix) bereitstellt
dev_of_mount_dir() {
	awk -v d="$1" \
		'$2 != "/" && index(d, $2 "/") == 1 && length($2) > m {
			m = length($2); dev = $1
		} END { print dev }' /proc/mounts
}

collect_boot_medium() {
	boot_names=" "
	# 1) Medium mit dem Snapshot (apkovl)
	bm_dev=$(dev_of_mount_dir "${APKOVL%/*}/")
	[ -n "$bm_dev" ] && bm_add_dev "$bm_dev"
	# 2) Live-Medium mit dem apk-Repository (im Normalfall dasselbe wie 1);
	#    /etc/apk/repositories enthaelt im Live-System /media/<dev>/apks
	# shellcheck disable=SC2013  # Mount-Pfade unter /media enthalten keine Leerzeichen
	for bm_dir in $(sed -n 's|^/\(media/[^/ ]*\)/.*|/\1|p' \
		/etc/apk/repositories 2>/dev/null | sort -u); do
		bm_dev=$(dev_of_mount_dir "$bm_dir/")
		[ -n "$bm_dev" ] && bm_add_dev "$bm_dev"
	done
	# 3) Fallback: nichts ermittelbar -> alle /media-Mounts sperren
	if [ "$boot_names" = " " ]; then
		# shellcheck disable=SC2013  # for-Loop statt while-read: kein Subshell-Problem hier
		for m_dev in $(awk '$2 ~ /^\/media\// {print $1}' /proc/mounts); do
			bm_add_dev "$m_dev"
		done
	fi
}

# Geraetename (+ Traegerplatte + deren Partitionen) zu boot_names hinzufuegen
bm_add_dev() {
	bm_name=${1##*/}
	case " $boot_names " in
	*" $bm_name "*) return 0 ;;
	esac
	boot_names="$boot_names$bm_name "
	bm_parent=$(parent_disk "$bm_name" 2>/dev/null || :)
	[ -n "$bm_parent" ] || return 0
	case " $boot_names " in
	*" $bm_parent "*) ;;
	*) boot_names="$boot_names$bm_parent " ;;
	esac
	# Alle Partitionen des Boot-Mediums sperren, nicht nur die gemountete
	for p in "/sys/block/$bm_parent/$bm_parent"*; do
		if [ -e "$p/partition" ]; then
			case " $boot_names " in
			*" ${p##*/} "*) ;;
			*) boot_names="$boot_names${p##*/} " ;;
			esac
		fi
	done
}

is_boot_medium_name() {
	for bmn in $boot_names; do
		[ "$1" = "$bmn" ] && return 0
	done
	return 1
}

collect_boot_medium

# ------------------------------------------------------------- Auswahl-Menue --

# Menue-Liste: ein Geraet pro Zeile; Zeilennummer = Menue-Nummer
menu_devs=
menu_count=0
menu_add() {
	menu_count=$((menu_count + 1))
	menu_devs="${menu_devs}$1
"
}

# Menue-Eintrag farbig ausgeben (Nr, Geraet, MB, Info)
menu_line() {
	printf '%b%3d) %b %8d MB  %s%b\n' \
		"$COLOR_OTHER" "$1" \
		"${COLOR_FILE}$2${COLOR_RESET}" "$3" "$4" \
		"$COLOR_RESET"
}

# Eingabe (Nummer oder Geraet) in /dev/GERAET aufloesen; exit 1 bei Fehler
menu_pick() {
	case "$1" in
	*[!0-9]*)
		normalize_dev "$1"
		;;
	*)
		[ "$1" -ge 1 ] 2>/dev/null || return 1
		p_dev=$(printf '%s\n' "$menu_devs" | sed -n "${1}p")
		[ -n "$p_dev" ] || return 1
		printf '%s\n' "$p_dev"
		;;
	esac
}

# J/n-Rueckfrage: $1 Prompt (mit [J/n]), $2 Standard j|n; rc 0 = ja
ask_yn() {
	while :; do
		print_text_n "$1"
		yn_ans=
		read -r yn_ans || yn_ans=
		case "$yn_ans" in
		"")
			[ "$2" = j ] && return 0
			return 1
			;;
		j|J|ja|Ja|JA|y|Y|yes|Yes|YES) return 0 ;;
		n|N|nein|Nein|NEIN|no|No|NO)  return 1 ;;
		*) print_text "$(t info_answer_yn)" ;;
		esac
	done
}

# Ueberblick: verfuegbare ganze Platten (ohne Nummern/Menue)
list_disks() {
	for d in /sys/block/*; do
		d_name=${d##*/}
		case "$d_name" in
		loop*|ram*|zram*|sr*|fd*|dm-*|md*|nbd*) continue ;;
		esac
		[ -e "$d/device" ] || continue
		d_size=$(cat "$d/size" 2>/dev/null || printf '0')
		d_model=$(cat "$d/device/model" 2>/dev/null || t info_unknown)
		printf '%b %8d MB  %s\n' "${COLOR_FILE}/dev/$d_name${COLOR_RESET}" $((d_size / 2048)) "$d_model"
	done
}

# Platten+Partitionen gesamt auflisten (interaktive Zielwahl)
show_target_menu() {
	menu_devs=
	menu_count=0
	print_heading "$(t ph_disk_menu)"
	for d in /sys/block/*; do
		d_name=${d##*/}
		case "$d_name" in
		loop*|ram*|zram*|sr*|fd*|dm-*|md*|nbd*) continue ;;
		esac
		[ -e "$d/device" ] || continue
		if is_boot_medium_name "$d_name"; then
			print_text "$(t info_boot_medium_skipped "$d_name")"
			continue
		fi
		d_size=$(dev_size_mb "$d_name")
		d_model=$(cat "$d/device/model" 2>/dev/null || t info_unknown)
		menu_add "/dev/$d_name"
		menu_line "$menu_count" "/dev/$d_name" "$d_size" "$(t menu_disk "$d_model")"
		for p in "$d"/"$d_name"*; do
			[ -e "$p/partition" ] || continue
			p_name=${p##*/}
			if is_boot_medium_name "$p_name"; then
				continue
			fi
			p_size=$(dev_size_mb "$p_name")
			# /dev-Knoten fuer den blkid-Test sicherstellen (Menue-Pfad
			# lief sonst immer 'kein Dateisystem', wenn Knoten fehlen)
			ensure_dev_node "$p_name" quiet || :
			p_fs=$(fs_type "/dev/$p_name")
			case "$p_fs" in
			vfat|fat|msdos) p_info="$(t info_esp_candidate)" ;;
			swap)           p_info="swap" ;;
			"")             p_info="$(t info_no_fs)" ;;
			*)              p_info="$p_fs" ;;
			esac
			menu_add "/dev/$p_name"
			menu_line "$menu_count" "/dev/$p_name" "$p_size" "$p_info"
		done
	done
}

# Partitions-Menue nach Filter: "" alle, "vfat" nur FAT, "swap" nur Swap.
# Ausgeschlossen: Boot-Medium, Root-, /boot- und ESP-Partitions-Auswahl.
show_part_menu() {
	menu_devs=
	menu_count=0
	for d in /sys/block/*; do
		d_name=${d##*/}
		case "$d_name" in
		loop*|ram*|zram*|sr*|fd*|dm-*|md*|nbd*) continue ;;
		esac
		[ -e "$d/device" ] || continue
		if is_boot_medium_name "$d_name"; then
			continue
		fi
		for p in "$d"/"$d_name"*; do
			[ -e "$p/partition" ] || continue
			p_name=${p##*/}
			if is_boot_medium_name "$p_name"; then
				continue
			fi
			p_dev="/dev/$p_name"
			if [ "$p_dev" = "$ROOT_PART" ] || [ "$p_dev" = "$BOOT_PART" ] \
				|| [ "$p_dev" = "$EFI_PART" ] || [ "$p_dev" = "$SWAP_PART" ]; then
				continue
			fi
			p_size=$(dev_size_mb "$p_name")
			ensure_dev_node "$p_name" quiet || :
			p_fs=$(fs_type "$p_dev")
			case "$1" in
			vfat)
				case "$p_fs" in
				vfat|fat|msdos) ;;
				*) continue ;;
				esac
				;;
			swap)
				[ "$p_fs" = swap ] || continue
				;;
			esac
			case "$p_fs" in
			"") p_info="$(t info_no_fs)" ;;
			*)  p_info="$p_fs" ;;
			esac
			menu_add "$p_dev"
			menu_line "$menu_count" "$p_dev" "$p_size" "$p_info"
		done
	done
}

# Partitions-Validierung: Blockgeraet, Partition, kein Boot-Medium.
# $1 = Geraet, $2 = Zweck fuer Fehlermeldungen; gibt normiertes Geraet aus.
check_part() {
	c_zweck=$2
	c_dev=$(require_block_dev "$1" "$2")
	is_partition "$c_dev" || td err_not_partition "$c_zweck" "$c_dev"
	if is_boot_medium_name "$(basename "$c_dev")"; then
		td err_is_boot_medium "$c_zweck" "$c_dev"
	fi
	printf '%s\n' "$c_dev"
}

# ------------------------------------------------------------- Zielauswahl --

MODE=disk
[ -n "$ROOT_PART" ] && MODE=part

# Optionen plausibilisieren
if [ -n "$TARGET" ] && [ -n "$ROOT_PART" ]; then
	td err_excl_dp
fi
if [ -n "$TARGET" ] && { [ -n "$BOOT_PART" ] || [ -n "$EFI_PART" ]; }; then
	td err_be_needs_p
fi
if [ -n "$ROOT_PART" ] && [ -n "$SWAP" ]; then
	td err_s_needs_d
fi

if [ -z "$TARGET" ] && [ -z "$ROOT_PART" ]; then
	show_target_menu
	print_text_n "$(t q_target_pick)"
	read -r t_ans || t_ans=
	[ -n "$t_ans" ] || td err_aborted
	t_dev=$(menu_pick "$t_ans") || td err_bad_choice "$t_ans"
	if is_partition "$t_dev"; then
		MODE=part
		ROOT_PART=$t_dev
	else
		TARGET=$t_dev
	fi
fi

# ------------------------------------------------------------- Modus: ganze Platte --

if [ "$MODE" = disk ]; then
	TARGET=$(require_block_dev "$TARGET" "$(t zweck_target_disk)")
	# Schutz: das Boot-Medium selbst darf nicht Ziel sein
	if is_boot_medium_name "${TARGET##*/}"; then
		td err_boot_medium "$TARGET"
	fi

	# Swap nur auf Wunsch (interaktiv per J/n, Standard J)
	if [ -z "$SWAP" ]; then
		if [ "$IS_TTY" = yes ] && ask_yn "$(t q_swap_create)" j; then
			print_text_n "$(t q_swap_size)"
			read -r s_ans || s_ans=
			SWAP=${s_ans:-auto}
		else
			SWAP=0
		fi
	fi
	# Swap-Option uebersetzen (0 = keiner, "auto" = setup-disk rechnet)
	case "$SWAP" in
	auto)       SWAP_ARGS="" ;;
	0)          SWAP_ARGS="-s 0" ;;
	*[!0-9]*)   td err_bad_swap "$SWAP" ;;
	*)          SWAP_ARGS="-s $SWAP" ;;
	esac
fi

# ------------------------------------------------------------- Modus: Partitionen --

if [ "$MODE" = part ]; then
	ROOT_PART=$(check_part "$ROOT_PART" "$(t zweck_root)")
	if [ -n "$BOOT_PART" ]; then
		BOOT_PART=$(check_part "$BOOT_PART" "$(t zweck_boot)")
	fi
	if [ -n "$EFI_PART" ]; then
		EFI_PART=$(check_part "$EFI_PART" "$(t zweck_efi)")
	fi
	[ "$ROOT_PART" != "$BOOT_PART" ] || td err_boot_is_root
	[ "$ROOT_PART" != "$EFI_PART" ] || td err_efi_is_root
	if [ -n "$BOOT_PART" ] && [ -n "$EFI_PART" ]; then
		[ "$BOOT_PART" != "$EFI_PART" ] || td err_boot_ne_efi
	fi

	if [ -d /sys/firmware/efi ]; then
		FIRMWARE=efi
		print_text "$(t info_uefi)"
	else
		if [ -n "$EFI_PART" ]; then
			td err_efi_no_uefi
		fi
		print_text "$(t info_bios)"
	fi

	# --- EFI-Systempartition (bei UEFI Pflicht; es kann mehrere geben) ---
	if [ "$FIRMWARE" = efi ] && [ -z "$EFI_PART" ]; then
		print_heading "$(t ph_esp_list)"
		show_part_menu vfat
		esp_fallback=no
		if [ "$menu_count" -eq 0 ]; then
			# Kein FAT erkannt (z.B. blkid schlug fehl): alle Partitionen
			# anbieten - eine nicht-FAT-Auswahl bietet die Formatier-
			# Rueckfrage weiter unten an
			print_text "$(t info_no_fat)"
			show_part_menu ""
			esp_fallback=yes
		fi
		if [ "$menu_count" -eq 0 ]; then
			td err_no_esp
		fi
		if [ "$IS_TTY" = yes ]; then
			print_text_n "$(t q_esp_pick)"
			read -r e_ans || e_ans=
			[ -n "$e_ans" ] || td err_aborted
			EFI_PART=$(menu_pick "$e_ans") || td err_bad_choice "$e_ans"
		else
			# Nicht-interaktiv: nur einen eindeutigen FAT-Kandidaten
			# automatisch uebernehmen (im Fallback-Menue waere eine
			# automatische Wahl zu riskant)
			if [ "$esp_fallback" = no ] && [ "$menu_count" -eq 1 ]; then
				EFI_PART=$(printf '%s\n' "$menu_devs" | sed -n '1p')
				print_text "$(t info_esp_auto "$EFI_PART")"
			else
				td err_esp_ambiguous
			fi
		fi
		EFI_PART=$(check_part "$EFI_PART" "$(t zweck_efi)")
		[ "$EFI_PART" != "$ROOT_PART" ] || td err_efi_is_root
		[ "$EFI_PART" != "$BOOT_PART" ] || td err_boot_is_efi
	fi

	# --- Separate /boot-Partition (optional) ---
	if [ -z "$BOOT_PART" ] && [ "$IS_TTY" = yes ]; then
		print_heading "$(t ph_boot_list)"
		show_part_menu ""
		if [ "$menu_count" -gt 0 ]; then
			print_text_n "$(t q_boot_pick)"
			read -r b_ans || b_ans=
			if [ -n "$b_ans" ]; then
				BOOT_PART=$(menu_pick "$b_ans") || td err_bad_choice "$b_ans"
				BOOT_PART=$(check_part "$BOOT_PART" "$(t zweck_boot)")
				[ "$BOOT_PART" != "$ROOT_PART" ] || td err_boot_is_root
				[ "$BOOT_PART" != "$EFI_PART" ] || td err_boot_is_efi
			fi
		fi
	fi

	# --- Root-Partition: Formatierung klaeren ---
	root_fs=$(fs_type "$ROOT_PART")
	if [ -z "$root_fs" ]; then
		FORMAT_ROOT=yes
		print_text "$(t info_fmt_root_auto "$ROOT_PART")"
	elif [ "$IS_TTY" = yes ]; then
		if ask_yn "$(t q_fmt_root "$root_fs")" j; then
			FORMAT_ROOT=yes
		else
			print_text "$(t info_fmt_root_no "$root_fs")"
		fi
	else
		print_text "$(t info_fmt_root_nontty "$root_fs")"
	fi

	# --- /boot-Partition: Formatierung klaeren ---
	if [ -n "$BOOT_PART" ]; then
		boot_fs=$(fs_type "$BOOT_PART")
		if [ -z "$boot_fs" ]; then
			FORMAT_BOOT=yes
			print_text "$(t info_fmt_boot_auto "$BOOT_PART")"
		elif [ "$IS_TTY" = yes ]; then
			if ask_yn "$(t q_fmt_boot "$boot_fs")" j; then
				FORMAT_BOOT=yes
			else
				print_text "$(t info_fmt_boot_no "$boot_fs")"
			fi
		fi
	fi

	# --- ESP: Formatierung klaeren ---
	if [ -n "$EFI_PART" ]; then
		esp_fs=$(fs_type "$EFI_PART")
		case "$esp_fs" in
		vfat|fat|msdos)
			if [ "$IS_TTY" = yes ] && ask_yn "$(t q_fmt_esp)" n; then
				FORMAT_EFI=yes
			fi
			;;
		*)
			if [ "$IS_TTY" = yes ]; then
				if ask_yn "$(t q_fmt_esp_fat "${esp_fs:-$(t info_no_fs)}")" j; then
					FORMAT_EFI=yes
				else
					td err_esp_not_fat
				fi
			else
				td err_esp_not_fat_nontty "$EFI_PART" "${esp_fs:-$(t info_no_fs)}"
			fi
			;;
		esac
	fi

	# --- Swap: vorhandene Partition bevorzugt, sonst Swap-Datei anbieten ---
	print_heading "$(t ph_swap_list)"
	show_part_menu swap
	if [ "$menu_count" -gt 0 ]; then
		if [ "$IS_TTY" = yes ]; then
			if ask_yn "$(t q_swap_existing)" j; then
				if [ "$menu_count" -eq 1 ]; then
					SWAP_PART=$(printf '%s\n' "$menu_devs" | sed -n '1p')
				else
					print_text_n "$(t q_swap_pick)"
					read -r w_ans || w_ans=
					[ -n "$w_ans" ] || td err_aborted
					SWAP_PART=$(menu_pick "$w_ans") || td err_bad_choice "$w_ans"
				fi
				print_info_path "$(t info_swap_part)" "$SWAP_PART"
			fi
		else
			# Nicht-interaktiv: einzige vorhandene Swap-Partition automatisch nutzen
			if [ "$menu_count" -eq 1 ]; then
				SWAP_PART=$(printf '%s\n' "$menu_devs" | sed -n '1p')
				print_text "$(t info_swap_auto "$SWAP_PART")"
			fi
		fi
	fi
	if [ -z "$SWAP_PART" ] && [ "$IS_TTY" = yes ]; then
		if ask_yn "$(t q_swapfile)" n; then
			print_text_n "$(t q_swapfile_size)"
			read -r f_ans || f_ans=
			case "$f_ans" in
			"")  SWAPFILE_MB=512 ;;
			*[!0-9]*) td err_bad_swap2 "$f_ans" ;;
			0)   td err_swap_zero ;;
			*)   SWAPFILE_MB=$f_ans ;;
			esac
		fi
	fi
fi

# ------------------------------------------------------------- Bestaetigung --

if [ "$ASSUME_YES" != yes ]; then
	print_text "$(t warn_targets)"
	if [ "$MODE" = disk ]; then
		print_info_path "$(t info_target_disk)" "$TARGET"
	else
		print_info_path "$(t info_target_root)" "$ROOT_PART"
		[ -n "$BOOT_PART" ] && print_info_path "$(t info_target_boot)" "$BOOT_PART"
		[ -n "$EFI_PART" ] && print_info_path "$(t info_target_efi)" "$EFI_PART"
		if [ -n "$SWAP_PART" ]; then
			print_info_path "$(t info_target_swap)" "$SWAP_PART"
		elif [ "$SWAPFILE_MB" -gt 0 ]; then
			print_text "$(t info_target_swapfile "$SWAPFILE_MB" "$ROOT_PART")"
		fi
	fi
	print_heading "$(t ph_disk_list)"
	list_disks
	ask_yn "$(t q_continue)" j || td err_aborted
fi

# ------------------------------------------------------------- Installation --

if [ "$MODE" = disk ]; then
	print_heading "$(t ph_install_disk "$TARGET")"
	case "$SWAP" in
	auto) print_text "$(t info_swap_auto_mode)" ;;
	0)    print_text "$(t info_swap_none)" ;;
	*)    print_text "$(t info_swap_mb "$SWAP")" ;;
	esac
	# ERASE_DISKS unterdrueckt die Loesch-Rueckfrage von setup-disk
	# shellcheck disable=SC2086
	ERASE_DISKS="$TARGET" setup-disk -m sys $SWAP_ARGS "$TARGET" \
		|| td err_setup_disk
	t_mounted=
else
	print_heading "$(t ph_install_part "$ROOT_PART")"
	print_text "$(t info_fw_bootloader "$FIRMWARE")"

	# Ziele formatieren (nur Partitionen mit Freigabe/ohne Dateisystem)
	if [ "$FORMAT_ROOT" = yes ] || [ "$FORMAT_BOOT" = yes ]; then
		command -v mkfs.ext4 >/dev/null 2>&1 \
			|| td err_no_mkfs_ext4
	fi
	if [ "$FORMAT_ROOT" = yes ]; then
		print_text "$(t info_formatting_root "$ROOT_PART")"
		mkfs.ext4 -F -q "$ROOT_PART" || td err_format_failed "$ROOT_PART"
	fi
	if [ "$FORMAT_BOOT" = yes ]; then
		print_text "$(t info_formatting_boot "$BOOT_PART")"
		mkfs.ext4 -F -q "$BOOT_PART" || td err_format_failed "$BOOT_PART"
	fi
	if [ "$FORMAT_EFI" = yes ]; then
		command -v mkfs.vfat >/dev/null 2>&1 \
			|| td err_no_mkfs_vfat
		print_text "$(t info_formatting_efi "$EFI_PART")"
		mkfs.vfat -F 32 "$EFI_PART" || td err_format_failed "$EFI_PART"
	fi

	# Root, optionales /boot und ESP einhaengen (setup-disk erkennt die
	# Mounts selbst: Root, /boot und vfat unter boot/efi)
	mkdir -p "$MNT"
	umount "$MNT/boot/efi" 2>/dev/null || :
	umount "$MNT/boot" 2>/dev/null || :
	umount "$MNT" 2>/dev/null || :
	mount "$ROOT_PART" "$MNT" || td err_mount_root "$ROOT_PART"
	if [ -n "$BOOT_PART" ]; then
		mkdir -p "$MNT/boot"
		mount "$BOOT_PART" "$MNT/boot" || td err_mount_boot "$BOOT_PART"
	fi
	if [ -n "$EFI_PART" ]; then
		# FAT-Kernelmodule explizit laden: vfat steckt zwar im Initramfs,
		# die nls-Codepages aber oft nicht (sonst bricht der Mount mit
		# "codepage cp437 not found" ab); der modloop liefert sie.
		for esp_mod in vfat nls_cp437 nls_utf8 nls_iso8859_1; do
			modprobe -q "$esp_mod" 2>/dev/null || :
		done
		mkdir -p "$MNT/boot/efi"
		mount "$EFI_PART" "$MNT/boot/efi" || td err_mount_efi "$EFI_PART"
	fi

	# Bootloader-Platte fuer grub (BIOS: MBR) = Platte der Root-Partition
	boot_disk=$(parent_disk "$ROOT_PART") || td err_parent_disk "$ROOT_PART"
	print_info_path "$(t info_bootloader_disk)" "/dev/$boot_disk"

	# setup-disk im 'mounted root'-Modus: uebernimmt /etc per lbu aus dem
	# Live-System, schreibt fstab aus den Mounts und installiert Kernel +
	# Bootloader ins Ziel. Der Bootloader wird per BOOTLOADER-Umgebungs-
	# variable erzwungen (setup-disk hat dafuer keine Kommandozeilen-
	# Option); bei UEFI installiert setup-disk grub selbst auf die ESP.
	# shellcheck disable=SC2086
	BOOTLOADER=grub setup-disk -m sys "$MNT" \
		|| td err_setup_disk

	# setup-disk schreibt im Mounted-Root-Modus keinen MBR (es warnt
	# selbst: "You might need fix the MBR to be able to boot"). Im
	# BIOS-Modus deshalb grub hier auf die Trägerplatte der Root-
	# Partition installieren; grub-bios hat setup-disk zuvor ins
	# Live-System installiert.
	if [ "$FIRMWARE" = bios ]; then
		command -v grub-install >/dev/null 2>&1 \
			|| td err_no_grub_install
		ensure_dev_node "$boot_disk" \
			|| td err_no_devnode "$boot_disk"
		print_text "$(t info_writing_mbr "$boot_disk")"
		grub-install --boot-directory="$MNT/boot" --target=i386-pc "/dev/$boot_disk" \
			|| td err_grub_install_failed "$boot_disk"
	fi
	t_mounted=$MNT
fi

# ------------------------------------------------------------- Daten wiederherstellen --

print_text "$(t info_restore)"
if [ -z "$t_mounted" ]; then
	mkdir -p /mnt
	umount /mnt 2>/dev/null || :
	t_mounted=
	# Partitionen ueber sysfs suchen (unabhaengig von /dev-Knoten und
	# Namensschema vda/sda/mmcblk0p1/nvme0n1p1)
	t_base=${TARGET##*/}
	for t_part in "/sys/block/$t_base/$t_base"*; do
		[ -e "$t_part/partition" ] || continue
		t_name=${t_part##*/}
		ensure_dev_node "$t_name" || continue
		if mount "/dev/$t_name" /mnt 2>/dev/null; then
			if [ -d /mnt/etc/apk ]; then
				t_mounted=/mnt
				break
			fi
			umount /mnt
		fi
	done
	[ -n "$t_mounted" ] || td err_find_root "$TARGET"
fi
if [ "$MODE" = disk ]; then
	print_info_path "$(t info_root_part)" "$t_mounted"
else
	print_info_path "$(t info_root_part)" "$ROOT_PART"
fi

# Alles aus dem apkovl ausser /etc (die Konfiguration hat setup-disk bereits
# aus dem Live-System uebernommen und frische fstab/mkinitfs.conf geschrieben).
tar -C "$t_mounted" -xzf "$APKOVL" --exclude './etc*' \
	|| td err_restore_failed
# shellcheck disable=SC2012  # reine Anzeige fuer den Nutzer
print_text "$(t info_homes_list "$(cd "$t_mounted/home" 2>/dev/null && ls | tr '\n' ' ')")"

# Netzwerk-Repos des Snapshots auf dem Ziel wiederherstellen (setup-disk
# kommentiert lokale Pfade in /etc/apk/repositories aus; die Original-URLs
# liegen im Snapshot unter repositories.alpe-network)
if [ -f "$t_mounted/etc/apk/repositories.alpe-network" ]; then
	cp "$t_mounted/etc/apk/repositories.alpe-network" "$t_mounted/etc/apk/repositories"
	print_text "$(t info_net_repos)"
fi

# Swap eintragen (nur Partitionsmodus; ganze Platte macht das setup-disk)
if [ -n "$SWAP_PART" ]; then
	sw_id=$(dev_uuid "$SWAP_PART")
	if [ -n "$sw_id" ]; then
		printf 'UUID=%s\tnone\tswap\tdefaults\t0 0\n' "$sw_id" >> "$t_mounted/etc/fstab"
	else
		printf '%s\tnone\tswap\tdefaults\t0 0\n' "$SWAP_PART" >> "$t_mounted/etc/fstab"
	fi
	print_text "$(t info_swap_fstab "$SWAP_PART")"
fi
if [ "$SWAPFILE_MB" -gt 0 ]; then
	print_text "$(t info_creating_swapfile "$SWAPFILE_MB")"
	dd if=/dev/zero of="$t_mounted/swapfile" bs=1M count="$SWAPFILE_MB" 2>/dev/null \
		|| td err_swapfile_failed
	chmod 600 "$t_mounted/swapfile"
	mkswap "$t_mounted/swapfile" >/dev/null
	printf '/swapfile\tnone\tswap\tdefaults\t0 0\n' >> "$t_mounted/etc/fstab"
	print_text "$(t info_swapfile_done)"
fi

sync
umount "$t_mounted/boot/efi" 2>/dev/null || :
umount "$t_mounted/boot" 2>/dev/null || :
umount "$t_mounted"
if [ "$MODE" = disk ]; then
	print_other "$(t info_done_disk "$TARGET")"
else
	print_other "$(t info_done_part "$ROOT_PART")"
fi
print_other "$(t info_reboot)"
print_other "$(t info_login)"
LLT_EMBED_INSTALL
}

# ---- alpe-part (byte-identisch eingebettet) ----
emit_part() {
    cat > "$1" <<'LLT_EMBED_PART'
#!/bin/sh
# ============================================================================
# Alpine-Partitionierer - Partitionen anlegen/loeschen/formatieren/Flags
# (Terminal-Portierung der Partitions-GUI; Aenderungen werden sofort
#  geschrieben. Benoetigt echte Root-Rechte.)
# Alpine/BusyBox-ash-Portierung des ArchLive-Partitionierers (old.sh) -
# gleiche Menues, gleiche Farben, gleicher Ablauf. Unterschiede:
#   - POSIX/ash-kompatibel (keine Bash-Arrays, kein [[, keine
#     Prozess-Substitution); Partitionen/Freiwaere liegen als Zeilen-
#     tabellen vor ("Feld|Feld|..."), geparsed mit awk/sed/cut.
#   - Paket-Nachinstall ueber apk (statt pacman), Paket-Check mit
#     'apk info -e'.
#   - udevadm ist optional (safe_settle faengt fehlendes udev ab).
#   - sudo-Neustart: sudo, falls vorhanden, sonst su.
#   - Test-Hook: ALT_INCLUDE_LOOP=1 zeigt auch loop/zram/ram/sr/dm/md-
#     Geraete (nur fuer Tests in Containern; Standard bleibt gefiltert).
# Enthaelt dieselben Funktionen wie der Partitionierer-Bereich von
# ArchLiveTools.sh - als eigenstaendige Datei nutzbar.
#
# Zweisprachig (DE/EN): Alle Meldungen erscheinen in der Systemsprache.
# Fest erzwingen laesst sich die Sprache ueber die Variable SPRACHE am
# Dateianfang (Werte: AUTO = Systemsprache, DE oder EN) oder per
# Kommandozeilen-Flag -de bzw. -en.
# ============================================================================

VERSION="2.3"
(set -o pipefail) 2>/dev/null && set -o pipefail
set -eu

# Anzeigename = tatsaechlicher Dateiname (umbenennbar)
PROG="$(basename -- "$0")"
# Absoluter Pfad dieses Skripts (set -u: von Anfang an gesetzt; noetig fuer
# den sudo-Neustart in require_root, da sudo das Arbeitsverzeichnis wechselt)
SCRIPT_PATH="$(readlink -f -- "$0" 2>/dev/null || printf '%s' "$0")"

# ==================== SPRACHE / LANGUAGE ====================
# Sprache aller Meldungen: AUTO (Systemsprache, Voreinstellung), DE oder EN.
# Zum Festlegen den Wert unten eintragen, z. B.:  SPRACHE=DE   bzw.   SPRACHE=EN
# Startet man das Skript aus der LinuxLiveTool-GUI, gewinnt die dort gewaehlte
# Sprache (Umgebungsvariable LLT_LANG = DE oder EN) ueber dieser Einstellung.
SPRACHE=DE
# Flags -de/-en: Sprache explizit setzen (gewinnt ueber AUTO, nicht
# ueber LLT_LANG der GUI); die Flags werden aus den Argumenten entfernt.
sprache_anzahl=$#
for sprache_a in "$@"; do
    case "$sprache_a" in
    -de) SPRACHE=DE ;;
    -en) SPRACHE=EN ;;
    -nc) NO_COLOR=1; export NO_COLOR ;;
    *)   set -- "$@" "$sprache_a" ;;
    esac
done
if [ "$sprache_anzahl" -gt 0 ]; then
    shift "$sprache_anzahl"
fi
case "${LLT_LANG:-}" in
DE|EN) SPRACHE="$LLT_LANG" ;;
esac
case "$SPRACHE" in
AUTO) case "${LC_ALL:-${LANG:-}}" in de*|DE*) SPRACHE=DE ;; *) SPRACHE=EN ;; esac ;;
esac

# Textkatalog: alle Meldungen in DE und EN (keine Extradatei).
#   t  KEY [ARGS...]  -> Meldung nach stdout; ARGS fuellen %s-Platzhalter
t() {
    local key=$1; shift
    case "$key:$SPRACHE" in
    lbl_warning:EN) printf '%s\n' "WARNING: " ;;
    lbl_warning:*)  printf '%s\n' "WARNUNG: " ;;
    lbl_error:EN) printf '%s\n' "ERROR: " ;;
    lbl_error:*)  printf '%s\n' "FEHLER: " ;;
    yn_jn:EN) printf '%s\n' "Y/n" ;;
    yn_jn:*)  printf '%s\n' "J/n" ;;
    yn_jN:EN) printf '%s\n' "y/N" ;;
    yn_jN:*)  printf '%s\n' "j/N" ;;
    yn_answer:EN) printf '%s\n' "Please answer with y or n." ;;
    yn_answer:*)  printf '%s\n' "Bitte j oder n antworten." ;;
    ask_cancel0:EN) printf '%s\n' "0 = cancel" ;;
    ask_cancel0:*)  printf '%s\n' "0 = Abbrechen" ;;
    ask_enter_empty:EN) printf '%s\n' "press Enter = empty" ;;
    ask_enter_empty:*)  printf '%s\n' "direkt Enter = leer" ;;
    menu_back:EN) printf '%s\n' "Back" ;;
    menu_back:*)  printf '%s\n' "Zurück" ;;
    menu_quit:EN) printf '%s\n' "Quit" ;;
    menu_quit:*)  printf '%s\n' "Beenden" ;;
    pick_disk_title:EN) printf '%s\n' "Choose disk to partition" ;;
    pick_disk_title:*)  printf '%s\n' "Festplatte zum Partitionieren wählen" ;;
    p_warn_mkntfs_missing:EN) printf '%s\n' "mkntfs missing - NTFS will be formatted via 'mkfs -t ntfs' (may take long due to zeroing)." ;;
    p_warn_mkntfs_missing:*)  printf '%s\n' "mkntfs fehlt - NTFS wird über 'mkfs -t ntfs' formatiert (kann wegen Nullieren lange dauern)." ;;
    p_err_ntfs_no_tool:EN) printf '%s\n' "NTFS formatting not possible: neither mkntfs nor mkfs available - please install ntfs-3g." ;;
    p_err_ntfs_no_tool:*)  printf '%s\n' "NTFS-Formatierung nicht möglich: weder mkntfs noch mkfs vorhanden - bitte ntfs-3g installieren." ;;
    p_warn_pkg_missing:EN) printf '%s missing (package %s) - will be installed via apk (network needed).\n'  "$1" "$2" ;;
    p_warn_pkg_missing:*)  printf '%s fehlt (Paket %s) - wird per apk nachinstalliert (Netzwerk nötig).\n'  "$1" "$2" ;;
    p_err_pkg_install_failed:EN) printf '%s (package %s) could not be installed.\n'  "$1" "$2" ;;
    p_err_pkg_install_failed:*)  printf '%s (Paket %s) konnte nicht installiert werden.\n'  "$1" "$2" ;;
    p_err_pkg_still_missing:EN) printf '%s is still missing.\n'  "$1" ;;
    p_err_pkg_still_missing:*)  printf '%s fehlt weiterhin.\n'  "$1" ;;
    p_info_type_gpt_set:EN) printf '%s\n' ">> Partition type set to 'Microsoft basic data' (GPT)." ;;
    p_info_type_gpt_set:*)  printf '%s\n' ">> Partitionstyp auf 'Microsoft basic data' gesetzt (GPT)." ;;
    p_warn_type_gpt_failed:EN) printf '%s\n' "Type 'Microsoft basic data' could not be set - the NTFS partition works anyway." ;;
    p_warn_type_gpt_failed:*)  printf '%s\n' "Typ 'Microsoft basic data' konnte nicht gesetzt werden - die NTFS-Partition funktioniert trotzdem." ;;
    p_info_type_mbr_set:EN) printf '%s\n' ">> Partition type set to 7 (HPFS/NTFS) (MBR)." ;;
    p_info_type_mbr_set:*)  printf '%s\n' ">> Partitionstyp auf 7 (HPFS/NTFS) gesetzt (MBR)." ;;
    p_warn_type_mbr_failed:EN) printf '%s\n' "Partition type 7 could not be set - the NTFS partition works anyway." ;;
    p_warn_type_mbr_failed:*)  printf '%s\n' "Partitionstyp 7 konnte nicht gesetzt werden - die NTFS-Partition funktioniert trotzdem." ;;
    p_warn_no_table_yet:EN) printf '%s\n' "Please create a partition table first (menu item 1)." ;;
    p_warn_no_table_yet:*)  printf '%s\n' "Bitte zuerst eine Partitionstabelle anlegen (Menüpunkt 1)." ;;
    p_warn_no_free_gap:EN) printf '%s\n' "No alignable free space found." ;;
    p_warn_no_free_gap:*)  printf '%s\n' "Kein ausrichtbarer freier Bereich gefunden." ;;
    p_warn_no_partitions:EN) printf '%s\n' "No partitions." ;;
    p_warn_no_partitions:*)  printf '%s\n' "Keine Partitionen vorhanden." ;;
    p_err_part_mounted_del:EN) printf '%s is mounted (%s) and cannot be deleted.\n'  "$1" "$2" ;;
    p_err_part_mounted_del:*)  printf '%s ist eingehängt (%s) und kann nicht gelöscht werden.\n'  "$1" "$2" ;;
    p_err_part_swap_del:EN) printf '%s is active as swap and cannot be deleted (swapoff first).\n'  "$1" ;;
    p_err_part_swap_del:*)  printf '%s ist als Swap aktiv und kann nicht gelöscht werden (vorher swapoff).\n'  "$1" ;;
    p_warn_del_warning:EN) printf 'Partition %s will be DELETED - the data will be irretrievably lost.\n'  "$1" ;;
    p_warn_del_warning:*)  printf 'Partition %s wird GELÖSCHT - die Daten sind unwiederbringlich verloren.\n'  "$1" ;;
    p_err_del_failed:EN) printf '%s\n' "Delete failed (parted rm)." ;;
    p_err_del_failed:*)  printf '%s\n' "Löschen fehlgeschlagen (parted rm)." ;;
    p_err_part_mounted_fmt:EN) printf '%s is mounted (%s) and cannot be formatted.\n'  "$1" "$2" ;;
    p_err_part_mounted_fmt:*)  printf '%s ist eingehängt (%s) und kann nicht formatiert werden.\n'  "$1" "$2" ;;
    p_err_extended_no_fs:EN) printf '%s\n' "An extended partition has no filesystem." ;;
    p_err_extended_no_fs:*)  printf '%s\n' "Eine erweiterte Partition hat kein Dateisystem." ;;
    p_err_part_swap_fmt:EN) printf '%s is active as swap (swapoff first).\n'  "$1" ;;
    p_err_part_swap_fmt:*)  printf '%s ist als Swap aktiv (vorher swapoff).\n'  "$1" ;;
    p_warn_format_warning:EN) printf '%s will be formatted with %s - ALL DATA on this partition will be lost!\n'  "$1" "$2" ;;
    p_warn_format_warning:*)  printf '%s wird mit %s formatiert - ALLE DATEN auf dieser Partition gehen verloren!\n'  "$1" "$2" ;;
    p_info_fs_created:EN) printf '>> Filesystem %s created on %s.\n'  "$1" "$2" ;;
    p_info_fs_created:*)  printf '>> Dateisystem %s auf %s angelegt.\n'  "$1" "$2" ;;
    p_info_esp_flag:EN) printf 'EFI system flag (esp): %s\n'  "$1" ;;
    p_info_esp_flag:*)  printf 'EFI-System-Flag (esp): %s\n'  "$1" ;;
    p_info_bios_flag:EN) printf 'BIOS boot flag (bios_grub): %s\n'  "$1" ;;
    p_info_bios_flag:*)  printf 'BIOS-Boot-Flag (bios_grub): %s\n'  "$1" ;;
    p_info_flag_set:EN) printf '%s\n' ">> Flag set." ;;
    p_info_flag_set:*)  printf '%s\n' ">> Flag gesetzt." ;;
    p_info_flag_set_boot:EN) printf '%s\n' ">> Flag set (via boot)." ;;
    p_info_flag_set_boot:*)  printf '%s\n' ">> Flag gesetzt (via boot)." ;;
    p_err_flag_failed:EN) printf '%s\n' "Flag could not be set." ;;
    p_err_flag_failed:*)  printf '%s\n' "Flag konnte nicht gesetzt werden." ;;
    menu_prompt:EN) printf '%s\n' "Choice: " ;;
    menu_prompt:*)  printf '%s\n' "Auswahl: " ;;
    menu_bad:EN) printf "Invalid choice '%s' - please enter a number from the list (0 = back).\n"  "$1" ;;
    menu_bad:*) printf "Ungültige Auswahl '%s' - bitte eine Zahl aus der Liste (0 = Zurück).\n"  "$1" ;;
    warn_nonroot_test:EN) printf '%s\n' "ALT_ALLOW_NONROOT=1: root check bypassed (test mode)." ;;
    warn_nonroot_test:*)  printf '%s\n' "ALT_ALLOW_NONROOT=1: Root-Prüfung übergangen (Testmodus)." ;;
    err_sudo_failed:EN) printf '%s\n' "sudo did not provide root privileges (wrong password?). Operation aborted." ;;
    err_sudo_failed:*)  printf '%s\n' "sudo hat keine Root-Rechte geliefert (Passwort falsch?). Vorgang abgebrochen." ;;
    info_need_root:EN) printf '%s\n' "Write operations require root privileges." ;;
    info_need_root:*)  printf '%s\n' "Für Schreibzugriffe werden Root-Rechte benötigt." ;;
    q_sudo_restart:EN) printf '%s\n' "Restart now with root privileges via sudo?" ;;
    q_sudo_restart:*)  printf '%s\n' "Jetzt per sudo mit Root-Rechten neu starten?" ;;
    err_need_real_root:EN) printf '%s\n' "Partitioning needs REAL root privileges - aborted (no read-only mode anymore)." ;;
    err_need_real_root:*)  printf '%s\n' "Partitionieren braucht ECHTE Root-Rechte - abgebrochen (kein Nur-Lese-Modus mehr)." ;;
    err_no_devices:EN) printf '%s\n' "No suitable devices found." ;;
    err_no_devices:*)  printf '%s\n' "Keine geeigneten Geräte gefunden." ;;
    kind_disk:EN) printf '%s\n' "[whole disk]" ;;
    kind_disk:*)  printf '%s\n' "[ganze Platte]" ;;
    kind_part:EN) printf '%s\n' "[partition]" ;;
    kind_part:*)  printf '%s\n' "[Partition]" ;;
    info_udev_missing:EN) printf '%s\n' "Note: udevadm missing (package eudev) - 'settle' is simply skipped." ;;
    info_udev_missing:*)  printf '%s\n' "Hinweis: udevadm fehlt (Paket eudev) - 'settle' wird einfach übersprungen." ;;
    info_mkntfs_missing:EN) printf '%s\n' "Note: mkntfs missing - NTFS will be attempted via 'mkfs -t ntfs' when formatting (option 2)." ;;
    info_mkntfs_missing:*)  printf '%s\n' "Hinweis: mkntfs fehlt - NTFS wird beim Formatieren über 'mkfs -t ntfs' versucht (Lösung 2)." ;;
    warn_cmd_missing:EN) printf "Command '%s' is missing (package: %s).\n"  "$1" "$2" ;;
    warn_cmd_missing:*) printf "Befehl '%s' fehlt (Paket: %s).\n"  "$1" "$2" ;;
    info_pkgs_ok:EN) printf '%s\n' "Package check: all required tools are present." ;;
    info_pkgs_ok:*)  printf '%s\n' "Paket-Prüfung: alle benötigten Werkzeuge vorhanden." ;;
    warn_pkgs_missing:EN) printf 'Packages missing for partitioning: %s\n'  "$1" ;;
    warn_pkgs_missing:*) printf 'Für das Partitionieren fehlen Pakete: %s\n'  "$1" ;;
    q_install_pkgs:EN) printf '%s\n' "Install all missing packages now via apk? (network required)" ;;
    q_install_pkgs:*)  printf '%s\n' "Alle fehlenden Pakete jetzt per apk installieren? (Netzwerk nötig)" ;;
    err_no_partition_without:EN) printf '%s\n' "Without these packages, partitioning is not possible." ;;
    err_no_partition_without:*)  printf '%s\n' "Ohne diese Pakete kann nicht partitioniert werden." ;;
    err_apk_add_failed:EN) printf '%s\n' "Packages could not be installed (check network/mirror)." ;;
    err_apk_add_failed:*)  printf '%s\n' "Pakete konnten nicht installiert werden (Netzwerk/Spiegel prüfen)." ;;
    err_pkgs_but_no_cmd:EN) printf 'The packages (%s) are installed according to apk, but the commands are missing - please check installation/PATH.\n'  "$1" ;;
    err_pkgs_but_no_cmd:*) printf 'Die Pakete (%s) sind laut apk installiert, aber die Befehle fehlen - bitte Installation/PATH prüfen.\n'  "$1" ;;
    err_no_apk:EN) printf 'Without apk, missing packages (%s) cannot be installed.\n'  "$1" ;;
    err_no_apk:*) printf 'Ohne apk können fehlende Pakete (%s) nicht nachinstalliert werden.\n'  "$1" ;;
    err_pkg_still_missing:EN) printf "Package for '%s' is still missing.\n"  "$1" ;;
    err_pkg_still_missing:*) printf "Paket für '%s' fehlt weiterhin.\n"  "$1" ;;
    info_pkgs_now_ok:EN) printf '%s\n' "Package check: all tools are now present." ;;
    info_pkgs_now_ok:*)  printf '%s\n' "Paket-Prüfung: alle Werkzeuge jetzt vorhanden." ;;
    pt_esp:EN) printf '%s\n' "EFI System" ;;
    pt_esp:*)  printf '%s\n' "EFI System" ;;
    pt_bios:EN) printf '%s\n' "BIOS boot" ;;
    pt_bios:*)  printf '%s\n' "BIOS boot" ;;
    pt_extended:EN) printf '%s\n' "Extended" ;;
    pt_extended:*)  printf '%s\n' "Erweitert" ;;
    pt_swap:EN) printf '%s\n' "Linux Swap" ;;
    pt_swap:*)  printf '%s\n' "Linux Swap" ;;
    pt_linux:EN) printf '%s\n' "Linux" ;;
    pt_linux:*)  printf '%s\n' "Linux" ;;
    pt_ntfs:EN) printf '%s\n' "NTFS" ;;
    pt_ntfs:*)  printf '%s\n' "NTFS" ;;
    pt_fat32:EN) printf '%s\n' "FAT32" ;;
    pt_fat32:*)  printf '%s\n' "FAT32" ;;
    pt_linuxfs:EN) printf '%s\n' "Linux fs" ;;
    pt_linuxfs:*)  printf '%s\n' "Linux fs" ;;
    pt_msdata:EN) printf '%s\n' "Microsoft basic data" ;;
    pt_msdata:*)  printf '%s\n' "Microsoft basic data" ;;
    lbl_none:EN) printf '%s\n' "(none)" ;;
    lbl_none:*)  printf '%s\n' "(keine)" ;;
    ph_disk:EN) printf 'Disk: %s\n'  "$1" ;;
    ph_disk:*) printf 'Festplatte: %s\n'  "$1" ;;
    info_table:EN) printf 'Table: %s   (1 MiB = %s sectors)\n'  "$1" "$2" ;;
    info_table:*) printf 'Tabelle: %s   (1 MiB = %s Sektoren)\n'  "$1" "$2" ;;
    info_mounted:EN) printf '(mounted: %s)\n'  "$1" ;;
    info_mounted:*) printf '(eingehängt: %s)\n'  "$1" ;;
    desc_mounted:EN) printf '%s\n' "(mounted)" ;;
    desc_mounted:*)  printf '%s\n' "(eingehängt)" ;;
    info_flag:EN) printf '      Flag: %s\n'  "$1" ;;
    info_flag:*) printf '      Flag: %s\n'  "$1" ;;
    info_free_gap:EN) printf '  Free space %s:  sectors %s-%s  (%s)\n'  "$1" "$2" "$3" "$4" ;;
    info_free_gap:*) printf '  Freier Bereich %s:  Sektoren %s-%s  (%s)\n'  "$1" "$2" "$3" "$4" ;;
    gap_label:EN) printf 'Free space %s: %s (sectors %s-%s)\n'  "$1" "$2" "$3" "$4" ;;
    gap_label:*) printf 'Freier Bereich %s: %s (Sektoren %s-%s)\n'  "$1" "$2" "$3" "$4" ;;
    warn_no_table:EN) printf '%s\n' "No partition table detected - please create one first." ;;
    warn_no_table:*)  printf '%s\n' "Keine Partitionstabelle erkannt - bitte zuerst eine Tabelle anlegen." ;;
    op_result_failed:EN) printf '%s\n' "The operation was not (fully) completed - back to the menu." ;;
    op_result_failed:*)  printf '%s\n' "Der Vorgang wurde nicht (vollständig) abgeschlossen - zurück ins Menü." ;;
    q_new_table_title:EN) printf 'New partition table on %s\n'  "$1" ;;
    q_new_table_title:*) printf 'Neue Partitionstabelle auf %s\n'  "$1" ;;
    menu_gpt:EN) printf '%s\n' "GPT (recommended for UEFI)" ;;
    menu_gpt:*)  printf '%s\n' "GPT (empfohlen für UEFI)" ;;
    menu_mbr:EN) printf '%s\n' "MBR/msdos (classic, BIOS)" ;;
    menu_mbr:*)  printf '%s\n' "MBR/msdos (klassisch, BIOS)" ;;
    warn_wipe_all:EN) printf 'ALL data on %s will be lost (table + all partitions will be removed)!\n'  "$1" ;;
    warn_wipe_all:*) printf 'ALLE Daten auf %s gehen verloren (Tabelle + alle Partitionen werden entfernt)!\n'  "$1" ;;
    q_really:EN) printf '%s\n' "Really continue?" ;;
    q_really:*)  printf '%s\n' "Wirklich fortfahren?" ;;
    msg_aborted:EN) printf '%s\n' "Aborted." ;;
    msg_aborted:*)  printf '%s\n' "Abgebrochen." ;;
    msg_wiping:EN) printf '>> Cleaning old signatures (wipefs --all) and creating %s table...\n'  "$1" ;;
    msg_wiping:*) printf '>> Säubere alte Signaturen (wipefs --all) und lege %s-Tabelle an...\n'  "$1" ;;
    err_mklabel:EN) printf '%s\n' "parted mklabel failed (see the parted message above)." ;;
    err_mklabel:*)  printf '%s\n' "parted mklabel fehlgeschlagen (siehe parted-Meldung oben)." ;;
    err_table_unverified:EN) printf '%s\n' "The table was not confirmed by parted - '%s' still has no partition table!
Possible causes: disk in use/defective, or parted reported an error above." "$1" ;;
    err_table_unverified:*)  printf '%s\n' "Die Tabelle wurde von parted nicht bestätigt - '%s' hat weiterhin keine Partitionstabelle!
Mögliche Ursachen: Platte in Benutzung/fehlerhaft, oder parted meldete oben einen Fehler." "$1" ;;
    msg_table_created:EN) printf '>> Partition table %s created and verified.\n'  "$1" ;;
    msg_table_created:*) printf '>> Partitionstabelle %s angelegt und verifiziert.\n'  "$1" ;;
    menu_gap_title:EN) printf '%s\n' "Choose free space (for the new partition)" ;;
    menu_gap_title:*)  printf '%s\n' "Freien Bereich wählen (für die neue Partition)" ;;
    menu_purpose_title:EN) printf 'Purpose of the new partition (range: %s)\n'  "$1" ;;
    menu_purpose_title:*) printf 'Zweck der neuen Partition (Bereich: %s)\n'  "$1" ;;
    preset_linux:EN) printf '%s\n' "Linux data partition (ext4)" ;;
    preset_linux:*)  printf '%s\n' "Linux-Datenpartition (ext4)" ;;
    preset_esp_512:EN) printf '%s\n' "EFI system partition (FAT32, ESP, prefilled 512 MiB)" ;;
    preset_esp_512:*)  printf '%s\n' "EFI-Systempartition (FAT32, ESP, 512 MiB vorbefüllt)" ;;
    preset_esp:EN) printf '%s\n' "EFI system partition (FAT32, ESP)" ;;
    preset_esp:*)  printf '%s\n' "EFI-Systempartition (FAT32, ESP)" ;;
    preset_bios:EN) printf '%s\n' "BIOS boot partition (2 MiB, GPT only - for GRUB in BIOS mode)" ;;
    preset_bios:*)  printf '%s\n' "BIOS-Boot-Partition (2 MiB, nur GPT - für GRUB im BIOS-Modus)" ;;
    preset_swap:EN) printf '%s\n' "Swap" ;;
    preset_swap:*)  printf '%s\n' "Swap" ;;
    preset_ntfs:EN) printf '%s\n' "NTFS (Windows compatible)" ;;
    preset_ntfs:*)  printf '%s\n' "NTFS (Windows-kompatibel)" ;;
    preset_fat32:EN) printf '%s\n' "FAT32 (data)" ;;
    preset_fat32:*)  printf '%s\n' "FAT32 (Daten)" ;;
    preset_raw:EN) printf '%s\n' "No filesystem (raw)" ;;
    preset_raw:*)  printf '%s\n' "Kein Dateisystem (roh)" ;;
    q_size:EN) printf 'Size in MiB or GiB (e.g. 512 / 100GB / 2G; empty = max %s MiB)\n'  "$1" ;;
    q_size:*) printf 'Größe in MiB oder GiB (z. B. 512 / 100GB / 2G; leer = maximal %s MiB)\n'  "$1" ;;
    warn_bad_size:EN) printf "Invalid size: '%s' - allowed are e.g. 512, 512M, 100GB, 2G, 1T (or empty = maximum).\n"  "$1" ;;
    warn_bad_size:*) printf "Ungültige Größenangabe: '%s' - erlaubt sind z. B. 512, 512M, 100GB, 2G, 1T (oder leer = maximal).\n"  "$1" ;;
    err_bios_gpt_only:EN) printf '%s\n' "A BIOS boot partition only exists on GPT." ;;
    err_bios_gpt_only:*)  printf '%s\n' "Eine BIOS-Boot-Partition gibt es nur bei GPT." ;;
    menu_position:EN) printf '%s\n' "Position in the free range" ;;
    menu_position:*)  printf '%s\n' "Position im freien Bereich" ;;
    menu_at_start:EN) printf '%s\n' "At the beginning" ;;
    menu_at_start:*)  printf '%s\n' "Am Anfang" ;;
    menu_at_end:EN) printf '%s\n' "At the end" ;;
    menu_at_end:*)  printf '%s\n' "Am Ende" ;;
    msg_extended:EN) printf '%s\n' ">> 4/4 primary slots used - creating an extended partition over the range..." ;;
    msg_extended:*)  printf '%s\n' ">> 4/4 primäre Slots belegt - lege erweiterte Partition über den Bereich an..." ;;
    err_ext_failed:EN) printf '%s\n' "Could not create the extended partition." ;;
    err_ext_failed:*)  printf '%s\n' "Erweiterte Partition konnte nicht angelegt werden." ;;
    err_no_primary:EN) printf '%s\n' "No free primary slot (4/4 used) and the free range is not inside an extended partition." ;;
    err_no_primary:*)  printf '%s\n' "Kein freier primärer Slot (4/4 belegt) und der freie Bereich liegt nicht innerhalb einer erweiterten Partition." ;;
    err_range_small:EN) printf '%s\n' "The chosen range is too small (at least 1 MiB needed)." ;;
    err_range_small:*)  printf '%s\n' "Der gewählte Bereich ist zu klein (mindestens 1 MiB nötig)." ;;
    err_mkpart:EN) printf '%s\n' "Could not create the partition (see the parted message above)." ;;
    err_mkpart:*)  printf '%s\n' "Partition konnte nicht angelegt werden (siehe parted-Meldung oben)." ;;
    err_not_rerecognized:EN) printf '%s\n' "The partition was created but not detected again - please check 'Refresh'." ;;
    err_not_rerecognized:*)  printf '%s\n' "Die Partition wurde angelegt, aber nicht wieder erkannt - bitte 'Aktualisieren' prüfen." ;;
    msg_created:EN) printf '>> Newly created: %s\n'  "$1" ;;
    msg_created:*) printf '>> Neu angelegt: %s\n'  "$1" ;;
    warn_node_missing:EN) printf 'Device node %s is not (yet) present - filesystem skipped. The partition exists anyway.\n'  "$1" ;;
    warn_node_missing:*) printf 'Geräteknoten %s ist (noch) nicht vorhanden - Dateisystem übersprungen. Die Partition existiert trotzdem.\n'  "$1" ;;
    msg_make_fs:EN) printf '>> Creating filesystem %s on %s (data on it will be lost) ...\n'  "$1" "$2" ;;
    msg_make_fs:*) printf '>> Lege Dateisystem %s auf %s an (Daten darauf gehen verloren) ...\n'  "$1" "$2" ;;
    warn_ntfs_mkfs:EN) printf '%s\n' "mkntfs missing - NTFS is formatted via 'mkfs -t ntfs' (can take long due to zeroing)." ;;
    warn_ntfs_mkfs:*)  printf '%s\n' "mkntfs fehlt - NTFS wird über 'mkfs -t ntfs' formatiert (kann wegen Nullieren lange dauern)." ;;
    err_no_ntfs:EN) printf '%s\n' "NTFS formatting impossible: neither mkntfs nor mkfs present - please install ntfs-3g." ;;
    err_no_ntfs:*)  printf '%s\n' "NTFS-Formatierung nicht möglich: weder mkntfs noch mkfs vorhanden - bitte ntfs-3g installieren." ;;
    warn_mkfs_missing:EN) printf '%s missing (package %s) - installing via apk (network required).\n'  "$1" "$2" ;;
    warn_mkfs_missing:*) printf '%s fehlt (Paket %s) - wird per apk nachinstalliert (Netzwerk nötig).\n'  "$1" "$2" ;;
    err_mkfs_install_failed:EN) printf '%s (package %s) could not be installed.\n'  "$1" "$2" ;;
    err_mkfs_install_failed:*) printf '%s (Paket %s) konnte nicht installiert werden.\n'  "$1" "$2" ;;
    err_still_missing:EN) printf '%s is still missing.\n'  "$1" ;;
    err_still_missing:*) printf '%s fehlt weiterhin.\n'  "$1" ;;
    msg_ntfs_gpt_type:EN) printf '%s\n' ">> Partition type set to 'Microsoft basic data' (GPT)." ;;
    msg_ntfs_gpt_type:*)  printf '%s\n' ">> Partitionstyp auf 'Microsoft basic data' gesetzt (GPT)." ;;
    warn_ntfs_gpt_type:EN) printf '%s\n' "Type 'Microsoft basic data' could not be set - the NTFS partition works anyway." ;;
    warn_ntfs_gpt_type:*)  printf '%s\n' "Typ 'Microsoft basic data' konnte nicht gesetzt werden - die NTFS-Partition funktioniert trotzdem." ;;
    msg_ntfs_mbr_type:EN) printf '%s\n' ">> Partition type set to 7 (HPFS/NTFS) (MBR)." ;;
    msg_ntfs_mbr_type:*)  printf '%s\n' ">> Partitionstyp auf 7 (HPFS/NTFS) gesetzt (MBR)." ;;
    warn_ntfs_mbr_type:EN) printf '%s\n' "Partition type 7 could not be set - the NTFS partition works anyway." ;;
    warn_ntfs_mbr_type:*)  printf '%s\n' "Partitionstyp 7 konnte nicht gesetzt werden - die NTFS-Partition funktioniert trotzdem." ;;
    warn_need_table:EN) printf '%s\n' "Please create a partition table first (menu item 1)." ;;
    warn_need_table:*)  printf '%s\n' "Bitte zuerst eine Partitionstabelle anlegen (Menüpunkt 1)." ;;
    warn_no_gap:EN) printf '%s\n' "No alignable free range found." ;;
    warn_no_gap:*)  printf '%s\n' "Kein ausrichtbarer freier Bereich gefunden." ;;
    part_no_partitions:EN) printf '%s\n' "No partitions present." ;;
    part_no_partitions:*)  printf '%s\n' "Keine Partitionen vorhanden." ;;
    menu_pick_title:EN) printf '%s\n' "Choose partition" ;;
    menu_pick_title:*)  printf '%s\n' "Partition wählen" ;;
    err_mounted_delete:EN) printf '%s is mounted (%s) and cannot be deleted.\n'  "$1" "$2" ;;
    err_mounted_delete:*) printf '%s ist eingehängt (%s) und kann nicht gelöscht werden.\n'  "$1" "$2" ;;
    err_active_swap_delete:EN) printf '%s is active as swap and cannot be deleted (swapoff first).\n'  "$1" ;;
    err_active_swap_delete:*) printf '%s ist als Swap aktiv und kann nicht gelöscht werden (vorher swapoff).\n'  "$1" ;;
    warn_delete:EN) printf 'Partition %s will be DELETED - the data is irretrievably lost.\n'  "$1" ;;
    warn_delete:*) printf 'Partition %s wird GELÖSCHT - die Daten sind unwiederbringlich verloren.\n'  "$1" ;;
    q_delete:EN) printf '%s\n' "Really delete?" ;;
    q_delete:*)  printf '%s\n' "Wirklich löschen?" ;;
    msg_deleted:EN) printf '>> Deleted: %s\n'  "$1" ;;
    msg_deleted:*) printf '>> Gelöscht: %s\n'  "$1" ;;
    err_delete_failed:EN) printf '%s\n' "Deleting failed (parted rm)." ;;
    err_delete_failed:*)  printf '%s\n' "Löschen fehlgeschlagen (parted rm)." ;;
    err_mounted_format:EN) printf '%s is mounted (%s) and cannot be formatted.\n'  "$1" "$2" ;;
    err_mounted_format:*) printf '%s ist eingehängt (%s) und kann nicht formatiert werden.\n'  "$1" "$2" ;;
    err_extended_no_fs:EN) printf '%s\n' "An extended partition has no filesystem." ;;
    err_extended_no_fs:*)  printf '%s\n' "Eine erweiterte Partition hat kein Dateisystem." ;;
    err_active_swap_format:EN) printf '%s is active as swap (swapoff first).\n'  "$1" ;;
    err_active_swap_format:*) printf '%s ist als Swap aktiv (vorher swapoff).\n'  "$1" ;;
    menu_fs_title:EN) printf 'Filesystem for %s\n'  "$1" ;;
    menu_fs_title:*) printf 'Dateisystem für %s\n'  "$1" ;;
    warn_formatting:EN) printf '%s will be formatted with %s - ALL DATA on this partition will be lost!\n'  "$1" "$2" ;;
    warn_formatting:*) printf '%s wird mit %s formatiert - ALLE DATEN auf dieser Partition gehen verloren!\n'  "$1" "$2" ;;
    msg_fs_created:EN) printf '>> Filesystem %s created on %s.\n'  "$1" "$2" ;;
    msg_fs_created:*) printf '>> Dateisystem %s auf %s angelegt.\n'  "$1" "$2" ;;
    lbl_no:EN) printf '%s\n' "no" ;;
    lbl_no:*)  printf '%s\n' "nein" ;;
    lbl_yes:EN) printf '%s\n' "yes" ;;
    lbl_yes:*)  printf '%s\n' "ja" ;;
    msg_esp_flag:EN) printf 'EFI system flag (esp): %s\n'  "$1" ;;
    msg_esp_flag:*) printf 'EFI-System-Flag (esp): %s\n'  "$1" ;;
    msg_bios_flag:EN) printf 'BIOS boot flag (bios_grub): %s\n'  "$1" ;;
    msg_bios_flag:*) printf 'BIOS-Boot-Flag (bios_grub): %s\n'  "$1" ;;
    menu_flags_title:EN) printf 'Change flag for %s\n'  "$1" ;;
    menu_flags_title:*) printf 'Flag für %s ändern\n'  "$1" ;;
    menu_esp_on:EN) printf '%s\n' "esp ON  (makes the partition the ESP)" ;;
    menu_esp_on:*)  printf '%s\n' "esp EIN  (macht die Partition zur ESP)" ;;
    menu_esp_off:EN) printf '%s\n' "esp OFF" ;;
    menu_esp_off:*)  printf '%s\n' "esp AUS" ;;
    menu_bios_on:EN) printf '%s\n' "bios_grub ON (useful on GPT only)" ;;
    menu_bios_on:*)  printf '%s\n' "bios_grub EIN (nur GPT sinnvoll)" ;;
    menu_bios_off:EN) printf '%s\n' "bios_grub OFF" ;;
    menu_bios_off:*)  printf '%s\n' "bios_grub AUS" ;;
    msg_flag_set:EN) printf '%s\n' ">> Flag set." ;;
    msg_flag_set:*)  printf '%s\n' ">> Flag gesetzt." ;;
    msg_flag_set_boot:EN) printf '%s\n' ">> Flag set (via boot)." ;;
    msg_flag_set_boot:*)  printf '%s\n' ">> Flag gesetzt (via boot)." ;;
    err_flag_failed:EN) printf '%s\n' "Flag could not be set." ;;
    err_flag_failed:*)  printf '%s\n' "Flag konnte nicht gesetzt werden." ;;
    menu_disk_title:EN) printf 'Partitioning: %s\n'  "$1" ;;
    menu_disk_title:*) printf 'Partitionieren: %s\n'  "$1" ;;
    menu_new_table:EN) printf '%s\n' "Create new partition table (GPT/MBR)" ;;
    menu_new_table:*)  printf '%s\n' "Neue Partitionstabelle anlegen (GPT/MBR)" ;;
    menu_create:EN) printf '%s\n' "Create partition (purpose presets, size, position)" ;;
    menu_create:*)  printf '%s\n' "Partition erstellen (Zweck-Presets, Größe, Position)" ;;
    menu_delete:EN) printf '%s\n' "Delete partition" ;;
    menu_delete:*)  printf '%s\n' "Partition löschen" ;;
    menu_format:EN) printf '%s\n' "Format partition (ext4/fat32/swap/ntfs)" ;;
    menu_format:*)  printf '%s\n' "Partition formatieren (ext4/fat32/swap/ntfs)" ;;
    menu_flags:EN) printf '%s\n' "Change flags (ESP / BIOS boot)" ;;
    menu_flags:*)  printf '%s\n' "Flags ändern (ESP / BIOS-Boot)" ;;
    menu_other_disk:EN) printf '%s\n' "Choose another disk" ;;
    menu_other_disk:*)  printf '%s\n' "Andere Festplatte wählen" ;;
    ph_partitioner:EN) printf '%s\n' "Partitioner (terminal port of the partition GUI)" ;;
    ph_partitioner:*)  printf '%s\n' "Partitionierer (Terminal-Portierung der Partitions-GUI)" ;;
    msg_immediate:EN) printf '%s\n' "Changes are written immediately (parted) - as in the GUI." ;;
    msg_immediate:*)  printf '%s\n' "Änderungen werden sofort geschrieben (parted) - wie in der GUI." ;;
    pick_disk_title:EN) printf '%s\n' "Choose the disk to partition" ;;
    pick_disk_title:*)  printf '%s\n' "Festplatte zum Partitionieren wählen" ;;
    warn_unknown_arg:EN) printf 'Unknown argument: %s (help: -h)\n'  "$1" ;;
    warn_unknown_arg:*) printf 'Unbekanntes Argument: %s (Hilfe: -h)\n'  "$1" ;;
    msg_bye:EN) printf '%s\n' "Alpine partitioner terminated." ;;
    msg_bye:*)  printf '%s\n' "Alpine-Partitionierer beendet." ;;
    *) printf '%s\n' "$key" ;;
    esac
}
te() { t "$@" >&2; }

# Farben gem. DESIGN.md (hell cyan/gelb/lila/gruen/rot, Fett = "1;3X"):
#   Überschriften 1;96 - Text 1;93 - Dateien/Befehle 1;35 - Rest 1;92 - Fehler 1;91
# Farb-Ausgabe nur bei interaktivem Terminal (stdout ist ein TTY) und ohne
# NO_COLOR; das Flag -nc setzt NO_COLOR (VOR dieser Pruefung geparst).
# ALT_FORCE_COLOR=1 erzwingt Farben (z. B. nach dem sudo-Neustart).
COLOR_ON=0
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    COLOR_ON=1
fi
if [ "${ALT_FORCE_COLOR:-0}" = "1" ]; then
    COLOR_ON=1
fi
if [ "$COLOR_ON" = "1" ]; then
    # Echte ESC-Bytes (nicht "\033"-Text): damit funktionieren sowohl
    # printf '%b' als auch ungefilterte cat-Heredocs (z. B. usage).
    ESC=$(printf '\033')
    readonly C_HEAD="${ESC}[1;96m"    # hell cyan   - Überschriften (DESIGN.md)
    readonly C_TEXT="${ESC}[1;93m"    # hell gelb   - normaler Text
    readonly C_FILE="${ESC}[1;35m"    # hell lila   - Dateien/Pfade/Befehle
    readonly C_MISC="${ESC}[1;92m"    # hellgrün    - alles andere
    readonly C_WARN="${ESC}[1;91m"    # hell rot    - Warnungen/Fehler
    readonly C_R="${ESC}[0m"
else
    readonly C_HEAD=""; C_TEXT=""; C_FILE=""; C_MISC=""; C_WARN=""; C_R=""
fi

head_()  { printf '%b\n' "${C_HEAD}$*${C_R}"; }
msg_()   { printf '%b\n' "${C_TEXT}$*${C_R}"; }
file_()  { printf '%b\n' "${C_FILE}$*${C_R}"; }
misc_()  { printf '%b\n' "${C_MISC}$*${C_R}"; }
# Warn-/Fehler-Praefixe kommen aus dem Sprachkatalog (bilingual).
warn_()  { printf '%b\n' "${C_WARN}$(t lbl_warning)$*${C_R}"; }
err_()   { printf '%b\n' "${C_WARN}>>> $(t lbl_error)$*${C_R}"; }
hr()     { printf '%b\n' "${C_HEAD}------------------------------------------------------------${C_R}"; }
show_file() {
    case "$(basename "$1")" in
        .*) printf '%b\n' "${C_MISC}$*${C_R}" ;;
        *)  printf '%b\n' "${C_FILE}$*${C_R}" ;;
    esac
}
read_answer() {
    REPLY_ANS=""
    IFS= read -r REPLY_ANS || return 3
    if [ "$REPLY_ANS" = "0" ]; then
        return 2
    fi
    return 0
}
ask_string() {
    # rc 0 = Antwort auf stdout (leere Eingabe -> Standardwert), rc 2 = 0/EOF.
    # Prompt nach stderr, damit $(...) die Antwort sauber einsammelt.
    local prompt="$1" default="${2:-}" ans rc
    if [ -n "$default" ]; then
        printf '%b' "${C_TEXT}${prompt} [${C_MISC}${default}${C_TEXT}]: ${C_R}" >&2
    else
        printf '%b' "${C_TEXT}${prompt} (${C_MISC}$(t ask_cancel0)${C_TEXT}, $(t ask_enter_empty)): ${C_R}" >&2
    fi
    rc=0
    read_answer || rc=$?
    if [ "$rc" = "3" ] || [ "$rc" = "2" ]; then
        printf '\n' >&2
        return 2
    fi
    ans="$REPLY_ANS"
    printf '%s\n' "${ans:-$default}"
    return 0
}
ask_yesno() {
    local question="$1" default="${2:-n}" ans rc yn_labels
    while :; do
        if [ "$default" = "j" ]; then
            yn_labels="$(t yn_jn)"
        else
            yn_labels="$(t yn_jN)"
        fi
        printf '%b' "${C_TEXT}${question} [${C_MISC}${yn_labels}${C_TEXT}]: ${C_R}" >&2
        rc=0
        read_answer || rc=$?
        if [ "$rc" = "3" ]; then
            printf '\n' >&2
            return 1
        fi
        if [ "$rc" = "2" ]; then
            return 1
        fi
        ans="$(printf '%s' "$REPLY_ANS" | tr '[:upper:]' '[:lower:]')"
        if [ -z "$ans" ]; then
            ans="$default"
        fi
        case "$ans" in
            j|ja|y|yes) return 0 ;;
            n|nein|no)  return 1 ;;
            *) warn_ "$(t yn_answer)" ;;
        esac
    done
}
menu_choose() {
    # rc 0 mit $SEL, rc 2 = 0/Zurück, rc 3 = EOF. Option 0 wird immer angeboten.
    # Argumente: Titel, dann Einträge "Schlüssel|Label".
    local title="$1" ans rc kv
    shift
    while :; do
        printf '\n'
        hr
        head_ "$title"
        for kv in "$@"; do
            msg_ "  ${kv%%|*}) ${kv#*|}"
        done
        msg_ "  0) $(t menu_back)"
        msg_ "  00) $(t menu_quit)"
        printf '%b' "${C_MISC}$(t menu_prompt)${C_R}" >&2
        rc=0
        read_answer || rc=$?
        if [ "$rc" = "3" ]; then
            printf '\n'
            return 3
        fi
        if [ "$rc" = "2" ]; then
            return 2
        fi
        ans="$REPLY_ANS"
        if [ -z "$ans" ]; then
            continue
        fi
        if [ "$ans" = "00" ]; then
            # 00 = GESAMTES Skript SOFORT beenden (42 = Quit-All-Signal)
            exit 42
        fi
        for kv in "$@"; do
            if [ "${kv%%|*}" = "$ans" ]; then
                SEL="$ans"
                return 0
            fi
        done
        warn_ "$(t menu_bad "$ans")"
    done
}

# ===== Pseudo-Tabellen (POSIX/ash kennt keine Arrays) =====
# Tabellen sind \n-separierte Zeilen; Felder sind mit | getrennt.
#   DEV_TABLE / PD_TABLE / PD_GAPS - siehe scan_devices / part_read_table
#   bzw. part_read_gaps.
row_count() { printf '%s\n' "$1" | awk 'NF{c++} END{print c+0}'; }
row_of()    { printf '%s\n' "$1" | awk -v n="$2" 'NF && ++c==n'; }
fld()       { printf '%s\n' "$1" | awk -F'|' -v f="$2" '{print $f}'; }

WORK="${ALT_WORK:-${HOME:-/root}/remastern}"
OP_FAILED="0"

# Globale Script-Zustände (set -u: alle von Anfang an gesetzt)
REPLY_ANS=""
SEL=""
PICK_DEV=""
PICK_PART=""
PICK_PART_TYPE=""
PICK_PART_MOUNT=""
PICK_PART_NR=""
MKFS_CMD=""
PD_DISK=""
DEV_TABLE=""          # Zeilen: Pfad|Typ|Bytes|Modell
PD_TABLE=""           # Zeilen: dev|nr|start|size|type|fstype|mountpoint
PD_GAPS=""            # Zeilen: start|end|bytes (1-MiB-ausgerichtet)
PD_LABEL=""
PD_FIRST=""
PD_LAST=""
PD_SECTSIZE=512
_T1=""
_T2=""

require_root() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi
    if [ "${ALT_ALLOW_NONROOT:-0}" = "1" ]; then
        warn_ "$(t warn_nonroot_test)"
        return 0
    fi
    if [ "${ALT_ASKED_SUDO:-0}" = "1" ]; then
        err_ "$(t err_sudo_failed)"
        return 1
    fi
    # DIREKT per sudo/su als root neu starten (sudo fragt selbst nach dem
    # Passwort) - keine Nachfrage, kein Abbruch
    local col=0
    if [ -t 1 ]; then
        col=1
    fi
    if command -v sudo >/dev/null 2>&1; then
        exec sudo env ALT_ASKED_SUDO=1 ALT_FORCE_COLOR="$col" sh "$SCRIPT_PATH"
    else
        # Alpine lebt oft ohne sudo - Rückfallebene su
        exec su root -c "ALT_ASKED_SUDO=1 ALT_FORCE_COLOR=$col sh '$SCRIPT_PATH'"
    fi
}

show_op_result() {
    printf '\n'
    if [ "$OP_FAILED" = "1" ]; then
        err_ "$(t op_result_failed)"
    fi
    OP_FAILED="0"
}
fmt_size() {
    local b="${1:-0}"
    if [ "$b" -ge 1000000000 ]; then
        awk -v x="$b" 'BEGIN{printf "%.1f GB", x/1000000000}'
    elif [ "$b" -ge 1000000 ]; then
        awk -v x="$b" 'BEGIN{printf "%.0f MB", x/1000000}'
    else
        awk -v x="$b" 'BEGIN{printf "%.0f KB", x/1000}'
    fi
}

scan_devices() {
    # Geräte-Tabelle: Zeilen "Pfad|Typ|Bytes|Modell", nur disk/part
    # (keine loop/zram/...; Test-Hook ALT_INCLUDE_LOOP=1 lässt sie zu).
    local name type size rest base
    DEV_TABLE=""
    : > "$_T1"
    lsblk -pnrbo NAME,TYPE,SIZE,MODEL 2>/dev/null > "$_T1" || true
    while read -r name type size rest; do
        [ -n "$name" ] || continue
        base="$(basename "$name")"
        case "$base" in
            loop*|zram*|ram*|sr*|fd*|dm-*|md*)
                if [ "${ALT_INCLUDE_LOOP:-0}" != "1" ]; then
                    continue
                fi
                ;;
        esac
        case "$type" in
            disk|part) ;;
            *) continue ;;
        esac
        rest="$(printf '%s' "${rest:-}" | tr '|' ' ')"
        DEV_TABLE="$DEV_TABLE$name|$type|${size:-0}|${rest:-}
"
    done < "$_T1"
}

pick_device() {
    # pick_device "Titel" [nur-platten|platten+partitionen] -> $PICK_DEV, rc 2 = Abbruch
    local title="$1" mode="${2:-platten+partitionen}"
    local i n row dpath dtype dsize dmodel fstype label kindname kdesc rc nr kinds
    while :; do
        scan_devices
        set --
        kinds=""
        i=0
        n="$(row_count "$DEV_TABLE")"
        while [ "$i" -lt "$n" ]; do
            i=$((i + 1))
            row="$(row_of "$DEV_TABLE" "$i")"
            dpath="$(fld "$row" 1)"
            dtype="$(fld "$row" 2)"
            dsize="$(fld "$row" 3)"
            dmodel="$(fld "$row" 4)"
            if [ "$mode" = "nur-platten" ] && [ "$dtype" != "disk" ]; then
                continue
            fi
            fstype="$(lsblk -ndro FSTYPE "$dpath" 2>/dev/null | head -n1 || true)"
            label="$(lsblk -ndro LABEL "$dpath" 2>/dev/null | head -n1 || true)"
            case "$dtype" in
                disk) kindname="$(t kind_disk)" ;;
                *)    kindname="$(t kind_part)" ;;
            esac
            kdesc=""
            if [ -n "$fstype" ]; then kdesc="  $fstype"; fi
            if [ -n "$label" ]; then kdesc="$kdesc  \"$label\""; fi
            if [ -n "$dmodel" ]; then kdesc="$kdesc  $dmodel"; fi
            set -- "$@" "$(($# + 1))|$dpath  $(fmt_size "$dsize")  $kindname$kdesc"
            kinds="$kinds$dpath
"
        done
        if [ "$#" -eq 0 ]; then
            err_ "$(t err_no_devices)"
            return 2
        fi
        rc=0
        menu_choose "$title" "$@" || rc=$?
        if [ "$rc" = "0" ]; then
            nr="$SEL"
            PICK_DEV="$(printf '%s\n' "$kinds" | sed -n "${nr}p")"
            return 0
        else
            return 2
        fi
    done
}

SECTOR=512
SPM=2048          # Sektoren pro MiB (512-Byte-Sektoren) - part_read_table
                  # passt SPM an die echte Sektorgröße an (4Kn-Platten!)
GUID_ESP="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
GUID_BIOS_BOOT="21686148-6449-6E6F-744E-656564454649"

safe_settle()    { udevadm settle --timeout=5 2>/dev/null || true; }
safe_reread()    { timeout 15 blockdev --rereadpt "$1" 2>/dev/null || true; }
safe_partprobe() { timeout 15 partprobe "$1" 2>/dev/null || true; }

part_check_packages() {
    # Format: "befehl[|alternativer-befehl]::paket"
    # mkswap/swapon/timeout sind BusyBox-Applets (immer da); udevadm ist
    # optional (safe_settle überspringt settle, wenn udev fehlt).
    local need="parted::parted
sfdisk::util-linux
lsblk::util-linux
wipefs::util-linux
blockdev::util-linux
partprobe::parted
mkfs.ext4::e2fsprogs
mkfs.vfat::dosfstools
mkswap::util-linux
swapon::util-linux
mkntfs|mkfs::ntfs-3g"
    local entry cmds pkg present c first_cand missing_pkgs="" found="0" p really
    if ! command -v udevadm >/dev/null 2>&1; then
        misc_ "$(t info_udev_missing)"
    fi
    printf '%s\n' "$need" > "$_T1"
    while IFS= read -r entry; do
        [ -n "$entry" ] || continue
        cmds="${entry%%::*}"
        pkg="${entry##*::}"
        present="0"
        for c in $(printf '%s' "$cmds" | tr '|' ' '); do
            if command -v "$c" >/dev/null 2>&1; then
                present="1"
                break
            fi
        done
        if [ "$present" = "0" ]; then
            first_cand="${cmds%%|*}"
            if [ "$first_cand" = "mkntfs" ]; then
                # Bekannter ntfs-3g-Bug (defekter Verweis) - blockiert nicht:
                # NTFS läuft über mkntfs bzw. 'mkfs -t ntfs'.
                misc_ "$(t info_mkntfs_missing)"
                continue
            fi
            found="1"
            case " $missing_pkgs " in
                *" $pkg "*) ;;
                *)
                    if [ -z "$missing_pkgs" ]; then missing_pkgs="$pkg"; else missing_pkgs="$missing_pkgs $pkg"; fi
                    ;;
            esac
            warn_ "$(t warn_cmd_missing "$first_cand" "$pkg")"
        fi
    done < "$_T1"
    if [ "$found" = "0" ]; then
        misc_ "$(t info_pkgs_ok)"
        return 0
    fi

    # Prüfen, welche der Pakete wirklich nicht installiert sind (apk info -e)
    if command -v apk >/dev/null 2>&1; then
        really=""
        for p in $missing_pkgs; do
            if ! apk info -e "$p" >/dev/null 2>&1; then
                if [ -z "$really" ]; then really="$p"; else really="$really $p"; fi
            fi
        done
        if [ -n "$really" ]; then
            warn_ "$(t warn_pkgs_missing "$really")"
            if ! ask_yesno "$(t q_install_pkgs)" j; then
                err_ "$(t err_no_partition_without)"
                return 1
            fi
            if ! apk add --no-cache $really; then
                err_ "$(t err_apk_add_failed)"
                return 1
            fi
        else
            err_ "$(t err_pkgs_but_no_cmd "$missing_pkgs")"
            return 1
        fi
    else
        err_ "$(t err_no_apk "$missing_pkgs")"
        return 1
    fi
    # Erneut prüfen - apk kann scheitern oder das Paket enthält das Werkzeug
    # nicht. Auch hier zählt der Alternativname (mkntfs statt mkfs.ntfs).
    printf '%s\n' "$need" > "$_T1"
    while IFS= read -r entry; do
        [ -n "$entry" ] || continue
        cmds="${entry%%::*}"
        present="0"
        for c in $(printf '%s' "$cmds" | tr '|' ' '); do
            if command -v "$c" >/dev/null 2>&1; then
                present="1"
                break
            fi
        done
        if [ "$present" = "0" ]; then
            err_ "$(t err_pkg_still_missing "${cmds%%|*}")"
            return 1
        fi
    done < "$_T1"
    misc_ "$(t info_pkgs_now_ok)"
    return 0
}
part_type_friendly() {
    local t_name
    t_name="$(printf '%s' "${1:-}" | tr '[:lower:]' '[:upper:]')"
    case "$t_name" in
        "$GUID_ESP"|0XEF|EF) t pt_esp ;;
        "$GUID_BIOS_BOOT") t pt_bios ;;
        5|0X5|F|0XF|85|0X85) t pt_extended ;;
        82|0X82) t pt_swap ;;
        83|0X83) t pt_linux ;;
        7|0X7) t pt_ntfs ;;
        C|0XC) t pt_fat32 ;;
        0FC63DAF-8483-4772-8E79-3D69D8477DE4) t pt_linuxfs ;;
        EBD0A0A2-B9E5-4433-87C0-68B6B72699C7) t pt_msdata ;;
        E6D6D379-F507-44C2-A23C-238F2A3DF928) t pt_swap ;;
        0657FD6D-A4AB-43C4-84E5-0933C84B4F4F) t pt_swap ;;
        *) echo "${1:-}" ;;
    esac
}
is_extended_type() {
    local t
    t="$(printf '%s' "${1:-}" | tr '[:lower:]' '[:upper:]')"
    case "$t" in
        5|0X5|F|0XF|85|0X85|*[Ee]xtended*) return 0 ;;
        *) return 1 ;;
    esac
}
part_read_table() {
    local disk="$1" line dev nr p_start p_size p_type fst mnt spm_new
    PD_LABEL=""; PD_FIRST=""; PD_LAST=""; PD_SECTSIZE=512
    PD_TABLE=""
    spm_new=2048
    : > "$_T1"
    sfdisk -d "$disk" 2>/dev/null > "$_T1" || true
    while IFS= read -r line; do
        case "$line" in
            "label: "*)
                PD_LABEL="$(printf '%s' "${line#label: }" | tr -d '[:space:]')"
                if [ "$PD_LABEL" = "dos" ]; then
                    PD_LABEL="msdos"
                fi
                ;;
            first-lba:*) PD_FIRST="$(printf '%s' "$line" | awk '{print $2}')" ;;
            last-lba:*)  PD_LAST="$(printf '%s' "$line" | awk '{print $2}')" ;;
            sector-size:*)
                # 4Kn-Platten melden 4096 - Sektoren pro MiB dynamisch ableiten
                PD_SECTSIZE="$(printf '%s' "$line" | awk '{print $2}')"
                case "$PD_SECTSIZE" in
                    ''|*[!0-9]*) PD_SECTSIZE=512 ;;
                    *) if [ "$PD_SECTSIZE" -lt 512 ]; then PD_SECTSIZE=512; fi ;;
                esac
                spm_new=$(( 1048576 / PD_SECTSIZE ))
                ;;
            *": start="*)
                dev="${line%% :*}"
                nr="${dev##*[!0-9]}"
                p_start="$(printf '%s' "$line" | sed -n 's/.*[ ,]start=[[:space:]]*\([0-9]*\).*/\1/p')"
                p_size="$(printf '%s' "$line" | sed -n 's/.*[ ,]size=[[:space:]]*\([0-9]*\).*/\1/p')"
                p_type="$(printf '%s' "$line" | sed -n 's/.*[ ,]type=\([^,;]*\).*/\1/p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                fst="$(lsblk -ndro FSTYPE "$dev" 2>/dev/null | head -n1 || true)"
                mnt="$(lsblk -ndro MOUNTPOINT "$dev" 2>/dev/null | head -n1 || true)"
                PD_TABLE="$PD_TABLE$dev|$nr|$p_start|$p_size|$p_type|$fst|$mnt
"
                ;;
        esac
    done < "$_T1"
    SPM="$spm_new"
}

part_read_gaps() {
    # Freie, 1-MiB-ausgerichtete Bereiche (Logik der Partitions-GUI)
    # Ergebnis: PD_GAPS, Zeilen "start|end|bytes".
    local size_bytes total lo hi iv n i row p_start p_size
    local merged ms me s e cursor
    PD_GAPS=""
    size_bytes="$(lsblk -dnb -o SIZE "$PD_DISK" 2>/dev/null | head -n1 || true)"
    [ -n "$size_bytes" ] || return 0
    total=$(( size_bytes / PD_SECTSIZE ))
    if [ "$PD_LABEL" = "gpt" ] && [ -n "$PD_FIRST" ] && [ -n "$PD_LAST" ]; then
        lo="$PD_FIRST"; hi="$PD_LAST"
    else
        lo="$SPM"; hi=$(( total - 1 ))
    fi

    iv=""
    n="$(row_count "$PD_TABLE")"
    i=0
    while [ "$i" -lt "$n" ]; do
        i=$((i + 1))
        row="$(row_of "$PD_TABLE" "$i")"
        p_start="$(fld "$row" 3)"
        p_size="$(fld "$row" 4)"
        iv="$iv$p_start $(( p_start + p_size - 1 ))
"
    done

    printf '%s\n' "$iv" | sort -n > "$_T2"
    merged=""
    ms=""; me=""
    while read -r s e; do
        [ -n "$s" ] || continue
        if [ -n "$ms" ] && [ "$s" -le $(( me + 1 )) ]; then
            if [ "$e" -gt "$me" ]; then
                me="$e"
            fi
        else
            if [ -n "$ms" ]; then
                merged="$merged$ms $me
"
            fi
            ms="$s"; me="$e"
        fi
    done < "$_T2"
    if [ -n "$ms" ]; then
        merged="$merged$ms $me
"
    fi

    printf '%s\n' "$merged" > "$_T2"
    cursor="$lo"
    while read -r s e; do
        [ -n "$s" ] || continue
        if [ "$s" -gt "$cursor" ]; then
            add_gap "$cursor" $(( s - 1 ))
        fi
        if [ $(( e + 1 )) -gt "$cursor" ]; then
            cursor=$(( e + 1 ))
        fi
    done < "$_T2"
    if [ "$cursor" -le "$hi" ]; then
        add_gap "$cursor" "$hi"
    fi
    return 0
}
add_gap() {
    # align_gap: 1-MiB-ausgerichteten Bereich in PD_GAPS aufnehmen
    local s="$1" e="$2" astart aend
    astart=$(( ( s + SPM - 1 ) / SPM * SPM ))
    aend=$(( e / SPM * SPM ))
    if [ "$aend" -ge "$astart" ]; then
        PD_GAPS="$PD_GAPS$astart|$aend|$(( ( aend - astart + 1 ) * PD_SECTSIZE ))
"
    fi
}
part_show() {
    printf '\n'
    hr
    head_ "$(t ph_disk "$PD_DISK")"
    msg_ "$(t info_table "${PD_LABEL:-$(t lbl_none)}" "$SPM")"
    printf '\n'
    local i n row dpath pnr pstart psize ptype pfst pmnt tname flags gn grow gstart gend gbytes
    n="$(row_count "$PD_TABLE")"
    i=0
    while [ "$i" -lt "$n" ]; do
        i=$((i + 1))
        row="$(row_of "$PD_TABLE" "$i")"
        dpath="$(fld "$row" 1)"; pnr="$(fld "$row" 2)"
        pstart="$(fld "$row" 3)"; psize="$(fld "$row" 4)"
        ptype="$(fld "$row" 5)"; pfst="$(fld "$row" 6)"; pmnt="$(fld "$row" 7)"
        tname="$(part_type_friendly "$ptype")"
        flags=""
        file_ "  $dpath  Nr.$pnr  $(fmt_size $(( psize * PD_SECTSIZE )))  ${tname}${pfst:+  $pfst}${pmnt:+  $(t info_mounted "$pmnt")}"
        case "$(printf '%s' "$ptype" | tr '[:lower:]' '[:upper:]')" in
            "$GUID_ESP"|0XEF|EF) flags="esp" ;;
            "$GUID_BIOS_BOOT") flags="bios_grub" ;;
        esac
        if [ -n "$flags" ]; then
            misc_ "$(t info_flag "$flags")"
        fi
    done
    gn="$(row_count "$PD_GAPS")"
    i=0
    while [ "$i" -lt "$gn" ]; do
        i=$((i + 1))
        grow="$(row_of "$PD_GAPS" "$i")"
        gstart="$(fld "$grow" 1)"; gend="$(fld "$grow" 2)"; gbytes="$(fld "$grow" 3)"
        misc_ "$(t info_free_gap "$i" "$gstart" "$gend" "$(fmt_size "$gbytes")")"
    done
    if [ "$n" -eq 0 ] && [ "$gn" -eq 0 ]; then
        warn_ "$(t warn_no_table)"
    fi
    printf '\n'
}
part_refresh() {
    part_read_table "$PD_DISK"
    part_read_gaps
    part_show
    safe_settle
    safe_reread "$PD_DISK"
    return 0
}
part_new_table() {
    printf '\n'
    local rc label
    rc=0
    menu_choose "$(t q_new_table_title "$PD_DISK")" \
        "1|$(t menu_gpt)" "2|$(t menu_mbr)" || rc=$?
    if [ "$rc" != "0" ]; then
        return 0
    fi
    label="gpt"
    if [ "$SEL" = "2" ]; then
        label="msdos"
    fi
    warn_ "$(t warn_wipe_all "$PD_DISK")"
    if ! ask_yesno "$(t q_really)" n; then
        misc_ "$(t msg_aborted)"
        return 0
    fi
    msg_ "$(t msg_wiping "$label")"
    wipefs --all --force "$PD_DISK" 2>/dev/null || true
    if ! parted -s "$PD_DISK" mklabel "$label"; then
        err_ "$(t err_mklabel)"
        OP_FAILED="1"
        return 1
    fi
    safe_settle
    safe_reread "$PD_DISK"
    safe_partprobe "$PD_DISK"
    safe_settle

    # Verifizieren, dass die Tabelle WIRKLICH existiert (Nutzer-Feedback:
    # "es wird gar keine erstellt" darf nie unsichtbar bleiben).
    part_read_table "$PD_DISK"
    if [ "$PD_LABEL" != "gpt" ] && [ "$PD_LABEL" != "msdos" ]; then
        err_ "$(t err_table_unverified "$PD_DISK")"
        OP_FAILED="1"
        return 1
    fi
    misc_ "$(t msg_table_created "$label")"
    return 0
}
parse_mib() {
    # Akzeptiert MiB/M/MB, GiB/G/GB, TiB/TB (binär) und nackte Zahlen.
    local v num="" unit=""
    v="$(printf '%s' "${1:-}" | tr -d ' ')"
    if [ -z "$v" ]; then
        printf '\n'
        return 0
    fi
    v="$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')"
    case "$v" in
        *[!0-9.]*)
            num="${v%%[a-z]*}"
            unit="${v#"$num"}"
            ;;
        *) num="$v" ;;
    esac
    case "$num" in
        ""|.*|*[!0-9.]*) printf '\n'; return 1 ;;
    esac
    case "$unit" in
        ""|m|mib|mi|mb) awk -v n="$num" 'BEGIN{printf "%d", n}' ;;
        g|gib|gi|gb)    awk -v n="$num" 'BEGIN{printf "%d", n*1024}' ;;
        t|tib|ti|tb)    awk -v n="$num" 'BEGIN{printf "%d", n*1048576}' ;;
        *) printf '\n'; return 1 ;;
    esac
}
parted_fs_name() {
    case "$1" in
        ext4) echo "ext4" ;;
        vfat) echo "fat32" ;;
        swap) echo "linux-swap" ;;
        ntfs) echo "ntfs" ;;
        *) echo "" ;;
    esac
}
ensure_mkfs_tool() {
    # NTFS wird AUSSCHLIESSLICH mit den beiden funktionierenden Aufrufen
    # formatiert (Nutzer-Vorgabe, defekter mkfs.ntfs-Verweis wird bewusst
    # NICHT benutzt):
    #   1. mkntfs        (beim Aufruf mit -f/--fast - Geschwindigkeitstipp)
    #   2. mkfs -t ntfs  (Rückfallebene)
    local fs="$1" cmd="" pkg=""
    MKFS_CMD=""
    case "$fs" in
        ext4) cmd="mkfs.ext4"; pkg="e2fsprogs" ;;
        vfat) cmd="mkfs.vfat"; pkg="dosfstools" ;;
        swap) cmd="mkswap";    pkg="util-linux" ;;
        ntfs)
            if command -v mkntfs >/dev/null 2>&1; then
                MKFS_CMD="mkntfs"
                return 0
            fi
            if command -v mkfs >/dev/null 2>&1; then
                warn_ "$(t p_warn_mkntfs_missing)"
                MKFS_CMD="mkfs -t ntfs"
                return 0
            fi
            err_ "$(t p_err_ntfs_no_tool)"
            return 1
            ;;
        *) return 0 ;;
    esac
    if command -v "$cmd" >/dev/null 2>&1; then
        MKFS_CMD="$cmd"
        return 0
    fi
    warn_ "$(t p_warn_pkg_missing "$cmd" "$pkg")"
    if ! apk add --no-cache "$pkg"; then
        err_ "$(t p_err_pkg_install_failed "$cmd" "$pkg")"
        return 1
    fi
    if ! command -v "$cmd" >/dev/null 2>&1; then
        err_ "$(t p_err_pkg_still_missing "$cmd")"
        return 1
    fi
    MKFS_CMD="$cmd"
    return 0
}
make_fs() {
    local dev="$1" fs="$2"
    ensure_mkfs_tool "$fs" || return 1
    msg_ "$(t msg_make_fs "$fs" "$dev")"
    wipefs -a "$dev" >/dev/null 2>&1 || true
    case "$fs" in
        ext4) mkfs.ext4 -F "$dev" ;;
        vfat) mkfs.vfat -F32 "$dev" ;;
        swap) mkswap "$dev" ;;
        ntfs)
            if [ "$MKFS_CMD" = "mkfs -t ntfs" ]; then
                mkfs -t ntfs "$dev"
            else
                $MKFS_CMD -f "$dev"
            fi
            ;;
        *) return 1 ;;
    esac
}
is_active_swap() {
    local dev
    dev="$(readlink -f "$1" 2>/dev/null || printf '%s' "$1")"
    awk '{print $1}' /proc/swaps 2>/dev/null | grep -Fxq "$dev"
}
part_set_ntfs_type() {
    local disk="$1" nr="$2" label="$3"
    if [ "$label" = "gpt" ]; then
        if parted -s "$disk" set "$nr" msftdata on 2>/dev/null; then
            misc_ "$(t p_info_type_gpt_set)"
        else
            warn_ "$(t p_warn_type_gpt_failed)"
        fi
    else
        if printf 'type=7\n' | sfdisk --force -N "$nr" "$disk" >/dev/null 2>&1; then
            misc_ "$(t p_info_type_mbr_set)"
        else
            warn_ "$(t p_warn_type_mbr_failed)"
        fi
    fi
    safe_settle
    safe_reread "$disk"
    return 0
}
part_create() {
    if [ -z "$PD_LABEL" ]; then
        warn_ "$(t p_warn_no_table_yet)"
        return 0
    fi
    if [ "$(row_count "$PD_GAPS")" -eq 0 ]; then
        warn_ "$(t p_warn_no_free_gap)"
        return 0
    fi

    local i n row gstart gend gbytes gap_nr rc
    local g_start g_end gap_mib purposes purpose p_fs p_name p_kind p_default
    local ans mib size_secs
    local at_end part_type force_start primaries_used ext_start ext_end ext_count
    local pnr pstart psize ptype start end new_dev new_nr parted_name parted_fs
    local mkpart_desc parted_ok w jrow jstart

    # Freien Bereich wählen (Positionen als Menü-Argumente, ohne Arrays)
    set --
    i=0
    n="$(row_count "$PD_GAPS")"
    while [ "$i" -lt "$n" ]; do
        i=$((i + 1))
        row="$(row_of "$PD_GAPS" "$i")"
        gstart="$(fld "$row" 1)"; gend="$(fld "$row" 2)"; gbytes="$(fld "$row" 3)"
        set -- "$@" "$i|$(t gap_label "$i" "$(fmt_size "$gbytes")" "$gstart" "$gend")"
    done
    rc=0
    menu_choose "$(t menu_gap_title)" "$@" || rc=$?
    if [ "$rc" != "0" ]; then
        return 0
    fi
    gap_nr="$SEL"
    row="$(row_of "$PD_GAPS" "$gap_nr")"
    g_start="$(fld "$row" 1)"
    g_end="$(fld "$row" 2)"
    gap_mib=$(( ( g_end - g_start + 1 ) / SPM ))

    # Zweck-Presets (wie in der GUI; BIOS-Boot nur bei GPT)
    if [ "$PD_LABEL" = "gpt" ]; then
        purposes='ext4|linux|ext4|
vfat|ESP|esp|512
|BIOS-Boot|bios|2
swap|swap|swap|
ntfs|daten|ntfs|
vfat|daten|vfat|
|roh||'
        set --
        set -- "$@" "1|$(t preset_linux)"
        set -- "$@" "2|$(t preset_esp_512)"
        set -- "$@" "3|$(t preset_bios)"
        set -- "$@" "4|$(t preset_swap)"
        set -- "$@" "5|$(t preset_ntfs)"
        set -- "$@" "6|$(t preset_fat32)"
        set -- "$@" "7|$(t preset_raw)"
    else
        purposes='ext4|linux|ext4|
vfat|ESP|esp|512
swap|swap|swap|
ntfs|daten|ntfs|
vfat|daten|vfat|
|roh||'
        set --
        set -- "$@" "1|$(t preset_linux)"
        set -- "$@" "2|$(t preset_esp)"
        set -- "$@" "3|$(t preset_swap)"
        set -- "$@" "4|$(t preset_ntfs)"
        set -- "$@" "5|$(t preset_fat32)"
        set -- "$@" "6|$(t preset_raw)"
    fi
    rc=0
    menu_choose "$(t menu_purpose_title "$(fmt_size $(( (g_end - g_start + 1) * PD_SECTSIZE )))")" "$@" || rc=$?
    if [ "$rc" != "0" ]; then
        return 0
    fi
    purpose="$(printf '%s\n' "$purposes" | sed -n "${SEL}p")"
    p_fs="$(printf '%s' "$purpose" | cut -d'|' -f1)"
    p_name="$(printf '%s' "$purpose" | cut -d'|' -f2)"
    p_kind="$(printf '%s' "$purpose" | cut -d'|' -f3)"
    p_default="$(printf '%s' "$purpose" | cut -d'|' -f4)"

    ans=""
    rc=0
    ans="$(ask_string "$(t q_size "$gap_mib")" "")" || rc=$?
    if [ "$rc" = "2" ]; then
        return 0
    fi
    mib="$(parse_mib "$ans" 2>/dev/null || true)"
    if [ -n "$ans" ] && [ -z "$mib" ]; then
        warn_ "$(t warn_bad_size "$ans")"
        return 0
    fi
    if [ -z "$mib" ] || [ "$mib" -le 0 ]; then
        mib="$gap_mib"
    fi
    if [ -n "$p_default" ] && [ "$mib" = "$gap_mib" ] && [ "$p_default" -lt "$gap_mib" ]; then
        mib="$p_default"
    fi
    size_secs=$(( mib * SPM ))

    if [ "$p_kind" = "bios" ]; then
        if [ "$PD_LABEL" != "gpt" ]; then
            err_ "$(t err_bios_gpt_only)"
            return 0
        fi
        if [ "$size_secs" -lt "$SPM" ]; then
            size_secs="$SPM"
        fi
    fi

    at_end="no"
    rc=0
    menu_choose "$(t menu_position)" "1|$(t menu_at_start)" "2|$(t menu_at_end)" || rc=$?
    if [ "$rc" != "0" ]; then
        return 0
    fi
    if [ "$SEL" = "2" ]; then
        at_end="yes"
    fi

    # MBR: primär/logisch/erweitert (Logik der GUI)
    part_type="primary"
    force_start="no"
    if [ "$PD_LABEL" = "msdos" ]; then
        primaries_used=0
        ext_start=""
        ext_end=""
        ext_count=0
        i=0
        n="$(row_count "$PD_TABLE")"
        while [ "$i" -lt "$n" ]; do
            i=$((i + 1))
            row="$(row_of "$PD_TABLE" "$i")"
            pnr="$(fld "$row" 2)"
            pstart="$(fld "$row" 3)"
            psize="$(fld "$row" 4)"
            ptype="$(fld "$row" 5)"
            if [ "$pnr" -le 4 ]; then
                primaries_used=$(( primaries_used + 1 ))
            fi
            if is_extended_type "$ptype"; then
                ext_count=$(( ext_count + 1 ))
                ext_start="$pstart"
                ext_end=$(( pstart + psize - 1 ))
            fi
        done
        if [ "$primaries_used" -lt 4 ]; then
            part_type="primary"
        elif [ -n "$ext_start" ] && [ "$g_start" -ge "$ext_start" ] && [ "$g_end" -le "$ext_end" ]; then
            part_type="logical"
        elif [ "$ext_count" -eq 0 ]; then
            msg_ "$(t msg_extended)"
            if ! parted -s "$PD_DISK" mkpart extended "${g_start}s" "${g_end}s"; then
                err_ "$(t err_ext_failed)"
                OP_FAILED="1"
                return 1
            fi
            part_type="logical"
            g_start=$(( g_start + SPM ))
            force_start="yes"
        else
            err_ "$(t err_no_primary)"
            return 0
        fi
    fi

    start=0
    end=0
    if [ "$at_end" = "yes" ] && [ "$force_start" = "no" ]; then
        end="$g_end"
        start=$(( g_end - size_secs + 1 ))
        if [ "$start" -lt "$g_start" ]; then
            start="$g_start"
        fi
        start=$(( ( start + SPM - 1 ) / SPM * SPM ))
    else
        start="$g_start"
        end=$(( g_start + size_secs - 1 ))
        if [ "$end" -gt "$g_end" ]; then
            end="$g_end"
        fi
    fi
    if [ "$start" -gt "$end" ] || [ $(( end - start + 1 )) -lt "$SPM" ]; then
        err_ "$(t err_range_small)"
        return 0
    fi

    parted_fs="$(parted_fs_name "$p_fs")"
    if [ "$PD_LABEL" = "gpt" ]; then
        parted_name="${p_name:-partition}"
    else
        parted_name="$part_type"
    fi
    mkpart_desc="mkpart $parted_name"
    if [ -n "$p_fs" ] && [ -n "$parted_fs" ]; then
        mkpart_desc="$mkpart_desc $parted_fs"
    fi
    mkpart_desc="$mkpart_desc ${start}s ${end}s"

    msg_ ">> parted -s $PD_DISK $mkpart_desc"
    parted_ok=1
    if [ "$PD_LABEL" = "gpt" ]; then
        if [ -n "$p_fs" ] && [ -n "$parted_fs" ]; then
            parted -s "$PD_DISK" mkpart "$parted_name" "$parted_fs" "${start}s" "${end}s" || parted_ok=0
        else
            parted -s "$PD_DISK" mkpart "$parted_name" "${start}s" "${end}s" || parted_ok=0
        fi
    else
        if [ -n "$p_fs" ] && [ -n "$parted_fs" ]; then
            parted -s "$PD_DISK" mkpart "$part_type" "$parted_fs" "${start}s" "${end}s" || parted_ok=0
        else
            parted -s "$PD_DISK" mkpart "$part_type" "${start}s" "${end}s" || parted_ok=0
        fi
    fi
    if [ "$parted_ok" = "0" ]; then
        err_ "$(t err_mkpart)"
        OP_FAILED="1"
        return 1
    fi
    safe_settle
    safe_reread "$PD_DISK"
    safe_partprobe "$PD_DISK"
    safe_settle

    # Neue Partition über den Startsektor identifizieren
    part_read_table "$PD_DISK"
    new_dev=""
    new_nr=""
    i=0
    n="$(row_count "$PD_TABLE")"
    while [ "$i" -lt "$n" ]; do
        i=$((i + 1))
        jrow="$(row_of "$PD_TABLE" "$i")"
        jstart="$(fld "$jrow" 3)"
        if [ "$jstart" = "$start" ]; then
            new_dev="$(fld "$jrow" 1)"
            new_nr="$(fld "$jrow" 2)"
            break
        fi
    done
    if [ -z "$new_dev" ]; then
        err_ "$(t err_not_rerecognized)"
        return 0
    fi
    misc_ "$(t msg_created "$new_dev")"

    if [ "$p_kind" = "esp" ]; then
        if ! parted -s "$PD_DISK" set "$new_nr" esp on 2>/dev/null; then
            if [ "$PD_LABEL" = "gpt" ]; then
                parted -s "$PD_DISK" set "$new_nr" boot on 2>/dev/null || true
            fi
        fi
    fi
    if [ "$p_kind" = "bios" ]; then
        parted -s "$PD_DISK" set "$new_nr" bios_grub on 2>/dev/null || true
    fi

    if [ -n "$p_fs" ]; then
        # Auf manchen Geräten braucht der Kernel einen Moment für den Knoten.
        w=0
        while [ "$w" -lt 3 ]; do
            w=$((w + 1))
            if [ -e "$new_dev" ]; then
                break
            fi
            safe_settle
            sleep 1 2>/dev/null || true
        done
        if [ -e "$new_dev" ]; then
            make_fs "$new_dev" "$p_fs" || { OP_FAILED="1"; return 1; }
        else
            warn_ "$(t warn_node_missing "$new_dev")"
        fi
    fi
    if [ "$p_fs" = "ntfs" ]; then
        part_set_ntfs_type "$PD_DISK" "$new_nr" "$PD_LABEL"
    fi
    return 0
}
part_pick_partition() {
    local i n row dpath psize ptype pfst pmnt tname desc rc nr
    n="$(row_count "$PD_TABLE")"
    if [ "$n" -eq 0 ]; then
        warn_ "$(t p_warn_no_partitions)"
        return 2
    fi
    set --
    i=0
    while [ "$i" -lt "$n" ]; do
        i=$((i + 1))
        row="$(row_of "$PD_TABLE" "$i")"
        dpath="$(fld "$row" 1)"
        psize="$(fld "$row" 4)"
        ptype="$(fld "$row" 5)"
        pfst="$(fld "$row" 6)"
        pmnt="$(fld "$row" 7)"
        tname="$(part_type_friendly "$ptype")"
        desc=""
        if [ -n "$pfst" ]; then desc="  $pfst"; fi
        if [ -n "$pmnt" ]; then desc="$desc  (eingehängt)"; fi
        set -- "$@" "$i|$dpath  $(fmt_size $(( psize * PD_SECTSIZE )))  $tname$desc"
    done
    rc=0
    menu_choose "$(t menu_pick_title)" "$@" || rc=$?
    if [ "$rc" != "0" ]; then
        return 2
    fi
    nr="$SEL"
    row="$(row_of "$PD_TABLE" "$nr")"
    PICK_PART="$(fld "$row" 1)"
    PICK_PART_TYPE="$(fld "$row" 5)"
    PICK_PART_MOUNT="$(fld "$row" 7)"
    PICK_PART_NR="$(fld "$row" 2)"
    return 0
}
part_delete() {
    local rc=0
    part_pick_partition || rc=$?
    if [ "$rc" != "0" ]; then
        return 0
    fi
    if [ -n "$PICK_PART_MOUNT" ]; then
        err_ "$(t p_err_part_mounted_del "$PICK_PART" "$PICK_PART_MOUNT")"
        return 0
    fi
    if is_active_swap "$PICK_PART"; then
        err_ "$(t p_err_part_swap_del "$PICK_PART")"
        return 0
    fi
    warn_ "$(t p_warn_del_warning "$PICK_PART")"
    if ! ask_yesno "Wirklich löschen?" n; then
        misc_ "$(t msg_aborted)"
        return 0
    fi
    if parted -s "$PD_DISK" rm "$PICK_PART_NR"; then
        misc_ "$(t msg_deleted "$PICK_PART")"
        safe_settle
        safe_reread "$PD_DISK"
    else
        err_ "$(t p_err_del_failed)"
        OP_FAILED="1"
        return 1
    fi
    return 0
}
part_format() {
    local rc=0 fs
    part_pick_partition || rc=$?
    if [ "$rc" != "0" ]; then
        return 0
    fi
    if [ -n "$PICK_PART_MOUNT" ]; then
        err_ "$(t p_err_part_mounted_fmt "$PICK_PART" "$PICK_PART_MOUNT")"
        return 0
    fi
    if is_extended_type "$PICK_PART_TYPE"; then
        err_ "$(t p_err_extended_no_fs)"
        return 0
    fi
    if is_active_swap "$PICK_PART"; then
        err_ "$(t p_err_part_swap_fmt "$PICK_PART")"
        return 0
    fi
    rc=0
    menu_choose "Dateisystem für $PICK_PART" \
        "1|ext4" "2|fat32 (vfat)" "3|swap" "4|ntfs" || rc=$?
    if [ "$rc" != "0" ]; then
        return 0
    fi
    fs=""
    case "$SEL" in
        1) fs="ext4" ;;
        2) fs="vfat" ;;
        3) fs="swap" ;;
        4) fs="ntfs" ;;
    esac
    warn_ "$(t p_warn_format_warning "$PICK_PART" "$fs")"
    if ! ask_yesno "Fortfahren?" n; then
        misc_ "$(t msg_aborted)"
        return 0
    fi
    make_fs "$PICK_PART" "$fs" || { OP_FAILED="1"; return 1; }
    if [ "$fs" = "ntfs" ]; then
        part_set_ntfs_type "$PD_DISK" "$PICK_PART_NR" "$PD_LABEL"
    fi
    misc_ "$(t p_info_fs_created "$fs" "$PICK_PART")"
    return 0
}
part_flags() {
    local rc=0 t flag value esp_now bios_now
    part_pick_partition || rc=$?
    if [ "$rc" != "0" ]; then
        return 0
    fi
    t="$(printf '%s' "$PICK_PART_TYPE" | tr '[:lower:]' '[:upper:]')"
    esp_now="nein"
    bios_now="nein"
    case "$t" in
        "$GUID_ESP"|0XEF|EF) esp_now="ja" ;;
        "$GUID_BIOS_BOOT") bios_now="ja" ;;
    esac
    msg_ "$(t p_info_esp_flag "$esp_now")"
    msg_ "$(t p_info_bios_flag "$bios_now")"
    printf '\n'
    rc=0
    menu_choose "Flag für $PICK_PART ändern" \
        "1|$(t menu_esp_on)" \
        "2|$(t menu_esp_off)" \
        "3|$(t menu_bios_on)" \
        "4|$(t menu_bios_off)" || rc=$?
    if [ "$rc" != "0" ]; then
        return 0
    fi
    flag=""
    value="on"
    case "$SEL" in
        1) flag="esp"; value="on" ;;
        2) flag="esp"; value="off" ;;
        3) flag="bios_grub"; value="on" ;;
        4) flag="bios_grub"; value="off" ;;
    esac
    if [ "$flag" = "esp" ] && [ "$PD_LABEL" != "gpt" ] && [ "$value" = "on" ]; then
        if ! parted -s "$PD_DISK" set "$PICK_PART_NR" esp on 2>/dev/null; then
            parted -s "$PD_DISK" set "$PICK_PART_NR" boot on 2>/dev/null || true
        fi
        safe_settle
        misc_ "$(t p_info_flag_set)"
        return 0
    fi
    if parted -s "$PD_DISK" set "$PICK_PART_NR" "$flag" "$value" 2>/dev/null; then
        safe_settle
        misc_ "$(t p_info_flag_set)"
        return 0
    fi
    if [ "$flag" = "esp" ] && [ "$PD_LABEL" = "gpt" ]; then
        parted -s "$PD_DISK" set "$PICK_PART_NR" boot "$value" 2>/dev/null || true
        safe_settle
        misc_ "$(t p_info_flag_set_boot)"
        return 0
    fi
    err_ "$(t p_err_flag_failed)"
    OP_FAILED="1"
    return 1
}
part_disk_menu() {
    local rc
    while :; do
        part_refresh
        rc=0
        menu_choose "$(t menu_disk_title "$PD_DISK")" \
            "1|$(t menu_new_table)" \
            "2|$(t menu_create)" \
            "3|$(t menu_delete)" \
            "4|$(t menu_format)" \
            "5|$(t menu_flags)" \
            "6|$(t menu_other_disk)" || rc=$?
        if [ "$rc" != "0" ]; then
            return 0
        fi
        case "$SEL" in
            1) part_new_table || : ;;
            2) part_create || : ;;
            3) part_delete || : ;;
            4) part_format || : ;;
            5) part_flags || : ;;
            6) return 4 ;;
        esac
        show_op_result
    done
}
part_menu() {
    local drc
    # Echtes Root ist Pflicht: ohne Root scheitern parted/wipefs still -
    # daraus entstand der Eindruck "Tabelle wird erstellt, aber es passiert nichts".
    if ! require_root; then
        err_ "$(t err_need_real_root)"
        OP_FAILED="1"
        return 1
    fi
    if ! part_check_packages; then
        OP_FAILED="1"
        return 1
    fi
    msg_ ""
    head_ "$(t ph_partitioner)"
    msg_ "$(t msg_immediate)"
    while :; do
        if ! pick_device "$(t pick_disk_title)" "nur-platten"; then
            return 0
        fi
        PD_DISK="$PICK_DEV"
        drc=0
        part_disk_menu || drc=$?
        # drc 4 = andere Platte wählen -> Schleife läuft weiter
        if [ "$drc" != "4" ]; then
            return 0
        fi
    done
}

usage() {
    cat <<HILFE
${C_HEAD}$PROG (Alpine-Partitionierer) $VERSION - Partitionen anlegen/loeschen/formatieren${C_R}

${C_MISC}Interaktiv: Festplatte waehlen, dann Tabellen (GPT/MBR), Partitionen
(Zweck-Presets, Groesse, Position), Loeschen, Formatieren, Flags.
0 = immer zurueck. Benoetigt echte Root-Rechte (sudo-Neustart).${C_R}

${C_TEXT}Optionen: ${C_FILE}-h${C_TEXT} Hilfe, ${C_FILE}-V${C_TEXT} Version, ${C_FILE}-de/-en${C_TEXT} Sprache, ${C_FILE}-nc${C_TEXT} Farben aus.${C_R}
HILFE
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -V|--version) echo "$PROG (Alpine-Partitionierer) $VERSION"; exit 0 ;;
            *) warn_ "$(t warn_unknown_arg "$1")" ;;
        esac
        shift
    done
}

# ===== Tempfiles (für Zeilen-Tabellen statt Prozess-Substitution) =====
mk_tempfiles() {
    _T1="$(mktemp "${TMPDIR:-/tmp}/altpart.XXXXXX" 2>/dev/null)" || _T1=""
    if [ -z "$_T1" ]; then
        _T1="${TMPDIR:-/tmp}/altpart.$$.a"
        : > "$_T1"
    fi
    _T2="$(mktemp "${TMPDIR:-/tmp}/altpart.XXXXXX" 2>/dev/null)" || _T2=""
    if [ -z "$_T2" ]; then
        _T2="${TMPDIR:-/tmp}/altpart.$$.b"
        : > "$_T2"
    fi
}
cleanup_exit() {
    if [ -n "$_T1" ]; then rm -f "$_T1" 2>/dev/null || true; fi
    if [ -n "$_T2" ]; then rm -f "$_T2" 2>/dev/null || true; fi
    printf '\n'
    if [ -n "$C_MISC" ]; then
        printf '%b\n' "${C_MISC}Alpine-Partitionierer beendet.${C_R}"
    fi
}

mk_tempfiles
trap cleanup_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

parse_args "$@"
# Root-Rechte sind Pflicht: das Skript startet IMMER als root - dafuer wird es
# beim Start DIREKT per sudo/su neu gestartet (sudo fragt selbst nach dem
# Passwort), bevor irgendetwas anderes laeuft. Kein Menue-Neustart noetig,
# denn das Menue geht bereits als root auf.
require_root || exit 1
part_menu
LLT_EMBED_PART
}

# ---------------- Hauptverarbeitung ----------------

CMD=
DIR=
while [ $# -gt 0 ]; do
    case "$1" in
    -h|--help) usage; exit 0 ;;
    -V|--version) printf '%s\n' "$PROG $VERSION"; exit 0 ;;
    -x|-e|--extract)
        [ $# -ge 2 ] || td err_extract_needs_dir
        DIR=$2
        shift 2
        ;;
    iso|live|mkalpe|install|inst|alpe-install|part|partition|alpe-part|menu)
        CMD=$1
        shift
        break
        ;;
    *)
        te err_unknown_arg "$1"
        usage
        exit 1
        ;;
    esac
done

if [ -n "$DIR" ]; then
    [ -z "$CMD" ] || td err_dir_and_cmd
    [ $# -eq 0 ] || td err_unknown_arg "$1"
    extract_scripts "$DIR"
    exit 0
fi

case "$CMD" in
iso|live|mkalpe)           run_embedded mkalpe "$@" ;;
install|inst|alpe-install) run_embedded install "$@" ;;
part|partition|alpe-part)  run_embedded part "$@" ;;
menu|"")                   main_menu ;;
esac
#@@@END:alpine/alpinelive-tool@@@
