# TigerFlow 数据库表设计

> 本文档基于 PolarDB (MySQL 5.7 兼容) 设计
> 生成时间: 2026-03-20

---

## 数据库初始化

```sql
-- 创建数据库
CREATE DATABASE tigerflow DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 使用数据库
USE tigerflow;
```

---

## 表结构总览

| 表名 | 说明 | 主要字段 |
|------|------|----------|
| tf_user | 用户表 | username, password, email, apple_user_id |
| tf_token | 认证令牌表 | user_id, token, refresh_token, expires_at |
| tf_flow | 流程类型表 | user_id, name, type, icon, color |
| tf_flow_item | 流程项表 | user_id, flow_id, title, content, status, occurred_at |
| tf_domain | 领域表 | user_id, name, icon, color |
| tf_tag | 标签表 | user_id, name, color, usage_count |
| tf_entity | 实体表(人物等) | user_id, name, type, emoji |
| tf_project | OneThing项目表 | user_id, name, icon, status, is_in_queue |
| tf_project_stage | 项目阶段表 | project_id, name, type, sort_order |
| tf_project_todo | 项目待办表 | project_id, stage_id, title, status, priority |

---

## 1. 用户表 (tf_user)

存储用户基本信息。

```sql
CREATE TABLE tf_user (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    username        VARCHAR(50) COMMENT '用户名(登录名)',
    password        VARCHAR(255) COMMENT '密码(BCrypt加密)',
    nickname        VARCHAR(50) COMMENT '昵称',
    email           VARCHAR(100) COMMENT '邮箱(唯一)',
    avatar_url      VARCHAR(500) COMMENT '头像URL',
    phone           VARCHAR(20) COMMENT '手机号(唯一)',
    status          VARCHAR(20) DEFAULT 'active' COMMENT '状态: active-正常, disabled-禁用',
    apple_user_id   VARCHAR(100) COMMENT 'Apple用户ID(唯一)',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME COMMENT '软删除时间',

    UNIQUE KEY uk_username (username),
    UNIQUE KEY uk_email (email),
    UNIQUE KEY uk_phone (phone),
    UNIQUE KEY uk_apple_user_id (apple_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';
```

### 索引说明

| 索引名 | 字段 | 类型 | 说明 |
|--------|------|------|------|
| uk_username | username | UNIQUE | 用户名唯一 |
| uk_email | email | UNIQUE | 邮箱唯一 |
| uk_phone | phone | UNIQUE | 手机号唯一 |
| uk_apple_user_id | apple_user_id | UNIQUE | Apple登录唯一 |

---

## 2. 认证令牌表 (tf_token)

存储用户登录令牌和设备信息。

```sql
CREATE TABLE tf_token (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id         BIGINT NOT NULL COMMENT '用户ID',
    token           VARCHAR(500) NOT NULL COMMENT 'JWT Token',
    refresh_token   VARCHAR(500) COMMENT '刷新Token',
    device_id       VARCHAR(64) COMMENT '设备ID',
    device_name     VARCHAR(100) COMMENT '设备名称',
    expires_at      DATETIME NOT NULL COMMENT '过期时间',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME COMMENT '软删除时间',

    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='认证令牌表';
```

### 索引说明

| 索引名 | 字段 | 说明 |
|--------|------|------|
| idx_user_id | user_id | 用户查询索引 |
| idx_expires_at | expires_at | 过期时间索引(清理过期Token用) |

---

## 3. 流程类型表 (tf_flow)

定义用户的流程类型，如任务、日程、事件等。

```sql
CREATE TABLE tf_flow (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id         BIGINT NOT NULL COMMENT '用户ID',
    name            VARCHAR(100) NOT NULL COMMENT '流程名称',
    type            VARCHAR(50) NOT NULL COMMENT '流程类型: task-任务, schedule-日程, event-事件, custom-自定义',
    icon            VARCHAR(50) COMMENT '图标',
    color           VARCHAR(20) COMMENT '颜色',
    is_pinned       TINYINT(1) DEFAULT 0 COMMENT '是否置顶',
    sort_order      INT DEFAULT 0 COMMENT '排序顺序',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME COMMENT '软删除时间',

    INDEX idx_user_id (user_id),
    INDEX idx_user_type (user_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='流程类型表';
```

