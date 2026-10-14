@echo off
setlocal
title EventDock Full Stack Runner
echo ==========================================================
echo              EventDock Full Stack Runner                  
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-all.ps1"
echo.
pause
