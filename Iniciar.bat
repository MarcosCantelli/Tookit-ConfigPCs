@echo off
REM Iniciar.bat - atalho pra rodar o toolkit sem precisar lembrar o comando do PowerShell.
REM Basta dar dois cliques (ou "Executar como administrador" se quiser pular o prompt do UAC).

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
pause
