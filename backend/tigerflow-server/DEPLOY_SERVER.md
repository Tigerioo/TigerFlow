# 服务器部署步骤

## 1. 准备 MySQL 数据库

```sql
-- 登录 MySQL
mysql -u root -p

-- 创建数据库和用户
CREATE DATABASE tigerflow CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'tigerflow'@'localhost' IDENTIFIED BY 'tigerflow123';
GRANT ALL PRIVILEGES ON tigerflow.* TO 'tigerflow'@'localhost';
FLUSH PRIVILEGES;
```

## 2. 上传代码到服务器

```bash
# 在服务器上执行
cd /你的项目目录

# 拉取最新代码
git pull origin dev

# 构建项目
cd backend/tigerflow-server
mvn clean package -DskipTests
```

## 3. 启动服务

```bash
cd /你的项目目录/backend/tigerflow-server

# 创建日志目录
mkdir -p logs

# 启动服务
./start.sh
```

## 4. 验证

```bash
# 检查健康状态
curl http://localhost:8080/actuator/health

# 访问 API 文档
# 浏览器打开: http://你的服务器IP:8080/swagger-ui.html
```

## 常用命令

```bash
# 启动
./start.sh

# 停止
./stop.sh

# 查看日志
tail -f logs/tigerflow-server.log

# 查看服务状态
curl http://localhost:8080/actuator/health
```

## 内存说明

start.sh 中已配置 JVM 内存：
- 初始堆: 256MB
- 最大堆: 512MB

适合 2GB 服务器运行。
