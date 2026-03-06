//
//  FlowType.swift
//  tigerflow
//
//  Flow 类型枚举
//

import Foundation

/// Flow 类型枚举
enum FlowType: String, Codable, CaseIterable, Identifiable {
    case task      // 任务流
    case life     // 生活流
    case event    // 事件流
    case custom   // 自定义流

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .task: return "任务流"
        case .life: return "生活流"
        case .event: return "事件流"
        case .custom: return "自定义"
        }
    }

    /// 图标名称
    var icon: String {
        switch self {
        case .task: return "checkmark.circle.fill"
        case .life: return "heart.fill"
        case .event: return "star.fill"
        case .custom: return "pin.fill"
        }
    }

    /// 是否显示 Checkbox
    var showCheckbox: Bool {
        self == .task
    }
}
