# Kryos Dungeon Tool
<img width="758" height="575" alt="Wow_ZJDN25IIeW" src="https://github.com/user-attachments/assets/a90f25af-100c-4da1-b580-c2754efae812" />
<img width="767" height="573" alt="Wow_mlca6DcKhT" src="https://github.com/user-attachments/assets/d825a988-fd76-48b2-8aae-98a56fade603" />
<img width="717" height="564" alt="Wow_QyhrfslOSr" src="https://github.com/user-attachments/assets/e3a0f782-0d6b-4f29-bcf9-59277d100cf2" />

https://discord.gg/NfEzzudDJp

A World of Warcraft addon for Mythic+ dungeon groups that helps you manage your group composition, track important utilities, maintain a blacklist of players, and quickly teleport to dungeons.

![Version](https://img.shields.io/badge/version-1.3-blue)
![WoW Version](https://img.shields.io/badge/WoW-The%20War%20Within-orange)

## Features

### Group Check
- **Group Overview**: See your group composition at a glance (Tanks, Healers, DPS)
- **Utility Tracking**: Instantly see if your group has Battle Rez and Bloodlust
- **Keystone Display**: View all party members' Mythic+ keystones
- **Class Stacking Warning**: Get notified when multiple players share the same class
- **Member List**: Detailed view of all group members with role, class, spec, and utilities

### Quick Actions
- **Ready Check**: Start a ready check with one click
- **Countdown**: Customizable countdown timer (1-60 seconds)
- **Post to Chat**: Share group composition in party/raid chat
- **Auto-Post**: Automatically announce new players joining your group with their spec and utilities

### Blacklist System
- **Add Players**: Blacklist players with a custom reason
- **Visual Warnings**: Blacklisted players are highlighted in the group list
- **Tooltip Integration**: See blacklist status when hovering over players
- **Join Alerts**: Get notified (with optional custom sound) when a blacklisted player joins your group
- **Right-Click Menu**: Quickly add/remove players via right-click context menu
- **Share List**: Share your blacklist with group members who also have the addon

### M+ Teleports (NEW in v1.3)
- **Season 3 Dungeons**: Quick access to all current M+ dungeon teleports
- **Visual Status**: See which teleports you have unlocked (colored) vs locked (grayed out)
- **One-Click Teleport**: Click any unlocked dungeon to instantly teleport
- **Tooltips**: Hover to see dungeon name and unlock status

#### Current Season Dungeons:
- Ara-Kara
- Dawnbreaker
- Eco-Dome
- Halls of Attonement
- Operation: Floodgate
- Priory of the Sacred Flame
- Tazavesh: So'leah's Gambit
- Tazavesh: Streets of Wonder

## Installation

1. Download the latest release
2. Extract the `KryosDungeonTool` folder to your WoW AddOns directory:
   - Windows: `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\`
   - macOS: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or type `/reload` in-game

### Custom Alert Sound (Optional)
To use a custom alert sound for blacklisted players:
1. Place an audio file named `intruder.mp3` in the addon folder
2. Enable "Custom Sound" checkbox in the Blacklist tab

## Usage

### Opening the Addon
- Click the **minimap button** (Left-click: Group Check, Right-click: Blacklist)
- Type `/kdt` or `/kryos` in chat
- Open the **Group Finder** (the addon opens automatically)

### Slash Commands
| Command | Description |
|---------|-------------|
| `/kdt` | Open Group Check panel |
| `/kdt bl` | Open Blacklist panel |
| `/kdt tp` | Open M+ Teleports panel |
| `/kdt cd` | Start countdown |
| `/kdt ready` | Initiate ready check |
| `/kdt post` | Post group info to chat |
| `/kdt share` | Share blacklist with group |

### Chat Output Example
When using "Post to Chat":
```
====== GROUP CHECK ======
Playername - Rogue (Outlaw) | ED +15
Tankname - Paladin (Protection) [BR] | AK +12
Healername - Shaman (Restoration) [BL]
[X] NO Battle Rez!
=========================
```

When Auto-Post announces a new player:
```
[+] Playername joined (Shaman - Restoration) - brings BL
```

## Supported Utilities

### Battle Rez Classes
- Death Knight
- Druid
- Paladin
- Warlock

### Bloodlust Classes
- Evoker
- Hunter
- Mage
- Shaman

## Dungeon Abbreviations
| Abbreviation | Dungeon |
|--------------|---------|
| AK | Ara-Kara |
| DB | Darkflame Cleft |
| ED | The Dawnbreaker |
| HOA | Halls of Atonement |
| OF | Operation: Floodgate |
| PSF | Priory of the Sacred Flame |
| SG | Stonevault |
| SOW | Siege of Boralus |

## Changelog

### Version 1.4
- Refactored into modular file structure
- Cleaner code organization
- Easier maintenance and updates
- 
### Version 1.3
- **NEW: M+ Teleports Tab** - Quick access to all Season 3 dungeon teleports
- Visual indication of unlocked vs locked teleports
- One-click teleportation to any unlocked dungeon
- Spell tooltips on hover

### Version 1.2
- Fixed group member display issues
- Added Auto-Post feature for player joins
- Improved chat posting with rate-limit handling
- Fixed panel overlap when switching tabs
- Added blacklist sharing between group members
- Custom alert sound support

### Version 1.1
- Initial release
- Group composition tracking
- Blacklist system
- Keystone display
- Ready check and countdown integration

## License

This addon is provided free of charge for personal use.

## Support

If you encounter any issues or have suggestions, please open an issue on the repository or join Discord https://discord.gg/NfEzzudDJp

---

*Made for the WoW community by Kryo*
