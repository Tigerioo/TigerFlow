//
//  TaskFlowModule.swift
//  tigerflow
//
//  任务流模块实现
//

import SwiftUI
import SwiftData

/// 任务流模块
struct TaskFlowModule: FlowModule {
    let flowType: FlowType = .task

    var displayName: String { "任务流" }
    var icon: String { "checkmark.circle.fill" }
    var showCheckbox: Bool { true }
    var showTime: Bool { false }
    var supportsSubtasks: Bool { true }
    var supportsDragReorder: Bool { false }
    var canComplete: Bool { true }

    func filterItems(_ items: [FlowItem]) -> [FlowItem] {
        items.filter { $0.flowType == .task }
    }

    func createItem(
        title: String,
        content: String?,
        occurredAt: Date,
        tags: [Tag],
        entities: [Entity],
        modelContext: ModelContext
    ) -> FlowItem {
        let flow = getOrCreateFlow(context: modelContext)
        let item = FlowItem(
            title: title,
            content: content,
            occurredAt: occurredAt,
            flow: flow
        )
        item.tags = tags
        item.entities = entities
        return item
    }

    func toggleComplete(_ item: FlowItem) {
        item.status = item.isCompleted ? .pending : .completed
        item.updatedAt = Date()
    }

    private func getOrCreateFlow(context: ModelContext) -> Flow {
        let taskType = FlowType.task
        let descriptor = FetchDescriptor<Flow>(
            predicate: #Predicate { $0.type == taskType },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        if let existingFlow = try? context.fetch(descriptor).first {
            return existingFlow
        }

        let newFlow = Flow(
            name: "任务流",
            type: .task,
            icon: "checkmark.circle.fill",
            color: "#FF3B30",
            sortOrder: 0
        )
        context.insert(newFlow)
        return newFlow
    }
}

// MARK: - 工厂方法

extension FlowModule {
    static func module(for flowType: FlowType) -> any FlowModule {
        switch flowType {
        case .task:
            return TaskFlowModule()
        case .schedule, .life:
            return ScheduleFlowModule()
        case .event:
            return EventFlowModule()
        case .custom:
            return TaskFlowModule() // 暂时复用任务流
        }
    }
}
