@echo off
chcp 65001 >nul
cd /d "%~dp0"
set PORT=18900

echo.
echo  ============================================
echo   3D Town Viewer  -  Interactive 3D Scene
echo  ============================================
echo.
echo   Starting local server on port %PORT% ...
echo   Combined (town + chibi): http://localhost:%PORT%/viewer_combined.html
echo   Town only:               http://localhost:%PORT%/viewer.html
echo.
echo   Keep this window OPEN. Close it to stop the server.
echo.

where python3 >nul 2>nul
if %errorlevel%==0 goto PYOK
where python >nul 2>nul
if %errorlevel%==0 goto PYOK2

echo   ERROR: Python 3 not found on PATH.
echo   Install Python 3 or run: python -m http.server %PORT%
pause
exit /b

:PYOK
start "" /b cmd /c "ping -n 3 127.0.0.1 >nul&start http://localhost:%PORT%/viewer_combined.html"
python3 -m http.server %PORT% --bind 127.0.0.1
goto END

:PYOK2
start "" /b cmd /c "ping -n 3 127.0.0.1 >nul&start http://localhost:%PORT%/viewer_combined.html"
python -m http.server %PORT% --bind 127.0.0.1
goto END

:END
pause
