---
name: webuntis
description: >
  WebUntis für Erziehungsberechtigte: Stundenplan der Kinder, Tagesnachrichten
  der Schule, Hausaufgaben, Abwesenheiten, Sprechstunden der Lehrkräfte und
  das Mitteilungs-Center (Posteingang lesen, an Lehrkräfte schreiben). Läuft
  headless über die REST-API, Passwort aus dem macOS-Schlüsselbund - kein
  Browser nötig. Auch bei "was hat mein Kind morgen", "Stundenplan diese
  Woche", "gibt es neue Nachrichten in WebUntis", "schreib der Lehrerin",
  "fällt eine Stunde aus", "wann hat die Lehrerin Sprechstunde".
  Trigger: /webuntis.
---

# webuntis -- WebUntis-Zugriff für Eltern

Alle Aufrufe gehen über das gebundelte Script `webuntis` (Python >= 3.11,
stdlib only, keine Abhängigkeiten).

**Aufruf:** `python3 "$SKILL_DIR/webuntis" <befehl> [optionen]`

`$SKILL_DIR` ist das Verzeichnis dieser SKILL.md.

## Installation

Der Skill ist **projektlokal** gedacht, nicht global: er ist nur in den
Projekten sichtbar, in die er verlinkt wird, nicht in jeder Claude-Code-Sitzung.

```
git clone https://github.com/mranner/webuntis-skill.git
sh webuntis-skill/install.sh /pfad/zum/projekt [/pfad/zum/projekt2 ...]
```

Verlinkt das Repo nach `<projekt>/.claude/skills/webuntis`. Wer ihn global
will, verlinkt das Verzeichnis stattdessen nach `~/.claude/skills/webuntis`.

## Konfiguration

`webuntis.json` im Skill-Verzeichnis (nicht im Git, Modus 600):

```json
{
  "server": "schule.webuntis.com",
  "school": "schule",
  "username": "vorname.nachname@example.at"
}
```

Das **Passwort steht nie in der Konfiguration**, sondern im macOS-Schlüssel-
bund unter Service `webuntis`, Account = Benutzername. Fehlt der Eintrag,
fragt `setup` (und jeder andere Befehl in einer interaktiven Shell) einmal
danach und legt ihn an.

Wichtig: Der iCloud-Schlüsselbund der Passwörter-App ist für `security`
nicht erreichbar. Der Eintrag muss im lokalen `login.keychain-db` liegen --
genau das macht `setup`.

## Ersteinrichtung

```
python3 "$SKILL_DIR/webuntis" setup
```

Fragt Server, Schulkürzel und Benutzername ab, legt das Passwort im
Schlüsselbund an und prüft den Login. Muss **in einer interaktiven Shell**
laufen (in Claude Code: `! python3 .../webuntis setup`), weil `security` das
Passwort auf dem Terminal abfragt.

## Befehle

| Befehl | Zweck |
|--------|-------|
| `setup` | Konfiguration und Schlüsselbund einrichten, Login prüfen |
| `whoami` | Schule, Benutzer und zugeordnete Kinder anzeigen |
| `students` | Nur die Kinder mit ihren ids |
| `classes` | Alle Klassen der Schule mit id |
| `timetable` | Stundenplan (`--student`, `--class`, `--date`, `--days`) |
| `news` | Tagesnachrichten der Schule (`--date`) |
| `homework` | Hausaufgaben (`--student`, `--date`, `--days`); ohne `--student` alle Kinder, jede Zeile mit Kind |
| `absences` | Abwesenheiten (`--student`, `--date`, `--days`); ohne `--student` alle Kinder, jede Zeile mit Kind |
| `officehours` | Sprechstunden der Lehrkräfte (`--class`, `--teacher`, `--date`, `--weeks`) |
| `messages list` | Posteingang, Gesendet oder Entwürfe (`--folder`) |
| `messages read <id>` | Eine Mitteilung im Volltext |
| `messages recipients` | Mögliche Empfänger mit userId |
| `messages permissions` | Was der Account senden darf |
| `messages send` | Mitteilung schreiben (siehe unten) |

