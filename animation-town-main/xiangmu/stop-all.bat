@echo off
chcp 65001 >nul
title 动画小镇 - 停止服务

echo.
echo  正在停止动画小镇前后端服务...
echo.

rem 停止监听 8081 的后端 Java 进程
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force; Write-Host '  后端(8081) 已停止' }"
rem 停止监听 5173 的前端 Node 进程
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 5173 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force; Write-Host '  前端(5173) 已停止' }"

echo.
echo  完成! (MySQL 服务未做改动)
echo.
pause
