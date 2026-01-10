-- Pelican Chat Logger
-- Exports chat messages and player events for Pelican Panel integration
-- Supports both file-based output AND direct RCON responses

local CONFIG = {
    max_entries = 100,  -- Keep last 100 messages
    include_system = true,  -- Include join/leave/death messages
    include_commands = false,  -- Don't log commands for security
    include_research = true,  -- Include research events
    include_admin = true  -- Include ban/kick events
}

-- Initialize storage
local function init_storage()
    if not storage then
        storage = {}
    end
    if not storage.chat_log then
        storage.chat_log = {}
    end
    if not storage.message_id then
        storage.message_id = 0
    end
end

-- Get real-world timestamp approximation using game tick
local function get_timestamp()
    local tick = game.tick
    local seconds = math.floor(tick / 60)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    
    return string.format("%02d:%02d:%02d", hours % 24, minutes % 60, seconds % 60)
end

-- Escape string for JSON
local function json_escape(str)
    if not str then return "" end
    str = string.gsub(str, '\\', '\\\\')
    str = string.gsub(str, '"', '\\"')
    str = string.gsub(str, '\n', '\\n')
    str = string.gsub(str, '\r', '\\r')
    str = string.gsub(str, '\t', '\\t')
    return str
end

-- Convert entry to JSON string
local function entry_to_json(entry)
    return string.format(
        '{"id":%d,"type":"%s","player":"%s","message":"%s","color":"%s","tick":%d,"time":"%s"}',
        entry.id,
        json_escape(entry.type),
        json_escape(entry.player),
        json_escape(entry.message),
        json_escape(entry.color),
        entry.tick,
        entry.time
    )
end

-- Add entry to chat log
local function add_entry(entry_type, player_name, message, color)
    init_storage()
    
    storage.message_id = storage.message_id + 1
    
    local entry = {
        id = storage.message_id,
        type = entry_type,
        player = player_name or "Server",
        message = message or "",
        color = color or "white",
        tick = game.tick,
        time = get_timestamp()
    }
    
    table.insert(storage.chat_log, entry)
    
    -- Trim old entries
    while #storage.chat_log > CONFIG.max_entries do
        table.remove(storage.chat_log, 1)
    end
end

-- NOTE: File output removed in v1.0.1
-- Factorio 2.0 removed game.write_file()
-- Use RCON commands (pelican.chat, pelican.status, etc.) to retrieve data

-- Event: Player chat message
script.on_event(defines.events.on_console_chat, function(event)
    local player = event.player_index and game.get_player(event.player_index)
    local player_name = player and player.name or "Server"
    local message = event.message
    
    -- Skip commands if configured
    if not CONFIG.include_commands and string.sub(message, 1, 1) == "/" then
        return
    end
    
    -- Determine color based on player
    local color = "white"
    if player then
        if player.admin then
            color = "orange"
        else
            color = "cyan"
        end
    else
        color = "yellow"  -- Server messages
    end
    
    add_entry("chat", player_name, message, color)
end)

-- Event: Player joined
script.on_event(defines.events.on_player_joined_game, function(event)
    if not CONFIG.include_system then return end
    
    local player = game.get_player(event.player_index)
    if player then
        add_entry("join", player.name, player.name .. " joined the game", "green")
    end
end)

-- Event: Player left
script.on_event(defines.events.on_player_left_game, function(event)
    if not CONFIG.include_system then return end
    
    local player = game.get_player(event.player_index)
    if player then
        add_entry("leave", player.name, player.name .. " left the game", "red")
    end
end)

-- Event: Player died
script.on_event(defines.events.on_player_died, function(event)
    if not CONFIG.include_system then return end
    
    local player = game.get_player(event.player_index)
    if player then
        local cause = ""
        if event.cause then
            cause = " (killed by " .. (event.cause.name or "unknown") .. ")"
        end
        add_entry("death", player.name, player.name .. " died" .. cause, "red")
    end
end)

