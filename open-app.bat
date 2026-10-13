@echo off
rem ---------------------------------------------------------------
rem  Stock Panel - one click launcher
rem  Double click: starts the local server if it is not running,
rem  then opens the page in your default browser.
rem  To stop the server, run stop.bat
rem ---------------------------------------------------------------
setlocal
cd /d "%~dp0"

set "PORT=8787"
set "URL=http://127.0.0.1:%PORT%"

set "RUNNING="
for /f "tokens=5" %%p in ('netstat -ano -p tcp ^| findstr /r /c:"LISTENING" ^| findstr ":%PORT%"') do set "RUNNING=%%p"

if not defined RUNNING (
  echo.
  echo   Server is not running. Starting it now...
  echo.
  start "Stock Panel Server" cmd /c "%~dp0start-server.cmd"
  rem Wait for it to come up (max 40s).
  rem NOTE: use ping instead of `timeout` - timeout fails when stdin is redirected.
  for /l %%i in (1,1,40) do (
    if not defined RUNNING (
      for /f "tokens=5" %%p in ('netstat -ano -p tcp ^| findstr /r /c:"LISTENING" ^| findstr ":%PORT%"') do set "RUNNING=%%p"
      if not defined RUNNING ping -n 2 127.0.0.1 >nul
    )
  )
)

if defined RUNNING (
  echo   Server ready. Opening the page...
  start "" "%URL%"
) else (
  echo.
  echo   The server did not start within 40 seconds.
  echo   Check the black window for errors, or port %PORT% may be in use.
  echo.
  pause
  start "" "%URL%"
)
