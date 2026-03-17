# 服务器部署步骤 - 阿里云 PolarDB

## 1. 准备阿里云 PolarDB

1. 登录阿里云控制台
2. 创建 PolarDB MySQL 兼容版集群
3. 创建数据库: `tigerflow`
4. 创建账号: `tigerflow` / `tigerflow123`
5. 配置白名单: 添加服务器 IP

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

## 3. 配置环境变量

```bash
# 编辑启动脚本或设置环境变量
export DB_PASSWORD=你的数据库密码
export JWT_SECRET=你的JWT密钥
export CORS_ALLOWED_ORIGINS=https://你的域名
```

## 4. 启动服务

```bash
cd /你的项目目录/backend/tigerflow-server

# 创建日志目录
mkdir -p logs

# 启动服务
./start.sh
```

## 5. 验证

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

## PolarDB 连接信息

在 `application-prod.yml` 中配置：

```yaml
spring:
  datasource:
    url: jdbc:mysql://your-endpoint.polardb.cn-hangzhou.rds.aliyuncs.com:3306/tigerflow
    username: tigerflow
    password: ${DB_PASSWORD}
```

**注意**: 从阿里云控制台获取正确的连接地址。
