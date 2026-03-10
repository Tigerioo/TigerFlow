//
//  OneThingEnums.swift
//  tigerflow
//
//  OneThing 相关枚举定义
//

import Foundation

/// 项目状态
enum ProjectStatus: String, Codable, CaseIterable {
    case active    // 进行中
    case completed // 已完成
    case archived  // 已归档

    var displayName: String {
        switch self {
        case .active: return "进行中"
        case .completed: return "已完成"
        case .archived: return "已归档"
        }
    }
}

/// 阶段类型
enum StageType: String, Codable, CaseIterable {
    case general   // 一般阶段
    case daily    // 每日任务
    case weekly   // 周常任务
    case milestone // 里程碑/长期目标

    var displayName: String {
        switch self {
        case .general: return "阶段"
        case .daily: return "每日任务"
        case .weekly: return "周常任务"
        case .milestone: return "里程碑"
        }
    }

    var icon: String {
        switch self {
        case .general: return "📋"
        case .daily: return "📅"
        case .weekly: return "📆"
        case .milestone: return "🏆"
        }
    }
}

/// 待办状态
enum TodoStatus: String, Codable, CaseIterable {
    case pending   // 待处理
    case completed // 已完成

    var displayName: String {
        switch self {
        case .pending: return "待处理"
        case .completed: return "已完成"
        }
    }
}

/// 优先级
enum Priority: String, Codable, CaseIterable {
    case high
    case medium
    case low

    var displayName: String {
        switch self {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }

    var icon: String {
        switch self {
        case .high: return "↑"
        case .medium: return "-"
        case .low: return "↓"
        }
    }
}

/// 重复规则
enum Recurrence: String, Codable, CaseIterable {
    case daily   // 每日
    case weekly  // 每周

    var displayName: String {
        switch self {
        case .daily: return "每日"
        case .weekly: return "每周"
        }
    }
}
