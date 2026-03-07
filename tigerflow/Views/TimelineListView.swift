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

    // 编辑器状态
    @State private var editorTitle: String = ""
    @State private var editorContent: String = ""
    @State private var editorTags: [Tag] = []
    @State private var editorEntities: [Entity] = []

    /// 是否显示同步到生活流的选项（默认关闭）
    @State private var syncToLife: Bool = false

    @Query private var allTags: [Tag]
    @Query private var allEntities: [Entity]

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

    // 是否显示编辑器
    private var showEditor: Bool {
        isCreating || editingItem != nil
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Timeline 内容
            TimelineView(
                items: items,
                flowType: flowType,
                onToggleComplete: toggleComplete,
                onEdit: startEditing,
                onSaveToLife: saveToLife,
                onDelete: deleteItem
            )
        }
        .navigationTitle(flowType.displayName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    startCreating()
                } label: {
                    Image(systemName: "plus")
                }
                .help("新建")
            }

            ToolbarItem(placement: .automatic) {
                sortMenu
            }
        }
        .overlay(alignment: .top) {
            if showEditor {
                ZStack(alignment: .top) {
                    // 阻塞层
                    Color.black.opacity(0.001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            // 阻止点击穿透
                        }

                    // 编辑器视图
                    TaskEditorView(
                        isCreating: isCreating,
                        flowType: flowType,
                        showSyncOption: flowType == .task && isCreating,
                        syncToLife: $syncToLife,
                        title: $editorTitle,
                        content: $editorContent,
                        tags: $editorTags,
                        entities: $editorEntities,
                        onSave: saveEditor,
                        onCancel: cancelEditor
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
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
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .help("排序")
    }

    // MARK: - 编辑器操作

    private func startCreating() {
        editorTitle = ""
        editorContent = ""
        editorTags = []
        editorEntities = []
        syncToLife = false
        isCreating = true
        editingItem = nil
    }

    private func startEditing(item: FlowItem) {
        editingItem = item
        editorTitle = item.title
        editorContent = item.content ?? ""
        editorTags = item.tags
        editorEntities = item.entities
        isCreating = false
    }

    private func cancelEditor() {
        withAnimation {
            isCreating = false
            editingItem = nil
            editorTitle = ""
            editorContent = ""
            editorTags = []
            editorEntities = []
            syncToLife = false
        }
    }

    private func saveEditor() {
        let cleanTitle = editorTitle
            .replacingOccurrences(of: "#\\w+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "@\\w+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        guard !cleanTitle.isEmpty else {
            cancelEditor()
            return
        }

        withAnimation {
            if isCreating {
                // 新建
                let flow = getOrCreateFlow(for: flowType)
                let item = FlowItem(
                    title: cleanTitle,
                    content: editorContent.isEmpty ? nil : editorContent,
                    flow: flow
                )
                item.tags = editorTags
                item.entities = editorEntities

                // 增加使用次数
                for tag in editorTags {
                    tag.usageCount += 1
                }
                for entity in editorEntities {
                    entity.usageCount += 1
                }

                // 同步到生活流
                if flowType == .task && syncToLife {
                    syncToLifeFlow(item: item)
                }

                modelContext.insert(item)
            } else if let item = editingItem {
                // 编辑
                item.title = cleanTitle
                item.content = editorContent.isEmpty ? nil : editorContent
                item.tags = editorTags
                item.entities = editorEntities
                item.updatedAt = Date()

                // 增加使用次数
                for tag in editorTags {
                    tag.usageCount += 1
                }
                for entity in editorEntities {
                    entity.usageCount += 1
                }
            }
        }

        cancelEditor()
    }

    // MARK: - 任务操作

    private func toggleComplete(item: FlowItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            item.status = item.isCompleted ? .pending : .completed
            item.updatedAt = Date()
        }
    }

    private func saveToLife(item: FlowItem) {
        withAnimation {
            let lifeFlow = getOrCreateFlow(for: .life)

            let lifeItem = FlowItem(
                title: item.title,
                content: item.content,
                occurredAt: Date(),
                isFromTaskSync: true,
                sourceItemId: item.id,
                flow: lifeFlow,
                domain: item.domain,
                isMemorable: item.isMemorable
            )

            lifeItem.tags = item.tags
            lifeItem.entities = item.entities

            modelContext.insert(lifeItem)
        }
    }

    private func deleteItem(item: FlowItem) {
        withAnimation(.easeOut(duration: 0.2)) {
            modelContext.delete(item)
        }
    }

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

        let newFlow = Flow(
            name: type.displayName,
            type: type,
            sortOrder: type.rawValue.count
        )
        modelContext.insert(newFlow)
        return newFlow
    }
}

// MARK: - 统一任务编辑器视图

struct TaskEditorView: View {
    let isCreating: Bool
    let flowType: FlowType
    let showSyncOption: Bool
    @Binding var syncToLife: Bool

    @Binding var title: String
    @Binding var content: String
    @Binding var tags: [Tag]
    @Binding var entities: [Entity]

    let onSave: () -> Void
    let onCancel: () -> Void

    @Query private var allTags: [Tag]
    @Query private var allEntities: [Entity]

    @State private var parsedTags: [Tag] = []
    @State private var parsedEntities: [Entity] = []
    @FocusState private var isFocused: Bool

    private var isEditing: Bool { !isCreating }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 输入框 - 支持 #标签 和 @对象
            TextField(isCreating ? "添加任务，支持 #标签 @对象" : "编辑任务，支持 #标签 @对象", text: $title)
                .font(.body)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onChange(of: title) { _, newValue in
                    parseInput(newValue)
                }
                .onSubmit {
                    onSave()
                }

            // 解析的标签和对象预览
            HStack(spacing: 8) {
                ForEach(parsedTags) { tag in
                    TagChip(tag: tag)
                }
                ForEach(parsedEntities) { entity in
                    EntityChip(entity: entity)
                }
            }

            // 同步选项（仅创建时显示）
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

            Divider()

            // 操作按钮
            HStack {
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Button("保存") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .onAppear {
            isFocused = true
            parseInput(title)
        }
    }

    private func parseInput(_ text: String) {
        let tagPattern = "#(\\w+)"
        let entityPattern = "@(\\w+)"

        var foundTags: [Tag] = []
        var foundEntities: [Entity] = []

        // 使用正则匹配
        if let regex = try? NSRegularExpression(pattern: tagPattern) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            for match in matches {
                if let tagRange = Range(match.range(at: 1), in: text) {
                    let tagName = String(text[tagRange])
                    if let tag = allTags.first(where: { $0.name == tagName }) {
                        foundTags.append(tag)
                    }
                }
            }
        }

        if let regex = try? NSRegularExpression(pattern: entityPattern) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            for match in matches {
                if let entityRange = Range(match.range(at: 1), in: text) {
                    let entityName = String(text[entityRange])
                    if let entity = allEntities.first(where: { $0.name == entityName }) {
                        foundEntities.append(entity)
                    }
                }
            }
        }

        parsedTags = foundTags
        parsedEntities = foundEntities
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TimelineListView(flowType: .task, appState: AppState())
    }
    .modelContainer(for: [FlowItem.self, Flow.self, Tag.self, Entity.self], inMemory: true)
}
