//
//  SuggestionsPopover.swift
//  tigerflow
//
//  建议弹出面板 - 标签/对象建议
//

import SwiftUI
import SwiftData

/// 建议类型
enum SuggestionType {
    case tag
    case entity
}

/// 建议弹出面板
struct SuggestionsPopover: View {
    let type: SuggestionType
    let suggestions: [Any]
    let onSelect: (Any) -> Void
    let onCreateNew: (String) -> Void

    @State private var isHovering: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            Text(type == .tag ? "标签建议" : "对象建议")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            // 建议列表
            if suggestions.isEmpty {
                Text("无匹配建议")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(12)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, item in
                            suggestionRow(item, index: index)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }

            Divider()

            // 创建新选项
            Button {
                let query = getCurrentQuery()
                onCreateNew(query)
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("创建新\(type == .tag ? "标签" : "对象")")
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .background(isHovering == -1 ? Color.primary.opacity(0.1) : Color.clear)
        }
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .frame(width: 240)
    }

    @ViewBuilder
    private func suggestionRow(_ item: Any, index: Int) -> some View {
        Button {
            onSelect(item)
        } label: {
            HStack {
                if let tag = item as? Tag {
                    Circle()
                        .fill(Color(hex: tag.color))
                        .frame(width: 10, height: 10)
                    Text(tag.name)
                        .font(.subheadline)
                } else if let entity = item as? Entity {
                    Text(entity.emoji)
                        .font(.subheadline)
                    Text(entity.name)
                        .font(.subheadline)
                    Spacer()
                    Text(entity.type == .person ? "人物" : "其他")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovering == index ? Color.primary.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering ? index : nil
        }
    }

    private func getCurrentQuery() -> String {
        return ""
    }
}

// MARK: - Preview

#Preview {
    let sampleTags = [
        Tag(name: "工作", color: "#007AFF"),
        Tag(name: "阅读", color: "#34C759"),
        Tag(name: "运动", color: "#FF3B30")
    ]

    let sampleEntities = [
        Entity(name: "老板", type: .person, emoji: "👨‍💼"),
        Entity(name: "老婆", type: .person, emoji: "👩")
    ]

    VStack(spacing: 20) {
        SuggestionsPopover(
            type: .tag,
            suggestions: sampleTags,
            onSelect: { _ in },
            onCreateNew: { _ in }
        )

        SuggestionsPopover(
            type: .entity,
            suggestions: sampleEntities,
            onSelect: { _ in },
            onCreateNew: { _ in }
        )
    }
    .padding()
}
