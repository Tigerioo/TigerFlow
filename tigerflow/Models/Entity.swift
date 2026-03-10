//
//  Entity.swift
//  tigerflow
//
//  Entity 实体 - @对象（人物、设备等）
//

import Foundation
import SwiftData

/// Entity 类型
enum EntityType: String, Codable, CaseIterable {
    case person   // 人物
    case device   // 设备
    case car      // 车辆
    case house    // 房产
    case other    // 其他

    var defaultIcon: String {
        switch self {
        case .person: return "person.fill"
        case .device: return "iphone"
        case .car: return "car.fill"
        case .house: return "house.fill"
        case .other: return "square.fill"
        }
    }
}

/// Entity 实体 - 代表一个关联对象（人物、实体）
@Model
final class Entity {
    /// 唯一标识
    var id: UUID

    /// 名称
    var name: String

    /// 类型
    var type: EntityType

    /// 头像 emoji
    var emoji: String

    /// 备注
    var note: String?

    /// 使用次数
    var usageCount: Int

    /// 创建时间
    var createdAt: Date

    /// 关联的 FlowItems
    @Relationship(inverse: \FlowItem.entities)
    var items: [FlowItem]?

    /// 关联的 OneThingProject
    var oneThingProject: OneThingProject?

    /// 关联的 ProjectTodos
    @Relationship
    var projectTodos: [ProjectTodo]?

    init(
        id: UUID = UUID(),
        name: String,
        type: EntityType = .person,
        emoji: String? = nil,
        note: String? = nil,
        usageCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.emoji = emoji ?? Entity.randomEmoji(for: type)
        self.note = note
        self.usageCount = usageCount
        self.createdAt = createdAt
        self.items = []
        self.projectTodos = []
    }

    /// 根据类型随机生成 emoji
    private static func randomEmoji(for type: EntityType) -> String {
        switch type {
        case .person:
            let emojis = ["👨", "👩", "👦", "👧", "👴", "👵", "👦", "👧", "👨‍💼", "👩‍💼"]
            return emojis.randomElement() ?? "👤"
        case .device:
            return "📱"
        case .car:
            return "🚗"
        case .house:
            return "🏠"
        case .other:
            return "📦"
        }
    }
}

// MARK: - Entity 扩展
extension Entity {
    /// 带有 @ 前缀的显示名称
    var displayName: String {
        "@\(name)"
    }
}
