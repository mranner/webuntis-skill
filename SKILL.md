---
name: webuntis
description: >
  WebUntis für Erziehungsberechtigte: Stundenplan der Kinder, Tagesnachrichten
  der Schule, Hausaufgaben, Abwesenheiten, Sprechstunden der Lehrkräfte, die
  Termine am Elternsprechtag (lesen, buchen, stornieren) und das Mitteilungs-Center (Posteingang lesen, an Lehrkräfte schreiben). Läuft
  headless über die REST-API, Passwort aus dem macOS-Schlüsselbund - kein
  Browser nötig. Auch bei "was hat mein Kind morgen", "Stundenplan diese
  Woche", "gibt es neue Nachrichten in WebUntis", "schreib der Lehrerin",
  "fällt eine Stunde aus", "wann hat die Lehrerin Sprechstunde",
  "welche Sprechtagstermine haben wir", "was ist am Sprechtag noch frei", "buch den Sprechtagstermin".
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
| `homework` | Hausaufgaben (`--student`, `--date`, `--days`); ohne `--student` alle Kinder, jede Zeile mit Kind; erste Spalte ist das Abgabedatum (`dueDate`), das Aufgabedatum (`date`) nur mit `--json` |
| `absences` | Abwesenheiten (`--student`, `--date`, `--days`); ohne `--student` alle Kinder, jede Zeile mit Kind |
| `officehours` | Sprechstunden der Lehrkräfte (`--class`, `--teacher`, `--date`, `--weeks`); mit `--class` samt Fächern in der Klasse |
| `teachers` | Alle Lehrkräfte einer Klasse (`--class`) oder eines Kindes (`--student`) mit Fächern und nächster Sprechstunde (`--date`) |
| `parentsday info` | Elternsprechtag: Datum, Status, Buchungsfenster (`--id`, sonst der angekündigte) |
| `parentsday list` | Eigene Sprechtagstermine: Zeit, Lehrkraft, Fächer, Raum, Kinder |
| `parentsday free` | Je Zeit die Lehrkräfte, die das Konto noch buchen kann |
| `parentsday book` | Termin buchen (`--teacher` Kürzel oder Namensteil, `--time HH:MM`) |
| `parentsday cancel` | Termin stornieren (`--teacher`, `--time`) |
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
python3 "$SKILL_DIR/webuntis" teachers --student Anna
python3 "$SKILL_DIR/webuntis" teachers --class 2a
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

`--attach PFAD` hängt eine Datei an, mehrfach angeben für mehrere (max. 5,
je 7 MB). `--dry-run` listet dann jeden Anhang mit Typ und Größe.

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
| Mitteilungen senden (Skript) | v2 seit 18.09.2026, scharf gelaufen seit November 2026, Anhänge seit 22.11.2026, siehe unten |
| Hausaufgaben | funktioniert, liefert Daten (geprüft 23.11.2026); nur was die Lehrkraft einträgt, nicht jede trägt ein |
| Abwesenheiten | funktioniert, nur je Kind mit `studentId` (ohne: HTTP 500) |
| Sprechstunden | funktioniert (`officehours`); Anmeldung laut Einstellungen erlaubt, im Script noch nicht |
| Elternsprechtag | funktioniert (`parentsday`): lesen, buchen, stornieren |
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

Anhänge gehen im selben Request mit: je Datei ein weiterer Part
`attachments` mit `filename="<Originalname>"` und dem Dateityp als
`Content-Type`, Inhalt roh. `oneDriveAttachments` bleibt `[]`. Aus einem
HAR vom 22.11.2026 (ein PDF) nachgebaut; mehrere Anhänge als mehrere
`attachments`-Parts sind angenommen, nicht aufgezeichnet.

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
Vereinbarung". `--class` beschränkt auf die Lehrkräfte einer Klasse und
hängt ihre Fächer in dieser Klasse an: aus dem Klassenplan (mindestens zwei
Wochen, wegen 14-tägiger Fächer), verknüpft über das Kürzel in
"NAME, Vorname (KZ)"; mit `--json` im Feld `subjects`. Der Klassenplan
enthält alle Gruppen -- nicht jede Lehrkraft unterrichtet jedes Kind.

`teachers` geht vom Plan aus statt von den Sprechstunden: alle Lehrkräfte aus
14 Tagen Klassen- oder Schülerplan ab `--date`, auch die ohne Sprechstunde.
Für die Lehrkräfte **eines Kindes** `--student` nehmen -- nur der Schülerplan
kennt dessen Gruppen. Name und nächste Sprechstunde kommen aus den
Sprechstunden **aller** Klassen der nächsten 14 Tage; hat eine Lehrkraft dort
keine, steht nur das Kürzel mit `?` da (der Plan liefert keine Namen).

Die Anmeldung selbst (vermutlich ein `POST`) ist nicht aufgezeichnet.

### Elternsprechtag

