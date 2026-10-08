@echo off
chcp 65001 >nul
title 생기부 면접 준비기
cd /d "%~dp0"

where node >nul 2>nul
if %errorlevel%==0 (
  node server.js
) else (
  echo Node.js가 없어 윈도우 기본 PowerShell 서버로 실행합니다.
  powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0server.ps1"
)

echo.
echo 앱이 종료되었습니다. 아무 키나 누르면 창이 닫힙니다.
pause >nul
