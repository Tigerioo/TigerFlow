//
//  Domain.swift
//  tigerflow
//
//  Domain 领域实体
//

import Foundation
import SwiftData

/// Domain 实体 - 代表一个领域分类
@Model
final class Domain {
    /// 唯一标识
    var id: UUID

    /// 名称
    var name: String

    /// 图标名称 (SF Symbols)
    var icon: String

    /// 颜色 (Hex 值)
    var color: String

    /// 排序顺序
    var sortOrder: Int

    /// 创建时间
    var createdAt: Date

    /// 关联的 FlowItems
    @Relationship(inverse: \FlowItem.domain)
    var items: [FlowItem]?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        color: String = "#34C759",
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.items = []
    }
}

// MARK: - 默认 Domain 扩展
extension Domain {
    /// 创建默认的领域
    static func createDefaultDomains() -> [Domain] {
        [
            Domain(name: "工作", icon: "briefcase.fill", color: "#007AFF", sortOrder: 0),
            Domain(name: "家庭", icon: "house.fill", color: "#FF9500", sortOrder: 1),
            Domain(name: "健康", icon: "heart.fill", color: "#FF3B30", sortOrder: 2),
            Domain(name: "成长", icon: "book.fill", color: "#34C759", sortOrder: 3)
        ]
    }
}
