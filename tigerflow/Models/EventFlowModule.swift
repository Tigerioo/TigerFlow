//
//  EventFlowModule.swift
//  tigerflow
//
//  事件流模块实现
//

import SwiftUI
import SwiftData

/// 事件流模块
struct EventFlowModule: FlowModule {
    let flowType: FlowType = .event

    var displayName: String { "事件流" }
    var icon: String { "star.fill" }
    var showCheckbox: Bool { false }
    var showTime: Bool { true }
    var supportsSubtasks: Bool { false }
    var supportsDragReorder: Bool { false }
    var canComplete: Bool { false }  // 事件不可标记完成

    func filterItems(_ items: [FlowItem]) -> [FlowItem] {
        items.filter { $0.flowType == .event }
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
        // 事件流不支持完成操作
    }

    private func getOrCreateFlow(context: ModelContext) -> Flow {
        let eventType = FlowType.event
        let descriptor = FetchDescriptor<Flow>(
            predicate: #Predicate { $0.type == eventType },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        if let existingFlow = try? context.fetch(descriptor).first {
            return existingFlow
        }

        let newFlow = Flow(
            name: "事件流",
            type: .event,
            icon: "star.fill",
            color: "#FFCC00",
            sortOrder: 2
        )
        context.insert(newFlow)
        return newFlow
    }
}
