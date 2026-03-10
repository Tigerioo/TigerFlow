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
    case schedule  // 日程流
    case event     // 事件流
    case custom    // 自定义流
    case life      // 旧版生活流（兼容用）

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .task: return "任务流"
        case .schedule: return "日程流"
        case .event: return "事件流"
        case .custom: return "自定义"
        case .life: return "日程流"
        }
    }

    /// 图标名称
    var icon: String {
        switch self {
        case .task: return "checkmark.circle.fill"
        case .schedule: return "calendar"
        case .event: return "star.fill"
        case .custom: return "pin.fill"
        case .life: return "calendar"
        }
    }

    /// 是否显示 Checkbox
    var showCheckbox: Bool {
        self == .task || self == .schedule
    }

    /// 是否显示时间
    var showTime: Bool {
        self == .schedule || self == .event
    }

    /// 从字符串解码，处理未知值
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        // 将旧的生活流映射到日程流
        if rawValue == "life" {
            self = .schedule
        } else if let type = FlowType(rawValue: rawValue) {
            self = type
        } else {
            self = .schedule // 默认转为日程流
        }
    }
}
