# TigerFlow 后端服务 Dockerfile
# 构建: docker build -t tigerflow-server:latest .
# 运行: docker run -d -p 8080:8080 --name tigerflow-server tigerflow-server:latest

# 使用 JDK 8 基础镜像
FROM eclipse-temurin:8-jre-alpine

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建应用目录
WORKDIR /app

# 复制 JAR 文件
COPY target/tigerflow-server-1.0.0.jar app.jar

# 创建日志目录
RUN mkdir -p logs

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# 启动命令
ENTRYPOINT ["sh", "-c", "java -jar -Dspring.profiles.active=prod app.jar"]
