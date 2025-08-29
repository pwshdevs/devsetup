@echo off
REM Check for PowerShell Core (pwsh.exe) first
pwsh.exe -Command "Exit 0" >nul 2>&1
if %errorlevel% neq 0 goto check_windows_ps
pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Force; & '%~dp0install.ps1'"
goto end

:check_windows_ps

REM Check for Windows PowerShell using where command first
where powershell.exe >nul 2>&1
if %errorlevel% neq 0 goto check_full_path
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Force; & '%~dp0install.ps1'"
goto end

:check_full_path

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -Command "Exit 0" >nul 2>&1
if %errorlevel% neq 0 goto no_powershell
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Force; & '%~dp0install.ps1'"
goto end

:no_powershell
echo ERROR: No PowerShell installation found!
echo Please install either PowerShell Core or Windows PowerShell.
echo Installation cannot continue without PowerShell.
exit /b 1

:end