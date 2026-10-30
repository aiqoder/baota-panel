@echo off
rem ops.cmd — Windows 包装：定位包内 sshpass(windows) 并调用 lib/ops.ps1
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%lib\ops.ps1"

if not exist "%PS1%" (
  echo Missing packaged script: %PS1% 1>&2
  exit /b 1
)

where powershell >nul 2>&1
if errorlevel 1 (
  echo PowerShell not found. Windows 10+ should ship it. 1>&2
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %errorlevel%
