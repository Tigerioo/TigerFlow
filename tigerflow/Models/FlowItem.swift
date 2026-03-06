//
//  FlowItem.swift
//  tigerflow
//
//  FlowItem 实体 - 时间线中的条目
//

import Foundation
import SwiftData

/// FlowItem 状态
enum FlowItemStatus: String, Codable {
    case pending   // 待处理
    case completed // 已完成
    case cancelled // 已取消
}

/// FlowItem 优先级
enum FlowItemPriority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2

    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        }
    }
}

/// FlowItem 实体 - 时间线中的条目
@Model
final class FlowItem {
    /// 唯一标识
    var id: UUID

    /// 标题
    var title: String

    /// 内容/描述
    var content: String?

    /// 发生时间
    var occurredAt: Date

    /// 结束时间（用于任务）
    var endAt: Date?

    /// 状态
    var status: FlowItemStatus

    /// 优先级
    var priority: FlowItemPriority

    /// 是否从任务同步而来
    var isFromTaskSync: Bool

    /// 来源条目 ID（用于追溯链）
    var sourceItemId: UUID?

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    /// 所属 Flow
    var flow: Flow?

    /// 所属领域
    var domain: Domain?

    /// 关联的标签
    var tags: [Tag] = []

    /// 关联的对象
    var entities: [Entity] = []

    /// 是否标记为值得纪念（用于升级到 Event）
    var isMemorable: Bool

    init(
        id: UUID = UUID(),
        title: String,
        content: String? = nil,
        occurredAt: Date = Date(),
        endAt: Date? = nil,
        status: FlowItemStatus = .pending,
        priority: FlowItemPriority = .medium,
        isFromTaskSync: Bool = false,
        sourceItemId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        flow: Flow? = nil,
        domain: Domain? = nil,
        isMemorable: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.occurredAt = occurredAt
        self.endAt = endAt
        self.status = status
        self.priority = priority
        self.isFromTaskSync = isFromTaskSync
        self.sourceItemId = sourceItemId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.flow = flow
        self.domain = domain
        self.isMemorable = isMemorable
    }
}

// MARK: - FlowItem 计算属性
extension FlowItem {
    /// 是否已完成
    var isCompleted: Bool {
        status == .completed
    }

    /// 所属 Flow 类型
    var flowType: FlowType? {
        flow?.type
    }

    /// 是否显示 Checkbox（仅任务流显示）
    var showCheckbox: Bool {
        flowType == .task
    }
}

// MARK: - FlowItem 日期分组
extension FlowItem {
    /// 按日期分组使用的日期（只保留年月日）
    var dateKey: Date {
        Calendar.current.startOfDay(for: occurredAt)
    }

    /// 月份 Key（格式：yyyy-MM）
    var monthKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: occurredAt)
    }

    /// 年份 Key
    var yearKey: Int {
        Calendar.current.component(.year, from: occurredAt)
    }
}