`--json` gibt bei jedem Befehl die Rohdaten aus -- das ist der verlässliche
Weg, wenn die lesbare Ausgabe ein Feld nicht kennt. Das Flag darf **vor oder
nach** dem Subcommand stehen, beides ist gleichwertig:

```
python3 "$SKILL_DIR/webuntis" --json homework --days 30
python3 "$SKILL_DIR/webuntis" homework --days 30 --json
```

`timetable` hängt an jede Stunde ihre Texte an, getrennt durch ` · `: `lessonText`
(bei Prüfungen die Art), `periodText` (Stundeninhalt, Hinweise), `substText`.

Datumsangaben: `YYYY-MM-DD`, `heute` oder `morgen`.

### Beispiele

```
python3 "$SKILL_DIR/webuntis" timetable --date morgen --days 1
python3 "$SKILL_DIR/webuntis" timetable --student Anna --days 5
python3 "$SKILL_DIR/webuntis" timetable --class 2a --days 5
python3 "$SKILL_DIR/webuntis" news --date heute
python3 "$SKILL_DIR/webuntis" homework --student Ben --date heute --days 3
python3 "$SKILL_DIR/webuntis" absences --student Ben --date 2026-09-14 --days 90
python3 "$SKILL_DIR/webuntis" officehours --class 2a --weeks 2
python3 "$SKILL_DIR/webuntis" officehours --teacher MUS --date morgen
python3 "$SKILL_DIR/webuntis" messages list --folder inbox --limit 10
python3 "$SKILL_DIR/webuntis" messages read 12345
```

### Klassenplan statt Schülerplan

`--class 2a` holt den Plan der ganzen Klasse statt den eines Kindes -- der Weg,
solange die persönliche Schülerzuordnung in WebUntis fehlt (dann ist der
Schülerplan leer, der Klassenplan aber vollständig). Kürzel wie im Zeugnis
(`2a`, `4b`); `classes` listet alle auf.

**Der Klassenplan ist ein Notbehelf, kein gleichwertiger Ersatz.** Er zeigt
alle Gruppen einer Stunde nebeneinander, der Schülerplan nur die des Kindes:

```
Klassenplan 2a          Schülerplan Anna
  BSPK HAN TS1            BSPK HAN TS1
  BSPM UNB TS2            (fällt weg)
  E    SAL 111            (fällt weg)
  E    BER 207            E    BER 207
```

Typische Teilungen: Bewegung und Sport nach Knaben und Mädchen (`BSPK`/`BSPM`),
Englisch und andere Fächer in zwei Gruppen bei verschiedenen Lehrkräften,
dazu Wahlpflichtfächer und Religion.

Daraus folgt für die Auskunft an den Nutzer: **sobald der Schülerplan Daten
liefert, immer `--student` verwenden.** Wird ersatzweise der Klassenplan
genommen, ist dazuzusagen, dass geteilte Stunden doppelt erscheinen und nicht
alle davon für das Kind gelten -- niemals eine Gruppe raten.

Ohne `--student` wird das erste zugeordnete Kind genommen. Sobald mehrere
Kinder im Account hängen, **immer `--student` setzen** statt sich auf die
Reihenfolge zu verlassen.

## Nachricht schreiben

Empfänger zuerst ermitteln, `send` braucht die numerische `userId`:

```
python3 "$SKILL_DIR/webuntis" messages recipients
python3 "$SKILL_DIR/webuntis" messages send \
    --to 12345 --subject "Krankmeldung" --body - --dry-run
```

`--body -` liest den Text von stdin (besser als lange Texte in der
Kommandozeile). **`--dry-run` zeigt nur die Nutzlast und sendet nicht.**

Vor dem ersten echten Versand: `--dry-run` zeigen lassen und vom Nutzer
bestätigen lassen. Eine gesendete Mitteilung geht an eine echte Lehrkraft
und lässt sich nicht zurückziehen.

**Den Text über eine Datei oder stdin übergeben, nicht aus einem
Markdown-Codeblock kopieren lassen.** Sonst landen die Einrückung des Blocks
und dessen harte Zeilenumbrüche in der Mitteilung (jede Zeile ab der zweiten
um zwei Leerzeichen eingerückt).

