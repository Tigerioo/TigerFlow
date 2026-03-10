//
//  TimelineListView.swift
//  tigerflow
//
//  时间线列表视图 - 内容区主视图
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

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

    /// 是否显示同步到日程流的选项（默认关闭）
    @State private var syncToSchedule: Bool = false

    /// 编辑器选择的时间（仅日程流使用）
    @State private var editorTime: Date = Date()

    @Query private var allTags: [Tag]
    @Query private var allEntities: [Entity]

    private var items: [FlowItem] {
        // 根据 FlowType 过滤
        let filtered: [FlowItem]
        switch flowType {
        case .task:
            filtered = allItems.filter { $0.flowType == .task }
        case .schedule, .life:  // .life 兼容旧数据
            filtered = allItems.filter { $0.flowType == .schedule || $0.flowType == .life }
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
                        syncToSchedule: $syncToSchedule,
                        title: $editorTitle,
                        content: $editorContent,
                        tags: $editorTags,
                        entities: $editorEntities,
                        selectedTime: flowType == .schedule ? $editorTime : nil,
                        onSave: saveEditor,
                        onCancel: cancelEditor,
                        onDelete: editingItem != nil ? { deleteItem(item: editingItem!) } : nil
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
        syncToSchedule = false
        editorTime = Date()
        isCreating = true
        editingItem = nil
    }

    private func startEditing(item: FlowItem) {
        editingItem = item
        editorTitle = item.title
        editorContent = item.content ?? ""
        editorTags = item.tags
        editorEntities = item.entities
        editorTime = item.occurredAt
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
            syncToSchedule = false
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
                var occurredAt = Date()

                // 日程流使用选择的时间
                if flowType == .schedule {
                    occurredAt = combineDateAndTime(date: Date(), time: editorTime)
                }

                let item = FlowItem(
                    title: cleanTitle,
                    content: editorContent.isEmpty ? nil : editorContent,
                    occurredAt: occurredAt,
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

                // 同步到日程流
                if flowType == .task && syncToSchedule {
                    syncToScheduleFlow(item: item)
                }

                modelContext.insert(item)
            } else if let item = editingItem {
                // 编辑
                item.title = cleanTitle
                item.content = editorContent.isEmpty ? nil : editorContent
                item.tags = editorTags
                item.entities = editorEntities
                item.updatedAt = Date()

                // 日程流更新时间
                if flowType == .schedule {
                    item.occurredAt = combineDateAndTime(date: item.occurredAt, time: editorTime)
                }

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
            let scheduleFlow = getOrCreateFlow(for: .schedule)

            let scheduleItem = FlowItem(
                title: item.title,
                content: item.content,
                occurredAt: combineDateAndTime(date: Date(), time: editorTime),
                isFromTaskSync: true,
                sourceItemId: item.id,
                flow: scheduleFlow,
                domain: item.domain,
                isMemorable: item.isMemorable
            )

            scheduleItem.tags = item.tags
            scheduleItem.entities = item.entities

            modelContext.insert(scheduleItem)
        }
    }

    private func deleteItem(item: FlowItem) {
        // 先获取关联的标签和对象
        let tagsToCheck = item.tags
        let entitiesToCheck = item.entities

        withAnimation(.easeOut(duration: 0.2)) {
            modelContext.delete(item)
        }

        // 清理不再被引用的标签和对象
        cleanupUnusedTags(tagsToCheck)
        cleanupUnusedEntities(entitiesToCheck)

        // 关闭编辑器
        cancelEditor()
    }

    // 清理不再被引用的标签
    private func cleanupUnusedTags(_ tags: [Tag]) {
        // 获取所有 FlowItem
        let descriptor = FetchDescriptor<FlowItem>()
        guard let allItems = try? modelContext.fetch(descriptor) else { return }

        for tag in tags {
            // 检查是否有其他任务引用此标签
            let isReferenced = allItems.contains { item in
                item.tags.contains { $0.id == tag.id }
            }
            if !isReferenced {
                modelContext.delete(tag)
            }
        }
    }

    // 清理不再被引用的对象
    private func cleanupUnusedEntities(_ entities: [Entity]) {
        let descriptor = FetchDescriptor<FlowItem>()
        guard let allItems = try? modelContext.fetch(descriptor) else { return }

        for entity in entities {
            let isReferenced = allItems.contains { item in
                item.entities.contains { $0.id == entity.id }
            }
            if !isReferenced {
                modelContext.delete(entity)
            }
        }
    }

    private func syncToScheduleFlow(item: FlowItem) {
        let scheduleFlow = getOrCreateFlow(for: .schedule)

        let scheduleItem = FlowItem(
            title: item.title,
            content: item.content,
            occurredAt: combineDateAndTime(date: Date(), time: editorTime),
            isFromTaskSync: true,
            sourceItemId: item.id,
            flow: scheduleFlow,
            domain: item.domain
        )

        scheduleItem.tags = item.tags
        scheduleItem.entities = item.entities

        modelContext.insert(scheduleItem)
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
}

// MARK: - 统一任务编辑器视图

struct TaskEditorView: View {
    let isCreating: Bool
    let flowType: FlowType
    let showSyncOption: Bool
    @Binding var syncToSchedule: Bool

    @Binding var title: String
    @Binding var content: String
    @Binding var tags: [Tag]
    @Binding var entities: [Entity]

    /// 选择的时间（仅日程流使用）
    var selectedTime: Binding<Date>?

    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Query private var allTags: [Tag]
    @Query private var allEntities: [Entity]

    @State private var parsedTagNames: [String] = []
    @State private var parsedEntityNames: [String] = []
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 输入框 - 支持 #标签 和 @对象
            TextField(isCreating ? "添加任务" : "编辑任务", text: $title)
                .font(.body)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onChange(of: title) { _, newValue in
                    parseInput(newValue)
                }
                .onSubmit {
                    onSave()
                }

            // 当前选中的标签和对象
            if !tags.isEmpty || !entities.isEmpty {
                FlowFlowLayout(spacing: 6) {
                    ForEach(tags) { tag in
                        SelectedTagChip(tag: tag) {
                            removeTag(tag)
                        }
                    }
                    ForEach(entities) { entity in
                        SelectedEntityChip(entity: entity) {
                            removeEntity(entity)
                        }
                    }
                }
            }

            // 解析到的标签（可点击添加）
            let newTagNames = parsedTagNames.filter { name in
                !tags.contains(where: { $0.name == name })
            }
            let newEntityNames = parsedEntityNames.filter { name in
                !entities.contains(where: { $0.name == name })
            }

            if !newTagNames.isEmpty || !newEntityNames.isEmpty {
                HStack(spacing: 8) {
                    Text("发现:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(newTagNames, id: \.self) { name in
                        Button {
                            addTag(name: name)
                        } label: {
                            Text("#\(name)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(newEntityNames, id: \.self) { name in
                        Button {
                            addEntity(name: name)
                        } label: {
                            Text("@\(name)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 快速添加已有标签/对象
            HStack(spacing: 12) {
                // 标签菜单
                if !availableTags.isEmpty {
                    Menu {
                        ForEach(availableTags) { tag in
                            Button {
                                addTagObject(tag)
                            } label: {
                                Label(tag.name, systemImage: "tag")
                            }
                        }
                    } label: {
                        Label("标签", systemImage: "tag")
                            .font(.caption)
                    }
                }

                // 对象菜单
                if !availableEntities.isEmpty {
                    Menu {
                        ForEach(availableEntities) { entity in
                            Button {
                                addEntityObject(entity)
                            } label: {
                                Label(entity.name, systemImage: "person")
                            }
                        }
                    } label: {
                        Label("对象", systemImage: "person")
                            .font(.caption)
                    }
                }

                Spacer()

                // 同步选项（仅创建时显示）
                if showSyncOption {
                    Toggle(isOn: $syncToSchedule) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.orange)
                            Text("同步")
                                .font(.caption)
                        }
                    }
                    .toggleStyle(.button)
                }
            }

            // 时间选择器（仅日程流显示）
            if let selectedTime = selectedTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("时间")
                        .foregroundColor(.secondary)

                    Spacer()

                    // 快速选择按钮
                    let quickTimes = [0, 15, 30, 45]
                    ForEach(quickTimes, id: \.self) { minute in
                        Button {
                            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                            components.hour = 0
                            components.minute = minute
                            if let date = Calendar.current.date(from: components) {
                                selectedTime.wrappedValue = date
                            }
                        } label: {
                            Text(String(format: "%02d:%02d", 0, minute))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Calendar.current.component(.minute, from: selectedTime.wrappedValue) == minute
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear
                                )
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }

                    // 精确时间选择
                    DatePicker(
                        "",
                        selection: selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .frame(width: 80)
                }
                .padding(.vertical, 4)
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

                // 删除按钮（仅编辑时显示）
                if let onDelete = onDelete, !isCreating {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("删除")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                Button("保存") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .onAppear {
            isFocused = true
            parseInput(title)
        }
    }

    // 可选的标签（未选中的）
    private var availableTags: [Tag] {
        allTags.filter { tag in !tags.contains(where: { $0.id == tag.id }) }
    }

    // 可选的对象（未选中的）
    private var availableEntities: [Entity] {
        allEntities.filter { entity in !entities.contains(where: { $0.id == entity.id }) }
    }

    // 解析输入中的 #标签 和 @对象
    private func parseInput(_ text: String) {
        // 支持中英文标签：#后面跟非空白字符
        let tagPattern = "#(\\S+)"
        let entityPattern = "@(\\S+)"

        var foundTagNames: [String] = []
        var foundEntityNames: [String] = []

        if let regex = try? NSRegularExpression(pattern: tagPattern) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            for match in matches {
                if let tagRange = Range(match.range(at: 1), in: text) {
                    foundTagNames.append(String(text[tagRange]))
                }
            }
        }

        if let regex = try? NSRegularExpression(pattern: entityPattern) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            for match in matches {
                if let entityRange = Range(match.range(at: 1), in: text) {
                    foundEntityNames.append(String(text[entityRange]))
                }
            }
        }

        parsedTagNames = foundTagNames
        parsedEntityNames = foundEntityNames
    }

    // 添加标签（从名称创建或匹配）
    private func addTag(name: String) {
        if let tag = allTags.first(where: { $0.name == name }) {
            if !tags.contains(where: { $0.id == tag.id }) {
                tags.append(tag)
            }
        } else {
            // 创建新标签
            let newTag = Tag(name: name)
            modelContext.insert(newTag)
            tags.append(newTag)
        }
    }

    // 添加对象（从名称创建或匹配）
    private func addEntity(name: String) {
        if let entity = allEntities.first(where: { $0.name == name }) {
            if !entities.contains(where: { $0.id == entity.id }) {
                entities.append(entity)
            }
        } else {
            // 创建新对象
            let newEntity = Entity(name: name, type: .person, emoji: "👤")
            modelContext.insert(newEntity)
            entities.append(newEntity)
        }
    }

    // 从对象添加（已有标签）
    private func addTagObject(_ tag: Tag) {
        if !tags.contains(where: { $0.id == tag.id }) {
            tags.append(tag)
        }
    }

    // 从对象添加（已有对象）
    private func addEntityObject(_ entity: Entity) {
        if !entities.contains(where: { $0.id == entity.id }) {
            entities.append(entity)
        }
    }

    // 移除标签
    private func removeTag(_ tag: Tag) {
        tags.removeAll { $0.id == tag.id }
    }

    // 移除对象
    private func removeEntity(_ entity: Entity) {
        entities.removeAll { $0.id == entity.id }
    }
}

// MARK: - 已选中的标签 Chip（可删除）

struct SelectedTagChip: View {
    let tag: Tag
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: tag.color))
                .frame(width: 6, height: 6)

            Text(tag.name)
                .font(.caption)
                .foregroundColor(Color(hex: tag.color))

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(Color(hex: tag.color).opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: tag.color).opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - 已选中的对象 Chip（可删除）

struct SelectedEntityChip: View {
    let entity: Entity
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(entity.emoji)
                .font(.caption)

            Text(entity.name)
                .font(.caption)
                .foregroundColor(.primary)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TimelineListView(flowType: .task, appState: AppState())
    }
    .modelContainer(for: [FlowItem.self, Flow.self, Tag.self, Entity.self], inMemory: true)
}
