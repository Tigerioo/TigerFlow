//
//  ItemEditView.swift
//  tigerflow
//
//  编辑任务项视图
//

import SwiftUI
import SwiftData

/// 编辑任务项视图 - Sheet 形式
struct ItemEditView: View {
    @Bindable var item: FlowItem
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var priority: FlowItemPriority = .medium
    @State private var isMemorable: Bool = false
    @State private var parsedTags: [Tag] = []
    @State private var parsedEntities: [Entity] = []

    @Query private var allTags: [Tag]
    @Query private var allEntities: [Entity]

    @FocusState private var focusedField: Field?

    private enum Field {
        case title, content
    }

    var body: some View {
        NavigationStack {
            Form {
                // 标题
                Section("标题") {
                    TextField("输入任务标题", text: $title)
                        .font(.body)
                        .focused($focusedField, equals: .title)
                }

                // 内容
                Section("内容") {
                    TextField("添加详细描述（可选）", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .content)
                }

                // 优先级
                if item.flowType == .task {
                    Section("优先级") {
                        Picker("优先级", selection: $priority) {
                            Label("高", systemImage: "flag.fill")
                                .tag(FlowItemPriority.high)
                            Label("中", systemImage: "flag")
                                .tag(FlowItemPriority.medium)
                            Label("低", systemImage: "flag")
                                .tag(FlowItemPriority.low)
                        }
                        .pickerStyle(.menu)
                    }
                }

                // 纪念
                Section {
                    Toggle("标记为纪念", isOn: $isMemorable)
                }

                // 标签
                Section("标签") {
                    if parsedTags.isEmpty && item.tags.isEmpty {
                        Text("暂无标签")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        FlowFlowLayout(spacing: 8) {
                            ForEach(parsedTags + item.tags.filter { !parsedTags.contains($0) }) { tag in
                                TagChip(tag: tag, isCompact: false)
                                    .onTapGesture {
                                        removeTag(tag)
                                    }
                            }
                        }
                    }

                    // 添加标签
                    Menu {
                        ForEach(allTags.filter { !parsedTags.contains($0) && !item.tags.contains($0) }) { tag in
                            Button {
                                addTag(tag)
                            } label: {
                                Label(tag.name, systemImage: "tag")
                            }
                        }

                        if allTags.isEmpty {
                            Text("暂无标签")
                        }
                    } label: {
                        Label("添加标签", systemImage: "plus.circle")
                    }
                }

                // 对象
                Section("对象 (@人)") {
                    if parsedEntities.isEmpty && item.entities.isEmpty {
                        Text("暂无对象")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        FlowFlowLayout(spacing: 8) {
                            ForEach(parsedEntities + item.entities.filter { !parsedEntities.contains($0) }) { entity in
                                EntityChip(entity: entity, isCompact: false)
                                    .onTapGesture {
                                        removeEntity(entity)
                                    }
                            }
                        }
                    }

                    // 添加对象
                    Menu {
                        ForEach(allEntities.filter { !parsedEntities.contains($0) && !item.entities.contains($0) }) { entity in
                            Button {
                                addEntity(entity)
                            } label: {
                                Label(entity.name, systemImage: "person")
                            }
                        }

                        if allEntities.isEmpty {
                            Text("暂无对象")
                        }
                    } label: {
                        Label("添加对象", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("编辑任务")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                loadItemData()
                focusedField = .title
            }
        }
    }

    // MARK: - 数据加载

    private func loadItemData() {
        title = item.title
        content = item.content ?? ""
        priority = item.priority
        isMemorable = item.isMemorable
        parsedTags = item.tags
        parsedEntities = item.entities
    }

    // MARK: - 保存

    private func saveChanges() {
        withAnimation {
            item.title = title.trimmingCharacters(in: .whitespaces)
            item.content = content.isEmpty ? nil : content
            item.priority = priority
            item.isMemorable = isMemorable
            item.updatedAt = Date()

            // 更新标签
            item.tags = parsedTags
            for tag in parsedTags {
                tag.usageCount += 1
            }

            // 更新对象
            item.entities = parsedEntities
            for entity in parsedEntities {
                entity.usageCount += 1
            }
        }

        onDismiss()
    }

    // MARK: - 标签操作

    private func addTag(_ tag: Tag) {
        if !parsedTags.contains(tag) {
            parsedTags.append(tag)
        }
    }

    private func removeTag(_ tag: Tag) {
        parsedTags.removeAll { $0.id == tag.id }
    }

    // MARK: - 对象操作

    private func addEntity(_ entity: Entity) {
        if !parsedEntities.contains(entity) {
            parsedEntities.append(entity)
        }
    }

    private func removeEntity(_ entity: Entity) {
        parsedEntities.removeAll { $0.id == entity.id }
    }
}

// MARK: - Flow Layout (简单实现)

struct FlowFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowFlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowFlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    struct FlowFlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FlowItem.self, Flow.self, Tag.self, Entity.self, configurations: config)

    let item = FlowItem(title: "测试任务", content: "测试内容")
    container.mainContext.insert(item)

    return ItemEditView(item: item, onDismiss: {})
        .modelContainer(container)
}
