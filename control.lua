-- Pelican Chat Logger
-- Factorio 2.0+

local MAX_ENTRIES = 100

local function init_storage()
    storage.chat_log = storage.chat_log or {}
    storage.msg_id = storage.msg_id or 0
end

local function get_time()
    local t = game.tick
    local s = math.floor(t / 60)
    local m = math.floor(s / 60)
    local h = math.floor(m / 60)
    return string.format("%02d:%02d:%02d", h % 24, m % 60, s % 60)
end

local function esc(str)
    if not str then return "" end
    str = tostring(str)
    -- Escape backslash first, then other special chars
    str = str:gsub('\\', '\\\\')
    str = str:gsub('"', '\\"')
    str = str:gsub('\n', '\\n')
    str = str:gsub('\r', '\\r')
    str = str:gsub('\t', '\\t')
    -- Remove other control characters (< 0x20)
    str = str:gsub('[%c]', '')
    return str
end

local function add_entry(typ, name, msg)
    init_storage()
    storage.msg_id = storage.msg_id + 1
    table.insert(storage.chat_log, {
        id = storage.msg_id,
        type = typ,
        player = name or "Server",
        message = msg or "",
        tick = game.tick,
        time = get_time()
    })
    while #storage.chat_log > MAX_ENTRIES do
        table.remove(storage.chat_log, 1)
    end
end

script.on_event(defines.events.on_console_chat, function(e)
    if not e.message or e.message == "" then return end
    if e.message:sub(1, 1) == "/" then return end
    
    local name = "Server"
    if e.player_index then
        local p = game.get_player(e.player_index)
        if p and p.valid then
            name = p.name
        end
    end
    add_entry("chat", name, e.message)
end)

script.on_event(defines.events.on_player_joined_game, function(e)
    local p = game.get_player(e.player_index)
    if p and p.valid then
        add_entry("join", p.name, p.name .. " joined")
    end
end)

script.on_event(defines.events.on_player_left_game, function(e)
    local p = game.get_player(e.player_index)
    if p and p.valid then
        add_entry("leave", p.name, p.name .. " left")
    end
end)

script.on_init(function()
    init_storage()
end)

script.on_load(function()
    -- Storage is automatically restored, no init needed
    -- This handler ensures commands work after loading a save
end)

script.on_configuration_changed(function()
    init_storage()
end)

commands.add_command("pelican.chat", "Get recent chat messages as JSON. Optional: number of messages (default 50)", function(cmd)
    init_storage()
    local n = tonumber(cmd.parameter) or 50
    local out = {}
    local start = math.max(1, #storage.chat_log - n + 1)
    for i = start, #storage.chat_log do
        local e = storage.chat_log[i]
        table.insert(out, string.format(
            '{"id":%d,"type":"%s","player":"%s","message":"%s","time":"%s"}',
            e.id, esc(e.type), esc(e.player), esc(e.message), e.time
        ))
    end
    rcon.print('[' .. table.concat(out, ',') .. ']')
end)

commands.add_command("pelican.status", "Get server status (tick, time, players, research, evolution) as JSON", function()
    local count = 0
    for _ in pairs(game.connected_players) do count = count + 1 end
    
    local research = "null"
    local force = game.forces["player"]
    if force and force.current_research then
        research = '"' .. esc(force.current_research.name) .. '"'
    end
    
    -- Evolution factor moved to surface in Factorio 2.0
    local evo = 0
    local surface = game.surfaces[1]
    if surface and surface.get_enemy_evolution then
        -- Factorio 2.0+: evolution is per-surface via get_enemy_evolution
        evo = surface.get_enemy_evolution() or 0
    elseif surface and surface.enemy_evolution then
        -- Alternative property name
        evo = surface.enemy_evolution or 0
    end
    
    rcon.print(string.format(
        '{"tick":%d,"time":"%s","players":%d,"research":%s,"evolution":%.4f}',
        game.tick, get_time(), count, research, evo
    ))
end)

commands.add_command("pelican.players", "Get list of online players as JSON", function()
    local out = {}
    for _, p in pairs(game.connected_players) do
        table.insert(out, string.format('{"name":"%s","admin":%s}', esc(p.name), tostring(p.admin)))
    end
    rcon.print('[' .. table.concat(out, ',') .. ']')
end)

commands.add_command("pelican.say", "Send a message to all players from Server", function(cmd)
    if cmd.parameter and cmd.parameter ~= "" then
        game.print("[Server] " .. cmd.parameter)
        add_entry("server", "Server", cmd.parameter)
        rcon.print('{"ok":true}')
    else
        rcon.print('{"ok":false}')
    end
end)
