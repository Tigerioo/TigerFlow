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
                .fill(isToday ? Color.accentColor : Color.secondary)
                .frame(width: 32, height: 32)

            Text(day)
                .font(.system(.callout, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DateCircleView(date: Date())
        DateCircleView(date: Date().addingTimeInterval(-86400))
    }
    .padding()
}
