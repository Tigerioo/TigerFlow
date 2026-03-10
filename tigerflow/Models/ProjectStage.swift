//
//  ProjectStage.swift
//  tigerflow
//
//  项目阶段实体
//

import Foundation
import SwiftData

/// 项目阶段实体
@Model
final class ProjectStage {
    /// 唯一标识
    var id: UUID

    /// 阶段名称
    var name: String

    /// 阶段类型
    var type: StageType

    /// 排序
    var sortOrder: Int

    /// 是否折叠
    var isCollapsed: Bool

    /// 创建时间
    var createdAt: Date

    /// 关联的项目
    var project: OneThingProject?

    /// 关联的待办
    @Relationship(deleteRule: .cascade)
    var todos: [ProjectTodo]?

    init(
        id: UUID = UUID(),
        name: String,
        type: StageType = .general,
        sortOrder: Int = 0,
        isCollapsed: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.sortOrder = sortOrder
        self.isCollapsed = isCollapsed
        self.createdAt = createdAt
        self.todos = []
    }

    /// 获取进行中的待办数量
    var pendingTodosCount: Int {
        todos?.filter { $0.status == .pending }.count ?? 0
    }

    /// 获取已完成待办数量
    var completedTodosCount: Int {
        todos?.filter { $0.status == .completed }.count ?? 0
    }
}
