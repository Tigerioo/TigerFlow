//
//  TimelineItemView.swift
//  tigerflow
//
//  时间线列表项视图
//

import SwiftUI
import SwiftData

/// 时间线列表项视图
struct TimelineItemView: View {
    let item: FlowItem
    let showDateCircle: Bool
    let showCheckbox: Bool

    @Environment(\.modelContext) private var modelContext
    @State private var isHovering: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左侧：DateCircle 或 Checkbox 或占位
            leftIndicator

            // 右侧：内容
            VStack(alignment: .leading, spacing: 4) {
                // 标题
                HStack {
                    Text(item.title)
                        .font(.body)
                        .lineLimit(2)
                        .strikethrough(item.isCompleted, color: .secondary)

                    if item.isMemorable {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }

                    Spacer()

                    // 优先级指示
                    if item.priority != .medium {
                        Image(systemName: item.priority.icon)
                            .font(.caption)
                            .foregroundColor(priorityColor)
                    }
                }

                // 内容（如果有）
                if let content = item.content, !content.isEmpty {
                    Text(content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // 标签和对象
                if !item.tags.isEmpty || !item.entities.isEmpty {
                    HStack(spacing: 6) {
                        // 标签
                        ForEach(item.tags) { tag in
                            TagChip(tag: tag)
                        }

                        // 对象
                        ForEach(item.entities) { entity in
                            EntityChip(entity: entity)
                        }
                    }
                    .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isHovering ? Color(.systemGray6) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            itemContextMenu
        }
    }

    // MARK: - 左侧指示器

    @ViewBuilder
    private var leftIndicator: some View {
        if showDateCircle {
            if showCheckbox {
                // Task Flow: 显示 Checkbox
                Button {
                    toggleComplete()
                } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(item.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
            } else {
                // 非 Task Flow: 显示 DateCircle
                DateCircleView(date: item.occurredAt)
            }
        } else {
            // 占位，保持对齐
            Color.clear
                .frame(width: 32, height: 32)
        }
    }

    // MARK: - 优先级颜色

    private var priorityColor: Color {
        switch item.priority {
        case .low:
            return .secondary
        case .medium:
            return .primary
        case .high:
            return .red
        }
    }

    // MARK: - 上下文菜单

    @ViewBuilder
    private var itemContextMenu: some View {
        if showCheckbox {
            Button {
                toggleComplete()
            } label: {
                Label(item.isCompleted ? "标记为未完成" : "标记为完成",
                      systemImage: item.isCompleted ? "circle" : "checkmark.circle")
            }

            // 优先级子菜单
            Menu {
                Button {
                    setPriority(.high)
                } label: {
                    Label("高", systemImage: item.priority == .high ? "checkmark" : "")
                }
                Button {
                    setPriority(.medium)
                } label: {
                    Label("中", systemImage: item.priority == .medium ? "checkmark" : "")
                }
                Button {
                    setPriority(.low)
                } label: {
                    Label("低", systemImage: item.priority == .low ? "checkmark" : "")
                }
            } label: {
                Label("优先级", systemImage: item.priority.icon)
            }

            Divider()
        }

        Button {
            // 标记为值得纪念
            item.isMemorable.toggle()
        } label: {
            Label(item.isMemorable ? "取消纪念" : "标记为纪念",
                  systemImage: item.isMemorable ? "star" : "star.fill")
        }

        if item.flowType == .task || item.flowType == .life {
            Divider()

            Button {
                // 转事件流
                promoteToEvent()
            } label: {
                Label("升级为事件", systemImage: "arrow.up.circle")
            }
        }

        Divider()

        Button {
            // 编辑
        } label: {
            Label("编辑", systemImage: "pencil")
        }

        Button(role: .destructive) {
            deleteItem()
        } label: {
            Label("删除", systemImage: "trash")
        }
    }

    // MARK: - 操作

    private func toggleComplete() {
        withAnimation {
            item.status = item.isCompleted ? .pending : .completed
            item.updatedAt = Date()
        }
    }

    private func setPriority(_ priority: FlowItemPriority) {
        withAnimation {
            item.priority = priority
            item.updatedAt = Date()
        }
    }

    private func promoteToEvent() {
        withAnimation {
            // 1. 获取或创建 Event Flow
            let eventFlow = getOrCreateEventFlow()

            // 2. 创建新的 Event Item
            let eventItem = FlowItem(
                title: item.title,
                content: item.content,
                occurredAt: Date(),
                sourceItemId: item.id,
                flow: eventFlow,
                domain: item.domain,
                isMemorable: true
            )

            // 3. 复制标签和对象
            eventItem.tags = item.tags
            eventItem.entities = item.entities

            // 4. 将原任务标记为已完成
            item.status = .completed
            item.updatedAt = Date()

            // 5. 保存
            modelContext.insert(eventItem)
        }
    }

    private func getOrCreateEventFlow() -> Flow {
        // 简单遍历获取 Event Flow（避免 Predicate 宏的枚举比较问题）
        let descriptor = FetchDescriptor<Flow>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        let allFlows = (try? modelContext.fetch(descriptor)) ?? []
        if let eventFlow = allFlows.first(where: { $0.type == .event }) {
            return eventFlow
        }

        // 创建默认 Event Flow
        let newFlow = Flow(
            name: "事件流",
            type: .event,
            icon: "star.fill",
            color: "#FFCC00",
            sortOrder: 2
        )
        modelContext.insert(newFlow)
        return newFlow
    }

    private func deleteItem() {
        withAnimation {
            modelContext.delete(item)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TimelineItemView(
            item: FlowItem(title: "完成任务", content: "这是任务内容"),
            showDateCircle: true,
            showCheckbox: true
        )

        Divider()

        TimelineItemView(
            item: FlowItem(title: "第二条记录"),
            showDateCircle: false,
            showCheckbox: false
        )
    }
}
