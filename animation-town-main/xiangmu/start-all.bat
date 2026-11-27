@echo off
setlocal enabledelayedexpansion
title ����С�� - һ������

rem ============================================================
rem  ����С��һ�������ű�
rem  ����: ���Java/Maven/MySQL -> ��ʼ�����ݿ� -> �������(8081) -> ����ǰ��(5173) -> �������
rem  ע��: ���ļ����뱣��Ϊ ANSI(GBK) ����, ��������ϵͳ cmd �����롣
rem ============================================================

set "ROOT=%~dp0"
set "BACKEND=%ROOT%springBootTest"
set "FRONTEND=%ROOT%vue"
set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
set "DB_USER=root"
set "DB_PASS=123456"

rem -- ��Ŀ�Դ� Maven����ѡ��--
set "MVN=%ROOT%tools\apache-maven-3.9.16\bin\mvn.cmd"

rem -- ��˶˿ڹ̶� 8081, ���� IDE ע��� SERVER__PORT --
set "SERVER__PORT=8081"
set "SERVER__HOST="

echo.
echo  ==========================================
echo    ����С�� Animation Town һ������
echo  ==========================================
echo.

rem ---------- 0. ��� Java ----------
echo  [0/6] ��� Java...
if defined JAVA_HOME (
    echo        JAVA_HOME = !JAVA_HOME! [OK]
) else (
    set "JEXE="
    for /f "delims=" %%i in ('where java 2^>nul') do (
        if not defined JEXE set "JEXE=%%i"
    )
    if not defined JEXE (
        echo        [����] δ�ҵ� Java! �밲װ JDK 17 ������ JAVA_HOME��
        pause
        exit /b 1
    )
    set "JAVA_HOME=!JEXE:\bin\java.exe=!"
    echo        �Զ�̽�� JAVA_HOME = !JAVA_HOME! [OK]
)

rem ---------- 1. ��� Maven ----------
echo  [1/6] ��� Maven...
if exist "%MVN%" (
    echo        ʹ����Ŀ�Դ� Maven: %MVN% [OK]
) else (
    where mvn >nul 2>&1
    if errorlevel 1 (
        echo        [����] δ�ҵ� Maven!
        echo        ��Ŀ tools Ŀ¼��û�� apache-maven��ϵͳ PATH ��Ҳû�� mvn ���
        echo        ����취: ���� tools\setup-maven.bat �Զ����أ������а�װ Maven��
        pause
        exit /b 1
    )
    set "MVN=mvn"
    echo        ʹ��ϵͳ Maven [OK]
)

rem ---------- 2. ��� MySQL ----------
echo  [2/6] ��� MySQL ����(3306)...
powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',3306);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
if errorlevel 1 (
    echo        [����] MySQL δ����! �������� MySQL ���������б��ű���
    echo        ��ʾ: ��"����"������ MySQL80, �����Ա���� net start MySQL80
    pause
    exit /b 1
)
echo        MySQL ���� [OK]

rem ---------- 3. ��ʼ��/ͬ�����ݿ�(�ű����ݵ�, ÿ�ζ���) ----------
echo  [3/6] ������ݿ� animation_town...
if not exist "%MYSQL_EXE%" (
    echo        [����] δ�ҵ� mysql.exe, �������ݿ���^(�����Ѵ��ڲ�Ӱ������^)
) else (
    rem ����ű����� CREATE DATABASE, ���ܴ� -D
    "%MYSQL_EXE%" -u%DB_USER% -p%DB_PASS% --default-character-set=utf8mb4 < "%BACKEND%\src\main\resources\sql\animation_town.sql" 2>nul
    if errorlevel 1 (
        echo        [����] �������ݿ�ʧ��, ���� application-dev.properties ����˺�����
        pause
        exit /b 1
    )
    rem ����ű�������ʽ -D: town_admin.sql ��û�� USE ���, ����� "No database selected"
    for %%F in (animation_town_data.sql town_admin.sql town_friend.sql town_friend_request.sql town_message.sql town_user_avatar.sql) do (
        "%MYSQL_EXE%" -u%DB_USER% -p%DB_PASS% -D animation_town --default-character-set=utf8mb4 < "%BACKEND%\src\main\resources\sql\%%F" 2>nul
    )
    "%MYSQL_EXE%" -u%DB_USER% -p%DB_PASS% -D animation_town -e "SELECT 1 FROM town_message LIMIT 1;" >nul 2>&1
    if errorlevel 1 (
        echo        [����] ���ݿ�ͬ��ʧ��^(town_message ȱʧ^), ���� MySQL �˺�����
        pause
        exit /b 1
    )
    echo        ���ݿ�ṹ��ͬ�� [OK]
)

