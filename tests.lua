-- Pelican Chat Logger - Unit Tests
-- Run with: factorio --run-test pelican-chat-logger
-- Or in-game: /c remote.call("pelican_chat_logger_tests", "run_all")

local tests = {}
local test_results = {
    passed = 0,
    failed = 0,
    errors = {}
}

-- ============================================
-- Test Utilities
-- ============================================

local function assert_equals(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s: Expected '%s', got '%s'", message or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "Expected true, got false")
    end
end

local function assert_false(value, message)
    if value then
        error(message or "Expected false, got true")
    end
end

local function assert_nil(value, message)
    if value ~= nil then
        error(message or "Expected nil, got " .. tostring(value))
    end
end

local function assert_not_nil(value, message)
    if value == nil then
        error(message or "Expected non-nil value")
    end
end

local function assert_contains(str, substring, message)
    if not string.find(str, substring, 1, true) then
        error(string.format("%s: '%s' does not contain '%s'", message or "Assertion failed", str, substring))
    end
end

local function run_test(name, test_func)
    local success, err = pcall(test_func)
    if success then
        test_results.passed = test_results.passed + 1
        game.print("[PASS] " .. name, {r=0, g=1, b=0})
    else
        test_results.failed = test_results.failed + 1
        table.insert(test_results.errors, {name = name, error = err})
        game.print("[FAIL] " .. name .. ": " .. tostring(err), {r=1, g=0, b=0})
    end
end

-- ============================================
-- JSON Escape Tests
-- ============================================

-- Recreate json_escape for testing (since local in control.lua)
local function json_escape(str)
    if not str then return "" end
    str = string.gsub(str, '\\', '\\\\')
    str = string.gsub(str, '"', '\\"')
    str = string.gsub(str, '\n', '\\n')
    str = string.gsub(str, '\r', '\\r')
    str = string.gsub(str, '\t', '\\t')
    return str
end

tests.test_json_escape_nil = function()
    local result = json_escape(nil)
    assert_equals("", result, "nil should return empty string")
end

tests.test_json_escape_empty_string = function()
    local result = json_escape("")
    assert_equals("", result, "empty string should return empty string")
end

tests.test_json_escape_simple_string = function()
    local result = json_escape("Hello World")
    assert_equals("Hello World", result, "simple string should remain unchanged")
end

tests.test_json_escape_quotes = function()
    local result = json_escape('Say "Hello"')
    assert_equals('Say \\"Hello\\"', result, "quotes should be escaped")
end

tests.test_json_escape_backslash = function()
    local result = json_escape('path\\to\\file')
    assert_equals('path\\\\to\\\\file', result, "backslashes should be escaped")
end

tests.test_json_escape_newline = function()
    local result = json_escape("line1\nline2")
    assert_equals("line1\\nline2", result, "newlines should be escaped")
end

tests.test_json_escape_tab = function()
    local result = json_escape("col1\tcol2")
    assert_equals("col1\\tcol2", result, "tabs should be escaped")
end

tests.test_json_escape_carriage_return = function()
    local result = json_escape("line1\rline2")
    assert_equals("line1\\rline2", result, "carriage returns should be escaped")
end

tests.test_json_escape_complex = function()
    local result = json_escape('Player said: "Hello!\nNew line\\path"')
    assert_equals('Player said: \\"Hello!\\nNew line\\\\path\\"', result, "complex string should be fully escaped")
end

-- ============================================
-- Timestamp Tests
-- ============================================

-- Recreate get_timestamp for testing
local function get_timestamp_from_tick(tick)
    local seconds = math.floor(tick / 60)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    
    return string.format("%02d:%02d:%02d", hours % 24, minutes % 60, seconds % 60)
end

tests.test_timestamp_zero = function()
    local result = get_timestamp_from_tick(0)
    assert_equals("00:00:00", result, "tick 0 should be 00:00:00")
end

tests.test_timestamp_one_second = function()
    local result = get_timestamp_from_tick(60)  -- 60 ticks = 1 second
    assert_equals("00:00:01", result, "60 ticks should be 00:00:01")
end

tests.test_timestamp_one_minute = function()
    local result = get_timestamp_from_tick(3600)  -- 3600 ticks = 1 minute
    assert_equals("00:01:00", result, "3600 ticks should be 00:01:00")
end

tests.test_timestamp_one_hour = function()
    local result = get_timestamp_from_tick(216000)  -- 216000 ticks = 1 hour
    assert_equals("01:00:00", result, "216000 ticks should be 01:00:00")
end

tests.test_timestamp_wrap_24h = function()
    local result = get_timestamp_from_tick(5184000)  -- 24 hours worth of ticks
    assert_equals("00:00:00", result, "24 hours should wrap to 00:00:00")
end

tests.test_timestamp_complex = function()
    -- 2 hours, 30 minutes, 45 seconds = 2*216000 + 30*3600 + 45*60 = 543900 ticks
    local result = get_timestamp_from_tick(543900)
    assert_equals("02:30:45", result, "543900 ticks should be 02:30:45")
end

-- ============================================
-- Entry to JSON Tests
-- ============================================

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

tests.test_entry_to_json_basic = function()
    local entry = {
        id = 1,
        type = "chat",
        player = "TestPlayer",
        message = "Hello",
        color = "white",
        tick = 1000,
        time = "00:00:16"
    }
    local result = entry_to_json(entry)
    assert_contains(result, '"id":1', "should contain id")
    assert_contains(result, '"type":"chat"', "should contain type")
    assert_contains(result, '"player":"TestPlayer"', "should contain player")
    assert_contains(result, '"message":"Hello"', "should contain message")
    assert_contains(result, '"color":"white"', "should contain color")
    assert_contains(result, '"tick":1000', "should contain tick")
end

tests.test_entry_to_json_special_chars = function()
    local entry = {
        id = 2,
        type = "chat",
        player = "Test\"Player",
        message = "Line1\nLine2",
        color = "cyan",
        tick = 2000,
        time = "00:00:33"
    }
    local result = entry_to_json(entry)
    assert_contains(result, 'Test\\"Player', "player name with quotes should be escaped")
    assert_contains(result, 'Line1\\nLine2', "message with newline should be escaped")
end

-- ============================================
-- Storage / Chat Log Tests (Integration)
-- ============================================

tests.test_remote_interface_exists = function()
    assert_not_nil(remote.interfaces["pelican_chat_logger"], "Remote interface should exist")
end

tests.test_remote_get_messages = function()
    if not remote.interfaces["pelican_chat_logger"] then
        error("Remote interface not available")
    end
    
    local messages = remote.call("pelican_chat_logger", "get_messages", 10)
    assert_not_nil(messages, "get_messages should return a table")
    assert_true(type(messages) == "table", "get_messages should return a table")
end

tests.test_remote_clear = function()
    if not remote.interfaces["pelican_chat_logger"] then
        error("Remote interface not available")
    end
    
    -- Clear and check
    remote.call("pelican_chat_logger", "clear")
    local messages = remote.call("pelican_chat_logger", "get_messages", 100)
    assert_equals(0, #messages, "clear should empty the chat log")
end

tests.test_remote_server_message = function()
    if not remote.interfaces["pelican_chat_logger"] then
        error("Remote interface not available")
    end
    
    -- Clear first
    remote.call("pelican_chat_logger", "clear")
    
    -- Add server message
    remote.call("pelican_chat_logger", "server_message", "Test message from unit test")
    
    -- Check it was added
    local messages = remote.call("pelican_chat_logger", "get_messages", 10)
    assert_equals(1, #messages, "should have one message after server_message")
    assert_equals("server", messages[1].type, "message type should be 'server'")
    assert_equals("Server", messages[1].player, "player should be 'Server'")
    assert_contains(messages[1].message, "Test message from unit test", "message content should match")
end

-- ============================================
-- Max Entries Limit Test
-- ============================================

tests.test_max_entries_limit = function()
    if not remote.interfaces["pelican_chat_logger"] then
        error("Remote interface not available")
    end
    
    -- Clear first
    remote.call("pelican_chat_logger", "clear")
    
    -- Add 110 messages (limit is 100)
    for i = 1, 110 do
        remote.call("pelican_chat_logger", "server_message", "Message " .. i)
    end
    
    -- Check only 100 are kept
    local messages = remote.call("pelican_chat_logger", "get_messages", 200)
    assert_true(#messages <= 100, "should not exceed max_entries limit of 100, got " .. #messages)
    
    -- First message should be Message 11 (first 10 were trimmed)
    if #messages == 100 then
        assert_contains(messages[1].message, "Message 11", "oldest message should be Message 11")
    end
end

-- ============================================
-- Test Runner
-- ============================================

local function run_all_tests()
    test_results.passed = 0
    test_results.failed = 0
    test_results.errors = {}
    
    game.print("========================================", {r=0.5, g=0.5, b=1})
    game.print("Pelican Chat Logger - Running Tests", {r=0.5, g=0.5, b=1})
    game.print("========================================", {r=0.5, g=0.5, b=1})
    
    -- Run all tests
    for name, test_func in pairs(tests) do
        if type(test_func) == "function" then
            run_test(name, test_func)
        end
    end
    
    -- Summary
    game.print("========================================", {r=0.5, g=0.5, b=1})
    game.print(string.format("Results: %d passed, %d failed", test_results.passed, test_results.failed), 
        test_results.failed == 0 and {r=0, g=1, b=0} or {r=1, g=0, b=0})
    game.print("========================================", {r=0.5, g=0.5, b=1})
    
    return test_results
end

-- Remote interface for running tests
remote.add_interface("pelican_chat_logger_tests", {
    run_all = run_all_tests,
    
    run_single = function(test_name)
        if tests[test_name] then
            run_test(test_name, tests[test_name])
        else
            game.print("Test not found: " .. test_name, {r=1, g=0.5, b=0})
        end
    end,
    
    list_tests = function()
        game.print("Available tests:", {r=0.5, g=0.5, b=1})
        for name, _ in pairs(tests) do
            game.print("  - " .. name)
        end
    end
})

-- Auto-run tests on mod startup in test mode
-- Check if we're in test mode by looking for a specific command
commands.add_command("pelican.test", "Run Pelican Chat Logger unit tests", function(cmd)
    if cmd.parameter == "list" then
        remote.call("pelican_chat_logger_tests", "list_tests")
    elseif cmd.parameter and cmd.parameter ~= "" then
        remote.call("pelican_chat_logger_tests", "run_single", cmd.parameter)
    else
        remote.call("pelican_chat_logger_tests", "run_all")
    end
end)
