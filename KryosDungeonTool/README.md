# Kryos Dungeon Tool v1.4

A comprehensive WoW addon for Mythic+ dungeon management.

## Features

- **Group Check**: View group composition, Battle Rez, Bloodlust, keystones
- **M+ Teleports**: Quick access to all dungeon teleports
- **Blacklist**: Track and alert when blacklisted players join

## Commands

- `/kdt` - Open Group Check
- `/kdt bl` - Open Blacklist
- `/kdt tp` - Open Teleports
- `/kdt cd` - Start countdown
- `/kdt ready` - Ready check
- `/kdt post` - Post group to chat
- `/kdt share` - Share blacklist with group
- `/kdt debug` - Debug keystone MapIDs

## File Structure

```
KryosDungeonTool/
├── Core.lua           # Main namespace, utilities, constants
├── DungeonData.lua    # Dungeon MapIDs and teleport data
├── Blacklist.lua      # Blacklist management
├── Group.lua          # Group analysis and chat functions
├── UI_MainFrame.lua   # Main window and tab system
├── UI_GroupTab.lua    # Group Check tab
├── UI_BlacklistTab.lua# Blacklist tab
├── UI_TeleportTab.lua # Teleports tab
├── Minimap.lua        # Minimap button
├── SlashCommands.lua  # Chat commands
├── Events.lua         # Event handling
└── Init.lua           # Initialization
```

## Adding New Dungeons

Edit `DungeonData.lua`:

1. **Keystone MapIDs** - Add to `KDT.DUNGEON_NAMES`
2. **Teleport Spells** - Add to `KDT.TELEPORT_DATA`

## Changelog

### v1.4
- Refactored into modular file structure
- Cleaner code organization
- Easier maintenance and updates

### v1.3
- Added M+ Teleports tab
- Added Midnight dungeons
- Fixed TWW Season 3 MapIDs
- Improved spec detection
