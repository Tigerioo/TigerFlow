//
//  ProjectDetailView.swift
//  tigerflow
//
//  项目详情视图
//

import SwiftUI
import SwiftData

/// 项目详情视图
struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: OneThingProject

    @State private var showAddStageSheet: Bool = false
    @State private var editingTodo: ProjectTodo?

    /// 按类型分组的阶段
    private var dailyStages: [ProjectStage] {
        (project.stages ?? []).filter { $0.type == .daily }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var weeklyStages: [ProjectStage] {
        (project.stages ?? []).filter { $0.type == .weekly }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var milestoneStages: [ProjectStage] {
        (project.stages ?? []).filter { $0.type == .milestone }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var generalStages: [ProjectStage] {
        (project.stages ?? []).filter { $0.type == .general }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// 独立待办（不属于任何阶段）
    private var standaloneTodos: [ProjectTodo] {
        (project.todos ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            // 项目描述
            if let description = project.descriptionText, !description.isEmpty {
                Section {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // 每日任务区域
            if !dailyStages.isEmpty || project.status == .active {
                StageSection(
                    title: "每日任务",
                    icon: "📅",
                    type: .daily,
                    stages: dailyStages,
                    project: project,
                    onAddTodo: { stage in
                        let todo = ProjectTodo(title: "")
                        todo.stage = stage
                        todo.project = project
                        modelContext.insert(todo)
                        editingTodo = todo
                    }
                )
            }

            // 周常任务区域
            if !weeklyStages.isEmpty || project.status == .active {
                StageSection(
                    title: "周常任务",
                    icon: "📆",
                    type: .weekly,
                    stages: weeklyStages,
                    project: project,
                    onAddTodo: { stage in
                        let todo = ProjectTodo(title: "")
                        todo.stage = stage
                        todo.project = project
                        modelContext.insert(todo)
                        editingTodo = todo
                    }
                )
            }

            // 里程碑区域
            if !milestoneStages.isEmpty || project.status == .active {
                StageSection(
                    title: "里程碑",
                    icon: "🏆",
                    type: .milestone,
                    stages: milestoneStages,
                    project: project,
                    onAddTodo: { stage in
                        let todo = ProjectTodo(title: "")
                        todo.stage = stage
                        todo.project = project
                        modelContext.insert(todo)
                        editingTodo = todo
                    }
                )
            }

            // 一般阶段区域
            ForEach(generalStages) { stage in
                GeneralStageSection(stage: stage)
            }

            // 添加阶段按钮
            Section {
                Button {
                    showAddStageSheet = true
                } label: {
                    Label("添加阶段", systemImage: "plus")
                }
            }

            // 标签和关联
            Section {
                if let tags = project.tags, !tags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(tags) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }

                if let entities = project.entities, !entities.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(entities) { entity in
                            EntityChip(entity: entity)
                        }
                    }
                }
            }
        }
        .navigationTitle(project.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        // 编辑项目
                    } label: {
                        Label("编辑项目", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        // 删除项目
                        deleteProject()
                    } label: {
                        Label("删除项目", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddStageSheet) {
            AddStageSheet(project: project)
        }
        .sheet(item: $editingTodo) { todo in
            TodoEditorSheet(todo: todo, project: project)
        }
    }

    private func deleteProject() {
        modelContext.delete(project)
    }
}

// MARK: - Stage Section (for Daily/Weekly/Milestone)

struct StageSection: View {
    let title: String
    let icon: String
    let type: StageType
    let stages: [ProjectStage]
    let project: OneThingProject
    let onAddTodo: (ProjectStage) -> Void

    @State private var isExpanded: Bool = true

    var body: some View {
        Section {
            if stages.isEmpty {
                // 空状态，显示添加按钮
                Button {
                    let stage = ProjectStage(name: title, type: type, sortOrder: 0)
                    stage.project = project
                    modelContext.insert(stage)
                } label: {
                    Label("添加\(title)", systemImage: "plus")
                        .font(.subheadline)
                }
            } else {
                ForEach(stages) { stage in
                    StageTodosView(stage: stage, onAddTodo: { onAddTodo(stage) })
                }
            }
        } header: {
            DisclosureGroup(isExpanded: $isExpanded) {
                // 内容在 ForEach 中
            } label: {
                HStack {
                    Text(icon)
                    Text(title)
                    Spacer()
                    if !stages.isEmpty {
                        Text("\(stages.reduce(0) { $0 + ($1.todos?.count ?? 0) }) 项")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
}

// MARK: - General Stage Section

struct GeneralStageSection: View {
    let stage: ProjectStage

    @State private var isExpanded: Bool = true
    @State private var editingTodo: ProjectTodo?

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if let todos = stage.todos, !todos.isEmpty {
                ForEach(todos.sorted { $0.sortOrder < $1.sortOrder }) { todo in
                    TodoRowView(todo: todo)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteTodo(todo)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }

            Button {
                let todo = ProjectTodo(title: "")
                todo.stage = stage
                todo.project = stage.project
                modelContext.insert(todo)
                editingTodo = todo
            } label: {
                Label("添加待办", systemImage: "plus")
                    .font(.subheadline)
            }
        } label: {
            HStack {
                Text(stage.type.icon)
                Text(stage.name)
                    .font(.headline)
                Spacer()
                if let todos = stage.todos, !todos.isEmpty {
                    let completed = todos.filter { $0.isCompleted }.count
                    Text("\(completed)/\(todos.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @Environment(\.modelContext) private var modelContext

    private func deleteTodo(_ todo: ProjectTodo) {
        modelContext.delete(todo)
    }
}

// MARK: - Stage Todos View

struct StageTodosView: View {
    let stage: ProjectStage
    let onAddTodo: () -> Void

    @State private var editingTodo: ProjectTodo?

    var body: some View {
        if let todos = stage.todos, !todos.isEmpty {
            ForEach(todos.sorted { $0.sortOrder < $1.sortOrder }) { todo in
                TodoRowView(todo: todo)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteTodo(todo)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }

        Button {
            onAddTodo()
        } label: {
            Label("添加待办", systemImage: "plus")
                .font(.subheadline)
        }
    }

    @Environment(\.modelContext) private var modelContext

    private func deleteTodo(_ todo: ProjectTodo) {
        modelContext.delete(todo)
    }
}

// MARK: - Todo Row View

struct TodoRowView: View {
    @Bindable var todo: ProjectTodo
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button {
            todo.toggleComplete()
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(todo.isCompleted ? .green : .secondary)

                // 内容
                VStack(alignment: .leading, spacing: 2) {
                    Text(todo.title.isEmpty ? "待办标题" : todo.title)
                        .font(.body)
                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                        .strikethrough(todo.isCompleted)

                    if let dueDate = todo.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 优先级
                if todo.priority == .high {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Stage Sheet

struct AddStageSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let project: OneThingProject

    @State private var name: String = ""
    @State private var type: StageType = .general

    var body: some View {
        NavigationStack {
            Form {
                Section("阶段名称") {
                    TextField("输入阶段名称", text: $name)
                }

                Section("阶段类型") {
                    Picker("类型", selection: $type) {
                        ForEach(StageType.allCases, id: \.self) { stageType in
                            Text("\(stageType.icon) \(stageType.displayName)").tag(stageType)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("添加阶段")
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
                    Button("添加") {
                        addStage()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addStage() {
        let maxOrder = (project.stages ?? []).map { $0.sortOrder }.max() ?? 0
        let stage = ProjectStage(
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            sortOrder: maxOrder + 1
        )
        stage.project = project
        modelContext.insert(stage)
        dismiss()
    }
}

// MARK: - Todo Editor Sheet

struct TodoEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var todo: ProjectTodo
    let project: OneThingProject

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var priority: Priority = .medium
    @State private var dueDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("标题") {
                    TextField("输入待办标题", text: $title)
                }

                Section("描述 (可选)") {
                    TextField("输入描述", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("优先级") {
                    Picker("优先级", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("截止日期 (可选)") {
                    DatePicker("日期", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle(todo.title.isEmpty ? "新建待办" : "编辑待办")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if todo.title.isEmpty {
                            modelContext.delete(todo)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTodo()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                title = todo.title
                content = todo.content ?? ""
                priority = todo.priority
                if let due = todo.dueDate {
                    dueDate = due
                }
            }
        }
    }

    private func saveTodo() {
        todo.title = title.trimmingCharacters(in: .whitespaces)
        todo.content = content.isEmpty ? nil : content
        todo.priority = priority
        todo.dueDate = dueDate
        todo.updatedAt = Date()

        if todo.project == nil {
            todo.project = project
        }

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProjectDetailView(project: OneThingProject(name: "测试项目"))
    }
    .modelContainer(for: [OneThingProject.self, ProjectStage.self, ProjectTodo.self, Tag.self, Entity.self], inMemory: true)
}
