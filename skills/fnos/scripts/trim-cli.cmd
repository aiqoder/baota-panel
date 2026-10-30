@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "ARCH=%PROCESSOR_ARCHITECTURE%"
if defined PROCESSOR_ARCHITEW6432 set "ARCH=%PROCESSOR_ARCHITEW6432%"

set "HAS_HOST="
set "HAS_PORT="
set "HAS_SCHEME="
for %%A in (%*) do call :detect_flag "%%~A"

call :reject_media %*
if errorlevel 1 exit /b %errorlevel%

rem 桌面端设置页注入的连接参数：未显式传参时补默认值
set "DEFAULT_ARGS="
if not defined HAS_HOST if not "%FNOS_HOST%"=="" set "DEFAULT_ARGS=--host %FNOS_HOST% "
if not defined HAS_PORT if not "%FNOS_PORT%"=="" set "DEFAULT_ARGS=%DEFAULT_ARGS%--port %FNOS_PORT% "
if not defined HAS_SCHEME if not "%FNOS_SCHEME%"=="" set "DEFAULT_ARGS=%DEFAULT_ARGS%--scheme %FNOS_SCHEME% "

if /I "%ARCH%"=="ARM64" (
  set "TARGET=%SCRIPT_DIR%..\bin\trim-cli-windows-arm64.exe"
) else (
  set "TARGET=%SCRIPT_DIR%..\bin\trim-cli-windows-x64.exe"
)

if not exist "%TARGET%" (
  echo Missing packaged binary: %TARGET% 1>&2
  exit /b 1
)

"%TARGET%" %DEFAULT_ARGS%%*
exit /b %errorlevel%

:detect_flag
set "ARG=%~1"
if /I "%ARG%"=="--host" set "HAS_HOST=1"
if /I "%ARG:~0,7%"=="--host=" set "HAS_HOST=1"
if /I "%ARG%"=="--port" set "HAS_PORT=1"
if /I "%ARG:~0,7%"=="--port=" set "HAS_PORT=1"
if /I "%ARG%"=="--scheme" set "HAS_SCHEME=1"
if /I "%ARG:~0,9%"=="--scheme=" set "HAS_SCHEME=1"
exit /b 0

:reject_media
if "%~1"=="" exit /b 0
set "ARG=%~1"
if /I "%ARG%"=="--host" shift&shift&goto reject_media
if /I "%ARG%"=="--port" shift&shift&goto reject_media
if /I "%ARG%"=="--profile" shift&shift&goto reject_media
if /I "%ARG%"=="--scheme" shift&shift&goto reject_media
if "%ARG:~0,1%"=="-" shift&goto reject_media
if /I "%ARG%"=="media" (
  echo Media commands are not available in this skill package. 1>&2
  exit /b 2
)
exit /b 0
