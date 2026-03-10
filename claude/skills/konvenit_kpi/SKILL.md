---
name: konvenit-kpi
description: "KPI-Auswertung für Blocker-Tickets im MP-Projekt. Fragt nach dem Monat, ruft dann per Atlassian Jira alle Blocker-Tickets ab, die in diesem Monat erstellt UND geschlossen wurden (Status 'Geschlossen') und GitHub-Links enthalten. Gibt eine Tabelle mit Key, Assignee, Summary, Created, Resolved, Duration aus – plus Durchschnitt und Maximum. Trigger-Wörter: KPI, Blocker, Blocker-Tickets, MP-Blocker, GitHub-Blocker, Durchlaufzeit, Jira-KPI, kpi blocker, wie lange blocker."
---

# KPI: Blocker-Tickets im MP-Projekt

Dieser Skill wertet Blocker-Tickets im Jira-Projekt MP aus, die in einem bestimmten Monat erstellt **und** geschlossen wurden und einen GitHub-Link enthalten.

---

## Schritt 1: Monat erfragen

Frage den User nach dem gewünschten Monat. Schlage dabei den **vorherigen Monat** als Standard vor.

Beispiel:
> "Für welchen Monat soll ich die Blocker-Tickets auswerten? (Vorschlag: **März 2026**)"

---

## Schritt 2: Datumsgrenzen berechnen

Berechne aus der Monatsangabe:
- `DATE_FROM`: Erster Tag des Monats → `YYYY-MM-01`
- `DATE_TO`: Letzter Tag des Monats (28/29/30/31 je nach Monat und Schaltjahr)

Beispiel für März 2026:
- `DATE_FROM = 2026-03-01`
- `DATE_TO = 2026-03-31`

---

## Schritt 3: Ticket-Keys per acli suchen

Verwende `acli jira workitem search` mit folgendem JQL:

```bash
acli jira workitem search --jql 'project = MP AND created >= "DATE_FROM" AND created <= "DATE_TO" AND (status CHANGED TO "Geschlossen" DURING ("DATE_FROM", "DATE_TO")) AND text ~ "github.com" AND priority = Blocker' --fields "key,summary,assignee,status,priority" --paginate --json
```

**Wichtig:** Die Search-Funktion unterstützt NICHT die Felder `created` und `resolutiondate`. Deshalb werden in diesem Schritt nur die Ticket-Keys und Basisdaten geholt.

---

## Schritt 4: Datumsfelder per workitem view nachladen

Für jedes gefundene Ticket die Datumsfelder einzeln abrufen:

```bash
acli jira workitem view <KEY> --fields "key,summary,assignee,created,resolutiondate,statuscategorychangedate" --json
```

**Fallback-Logik für das Schließdatum:**
- Primär: `resolutiondate` verwenden
- Fallback: Wenn `resolutiondate` null ist (häufig bei geschlossenen Tickets ohne formale Resolution), `statuscategorychangedate` als Schließdatum verwenden

---

## Schritt 5: Dauer berechnen

Für jedes Ticket:
- `Resolved` = `resolutiondate` || `statuscategorychangedate`
- `Duration` = `Resolved` - `created`
- Ausgabe in **ganzen Tagen** (z.B. `3d`, `0d`, `12d`)
- Falls weder `resolutiondate` noch `statuscategorychangedate` vorhanden → zeige `–` an

---

## Schritt 6: Ergebnisse als Tabelle ausgeben

Gib die Tickets in dieser Tabellenstruktur aus:

```
| Key      | Assignee       | Summary                              | Created          | Resolved         | Duration |
|----------|----------------|--------------------------------------|------------------|------------------|----------|
| MP-1234  | Max Mustermann | Fix broken deploy pipeline on github | 2026-03-03 09:15 | 2026-03-05 14:30 | 2d       |
| MP-1251  | Erika Muster   | GitHub action fails on main branch   | 2026-03-12 11:00 | 2026-03-12 16:45 | 0d       |
```

Darunter gibst du aus:

```
📊 Auswertung März 2026
─────────────────────────────────
Tickets gesamt:    5
Ø Durchlaufzeit:   3,4 Tage
⏱ Längste Dauer:   7 Tage (MP-1267)
```

Status Text: Blocker: <Anzahl Tickets> (all security updates) - MTTC: AVG (<Durchlaufzeit> Days) longest: <Längste Dauer> days
---

## Schritt 7: Sonderfälle

| Situation | Verhalten |
|---|---|
| Keine Tickets gefunden | "Keine Blocker-Tickets für diesen Monat gefunden." |
| `resolutiondate` null | `statuscategorychangedate` als Fallback verwenden |
| Beide Datumsfelder null | Duration = `–`, wird aus Durchschnitt ausgeschlossen |
| Ticket noch offen | Wird nicht angezeigt (JQL filtert bereits danach) |

---

## Hinweise zur acli-Integration

- Verwende `acli jira workitem search` für die JQL-Suche und `acli jira workitem view` für Detailfelder
- Die Search-Funktion unterstützt nur bestimmte Felder: `key`, `summary`, `assignee`, `status`, `priority`, `issuetype`
- Datumsfelder (`created`, `resolutiondate`, `statuscategorychangedate`) müssen per `workitem view --fields` einzeln abgerufen werden
- Verwende `--paginate --json` bei der Suche für vollständige Ergebnisse
- Achte auf die Zeitzonen bei der Berechnung von `Duration` (Jira gibt Zeiten mit Offset zurück, z.B. `+0100`)
