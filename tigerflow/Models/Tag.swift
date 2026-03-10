//
//  Tag.swift
//  tigerflow
//
//  Tag 标签实体
//

import Foundation
import SwiftData

/// Tag 实体 - 代表一个标签
@Model
final class Tag {
    /// 唯一标识
    var id: UUID

    /// 名称 (不含 #)
    var name: String

    /// 颜色 (Hex 值)
    var color: String

    /// 使用次数
    var usageCount: Int

    /// 创建时间
    var createdAt: Date

    /// 关联的 FlowItems
    @Relationship(inverse: \FlowItem.tags)
    var items: [FlowItem]?

    /// 关联的 OneThingProject
    var oneThingProject: OneThingProject?

    /// 关联的 ProjectTodos
    @Relationship
    var projectTodos: [ProjectTodo]?

    init(
        id: UUID = UUID(),
        name: String,
        color: String? = nil,
        usageCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        // 自动生成颜色或使用传入的颜色
        if let color = color {
            self.color = color
        } else {
            self.color = Tag.randomColor()
        }
        self.usageCount = usageCount
        self.createdAt = createdAt
        self.items = []
        self.projectTodos = []
    }

    /// 随机生成一个柔和的颜色
    private static func randomColor() -> String {
        let colors = [
            "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
            "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
            "#BB8FCE", "#85C1E9", "#F8B500", "#00CED1"
        ]
        return colors.randomElement() ?? "#007AFF"
    }
}

// MARK: - Tag 扩展
extension Tag {
    /// 带有 # 前缀的显示名称
    var displayName: String {
        "#\(name)"
    }
}
