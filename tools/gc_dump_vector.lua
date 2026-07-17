--[[
    Fallen Survival — full GC dump + static dump/ merge (Vector external)

    BEFORE FIRST RUN:
      node tools/build_gc_static_catalog.mjs

    WHAT THIS DOES (in order):
      1. Warmup countdown (join game, spawn, optionally equip gun)
      2. require() all ReplicatedStorage.Modules.* from dump catalog → loads ToolInfo/Items into heap
      3. dumpgc() full live heap → gc_dump.txt
      4. dumpgc(key_seeds) targeted pass → gc_dump.targeted.txt (extra tables keyed by dump research)
      5. Appends tools/gc_static_appendix.txt (items, weapons, remotes, all static keys from dump/)

    Vector has NO task — uses thread.create.
]]

local OUTPUT = "C:/Users/Cunza/Desktop/Vector Fallen V2/gc_dump.txt"
local TARGETED_OUTPUT = "C:/Users/Cunza/Desktop/Vector Fallen V2/gc_dump.targeted.txt"
local STATIC_APPENDIX = "C:/Users/Cunza/Desktop/Vector Fallen V2/tools/gc_static_appendix.txt"
local KEY_SEEDS_FILE = "C:/Users/Cunza/Desktop/Vector Fallen V2/tools/gc_key_seeds.lua"
local PRELOAD_FILE = "C:/Users/Cunza/Desktop/Vector Fallen V2/tools/gc_preload_modules.lua"

local WARMUP = 25
local SKIP_REFRESH = true
local RUN_TARGETED_PASS = true
local PRELOAD_MODULES = true

if type(dumpgc) ~= "function" then
    error("dumpgc missing — run from Vector external")
end
if not thread or type(thread.create) ~= "function" then
    error("thread.create missing — run from Vector external")
end

local function log(msg)
    print("[gc] " .. msg)
end

local function append_file(dest, src)
    local rf = io.open(src, "r")
    if not rf then
        log("skip append — missing " .. src)
        return false
    end
    local body = rf:read("*a")
    rf:close()
    local wf = io.open(dest, "a")
    if not wf then
        log("skip append — cannot open " .. dest)
        return false
    end
    wf:write("\n")
    wf:write(body)
    wf:close()
    return true
end

local function load_string_list(path)
    -- Vector inline scripts have no loadfile — parse "..." lines via io.open
    if not io or not io.open then
        log("io.open unavailable")
        return nil
    end
    local f = io.open(path, "r")
    if not f then
        log("cannot open " .. path)
        return nil
    end
    local text = f:read("*a")
    f:close()
    local list = {}
    for item in string.gmatch(text, '"([^"]+)"') do
        list[#list + 1] = item
    end
    if #list == 0 then
        log("no quoted entries in " .. path)
        return nil
    end
    return list
end

-- Minimal fallback if catalog files missing (run: node tools/build_gc_static_catalog.mjs)
local FALLBACK_PRELOAD = {
    "ToolInfo", "Items", "ArmorModule", "BenchInfo", "RecipeModule",
    "ResearchModule", "RaycastUtil", "ItemClass", "StatusClass",
    "BasePartInfo", "SettingsModule", "SoundModule", "NumberUtil", "TableUtil",
}

local function require_module_path(rel)
    local node = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
    if not node then
        return false, "Modules folder missing"
    end
    for part in string.gmatch(rel, "[^%.]+") do
        node = node:FindFirstChild(part)
        if not node then
            return false, "missing " .. part
        end
    end
    if not node:IsA("ModuleScript") then
        return false, "not ModuleScript"
    end
    return pcall(require, node)
end

local function preload_catalog()
    if not PRELOAD_MODULES then
        return
    end
    local list = load_string_list(PRELOAD_FILE) or FALLBACK_PRELOAD
    if list == FALLBACK_PRELOAD then
        log("using fallback preload — run: node tools/build_gc_static_catalog.mjs")
    end
    log("preloading " .. #list .. " modules from dump catalog...")
    local ok_n, fail_n = 0, 0
    for _, rel in ipairs(list) do
        local ok = require_module_path(rel)
        if ok then
            ok_n = ok_n + 1
        else
            fail_n = fail_n + 1
        end
    end
    log(string.format("preload done — ok %d, fail %d", ok_n, fail_n))
end

local function run_dump()
    preload_catalog()

    if not SKIP_REFRESH and type(refreshgc) == "function" then
        log("refreshgc...")
        pcall(refreshgc)
    end

    log("full dumpgc -> " .. OUTPUT)
    local n_full = dumpgc(OUTPUT)
    log(string.format("full dump: %s entries/lines", tostring(n_full)))

    if RUN_TARGETED_PASS then
        local seeds = load_string_list(KEY_SEEDS_FILE)
        if seeds and #seeds > 0 then
            log(string.format("targeted dumpgc (%d keys) -> %s", #seeds, TARGETED_OUTPUT))
            local n_tgt = dumpgc(seeds, TARGETED_OUTPUT)
            log(string.format("targeted dump: %s entries/lines", tostring(n_tgt)))
            if append_file(OUTPUT, TARGETED_OUTPUT) then
                log("merged targeted pass into gc_dump.txt")
            end
        else
            log("no key seeds — run: node tools/build_gc_static_catalog.mjs")
        end
    end

    if append_file(OUTPUT, STATIC_APPENDIX) then
        log("appended static dump/ catalog")
    else
        log("static appendix missing — run: node tools/build_gc_static_catalog.mjs")
    end

    log("DONE -> " .. OUTPUT)
end

local remaining = WARMUP
log(string.format("join + spawn, then dump in %ds (equip gun for attachment GC nodes)", remaining))

local countdown_id
countdown_id = thread.create(function()
    remaining = remaining - 1
    if remaining > 0 then
        log(string.format("starting in %ds...", remaining))
        return
    end
    thread.stop(countdown_id)
    run_dump()
end, 1000)
