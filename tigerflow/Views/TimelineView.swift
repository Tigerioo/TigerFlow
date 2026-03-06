//
//  TimelineView.swift
//  tigerflow
//
//  时间线视图
//

import SwiftUI
import SwiftData

/// 时间线视图 - 按年/月/日分组展示 FlowItems
struct TimelineView: View {
    let items: [FlowItem]
    let flowType: FlowType

    @State private var stickyMonth: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedByYear.keys.sorted(by: >), id: \.self) { year in
                    let yearGroups = groupedByYear[year] ?? [:]

                    // 年份标题
                    YearHeader(year: year)

                    ForEach(yearGroups.keys.sorted(by: >), id: \.self) { month in
                        let monthGroups = yearGroups[month] ?? [:]

                        // 月份 Sticky Header
                        MonthHeader(month: month, isSticky: stickyMonth == month)

                        // 日分组
                        ForEach(monthGroups.keys.sorted(by: >), id: \.self) { day in
                            let dayItems = monthGroups[day] ?? []

                            // 日分组
                            DaySection(
                                date: day,
                                items: dayItems,
                                flowType: flowType,
                                isFirstDayOfMonth: day == dayItems.first?.occurredAt
                            )
                        }
                    }
                }

                // 空状态
                if items.isEmpty {
                    EmptyTimelineView(flowType: flowType)
                }
            }
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
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Month Header

struct MonthHeader: View {
    let month: String
    let isSticky: Bool

    private var displayMonth: String {
        // 解析 "yyyy-MM" 格式
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
        Text(displayMonth)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSticky ? Color(.systemBackground) : Color.clear)
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
                }
            )
    }
}

// MARK: - Day Section

struct DaySection: View {
    let date: Date
    let items: [FlowItem]
    let flowType: FlowType
    let isFirstDayOfMonth: Bool

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d日"
        return formatter
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 日期标题
            HStack {
                Text(dayFormatter.string(from: date))
                    .font(.subheadline)
                    .foregroundColor(isToday ? .accentColor : .secondary)

                if isToday {
                    Text("今天")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Items
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                TimelineItemView(
                    item: item,
                    showDateCircle: index == 0,  // 仅每天首条显示 DateCircle
                    showCheckbox: flowType.showCheckbox
                )
            }
        }
    }
}

// MARK: - Empty State

struct EmptyTimelineView: View {
    let flowType: FlowType

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: flowType.icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("暂无记录")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("点击右上角 + 按钮创建第一条记录")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
