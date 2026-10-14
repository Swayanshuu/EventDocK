@echo off
title Stop EventDock Services
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop-all.ps1"
pause
