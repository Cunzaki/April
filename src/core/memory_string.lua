local env = April.require("core.env")

local M = {}

local CHUNK = 65536
local ANCHOR_RADIUS = 1024 * 1024
local HEAP_SCAN_SIZE = 32 * 1024 * 1024
local MAX_HITS = 128

local function has_memory()
    return memory and type(memory.read_buffer) == "function"
        and type(memory.write) == "function"
end

function M.available()
    return has_memory()
end

function M.instance_addr(inst)
    if not inst then return nil end
    local addr = inst.Address or inst.address
    if type(addr) == "number" and addr > 0 then return addr end
    return nil
end

function M.utf16_bytes(ascii)
    if not ascii or ascii == "" then return "" end
    local out = {}
    for i = 1, #ascii do
        out[#out + 1] = string.char(string.byte(ascii, i))
        out[#out + 1] = string.char(0)
    end
    return table.concat(out)
end

function M.scan_buffer(buf, needle, base_addr, hits, max_hits)
    if not buf or buf == "" or not needle or needle == "" then return hits end
    max_hits = max_hits or MAX_HITS
    hits = hits or {}

    local pos = 1
    while #hits < max_hits do
        local found = buf:find(needle, pos, true)
        if not found then break end
        hits[#hits + 1] = { addr = base_addr + found - 1, enc = needle:find(string.char(0), 1, true) and "utf16" or "ascii" }
        pos = found + 1
    end
    return hits
end

function M.scan_range(start_addr, size, needle, max_hits, enc)
    local hits = {}
    if not has_memory() or not start_addr or start_addr <= 0 then return hits end
    if not needle or #needle < 2 then return hits end

    max_hits = max_hits or MAX_HITS
    size = math.max(256, math.min(size or ANCHOR_RADIUS, HEAP_SCAN_SIZE))
    local overlap = math.min(#needle + 4, 256)
    local offset = 0

    while offset < size and #hits < max_hits do
        local read_size = math.min(CHUNK, size - offset)
        local buf = memory.read_buffer(start_addr + offset, read_size)
        if buf and buf ~= "" then
            M.scan_buffer(buf, needle, start_addr + offset, hits, max_hits)
            for i = 1, #hits do
                hits[i].enc = enc or hits[i].enc or "ascii"
            end
        end
        if read_size <= overlap then break end
        offset = offset + read_size - overlap
    end

    return hits
end

function M.try_engine_scan(needle, max_hits)
    if not needle or needle == "" then return {} end
    for _, fn_name in ipairs({ "scan_string", "find_string", "search_string" }) do
        local fn = memory and memory[fn_name]
        if type(fn) == "function" then
            for _, args in ipairs({ { needle }, { needle, true }, { needle, false } }) do
                local ok, result = pcall(fn, unpack(args))
                if ok and type(result) == "table" then
                    local hits = {}
                    for i = 1, math.min(#result, max_hits or MAX_HITS) do
                        local addr = result[i]
                        if type(addr) == "number" and addr > 0 then
                            hits[#hits + 1] = { addr = addr, enc = "ascii" }
                        elseif type(addr) == "table" and type(addr.addr or addr.address) == "number" then
                            hits[#hits + 1] = { addr = addr.addr or addr.address, enc = addr.enc or "ascii" }
                        end
                    end
                    if #hits > 0 then return hits end
                end
            end
        end
    end
    return {}
end

function M.collect_anchors()
    local anchors = {}
    local seen = {}

    local function add(addr, radius)
        if not addr or addr <= 0 or seen[addr] then return end
        seen[addr] = true
        anchors[#anchors + 1] = { addr = addr, radius = radius or ANCHOR_RADIUS }
    end

    if memory and memory.base and memory.base > 0 then
        add(memory.base, HEAP_SCAN_SIZE)
    end

    if game then
        add(M.instance_addr(game.workspace), ANCHOR_RADIUS)
        add(M.instance_addr(game.players), ANCHOR_RADIUS * 2)
        add(M.instance_addr(game.local_player), ANCHOR_RADIUS * 2)

        local core = env.safe_call(function() return game.get_service("CoreGui") end)
        add(M.instance_addr(core), ANCHOR_RADIUS)

        local starter = env.safe_call(function() return game.get_service("StarterGui") end)
        add(M.instance_addr(starter), ANCHOR_RADIUS)
    end

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if p.is_local then
                add(M.instance_addr(p.player), ANCHOR_RADIUS * 2)
                add(M.instance_addr(p.character), ANCHOR_RADIUS)
                add(M.instance_addr(p.humanoid), ANCHOR_RADIUS)
            end
        end
    end

    local lp = env.get_local_player()
    if lp then
        add(M.instance_addr(lp.player), ANCHOR_RADIUS * 2)
        add(M.instance_addr(lp.character), ANCHOR_RADIUS)
    end

    return anchors
end

function M.find_string_variants(text, max_hits)
    if not has_memory() or not text or #text < 2 then return {} end

    local variants = {
        { needle = text, enc = "ascii" },
        { needle = M.utf16_bytes(text), enc = "utf16" },
    }

    if not text:find("@", 1, true) then
        variants[#variants + 1] = { needle = "@" .. text, enc = "ascii" }
        variants[#variants + 1] = { needle = M.utf16_bytes("@" .. text), enc = "utf16" }
    end

    local hits = {}
    local seen_addr = {}

    local function merge(list)
        for i = 1, #list do
            local hit = list[i]
            local addr = type(hit) == "table" and hit.addr or hit
            local enc = type(hit) == "table" and hit.enc or "ascii"
            if addr and not seen_addr[addr] then
                seen_addr[addr] = true
                hits[#hits + 1] = { addr = addr, enc = enc }
                if #hits >= (max_hits or MAX_HITS) then return true end
            end
        end
        return false
    end

    for i = 1, #variants do
        local v = variants[i]
        if merge(M.try_engine_scan(v.needle, max_hits)) then return hits end
    end

    for i = 1, #variants do
        local v = variants[i]
        for _, anchor in ipairs(M.collect_anchors()) do
            if merge(M.scan_range(anchor.addr, anchor.radius, v.needle, max_hits, v.enc)) then
                return hits
            end
        end
    end

    return hits
end

function M.find_string(needle, max_hits)
    local hits = M.find_string_variants(needle, max_hits)
    local out = {}
    for i = 1, #hits do
        out[i] = hits[i].addr
    end
    return out
end

M._heap_offset = 0
M._heap_needle = ""

function M.reset_heap_scan()
    M._heap_offset = 0
    M._heap_needle = ""
end

function M.heap_scan_step(needle, bytes_per_tick, max_hits)
    if not has_memory() or not memory.base or memory.base <= 0 then return {} end
    if not needle or #needle < 2 then return {} end

    if needle ~= M._heap_needle then
        M._heap_needle = needle
        M._heap_offset = 0
    end

    local hits = {}
    local budget = bytes_per_tick or (512 * 1024)
    local scanned = 0

    while M._heap_offset < HEAP_SCAN_SIZE and scanned < budget and #hits < (max_hits or 16) do
        local size = math.min(CHUNK, HEAP_SCAN_SIZE - M._heap_offset)
        local start = memory.base + M._heap_offset
        local buf = memory.read_buffer(start, size) or ""
        for _, v in ipairs({
            { needle = needle, enc = "ascii" },
            { needle = M.utf16_bytes(needle), enc = "utf16" },
        }) do
            local before = #hits
            M.scan_buffer(buf, v.needle, start, hits, max_hits)
            for j = before + 1, #hits do
                hits[j].enc = v.enc
            end
        end
        scanned = scanned + size
        M._heap_offset = M._heap_offset + size - math.min(#needle + 4, 128)
    end

    if M._heap_offset >= HEAP_SCAN_SIZE then
        M._heap_offset = 0
    end

    return hits
end

function M.read_at(addr, max_len, enc)
    if not has_memory() or not addr or addr <= 0 then return "" end
    if enc == "utf16" then
        local buf = memory.read_buffer(addr, math.min((max_len or 64) * 2, 512))
        if not buf or buf == "" then return "" end
        local chars = {}
        for i = 1, #buf - 1, 2 do
            local b = string.byte(buf, i)
            if b == 0 then break end
            chars[#chars + 1] = string.char(b)
        end
        return table.concat(chars)
    end
    return memory.read_string(addr, max_len or 256) or ""
end

function M.write_bytes(addr, data)
    if not has_memory() or not addr or addr <= 0 or not data then return false end
    for i = 1, #data do
        local ok = pcall(memory.write, addr + i - 1, "uint8", string.byte(data, i))
        if not ok then return false end
    end
    return true
end

function M.write_at(addr, text, max_len, enc)
    if not has_memory() or not addr or addr <= 0 or not text then return false end

    if enc == "utf16" then
        local bytes = M.utf16_bytes(text)
        local limit = (max_len or #text) * 2
        if #bytes > limit then
            bytes = bytes:sub(1, limit)
        end
        bytes = bytes .. string.char(0, 0)
        return M.write_bytes(addr, bytes)
    end

    return pcall(memory.write_string, addr, text, max_len)
end

function M.random_alias(length)
    length = math.max(3, math.min(length or 12, 20))
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local n = #chars
    local out = {}
    for i = 1, length do
        local r = math.random(1, n)
        out[i] = chars:sub(r, r)
    end
    return table.concat(out)
end

function M.pad_alias(alias, target_len)
    target_len = math.max(1, target_len or #alias)
    if #alias >= target_len then
        return alias:sub(1, target_len)
    end
    return alias .. string.rep("_", target_len - #alias)
end

return M
