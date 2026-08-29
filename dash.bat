@echo off
REM 브랜드 경영 현황판 - 더블클릭하면 로컬 서버 실행 + 브라우저 열기
cd /d "%~dp0"
start "브랜드 현황판 서버" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Minimized -File "%~dp0dashboard-server.ps1"
timeout /t 2 /nobreak >nul
start "" "http://localhost:8090/"
exit
