# LinuxLiveTool (LLT)

![LinuxLiveTool Banner](banner/banner.png)

**Deutsch** | [English](#english)

---

## Deutsch

### Was ist LinuxLiveTool?

`linuxlivetool.sh` ist **ein einziges, in sich geschlossenes shell-Skript**. Es enthält die
vier LinuxLiveTools für **Ubuntu, Debian, Arch und Alpine** — und mit **clonie** ist jetzt
ein **fünftes Tool Teil der Sammlung**: Festplatten/Partitionen **klonen, imagen, recovern**.

Die vier Live-Tools können jeweils:

- eine **Live-ISO vom laufenden System** erstellen (BIOS **und** UEFI bootfähig, remastert — das eigene System als bootbares Abbild),
- das **Live-System auf Festplatte/Partition installieren** (inkl. Bootloader),
- **Festplatten/Partitionen partitionieren und formatieren** (interaktiver Partitionierer),
- Bau-Artefakte **aufräumen** und mögliche **Installationsziele anzeigen**.

**clonie** (ebenfalls als Datenblock eingebettet) ergänzt die Sammlung um:

- Festplatten/Partitionen **1:1 klonen** (Disk-zu-Disk),
- **Images erstellen** (zstd multithreaded, xz/gzip-Fallback) und inkl.
  **SHA-256-Prüfung** zurückspielen — einzelne Partitionen aus
  Multi-Partitions-Images sind restorbar,
- optional **verschlüsselte Images** (AES-256) und Partitionstabellen
  sichern/zurückspielen (Details im Abschnitt
  [clonie — klonen, imagen, recovern](#clonie--klonen-imagen-recovern)).

Das Skript muss nicht installiert werden: herunterladen, ausführbar machen, starten.
Alle **fünf** Tools stecken als Datenblock im Skript selbst und werden bei Bedarf
entpackt und ausgeführt.

### Schnellstart

```shell
chmod +x linuxlivetool.sh
./linuxlivetool.sh              # interaktives Menü
```

### Das Hauptmenü

```
  1) Alpine
  2) Arch
  3) Debian
  4) Ubuntu
  5) Clonie
  00) Beenden
```

Jede Distribution enthält genau ein Live-Tool; **clonie** startet als
eigenständiges Tool. Die Auswahl startet das gewählte Tool **direkt**.
Im Tool-Menü gilt überall:

- **0** = genau ein Menü zurück
- **00** = das **gesamte Skript sofort beenden** (aus jedem Untermenü heraus)

### Funktionsumfang der vier Live-Tools

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
- **Eigene Tools einpflegen:** mit `-x` entpacken, ändern, mit `-r` wieder
  einbetten — Details im Abschnitt [Tools aktualisieren](#tools-aktualisieren--der--r-workflow).

### clonie — klonen, imagen, recovern

**clonie** ist mit dieser Version **Teil der Tool-Sammlung**. Es ist **kein
Live-Tool** (baut keine ISO, installiert kein System), sondern ein eigenständiges
Werkzeug für Festplatten und Partitionen:

- **1:1 klonen** (Disk-zu-Disk) — inkl. Ziel-Anpassung nach dem Klonen auf eine
  größere Platte
- **Images erstellen** — zstd multithreaded (Fallback xz/gzip), automatisch
  benannt als `<Platte>_<Zeit>`; der Image-Host-Ordner wird am Beginn gewählt
- **Images zurückspielen** inkl. **SHA-256-Prüfung**; **Multi-Restore** — alle
  Ziele in einer Eingabe (z. B. `1,3` oder `1-4`), zugeordnet in der Reihenfolge
  der Quellpartitionen
- **Mehrere Partitionen** in **einem** Image sichern (tar) und einzeln daraus
  zurückspielen
- **Partitionstabelle sichern/zurückspielen** (sfdisk)
- **Optional verschlüsselte Images** (AES-256 via openssl/PBKDF2, Endung
  `.enc`) — das Passwort wird per Passcheck-Datei verifiziert, **bevor** das
  Ziel überschrieben wird
- Eigene Einhängungen (Image-Host-Ordner) werden beim Beenden ausgehängt
- Menü-Steuerung wie überall: **0** = zurück, **00** = beenden,
  **000** = abbrechen

### Befehlszeile (CLI)

```shell
./linuxlivetool.sh                       # interaktives Menü (Standard: Deutsch)

./linuxlivetool.sh -x  <verzeichnis>     # alle 5 Tools flach entpacken (4 Live-Tools + clonie)
./linuxlivetool.sh -xx <verzeichnis>     # die 12 Einzelskripte der 4 Live-Tools + clonie entpacken
./linuxlivetool.sh -xx arch <verzeichnis># nur die Einzelskripte eines Tools
                                        #   (arch | alpine | ubuntu | debian | clonie | all)
                                        #   (clonie: eine Datei, keine Export-Aufteilung)
./linuxlivetool.sh -r  <verzeichnis>     # veraenderte Tools aus -x/-xx wieder einbetten
                                        #   (VERSION wird um 0.1 erhöht, Backup .bak)
./linuxlivetool.sh -v                    # Version + Versionen aller enthaltenen Tools
./linuxlivetool.sh -de | -en             # Sprache erzwingen (Standard: DE)
./linuxlivetool.sh -nc                   # ohne Farben (Fallback für ältere Konsolen;
                                        #   Farben sind bei nicht-Terminal automatisch aus)
./linuxlivetool.sh -h                    # Hilfe
```

Was `-x`, `-xx` und `-r` im Detail machen: eigene Abschnitte direkt unterhalb.

Verzeichnisse werden bei Bedarf automatisch angelegt. Bei `-r` bleiben unveränderte
Tools unberührt; nur tatsächlich geänderte werden ersetzt.

Jedes Live-Tool ist auch **einzeln lauffähig** und bietet dieselbe Extraktion:

```shell
./ubuntulive-tool  -x <verz>   # oder: export -s 1,2,3 -o <verz>
./debianlive-tool  -x <verz>
./archlive-tool    -x <verz>
./alpinelive-tool  -x <verz>   # schreibt mkalpe-live.sh, alpe-install.sh, alpe-part
```

**clonie** läuft ebenfalls einzeln (`./clonie`), hat als eigenständiges
Einzelskript aber keine Export-Funktion.

### Tools extrahieren — `-x`

Holt die **fünf eingebetteten Tools** aus dem Bündel heraus — **flach** in ein
Zielverzeichnis (wird bei Bedarf automatisch angelegt), **byte-identisch** und
ausführbar:

```shell
./linuxlivetool.sh -x ~/tools
```

Ergebnis:

```text
~/tools/ubuntulive-tool
~/tools/debianlive-tool
~/tools/archlive-tool
~/tools/alpinelive-tool
~/tools/clonie
```

Wofür: die Tools einzeln starten und ausprobieren, an andere weitergeben —
oder als Grundlage für eigene Anpassungen (→ zurück ins Bündel mit `-r`,
siehe unten).

### Einzelskripte exportieren — `-xx`

Jedes Tool enthält seine **drei Bausteine** (Installation / ISO / Partitionierer)
selbst. Mit `-xx` werden sie über die eingebaute Export-Funktion als
**eigenständige, separat lauffähige Skripte** geschrieben:

```shell
./linuxlivetool.sh -xx ~/skripte        # alle 4 Live-Tools + clonie (13 Dateien)
./linuxlivetool.sh -xx arch ~/skripte   # nur arch
                                       #   (arch | alpine | ubuntu | debian | clonie | all)
```

Ergebnis für arch:

```text
~/skripte/archlive-tool-install.sh
~/skripte/archlive-tool-iso.sh
~/skripte/archlive-tool-part.sh
```

`-xx clonie ~/skripte` schreibt nur die **eine Datei** `clonie` — das Tool hat
keine Export-Aufteilung in Bausteine.

Wofür: an den einzelnen Bausteinen arbeiten, ohne das große Tool im Blick zu
haben. **Wichtig:** Diese Einzelskripte laufen unabhängig, werden aber **nicht**
über `-r` zurück ins Bündel gebracht — das gilt nur für die Tool-Dateien aus
`-x`.

### Tools aktualisieren — der `-r`-Workflow

Alle fünf Tools sind **eingebettet** — zum Ändern musst du `linuxlivetool.sh`
nie direkt anfassen. Der sichere Weg:

```shell
./linuxlivetool.sh -x  ~/tools     # 1. alle 5 Tools entpacken (flach)

#  2. Tool(s) in ~/tools bearbeiten und VORHER einzeln testen,
#     z. B.:  ./ubuntulive-tool part

./linuxlivetool.sh -r  ~/tools     # 3. Änderungen wieder einbetten
```

**Was `-r` genau macht:**

- vergleicht jedes entpackte Tool mit der eingebetteten Version und bettet
  **nur tatsächlich geänderte** Tools wieder ein — alles Unveränderte bleibt an
  seiner Stelle
- legt **vorher automatisch eine Sicherung** an (`linuxlivetool.sh.bak`) —
  du kannst also jederzeit einen Schritt zurück
- erhöht die **VERSION um 0.1** (mit Überlauf: 1.9 → 2.0), damit du am
  Versionsstand siehst, welchen Stand du gerade hast — `-v` zeigt die
  Versionen aller Tools live an
- meldet *„Keine veränderten Skripte - nichts zu tun"*, wenn du nichts
  geändert hast — dann passiert auch nichts

**Wichtig zu wissen:**

- `-r` erwartet die **Tool-Dateien** aus `-x` (also z. B. `ubuntulive-tool`
  selbst). Die mit `-xx` exportierten Einzelskripte (install/iso/part) sind
  eigenständige Dateien und werden **nicht** wieder eingebettet.
- Das Backup `.bak` wird bei **jedem** Re-Embed neu überschrieben — es gilt
  immer nur für den letzten Lauf. Willst du länger zurück, sichere die Datei
  zusätzlich von Hand.

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

Jedes der vier Live-Tools — `ubuntulive-tool`, `debianlive-tool`,
`archlive-tool` und `alpinelive-tool` — ist selbst wieder ein **Bündel von
Skripten für seine Distribution**: Es besteht aus jeweils **drei Skripten** mit
den Funktionen **ISO bauen**, **installieren** und **partitionieren** (beim
Alpine-Tool: `mkalpe-live.sh`, `alpe-install.sh`, `alpe-part`). Die drei
Einzelskripte lassen sich mit `-xx` exportieren und laufen dann eigenständig.

**clonie** ist die Ausnahme: ein einzelnes, fertiges Skript ohne Unter-Skripte
— mit `-x` wird es 1:1 als eine Datei entpackt.

Die fünf Tools liegen zwischen Marker-Zeilen im Skript
(`#@@@SCRIPT:<distro>/<datei>@@@` … `#@@@END:…@@@`), nach `exit 0` als reiner
Datenblock — sie werden nie von der Shell des Wrappers geparst. Mit `-x`/`-xx`
lassen sie sich exakt 1:1 wiederherstellen.

### Lizenz

**GPL-3.0-or-later** — veröffentlicht unter der GNU General Public License
Version 3 (oder später); siehe die Datei [`LICENSE`](LICENSE). Der vollständige
Lizenz-Hinweis steht im Kopf des Skripts.

### Hinweis

Nutzung auf eigene Verantwortung — das Partitionierer- und
Installations-Tool ebenso wie **clonie** schreiben auf Festplatten!

---

<a name="english"></a>
## English

### What is LinuxLiveTool?

`linuxlivetool.sh` is **a single, self-contained shell script**. It contains the
four LinuxLiveTools for **Ubuntu, Debian, Arch and Alpine** — and with
**clonie**, a **fifth tool is now part of the collection**: clone, image and
recover disks/partitions.

The four live tools can each:

- create a **live ISO from the running system** (bootable on BIOS **and** UEFI,
  remastered — your own system as a bootable image),
- **install the live system to a disk or partition** (including bootloader),
- **partition and format disks/partitions** (interactive partitioner),
- **clean up** build artifacts and **show possible installation targets**.

**clonie** (also embedded as a data block) adds to the collection:

- **1:1 cloning** of disks/partitions (disk-to-disk),
- **image creation** (zstd multithreaded, xz/gzip fallback) and restore with a
  **SHA-256 check** — single partitions can be restored from multi-partition
  images,
- optional **encrypted images** (AES-256) plus saving/restoring partition
  tables (details in [clonie — clone, image and recover](#clonie--clone-image-and-recover)).

No installation required: download, make executable, run. All **five** tools are
embedded inside the script itself as a data block and are extracted and executed
on demand.

### Quick start

```shell
chmod +x linuxlivetool.sh
./linuxlivetool.sh              # interactive menu
```

### The main menu

```
  1) Alpine
  2) Arch
  3) Debian
  4) Ubuntu
  5) Clonie
  00) Quit
```

Each distribution contains exactly one live tool; **clonie** starts as a
standalone tool. Selecting an entry starts that tool **directly**. Inside the
tool menus, everywhere:

- **0** = go back exactly one menu
- **00** = **immediately terminate the whole script** (from any submenu)

### Feature set of the four live tools

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
- **Update your own tools:** extract with `-x`, modify, re-embed with `-r` —
  details in [Updating tools](#updating-tools--the--r-workflow).

### clonie — clone, image and recover

**clonie** is **part of the tool collection** as of this version. It is **not a
live tool** (it builds no ISO and installs no system) but a standalone utility
for disks and partitions:

- **1:1 cloning** (disk-to-disk) — including target adjustment after cloning to
  a larger disk
- **image creation** — zstd multithreaded (fallback xz/gzip), automatically
  named `<disk>_<time>`; the image host directory is chosen at the start
- **image restore** with a **SHA-256 check**; **multi-restore** — all targets
  in one entry (e.g. `1,3` or `1-4`), assigned in the order of the source
  partitions
- back up **several partitions** into **one** image (tar) and restore them
  individually
- **save/restore the partition table** (sfdisk)
- **optional encrypted images** (AES-256 via openssl/PBKDF2, suffix `.enc`) —
  the password is verified via a passcheck file **before** the target is
  overwritten
- own mounts (image host directory) are unmounted at exit
- menu control like everywhere: **0** = back, **00** = quit, **000** = abort

### Command line (CLI)

```shell
./linuxlivetool.sh                       # interactive menu (default: German)

./linuxlivetool.sh -x  <directory>       # extract all 5 tools, flat (4 live tools + clonie)
./linuxlivetool.sh -xx <directory>       # extract the 12 standalone scripts of the 4 live tools + clonie
./linuxlivetool.sh -xx arch <directory>  # only the standalone scripts of one tool
                                        #   (arch | alpine | ubuntu | debian | clonie | all)
                                        #   (clonie: one file, no export split)
./linuxlivetool.sh -r  <directory>       # re-embed modified tools from -x/-xx
                                        #   (VERSION is bumped by 0.1, backup .bak)
./linuxlivetool.sh -v                    # version + versions of all embedded tools
./linuxlivetool.sh -de | -en             # force language (default: German)
./linuxlivetool.sh -nc                   # no colors (fallback for older terminals;
                                        #   colors are also off when not a terminal)
./linuxlivetool.sh -h                    # help
```

What `-x`, `-xx` and `-r` do in detail: dedicated sections right below.

Directories are created automatically if missing. With `-r`, unchanged tools are
left untouched; only actually changed ones are replaced.

Every live tool also runs **standalone** and offers the same extraction:

```shell
./ubuntulive-tool  -x <dir>   # or: export -s 1,2,3 -o <dir>
./debianlive-tool  -x <dir>
./archlive-tool    -x <dir>
./alpinelive-tool  -x <dir>   # writes mkalpe-live.sh, alpe-install.sh, alpe-part
```

**clonie** also runs standalone (`./clonie`) but, being a single standalone
script, has no export function.

### Extracting tools — `-x`

Pulls the **five embedded tools** out of the bundle — **flat** into a target
directory (created automatically if missing), **byte-identical** and
executable:

```shell
./linuxlivetool.sh -x ~/tools
```

Result:

```text
~/tools/ubuntulive-tool
~/tools/debianlive-tool
~/tools/archlive-tool
~/tools/alpinelive-tool
~/tools/clonie
```

Use cases: run and try the tools standalone, share them — or use them as a
starting point for your own modifications (→ back into the bundle with `-r`,
see below).

### Exporting standalone scripts — `-xx`

Each tool contains its **three building blocks** (installation / ISO /
partitioner) internally. With `-xx` they are written out via the built-in
export function as **independent, separately runnable scripts**:

```shell
./linuxlivetool.sh -xx ~/scripts        # all 4 live tools + clonie (13 files)
./linuxlivetool.sh -xx arch ~/scripts   # arch only
                                       #   (arch | alpine | ubuntu | debian | clonie | all)
```

Result for arch:

```text
~/scripts/archlive-tool-install.sh
~/scripts/archlive-tool-iso.sh
~/scripts/archlive-tool-part.sh
```

`-xx clonie ~/scripts` writes just the **single file** `clonie` — the tool has
no export split into building blocks.

Use case: work on individual building blocks without the big tool in the way.
**Important:** These standalone scripts run on their own but are **not** put
back into the bundle via `-r` — that only applies to the tool files from `-x`.

### Updating tools — the `-r` workflow

All five tools are **embedded** — you never have to touch `linuxlivetool.sh`
directly to change them. The safe path:

```shell
./linuxlivetool.sh -x  ~/tools     # 1. extract all 5 tools (flat)

#  2. edit the tool(s) in ~/tools and test them standalone FIRST,
#     e.g.:  ./ubuntulive-tool part

./linuxlivetool.sh -r  ~/tools     # 3. re-embed your changes
```

**What `-r` does exactly:**

- compares each extracted tool against the embedded version and re-embeds
  **only the tools that actually changed** — everything untouched stays as is
- **creates a backup automatically first** (`linuxlivetool.sh.bak`) — you can
  always go back one step
- bumps the **VERSION by 0.1** (with rollover: 1.9 → 2.0) so the version
  tells you which state you are on — `-v` shows all tool versions live
- reports *"No changed scripts found - nothing to do"* when you changed
  nothing — and then does nothing

**Good to know:**

- `-r` expects the **tool files** from `-x` (e.g. `ubuntulive-tool` itself).
  The standalone scripts exported with `-xx` (install/iso/part) are separate
  files and are **not** re-embedded.
- The `.bak` backup is **overwritten on every** re-embed — it only covers the
  last run. To go back further, keep an extra copy by hand.

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

Each of the four live tools — `ubuntulive-tool`, `debianlive-tool`,
`archlive-tool` and `alpinelive-tool` — is itself again a **bundle of scripts
for its distribution**: it consists of **three scripts** with the functions
**build ISO**, **install** and **partition** (for the Alpine tool:
`mkalpe-live.sh`, `alpe-install.sh`, `alpe-part`). These three standalone
scripts can be exported with `-xx` and then run independently.

**clonie** is the exception: a single, finished script without sub-scripts —
`-x` extracts it 1:1 as one file.

The five tools sit between marker lines inside the script
(`#@@@SCRIPT:<distro>/<file>@@@` … `#@@@END:…@@@`), after `exit 0` as a pure data
block — the wrapper shell never parses them. `-x`/`-xx` restore them exactly 1:1.

### License

**GPL-3.0-or-later** — released under the GNU General Public License version 3
(or later); see the [`LICENSE`](LICENSE) file. The full license notice is at
the top of the script.

### Note

Use at your own risk — the partitioner and installer tools as well as
**clonie** write to disks!
