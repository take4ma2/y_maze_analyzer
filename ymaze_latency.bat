@echo off

echo %1
echo %~dp0

if exist %1 goto EXECUTE else goto USAGE


:EXECUTE
cd /d %~dp0
ruby ymaze.rb %1

goto EXIT

:USAGE
echo "Drag and Drop Y-maze XY data files included directory on this batch file"

:EXIT
pause
