# Kryos Dungeon Tool

A World of Warcraft addon for Mythic+ dungeon groups that helps you manage your group composition, track important utilities, and maintain a blacklist of players.

![Version](https://img.shields.io/badge/version-1.2-blue)
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

If you encounter any issues or have suggestions, please open an issue on the repository.

---

*Made for the WoW community by Kryos*
