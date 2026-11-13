# webuntis-skill

Ein [Claude-Code](https://claude.com/claude-code)-Skill für WebUntis aus Sicht
der Erziehungsberechtigten: Stundenplan der Kinder, Tagesnachrichten,
Hausaufgaben, Abwesenheiten und das Mitteilungs-Center (lesen und an
Lehrkräfte schreiben).

Er läuft headless über die REST-API von WebUntis, ohne Browser. Das Passwort
liegt im macOS-Schlüsselbund, nicht in einer Datei.

## Voraussetzungen

- macOS (Schlüsselbund über `security`)
- Python ≥ 3.11, keine weiteren Pakete
- ein Eltern-Account bei WebUntis

## Installation

```sh
git clone https://github.com/mranner/webuntis-skill.git
sh webuntis-skill/install.sh /pfad/zum/projekt
```

`install.sh` verlinkt den Skill nach `<projekt>/.claude/skills/webuntis`. Für
alle Projekte stattdessen nach `~/.claude/skills/webuntis` verlinken.

Einmalig in einer interaktiven Shell einrichten:

```sh
python3 webuntis-skill/webuntis setup
```

`setup` fragt Server, Schulkürzel und Benutzername ab, legt das Passwort im
Schlüsselbund an und prüft den Login.

## Verwendung

In Claude Code genügt eine Frage wie „Was hat Anna morgen?“ oder `/webuntis`.
Direkt aufgerufen:

```sh
python3 webuntis timetable --student Anna --days 5
python3 webuntis news --date heute
python3 webuntis messages list --folder inbox
```

Alle Befehle und Optionen stehen in der [SKILL.md](SKILL.md).

## Hinweis

Welche Bereiche funktionieren, legt jede Schule selbst fest. Antwortet ein
Endpunkt mit 403 oder 500, ist er dort für Eltern gesperrt oder nicht aktiv.
Das ist kein Fehler im Skill.