-- Event: Player respawned
script.on_event(defines.events.on_player_respawned, function(event)
    if not CONFIG.include_system then return end
    
    local player = game.get_player(event.player_index)
    if player then
        add_entry("respawn", player.name, player.name .. " respawned", "green")
    end
end)

-- Event: Research completed
script.on_event(defines.events.on_research_finished, function(event)
    if not CONFIG.include_research then return end
    
    local research = event.research
    if research then
        add_entry("research", "Server", "Research completed: " .. research.name, "purple")
    end
end)

-- Event: Research started
script.on_event(defines.events.on_research_started, function(event)
    if not CONFIG.include_research then return end
    
    local research = event.research
    if research then
        add_entry("research_started", "Server", "Research started: " .. research.name, "blue")
    end
end)

-- Event: Player banned
script.on_event(defines.events.on_player_banned, function(event)
    if not CONFIG.include_admin then return end
    
    local player_name = event.player_name or "Unknown"
    local by_player = event.by_player and game.get_player(event.by_player)
    local by_name = by_player and by_player.name or "Server"
    local reason = event.reason or ""
    
    local message = player_name .. " was banned by " .. by_name
    if reason ~= "" then
        message = message .. " (Reason: " .. reason .. ")"
    end
    
    add_entry("ban", player_name, message, "red")
end)

-- Event: Player unbanned
script.on_event(defines.events.on_player_unbanned, function(event)
    if not CONFIG.include_admin then return end
    
    local player_name = event.player_name or "Unknown"
    local by_player = event.by_player and game.get_player(event.by_player)
    local by_name = by_player and by_player.name or "Server"
    
    add_entry("unban", player_name, player_name .. " was unbanned by " .. by_name, "green")
end)

-- Event: Player kicked
script.on_event(defines.events.on_player_kicked, function(event)
    if not CONFIG.include_admin then return end
    
    local player = game.get_player(event.player_index)
    local player_name = player and player.name or "Unknown"
    local by_player = event.by_player and game.get_player(event.by_player)
    local by_name = by_player and by_player.name or "Server"
    local reason = event.reason or ""
    
    local message = player_name .. " was kicked by " .. by_name
    if reason ~= "" then
        message = message .. " (Reason: " .. reason .. ")"
    end
    
    add_entry("kick", player_name, message, "orange")
end)

-- Event: Player promoted to admin
script.on_event(defines.events.on_player_promoted, function(event)
    if not CONFIG.include_admin then return end
    
    local player = game.get_player(event.player_index)
    if player then
        add_entry("promote", player.name, player.name .. " was promoted to admin", "gold")
    end
end)

-- Event: Player demoted from admin
script.on_event(defines.events.on_player_demoted, function(event)
    if not CONFIG.include_admin then return end
    
    local player = game.get_player(event.player_index)
    if player then
        add_entry("demote", player.name, player.name .. " was demoted from admin", "orange")
    end
end)

-- Initialize on load
script.on_init(function()
    init_storage()
    add_entry("system", "Server", "Pelican Chat Logger initialized", "gray")
end)

script.on_load(function()
    -- Storage is automatically restored by Factorio
    -- No initialization needed here
end)

-- Handle mod updates and configuration changes
script.on_configuration_changed(function(data)
    init_storage()
    
    local mod_changes = data.mod_changes["pelican-chat-logger"]
    if mod_changes then
        -- Mod was updated
        local old_version = mod_changes.old_version
        local new_version = mod_changes.new_version
        
        if old_version then
            add_entry("system", "Server", "Pelican Chat Logger updated from " .. old_version .. " to " .. new_version, "blue")
        end
    end
end)

-- ============================================
-- RCON Commands
-- These commands return data directly via rcon.print()
-- ============================================

