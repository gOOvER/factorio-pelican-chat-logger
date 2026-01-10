# Changelog

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [1.0.0] - 2026-01-10

### Hinzugefügt
- RCON-Befehl `/pelican.chat` - Gibt Chat-Nachrichten als JSON zurück
- RCON-Befehl `/pelican.status` - Gibt Serverstatus als JSON zurück (Spielzeit, Spieleranzahl, Evolution, Forschung)
- RCON-Befehl `/pelican.players` - Gibt Online-Spielerliste als JSON zurück
- Chat-Logging für Spielernachrichten
- Event-Tracking für Spieler-Join/Leave
- Mehrsprachige Unterstützung (Deutsch, Englisch)
- Kompatibilität mit Factorio 2.0 API (verwendet `storage` statt `global`)

### Technische Details
- Verwendet LuaGameScript `storage` für persistente Datenspeicherung
- Effiziente Evolution-Faktor-Berechnung mit optionalem Feindzugriff
- JSON-formatierte Ausgabe für einfache Integration mit externen Systemen
