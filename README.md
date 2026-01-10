# Pelican Chat Logger

A Factorio mod that logs chat messages and player events for integration with [Pelican Panel](https://pelican.dev/).

## Overview

The **Pelican Chat Logger** mod captures in-game chat messages and player events, providing them via RCON commands in JSON format. This enables the [Factorio RCON Manager](https://github.com/gOOvER/pelican-factorio-rcon) plugin to display chat history and extended server status in the Pelican Panel.

## Features

* **Chat Logging**: Captures all player chat messages
* **Player Events**: Tracks join, leave, death, and respawn events
* **Admin Events**: Logs kick, ban, unban, promote, and demote actions
* **Research Events**: Records research start and completion
* **RCON Integration**: Returns data as JSON via RCON commands
* **File Output**: Saves chat log to `script-output/pelican-chat.json`
* **Multi-language Support**: English and German localization

## Requirements

* **Factorio**: Version 2.0 or higher
* **Base Mod**: Version 2.0 or higher

## Installation

### Via Factorio Mod Portal
1. Search for "Pelican Chat Logger" in the Factorio mod portal
2. Click "Download" to install

### Manual Installation
1. Download the latest release from [GitHub Releases](https://github.com/gOOvER/factorio-pelican-chat-logger/releases)
2. Extract the ZIP file to your Factorio mods folder:
   - **Windows**: `%APPDATA%\Factorio\mods\`
   - **Linux**: `~/.factorio/mods/`
   - **Server**: `<server-path>/mods/`
3. Restart Factorio or the server

## RCON Commands

All commands return JSON data for easy parsing:

| Command | Description | Response |
|---------|-------------|----------|
| `/pelican.chat [count]` | Get last N chat messages (default: 50) | JSON array of messages |
| `/pelican.status` | Server status with players, evolution, research | JSON object |
| `/pelican.players` | Detailed online player information | JSON array |
| `/pelican.say <message>` | Send a server message (logged) | `{"status":"ok"}` |
| `/pelican.clear` | Clear the chat log | `{"status":"ok"}` |
| `/pelican.version` | Get mod version info | `{"name":"...","version":"..."}` |

### Response Examples

#### `/pelican.chat`
```json
[
  {
    "id": 1,
    "type": "chat",
    "player": "PlayerName",
    "message": "Hello everyone!",
    "color": "cyan",
    "tick": 12345,
    "time": "00:03:25"
  },
  {
    "id": 2,
    "type": "join",
    "player": "NewPlayer",
    "message": "NewPlayer joined the game",
    "color": "green",
    "tick": 12500,
    "time": "00:03:28"
  }
]
```

#### `/pelican.status`
```json
{
  "tick": 54321,
  "time": "00:15:05",
  "players": 3,
  "player_list": [
    {"name": "Player1", "admin": true, "time_played": 54000},
    {"name": "Player2", "admin": false, "time_played": 30000}
  ],
  "current_research": "automation-2",
  "evolution": 0.1523
}
```

#### `/pelican.players`
```json
[
  {
    "name": "Player1",
    "admin": true,
    "afk_time": 0,
    "position": {"x": 123.5, "y": -45.2},
    "surface": "nauvis"
  }
]
```

## Event Types

The mod logs the following event types:

| Type | Color | Description |
|------|-------|-------------|
| `chat` | cyan/orange | Player chat messages (orange for admins) |
| `server` | yellow | Server messages via `/pelican.say` |
| `join` | green | Player joined the game |
| `leave` | red | Player left the game |
| `death` | red | Player died |
| `respawn` | green | Player respawned |
| `research` | purple | Research completed |
| `research_started` | blue | Research started |
| `ban` | red | Player was banned |
| `unban` | green | Player was unbanned |
| `kick` | orange | Player was kicked |
| `promote` | gold | Player promoted to admin |
| `demote` | orange | Player demoted from admin |
| `system` | gray | System messages |

## Configuration

The mod uses the following default configuration:

```lua
CONFIG = {
    output_file = "pelican-chat.json",  -- Output file in script-output/
    max_entries = 100,                   -- Maximum stored messages
    include_system = true,               -- Log join/leave/death events
    include_commands = false,            -- Don't log commands (security)
    include_research = true,             -- Log research events
    include_admin = true                 -- Log ban/kick events
}
```

## File Output

The chat log is automatically saved to:
```
<factorio-install>/script-output/pelican-chat.json
```

The file is updated:
- On every new message
- Every 5 seconds (300 ticks)

## Remote Interface

For other mods or scripts, a remote interface is available:

```lua
-- Get last 50 messages
local messages = remote.call("pelican_chat_logger", "get_messages", 50)

-- Clear the chat log
remote.call("pelican_chat_logger", "clear")

-- Send a server message
remote.call("pelican_chat_logger", "server_message", "Hello from another mod!")
```

## Integration with Pelican Panel

This mod is designed to work with the **Factorio RCON Manager** plugin for Pelican Panel:

🔗 **[Factorio RCON Manager](https://github.com/gOOvER/pelican-factorio-rcon)**

The plugin uses the RCON commands provided by this mod to display:
- Real-time chat history in the panel
- Extended server status (evolution, research, game time)
- Detailed player information

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Author

**gOOvER**

## Links

- [GitHub Repository](https://github.com/gOOvER/factorio-pelican-chat-logger)
- [Pelican Panel](https://pelican.dev/)
- [Factorio RCON Manager Plugin](https://github.com/gOOvER/pelican-factorio-rcon)
