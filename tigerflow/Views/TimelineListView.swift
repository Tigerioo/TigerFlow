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

    // 行内编辑状态
    @State private var editingTitle: String = ""
    @State private var editingTags: [Tag] = []
    @State private var editingEntities: [Entity] = []

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

    var body: some View {
        ZStack(alignment: .top) {
            // Timeline 内容
            TimelineView(
                items: items,
                flowType: flowType,
                onToggleComplete: toggleComplete,
                onEdit: startInlineEdit,
                onSaveToLife: saveToLife,
                onDelete: deleteItem
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
        .overlay(alignment: .top) {
            ZStack(alignment: .top) {
                // 阻塞层 - 防止点击穿透（创建模式）
                if isCreating {
                    Color.black.opacity(0.001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            // 阻止点击穿透
                        }
                }

                // 内联创建视图
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
        }
        .overlay(alignment: .top) {
            ZStack(alignment: .top) {
                // 阻塞层 - 防止点击穿透（编辑模式）
                if editingItem != nil {
                    Color.black.opacity(0.001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            // 阻止点击穿透
                        }
                }

                // 编辑视图
                if let item = editingItem {
                    SimpleInlineEditView(
                        item: item,
                        title: $editingTitle,
                        allTags: allTags,
                        allEntities: allEntities,
                        onSave: saveInlineEdit,
                        onCancel: cancelInlineEdit
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

    // MARK: - 行内编辑操作

    private func startInlineEdit(item: FlowItem) {
        editingItem = item
        editingTitle = item.title
        editingTags = item.tags
        editingEntities = item.entities
    }

    private func cancelInlineEdit() {
        withAnimation {
            editingItem = nil
            editingTitle = ""
            editingTags = []
            editingEntities = []
        }
    }

    private func saveInlineEdit() {
        guard let item = editingItem else {
            cancelInlineEdit()
            return
        }

        let cleanTitle = editingTitle
            .replacingOccurrences(of: "#\\w+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "@\\w+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        guard !cleanTitle.isEmpty else {
            cancelInlineEdit()
            return
        }

        withAnimation {
            item.title = cleanTitle
            item.tags = editingTags
            item.entities = editingEntities
            item.updatedAt = Date()

            // 增加使用次数
            for tag in editingTags {
                tag.usageCount += 1
            }
            for entity in editingEntities {
                entity.usageCount += 1
            }
        }

        cancelInlineEdit()
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

            // 复制标签和对象
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

// MARK: - 简单行内编辑视图

struct SimpleInlineEditView: View {
    let item: FlowItem
    @Binding var title: String
    let allTags: [Tag]
    let allEntities: [Entity]
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var parsedTags: [Tag] = []
    @State private var parsedEntities: [Entity] = []
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 输入框 - 支持 #标签 和 @对象
            TextField("编辑任务，支持 #标签 @对象", text: $title)
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

            // 已有标签快速添加
            if !item.tags.isEmpty || !item.entities.isEmpty {
                HStack(spacing: 6) {
                    Text("已有:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(item.tags) { tag in
                        TagChip(tag: tag)
                    }
                    ForEach(item.entities) { entity in
                        EntityChip(entity: entity)
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
            // 初始化解析
            parseInput(title)
        }
    }

    private func parseInput(_ text: String) {
        // 简单的解析：从文本中提取 #标签 和 @对象
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
