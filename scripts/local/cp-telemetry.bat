@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Script location:
rem   C:\Projects\radiomaster-boxer\scripts\local
rem Source files:
rem   C:\Projects\radiomaster-boxer\scripts\SCRIPTS\TELEMETRY
rem Destination:
rem   C:\Radiomaster\SCRIPTS\TELEMETRY

set "SCRIPT_DIR=%~dp0"
set "SOURCE_DIR=C:\Projects\radiomaster-boxer\scripts\SCRIPTS\TELEMETRY"
set "DEST_DIR=C:\Radiomaster\SCRIPTS\TELEMETRY"
set /a COPIED=0
set /a ERRORS=0

if not exist "%SCRIPT_DIR%" (
  echo ERROR: Script directory not found: "%SCRIPT_DIR%"
  exit /b 1
)

if not exist "%SOURCE_DIR%\" (
  echo ERROR: Source directory not found: "%SOURCE_DIR%"
  exit /b 2
)

if not exist "%DEST_DIR%\" (
  echo ERROR: Destination directory not found: "%DEST_DIR%"
  exit /b 3
)

if "%~1"=="" (
  echo ERROR: No filenames provided.
  echo Usage: %~nx0 file1.lua [file2.lua ...]
  exit /b 4
)

for %%F in (%*) do (
  set "SRC=%SOURCE_DIR%\%%~nxF"
  set "DST=%DEST_DIR%\%%~nxF"

  if not exist "!SRC!" (
    echo ERROR: File not found: "!SRC!"
    set /a ERRORS+=1
  ) else (
    copy /Y "!SRC!" "!DST!" >nul
    if errorlevel 1 (
      echo ERROR: Failed to copy "%%~nxF"
      set /a ERRORS+=1
    ) else (
      echo Copied: "%%~nxF"
      set /a COPIED+=1
    )
  )
)

echo.
echo Files copied: %COPIED%
echo Errors: %ERRORS%

if %ERRORS% gtr 0 exit /b 10
exit /b 0