-- /pelican.chat [count] - Get last N chat messages as JSON
commands.add_command("pelican.chat", "Get recent chat messages (JSON)", function(cmd)
    init_storage()
    
    local count = tonumber(cmd.parameter) or 50
    count = math.min(count, CONFIG.max_entries)
    
    local result = {}
    local start = math.max(1, #storage.chat_log - count + 1)
    
    for i = start, #storage.chat_log do
        table.insert(result, entry_to_json(storage.chat_log[i]))
    end
    
    rcon.print('[' .. table.concat(result, ',') .. ']')
end)

-- /pelican.status - Get server status as JSON
commands.add_command("pelican.status", "Get server status (JSON)", function(cmd)
    local online_players = {}
    local player_count = 0
    
    for _, player in pairs(game.connected_players) do
        player_count = player_count + 1
        table.insert(online_players, string.format(
            '{"name":"%s","admin":%s,"time_played":%d}',
            json_escape(player.name),
            tostring(player.admin),
            player.online_time
        ))
    end
    
    local current_research = "null"
    if game.forces["player"].current_research then
        current_research = string.format('"%s"', json_escape(game.forces["player"].current_research.name))
    end
    
    -- Safe evolution factor retrieval (property in Factorio 2.0, not a method)
    local evolution = 0
    local enemy_force = game.forces["enemy"]
    if enemy_force then
        evolution = enemy_force.evolution_factor or 0
    end
    
    local status = string.format(
        '{"tick":%d,"time":"%s","players":%d,"player_list":[%s],"current_research":%s,"evolution":%.4f}',
        game.tick,
        get_timestamp(),
        player_count,
        table.concat(online_players, ','),
        current_research,
        evolution
    )
    
    rcon.print(status)
end)

-- /pelican.players - Get online players as JSON
commands.add_command("pelican.players", "Get online players (JSON)", function(cmd)
    local players = {}
    
    for _, player in pairs(game.connected_players) do
        table.insert(players, string.format(
            '{"name":"%s","admin":%s,"afk_time":%d,"position":{"x":%.1f,"y":%.1f},"surface":"%s"}',
            json_escape(player.name),
            tostring(player.admin),
            player.afk_time,
            player.position.x,
            player.position.y,
            player.surface.name
        ))
    end
    
    rcon.print('[' .. table.concat(players, ',') .. ']')
end)

-- /pelican.say <message> - Send server message
commands.add_command("pelican.say", "Send server message", function(cmd)
    if cmd.parameter and cmd.parameter ~= "" then
        game.print("[Server] " .. cmd.parameter)
        add_entry("server", "Server", cmd.parameter, "yellow")
        rcon.print('{"status":"ok","message":"sent"}')
    else
        rcon.print('{"status":"error","message":"No message provided"}')
    end
end)

-- /pelican.clear - Clear chat log
commands.add_command("pelican.clear", "Clear chat log", function(cmd)
    init_storage()
    storage.chat_log = {}
    storage.message_id = 0
    rcon.print('{"status":"ok","message":"Chat log cleared"}')
end)

-- /pelican.version - Get mod version
commands.add_command("pelican.version", "Get mod version", function(cmd)
    rcon.print('{"name":"pelican-chat-logger","version":"1.0.2","api_version":1}')
end)

-- Remote interface for external tools
remote.add_interface("pelican_chat_logger", {
    -- Get last N messages
    get_messages = function(count)
        init_storage()
        count = count or 50
        local result = {}
        local start = math.max(1, #storage.chat_log - count + 1)
        for i = start, #storage.chat_log do
            table.insert(result, storage.chat_log[i])
        end
        return result
    end,
    
    -- Clear chat log
    clear = function()
        init_storage()
        storage.chat_log = {}
        storage.message_id = 0
    end,
    
    -- Add server message
    server_message = function(message)
        add_entry("server", "Server", message, "yellow")
    end
})

-- Load tests module (optional - only if file exists)
local function load_tests()
    local success, err = pcall(function()
        require("tests")
    end)
    if success then
        -- Tests loaded successfully
    end
end

-- Attempt to load tests
load_tests()
