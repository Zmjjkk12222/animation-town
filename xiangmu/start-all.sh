#!/usr/bin/env bash
# ============================================================
#  动画小镇一键启动脚本（Git Bash / MINGW 版）v2
#  作用: 检查MySQL -> 初始化数据库 -> 启动后端(8081) -> 启动前端(5173)
#  用法: bash start-all.sh
#
#  v2 改进（修复启动不了的问题）:
#   1. Maven 不再写死 "C:/Users/Administrator/..." 路径，优先用项目自带
#      tools/apache-maven-3.9.16（.cmd 版），其次找系统 mvn。
#   2. 自动探测 JAVA_HOME。
#   3. vue/node_modules 缺失时自动 npm install（走 npmmirror 镜像）。
#   4. 依赖下载走阿里云镜像（~/.m2/settings.xml）。
# ============================================================
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$ROOT/springBootTest"
FRONTEND="$ROOT/vue"
LOG_DIR="$ROOT/logs"
MYSQL_EXE="C:/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe"
DB_USER=root
DB_PASS=123456
# 项目自带 Maven（bash 下必须用 mvn.cmd，shell 版 mvn 在 Git Bash 下会报
# "ClassNotFoundException: org.codehaus.plexus.classworlds.launcher.Launcher"）
MVN="$ROOT/tools/apache-maven-3.9.16/bin/mvn.cmd"

mkdir -p "$LOG_DIR"

# 强制后端端口为 8081（覆盖 IDE 注入的 SERVER__PORT，避免抢占 IDE 端口导致启动失败）
export SERVER__PORT=8081
unset SERVER__HOST

ok()   { echo "        $1 ✓"; }
fail() { echo "        [错误] $1"; exit 1; }

port_up() {
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3>&- 3<&-; return 0; }
  return 1
}

free_port() {
  local p="$1" pids pid
  pids=$(netstat -ano 2>/dev/null | grep LISTENING | grep -E "[:.]${p}[[:space:]]" | awk '{print $5}' | grep -E '^[0-9]+$')
  for pid in $pids; do
    [ "$pid" = "0" ] && continue
    echo "        释放占用端口 $p 的进程 PID=$pid"
    taskkill /F /PID "$pid" >/dev/null 2>&1
  done
}

echo
echo "  =========================================="
echo "    动画小镇 Animation Town 一键启动"
echo "  =========================================="
echo

# ---------- 0. 检查 Java ----------
echo "  [0/5] 检查 Java..."
if [ -z "${JAVA_HOME:-}" ]; then
  JEXE="$(command -v java 2>/dev/null || true)"
  if [ -z "$JEXE" ]; then
    fail "未找到 Java! 请安装 JDK 17 或设置 JAVA_HOME"
  fi
  # 从 java 可执行文件路径推导 JAVA_HOME（去掉 /bin/java）
  JDIR="$(dirname "$JEXE")"
  export JAVA_HOME="$(cd "$JDIR/.." && pwd)"
fi
ok "JAVA_HOME = $JAVA_HOME"

# ---------- 1. 检查 Maven ----------
echo "  [1/5] 检查 Maven..."
if [ ! -f "$MVN" ]; then
  if command -v mvn >/dev/null 2>&1; then
    MVN="mvn"
  else
    fail "未找到 Maven! 请运行 tools/setup-maven.bat 或自行安装"
  fi
fi
ok "Maven 就绪: $MVN"

# ---------- 2. 检查 MySQL ----------
echo "  [2/5] 检查 MySQL 服务(3306)..."
port_up 3306 || fail "MySQL 未启动! 请先在“服务”里启动 MySQL80"
ok "MySQL 正常"

# ---------- 3. 初始化数据库(已存在则跳过) ----------
echo "  [3/5] 检查数据库 animation_town..."
if [ ! -f "$MYSQL_EXE" ]; then
  echo "        [警告] 未找到 mysql.exe, 跳过数据库检查"
else
  if "$MYSQL_EXE" -u"$DB_USER" -p"$DB_PASS" -e "USE animation_town;" >/dev/null 2>&1; then
    ok "数据库已就绪"
  else
    echo "        首次运行, 正在初始化数据库..."
    "$MYSQL_EXE" -u"$DB_USER" -p"$DB_PASS" --default-character-set=utf8mb4 < "$BACKEND/src/main/resources/sql/animation_town.sql" 2>/dev/null
    "$MYSQL_EXE" -u"$DB_USER" -p"$DB_PASS" --default-character-set=utf8mb4 < "$BACKEND/src/main/resources/sql/animation_town_data.sql" 2>/dev/null \
      && ok "数据库初始化完成" || fail "数据库初始化失败, 请检查 application-dev.properties 的账号密码"
  fi
fi

# ---------- 4. 启动后端 ----------
echo "  [4/5] 启动后端 Spring Boot (8081)..."
if port_up 8081; then
  ok "后端已在运行, 跳过"
else
  free_port 8081
  ( cd "$BACKEND" && "$MVN" spring-boot:run > "$LOG_DIR/backend.log" 2>&1 ) &
  disown
  echo "        后端启动中(日志: $LOG_DIR/backend.log, 首次编译约 30-60 秒)..."
  tries=0
  until port_up 8081; do
    tries=$((tries+1))
    [ $tries -ge 40 ] && { echo "        [警告] 等待后端超时, 请查看 $LOG_DIR/backend.log"; break; }
    sleep 3
  done
  port_up 8081 && ok "后端启动成功"
fi

# ---------- 5. 启动前端 ----------
echo "  [5/5] 启动前端 Vite (5173)..."
if ! command -v npm >/dev/null 2>&1; then
  # npm 不在 PATH 时，尝试 WorkBuddy 自带 node
  for d in "$HOME"/.workbuddy/binaries/node/versions/*/; do
    if [ -f "$d/npm.cmd" ] || [ -f "$d/npm" ]; then
      export PATH="$d:$PATH"
      break
    fi
  done
fi
command -v npm >/dev/null 2>&1 || fail "未找到 npm! 请安装 Node.js (https://nodejs.org)"

if [ ! -d "$FRONTEND/node_modules" ]; then
  echo "        首次运行, 正在安装前端依赖..."
  ( cd "$FRONTEND" && npm install --registry=https://registry.npmmirror.com --no-audit --no-fund > "$LOG_DIR/frontend-install.log" 2>&1 ) \
    && ok "前端依赖安装完成" || fail "前端依赖安装失败, 请查看 $LOG_DIR/frontend-install.log"
fi

if port_up 5173; then
  ok "前端已在运行, 跳过"
else
  free_port 5173
  ( cd "$FRONTEND" && npm run dev > "$LOG_DIR/frontend.log" 2>&1 ) &
  disown
  echo "        前端启动中(日志: $LOG_DIR/frontend.log)..."
  tries=0
  until port_up 5173; do
    tries=$((tries+1))
    [ $tries -ge 20 ] && { echo "        [警告] 等待前端超时, 请查看 $LOG_DIR/frontend.log"; break; }
    sleep 2
  done
  port_up 5173 && ok "前端启动成功"
fi

echo
echo "  =========================================="
echo "    全部就绪! 访问: http://localhost:5173"
echo "    停止服务: 关闭后端/前端窗口, 或结束占用 8081/5173 的进程"
echo "  =========================================="
echo
