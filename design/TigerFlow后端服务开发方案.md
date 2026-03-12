# TigerFlow 后端服务开发方案

> 独立 Spring Boot 3.x 后端服务

---

## 1. 项目概述

### 1.1 技术栈

| 组件 | 技术版本 | 说明 |
|------|----------|------|
| Spring Boot | 3.2.x | 最新 LTS 版本 |
| Java | 17+ | Spring Boot 3.x 要求 |
| Spring Data JPA | 3.2.x | 数据访问 |
| Spring Security | 3.2.x | 安全认证 |
| MySQL | 8.0+ | 主数据库 |
| Redis | 7.0+ | Token 缓存 |
| JWT | 0.12.x | Token 生成 |
| Gradle | 8.5+ | 构建工具 |

### 1.2 项目结构

```
tigerflow/
├── backend/                      # 后端服务根目录
│   ├── tigerflow-server/        # 主应用
│   │   ├── src/main/java/
│   │   │   └── com/tigerflow/
│   │   │       ├── TigerflowApplication.java
│   │   │       ├── config/
│   │   │       ├── controller/
│   │   │       ├── service/
│   │   │       ├── repository/
│   │   │       ├── entity/
│   │   │       ├── dto/
│   │   │       ├── security/
│   │   │       └── exception/
│   │   └── src/main/resources/
│   │       └── application.yml
│   │
│   ├── tigerflow-api/           # API 公共定义
│   │   └── ...
│   │
│   └── docker/                  # Docker 部署
│       ├── Dockerfile
│       └── docker-compose.yml
│
├── design/                      # 设计文档
└── tigerflow/                   # iOS/macOS 客户端
```

---

## 2. 数据库设计 (MySQL 8.0+)

### 2.1 用户认证

