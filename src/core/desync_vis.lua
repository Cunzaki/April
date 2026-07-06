--[[ Shared 3D desync / manipulation visualizer helpers. ]]

local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")

local M = {}

function M.draw_box(wx, wy, wz, size, col, thick)
    if not wx then return end
    size = size or 1.2
    thick = thick or 2
    local s = size

    esp_util.draw_world_line(wx - s, wy - s, wz - s, wx + s, wy - s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz - s, wx + s, wy - s, wz + s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz + s, wx - s, wy - s, wz + s, col, thick)
    esp_util.draw_world_line(wx - s, wy - s, wz + s, wx - s, wy - s, wz - s, col, thick)
    esp_util.draw_world_line(wx - s, wy + s, wz - s, wx + s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy + s, wz - s, wx + s, wy + s, wz + s, col, thick)
    esp_util.draw_world_line(wx + s, wy + s, wz + s, wx - s, wy + s, wz + s, col, thick)
    esp_util.draw_world_line(wx - s, wy + s, wz + s, wx - s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx - s, wy - s, wz - s, wx - s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz - s, wx + s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz + s, wx + s, wy + s, wz + s, col, thick)
    esp_util.draw_world_line(wx - s, wy - s, wz + s, wx - s, wy + s, wz + s, col, thick)
end

function M.draw_cross(wx, wy, wz, size, col, thick)
    if not wx then return end
    size = size or 1.5
    thick = thick or 2
    esp_util.draw_world_line(wx - size, wy, wz, wx + size, wy, wz, col, thick)
    esp_util.draw_world_line(wx, wy - size, wz, wx, wy + size, wz, col, thick)
    esp_util.draw_world_line(wx, wy, wz - size, wx, wy, wz + size, col, thick)
end

function M.draw_sphere_ring(wx, wy, wz, radius, col, thick)
    if not wx then return end
    radius = radius or 1.5
    thick = thick or 2
    local steps = 16
    local prev_sx, prev_sy, prev_vis
    for i = 0, steps do
        local a = (i / steps) * math.pi * 2
        local px = wx + math.cos(a) * radius
        local pz = wz + math.sin(a) * radius
        local sx, sy, vis = esp_util.w2s(px, wy, pz)
        if vis and prev_vis then
            draw_util.line(prev_sx, prev_sy, sx, sy, col, thick)
        end
        prev_sx, prev_sy, prev_vis = sx, sy, vis
    end
end

function M.draw_link(a, b, col, thick)
    if not a or not b then return end
    esp_util.draw_world_line(a.x, a.y, a.z, b.x, b.y, b.z, col, thick or 2)
end

function M.draw_labeled(wx, wy, wz, label, col, size)
    if not wx or not label then return end
    local sx, sy, vis = esp_util.w2s(wx, wy + 2, wz)
    if vis then
        draw_util.text_centered(sx, sy, label, col, size or 13)
    end
end

function M.draw_mode(mode, wx, wy, wz, size, col, thick)
    mode = mode or 0
    if mode == 1 then
        M.draw_cross(wx, wy, wz, size, col, thick)
    elseif mode == 2 then
        M.draw_sphere_ring(wx, wy, wz, size, col, thick)
    else
        M.draw_box(wx, wy, wz, size, col, thick)
    end
end

function M.draw_server_local(server, local_pos, opts)
    if not server or not local_pos then return end
    opts = opts or {}

    local mode = opts.mode or 0
    local size = opts.size or 1.2
    local col_server = opts.col_server or { 0.2, 0.85, 1, 0.9 }
    local col_local = opts.col_local or { 1, 0.35, 0.35, 0.9 }
    local col_link = opts.col_link or { 1, 1, 1, 0.4 }
    local server_label = opts.server_label or "SERVER"
    local local_label = opts.local_label or "LOCAL"

    M.draw_mode(mode, server.x, server.y, server.z, size, col_server, 2)
    M.draw_mode(mode, local_pos.x, local_pos.y, local_pos.z, size * 0.85, col_local, 2)

    if opts.link ~= false then
        M.draw_link(server, local_pos, col_link, 2)
    end

    if opts.labels then
        M.draw_labeled(server.x, server.y, server.z, server_label, col_server, 12)
        M.draw_labeled(local_pos.x, local_pos.y, local_pos.z, local_label, col_local, 12)
    end
end

return M