Eigener JSON-RPC-Dienst, nicht die REST-API:
`POST /jsonrpc_web/jsonParentsDayService`, Körper
`{"id":0,"method":"<name>","params":[...],"jsonrpc":"2.0"}`. Er braucht die
Cookie-Session **und** den Header `X-CSRF-Token`, sonst **403 „Access
denied"**. Das Token steht als `<input name="_csrf">` im HTML von
`GET /main.do`; ein Bearer-Token braucht der Dienst nicht. Dort steht auch die
Sprechtag-id, als `parentsday/parentview?selId=<id>` -- nur solange die
Schule den Sprechtag auf der Startseite ankündigt.

| Methode | Parameter | Inhalt |
|---|---|---|
| `getParentsDayMetaData` | `["<id>", -1]` (id als String) | Name, `state`, Buchungsfenster `appointmentSelectionDateTimeRange`, `timeBlocks` mit 5-Minuten-`timeSlots` |
| `getParentsRegistrationData` | `[id, -1]` | alle Lehrkräfte (Kürzel); je Kind `isTeachingStudent` und Fächer |
| `getParentTimeSlots` | `[id, -1]` | alle Slots, gebuchte mit `appointment`: Lehrkraft, Fächer, Raum, Kinder -- dieselben Daten wie der PDF-Export |
| `getMatrixData` | `[id, blockId, -1, [lehrer-ids]]` | Spalten = Lehrkräfte (voller Name in `details[0].label`), Zeilen = Slots mit `relations` (gebucht) und `possibilities` (noch buchbar) |
| `saveAppointment` / `cancelAppointment` | `[id, lehrerId, blockId, slotId, -1, [1]]` | bucht bzw. storniert; Antwort: neue Matrix und Slots |

`possibilities` berücksichtigt schon, was der Server erlaubt, auch den
Mindestabstand zwischen zwei Buchungen desselben Kontos. `free` fragt die
Matrix über die Lehrkräfte ab, die ein Kind unterrichten -- so tut es die
Weboberfläche. Verifiziert 16.11.2026: `list` deckt sich mit dem PDF-Export,
`free` mit der Matrix der aufgezeichneten Sitzung.

`book` und `cancel` schreiben. Vor dem Aufruf **beim User bestätigen lassen**
(Lehrkraft und Zeit nennen) -- eine Buchung belegt den Termin für andere Eltern.
`book` prüft vorher `possibilities`, `cancel` die eigene Buchung; danach prüfen
beide an den zurückgegebenen `timeSlots`, ob sich die Buchung geändert hat. Eine
zweite Buchung bei derselben Lehrkraft **verschiebt nicht**, sie kommt dazu --
verschieben heißt: neu buchen, alten Termin stornieren. `--teacher` trifft das
Kürzel exakt oder einen Namensteil; ein Nachname, den zwei Lehrkräfte tragen,
ist mehrdeutig und bricht mit beiden Kandidaten ab. `-1` und `[1]` schickt die
Weboberfläche so mit, ihre Bedeutung ist offen. Verifiziert 16.11.2026: ein
freier Termin gebucht und storniert, die übrigen Termine unverändert.

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

Zuordnung `cellState` (alt) zu `type`/`status` (neu), beobachtet im selben
Vergleich:

| alt `cellState` | neu `type` | neu `status` | Merkmal |
|---|---|---|---|
| `STANDARD` | `NORMAL_TEACHING_PERIOD` | `REGULAR` | |
| `CANCEL` | `NORMAL_TEACHING_PERIOD` | `CANCELLED` | teils mit `moved` |
| `FREE` | `NORMAL_TEACHING_PERIOD` | `CANCELLED` | nicht von `CANCEL` zu trennen |
| `SUBSTITUTION` | `NORMAL_TEACHING_PERIOD` | `CHANGED` | `removed` bei der Lehrkraft |
| `ROOMSUBSTITUTION` | `NORMAL_TEACHING_PERIOD` | `CHANGED` | `removed` beim Raum, vereinzelt ohne `removed` |
| `ADDITIONAL` | `ADDITIONAL_PERIOD` | `ADDITIONAL` oder `CHANGED` | |
| `ADDITIONAL` | `EVENT` | `CHANGED` | Veranstaltung, Text in `lessonInfo` |
| `SHIFT` | `ADDITIONAL_PERIOD` | `ADDITIONAL` | `moved` |
| `EXAM` | `EXAM` | `REGULAR` | Art in `lessonInfo` |

Eine Doppelstunde ist ein Eintrag mit mehreren `ids`; jede `id` entspricht
einer Periode des alten API.

Daher bleibt `timetable` beim alten API. Erst umstellen, wenn das alte
abgeschaltet wird -- dann die beiden Lücken oben berücksichtigen.

## Grenzen

- Nur macOS (Schlüsselbund über `security`).
- Der v2-Versand ist gegen den Request der Weboberfläche nachgebaut und
  läuft seit November 2026 scharf. Da Untis die Route nicht dokumentiert, kann
  sie sich ohne Ankündigung ändern -- vor jedem Versand weiterhin `--dry-run`
  zeigen und vom Nutzer bestätigen lassen.
