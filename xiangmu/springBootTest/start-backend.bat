@echo off
REM ============================================================
REM  动画小镇后端启动脚本 (Spring Boot) v2
REM
REM  v2 改进（修复启动不了的问题）:
REM   1. Maven 不再写死 "C:\Users\Administrator\..." 路径，
REM      优先使用项目自带 tools\apache-maven-3.9.16，其次找系统 mvn。
REM   2. 自动探测 JAVA_HOME。
REM
REM  端口说明:
REM  本机 IDE 会向子进程注入 SERVER__PORT 环境变量（指向 IDE 自身端口）。
REM  Spring Boot 的宽松绑定会把 SERVER__PORT 解析为 server.port，
REM  覆盖 application-dev.properties 里的 server.port=8081，
REM  导致后端去抢占 IDE 端口而启动失败（Port xxx was already in use）。
REM  这里显式把端口固定为 8081 来规避该问题。
REM ============================================================
setlocal enabledelayedexpansion
set "ROOT=%~dp0"
set "SERVER__PORT=8081"
set "SERVER__HOST="

rem -- Maven: 优先项目自带，其次系统 PATH --
set "MVN=%ROOT%tools\apache-maven-3.9.16\bin\mvn.cmd"
if not exist "%MVN%" (
    where mvn >nul 2>&1
    if errorlevel 1 (
        echo [错误] 未找到 Maven! 请运行 %ROOT%tools\setup-maven.bat 或自行安装。
        pause
        exit /b 1
    )
    set "MVN=mvn"
)

rem -- JAVA_HOME: 未设置时自动探测 --
if not defined JAVA_HOME (
    set "JEXE="
    for /f "delims=" %%i in ('where java 2^>nul') do (
        if not defined JEXE set "JEXE=%%i"
    )
    if defined JEXE set "JAVA_HOME=!JEXE:\bin\java.exe=!"
)

echo 使用 Maven: %MVN%
echo JAVA_HOME : %JAVA_HOME%
echo 后端端口 : 8081

cd /d "%ROOT%"
call "%MVN%" spring-boot:run
