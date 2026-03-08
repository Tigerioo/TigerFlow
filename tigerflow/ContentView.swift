//
//  ContentView.swift
//  tigerflow
//
//  主内容视图 - NavigationSplitView 布局
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState()

    var body: some View {
        NavigationSplitView(columnVisibility: $appState.sidebarVisibility) {
            // 左侧边栏
            SidebarView(appState: appState)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } content: {
            // 中间内容区 - Timeline
            contentView
                .navigationSplitViewColumnWidth(min: 300, ideal: 400)
        } detail: {
            // 右侧详情区
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $appState.showingSettings) {
            SettingsView()
        }
    }

    // MARK: - 内容区

    @ViewBuilder
    private var contentView: some View {
        if let flowType = appState.currentFlowType {
            TimelineListView(flowType: flowType, appState: appState)
        } else if appState.selectedSidebarItem != nil {
            // 筛选模式 - 显示所有相关项
            FilteredTimelineView(appState: appState)
        } else {
            // 默认显示任务流
            TimelineListView(flowType: .task, appState: appState)
        }
    }

    // MARK: - 详情区

    @ViewBuilder
    private var detailView: some View {
        if let itemId = appState.selectedItemId {
            ItemDetailView(itemId: itemId)
        } else {
            Text("选择一个项目查看详情")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Filtered Timeline View

struct FilteredTimelineView: View {
    @Bindable var appState: AppState
    @Query(sort: \FlowItem.occurredAt, order: .reverse) private var allItems: [FlowItem]

    private var filteredItems: [FlowItem] {
        var items = allItems

        // 根据选中项筛选
        switch appState.selectedSidebarItem {
        case .flow(let type):
            items = items.filter { $0.flowType == type }
        case .customFlow(let flowId):
            items = items.filter { $0.flow?.id == flowId }
        case .domain(let domainId):
            items = items.filter { $0.domain?.id == domainId }
        case .person(let entityId):
            items = items.filter { item in
                item.entities.contains { $0.id == entityId }
            }
        case .tag(let tagId):
            items = items.filter { item in
                item.tags.contains { $0.id == tagId }
            }
        case .none:
            break
        }

        // 应用搜索
        if !appState.searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(appState.searchText) ||
                (item.content?.localizedCaseInsensitiveContains(appState.searchText) ?? false)
            }
        }

        return items
    }

    var body: some View {
        TimelineView(items: filteredItems, flowType: .task)
            .navigationTitle(selectedTitle)
    }

    private var selectedTitle: String {
        if case .flow(let type) = appState.selectedSidebarItem {
            return type.displayName
        }
        return "筛选结果"
    }
}

// MARK: - Item Detail View

struct ItemDetailView: View {
    let itemId: UUID

    @Query private var items: [FlowItem]

    private var item: FlowItem? {
        items.first { $0.id == itemId }
    }

    var body: some View {
        if let item = item {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题
                    Text(item.title)
                        .font(.title)
                        .fontWeight(.bold)

                    // 元信息
                    HStack {
                        if let flow = item.flow {
                            Label(flow.name, systemImage: flow.icon)
                        }

                        if let domain = item.domain {
                            Label(domain.name, systemImage: domain.icon)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    // 时间
                    HStack {
                        Image(systemName: "clock")
                        Text(item.occurredAt, style: .date)
                        Text(item.occurredAt, style: .time)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    // 内容
                    if let content = item.content, !content.isEmpty {
                        Text(content)
                            .font(.body)
                            .padding(.top, 8)
                    }

                    // 标签
                    if !item.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("标签")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(item.tags) { tag in
                                    TagChip(tag: tag, isCompact: false)
                                }
                            }
                        }
                        .padding(.top, 16)
                    }

                    // 对象
                    if !item.entities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("关联")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(item.entities) { entity in
                                    EntityChip(entity: entity, isCompact: false)
                                }
                            }
                        }
                        .padding(.top, 16)
                    }

                    Spacer()
                }
                .padding()
            }
        } else {
            Text("未找到项目")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [FlowItem.self, Flow.self, Domain.self, Tag.self, Entity.self], inMemory: true)
}
