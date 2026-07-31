-- Map new Vector PascalCase APIs onto the snake_case names April uses everywhere.
-- Safe to call every frame — assignment is cheap and idempotent.

local M = {}

local function alias(tbl, snake, pascal)
    if not tbl then return end
    if tbl[snake] == nil and tbl[pascal] ~= nil then
        tbl[snake] = tbl[pascal]
    end
    if tbl[pascal] == nil and tbl[snake] ~= nil then
        tbl[pascal] = tbl[snake]
    end
end

function M.apply()
    if entity then
        alias(entity, "get_players", "GetPlayers")
        alias(entity, "get_local_player", "GetLocalPlayer")
        alias(entity, "get_player_count", "GetPlayerCount")
    end

    if draw then
        alias(draw, "line", "Line")
        alias(draw, "rect", "Rect")
        alias(draw, "rect_filled", "RectFilled")
        alias(draw, "circle", "Circle")
        alias(draw, "circle_filled", "CircleFilled")
        alias(draw, "text", "Text")
        alias(draw, "get_text_size", "GetTextSize")
        alias(draw, "box", "Box")
        alias(draw, "corner_box", "CornerBox")
        alias(draw, "health_bar", "HealthBar")
        alias(draw, "world_to_screen", "WorldToScreen")
        alias(draw, "get_screen_size", "GetScreenSize")
        alias(draw, "poly", "Poly")
        alias(draw, "poly_closed", "PolyClosed")
        alias(draw, "poly_filled", "PolyFilled")
        alias(draw, "compute_hull", "ComputeHull")
        alias(draw, "chams_player", "ChamsPlayer")
        alias(draw, "chams", "Chams")
        alias(draw, "get_player_hulls", "GetPlayerHulls")
        alias(draw, "load_image", "LoadImage")
        alias(draw, "image", "Image")
        alias(draw, "image_loaded", "ImageLoaded")
        alias(draw, "image_failed", "ImageFailed")
        alias(draw, "image_size", "ImageSize")
        alias(draw, "free_image", "FreeImage")
        alias(draw, "window", "Window")
        -- Legacy wrong names some April code used
        if draw.filled_rect == nil then
            draw.filled_rect = draw.rect_filled or draw.RectFilled
        end
        if draw.filled_circle == nil then
            draw.filled_circle = draw.circle_filled or draw.CircleFilled
        end
    end

    if utility then
        alias(utility, "world_to_screen", "WorldToScreen")
        alias(utility, "get_screen_size", "GetScreenSize")
        alias(utility, "get_mouse_pos", "GetMousePos")
        alias(utility, "get_tick_count", "GetTickCount")
        alias(utility, "get_delta_time", "GetDeltaTime")
        alias(utility, "is_valid", "IsValid")
        alias(utility, "load_url", "LoadUrl")
        alias(utility, "http_get", "HttpGet")
    end

    if input then
        alias(input, "is_key_down", "IsKeyDown")
        alias(input, "is_mouse_down", "IsMouseDown")
    end

    if game then
        alias(game, "local_player", "LocalPlayer")
        alias(game, "players", "Players")
        alias(game, "workspace", "Workspace")
        alias(game, "get_service", "GetService")
    end
end

return M
