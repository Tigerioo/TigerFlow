//
//  ProjectTodo.swift
//  tigerflow
//
//  项目待办实体
//

import Foundation
import SwiftData

/// 项目待办实体
@Model
final class ProjectTodo {
    /// 唯一标识
    var id: UUID

    /// 待办标题
    var title: String

    /// 详细描述
    var content: String?

    /// 状态
    var status: TodoStatus

    /// 优先级
    var priority: Priority

    /// 重复规则
    var recurrence: Recurrence?

    /// 截止日期
    var dueDate: Date?

    /// 完成时间
    var completedAt: Date?

    /// 排序
    var sortOrder: Int

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    /// 关联的项目
    var project: OneThingProject?

    /// 关联的阶段
    var stage: ProjectStage?

    /// 关联的标签
    @Relationship(inverse: \Tag.projectTodos)
    var tags: [Tag]?

    /// 关联的对象
    @Relationship(inverse: \Entity.projectTodos)
    var entities: [Entity]?

    init(
        id: UUID = UUID(),
        title: String,
        content: String? = nil,
        status: TodoStatus = .pending,
        priority: Priority = .medium,
        recurrence: Recurrence? = nil,
        dueDate: Date? = nil,
        completedAt: Date? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.status = status
        self.priority = priority
        self.recurrence = recurrence
        self.dueDate = dueDate
        self.completedAt = completedAt
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = []
        self.entities = []
    }

    /// 切换完成状态
    func toggleComplete() {
        if status == .pending {
            status = .completed
            completedAt = Date()
        } else {
            status = .pending
            completedAt = nil
        }
        updatedAt = Date()
    }

    /// 是否已完成
    var isCompleted: Bool {
        status == .completed
    }
}
