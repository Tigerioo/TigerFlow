//
//  DateCircleView.swift
//  tigerflow
//
//  圆形日期视图
//

import SwiftUI

/// 圆形日期视图 - 显示在每天首条 Item 左侧
struct DateCircleView: View {
    let date: Date
    var isCompleted: Bool = false  // 是否已完成

    private var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(circleColor)
                .frame(width: 32, height: 32)

            Text(day)
                .font(.system(.callout, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(textColor)
        }
    }

    private var circleColor: Color {
        if isCompleted {
            return Color.green.opacity(0.3)
        } else if isToday {
            return Color.accentColor
        } else {
            return Color.secondary
        }
    }

    private var textColor: Color {
        if isCompleted {
            return .green
        } else {
            return .white
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DateCircleView(date: Date())
        DateCircleView(date: Date(), isCompleted: true)
        DateCircleView(date: Date().addingTimeInterval(-86400))
    }
    .padding()
}
