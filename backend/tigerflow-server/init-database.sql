-- TigerFlow 数据库建表脚本
-- 适用于 PolarDB (MySQL 5.7 兼容)
-- 使用前请先创建数据库: CREATE DATABASE tigerflow DEFAULT CHARACTER SET utf8mb4;

USE tigerflow;

-- 1. 用户表
CREATE TABLE IF NOT EXISTS tf_user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50), password VARCHAR(255), nickname VARCHAR(50),
    email VARCHAR(100), avatar_url VARCHAR(500), phone VARCHAR(20),
    status VARCHAR(20) DEFAULT 'active', apple_user_id VARCHAR(100),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    UNIQUE KEY uk_username (username), UNIQUE KEY uk_email (email),
    UNIQUE KEY uk_phone (phone), UNIQUE KEY uk_apple_user_id (apple_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 2. 认证令牌表
CREATE TABLE IF NOT EXISTS tf_token (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
    token VARCHAR(500) NOT NULL, refresh_token VARCHAR(500),
    device_id VARCHAR(64), device_name VARCHAR(100), expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME, INDEX idx_user_id (user_id), INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='认证令牌表';

-- 3. 流程类型表
CREATE TABLE IF NOT EXISTS tf_flow (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL, type VARCHAR(50) NOT NULL,
    icon VARCHAR(50), color VARCHAR(20), is_pinned TINYINT(1) DEFAULT 0,
    sort_order INT DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME, INDEX idx_user_id (user_id), INDEX idx_user_type (user_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='流程类型表';

-- 4. 流程项表
CREATE TABLE IF NOT EXISTS tf_flow_item (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
    flow_id VARCHAR(36), flow_type VARCHAR(50) NOT NULL, domain_id VARCHAR(36),
    title VARCHAR(500) NOT NULL, content TEXT, status VARCHAR(20) DEFAULT 'pending',
    occurred_at DATETIME NOT NULL, start_time DATETIME, end_time DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME, INDEX idx_user_id (user_id), INDEX idx_flow_id (flow_id),
    INDEX idx_flow_type (flow_type), INDEX idx_status (status),
    INDEX idx_occurred_at (occurred_at), INDEX idx_user_occurred (user_id, occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='流程项表';

-- 5. 领域表
CREATE TABLE IF NOT EXISTS tf_domain (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL, icon VARCHAR(50), color VARCHAR(20),
    sort_order INT DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME, INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='领域表';

-- 6. 标签表
CREATE TABLE IF NOT EXISTS tf_tag (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL, color VARCHAR(20) DEFAULT '#007AFF',
    usage_count INT DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME, INDEX idx_user_id (user_id), INDEX idx_user_name (user_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标签表';

-- 7. 实体表
CREATE TABLE IF NOT EXISTS tf_entity (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL, type VARCHAR(50) NOT NULL, emoji VARCHAR(10),
    usage_count INT DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME, INDEX idx_user_id (user_id), INDEX idx_user_type (user_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='实体表';

-- 8. 项目表
CREATE TABLE IF NOT EXISTS tf_project (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL, icon VARCHAR(10) DEFAULT '🎯', color VARCHAR(20) DEFAULT '#007AFF',
    description TEXT, status VARCHAR(20) DEFAULT 'active', is_in_queue TINYINT(1) DEFAULT 0,
    queue_order INT DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME, INDEX idx_user_id (user_id), INDEX idx_status (status),
    INDEX idx_queue (user_id, is_in_queue, queue_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目表';

-- 9. 项目阶段表
CREATE TABLE IF NOT EXISTS tf_project_stage (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, project_id VARCHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL, type VARCHAR(50) NOT NULL, sort_order INT DEFAULT 0,
    is_collapsed TINYINT(1) DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME, INDEX idx_project_id (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目阶段表';

-- 10. 项目待办表
CREATE TABLE IF NOT EXISTS tf_project_todo (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, project_id VARCHAR(36), stage_id VARCHAR(36),
    title VARCHAR(500) NOT NULL, content TEXT, status VARCHAR(20) DEFAULT 'pending',
    priority VARCHAR(20) DEFAULT 'medium', recurrence VARCHAR(20), due_date DATE,
    sort_order INT DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME, INDEX idx_project_id (project_id), INDEX idx_stage_id (stage_id),
    INDEX idx_status (status), INDEX idx_due_date (due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目待办表';
