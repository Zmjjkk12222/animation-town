@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title 动画小镇 - 一键启动

rem ============================================================
rem  动画小镇一键启动脚本 v2
rem  作用: 检查Java/Maven/MySQL -> 初始化数据库 -> 启动后端(8081) -> 启动前端(5173) -> 打开浏览器
rem
rem  v2 改进（修复启动不了的问题）:
rem   1. 不再写死 "C:\Users\Administrator\..." 的 Maven 路径（换电脑/换用户就失效），
rem      改为优先使用项目自带 tools\apache-maven-3.9.16，其次找系统 mvn。
rem   2. 自动探测 JAVA_HOME（只要 PATH 里有 java 就能跑）。
rem   3. 自动探测 npm；vue\node_modules 缺失时先自动安装依赖。
rem   4. 依赖下载走阿里云镜像（C:\Users\<你>\.m2\settings.xml）。
rem ============================================================

set "ROOT=%~dp0"
set "BACKEND=%ROOT%springBootTest"
set "FRONTEND=%ROOT%vue"
set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
set "DB_USER=root"
set "DB_PASS=123456"

rem -- 项目自带 Maven（首选）--
set "MVN=%ROOT%tools\apache-maven-3.9.16\bin\mvn.cmd"

rem -- 强制后端端口为 8081，覆盖 IDE 注入的 SERVER__PORT（否则会去抢 IDE 端口导致"Port already in use"）--
set "SERVER__PORT=8081"
set "SERVER__HOST="

echo.
echo  ==========================================
echo    动画小镇 Animation Town 一键启动
echo  ==========================================
echo.

rem ---------- 0. 检查 Java ----------
echo  [0/6] 检查 Java...
if defined JAVA_HOME (
    echo        JAVA_HOME = !JAVA_HOME! ✓
) else (
    set "JEXE="
    for /f "delims=" %%i in ('where java 2^>nul') do (
        if not defined JEXE set "JEXE=%%i"
    )
    if not defined JEXE (
        echo        [错误] 未找到 Java! 请安装 JDK 17 或设置 JAVA_HOME。
        pause
        exit /b 1
    )
    set "JAVA_HOME=!JEXE:\bin\java.exe=!"
    echo        自动探测 JAVA_HOME = !JAVA_HOME! ✓
)

rem ---------- 1. 检查 Maven ----------
echo  [1/6] 检查 Maven...
if exist "%MVN%" (
    echo        使用项目自带 Maven: %MVN% ✓
) else (
    where mvn >nul 2>&1
    if errorlevel 1 (
        echo        [错误] 未找到 Maven!
        echo        项目 tools 目录里没有 apache-maven，系统 PATH 里也没有 mvn 命令。
        echo        解决办法: 运行 tools\setup-maven.bat 自动下载，或自行安装 Maven。
        pause
        exit /b 1
    )
    set "MVN=mvn"
    echo        使用系统 Maven ✓
)

rem ---------- 2. 检查 MySQL ----------
echo  [2/6] 检查 MySQL 服务(3306)...
powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',3306);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
if errorlevel 1 (
    echo        [错误] MySQL 未启动! 请先启动 MySQL 服务再运行本脚本。
    echo        提示: 在"服务"里启动 MySQL80, 或管理员运行 net start MySQL80
    pause
    exit /b 1
)
echo        MySQL 正常 ✓

rem ---------- 3. 初始化数据库(已存在则跳过) ----------
echo  [3/6] 检查数据库 animation_town...
if not exist "%MYSQL_EXE%" (
    echo        [警告] 未找到 mysql.exe, 跳过数据库检查(若库已存在不影响启动)
) else (
    "%MYSQL_EXE%" -u%DB_USER% -p%DB_PASS% -e "USE animation_town;" >nul 2>&1
    if errorlevel 1 (
        echo        首次运行, 正在初始化数据库...
        "%MYSQL_EXE%" -u%DB_USER% -p%DB_PASS% --default-character-set=utf8mb4 < "%BACKEND%\src\main\resources\sql\animation_town.sql" 2>nul
        "%MYSQL_EXE%" -u%DB_USER% -p%DB_PASS% --default-character-set=utf8mb4 < "%BACKEND%\src\main\resources\sql\animation_town_data.sql" 2>nul
        if errorlevel 1 (
            echo        [错误] 数据库初始化失败, 请检查 %BACKEND%\src\main\resources\application-dev.properties 里的账号密码
            pause
            exit /b 1
        )
        echo        数据库初始化完成 ✓
    ) else (
        echo        数据库已就绪 ✓
    )
)

