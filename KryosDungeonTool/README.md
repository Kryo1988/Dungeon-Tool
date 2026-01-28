# Kryos Blacklist - WoW Addon

Ein professionelles World of Warcraft Addon mit vollständigem GUI, Custom Sound und Share-Funktion, das dich warnt, wenn ein Spieler von deiner Blacklist der Gruppe beitritt.

## 🎯 Features

### ✨ Vollständiges GUI
- **Grafische Oberfläche** zum Verwalten der Blacklist
- **Minimap-Button** zum schnellen Öffnen des GUIs (verschiebbar!)
- **Spieler hinzufügen** mit Name und Grund
- **Gründe bearbeiten** - ändere den Grund jederzeit mit einem Klick
- **Liste anzeigen** mit allen geblacklisteten Spielern und ihren Gründen
- **Spieler löschen** direkt aus der Liste per Knopfdruck
- **Komplette Liste leeren** mit Sicherheitsabfrage
- **Custom Sound Toggle** - zwischen eigenem Sound und Standard-Sound wählen

### 🔊 Custom Sound Alert
- **Eigener Alarm-Sound** (intruder.mp3) für Warnungen
- **Sound-Toggle** im GUI zum An/Ausschalten
- Demo-Funktion beim Umschalten

### 🔔 Automatische Warnungen
- Signalton wenn ein geblacklisteter Spieler der Gruppe beitritt (nur 1x pro Session!)
- Chat-Warnung mit Spielername und Grund
- Bildschirm-Alert im Raid-Warning Style

### 📤 Share-Funktion
- **Teile deine Blacklist** mit anderen Addon-Nutzern in deiner Gruppe/Raid/Gilde
- **Empfange Blacklists** von anderen Spielern
- **Bestätigungs-Dialog** bevor fremde Listen hinzugefügt werden
- Automatische Markierung woher die Einträge kommen

### 🖱️ Rechtsklick-Integration
- Rechtsklick auf Spieler → **"Zur Blacklist hinzufügen"** (direkt, kein Dialog)
- Rechtsklick auf Spieler → **"Von Blacklist entfernen"**
- Funktioniert überall: Gruppe, Raid, Freundesliste, Feinde

## 📦 Installation

