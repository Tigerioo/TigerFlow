//
//  TimelineView.swift
//  tigerflow
//
//  时间线视图 - 按年/月/日分组展示 FlowItems
//

import SwiftUI
import SwiftData

/// 时间线视图 - 按年/月/日分组展示 FlowItems
struct TimelineView: View {
    let items: [FlowItem]
    let flowType: FlowType

    // 回调
    var onToggleComplete: ((FlowItem) -> Void)? = nil
    var onEdit: ((FlowItem) -> Void)? = nil
    var onSaveToLife: ((FlowItem) -> Void)? = nil
    var onDelete: ((FlowItem) -> Void)? = nil

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedByYear.keys.sorted(by: >), id: \.self) { year in
                    let yearGroups = groupedByYear[year] ?? [:]

                    // 年份标题
                    YearHeader(year: year)

                    ForEach(yearGroups.keys.sorted(by: >), id: \.self) { month in
                        let monthGroups = yearGroups[month] ?? [:]

                        // 月份分组
                        MonthSection(
                            month: month,
                            monthGroups: monthGroups,
                            flowType: flowType,
                            onToggleComplete: onToggleComplete,
                            onEdit: onEdit,
                            onSaveToLife: onSaveToLife,
                            onDelete: onDelete
                        )
                    }
                }

                // 空状态
                if items.isEmpty {
                    EmptyTimelineView(flowType: flowType)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 分组逻辑

    /// 按年份分组
    private var groupedByYear: [Int: [String: [Date: [FlowItem]]]] {
        var result: [Int: [String: [Date: [FlowItem]]]] = [:]

        for item in items {
            let year = item.yearKey
            let month = item.monthKey
            let day = item.dateKey

            if result[year] == nil {
                result[year] = [:]
            }
            if result[year]?[month] == nil {
                result[year]?[month] = [:]
            }
            if result[year]?[month]?[day] == nil {
                result[year]?[month]?[day] = []
            }
            result[year]?[month]?[day]?.append(item)
        }

        // 按日期排序（倒序）
        for year in result.keys {
            for month in result[year]!.keys {
                result[year]![month] = result[year]![month]!.mapValues { items in
                    items.sorted { $0.occurredAt > $1.occurredAt }
                }
            }
        }

        return result
    }
}

// MARK: - Year Header

struct YearHeader: View {
    let year: Int

    var body: some View {
        Text("\(year)年")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .padding(.top, 16)
            .padding(.bottom, 12)
    }
}

// MARK: - Month Section

struct MonthSection: View {
    let month: String
    let monthGroups: [Date: [FlowItem]]
    let flowType: FlowType

    // 回调
    var onToggleComplete: ((FlowItem) -> Void)? = nil
    var onEdit: ((FlowItem) -> Void)? = nil
    var onSaveToLife: ((FlowItem) -> Void)? = nil
    var onDelete: ((FlowItem) -> Void)? = nil

    private var displayMonth: String {
        let components = month.split(separator: "-")
        if components.count == 2,
           let monthNum = Int(components[1]) {
            let monthNames = ["", "1月", "2月", "3月", "4月", "5月", "6月",
                              "7月", "8月", "9月", "10月", "11月", "12月"]
            return monthNum < monthNames.count ? monthNames[monthNum] : month
        }
        return month
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 月份标题
            Text(displayMonth)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.leading, 8)

            // 日分组
            ForEach(monthGroups.keys.sorted(by: >), id: \.self) { day in
                let dayItems = monthGroups[day] ?? []
                DaySection(
                    date: day,
                    items: dayItems,
                    flowType: flowType,
                    onToggleComplete: onToggleComplete,
                    onEdit: onEdit,
                    onSaveToLife: onSaveToLife,
                    onDelete: onDelete
                )
            }
        }
    }
}

// MARK: - Day Section

struct DaySection: View {
    let date: Date
    let items: [FlowItem]
    let flowType: FlowType

    // 回调
    var onToggleComplete: ((FlowItem) -> Void)? = nil
    var onEdit: ((FlowItem) -> Void)? = nil
    var onSaveToLife: ((FlowItem) -> Void)? = nil
    var onDelete: ((FlowItem) -> Void)? = nil

    @State private var isExpanded: Bool = true

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd"
        return formatter
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private var weekdayIndex: Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // 转换为中文周几 (1=周日, 2=周一, ..., 7=周六)
        return weekday - 1
    }

    private var chineseWeekday: String {
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return weekdays[weekdayIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 日期行 - 可折叠
            HStack(alignment: .center, spacing: 8) {
                // 折叠箭头
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)

                // 日期：0306 周五 格式
                Text(dateFormatter.string(from: date))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(isToday ? .accentColor : .primary)

                Text(chineseWeekday)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isToday {
                    Text("今天")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }

                Spacer()

                // 显示任务数量
                Text("\(items.count) 项")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
            .padding(.vertical, 8)
            .background(Color(.systemGray6).opacity(0.5))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            // Items - 缩进显示
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        // 任务流添加滑动操作
                        if flowType == .task {
                            TimelineItemView(
                                item: item,
                                showCheckbox: flowType.showCheckbox,
                                isFirstOfDay: index == 0,
                                isLastOfDay: index == items.count - 1,
                                onToggleComplete: { onToggleComplete?(item) },
                                onEdit: { onEdit?(item) },
                                onSaveToLife: { onSaveToLife?(item) },
                                onDelete: { onDelete?(item) }
                            )
                        } else {
                            // 非任务流不添加滑动操作
                            TimelineItemView(
                                item: item,
                                showCheckbox: flowType.showCheckbox,
                                isFirstOfDay: index == 0,
                                isLastOfDay: index == items.count - 1,
                                onToggleComplete: { onToggleComplete?(item) },
                                onEdit: { onEdit?(item) }
                            )
                        }
                    }
                }
                .padding(.leading, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Empty State

struct EmptyTimelineView: View {
    let flowType: FlowType

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: flowType.icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("暂无记录")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("点击右上角 + 按钮创建第一条记录")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    TimelineView(items: [], flowType: .task)
}
