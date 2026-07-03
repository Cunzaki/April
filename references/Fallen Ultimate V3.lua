--[[
    Fallen Ultimate V3 — Volt entry
    IMPORTANT: Volt loads from %LOCALAPPDATA%\Volt\workspace\fallen-v3\
    NOT from this Desktop repo. After EVERY edit, deploy first:

      powershell -ExecutionPolicy Bypass -File tools/deploy_volt.ps1

    Or keep auto-deploy running while testing:

      powershell -ExecutionPolicy Bypass -File tools/watch_deploy.ps1

    In Volt console you should see: [Fallen Ultimate V3] UI build: sidebar-v3
    If you see the old top-tab menu, deploy was not run (or you loaded a stale script).
]]
getgenv().FallenV3 = getgenv().FallenV3 or {}
FallenV3.src = FallenV3.src or "fallen-v3/src/"

loadstring(readfile("fallen-v3/loader/loader.lua"), "FallenV3-loader")()