## Was eine Schule freigibt (Beispiel)

Geprüft am 14.09.2026 mit einem Erziehungsberechtigten-Account an einer
österreichischen AHS, nachgeprüft am 13.11.2026. Andere Schulen schalten
andere Bereiche frei:

| Bereich | Status |
|---------|--------|
| Stundenplan Klasse | funktioniert, vollständige Daten |
| Stundenplan Schüler | funktioniert; leer, solange die Schülerzuordnung fehlt (zu Schulbeginn) |
| Tagesnachrichten | funktioniert |
| Mitteilungen lesen | funktioniert |
| Mitteilungen senden | erlaubt, `recipientOptions: ["TEACHER"]`, max. 5 Anhänge a 7 MB |
| Mitteilungen senden (Skript) | v2 seit 18.09.2026, scharf gelaufen seit November 2026, siehe unten |
| Hausaufgaben | Endpunkt antwortet, war leer |
| Abwesenheiten | funktioniert, nur je Kind mit `studentId` (ohne: HTTP 500) |
| Sprechstunden | funktioniert (`officehours`); Anmeldung laut Einstellungen erlaubt, im Script noch nicht |
| Prüfungen | HTTP 403 -- für Eltern gesperrt |

Bei 403/500 meldet das Script das im Klartext. Oft ist das eine
Rechteeinstellung der Schule -- nicht versuchen zu umgehen. **Ein 500 kann aber
auch ein fehlender Parameter sein:** die Abwesenheiten galten bis 13.11.2026
als "an dieser Schule nicht aktiv", tatsächlich fehlte nur die `studentId`.
Vor dem Urteil "gesperrt" den Request der Weboberfläche vergleichen.

### Prüfungstermine trotzdem aus dem Stundenplan

Der Stundenplan markiert Stunden mit Prüfung als `[Pruefung]`, auch für
Eltern. Für "welche Tests bis X" daher den Schülerplan über den Zeitraum
holen und nach der Markierung filtern:

```
python3 "$SKILL_DIR/webuntis" timetable --student Anna --date 2026-11-09 --days 45 \
  | awk '/^(Mo|Di|Mi|Do|Fr) /{d=$0} /\[Pruefung\]/{print d" | "$0}'
```

- Die **Art** steht hinter der Markierung, wenn die Lehrkraft sie einträgt
  (`lessonText`, etwa `SA M`, `T BIOUB_3`). Fehlt sie -- nicht raten, sondern als
  "Prüfung, Art offen" melden.
- Termine werden verschoben, auch mehrfach und kurzfristig. Vor jeder
  Weitergabe frisch abfragen.
- Kurzfristig angesagte Wiederholungen ohne Eintrag fehlen.

## Technik

### Versand: v2 und multipart, nicht v1/JSON

Bis 18.09.2026 schickte `messages send` ein JSON an
`POST /api/rest/view/v1/messages` mit dem Feld `recipientStaticPersonIds`.
Das quittiert der Server mit **403**, obwohl
`/api/rest/view/v1/messages/permissions` `["TEACHER"]` meldet und das Konto
über die Weboberfläche senden darf -- die Route gibt es so nicht mehr.

Die Oberfläche verwendet:

```
POST /api/rest/view/v2/messages/users
Content-Type: multipart/form-data; boundary=...
```

mit **einem** Part `request` (`filename="blob"`, `Content-Type: application/json`)
und diesem Rumpf:

```json
{"subject": "...", "content": "...", "requestConfirmation": false,
 "recipientUserIds": [12345], "oneDriveAttachments": [], "forbidReply": false}
```

Der Empfänger steht also in `recipientUserIds` (die `userId` aus
`messages recipients`), ein `recipientOption` gibt es nicht mehr. Ein
403 beim Senden ist demnach zuerst ein Verdacht gegen den Endpunkt, nicht
gegen die Rechte der Schule.

