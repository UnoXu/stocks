@echo off
rem ---------------------------------------------------------------
rem  Stock Panel - stop the local server (port 8787)
rem  Your data file is NOT touched.
rem ---------------------------------------------------------------
setlocal

echo.
echo   Looking for a service listening on port 8787...
set "FOUND="
for /f "tokens=5" %%p in ('netstat -ano -p tcp ^| findstr /r /c:"LISTENING" ^| findstr ":8787"') do (
  set "FOUND=1"
  echo   Found PID %%p, stopping it...
  taskkill /PID %%p /F >nul 2>&1
)

if not defined FOUND (
  echo   Nothing is running on port 8787.
) else (
  echo   Stopped. Your data file is untouched.
)
echo.
pause
