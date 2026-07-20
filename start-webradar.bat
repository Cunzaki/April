@echo off
title April Web Radar
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
    echo.
    echo   Node.js was not found in PATH.
    echo   Install it from https://nodejs.org then run this again.
    echo.
    pause
    exit /b 1
)

echo.
echo   April Web Radar
echo   Any old server on port 8765 will be closed automatically.
echo   Keep this window open while using the radar.
echo.
node "%~dp0web-radar\server.mjs"
pause
