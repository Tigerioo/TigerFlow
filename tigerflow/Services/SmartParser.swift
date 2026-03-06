//
//  SmartParser.swift
//  tigerflow
//
//  智能解析服务 - 解析 #标签 和 @对象
//

import Foundation
import SwiftData

/// 智能解析服务
class SmartParser {
    /// 解析文本中的标签和对象
    /// - Parameters:
    ///   - text: 输入文本
    ///   - context: SwiftData 上下文，用于查找/创建标签和对象
    /// - Returns: 解析结果
    static func parse(_ text: String, context: ModelContext) -> ParsedResult {
        // 1. 提取标签
        let tagMatches = extractTagMatches(from: text)
        let tags = resolveTags(tagMatches, context: context)

        // 2. 提取对象
        let entityMatches = extractEntityMatches(from: text)
        let entities = resolveEntities(entityMatches, context: context)

        // 3. 清理文本，移除 # 和 @ 符号
        let cleanTitle = cleanTitle(text)

        return ParsedResult(
            title: cleanTitle,
            tags: tags,
            entities: entities,
            rawTags: tagMatches,
            rawEntities: entityMatches
        )
    }

    /// 提取标签匹配
    private static func extractTagMatches(from text: String) -> [String] {
        let pattern = "#(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        return matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }

    /// 提取对象匹配
    private static func extractEntityMatches(from text: String) -> [String] {
        let pattern = "@(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        return matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }

    /// 清理标题
    private static func cleanTitle(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "#\\w+", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "@\\w+", with: "", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespaces)
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return result
    }

    /// 解析标签
    private static func resolveTags(_ matches: [String], context: ModelContext) -> [Tag] {
        var tags: [Tag] = []
        let existingTags = fetchAllTags(context: context)

        for match in matches {
            // 精确匹配
            if let existing = existingTags.first(where: { $0.name.lowercased() == match.lowercased() }) {
                tags.append(existing)
            } else {
                // 创建新标签
                let newTag = Tag(name: match)
                context.insert(newTag)
                tags.append(newTag)
            }
        }

        return tags
    }

    /// 解析对象
    private static func resolveEntities(_ matches: [String], context: ModelContext) -> [Entity] {
        var entities: [Entity] = []
        let existingEntities = fetchAllEntities(context: context)

        for match in matches {
            // 精确匹配
            if let existing = existingEntities.first(where: { $0.name.lowercased() == match.lowercased() }) {
                entities.append(existing)
            } else {
                // 创建新对象（默认为人物类型）
                let newEntity = Entity(name: match, type: .person)
                context.insert(newEntity)
                entities.append(newEntity)
            }
        }

        return entities
    }

    /// 获取所有标签
    private static func fetchAllTags(context: ModelContext) -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.usageCount, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// 获取所有对象
    private static func fetchAllEntities(context: ModelContext) -> [Entity] {
        let descriptor = FetchDescriptor<Entity>(sortBy: [SortDescriptor(\.usageCount, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// 模糊搜索标签
    static func searchTags(_ query: String, context: ModelContext) -> [Tag] {
        guard !query.isEmpty else {
            return fetchAllTags(context: context)
        }

        let allTags = fetchAllTags(context: context)
        return allTags.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    /// 模糊搜索对象
    static func searchEntities(_ query: String, context: ModelContext) -> [Entity] {
        guard !query.isEmpty else {
            return fetchAllEntities(context: context)
        }

        let allEntities = fetchAllEntities(context: context)
        return allEntities.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    /// 检测触发建议的类型
    static func detectSuggestionTrigger(_ text: String) -> SuggestionTrigger {
        // 找到最后一个 # 或 @ 的位置
        let lastHashIndex = text.lastIndex(of: "#")
        let lastAtIndex = text.lastIndex(of: "@")

        // 确定哪个是最后触发的
        if let hashIndex = lastHashIndex, let atIndex = lastAtIndex {
            if hashIndex > atIndex {
                // # 在最后，提取查询
                let queryStart = text.index(after: hashIndex)
                let query = String(text[queryStart...]).trimmingCharacters(in: .whitespaces)
                return .tag(query)
            } else if atIndex > text.startIndex {
                // 检查 @ 前面是否有空格或特殊字符
                let prevIndex = text.index(before: atIndex)
                if prevIndex >= text.startIndex {
                    let prevChar = text[prevIndex]
                    if prevChar == " " || prevChar == "\n" || prevIndex == text.startIndex {
                        let queryStart = text.index(after: atIndex)
                        let query = String(text[queryStart...]).trimmingCharacters(in: .whitespaces)
                        return .entity(query)
                    }
                }
            }
        } else if let hashIndex = lastHashIndex {
            let queryStart = text.index(after: hashIndex)
            let query = String(text[queryStart...]).trimmingCharacters(in: .whitespaces)
            return .tag(query)
        } else if let atIndex = lastAtIndex, atIndex > text.startIndex {
            let prevIndex = text.index(before: atIndex)
            if prevIndex >= text.startIndex {
                let prevChar = text[prevIndex]
                let prevCharString = String(prevChar)
                if prevCharString == " " || prevCharString == "\n" || prevIndex == text.startIndex {
                    let queryStart = text.index(after: atIndex)
                    let query = String(text[queryStart...]).trimmingCharacters(in: .whitespaces)
                    return .entity(query)
                }
            }
        }

        return .none
    }
}

/// 解析结果
struct ParsedResult {
    let title: String
    let tags: [Tag]
    let entities: [Entity]
    let rawTags: [String]
    let rawEntities: [String]

    var isEmpty: Bool {
        title.isEmpty && tags.isEmpty && entities.isEmpty
    }
}

/// 建议触发类型
enum SuggestionTrigger: Equatable {
    case none
    case tag(String)
    case entity(String)

    var isActive: Bool {
        switch self {
        case .none: return false
        case .tag(let query), .entity(let query): return !query.isEmpty || query.isEmpty
        }
    }

    var query: String {
        switch self {
        case .none: return ""
        case .tag(let query), .entity(let query): return query
        }
    }

    var isTag: Bool {
        if case .tag = self { return true }
        return false
    }

    var isEntity: Bool {
        if case .entity = self { return true }
        return false
    }
}
