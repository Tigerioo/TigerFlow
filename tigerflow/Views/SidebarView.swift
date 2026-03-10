//
//  SidebarView.swift
//  tigerflow
//
//  左侧边栏视图
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Flow.sortOrder) private var flows: [Flow]
    @Query(sort: \Domain.sortOrder) private var domains: [Domain]
    @Query(sort: \Tag.usageCount, order: .reverse) private var tags: [Tag]
    @Query(sort: \Entity.usageCount, order: .reverse) private var entities: [Entity]

    @Bindable var appState: AppState

    var body: some View {
        List(selection: $appState.selectedSidebarItem) {
            // OneThing 入口
            oneThingSection

            flowsSection
            domainsSection
            peopleSection
            tagsSection
        }
        .listStyle(.sidebar)
        .navigationTitle("Tiger时光流")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    appState.searchText = ""
                    appState.showingFilters.toggle()
                } label: {
                    Image(systemName: appState.showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .help("筛选")
            }
        }
        .searchable(text: $appState.searchText, prompt: "搜索")
        .onAppear {
            initializeDefaultData()
        }
    }

    // MARK: - Flows Section

    @ViewBuilder
    private var oneThingSection: some View {
        Section("FOCUS") {
            NavigationLink(value: SidebarItem.oneThing) {
                HStack {
                    Text("🎯")
                        .font(.title3)
                    Text("OneThing")
                        .font(.body)
                }
            }
        }
    }

    @ViewBuilder
    private var flowsSection: some View {
        Section("FLOWS") {
            ForEach(FlowType.allCases) { flowType in
                FlowRow(
                    flowType: flowType,
                    itemCount: itemCount(for: flowType)
                )
                .tag(SidebarItem.flow(flowType))
                .contextMenu {
                    flowContextMenu(for: flowType)
                }
            }

            ForEach(flows.filter { $0.type == .custom }) { flow in
                FlowRow(flow: flow, itemCount: flow.items?.count ?? 0)
                    .tag(SidebarItem.customFlow(flow.id))
                    .contextMenu {
                        flowContextMenu(for: flow)
                    }
            }

            Button {
                createCustomFlow()
            } label: {
                Label("新建 Flow", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Domains Section

    @ViewBuilder
    private var domainsSection: some View {
        Section("DOMAINS") {
            ForEach(domains) { domain in
                DomainRow(
                    domain: domain,
                    itemCount: domain.items?.count ?? 0
                )
                .tag(SidebarItem.domain(domain.id))
                .contextMenu {
                    Button("编辑") { }
                    Divider()
                    Button("删除", role: .destructive) {
                        modelContext.delete(domain)
                    }
                }
            }

            Button {
                createDomain()
            } label: {
                Label("新建领域", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - People Section

    @ViewBuilder
    private var peopleSection: some View {
        Section("PEOPLE") {
            ForEach(entities.filter { $0.type == .person }) { entity in
                PeopleRow(
                    entity: entity,
                    itemCount: entity.items?.count ?? 0
                )
                .tag(SidebarItem.person(entity.id))
                .contextMenu {
                    Button("编辑") { }
                    Divider()
                    Button("删除", role: .destructive) {
                        modelContext.delete(entity)
                    }
                }
            }

            Button {
                createPerson()
            } label: {
                Label("新建人物", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Tags Section

    @ViewBuilder
    private var tagsSection: some View {
        Section("TAGS") {
            ForEach(tags) { tag in
                TagRow(
                    tag: tag,
                    itemCount: tag.items?.count ?? 0
                )
                .tag(SidebarItem.tag(tag.id))
            }

            Button {
                createTag()
            } label: {
                Label("新建标签", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - 辅助方法

    private func itemCount(for flowType: FlowType) -> Int {
        flows.first { $0.type == flowType }?.items?.count ?? 0
    }

    private func initializeDefaultData() {
        if flows.isEmpty {
            let defaultFlows = Flow.createDefaultFlows()
            for flow in defaultFlows {
                modelContext.insert(flow)
            }
        }

        if domains.isEmpty {
            let defaultDomains = Domain.createDefaultDomains()
            for domain in defaultDomains {
                modelContext.insert(domain)
            }
        }
    }

    @ViewBuilder
    private func flowContextMenu(for flowType: FlowType) -> some View {
        Button("重命名") { }
        Divider()
        Button("删除", role: .destructive) { }
    }

    @ViewBuilder
    private func flowContextMenu(for flow: Flow) -> some View {
        Button("编辑") { }
        Button(flow.isPinned ? "取消置顶" : "置顶") {
            flow.isPinned.toggle()
        }
        Divider()
        Button("删除", role: .destructive) {
            modelContext.delete(flow)
        }
    }

    private func createCustomFlow() {
        let flow = Flow(name: "新 Flow", type: .custom, sortOrder: flows.count)
        modelContext.insert(flow)
    }

    private func createDomain() {
        let domain = Domain(name: "新领域", sortOrder: domains.count)
        modelContext.insert(domain)
    }

    private func createPerson() {
        let entity = Entity(name: "新人物", type: .person)
        modelContext.insert(entity)
    }

    private func createTag() {
        let tag = Tag(name: "新标签")
        modelContext.insert(tag)
    }
}

// MARK: - Flow Row

struct FlowRow: View {
    let flowType: FlowType?
    let flow: Flow?
    let itemCount: Int

    init(flowType: FlowType, itemCount: Int) {
        self.flowType = flowType
        self.flow = nil
        self.itemCount = itemCount
    }

    init(flow: Flow, itemCount: Int) {
        self.flowType = nil
        self.flow = flow
        self.itemCount = itemCount
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: color))
                .frame(width: 20)

            Text(displayName)
                .font(.body)

            Spacer()

            if itemCount > 0 {
                Text("\(itemCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }

    private var displayName: String {
        if let flowType = flowType {
            return flowType.displayName
        }
        return flow?.name ?? ""
    }

    private var icon: String {
        if let flowType = flowType {
            return flowType.icon
        }
        return flow?.icon ?? "pin.fill"
    }

    private var color: String {
        flow?.color ?? "#007AFF"
    }
}

// MARK: - Domain Row

struct DomainRow: View {
    let domain: Domain
    let itemCount: Int

    var body: some View {
        HStack {
            Image(systemName: domain.icon)
                .foregroundColor(Color(hex: domain.color))
                .frame(width: 20)

            Text(domain.name)
                .font(.body)

            Spacer()

            if itemCount > 0 {
                Text("\(itemCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - People Row

struct PeopleRow: View {
    let entity: Entity
    let itemCount: Int

    var body: some View {
        HStack {
            Text(entity.emoji)
                .font(.title3)
                .frame(width: 20)

            Text(entity.name)
                .font(.body)

            Spacer()

            if itemCount > 0 {
                Text("\(itemCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Tag Row

struct TagRow: View {
    let tag: Tag
    let itemCount: Int

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: tag.color))
                .frame(width: 10, height: 10)

            Text(tag.displayName)
                .font(.body)

            Spacer()

            if itemCount > 0 {
                Text("\(itemCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
