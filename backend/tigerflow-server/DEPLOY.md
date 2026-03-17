# TigerFlow 后端服务部署指南

## 环境要求

| 软件 | 版本要求 | 说明 |
|------|---------|------|
| JDK | 11+ | 推荐 JDK 17 |
| MySQL | 8.0+ | 生产环境必需 |
| Docker | 20.10+ | 可选，用于容器部署 |
| Docker Compose | 2.0+ | 可选，用于容器部署 |

---

## 快速部署（Docker Compose）

最简单的部署方式，使用 Docker Compose 一键启动：

```bash
cd backend/tigerflow-server

# 启动所有服务（MySQL + 后端）
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

服务启动后：
- 后端 API: http://localhost:8080
- Swagger 文档: http://localhost:8080/swagger-ui.html

---

## 手动部署

### 1. 准备数据库

```sql
-- 登录 MySQL
mysql -u root -p

-- 创建数据库和用户
CREATE DATABASE tigerflow CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'tigerflow'@'localhost' IDENTIFIED BY 'tigerflow123';
GRANT ALL PRIVILEGES ON tigerflow.* TO 'tigerflow'@'localhost';
FLUSH PRIVILEGES;
```

### 2. 构建项目

```bash
cd backend/tigerflow-server

# 构建 JAR 文件
./deploy.sh build

# 或手动构建
mvn clean package -DskipTests
```

### 3. 配置环境变量

```bash
# 创建日志目录
mkdir -p logs

# 设置环境变量
export DB_PASSWORD=tigerflow123
export JWT_SECRET=your-secret-key-here
export CORS_ALLOWED_ORIGINS=https://your-domain.com
```

### 4. 启动服务

```bash
# 方式一：使用部署脚本
./deploy.sh start

# 方式二：直接运行
java -jar -Dspring.profiles.active=prod target/tigerflow-server-1.0.0.jar
```

### 5. 验证部署

```bash
# 检查服务状态
curl http://localhost:8080/actuator/health

# 访问 Swagger 文档
# 浏览器打开: http://your-server:8080/swagger-ui.html
```

---

## 部署脚本使用说明

```bash
# 进入部署目录
cd backend/tigerflow-server

# 查看帮助
./deploy.sh help

# 构建项目
./deploy.sh build

# 一键部署（构建+启动）
./deploy.sh deploy

# 查看服务状态
./deploy.sh status

# 查看日志
./deploy.sh logs

# 停止服务
./deploy.sh stop

# 重启服务
./deploy.sh restart

# Docker 构建
./deploy.sh docker-build

# Docker 运行
./deploy.sh docker-run -m mysql-host-ip
```

---

## 生产环境配置

### MySQL 配置建议

```ini
# my.cnf
[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
max_connections = 200
innodb_buffer_pool_size = 1G
```

### JVM 参数建议

```bash
java -Xms512m -Xmx1024m \
     -XX:+UseG1GC \
     -XX:MaxGCPauseMillis=200 \
     -Dspring.profiles.active=prod \
     -jar target/tigerflow-server-1.0.0.jar
```

### Nginx 配置示例

```nginx
upstream tigerflow {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name api.tigerflow.com;

    location / {
        proxy_pass http://tigerflow;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 安全建议

1. **修改默认密码**: 部署前修改 `DB_PASSWORD` 和 `JWT_SECRET`
2. **限制 CORS**: 生产环境设置具体的允许域名，而非 `*`
3. **使用 HTTPS**: 通过 Nginx 配置 SSL 证书
4. **防火墙**: 只开放必要端口 (80, 443, 3306)
5. **日志监控**: 定期检查日志文件

---

## 常见问题

### 1. 服务启动失败

检查日志：
```bash
./deploy.sh logs
```

常见原因：
- MySQL 未启动
- 数据库连接信息错误
- 端口被占用

### 2. 数据库连接超时

确认 MySQL 已启动：
```bash
docker-compose ps
# 或
mysql -h localhost -u tigerflow -p tigerflow123
```

### 3. 性能问题

调整 JVM 参数：
```bash
java -Xms1024m -Xmx2048m -jar target/tigerflow-server-1.0.0.jar
```

---

## 备份与恢复

### 备份数据库

```bash
mysqldump -u tigerflow -p tigerflow > backup_$(date +%Y%m%d).sql
```

### 恢复数据库

```bash
mysql -u tigerflow -p tigerflow < backup_20240101.sql
```
