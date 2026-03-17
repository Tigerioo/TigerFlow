#!/bin/bash

# =====================================================
# TigerFlow 后端服务停止脚本
# =====================================================

APP_NAME="tigerflow-server"
PID_FILE="${APP_NAME}.pid"
PORT=9998

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "停止服务 PID: $PID"
        kill "$PID"
        rm -f "$PID_FILE"
        echo "✅ 服务已停止"
    else
        echo "服务未运行"
        rm -f "$PID_FILE"
    fi
else
    # 尝试通过端口查找
    PID=$(lsof -ti:${PORT} 2>/dev/null || true)
    if [ -n "$PID" ]; then
        echo "停止服务 PID: $PID"
        kill "$PID"
        echo "✅ 服务已停止"
    else
        echo "服务未运行"
    fi
fi
