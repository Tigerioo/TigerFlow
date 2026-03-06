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
            TimelineView(items: items, flowType: flowType)

            // 内联创建（激活时）
            if isCreating {
                InlineEditorView(
                    flowType: flowType,
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
                Menu {
                    Button {
                        // 排序方式
                    } label: {
                        Label("按时间排序", systemImage: "clock")
                    }
                    Button {
                        // 另一种排序
                    } label: {
                        Label("按创建时间", systemImage: "calendar.badge.plus")
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .help("排序")
            }
        }
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

    private func saveItem(title: String, content: String?) {
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

            // 如果是 Task Flow，默认同步到 Life Flow
            if flowType == .task {
                // TODO: 可配置的同步逻辑
            }

            modelContext.insert(item)
        }

        cancelCreate()
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
    let onSave: (String, String?) -> Void
    let onCancel: () -> Void

    @State private var title: String = ""
    @State private var content: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题输入
            TextField("输入标题...", text: $title)
                .font(.body)
                .focused($isFocused)
                .onSubmit {
                    if !title.isEmpty {
                        onSave(title, content.isEmpty ? nil : content)
                    }
                }

            // 内容输入（可选）
            TextField("添加描述（可选）...", text: $content)
                .font(.caption)
                .foregroundColor(.secondary)
                .onSubmit {
                    onSave(title, content.isEmpty ? nil : content)
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
                    onSave(title, content.isEmpty ? nil : content)
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TimelineListView(flowType: .task, appState: AppState())
    }
    .modelContainer(for: [FlowItem.self, Flow.self], inMemory: true)
}