### 字段说明

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| type | VARCHAR(50) | 流程类型 | task, schedule, event, custom |
| is_pinned | TINYINT(1) | 是否置顶显示 | 0-否, 1-是 |
| sort_order | INT | 排序顺序(越小越靠前) | 0, 1, 2... |

---

## 4. 流程项表 (tf_flow_item)

存储具体的流程记录，如一个任务、一条日程。

```sql
CREATE TABLE tf_flow_item (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id         BIGINT NOT NULL COMMENT '用户ID',
    flow_id         VARCHAR(36) COMMENT '所属流程ID',
    flow_type       VARCHAR(50) NOT NULL COMMENT '流程类型: task-任务, schedule-日程, event-事件',
    domain_id       VARCHAR(36) COMMENT '所属领域ID',
    title           VARCHAR(500) NOT NULL COMMENT '标题',
    content         TEXT COMMENT '内容/描述',
    status          VARCHAR(20) DEFAULT 'pending' COMMENT '状态: pending-待处理, completed-已完成',
    occurred_at     DATETIME NOT NULL COMMENT '发生/记录时间',
    start_time      DATETIME COMMENT '开始时间',
    end_time        DATETIME COMMENT '结束时间',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME COMMENT '软删除时间',

    INDEX idx_user_id (user_id),
    INDEX idx_flow_id (flow_id),
    INDEX idx_flow_type (flow_type),
    INDEX idx_status (status),
    INDEX idx_occurred_at (occurred_at),
    INDEX idx_user_occurred (user_id, occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='流程项表';
```

### 索引说明

| 索引名 | 字段 | 说明 |
|--------|------|------|
| idx_flow_id | flow_id | 按流程筛选 |
| idx_flow_type | flow_type | 按类型筛选 |
| idx_status | status | 按状态筛选 |
| idx_occurred_at | occurred_at | 按时间排序 |
| idx_user_occurred | (user_id, occurred_at) | 用户时间线查询 |

---

## 5. 领域表 (tf_domain)

用于组织和分类流程项的领域/分类。

```sql
CREATE TABLE tf_domain (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id         BIGINT NOT NULL COMMENT '用户ID',
    name            VARCHAR(100) NOT NULL COMMENT '领域名称',
    icon            VARCHAR(50) COMMENT '图标',
    color           VARCHAR(20) COMMENT '颜色',
    sort_order      INT DEFAULT 0 COMMENT '排序顺序',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME COMMENT '软删除时间',

    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='领域表';
```

---

## 6. 标签表 (tf_tag)

用于给流程项打标签。

```sql
CREATE TABLE tf_tag (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id         BIGINT NOT NULL COMMENT '用户ID',
    name            VARCHAR(100) NOT NULL COMMENT '标签名称',
    color           VARCHAR(20) DEFAULT '#007AFF' COMMENT '颜色',
    usage_count     INT DEFAULT 0 COMMENT '使用次数',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME COMMENT '软删除时间',

    INDEX idx_user_id (user_id),
    INDEX idx_user_name (user_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标签表';
```

---

## 7. 实体表 (tf_entity)

存储人物、公司等实体信息，用于流程项关联。

```sql
CREATE TABLE tf_entity (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id         BIGINT NOT NULL COMMENT '用户ID',
    name            VARCHAR(100) NOT NULL COMMENT '实体名称',
    type            VARCHAR(50) NOT NULL COMMENT '实体类型: person-人物, company-公司, location-地点',
    emoji           VARCHAR(10) COMMENT '表情图标',
    usage_count     INT DEFAULT 0 COMMENT '使用次数',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME COMMENT '软删除时间',

    INDEX idx_user_id (user_id),
    INDEX idx_user_type (user_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='实体表';
```

---

## 8. 项目表 (tf_project)

OneThing 项目管理的主表。

