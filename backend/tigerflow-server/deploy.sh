#!/bin/bash

# =====================================================
# TigerFlow 后端服务一键部署脚本
# =====================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认配置
APP_NAME="tigerflow-server"
APP_VERSION="1.0.0"
JAR_FILE="target/${APP_NAME}-${APP_VERSION}.jar"
PROFILE="prod"
PORT=8080

# 帮助信息
function show_help() {
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  build       构建 JAR 文件"
    echo "  start       启动服务"
    echo "  stop       停止服务"
    echo "  restart    重启服务"
    echo "  status     查看服务状态"
    echo "  logs       查看日志"
    echo "  deploy     一键部署（构建+启动）"
    echo "  docker-build  构建 Docker 镜像"
    echo "  docker-run    运行 Docker 容器"
    echo ""
    echo "选项:"
    echo "  -p, --port      端口号 (默认: 8080)"
    echo "  -m, --mysql     MySQL 主机地址"
    echo "  -h, --help     显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 build                    # 构建 JAR"
    echo "  $0 deploy                   # 一键部署"
    echo "  $0 deploy -m 192.168.1.100 # 部署到指定 MySQL"
}

# 日志函数
function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Java
function check_java() {
    if ! command -v java &> /dev/null; then
        log_error "Java 未安装，请先安装 JDK 11+"
        exit 1
    fi
    log_info "Java 版本: $(java -version 2>&1 | head -n 1)"
}

# 检查 Maven
function check_maven() {
    if ! command -v mvn &> /dev/null; then
        log_error "Maven 未安装，请先安装 Maven"
        exit 1
    fi
    log_info "Maven 版本: $(mvn -version 2>&1 | head -n 1)"
}

# 构建项目
function build() {
    log_info "开始构建项目..."
    cd "$(dirname "$0")"

    check_maven

    mvn clean package -DskipTests

    if [ -f "$JAR_FILE" ]; then
        log_info "构建成功: $JAR_FILE"
    else
        log_error "构建失败"
        exit 1
    fi
}

# 启动服务
function start() {
    log_info "启动服务..."
    cd "$(dirname "$0")"

    # 检查 JAR 文件
    if [ ! -f "$JAR_FILE" ]; then
        log_warn "JAR 文件不存在，正在构建..."
        build
    fi

    # 检查端口是否被占用
    if lsof -i :${PORT} &> /dev/null; then
        log_error "端口 ${PORT} 已被占用"
        exit 1
    fi

    # 设置环境变量
    export SPRING_PROFILES_ACTIVE=$PROFILE
    export DB_PASSWORD=${DB_PASSWORD:-tigerflow123}
    export JWT_SECRET=${JWT_SECRET:-tigerflow-secret-key-must-be-at-least-256-bits-long-for-hs256}

    # 启动服务（后台运行）
    nohup java -jar -Dspring.profiles.active=$PROFILE $JAR_FILE > logs/app.log 2>&1 &

    PID=$!
    echo $PID > .app.pid

    log_info "服务已启动，PID: $PID"
    log_info "等待服务启动..."
    sleep 10

    # 检查服务是否启动成功
    if curl -s http://localhost:${PORT}/v3/api-docs &> /dev/null; then
        log_info "服务启动成功!"
        log_info "API 文档: http://localhost:${PORT}/swagger-ui.html"
    else
        log_warn "服务可能未完全启动，请检查日志: logs/app.log"
    fi
}

# 停止服务
function stop() {
    log_info "停止服务..."

    if [ -f .app.pid ]; then
        PID=$(cat .app.pid)
        if ps -p $PID &> /dev/null; then
            kill $PID
            rm -f .app.pid
            log_info "服务已停止"
        else
            log_warn "服务未运行"
            rm -f .app.pid
        fi
    else
        # 尝试查找进程
        PID=$(lsof -ti :${PORT} 2>/dev/null || true)
        if [ -n "$PID" ]; then
            kill $PID
            log_info "服务已停止 (PID: $PID)"
        else
            log_warn "服务未运行"
        fi
    fi
}

# 查看状态
function status() {
    if [ -f .app.pid ]; then
        PID=$(cat .app.pid)
        if ps -p $PID &> /dev/null; then
            log_info "服务运行中 (PID: $PID)"
        else
            log_warn "服务未运行 (PID 文件过期)"
        fi
    else
        PID=$(lsof -ti :${PORT} 2>/dev/null || true)
        if [ -n "$PID" ]; then
            log_info "服务运行中 (PID: $PID)"
        else
            log_info "服务未运行"
        fi
    fi
}

# 查看日志
function logs() {
    if [ -f "logs/app.log" ]; then
        tail -f logs/app.log
    else
        log_error "日志文件不存在"
    fi
}

# 一键部署
function deploy() {
    log_info "开始一键部署..."
    build
    stop
    start
    log_info "部署完成!"
}

# Docker 构建
function docker_build() {
    log_info "开始 Docker 构建..."
    cd "$(dirname "$0")"

    # 先构建 JAR
    build

    # 构建 Docker 镜像
    docker build -t tigerflow-server:latest .

    log_info "Docker 镜像构建成功: tigerflow-server:latest"
}

# Docker 运行
function docker_run() {
    log_info "启动 Docker 容器..."

    # 检查 MySQL
    if [ -z "$MYSQL_HOST" ]; then
        log_warn "未指定 MySQL_HOST，使用默认值 localhost"
        MYSQL_HOST="localhost"
    fi

    docker run -d \
        --name tigerflow-server \
        -p ${PORT}:8080 \
        -e SPRING_PROFILES_ACTIVE=prod \
        -e DB_PASSWORD=${DB_PASSWORD:-tigerflow123} \
        -e JWT_SECRET=${JWT_SECRET:-tigerflow-secret-key-must-be-at-least-256-bits-long-for-hs256} \
        -e SPRING_DATASOURCE_URL="jdbc:mysql://${MYSQL_HOST}:3306/tigerflow?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai&createDatabaseIfNotExist=true" \
        tigerflow-server:latest

    log_info "Docker 容器已启动"
    log_info "服务地址: http://localhost:${PORT}"
}

# 主程序
function main() {
    # 解析参数
    COMMAND=${1:-help}
    shift || true

    case $COMMAND in
        build)
            build
            ;;
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            stop
            start
            ;;
        status)
            status
            ;;
        logs)
            logs
            ;;
        deploy)
            deploy
            ;;
        docker-build)
            docker_build
            ;;
        docker-run)
            docker_run
            ;;
        -h|--help|help)
            show_help
            ;;
        *)
            log_error "未知命令: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
