//
//  TagChip.swift
//  tigerflow
//
//  标签卡片视图
//

import SwiftUI

/// 标签卡片视图
struct TagChip: View {
    let tag: Tag
    var isCompact: Bool = true

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(Color(hex: tag.color))
                .frame(width: 6, height: 6)

            Text(tag.name)
                .font(isCompact ? .caption : .subheadline)
                .foregroundColor(Color(hex: tag.color))
        }
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, isCompact ? 2 : 4)
        .background(Color(hex: tag.color).opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        TagChip(tag: Tag(name: "工作", color: "#007AFF"))
        TagChip(tag: Tag(name: "阅读", color: "#34C759"), isCompact: false)
    }
    .padding()
}
