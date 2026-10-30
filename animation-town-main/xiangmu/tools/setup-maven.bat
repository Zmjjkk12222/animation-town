@echo off
chcp 65001 >nul
REM ============================================================
REM  Maven 自动安装脚本（供 start-all.bat / start-backend.bat 使用）
REM  作用: 当项目 tools 目录里没有 Maven 时，从清华镜像自动下载
REM        apache-maven-3.9.16 并解压到项目 tools 目录。
REM ============================================================
setlocal
set "TOOLS=%~dp0"
set "MVN_DIR=%TOOLS%apache-maven-3.9.16"

if exist "%MVN_DIR%\bin\mvn.cmd" (
    echo Maven 已存在: %MVN_DIR% ✓
    pause
    exit /b 0
)

echo 正在从清华镜像下载 Maven 3.9.16 (约 9MB)...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.zip' -OutFile '%TOOLS%maven.zip'"
if errorlevel 1 (
    echo [错误] 下载失败, 请检查网络后重试。
    pause
    exit /b 1
)

echo 正在解压...
powershell -NoProfile -Command "Expand-Archive -Path '%TOOLS%maven.zip' -DestinationPath '%TOOLS%' -Force"
del "%TOOLS%maven.zip" >nul 2>&1

if exist "%MVN_DIR%\bin\mvn.cmd" (
    echo Maven 安装完成 ✓
) else (
    echo [错误] 解压失败, 请手动下载并解压到 %TOOLS%
)
pause
