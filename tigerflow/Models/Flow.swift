//
//  Flow.swift
//  tigerflow
//
//  Flow 实体模型
//

import Foundation
import SwiftData

/// Flow 实体 - 代表一个流程/列表
@Model
final class Flow {
    /// 唯一标识
    var id: UUID

    /// 名称
    var name: String

    /// 类型
    var type: FlowType

    /// 图标名称 (SF Symbols)
    var icon: String

    /// 颜色 (Hex 值)
    var color: String

    /// 是否置顶/跟踪中
    var isPinned: Bool

    /// 排序顺序
    var sortOrder: Int

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    /// 关联的 FlowItems
    @Relationship(deleteRule: .cascade, inverse: \FlowItem.flow)
    var items: [FlowItem]?

    init(
        id: UUID = UUID(),
        name: String,
        type: FlowType,
        icon: String? = nil,
        color: String? = nil,
        isPinned: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon ?? type.icon
        self.color = color ?? "#007AFF" // 默认蓝色
        self.isPinned = isPinned
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = []
    }
}

// MARK: - 默认 Flow 扩展
extension Flow {
    /// 创建默认的系统 Flow
    static func createDefaultFlows() -> [Flow] {
        [
            Flow(name: "任务流", type: .task, icon: "checkmark.circle.fill", color: "#FF3B30", sortOrder: 0),
            Flow(name: "日程流", type: .schedule, icon: "calendar", color: "#FF9500", sortOrder: 1),
            Flow(name: "事件流", type: .event, icon: "star.fill", color: "#FFCC00", sortOrder: 2)
        ]
    }
}
