@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title 动画小镇 - 一键启动

rem ============================================================
rem  动画小镇一键启动脚本
rem  作用: 检查MySQL -> 初始化数据库 -> 启动后端(8081) -> 启动前端(5173) -> 打开浏览器
rem ============================================================

set "ROOT=%~dp0"
set "BACKEND=%ROOT%springBootTest"
set "FRONTEND=%ROOT%vue"
set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
set "DB_USER=root"
set "DB_PASS=123456"

rem -- 防止某些环境下 SERVER__PORT 环境变量覆盖 server.port 配置 --
set "SERVER__PORT="
set "SERVER__HOST="

echo.
echo  ==========================================
echo    动画小镇 Animation Town 一键启动
echo  ==========================================
echo.

rem ---------- 0. 检查 MySQL ----------
echo  [1/4] 检查 MySQL 服务(3306)...
powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',3306);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
if errorlevel 1 (
    echo        [错误] MySQL 未启动! 请先启动 MySQL 服务再运行本脚本。
    echo        提示: 在"服务"里启动 MySQL80, 或管理员运行 net start MySQL80
    pause
    exit /b 1
)
echo        MySQL 正常 ✓

rem ---------- 1. 初始化数据库(已存在则跳过) ----------
echo  [2/4] 检查数据库 animation_town...
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

rem ---------- 2. 启动后端 ----------
echo  [3/4] 启动后端 Spring Boot (8081)...
powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',8081);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
if not errorlevel 1 (
    echo        后端已在运行, 跳过 ✓
) else (
    start "springBootTest-后端" cmd /k "cd /d "%BACKEND%" && mvnw.cmd spring-boot:run"
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

rem ---------- 3. 启动前端 ----------
echo  [4/4] 启动前端 Vite (5173)...
powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',5173);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
if not errorlevel 1 (
    echo        前端已在运行, 跳过 ✓
) else (
    start "animation-town-前端" cmd /k "cd /d "%FRONTEND%" && npm run dev"
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
