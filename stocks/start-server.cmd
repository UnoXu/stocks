@echo off
rem ---------------------------------------------------------------
rem  Stock Panel - start the server (no pause, safe for autostart)
rem  For an interactive start that pauses on error, use start.bat
rem ---------------------------------------------------------------
setlocal
cd /d "%~dp0"

set "NODE=%USERPROFILE%\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\node\bin\node.exe"
if not exist "%NODE%" set "NODE=node"

"%NODE%" server.mjs