Login per Formular (`POST /WebUntis/j_spring_security_check`) setzt die
Session-Cookies, die unter `~/.cache/webuntis-skill/` (Modus 600) liegen und
wiederverwendet werden. Die REST-Endpunkte unter
`/WebUntis/api/rest/view/v1/` brauchen zusätzlich ein Bearer-Token aus
`/WebUntis/api/token/new`; das Script holt es automatisch und erneuert es bei
HTTP 401. Ältere Endpunkte (`/api/public/...`, `/api/homeworks/...`) kommen
mit der Cookie-Session aus.

### Abwesenheiten

`GET /api/classreg/absences/students?studentId=<id>&startDate=YYYYMMDD&endDate=YYYYMMDD&excuseStatusId=-1&includeTodaysAbsence=true`

Ohne `studentId` antwortet der Server mit **500 `INTERNAL_ERROR`**, deshalb
fragt `absences` je Kind einzeln. `excuseStatusId`: `-1` alle, `-2`
entschuldigt, `-3` nicht entschuldigt, `0` offen (Liste aus
`/api/classreg/absences/meta`). Laut `meta` dürfte der Eltern-Account
Abwesenheiten auch melden und entschuldigen (`canReportAbsence`,
`canExcuse`) -- diese schreibenden Requests sind nicht aufgezeichnet und im
Script nicht nachgebaut.

### Sprechstunden

Alle mit der Cookie-Session:

| Endpunkt | Inhalt |
|---|---|
| `GET /api/public/officehours/classes` | Klassen mit `id` und `label` |
| `GET /api/public/officehours/hours?date=YYYYMMDD&klasseId=<id>` | Sprechstunden ab `date`, etwa eine Woche: Lehrkraft, Tag, Zeit, Raum, `available`, `registered`; `klasseId=-1` für alle |
| `GET /api/public/officehours/registrations` | eigene Anmeldungen |
| `GET /api/public/officehours/settings` | u.a. `allowRegistration`, `noAppointmentMsg` |

`officehours` fragt Woche für Woche ab und fasst Doppelte zusammen. Einträge
mit `date: 0` haben keinen festen Termin und erscheinen als "nach
Vereinbarung". `--class` beschränkt auf die Lehrkräfte einer Klasse.
Die Anmeldung selbst (vermutlich ein `POST`) ist nicht aufgezeichnet.

### Neues Stundenplan-API -- geprüft, nicht übernommen

Die Weboberfläche lädt den Stundenplan inzwischen über
`GET /api/rest/view/v1/timetable/entries?start=YYYY-MM-DD&end=YYYY-MM-DD&format=1&resourceType=STUDENT&resources=<id>&timetableType=MY_TIMETABLE&layout=START_TIME`
(Bearer-Token nötig; Klasse: `resourceType=CLASS`, `timetableType=STANDARD`).

Am 13.11.2026 für zwei Kinder über ein ganzes Semester (rund 800 Stunden)
gegen `public/timetable/weekly/data` verglichen, das `timetable` nutzt:

- **Eine Stunde fehlte** im neuen API, das alte lieferte sie.
- **`FREE` und `CANCEL`** landen beide auf `status: CANCELLED` -- "frei" und
  "Entfall" sind nicht mehr unterscheidbar.
- Gleichwertig: Zeiten, Fach, Lehrkraft, Raum, Prüfungen (`type: EXAM`,
  Art in `lessonInfo`), Notizen (`notesAll` = alt `periodText`), Vertretung
  und Raumwechsel (`removed` = alt `orgId`), verlegt (`moved`).
- Zusätzlich nur Langnamen (Fach "Mathematik", Raum "Musiksaal") und
  zusammengefasste Doppelstunden.

Daher bleibt `timetable` beim alten API. Erst umstellen, wenn das alte
abgeschaltet wird -- dann die beiden Lücken oben berücksichtigen.

## Grenzen

- Nur macOS (Schlüsselbund über `security`).
- Der v2-Versand ist gegen den Request der Weboberfläche nachgebaut und
  läuft seit November 2026 scharf. Da Untis die Route nicht dokumentiert, kann
  sie sich ohne Ankündigung ändern -- vor jedem Versand weiterhin `--dry-run`
  zeigen und vom Nutzer bestätigen lassen.