```sql
-- 用户表
CREATE TABLE `tf_user` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `username` VARCHAR(50) COMMENT '用户名',
    `password` VARCHAR(255) COMMENT '密码(Bcrypt)',
    `nickname` VARCHAR(50) COMMENT '昵称',
    `email` VARCHAR(100) COMMENT '邮箱',
    `avatar_url` VARCHAR(500) COMMENT '头像',
    `phone` VARCHAR(20) COMMENT '手机号',
    `status` VARCHAR(20) DEFAULT 'active' COMMENT '状态',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE (`username`),
    UNIQUE (`phone`),
    INDEX (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 第三方登录
CREATE TABLE `tf_user_auth` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `auth_type` VARCHAR(20) NOT NULL COMMENT 'apple/wechat/phone',
    `auth_id` VARCHAR(100) NOT NULL,
    `auth_info` JSON,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (`auth_type`, `auth_id`),
    INDEX (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Token
CREATE TABLE `tf_token` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `token` VARCHAR(500) NOT NULL,
    `refresh_token` VARCHAR(500),
    `device_id` VARCHAR(64),
    `expires_at` TIMESTAMP NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (`token`),
    INDEX (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 验证码
CREATE TABLE `tf_sms_code` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `phone` VARCHAR(20) NOT NULL,
    `code` VARCHAR(6) NOT NULL,
    `purpose` VARCHAR(20) NOT NULL,
    `expires_at` TIMESTAMP NOT NULL,
    INDEX (`phone`, `code`, `purpose`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2.2 Flow 核心

```sql
-- Flow
CREATE TABLE `tf_flow` (
    `id` VARCHAR(36) PRIMARY KEY,
    `user_id` BIGINT NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `type` VARCHAR(50) NOT NULL COMMENT 'task/schedule/event/custom',
    `icon` VARCHAR(50),
    `color` VARCHAR(20),
    `is_pinned` BOOLEAN DEFAULT FALSE,
    `sort_order` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX (`user_id`),
    INDEX (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- FlowItem
CREATE TABLE `tf_flow_item` (
    `id` VARCHAR(36) PRIMARY KEY,
    `user_id` BIGINT NOT NULL,
    `flow_id` VARCHAR(36),
    `flow_type` VARCHAR(50) NOT NULL,
    `domain_id` VARCHAR(36),
    `title` VARCHAR(500) NOT NULL,
    `content` TEXT,
    `status` VARCHAR(20) DEFAULT 'pending',
    `occurred_at` TIMESTAMP NOT NULL,
    `start_time` TIMESTAMP,
    `end_time` TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX (`user_id`),
    INDEX (`flow_id`),
    INDEX (`occurred_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Domain
CREATE TABLE `tf_domain` (
    `id` VARCHAR(36) PRIMARY KEY,
    `user_id` BIGINT NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `icon` VARCHAR(50),
    `color` VARCHAR(20),
    `sort_order` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tag
CREATE TABLE `tf_tag` (
    `id` VARCHAR(36) PRIMARY KEY,
    `user_id` BIGINT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `color` VARCHAR(20) DEFAULT '#007AFF',
    `usage_count` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Entity
CREATE TABLE `tf_entity` (
    `id` VARCHAR(36) PRIMARY KEY,
    `user_id` BIGINT NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `type` VARCHAR(50) NOT NULL COMMENT 'person/company/location',
    `emoji` VARCHAR(10),
    `usage_count` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 关联表
CREATE TABLE `tf_flow_item_tag` (
    `flow_item_id` VARCHAR(36) NOT NULL,
    `tag_id` VARCHAR(36) NOT NULL,
    PRIMARY KEY (`flow_item_id`, `tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tf_flow_item_entity` (
    `flow_item_id` VARCHAR(36) NOT NULL,
    `entity_id` VARCHAR(36) NOT NULL,
    PRIMARY KEY (`flow_item_id`, `entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2.3 OneThing 项目

```sql
-- Project
CREATE TABLE `tf_project` (
    `id` VARCHAR(36) PRIMARY KEY,
    `user_id` BIGINT NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `icon` VARCHAR(10) DEFAULT '🎯',
    `color` VARCHAR(20) DEFAULT '#007AFF',
    `description` TEXT,
    `status` VARCHAR(20) DEFAULT 'active',
    `is_in_queue` BOOLEAN DEFAULT FALSE,
    `queue_order` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX (`user_id`),
    INDEX (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ProjectStage
CREATE TABLE `tf_project_stage` (
    `id` VARCHAR(36) PRIMARY KEY,
    `project_id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `type` VARCHAR(50) NOT NULL COMMENT 'general/daily/weekly/milestone',
    `sort_order` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ProjectTodo
CREATE TABLE `tf_project_todo` (
    `id` VARCHAR(36) PRIMARY KEY,
    `project_id` VARCHAR(36),
    `stage_id` VARCHAR(36),
    `title` VARCHAR(500) NOT NULL,
    `content` TEXT,
    `status` VARCHAR(20) DEFAULT 'pending',
    `priority` VARCHAR(20) DEFAULT 'medium',
    `recurrence` VARCHAR(20),
    `due_date` DATE,
    `sort_order` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX (`project_id`),
    INDEX (`stage_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 3. API 设计

### 3.1 认证接口

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/v1/auth/register | 用户名密码注册 |
| POST | /api/v1/auth/login | 用户名密码登录 |
| POST | /api/v1/auth/phone/send | 发送验证码 |
| POST | /api/v1/auth/phone/login | 手机登录 |
| POST | /api/v1/auth/apple/login | Apple 登录 |
| POST | /api/v1/auth/wechat/login | 微信登录 |
| POST | /api/v1/auth/refresh | 刷新 Token |
| POST | /api/v1/auth/logout | 登出 |

### 3.2 同步接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/sync/pull | 拉取变更 |
| POST | /api/v1/sync/push | 推送变更 |

### 3.3 数据 CRUD

| 资源 | CRUD 路径 |
|------|-----------|
| Flow | /api/v1/flows |
| FlowItem | /api/v1/flow-items |
| Domain | /api/v1/domains |
| Tag | /api/v1/tags |
| Entity | /api/v1/entities |
| Project | /api/v1/projects |
| Stage | /api/v1/stages |
| Todo | /api/v1/todos |

---

## 4. 开发步骤

### Step 1: 初始化项目 (30分钟)

1. **创建 Gradle 项目**
```bash
mkdir -p backend/tigerflow-server
cd backend/tigerflow-server
gradle init --type java-application --package com.tigerflow
```

2. **配置 build.gradle**
```groovy
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.2.5'
    id 'io.spring.dependency-management' version '1.1.4'
}

group = 'com.tigerflow'
version = '1.0.0'

java {
    sourceCompatibility = '17'
}

dependencies {
    // Spring Boot
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-data-redis'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation 'org.springframework.boot:spring-boot-starter-security'

    // MySQL
    runtimeOnly 'com.mysql:mysql-connector-j'

    // JWT
    implementation 'io.jsonwebtoken:jjwt-api:0.12.5'
    runtimeOnly 'io.jsonwebtoken:jjwt-impl:0.12.5'
    runtimeOnly 'io.jsonwebtoken:jjwt-jackson:0.12.5'

    // Lombok
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'

    // Test
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.springframework.security:spring-security-test'
}
```

3. **配置 application.yml**
```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/tigerflow?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai
    username: root
    password: root
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
  data:
    redis:
      host: localhost
      port: 6379

app:
  jwt:
    secret: tigerflow-secret-key-must-be-at-least-256-bits-long
    access-token-validity: 3600
    refresh-token-validity: 604800
```

### Step 2: 实体类 (1小时)

创建基础实体和 JPA Repository

```java
// 基础实体
@MappedSuperclass
public abstract class BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(updatable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    private LocalDateTime deletedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

### Step 3: 认证模块 (2小时)

实现 JWT 认证、登录、Token 刷新

### Step 4: 数据 CRUD (3小时)

实现各个实体的增删改查

### Step 5: 同步接口 (2小时)

实现增量同步逻辑

### Step 6: 安全配置 (1小时)

配置 Spring Security、CORS

---

## 5. 目录结构详解

```
backend/
└── tigerflow-server/
    ├── src/main/java/com/tigerflow/
    │   ├── TigerflowApplication.java
    │   │
    │   ├── config/
    │   │   ├── SecurityConfig.java
    │   │   ├── RedisConfig.java
    │   │   ├── CorsConfig.java
    │   │   └── JwtConfig.java
    │   │
    │   ├── controller/
    │   │   ├── AuthController.java
    │   │   ├── SyncController.java
    │   │   ├── FlowController.java
    │   │   └── ProjectController.java
    │   │
    │   ├── service/
    │   │   ├── AuthService.java
    │   │   ├── SyncService.java
    │   │   └── FlowService.java
    │   │
    │   ├── repository/
    │   │   ├── UserRepository.java
    │   │   ├── FlowRepository.java
    │   │   └── ...
    │   │
    │   ├── entity/
    │   │   ├── User.java
    │   │   ├── Flow.java
    │   │   ├── FlowItem.java
    │   │   └── ...
    │   │
    │   ├── dto/
    │   │   ├── request/
    │   │   │   ├── LoginRequest.java
    │   │   │   └── SyncRequest.java
    │   │   └── response/
    │   │       ├── AuthResponse.java
    │   │       └── SyncResponse.java
    │   │
    │   ├── security/
    │   │   ├── JwtTokenProvider.java
    │   │   ├── JwtAuthenticationFilter.java
    │   │   └── CustomUserDetailsService.java
    │   │
    │   └── exception/
    │       ├── GlobalExceptionHandler.java
    │       ├── BusinessException.java
    │       └── ErrorResponse.java
    │
    └── src/main/resources/
        └── application.yml
```

---

## 6. Docker 部署

### Dockerfile

```dockerfile
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/tigerflow
      - SPRING_DATA_REDIS_HOST=redis
    depends_on:
      - mysql
      - redis

  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=tigerflow
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:7-alpine

volumes:
  mysql_data:
```

---

## 7. 开发顺序

| 序号 | 任务 | 预计时间 |
|------|------|----------|
| 1 | 初始化项目、配置 | 30分钟 |
| 2 | 基础实体和 Repository | 1小时 |
| 3 | 认证模块 (JWT + 登录) | 2小时 |
| 4 | Flow/Item CRUD | 2小时 |
| 5 | Domain/Tag/Entity CRUD | 1小时 |
| 6 | Project/Stage/Todo CRUD | 2小时 |
| 7 | 同步接口 | 2小时 |
| 8 | 安全配置 | 1小时 |
| 9 | Docker 部署 | 30分钟 |

**总计: 约 12 小时**

---

## 8. 后续任务

1. **iOS 客户端实现**
   - APIClient 封装
   - 登录页面
   - 同步服务

2. **可选功能**
   - 短信验证码 (需 SMS 服务)
   - Apple 登录配置
   - 微信登录配置

---

需要我现在开始创建项目骨架和基础代码吗？