```sql
CREATE TABLE tf_project (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id         BIGINT NOT NULL COMMENT '用户ID',
    name            VARCHAR(100) NOT NULL COMMENT '项目名称',
    icon            VARCHAR(10) DEFAULT '🎯' COMMENT '图标',
    color           VARCHAR(20) DEFAULT '#007AFF' COMMENT '颜色',
    description     TEXT COMMENT '项目描述',
    status          VARCHAR(20) DEFAULT 'active' COMMENT '状态: active-进行中, completed-已完成, archived-归档',
    is_in_queue     TINYINT(1) DEFAULT 0 COMMENT '是否在队列中',
    queue_order     INT DEFAULT 0 COMMENT '队列顺序',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME COMMENT '软删除时间',

    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_queue (user_id, is_in_queue, queue_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目表';
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| status | VARCHAR(20) | active/completed/archived |
| is_in_queue | TINYINT(1) | 是否在执行队列中 |
| queue_order | INT | 队列中的排序 |

---

## 9. 项目阶段表 (tf_project_stage)

项目的阶段/列表，如"待办"、"进行中"、"已完成"。

```sql
CREATE TABLE tf_project_stage (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    project_id      VARCHAR(36) NOT NULL COMMENT '项目ID',
    name            VARCHAR(100) NOT NULL COMMENT '阶段名称',
    type            VARCHAR(50) NOT NULL COMMENT '阶段类型: general-常规, daily-每日, weekly-每周, milestone-里程碑',
    sort_order      INT DEFAULT 0 COMMENT '排序顺序',
    is_collapsed    TINYINT(1) DEFAULT 0 COMMENT '是否折叠',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME COMMENT '软删除时间',

    INDEX idx_project_id (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目阶段表';
```

---

## 10. 项目待办表 (tf_project_todo)

项目阶段下的具体待办事项。

```sql
CREATE TABLE tf_project_todo (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    project_id      VARCHAR(36) COMMENT '所属项目ID',
    stage_id        VARCHAR(36) COMMENT '所属阶段ID',
    title           VARCHAR(500) NOT NULL COMMENT '待办标题',
    content         TEXT COMMENT '待办内容',
    status          VARCHAR(20) DEFAULT 'pending' COMMENT '状态: pending-待处理, completed-已完成',
    priority       VARCHAR(20) DEFAULT 'medium' COMMENT '优先级: high-高, medium-中, low-低',
    recurrence      VARCHAR(20) COMMENT '重复周期: daily-每日, weekly-每周',
    due_date        DATE COMMENT '截止日期',
    sort_order      INT DEFAULT 0 COMMENT '排序顺序',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME COMMENT '软删除时间',

    INDEX idx_project_id (project_id),
    INDEX idx_stage_id (stage_id),
    INDEX idx_status (status),
    INDEX idx_due_date (due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目待办表';
```

---

## ER 关系图

```
┌─────────────┐       ┌─────────────┐
│   tf_user   │──────<│  tf_token   │
└─────────────┘       └─────────────┘
       │
       ├──────────────────────────────┐
       │                              │
       ▼                              ▼
┌─────────────┐              ┌─────────────┐
│  tf_flow    │              │ tf_flow_item│
└─────────────┘              └─────────────┘
       │                              │
       │                              ▼
       │                      ┌─────────────┐
       ├─────────────────────>│ tf_domain    │
       │                      └─────────────┘
       │
       ├──────────────────────>┌─────────────┐
       │                      │ tf_tag       │
       └──────────────────────┌─────────────┘
       │                      │
       │                      ▼
       │              ┌─────────────┐
       └─────────────>│ tf_entity   │
                      └─────────────┘


┌─────────────┐       ┌──────────────────┐
│ tf_project │──────<│ tf_project_stage│
└─────────────┘       └──────────────────┘
                              │
                              ▼
                      ┌──────────────────┐
                      │ tf_project_todo  │
                      └──────────────────┘
```

---

## 一键执行脚本

```sql
-- TigerFlow 数据库初始化脚本
-- 适用于 PolarDB (MySQL 5.7 兼容)

-- 创建数据库
CREATE DATABASE IF NOT EXISTS tigerflow DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tigerflow;

-- 1. 用户表
CREATE TABLE IF NOT EXISTS tf_user (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(50),
    password        VARCHAR(255),
    nickname        VARCHAR(50),
    email           VARCHAR(100),
    avatar_url      VARCHAR(500),
    phone           VARCHAR(20),
    status          VARCHAR(20) DEFAULT 'active',
    apple_user_id   VARCHAR(100),
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    UNIQUE KEY uk_username (username),
    UNIQUE KEY uk_email (email),
    UNIQUE KEY uk_phone (phone),
    UNIQUE KEY uk_apple_user_id (apple_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 2. 认证令牌表
CREATE TABLE IF NOT EXISTS tf_token (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    token           VARCHAR(500) NOT NULL,
    refresh_token   VARCHAR(500),
    device_id       VARCHAR(64),
    device_name     VARCHAR(100),
    expires_at      DATETIME NOT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='认证令牌表';

-- 3. 流程类型表
CREATE TABLE IF NOT EXISTS tf_flow (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    type            VARCHAR(50) NOT NULL,
    icon            VARCHAR(50),
    color           VARCHAR(20),
    is_pinned       TINYINT(1) DEFAULT 0,
    sort_order      INT DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    INDEX idx_user_id (user_id),
    INDEX idx_user_type (user_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='流程类型表';

-- 4. 流程项表
CREATE TABLE IF NOT EXISTS tf_flow_item (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    flow_id         VARCHAR(36),
    flow_type       VARCHAR(50) NOT NULL,
    domain_id       VARCHAR(36),
    title           VARCHAR(500) NOT NULL,
    content         TEXT,
    status          VARCHAR(20) DEFAULT 'pending',
    occurred_at     DATETIME NOT NULL,
    start_time      DATETIME,
    end_time        DATETIME,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    INDEX idx_user_id (user_id),
    INDEX idx_flow_id (flow_id),
    INDEX idx_flow_type (flow_type),
    INDEX idx_status (status),
    INDEX idx_occurred_at (occurred_at),
    INDEX idx_user_occurred (user_id, occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='流程项表';

-- 5. 领域表
CREATE TABLE IF NOT EXISTS tf_domain (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    icon            VARCHAR(50),
    color           VARCHAR(20),
    sort_order      INT DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='领域表';

-- 6. 标签表
CREATE TABLE IF NOT EXISTS tf_tag (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    color           VARCHAR(20) DEFAULT '#007AFF',
    usage_count     INT DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    INDEX idx_user_id (user_id),
    INDEX idx_user_name (user_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标签表';

-- 7. 实体表
CREATE TABLE IF NOT EXISTS tf_entity (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    type            VARCHAR(50) NOT NULL,
    emoji           VARCHAR(10),
    usage_count     INT DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    INDEX idx_user_id (user_id),
    INDEX idx_user_type (user_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='实体表';

-- 8. 项目表
CREATE TABLE IF NOT EXISTS tf_project (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    icon            VARCHAR(10) DEFAULT '🎯',
    color           VARCHAR(20) DEFAULT '#007AFF',
    description     TEXT,
    status          VARCHAR(20) DEFAULT 'active',
    is_in_queue     TINYINT(1) DEFAULT 0,
    queue_order     INT DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_queue (user_id, is_in_queue, queue_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目表';

-- 9. 项目阶段表
CREATE TABLE IF NOT EXISTS tf_project_stage (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_id      VARCHAR(36) NOT NULL,
    name            VARCHAR(100) NOT NULL,
    type            VARCHAR(50) NOT NULL,
    sort_order      INT DEFAULT 0,
    is_collapsed    TINYINT(1) DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    INDEX idx_project_id (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目阶段表';

-- 10. 项目待办表
CREATE TABLE IF NOT EXISTS tf_project_todo (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_id      VARCHAR(36),
    stage_id        VARCHAR(36),
    title           VARCHAR(500) NOT NULL,
    content         TEXT,
    status          VARCHAR(20) DEFAULT 'pending',
    priority        VARCHAR(20) DEFAULT 'medium',
    recurrence      VARCHAR(20),
    due_date        DATE,
    sort_order      INT DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    INDEX idx_project_id (project_id),
    INDEX idx_stage_id (stage_id),
    INDEX idx_status (status),
    INDEX idx_due_date (due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目待办表';
```

---

## 维护脚本

### 清理过期 Token

```sql
-- 清理7天前过期的Token
DELETE FROM tf_token
WHERE expires_at < DATE_SUB(NOW(), INTERVAL 7 DAY);
```

### 软删除数据查询

```sql
-- 查看用户的所有数据(包括已删除)
SELECT 'flow_item' as table_name, id, title, deleted_at FROM tf_flow_item WHERE user_id = ? AND deleted_at IS NOT NULL
UNION ALL
SELECT 'tag' as table_name, id, name, deleted_at FROM tf_tag WHERE user_id = ? AND deleted_at IS NOT NULL
UNION ALL
SELECT 'project' as table_name, id, name, deleted_at FROM tf_project WHERE user_id = ? AND deleted_at IS NOT NULL;
```
