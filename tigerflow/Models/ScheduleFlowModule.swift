//
//  ScheduleFlowModule.swift
//  tigerflow
//
//  日程流模块实现
//

import SwiftUI
import SwiftData

/// 日程流模块
struct ScheduleFlowModule: FlowModule {
    let flowType: FlowType = .schedule

    var displayName: String { "日程流" }
    var icon: String { "calendar" }
    var showCheckbox: Bool { true }
    var showTime: Bool { true }
    var supportsSubtasks: Bool { false }
    var supportsDragReorder: Bool { false }
    var canComplete: Bool { true }

    func filterItems(_ items: [FlowItem]) -> [FlowItem] {
        items.filter { $0.flowType == .schedule || $0.flowType == .life }
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

    /// 同步任务到日程流
    func saveToLife(item: FlowItem, time: Date, modelContext: ModelContext) {
        let flow = getOrCreateFlow(context: modelContext)

        let occurredAt = combineDateAndTime(date: Date(), time: time)

        let scheduleItem = FlowItem(
            title: item.title,
            content: item.content,
            occurredAt: occurredAt,
            isFromTaskSync: true,
            sourceItemId: item.id,
            flow: flow,
            domain: item.domain,
            isMemorable: item.isMemorable
        )

        scheduleItem.tags = item.tags
        scheduleItem.entities = item.entities

        modelContext.insert(scheduleItem)
    }

    /// 将日期和时间合并
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? date
    }

    private func getOrCreateFlow(context: ModelContext) -> Flow {
        let scheduleType = FlowType.schedule
        let descriptor = FetchDescriptor<Flow>(
            predicate: #Predicate { $0.type == scheduleType },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        if let existingFlow = try? context.fetch(descriptor).first {
            return existingFlow
        }

        let newFlow = Flow(
            name: "日程流",
            type: .schedule,
            icon: "calendar",
            color: "#FF9500",
            sortOrder: 1
        )
        context.insert(newFlow)
        return newFlow
    }
}
