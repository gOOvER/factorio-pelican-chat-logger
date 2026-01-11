# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] - 2026-01-11

### Fixed
- Fixed evolution factor API call - use `enemy.get_evolution_factor(surface)` instead of `surface.get_enemy_evolution()`

## [1.0.4] - 2026-01-11

### Added
- GitHub Action workflow for automated publishing to Factorio Mod Portal
- `.factorioignore` file to exclude non-mod files from package

### Changed
- Manual workflow trigger with version input

## [1.0.3] - 2026-01-11

### Fixed
- Fixed `evolution_factor` crash in Factorio 2.0 - property was moved from `LuaForce` to surface
- Evolution now correctly retrieved via `surface.get_enemy_evolution()`

## [1.0.1] - 2026-01-10

### Fixed
- Removed `game.write_file()` which was removed in Factorio 2.0 API
- Mod now works purely via RCON commands (no file output)

### Changed
- Removed `output_file` configuration option (no longer needed)
- Removed periodic file save (on_nth_tick handler)

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
