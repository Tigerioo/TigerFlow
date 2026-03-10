//
//  EventFlowView.swift
//  tigerflow
//
//  事件流主视图
//

import SwiftUI
import SwiftData

/// 事件流视图
struct EventFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FlowItem.occurredAt, order: .reverse) private var allItems: [FlowItem]

    @Bindable var appState: AppState

    // 编辑器状态
    @State private var isCreating: Bool = false
    @State private var editingItem: FlowItem? = nil
    @State private var editorTitle: String = ""
    @State private var editorContent: String = ""
    @State private var editorTags: [Tag] = []
    @State private var editorEntities: [Entity] = []

    @Query private var allTags: [Tag]
    @Query private var allEntities: [Entity]

    private let module = EventFlowModule()

    private var items: [FlowItem] {
        module.filterItems(allItems)
    }

    private var showEditor: Bool {
        isCreating || editingItem != nil
    }

    // 编辑器是否有内容
    private var hasEditorContent: Bool {
        let cleanTitle = editorTitle
            .replacingOccurrences(of: "#\\w+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "@\\w+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return !cleanTitle.isEmpty || !editorContent.isEmpty || !editorTags.isEmpty || !editorEntities.isEmpty
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Timeline 内容
            TimelineView(
                items: items,
                flowType: .event,
                onToggleComplete: nil, // 事件流不支持完成
                onEdit: startEditing,
                onDelete: deleteItem
            )
        }
        .navigationTitle(module.displayName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    startCreating()
                } label: {
                    Image(systemName: "plus")
                }
                .help("新建事件")
            }
        }
        .overlay(alignment: .top) {
            if showEditor {
                ZStack(alignment: .top) {
                    // 阻塞层 - 点击空白区域保存或关闭
                    Color.black.opacity(0.001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            handleBackgroundTap()
                        }

                    // 编辑器视图
                    TaskEditorView(
                        isCreating: isCreating,
                        flowType: .event,
                        showSyncOption: false,
                        syncToSchedule: .constant(false),
                        title: $editorTitle,
                        content: $editorContent,
                        tags: $editorTags,
                        entities: $editorEntities,
                        selectedTime: nil, // 事件流不显示时间选择器
                        onSave: saveEditor,
                        onCancel: cancelEditor,
                        onDelete: editingItem != nil ? { deleteItem(item: editingItem!) } : nil
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - 编辑器操作

    private func handleBackgroundTap() {
        if hasEditorContent {
            saveEditor()
        } else {
            cancelEditor()
        }
    }

    private func startCreating() {
        editorTitle = ""
        editorContent = ""
        editorTags = []
        editorEntities = []
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
                // 新建事件
                let item = module.createItem(
                    title: cleanTitle,
                    content: editorContent.isEmpty ? nil : editorContent,
                    occurredAt: Date(),
                    tags: editorTags,
                    entities: editorEntities,
                    modelContext: modelContext
                )

                // 增加使用次数
                for tag in editorTags {
                    tag.usageCount += 1
                }
                for entity in editorEntities {
                    entity.usageCount += 1
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

    // MARK: - 事件操作

    private func deleteItem(item: FlowItem) {
        let tagsToCheck = item.tags
        let entitiesToCheck = item.entities

        withAnimation(.easeOut(duration: 0.2)) {
            modelContext.delete(item)
        }

        cleanupUnusedTags(tagsToCheck)
        cleanupUnusedEntities(entitiesToCheck)
        cancelEditor()
    }

    // 清理不再被引用的标签
    private func cleanupUnusedTags(_ tags: [Tag]) {
        let descriptor = FetchDescriptor<FlowItem>()
        guard let allItems = try? modelContext.fetch(descriptor) else { return }

        for tag in tags {
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
}

#Preview {
    NavigationStack {
        EventFlowView(appState: AppState())
    }
    .modelContainer(for: [FlowItem.self, Flow.self, Tag.self, Entity.self], inMemory: true)
}
