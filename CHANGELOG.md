# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-10

### Added
- RCON command `/pelican.chat` - Returns chat messages as JSON
- RCON command `/pelican.status` - Returns server status as JSON (game time, player count, evolution, research)
- RCON command `/pelican.players` - Returns online player list as JSON
- Chat logging for player messages
- Event tracking for player join/leave
- Multi-language support (German, English)
- Factorio 2.0 API compatibility (uses `storage` instead of `global`)

### Technical Details
- Uses LuaGameScript `storage` for persistent data storage
- Efficient evolution factor calculation with optional enemy access
- JSON-formatted output for easy integration with external systems
