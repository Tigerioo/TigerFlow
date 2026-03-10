//
//  OneThingQueueView.swift
//  tigerflow
//
//  OneThing 项目队列视图
//

import SwiftUI
import SwiftData

/// OneThing 队列视图 - 显示当前进行中的项目
struct OneThingQueueView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OneThingProject.queueOrder) private var allProjects: [OneThingProject]

    @Bindable var appState: AppState

    @State private var showNewProjectSheet: Bool = false
    @State private var selectedProject: OneThingProject?

    /// 队列中的项目（进行中）
    private var queueProjects: [OneThingProject] {
        allProjects
            .filter { $0.isInQueue && $0.status == .active }
            .sorted { $0.queueOrder < $1.queueOrder }
    }

    /// 已完成/归档的项目
    private var archivedProjects: [OneThingProject] {
        allProjects
            .filter { !$0.isInQueue || $0.status != .active }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        List {
            // 队列区域
            if !queueProjects.isEmpty {
                Section {
                    ForEach(queueProjects) { project in
                        ProjectCardView(project: project)
                            .onTapGesture {
                                selectedProject = project
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    archiveProject(project)
                                } label: {
                                    Label("归档", systemImage: "archivebox")
                                }
                            }
                    }
                    .onMove { from, to in
                        moveProject(from: from, to: to)
                    }
                } header: {
                    HStack {
                        Text("进行中")
                        Spacer()
                        Text("\(queueProjects.count)/3")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // 添加到队列按钮
            Section {
                Button {
                    showNewProjectSheet = true
                } label: {
                    Label("新建项目", systemImage: "plus")
                }
            }

            // 已完成/归档区域
            if !archivedProjects.isEmpty {
                Section {
                    ForEach(archivedProjects) { project in
                        ProjectCardView(project: project, isCompact: true)
                            .onTapGesture {
                                selectedProject = project
                            }
                    }
                } header: {
                    DisclosureGroup("已完成") {
                        // 内容在 ForEach 中
                    }
                }
            }
        }
        .navigationTitle("OneThing")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewProjectSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("新建项目")
            }
        }
        .sheet(isPresented: $showNewProjectSheet) {
            NewProjectSheet()
        }
        .sheet(item: $selectedProject) { project in
            NavigationStack {
                ProjectDetailView(project: project)
            }
        }
        .navigationDestination(for: OneThingProject.self) { project in
            ProjectDetailView(project: project)
        }
    }

    // MARK: - Actions

    private func archiveProject(_ project: OneThingProject) {
        withAnimation {
            project.isInQueue = false
            project.status = .completed
            project.updatedAt = Date()
        }
    }

    private func moveProject(from source: IndexSet, to destination: Int) {
        var projects = queueProjects
        projects.move(fromOffsets: source, toOffset: destination)

        withAnimation {
            for (index, project) in projects.enumerated() {
                project.queueOrder = index
            }
        }
    }
}

// MARK: - Project Card View

struct ProjectCardView: View {
    let project: OneThingProject
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Text(project.icon)
                .font(isCompact ? .title3 : .title)
                .frame(width: 40)

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)

                if !isCompact {
                    HStack(spacing: 8) {
                        Text("\(project.pendingTodosCount) 待办")
                        if project.completedTodosCount > 0 {
                            Text("· \(project.completedTodosCount) 已完成")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 状态标识
            if project.status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - New Project Sheet

struct NewProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var icon: String = "🎯"
    @State private var description: String = ""
    @State private var addToQueue: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("项目名称") {
                    TextField("输入项目名称", text: $name)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(OneThingProject.presetIcons, id: \.self) { emoji in
                            Button {
                                icon = emoji
                            } label: {
                                Text(emoji)
                                    .font(.title)
                                    .frame(width: 44, height: 44)
                                    .background(icon == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("描述 (可选)") {
                    TextField("输入项目描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("添加到 OneThing 队列", isOn: $addToQueue)
                }
            }
            .navigationTitle("新建项目")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createProject()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createProject() {
        let project = OneThingProject(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            descriptionText: description.isEmpty ? nil : description,
            isInQueue: addToQueue,
            queueOrder: 0
        )

        modelContext.insert(project)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OneThingQueueView(appState: AppState())
    }
    .modelContainer(for: [OneThingProject.self, ProjectStage.self, ProjectTodo.self], inMemory: true)
}