rem ---------- 4. 启动后端 ----------
echo  [4/6] 启动后端 Spring Boot (8081)...
powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',8081);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
if not errorlevel 1 (
    echo        后端已在运行, 跳过 ✓
) else (
    call :free_port 8081
    start "springBootTest-后端" cmd /k "cd /d "%BACKEND%" && set "SERVER__PORT=8081" && set "SERVER__HOST=" && "%MVN%" spring-boot:run"
    echo        后端启动中(首次编译约需 30-60 秒)...
    set /a tries=0
    :wait_backend
    ping -n 4 127.0.0.1 >nul
    powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',8081);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
    if errorlevel 1 (
        set /a tries+=1
        if !tries! lss 30 goto wait_backend
        echo        [警告] 等待后端超时, 请查看 springBootTest-后端 窗口的报错信息
    ) else (
        echo        后端启动成功 ✓
    )
)

rem ---------- 5. 启动前端 ----------
echo  [5/6] 启动前端 Vite (5173)...

rem -- 探测 npm: 优先系统 PATH，其次常见安装位置 --
set "NPM="
where npm >nul 2>&1 && set "NPM=npm"
if not defined NPM if exist "C:\Program Files\nodejs\npm.cmd" set "NPM=C:\Program Files\nodejs\npm.cmd"
if not defined NPM for /d %%d in ("%USERPROFILE%\.workbuddy\binaries\node\versions\*") do (
    if not defined NPM if exist "%%~fd\npm.cmd" set "NPM=%%~fd\npm.cmd"
)
if not defined NPM (
    echo        [错误] 未找到 npm! 请安装 Node.js (https://nodejs.org) 后重试。
    pause
    exit /b 1
)

rem -- 依赖缺失时自动安装 --
if not exist "%FRONTEND%\node_modules" (
    echo        首次运行, 正在安装前端依赖(约 1 分钟)...
    cd /d "%FRONTEND%"
    call !NPM! install --registry=https://registry.npmmirror.com --no-audit --no-fund
    if errorlevel 1 (
        echo        [错误] 前端依赖安装失败, 请检查网络。
        cd /d "%ROOT%"
        pause
        exit /b 1
    )
    cd /d "%ROOT%"
    echo        前端依赖安装完成 ✓
)

powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',5173);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
if not errorlevel 1 (
    echo        前端已在运行, 跳过 ✓
) else (
    call :free_port 5173
    start "animation-town-前端" cmd /k "cd /d "%FRONTEND%" && set "PATH=%PATH%" && !NPM! run dev"
    echo        前端启动中...
    set /a tries=0
    :wait_frontend
    ping -n 3 127.0.0.1 >nul
    powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',5173);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
    if errorlevel 1 (
        set /a tries+=1
        if !tries! lss 15 goto wait_frontend
        echo        [警告] 等待前端超时, 请查看 animation-town-前端 窗口
    ) else (
        echo        前端启动成功 ✓
    )
)

echo.
echo  ==========================================
echo    全部就绪! 浏览器即将自动打开
echo    手动访问: http://localhost:5173
echo  ==========================================
echo.
start http://localhost:5173
pause
goto :eof

rem ---------- 释放指定端口占用的进程（避免"端口被占用导致前端/后端启动失败"） ----------
:free_port
  set "P=%1"
  echo        检查端口 %P% 是否被占用...
  for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /R ":%P% " ^| findstr /I "LISTENING" ') do (
    if not "%%a"=="0" (
      echo        释放占用端口 %P% 的进程 PID=%%a
      taskkill /PID %%a /F >nul 2>&1
    )
  )
  goto :eof