1. Erstelle einen Ordner namens `KryosBlacklist` in deinem WoW AddOns-Verzeichnis:
   - **Windows:** `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\KryosBlacklist\`
   - **Mac:** `/Applications/World of Warcraft/_retail_/Interface/AddOns/KryosBlacklist/`

2. Kopiere **alle drei Dateien** in diesen Ordner:
   - `KryosBlacklist.toc`
   - `KryosBlacklist.lua`
   - `intruder.mp3` (Custom Sound-Datei)

3. Starte WoW neu oder nutze `/reload`

**WICHTIG:** Der Ordner muss genau `KryosBlacklist` heißen!

## 🎮 Verwendung

### GUI öffnen
Es gibt **3 Wege** das GUI zu öffnen:

1. **Minimap-Button** (empfohlen!)
   - Klicke auf den Button an deiner Minimap
   - Du kannst ihn mit gedrückter linker Maustaste verschieben

2. **Slash-Befehle**
```
/blacklist
/bl
```

3. **Rechtsklick auf Spieler**
   - Rechtsklick → "Zur Blacklist hinzufügen"
   - Spieler wird direkt mit Standardgrund hinzugefügt

### Im GUI kannst du:
1. **Spieler hinzufügen:**
   - Name eingeben
   - Grund eingeben (optional)
   - "Hinzufügen" klicken

2. **Blacklist ansehen:**
   - Alle Spieler mit ihren Gründen in einer scrollbaren Liste

3. **Grund bearbeiten:**
   - "Bearbeiten"-Button neben dem Spieler klicken
   - Grund ändern im Dialog
   - Enter drücken oder "Speichern" klicken

4. **Spieler löschen:**
   - "Löschen"-Button neben dem Spieler klicken

5. **Liste leeren:**
   - "Liste leeren" Button unten links (mit Sicherheitsabfrage)

6. **Blacklist teilen:**
   - "Liste teilen" Button klicken
   - Deine Liste wird an alle in deiner Gruppe/Raid/Gilde mit dem Addon gesendet
   - Andere erhalten einen Dialog zum Akzeptieren

7. **Sound umschalten:**
   - Checkbox "Custom Sound verwenden" an/aus
   - Demo-Sound wird beim Umschalten abgespielt

### Slash-Befehle (Alternative zum GUI)

| Befehl | Beschreibung | Beispiel |
|--------|--------------|----------|
| `/blacklist` | GUI öffnen | `/bl` |
| `/blacklist add <n> [Grund]` | Spieler hinzufügen | `/bl add Noobkiller Ninja Looter` |
| `/blacklist remove <n>` | Spieler entfernen | `/bl remove Noobkiller` |
| `/blacklist list` | Liste im Chat anzeigen | `/bl list` |
| `/blacklist clear` | Liste leeren | `/bl clear` |

## 🔊 Warnungen

Wenn ein geblacklisteter Spieler deiner Gruppe beitritt:
- ⚠️ **Signalton** (Custom oder Standard)
- 💬 **Chat-Nachricht:** "BLACKLIST ALARM: [Name] ist deiner Gruppe beigetreten!"
- 💬 **Grund anzeigen:** "Grund: [dein eingegebener Grund]"
- 📺 **Bildschirm-Warnung** (rote Nachricht oben am Bildschirm)
- ✅ **Nur 1x pro Session** - keine nervigen Wiederholungen!

## 💾 Datenspeicherung

- Die Blacklist wird **automatisch gespeichert**
- Bleibt nach Logout/Restart erhalten
- Für jeden Spieler wird gespeichert:
  - Name
  - Grund
  - Zeitstempel (wann hinzugefügt)

## 🔧 Technische Details

- **Interface Version:** 120000 (Patch 12.0.0)
- **Saved Variables:** KryosBlacklistDB
- Funktioniert in Dungeongruppen und Raids
- Servernamen werden automatisch entfernt

## ❓ Häufige Fragen

**Q: Kann ich einen Grund nachträglich ändern?**
A: Ja! Klicke einfach auf den "Bearbeiten"-Button neben dem Spieler in der Liste.

**Q: Warum hört die Warnung nicht mehr auf?**
A: Das wurde gefixt! Jeder Spieler löst nur EINMAL pro Session eine Warnung aus.

**Q: Wie viele Spieler kann ich auf die Blacklist setzen?**
A: Unbegrenzt (praktisch gesehen mehrere hundert ohne Performance-Probleme).

**Q: Sehen andere Spieler meine Blacklist?**
A: Nein, die Blacklist ist nur lokal auf deinem Computer gespeichert - außer du teilst sie explizit über die Share-Funktion.

**Q: Was passiert mit meiner alten BlacklistAlert?**
A: Deine Daten bleiben erhalten! Lösche einfach den alten BlacklistAlert-Ordner nach der Installation von KryosBlacklist.

**Q: Funktioniert es auch in Classic/TBC/Wrath?**
A: Du müsstest die Interface-Version in der .toc Datei anpassen.

## 🆕 Neu in Version 3.1

- ✏️ **Grund bearbeiten funktioniert jetzt korrekt** - Voller Dialog mit Enter-Support
- 🔕 **Keine mehrfachen Warnungen mehr** - Nur 1x Alarm pro Spieler pro Session
- 🎨 **Addon umbenannt** zu "Kryos Blacklist"
- 🔊 **Custom Sound Support** - Eigener Alarm-Sound mit Toggle
- 📤 **Share-Funktion** - Teile deine Blacklist mit anderen
- 📥 **Empfange Listen** von anderen Spielern
- 🎵 **Sound-Toggle** im GUI
- 🗺️ **Minimap-Button** (verschiebbar!)
- 🖱️ **Verbessertes Rechtsklick-Menü**
- ✨ Vollständiges GUI mit Scroll-Liste

## 💡 Tipps

- **Minimap-Button:** Du kannst ihn durch Ziehen verschieben
- **Schnellzugriff:** Der Minimap-Button ist der schnellste Weg
- **Bearbeiten:** Der Edit-Dialog funktioniert jetzt perfekt - Enter speichert!
- **Keine Spam-Warnungen mehr:** Jeder Spieler löst nur einmal eine Warnung aus

## 🐛 Troubleshooting

**GUI öffnet sich nicht?**
- Prüfe mit `/reload` ob das Addon geladen ist
- Schaue ins Interface-Addon-Menü ob "Kryos Blacklist" aktiviert ist

**Bearbeiten-Button funktioniert nicht?**
- Dieses Problem wurde in Version 3.1 behoben
- Stelle sicher, dass du die neueste Version hast

**Sound wird nicht abgespielt?**
- Stelle sicher, dass die intruder.mp3 Datei im KryosBlacklist-Ordner liegt
- Pfad: `Interface\AddOns\KryosBlacklist\intruder.mp3`

**Warnung kommt mehrfach?**
- Dieses Problem wurde in Version 3.1 behoben

## 🙏 Credits

Entwickelt von **Kryos** für die WoW-Community.

Viel Erfolg beim Dungeon-Farming! 🎮
