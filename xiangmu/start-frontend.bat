@echo off
setlocal enabledelayedexpansion
title 动画小镇 - 前端启动

rem ============================================================
rem  动画小镇 前端启动脚本 (Vue 3 + Vite)
rem  与后端脚本同样处理"闪退": 任何错误都会暂停并显示原因, 不会一闪而过。
rem  注意: 本文件必须保存为 ANSI(GBK) 编码, 否则中文系统 cmd 会乱码。
rem ============================================================

set "SCRIPT_DIR=%~dp0"
set "FRONTEND=%SCRIPT_DIR%vue"

echo.
echo ==========================================
echo   动画小镇 前端启动 (Vite)
echo ==========================================
echo.

rem ---------- 探测 npm: 优先系统 PATH，其次常见安装位置 ----------
set "NPM="
where npm >nul 2>&1 && set "NPM=npm"
if not defined NPM if exist "C:\Program Files\nodejs\npm.cmd" set "NPM=C:\Program Files\nodejs\npm.cmd"
if not defined NPM for /d %%d in ("%USERPROFILE%\.workbuddy\binaries\node\versions\*") do (
    if not defined NPM if exist "%%~fd\npm.cmd" set "NPM=%%~fd\npm.cmd"
)
if not defined NPM (
    echo [错误] 未找到 npm! 请安装 Node.js (https://nodejs.org) 后重试。
    goto :finish
)
echo   使用 npm: %NPM% [OK]

rem ---------- node_modules 缺失时自动安装 ----------
if not exist "%FRONTEND%\node_modules" (
    echo   首次运行, 正在安装前端依赖(约 1 分钟)...
    cd /d "%FRONTEND%"
    call "%NPM%" install --registry=https://registry.npmmirror.com --no-audit --no-fund
    if errorlevel 1 (
        echo   [错误] 前端依赖安装失败, 请检查网络。
        cd /d "%SCRIPT_DIR%"
        goto :finish
    )
    cd /d "%SCRIPT_DIR%"
    echo   前端依赖安装完成 [OK]
)

rem ---------- 端口 5173 被占用则释放 ----------
echo   检查端口 5173 是否被占用...
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /R ":5173 " ^| findstr /I "LISTENING" ') do (
    if not "%%a"=="0" (
        echo   释放占用端口 5173 的进程 PID=%%a
        taskkill /PID %%a /F >nul 2>&1
    )
)

rem ---------- 启动前端 ----------
echo   启动前端 Vite (端口 5173)... 按 Ctrl+C 可停止。
echo.
cd /d "%FRONTEND%"
call "%NPM%" run dev
set "RC=!errorlevel!"
echo.
if not !RC!==0 (
    echo ==========================================
    echo   [失败] 前端启动失败 (退出码 !RC!)。
    echo   请查看上方红色报错。
    echo ==========================================
) else (
    echo 前端已停止 (退出码 0)。
)
goto :finish

:finish
echo.
echo 按任意键关闭本窗口...
pause >nul
