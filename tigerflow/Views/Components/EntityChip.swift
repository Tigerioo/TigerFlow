//
//  EntityChip.swift
//  tigerflow
//
//  对象卡片视图
//

import SwiftUI

/// 对象卡片视图 - 显示关联的人物或实体
struct EntityChip: View {
    let entity: Entity
    var isCompact: Bool = true

    var body: some View {
        HStack(spacing: 2) {
            Text(entity.emoji)
                .font(isCompact ? .caption : .subheadline)

            Text(entity.name)
                .font(isCompact ? .caption : .subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, isCompact ? 2 : 4)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        EntityChip(entity: Entity(name: "老婆", type: .person, emoji: "👩"))
        EntityChip(entity: Entity(name: "老板", type: .person, emoji: "👨‍💼"), isCompact: false)
        EntityChip(entity: Entity(name: "iPhone", type: .device, emoji: "📱"))
    }
    .padding()
}
