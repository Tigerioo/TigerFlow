#!/bin/bash

# =====================================================
# TigerFlow 后端服务启动脚本
# 直接部署用（不需要 Docker）
# =====================================================

# 配置
APP_NAME="tigerflow-server"
APP_VERSION="1.0.0"
JAR_FILE="target/${APP_NAME}-${APP_VERSION}.jar"
PID_FILE="${APP_NAME}.pid"
LOG_FILE="logs/${APP_NAME}.log"
PORT=9998

# JVM 内存配置（2GB 服务器优化，JDK 8 兼容）
JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=100"

# 环境变量（生产环境请修改这些值）
export DB_PASSWORD=${DB_PASSWORD:-tigerflow123}
export JWT_SECRET=${JWT_SECRET:-tigerflow-secret-key-must-be-at-least-256-bits-long-for-hs256}
export CORS_ALLOWED_ORIGINS=${CORS_ALLOWED_ORIGINS:-*}

# 应用配置
SPRING_OPTS="-Dspring.profiles.active=prod"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# 检查 JAR 是否存在
if [ ! -f "$JAR_FILE" ]; then
    error "JAR 文件不存在: $JAR_FILE"
    echo "请先运行: mvn clean package -DskipTests"
    exit 1
fi

# 创建日志目录
mkdir -p logs

# 停止旧进程
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        log "停止旧进程: $OLD_PID"
        kill "$OLD_PID"
        sleep 3
    fi
    rm -f "$PID_FILE"
fi

# 启动服务
log "启动服务..."
nohup java $JAVA_OPTS -jar $SPRING_OPTS "$JAR_FILE" >> "$LOG_FILE" 2>&1 &

# 保存 PID
PID=$!
echo $PID > "$PID_FILE"

log "服务已启动, PID: $PID"
log "日志文件: $LOG_FILE"
log "等待服务启动..."

# 等待服务启动
for i in {1..30}; do
    if curl -s http://localhost:${PORT}/actuator/health > /dev/null 2>&1; then
        log "✅ 服务启动成功!"
        log "API 地址: http://localhost:${PORT}"
        log "Swagger: http://localhost:${PORT}/swagger-ui.html"
        exit 0
    fi
    sleep 2
done

error "服务启动超时，请检查日志: $LOG_FILE"
exit 1
