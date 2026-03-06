//
//  QuickInputField.swift
//  tigerflow
//
//  快速输入框 - 支持智能解析
//

import SwiftUI
import SwiftData

/// 快速输入框
struct QuickInputField: View {
    @Binding var text: String
    var onSubmit: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.usageCount, order: .reverse) private var allTags: [Tag]
    @Query(sort: \Entity.usageCount, order: .reverse) private var allEntities: [Entity]

    @State private var trigger: SuggestionTrigger = .none
    @State private var tagSuggestions: [Tag] = []
    @State private var entitySuggestions: [Entity] = []

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 输入框
            TextField("输入任务，回车保存...", text: $text)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($isFocused)
                .onSubmit(onSubmit)
                .onChange(of: text) { _, newValue in
                    handleTextChange(newValue)
                }

            // 解析预览
            if !text.isEmpty {
                ParsedPreviewView(text: text)
            }

            // 建议面板
            if trigger.isActive {
                suggestionPanel
            }
        }
        .onAppear {
            isFocused = true
        }
    }

    @ViewBuilder
    private var suggestionPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(trigger.isTag ? "标签建议" : "对象建议")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            let suggestions = trigger.isTag ? AnyView(tagSuggestionsView) : AnyView(entitySuggestionsView)

            suggestions
        }
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .frame(width: 240)
    }

    @ViewBuilder
    private var tagSuggestionsView: some View {
        if tagSuggestions.isEmpty {
            Text("无匹配标签")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(12)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(tagSuggestions) { tag in
                        Button {
                            selectTag(tag)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(hex: tag.color))
                                    .frame(width: 10, height: 10)
                                Text(tag.name)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 150)
        }
    }

    @ViewBuilder
    private var entitySuggestionsView: some View {
        if entitySuggestions.isEmpty {
            Text("无匹配对象")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(12)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(entitySuggestions) { entity in
                        Button {
                            selectEntity(entity)
                        } label: {
                            HStack {
                                Text(entity.emoji)
                                Text(entity.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(entity.type == .person ? "人物" : "其他")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 150)
        }
    }

    private func handleTextChange(_ newValue: String) {
        let newTrigger = SmartParser.detectSuggestionTrigger(newValue)

        if newTrigger.isTag {
            trigger = .tag(newTrigger.query)
            tagSuggestions = SmartParser.searchTags(newTrigger.query, context: modelContext)
        } else if newTrigger.isEntity {
            trigger = .entity(newTrigger.query)
            entitySuggestions = SmartParser.searchEntities(newTrigger.query, context: modelContext)
        } else {
            trigger = .none
        }
    }

    private func selectTag(_ tag: Tag) {
        // 替换当前的 #未完成 文本
        if case .tag(let query) = trigger {
            if let range = text.range(of: "#" + query) {
                text.replaceSubrange(range, with: "#" + tag.name + " ")
            }
        }
        trigger = .none
        isFocused = true
    }

    private func selectEntity(_ entity: Entity) {
        // 替换当前的 @未完成 文本
        if case .entity(let query) = trigger {
            if let range = text.range(of: "@" + query) {
                text.replaceSubrange(range, with: "@" + entity.name + " ")
            }
        }
        trigger = .none
        isFocused = true
    }
}

/// 解析预览视图
struct ParsedPreviewView: View {
    let text: String

    @State private var tags: [String] = []
    @State private var entities: [String] = []

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }

            ForEach(entities, id: \.self) { entity in
                Text("@\(entity)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .onAppear {
            parsePreview()
        }
        .onChange(of: text) { _, _ in
            parsePreview()
        }
    }

    private func parsePreview() {
        // 提取标签
        let tagPattern = "#(\\w+)"
        if let regex = try? NSRegularExpression(pattern: tagPattern, options: []) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            tags = matches.compactMap { match in
                guard let range = Range(match.range(at: 1), in: text) else { return nil }
                return String(text[range])
            }
        }

        // 提取对象
        let entityPattern = "@(\\w+)"
        if let regex = try? NSRegularExpression(pattern: entityPattern, options: []) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            entities = matches.compactMap { match in
                guard let range = Range(match.range(at: 1), in: text) else { return nil }
                return String(text[range])
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var text = "写周报 #工作 @老板"

    QuickInputField(text: $text, onSubmit: {})
        .padding()
        .modelContainer(for: [Tag.self, Entity.self], inMemory: true)
}
