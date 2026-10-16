@echo off
REM ============================================================
REM  动画小镇后端启动脚本 (Spring Boot)
REM
REM  重要修复：
REM  本机 WorkBuddy IDE 会向子进程注入 SERVER__PORT 环境变量（指向 IDE 自身端口）。
REM  Spring Boot 的宽松绑定会把 SERVER__PORT 解析为 server.port，从而覆盖
REM  application-dev.properties 中配置的 server.port=8081，
REM  导致后端去抢占 IDE 端口而启动失败（Port xxx was already in use）。
REM  这里显式把端口固定为 8081 来规避该问题。
REM ============================================================
set SERVER__PORT=8081
set MAVEN_HOME=C:\Users\Administrator\.m2\wrapper\dists\apache-maven-3.9.9-bin\4nf9hui3q3djbarqar9g711ggc\apache-maven-3.9.9

cd /d %~dp0
call "%MAVEN_HOME%\bin\mvn.cmd" spring-boot:run
