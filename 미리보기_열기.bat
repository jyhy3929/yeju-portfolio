@echo off
title Portfolio Preview Server
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
pause
