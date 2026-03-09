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
    var isFirstOfDay: Bool = false
    var isLastOfDay: Bool = false

    // 回调
    var onToggleComplete: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onSaveToLife: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var isHovering: Bool = false

    // 主题紫色
    private let themePurple = Color.accentColor

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左侧：复选框或时间
            checkboxView
                .frame(width: showCheckbox ? 24 : 44, height: 24)

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

                    // 纪念标识
                    if item.isMemorable {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
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
                .fill(isHovering ? Color.gray.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        // 点击触发行内编辑
        .onTapGesture {
            onEdit?()
        }
    }

    // MARK: - 复选框视图

    @ViewBuilder
    private var checkboxView: some View {
        if showCheckbox {
            Button {
                onToggleComplete?()
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
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TimelineItemView(
            item: FlowItem(title: "完成项目提案", content: "这是任务内容"),
            showCheckbox: true,
            isFirstOfDay: true,
            isLastOfDay: false,
            onToggleComplete: {},
            onSaveToLife: {},
            onDelete: {}
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
