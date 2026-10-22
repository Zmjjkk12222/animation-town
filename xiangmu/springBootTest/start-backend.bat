@echo off
setlocal enabledelayedexpansion
title 动画小镇 - 后端启动

rem ============================================================
rem  动画小镇 后端启动脚本 (Spring Boot)
rem
rem  修复记录:
rem   1. 修正 Maven 路径: 使用上级目录 xiangmu\tools 里的 Maven。
rem   2. 启动失败不再闪退: 检测退出码, 失败时提示并暂停。
rem   3. 端口固定 8081: 环境变量 + 启动参数双保险, 覆盖 IDE 注入的端口。
rem   4. 本文件必须保存为 ANSI(GBK) 编码, 否则中文系统 cmd 会乱码。
rem ============================================================

set "SCRIPT_DIR=%~dp0"
rem 项目根目录(xiangmu): 脚本位于 springBootTest 子目录, 向上回退一级
set "PROJ_DIR=%SCRIPT_DIR%..\"
set "BACKEND=%SCRIPT_DIR%"
set "MVN=%PROJ_DIR%tools\apache-maven-3.9.16\bin\mvn.cmd"
set "MVNW=%SCRIPT_DIR%mvnw.cmd"

rem 固定端口, 覆盖 IDE 可能注入的 SERVER__PORT / SERVER_PORT
set "SERVER_PORT=8081"
set "SERVER__PORT=8081"
set "SERVER_HOST="

echo.
echo ==========================================
echo   动画小镇 后端启动 (Spring Boot)
echo ==========================================
echo.

rem ---------- 1. 检查 Maven ----------
echo [1/4] 检查 Maven...
if exist "%MVN%" (
    echo   使用项目自带 Maven: %MVN% [OK]
) else if exist "%MVNW%" (
    set "MVN=%MVNW%"
    echo   使用项目自带 Maven Wrapper: %MVN% [OK]
) else (
    where mvn >nul 2>&1
    if errorlevel 1 (
        echo   [错误] 未找到 Maven! 项目 tools 目录没有 apache-maven,
        echo           也没有 mvnw, 且系统 PATH 里没有 mvn 命令。
        echo           解决办法: 运行 tools\setup-maven.bat 自动下载, 或自行安装 Maven。
        goto :finish
    )
    set "MVN=mvn"
    echo   使用系统 Maven [OK]
)

rem ---------- 2. 检查 Java ----------
echo [2/4] 检查 Java...
if defined JAVA_HOME (
    echo   JAVA_HOME = !JAVA_HOME! [OK]
) else (
    set "JEXE="
    for /f "delims=" %%i in ('where java 2^>nul') do (
        if not defined JEXE set "JEXE=%%i"
    )
    if not defined JEXE (
        echo   [错误] 未找到 Java! 请安装 JDK 17 并设置 JAVA_HOME, 或将 java 加入 PATH。
        goto :finish
    )
    set "JAVA_HOME=!JEXE:\bin\java.exe=!"
    echo   自动探测 JAVA_HOME = !JAVA_HOME! [OK]
)

rem ---------- 3. 检查 MySQL ----------
echo [3/4] 检查 MySQL 服务(3306)...
powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect('127.0.0.1',3306);exit 0}catch{exit 1}finally{$c.Close()}" >nul 2>&1
if errorlevel 1 (
    echo   [警告] MySQL 未启动! 后端可能因连不上数据库而启动失败。
    echo           请先在"服务"中启动 MySQL80, 或管理员运行: net start MySQL80
) else (
    echo   MySQL 正常 [OK]
)

rem ---------- 4. 启动后端 ----------
echo [4/4] 启动后端 Spring Boot (端口 8081)...
echo   运行日志由应用同时写入 log\xx.log
echo   按 Ctrl+C 可停止后端。
echo.
cd /d "%BACKEND%"
"%MVN%" spring-boot:run -Dspring-boot.run.arguments=--server.port=8081
set "RC=!errorlevel!"
echo.
if not !RC!==0 (
    echo ==========================================
    echo   [失败] 后端启动失败 (退出码 !RC!)。
    echo   请查看上方报错, 或打开应用日志:
    echo   %BACKEND%log\xx.log
    echo ==========================================
) else (
    echo 后端已停止 (退出码 0)。
)
goto :finish

:finish
echo.
echo 按任意键关闭本窗口...
pause >nul