rem ---------- 4. ������� ----------
echo  [4/6] ������� Spring Boot (8081)...
powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',8081);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
if not errorlevel 1 (
    echo        �����������, ���� [OK]
) else (
    call :free_port 8081
    rem ע��: ·���������ո�, ��� cmd /k �ڲ�Ƕ������^(Ƕ�����Żᱻ�ض�^)
    start "springBootTest-���" %ROOT%springBootTest\start-backend.bat
    echo        ���������^(�״α���Լ�� 30-60 ��^)...
    set /a tries=0
    :wait_backend
    ping -n 4 127.0.0.1 >nul
    powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',8081);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
    if errorlevel 1 (
        set /a tries+=1
        if !tries! lss 30 goto wait_backend
        echo        [����] �ȴ���˳�ʱ, ��鿴 springBootTest-��� ���ڵı�����Ϣ
    ) else (
        echo        ��������ɹ� [OK]
    )
)

rem ---------- 5. ����ǰ�� ----------
echo  [5/6] ����ǰ�� Vite (5173)...

rem -- ̽�� npm: ����ϵͳ PATH����γ�����װλ�� --
set "NPM="
for /f "delims=" %%i in ('where npm.cmd 2^>nul') do if not defined NPM set "NPM=%%i"
if not defined NPM if exist "C:\Program Files\nodejs\npm.cmd" set "NPM=C:\Program Files\nodejs\npm.cmd"
if not defined NPM for /d %%d in ("%USERPROFILE%\.workbuddy\binaries\node\versions\*") do (
    if not defined NPM if exist "%%~fd\npm.cmd" set "NPM=%%~fd\npm.cmd"
)
if not defined NPM (
    echo        [����] δ�ҵ� npm! �밲װ Node.js ^(https://nodejs.org^) �����ԡ�
    pause
    exit /b 1
)

rem -- ����ȱʧʱ�Զ���װ --
if not exist "%FRONTEND%\node_modules" (
    echo        �״�����, ���ڰ�װǰ������^(Լ 1 ����^)...
    cd /d "%FRONTEND%"
    call !NPM! install --registry=https://registry.npmmirror.com --no-audit --no-fund
    if errorlevel 1 (
        echo        [����] ǰ��������װʧ��, �������硣
        cd /d "%ROOT%"
        pause
        exit /b 1
    )
    cd /d "%ROOT%"
    echo        ǰ��������װ��� [OK]
)

powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',5173);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
if not errorlevel 1 (
    echo        ǰ����������, ���� [OK]
) else (
    call :free_port 5173
    rem ǰ��ͬ��: ·�������ո�, ��� cmd /k �ڲ�Ƕ������
    start "animation-town-ǰ��" %ROOT%start-frontend.bat
    echo        ǰ��������...
    set /a tries=0
    :wait_frontend
    ping -n 3 127.0.0.1 >nul
    powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',5173);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
    if errorlevel 1 (
        set /a tries+=1
        if !tries! lss 15 goto wait_frontend
        echo        [����] �ȴ�ǰ�˳�ʱ, ��鿴 animation-town-ǰ�� ����
    ) else (
        echo        ǰ�������ɹ� [OK]
    )
)

echo.
echo  ==========================================
echo    ȫ������! ����������Զ���
echo    �ֶ�����: http://localhost:5173
echo  ==========================================
echo.
start http://localhost:5173
pause
goto :eof

rem ---------- �ͷ�ָ���˿�ռ�õĽ��� ----------
:free_port
  set "P=%1"
  echo        ���˿� %P% �Ƿ�ռ��...
  for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /R ":%P% " ^| findstr /I "LISTENING" ') do (
    if not "%%a"=="0" (
      echo        �ͷ�ռ�ö˿� %P% �Ľ��� PID=%%a
      taskkill /PID %%a /F >nul 2>&1
    )
  )
  goto :eof
