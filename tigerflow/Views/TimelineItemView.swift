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
    let showCheckbox: Bool
    var isFirstOfDay: Bool = false  // 是否是每天第一条
    var isLastOfDay: Bool = false   // 是否是每天最后一条

    @Environment(\.modelContext) private var modelContext
    @State private var isHovering: Bool = false

    // 主题紫色
    private let themePurple = Color.accentColor

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左侧：复选框或占位
            checkboxView
                .frame(width: 24, height: 24)

            // 右侧：内容
            VStack(alignment: .leading, spacing: 6) {
                // 标题行
                HStack(alignment: .center, spacing: 8) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(item.isCompleted ? .regular : .medium)
                        .foregroundColor(item.isCompleted ? .secondary : .primary)
                        .strikethrough(item.isCompleted, color: item.isCompleted ? themePurple.opacity(0.6) : .clear)
                        .lineLimit(2)

                    Spacer()

                    // 优先级和纪念标识
                    HStack(spacing: 6) {
                        if item.isMemorable {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }

                        if item.priority != .medium && !item.isCompleted {
                            Image(systemName: item.priority.icon)
                                .font(.caption2)
                                .foregroundColor(priorityColor)
                        }
                    }
                }

                // 内容（如果有）
                if let content = item.content, !content.isEmpty {
                    Text(content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // 标签和对象
                if !item.tags.isEmpty || !item.entities.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(item.tags) { tag in
                            TagChip(tag: tag)
                        }

                        ForEach(item.entities) { entity in
                            EntityChip(entity: entity)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color(.systemGray6) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            itemContextMenu
        }
    }

    // MARK: - 复选框视图

    @ViewBuilder
    private var checkboxView: some View {
        if showCheckbox {
            Button {
                toggleComplete()
            } label: {
                ZStack {
                    // 圆角矩形边框
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            item.isCompleted ? themePurple : Color.secondary.opacity(0.5),
                            lineWidth: 2
                        )

                    // 完成后填充紫色
                    if item.isCompleted {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themePurple)
                    }

                    // 勾选图标
                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            // 非任务流：显示时间
            VStack(alignment: .leading, spacing: 2) {
                Text(timeFormatter.string(from: item.occurredAt))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
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
            item.isMemorable.toggle()
        } label: {
            Label(item.isMemorable ? "取消纪念" : "标记为纪念",
                  systemImage: item.isMemorable ? "star" : "star.fill")
        }

        if item.flowType == .task || item.flowType == .life {
            Divider()

            Button {
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
            let eventFlow = getOrCreateEventFlow()

            let eventItem = FlowItem(
                title: item.title,
                content: item.content,
                occurredAt: Date(),
                sourceItemId: item.id,
                flow: eventFlow,
                domain: item.domain,
                isMemorable: true
            )

            eventItem.tags = item.tags
            eventItem.entities = item.entities

            item.status = .completed
            item.updatedAt = Date()

            modelContext.insert(eventItem)
        }
    }

    private func getOrCreateEventFlow() -> Flow {
        let descriptor = FetchDescriptor<Flow>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        let allFlows = (try? modelContext.fetch(descriptor)) ?? []
        if let eventFlow = allFlows.first(where: { $0.type == .event }) {
            return eventFlow
        }

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
        withAnimation(.easeOut(duration: 0.2)) {
            modelContext.delete(item)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TimelineItemView(
            item: FlowItem(title: "完成项目提案", content: "这是任务内容"),
            showCheckbox: true,
            isFirstOfDay: true,
            isLastOfDay: false
        )

        Divider()

        TimelineItemView(
            item: FlowItem(title: "写周报 #工作 @老板"),
            showCheckbox: false,
            isFirstOfDay: false,
            isLastOfDay: false
        )

        Divider()

        TimelineItemView(
            item: FlowItem(title: "已完成的任务", status: .completed),
            showCheckbox: true,
            isFirstOfDay: true,
            isLastOfDay: true
        )
    }
    .padding()
}
