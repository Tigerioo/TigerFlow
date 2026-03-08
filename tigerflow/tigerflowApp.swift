//
//  tigerflowApp.swift
//  tigerflow
//
//  应用入口
//

import SwiftUI
import SwiftData

@main
struct tigerflowApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Flow.self,
            FlowItem.self,
            Domain.self,
            Tag.self,
            Entity.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
#if os(macOS)
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 600)
#endif
        .commands {
            // 文件菜单
            CommandGroup(replacing: .newItem) {
                Button("新建任务") {
                    NotificationCenter.default.post(name: .createNewItem, object: FlowType.task)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("新建生活记录") {
                    NotificationCenter.default.post(name: .createNewItem, object: FlowType.life)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("新建事件") {
                    NotificationCenter.default.post(name: .createNewItem, object: FlowType.event)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }

            // 视图菜单
            CommandMenu("视图") {
                Button("任务流") {
                    NotificationCenter.default.post(name: .selectFlow, object: FlowType.task)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("生活流") {
                    NotificationCenter.default.post(name: .selectFlow, object: FlowType.life)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("事件流") {
                    NotificationCenter.default.post(name: .selectFlow, object: FlowType.event)
                }
                .keyboardShortcut("3", modifiers: .command)

                Divider()

                Button("显示/隐藏侧边栏") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
        }
    }
}

// MARK: - 通知名称

extension Notification.Name {
    static let createNewItem = Notification.Name("createNewItem")
    static let selectFlow = Notification.Name("selectFlow")
    static let toggleSidebar = Notification.Name("toggleSidebar")
}
