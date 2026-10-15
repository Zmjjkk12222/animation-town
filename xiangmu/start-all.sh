#!/usr/bin/env bash
# ============================================================
#  动画小镇一键启动脚本（Git Bash / MINGW 版）
#  作用: 检查MySQL -> 初始化数据库 -> 启动后端(8081) -> 启动前端(5173)
#  说明: 项目自带的 mvnw 包装器已损坏，这里改用本机缓存的 Maven。
#  用法: bash start-all.sh   （停止用 bash stop-all.sh）
# ============================================================
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$ROOT/springBootTest"
FRONTEND="$ROOT/vue"
LOG_DIR="$ROOT/logs"
MYSQL_EXE="C:/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe"
DB_USER=root
DB_PASS=123456
# 本机缓存的 Maven（bash 版脚本，已在 MINGW 下修复 cygpath 路径问题）
# 注意: 必须用 mvn.cmd（Windows 批处理版）。同目录下的 shell 版 mvn 在 Git Bash 下会报
# "ClassNotFoundException: org.codehaus.plexus.classworlds.launcher.Launcher" 而无法启动后端。
MVN="C:/Users/Administrator/.m2/wrapper/dists/apache-maven-3.9.16-bin/5grr65jo27hi51sujmtcldfovl/apache-maven-3.9.16/bin/mvn.cmd"

mkdir -p "$LOG_DIR"

# 强制后端端口为 8081（覆盖 IDE 注入的 SERVER__PORT，避免抢占 IDE 端口导致启动失败）
export SERVER__PORT=8081
unset SERVER__HOST

ok()   { echo "        $1 ✓"; }
fail() { echo "        [错误] $1"; exit 1; }

port_up() {
  # 用 /dev/tcp 探测端口是否可连通
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3>&- 3<&-; return 0; }
  return 1
}

free_port() {
  # 结束占用指定端口的进程，避免“端口被占用导致启动失败”（典型：上次没关的 Vite 占着 5173）
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

# ---------- 0. 检查 Maven ----------
echo "  [0/5] 检查 Maven..."
[ -f "$MVN" ] || fail "未找到 Maven: $MVN"
ok "Maven 就绪"

# ---------- 1. 检查 MySQL ----------
echo "  [1/5] 检查 MySQL 服务(3306)..."
port_up 3306 || fail "MySQL 未启动! 请先在“服务”里启动 MySQL80"
ok "MySQL 正常"

# ---------- 2. 初始化数据库(已存在则跳过) ----------
echo "  [2/5] 检查数据库 animation_town..."
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

# ---------- 3. 启动后端 ----------
echo "  [3/5] 启动后端 Spring Boot (8081)..."
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

# ---------- 4. 启动前端 ----------
echo "  [4/5] 启动前端 Vite (5173)..."
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
echo "    停止服务:  bash stop-all.sh"
echo "  =========================================="
echo
