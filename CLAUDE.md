# TigerFlow 项目规范

> 本文件会自动加载为系统提示

---

## 开发流程（请配合执行）

每次完成功能开发后，请帮我执行以下步骤：

1. **构建验证**
   - iOS: `xcodebuild -project TigerFlow.xcodeproj -scheme TigerFlow -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
   - macOS: `xcodebuild -project TigerFlow.xcodeproj -scheme TigerFlow -configuration Debug -destination 'platform=macOS' build`
   - 后端: `mvn compile`

2. **更新开发日志**
   - 文件: `./开发日志.md`
   - 格式: 在 "开发中功能" 或 "已完成功能" 下添加
   - 内容: 粗颗粒度描述 + 新增文件列表

3. **Git 提交**
   - 格式: `<type>: <subject>`
   - type: feat/fix/refactor/docs/chore

4. **Git Push**
   - 推送到远程仓库

---

## 提交格式

```
<type>: <subject>

<body>
```

### Type 类型
- `feat`: 新功能
- `fix`: 修复
- `refactor`: 重构
- `docs`: 文档
- `chore`: 杂项

---

## 项目结构

```
TigerFlow/
├── tigerflow/          # iOS/macOS 客户端
├── backend/            # Spring Boot 后端服务
├── design/             # 设计文档
└── 开发日志.md          # 开发日志
```

---

## 技术栈

### 前端 (tigerflow/)
- Swift 5.9+
- SwiftUI + SwiftData
- iOS 17.0+, macOS 14.0+

### 后端 (backend/)
- Spring Boot 2.7.18
- Java 11
- MySQL 8.0+
- Redis
- JWT 认证
