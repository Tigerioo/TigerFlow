//
//  OneThingProject.swift
//  tigerflow
//
//  OneThing 项目实体
//

import Foundation
import SwiftData

/// OneThing 项目实体
@Model
final class OneThingProject {
    /// 唯一标识
    var id: UUID

    /// 项目名称
    var name: String

    /// Emoji 图标
    var icon: String

    /// 主题色 (Hex)
    var color: String

    /// 项目描述
    var descriptionText: String?

    /// 状态
    var status: ProjectStatus

    /// 是否在 OneThing 队列中
    var isInQueue: Bool

    /// 队列中的顺序
    var queueOrder: Int

    /// 排序
    var sortOrder: Int

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    /// 关联的阶段
    @Relationship(deleteRule: .cascade)
    var stages: [ProjectStage]?

    /// 关联的待办（独立待办，不属于任何阶段）
    @Relationship(deleteRule: .cascade)
    var todos: [ProjectTodo]?

    /// 关联的标签
    @Relationship(inverse: \Tag.oneThingProject)
    var tags: [Tag]?

    /// 关联的对象
    @Relationship(inverse: \Entity.oneThingProject)
    var entities: [Entity]?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "🎯",
        color: String? = nil,
        descriptionText: String? = nil,
        status: ProjectStatus = .active,
        isInQueue: Bool = false,
        queueOrder: Int = 0,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color ?? OneThingProject.randomColor()
        self.descriptionText = descriptionText
        self.status = status
        self.isInQueue = isInQueue
        self.queueOrder = queueOrder
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.stages = []
        self.todos = []
        self.tags = []
        self.entities = []
    }

    /// 随机生成一个主题色
    private static func randomColor() -> String {
        let colors = [
            "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
            "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
            "#BB8FCE", "#85C1E9", "#F8B500", "#00CED1"
        ]
        return colors.randomElement() ?? "#007AFF"
    }

    /// 获取所有待办（包括阶段中的）
    var allTodos: [ProjectTodo] {
        var result = todos ?? []
        for stage in (stages ?? []) {
            result.append(contentsOf: stage.todos ?? [])
        }
        return result
    }

    /// 获取进行中的待办数量
    var pendingTodosCount: Int {
        allTodos.filter { $0.status == .pending }.count
    }

    /// 获取已完成待办数量
    var completedTodosCount: Int {
        allTodos.filter { $0.status == .completed }.count
    }
}

// MARK: - 预设图标

extension OneThingProject {
    static let presetIcons = [
        "🎯", "📚", "💼", "🏠", "👧", "🏥", "✈️",
        "⚔️", "🎮", "💪", "🏃", "🍳", "🎨", "📖",
        "💰", "🔧", "🚗", "🌱", "☕", "🎵"
    ]
}
