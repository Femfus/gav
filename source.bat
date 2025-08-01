@echo off
setlocal EnableDelayedExpansion

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    echo Press any key to exit...
    pause >nul
    exit /b
)

echo Running with administrator privileges.
echo.

REM Check if Defender is already disabled
REG QUERY "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware >nul 2>&1
if !errorlevel! == 0 (
    REG QUERY "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" | findstr /i "DisableAntiSpyware" | findstr "0x1" >nul
    if !errorlevel! == 0 (
        echo Windows Defender is already disabled via registry.
        echo Press any key to exit...
        pause >nul
        goto :EOF
    )
)

echo =====================================================
echo WARNING: This action will disable Windows Defender.
echo This is NOT recommended unless you know what you're doing.
echo Proceed at your own risk.
echo =====================================================
echo.

set /p choice=Do you still want to disable Defender? (Y/N): 
if /i not "%choice%"=="Y" (
    echo Operation cancelled.
    echo Press any key to exit...
    pause >nul
    goto :EOF
)

echo Disabling Windows Defender...

REM Disable via registry
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f

REM Try to stop Defender services (limited effect on Windows 10/11)
sc stop WinDefend >nul 2>&1
taskkill /f /im "MsMpEng.exe" >nul 2>&1

REM Create re-enable script
> enable_av.bat (
    echo @echo off
    echo :: === Auto-elevate on run ===
    echo net session ^>nul 2^>^&1
    echo if %%errorlevel%% NEQ 0 (
    echo.    powershell -Command "Start-Process '%%~f0' -Verb RunAs"
    echo.    exit /b
    echo )
    echo echo Re-enabling Windows Defender...
    echo REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /f
    echo REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /f
    echo sc start WinDefend ^>nul 2^>^&1
    echo echo Windows Defender should now be enabled. A reboot may be required.
    echo pause
)

echo Defender has been disabled. Run enable_av.bat to restore it.
echo Press any key to exit...
pause >nul
