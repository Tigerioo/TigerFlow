//
//  AppState.swift
//  tigerflow
//
//  应用状态管理
//

import Foundation
import SwiftUI

/// Sidebar 项目枚举
enum SidebarItem: Hashable, Identifiable {
    case flow(FlowType)           // 系统 Flow（任务流、生活流、事件流）
    case customFlow(UUID)         // 自定义 Flow
    case domain(UUID)             // 领域
    case person(UUID)             // 人物
    case tag(UUID)                // 标签

    var id: String {
        switch self {
        case .flow(let type):
            return "flow-\(type.rawValue)"
        case .customFlow(let id):
            return "custom-\(id.uuidString)"
        case .domain(let id):
            return "domain-\(id.uuidString)"
        case .person(let id):
            return "person-\(id.uuidString)"
        case .tag(let id):
            return "tag-\(id.uuidString)"
        }
    }

    /// 显示名称
    var displayName: String {
        switch self {
        case .flow(let type):
            return type.displayName
        case .customFlow:
            return "自定义"
        case .domain:
            return "领域"
        case .person:
            return "人物"
        case .tag:
            return "标签"
        }
    }

    /// 图标名称
    var icon: String {
        switch self {
        case .flow(let type):
            return type.icon
        case .customFlow:
            return "pin.fill"
        case .domain:
            return "folder.fill"
        case .person:
            return "person.fill"
        case .tag:
            return "tag.fill"
        }
    }
}

/// Flow 筛选条件
struct FlowFilter: Equatable {
    var domains: Set<UUID> = []
    var tags: Set<UUID> = []
    var entities: Set<UUID> = []
    var status: FlowItemStatus? = nil
    var priority: FlowItemPriority? = nil

    var isEmpty: Bool {
        domains.isEmpty && tags.isEmpty && entities.isEmpty && status == nil && priority == nil
    }

    mutating func reset() {
        domains = []
        tags = []
        entities = []
        status = nil
        priority = nil
    }
}

/// 应用全局状态
@Observable
class AppState {
    // MARK: - 导航状态

    /// 当前选中的 Sidebar 项目
    var selectedSidebarItem: SidebarItem? = .flow(.task) {
        didSet {
            if selectedSidebarItem != nil {
                selectedItemId = nil
            }
        }
    }

    /// 当前选中的 FlowItem ID
    var selectedItemId: UUID? = nil

    // MARK: - 搜索与筛选

    /// 搜索文本
    var searchText: String = ""

    /// 筛选条件
    var filters: FlowFilter = FlowFilter()

    // MARK: - 视图状态

    /// Sidebar 可见性
    var sidebarVisibility: NavigationSplitViewVisibility = .all

    /// 是否正在创建新条目
    var isCreating: Bool = false

    /// 是否显示筛选面板
    var showingFilters: Bool = false

    // MARK: - 便捷方法

    /// 获取当前选中的 FlowType
    var currentFlowType: FlowType? {
        if case .flow(let type) = selectedSidebarItem {
            return type
        }
        return nil
    }

    /// 是否处于筛选模式
    var isFiltering: Bool {
        !filters.isEmpty || !searchText.isEmpty
    }

    /// 重置筛选条件
    func resetFilters() {
        filters.reset()
        searchText = ""
    }

    /// 选中默认的 Flow
    func selectDefaultFlow() {
        selectedSidebarItem = .flow(.task)
    }
}
