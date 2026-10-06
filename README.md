# LinuxLiveTool (LLT)

**Deutsch** | [English](#english)

---

## Deutsch

### Was ist LinuxLiveTool?

`live-toolbox.sh` ist **ein einziges, in sich geschlossenes shell-Skript**, das die vier
LinuxLiveTools für **Ubuntu, Debian, Arch und Alpine** enthält. Jedes Tool kann:

- eine **Live-ISO vom laufenden System** erstellen (BIOS **und** UEFI bootfähig, remastert — das eigene System als bootbares Abbild),
- das **Live-System auf Festplatte/Partition installieren** (inkl. Bootloader),
- **Festplatten/Partitionen partitionieren und formatieren** (interaktiver Partitionierer),
- Bau-Artefakte **aufräumen** und mögliche **Installationsziele anzeigen**.

Das Skript muss nicht installiert werden: herunterladen, ausführbar machen, starten.
Alle vier Tools stecken als Datenblock im Skript selbst und werden bei Bedarf
entpackt und ausgeführt.

### Schnellstart

```shell
chmod +x live-toolbox.sh
./live-toolbox.sh              # interaktives Menü
```

### Das Hauptmenü

```
  1) Alpine
  2) Arch
  3) Debian
  4) Ubuntu
  0)  Beenden
  00) Beenden
```

Jede Distribution enthält genau ein Tool; die Auswahl startet es **direkt**.
Im Tool-Menü gilt überall:

- **0** = genau ein Menü zurück
- **00** = das **gesamte Skript sofort beenden** (aus jedem Untermenü heraus)

### Funktionsumfang der vier Tools

| Funktion | ubuntulive-tool | debianlive-tool | archlive-tool | alpinelive-tool |
|---|---|---|---|---|
| Live-ISO vom laufenden System (BIOS + UEFI) | ✓ | ✓ | ✓ | ✓ (mkalpe-live) |
| Live-System auf Festplatte/Partition installieren | ✓ | ✓ | ✓ | ✓ (alpe-install, offline) |
| Partitionierer (GPT/MBR, anlegen/löschen/formatieren, Flags ESP/BIOS-Boot) | ✓ | ✓ | ✓ | ✓ (alpe-part) |
| Aufräumen der ISO-Bau-Artefakte | ✓ | ✓ | ✓ | ✓ |
| Mögliche Installationsziele anzeigen | ✓ | ✓ | ✓ | ✓ |
| Einzelskripte exportieren (Partitionierer/ISO/Installation) | ✓ | ✓ | ✓ | ✓ |
| SquashFS-Kompression wählbar (xz/zstd/lzma/gzip/lzo/lz4) | ✓ | ✓ | ✓ | ✓ |

Besonderheiten:

- **alpinelive-tool** erzeugt die ISO aus dem installierten System (apkovl + modloop)
  und enthält einen **offline-fähigen Installer** — die gebootete ISO kann ohne Netz
  installieren. Der Partitionierer **startet immer mit Root-Rechten**.
- **ubuntu/debian/archlive-tool** fragen Root-Rechte an, sobald eine Aktion sie
  benötigt, und führen **direkt die gewählte Aktion** als root aus — keine erneute
  Menüauswahl nach dem Root-Wechsel.
- **Warnungen und Fehler** erscheinen überall in HELLROT, Überschriften in
  Hellcyan, Menüs in Hellgelb (Farbschema `DESIGN.md`).

### Befehlszeile (CLI)

```shell
./live-toolbox.sh                       # interaktives Menü (Standard: Deutsch)

./live-toolbox.sh -x  <verzeichnis>     # alle 4 Tools flach entpacken
./live-toolbox.sh -xx <verzeichnis>     # die 12 Einzelskripte aller 4 Distributionen entpacken
./live-toolbox.sh -xx arch <verzeichnis># nur die 3 Einzelskripte einer Distribution
                                        #   (arch | alpine | ubuntu | debian | all)
./live-toolbox.sh -r  <verzeichnis>     # veraenderte Tools aus -x/-xx wieder einbetten
                                        #   (VERSION wird um 0.1 erhöht, Backup .bak)
./live-toolbox.sh -v                    # Version + Versionen aller enthaltenen Tools
./live-toolbox.sh -de | -en             # Sprache erzwingen (Standard: DE)
./live-toolbox.sh -nc                   # ohne Farben (Fallback für ältere Konsolen;
                                        #   Farben sind bei nicht-Terminal automatisch aus)
./live-toolbox.sh -h                    # Hilfe
```

Verzeichnisse werden bei Bedarf automatisch angelegt. Bei `-r` bleiben unveränderte
Tools unberührt; nur tatsächlich geänderte werden ersetzt.

Jedes Tool ist auch **einzeln lauffähig** und bietet dieselbe Extraktion:

```shell
./ubuntulive-tool  -x <verz>   # oder: export -s 1,2,3 -o <verz>
./debianlive-tool  -x <verz>
./archlive-tool    -x <verz>
./alpinelive-tool  -x <verz>   # schreibt mkalpe-live.sh, alpe-install.sh, alpe-part
```

### Sprache

Standard ist **Deutsch**. Mit `-de` oder `-en` lässt sich die Sprache erzwingen;
ganz am Anfang jedes Skripts kann die Sprache auch fest eingestellt werden
(`SPRACHE=DE` bzw. `SPRACHE=EN`). Ist eine Sprache gewählt, erscheinen **ausschließlich**
Ausgaben dieser Sprache — keine Mischsprachen.

### Kein Autologin — bewusste Entscheidung

Eine **automatische Anmeldung (Autologin)** wurde **absichtlich nicht
implementiert** — aus Sicherheitsbedenken: Ein Live-System, das sich ohne
Passwortabfrage automatisch als Root/Benutzer anmeldet, bietet jedem, der
physischen Zugriff auf den Rechner erhält, sofort vollen Zugriff (inkl.
Festplattenzugriff, Netzwerkkonfiguration, Installer). Stattdessen gilt:

- Das Live-System fragt nach Anmeldedaten bzw. erwartet eine bewusste Anmeldung.
- Die Tools fordern Root-Rechte nur dann an, wenn eine Aktion sie wirklich
  benötigt (per `sudo` bzw. `su`, mit Passwortabfrage).

Wer Autologin dennoch möchte, muss es nach dem Booten selbst und bewusst
einrichten — das Skript liefert es nicht mit.

### Voraussetzungen

- Linux, `shell` bzw. POSIX-`sh` (busybox-ash reicht für das Alpine-Tool)
- Root-Rechte für schreibende Aktionen (werden per `sudo` — Fallback `su` — angefordert)
- Für den ISO-Bau: die jeweiligen Pakete (z. B. `xorriso`, `squashfs-tools`,
  `syslinux`, `grub-bios`, `grub-efi`, `mtools`); das Alpine-Tool erkennt fehlende
  Pakete und bietet die Installation per `apk` an

### Aufbau

Die vier Tools liegen zwischen Marker-Zeilen im Skript
(`#@@@SCRIPT:<distro>/<datei>@@@` … `#@@@END:…@@@`), nach `exit 0` als reiner
Datenblock — sie werden nie von der Shell des Wrappers geparst. Mit `-x`/`-xx`
lassen sie sich exakt 1:1 wiederherstellen.

### Lizenz

**GPL-3.0-or-later** — veröffentlicht unter der GNU General Public License
Version 3 (oder später); siehe die Datei [`LICENSE`](LICENSE). Der vollständige
Lizenz-Hinweis steht im Kopf des Skripts.

### Hinweis

Nutzung auf eigene Verantwortung — das Partitionierer- und
Installations-Tool schreiben auf Festplatten!

---

<a name="english"></a>
## English

### What is LinuxLiveTool?

`live-toolbox.sh` is **a single, self-contained shell script** containing the four
LinuxLiveTools for **Ubuntu, Debian, Arch and Alpine**. Each tool can:

- create a **live ISO from the running system** (bootable on BIOS **and** UEFI,
  remastered — your own system as a bootable image),
- **install the live system to a disk or partition** (including bootloader),
- **partition and format disks/partitions** (interactive partitioner),
- **clean up** build artifacts and **show possible installation targets**.

No installation required: download, make executable, run. All four tools are
embedded inside the script itself as a data block and are extracted and executed
on demand.

### Quick start

```shell
chmod +x live-toolbox.sh
./live-toolbox.sh              # interactive menu
```

### The main menu

```
  1) Alpine
  2) Arch
  3) Debian
  4) Ubuntu
  0)  Quit
  00) Quit
```

Each distribution contains exactly one tool; selecting it starts that tool
**directly**. Inside the tool menus, everywhere:

- **0** = go back exactly one menu
- **00** = **immediately terminate the whole script** (from any submenu)

### Feature set of the four tools

| Feature | ubuntulive-tool | debianlive-tool | archlive-tool | alpinelive-tool |
|---|---|---|---|---|
| Live ISO from the running system (BIOS + UEFI) | ✓ | ✓ | ✓ | ✓ (mkalpe-live) |
| Install the live system to disk/partition | ✓ | ✓ | ✓ | ✓ (alpe-install, offline) |
| Partitioner (GPT/MBR, create/delete/format, ESP/BIOS-boot flags) | ✓ | ✓ | ✓ | ✓ (alpe-part) |
| Clean up ISO build artifacts | ✓ | ✓ | ✓ | ✓ |
| Show possible installation targets | ✓ | ✓ | ✓ | ✓ |
| Export standalone scripts (partitioner/ISO/installation) | ✓ | ✓ | ✓ | ✓ |
| Selectable SquashFS compression (xz/zstd/lzma/gzip/lzo/lz4) | ✓ | ✓ | ✓ | ✓ |

Details:

- **alpinelive-tool** builds the ISO from the installed system (apkovl + modloop)
  and includes an **offline installer** — the booted ISO can install without a
  network. The partitioner **always starts with root privileges**.
- **ubuntu/debian/archlive-tool** request root privileges as soon as an action
  needs them and then **execute the selected action directly as root** — no
  repeated menu selection after the root switch.
- **Warnings and errors** are always shown in BRIGHT RED, headers in bright cyan,
  menus in bright yellow (color scheme `DESIGN.md`).

### Command line (CLI)

```shell
./live-toolbox.sh                       # interactive menu (default: German)

./live-toolbox.sh -x  <directory>       # extract all 4 tools, flat
./live-toolbox.sh -xx <directory>       # extract the 12 standalone scripts of all 4 distros
./live-toolbox.sh -xx arch <directory>  # only the 3 standalone scripts of one distro
                                        #   (arch | alpine | ubuntu | debian | all)
./live-toolbox.sh -r  <directory>       # re-embed modified tools from -x/-xx
                                        #   (VERSION is bumped by 0.1, backup .bak)
./live-toolbox.sh -v                    # version + versions of all embedded tools
./live-toolbox.sh -de | -en             # force language (default: German)
./live-toolbox.sh -nc                   # no colors (fallback for older terminals;
                                        #   colors are also off when not a terminal)
./live-toolbox.sh -h                    # help
```

Directories are created automatically if missing. With `-r`, unchanged tools are
left untouched; only actually changed ones are replaced.

Every tool also runs **standalone** and offers the same extraction:

```shell
./ubuntulive-tool  -x <dir>   # or: export -s 1,2,3 -o <dir>
./debianlive-tool  -x <dir>
./archlive-tool    -x <dir>
./alpinelive-tool  -x <dir>   # writes mkalpe-live.sh, alpe-install.sh, alpe-part
```

### Language

The default language is **German**. Use `-de` or `-en` to force a language; you
can also set it permanently at the top of each script (`SPRACHE=DE` or
`SPRACHE=EN`). Once a language is chosen, output appears in **that language
only** — no mixed languages.

### No autologin — deliberate decision

**Automatic login (autologin)** was **deliberately not implemented** for
security reasons: a live system that logs in automatically as root/user without
any password prompt gives anyone with physical access to the machine immediate
full access (including disks, network configuration and the installer).
Instead:

- The live system asks for credentials or expects a conscious login.
- The tools request root privileges only when an action actually needs them
  (via `sudo` or `su`, with a password prompt).

If you want autologin anyway, you must set it up yourself after booting —
the script does not ship it.

### Requirements

- Linux, `shell` or POSIX-`sh` (busybox-ash is sufficient for the Alpine tool)
- Root privileges for write actions (requested via `sudo` — fallback `su`)
- For building ISOs: the respective packages (e.g. `xorriso`, `squashfs-tools`,
  `syslinux`, `grub-bios`, `grub-efi`, `mtools`); the Alpine tool detects missing
  packages and offers installation via `apk`

### Structure

The four tools sit between marker lines inside the script
(`#@@@SCRIPT:<distro>/<file>@@@` … `#@@@END:…@@@`), after `exit 0` as a pure data
block — the wrapper shell never parses them. `-x`/`-xx` restore them exactly 1:1.

### License

**GPL-3.0-or-later** — released under the GNU General Public License version 3
(or later); see the [`LICENSE`](LICENSE) file. The full license notice is at
the top of the script.

### Note

Use at your own risk — the partitioner and installer tools write to disks!
