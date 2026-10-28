@echo off
setlocal

rem Run from the folder containing this script (the project root).
cd /d "%~dp0"

rem Use FLUTTER_ROOT if set, otherwise flutter from PATH.
if defined FLUTTER_ROOT (
  set "FLUTTER=%FLUTTER_ROOT%\bin\flutter.bat"
) else (
  for %%i in (flutter.bat) do set "FLUTTER=%%~$PATH:i"
)
if not exist "%FLUTTER%" (
  echo Flutter not found: add it to PATH or set FLUTTER_ROOT.
  exit /b 1
)

echo Build started %date% %time% > build_apk.log
call "%FLUTTER%" pub get >> build_apk.log 2>&1
if errorlevel 1 goto done
call "%FLUTTER%" build apk --release >> build_apk.log 2>&1

:done
set "CODE=%ERRORLEVEL%"
echo EXIT CODE %CODE% >> build_apk.log
echo Build finished with exit code %CODE%, see build_apk.log
exit /b %CODE%
