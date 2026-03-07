//
//  TimelineListView.swift
//  tigerflow
//
//  时间线列表视图 - 内容区主视图
//

import SwiftUI
import SwiftData

struct TimelineListView: View {
    let flowType: FlowType

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FlowItem.occurredAt, order: .reverse) private var allItems: [FlowItem]

    @Bindable var appState: AppState
    @State private var isCreating: Bool = false
    @State private var editingItem: FlowItem? = nil

    /// 是否显示同步到生活流的选项
    @State private var syncToLife: Bool = true

    private var items: [FlowItem] {
        // 根据 FlowType 过滤
        let filtered: [FlowItem]
        switch flowType {
        case .task:
            filtered = allItems.filter { $0.flowType == .task }
        case .life:
            filtered = allItems.filter { $0.flowType == .life }
        case .event:
            filtered = allItems.filter { $0.flowType == .event }
        case .custom:
            filtered = allItems.filter { $0.flowType == .custom }
        }

        // 应用搜索筛选
        if !appState.searchText.isEmpty {
            return filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(appState.searchText) ||
                (item.content?.localizedCaseInsensitiveContains(appState.searchText) ?? false)
            }
        }

        return filtered
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Timeline 内容
            TimelineView(
                items: items,
                flowType: flowType,
                onEditItem: { item in
                    editingItem = item
                }
            )

            // 内联创建（激活时）
            if isCreating {
                InlineEditorView(
                    flowType: flowType,
                    showSyncOption: flowType == .task,
                    syncToLife: $syncToLife,
                    onSave: saveItem,
                    onCancel: cancelCreate
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle(flowType.displayName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    activateCreate()
                } label: {
                    Image(systemName: "plus")
                }
                .help("新建")
            }

            ToolbarItem(placement: .automatic) {
                sortMenu
            }
        }
        .sheet(item: $editingItem) { item in
            ItemEditView(item: item) {
                editingItem = nil
            }
        }
    }

    @ViewBuilder
    private var sortMenu: some View {
        Menu {
            Button {
                // 按时间排序
            } label: {
                Label("按时间排序", systemImage: "clock")
            }

            Button {
                // 按创建时间
            } label: {
                Label("按创建时间", systemImage: "calendar.badge.plus")
            }

            if flowType == .task {
                Button {
                    // 按优先级
                } label: {
                    Label("按优先级", systemImage: "flag")
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .help("排序")
    }

    // MARK: - 创建操作

    private func activateCreate() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isCreating = true
        }
    }

    private func cancelCreate() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isCreating = false
        }
    }

    private func saveItem(title: String, content: String?, tags: [Tag], entities: [Entity]) {
        guard !title.isEmpty else {
            cancelCreate()
            return
        }

        withAnimation {
            // 找到对应的 Flow
            let flow = getOrCreateFlow(for: flowType)

            // 创建新 Item
            let item = FlowItem(
                title: title,
                content: content,
                flow: flow
            )

            // 设置标签和对象
            item.tags = tags
            item.entities = entities

            // 增加使用次数
            for tag in tags {
                tag.usageCount += 1
            }
            for entity in entities {
                entity.usageCount += 1
            }

            // 如果是 Task Flow 且开启了同步，生成 Life 记录
            if flowType == .task && syncToLife {
                syncToLifeFlow(item: item)
            }

            modelContext.insert(item)
        }

        cancelCreate()
    }

    /// 同步到生活流
    private func syncToLifeFlow(item: FlowItem) {
        let lifeFlow = getOrCreateFlow(for: .life)

        let lifeItem = FlowItem(
            title: item.title,
            content: item.content,
            occurredAt: Date(),
            isFromTaskSync: true,
            sourceItemId: item.id,
            flow: lifeFlow,
            domain: item.domain
        )

        // 复制标签和对象
        lifeItem.tags = item.tags
        lifeItem.entities = item.entities

        modelContext.insert(lifeItem)
    }

    private func getOrCreateFlow(for type: FlowType) -> Flow {
        let descriptor = FetchDescriptor<Flow>(
            predicate: #Predicate { $0.type == type },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        if let existingFlow = try? modelContext.fetch(descriptor).first {
            return existingFlow
        }

        // 创建默认 Flow
        let newFlow = Flow(
            name: type.displayName,
            type: type,
            sortOrder: type.rawValue.count
        )
        modelContext.insert(newFlow)
        return newFlow
    }
}

// MARK: - Inline Editor View

struct InlineEditorView: View {
    let flowType: FlowType
    let showSyncOption: Bool
    @Binding var syncToLife: Bool
    let onSave: (String, String?, [Tag], [Entity]) -> Void
    let onCancel: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var parsedTags: [Tag] = []
    @State private var parsedEntities: [Entity] = []

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 快速输入框（支持智能解析）
            QuickInputField(text: $title, onSubmit: submit)
                .onChange(of: title) { _, newValue in
                    parseInput(newValue)
                }

            // 解析预览
            if !parsedTags.isEmpty || !parsedEntities.isEmpty {
                HStack(spacing: 6) {
                    ForEach(parsedTags) { tag in
                        TagChip(tag: tag)
                    }
                    ForEach(parsedEntities) { entity in
                        EntityChip(entity: entity)
                    }
                }
            }

            // 同步选项（仅任务流显示）
            if showSyncOption {
                Toggle(isOn: $syncToLife) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.orange)
                        Text("同步到生活流")
                            .font(.caption)
                    }
                }
                .padding(.top, 4)
            }

            // 操作按钮
            HStack {
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Button("保存") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .onAppear {
            isFocused = true
        }
    }

    private func parseInput(_ text: String) {
        let result = SmartParser.parse(text, context: modelContext)
        parsedTags = result.tags
        parsedEntities = result.entities
    }

    private func submit() {
        let cleanTitle = title
            .replacingOccurrences(of: "#\\w+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "@\\w+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        guard !cleanTitle.isEmpty else {
            onCancel()
            return
        }

        onSave(cleanTitle, content.isEmpty ? nil : content, parsedTags, parsedEntities)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TimelineListView(flowType: .task, appState: AppState())
    }
    .modelContainer(for: [FlowItem.self, Flow.self, Tag.self, Entity.self], inMemory: true)
}
