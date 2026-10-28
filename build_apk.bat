@echo off
cd /d D:\aura
echo Build started %date% %time% > build_apk.log
call C:\sdk\flutter\bin\flutter.bat pub get >> build_apk.log 2>&1
call C:\sdk\flutter\bin\flutter.bat build apk --release >> build_apk.log 2>&1
echo EXIT CODE %ERRORLEVEL% >> build_apk.log
