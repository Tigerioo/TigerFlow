//
//  FlowModule.swift
//  tigerflow
//
//  Flow 模块协议 - 定义各 Flow 的行为规范
//

import SwiftUI
import SwiftData

/// Flow 模块协议 - 定义各 Flow 的行为规范
protocol FlowModule {
    /// Flow 类型
    var flowType: FlowType { get }

    /// 显示名称
    var displayName: String { get }

    /// 图标
    var icon: String { get }

    /// 是否显示 Checkbox（仅任务流）
    var showCheckbox: Bool { get }

    /// 是否显示时间（日程流、事件流）
    var showTime: Bool { get }

    /// 是否支持子任务（仅任务流）
    var supportsSubtasks: Bool { get }

    /// 是否支持拖拽排序
    var supportsDragReorder: Bool { get }

    /// 数据过滤：根据 FlowType 过滤 Items
    func filterItems(_ items: [FlowItem]) -> [FlowItem]

    /// 创建 Item
    func createItem(
        title: String,
        content: String?,
        occurredAt: Date,
        tags: [Tag],
        entities: [Entity],
        modelContext: ModelContext
    ) -> FlowItem

    /// 切换完成状态
    func toggleComplete(_ item: FlowItem)

    /// 是否可以完成（某些 Flow 可能不允许）
    var canComplete: Bool { get }
}

// MARK: - 默认实现

extension FlowModule {
    var showCheckbox: Bool { false }
    var showTime: Bool { false }
    var supportsSubtasks: Bool { false }
    var supportsDragReorder: Bool { false }
    var canComplete: Bool { true }
}
