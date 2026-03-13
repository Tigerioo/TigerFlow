import Foundation
import Combine

// MARK: - Sync Service

final class SyncService {
    static let shared = SyncService()

    private let api = APIClient.shared
    private let tokenManager = TokenManager.shared

    private init() {}

    // MARK: - 同步状态

    enum SyncState {
        case idle
        case syncing
        case success
        case failed(Error)
    }

    @Published private(set) var state: SyncState = .idle

    // MARK: - 全量同步

    func fullSync() async throws {
        state = .syncing

        do {
            let response = try await api.fullSync()

            // 保存同步时间
            if let syncTime = parseDate(response.syncTime) {
                tokenManager.lastSyncTime = syncTime
            }

            // TODO: 将数据合并到 SwiftData
            // 1. 处理 Flows
            // 2. 处理 FlowItems
            // 3. 处理 Domains
            // 4. 处理 Tags
            // 5. 处理 Entities

            state = .success
        } catch {
            state = .failed(error)
            throw error
        }
    }

    // MARK: - 增量同步

    func incrementalSync() async throws {
        guard tokenManager.isLoggedIn else {
            throw SyncError.notLoggedIn
        }

        state = .syncing

        do {
            let lastSyncTime = tokenManager.lastSyncTimeString
            let response = try await api.sync(lastSyncTime: lastSyncTime)

            // 保存同步时间
            if let syncTime = parseDate(response.syncTime) {
                tokenManager.lastSyncTime = syncTime
            }

            // 处理新增/更新的数据
            if let flows = response.flows {
                await processFlows(flows)
            }

            if let flowItems = response.flowItems {
                await processFlowItems(flowItems)
            }

            if let domains = response.domains {
                await processDomains(domains)
            }

            if let tags = response.tags {
                await processTags(tags)
            }

            if let entities = response.entities {
                await processEntities(entities)
            }

            // 处理删除的数据
            if let deletedFlows = response.deletedFlows {
                await deleteFlows(deletedFlows)
            }

            if let deletedFlowItems = response.deletedFlowItems {
                await deleteFlowItems(deletedFlowItems)
            }

            if let deletedDomains = response.deletedDomains {
                await deleteDomains(deletedDomains)
            }

            if let deletedTags = response.deletedTags {
                await deleteTags(deletedTags)
            }

            if let deletedEntities = response.deletedEntities {
                await deleteEntities(deletedEntities)
            }

            state = .success
        } catch {
            state = .failed(error)
            throw error
        }
    }

    // MARK: - 数据处理

    private func processFlows(_ flows: [FlowDTO]) async {
        // TODO: 实现 SwiftData 合并逻辑
        print("[SyncService] Processing \(flows.count) flows")
    }

    private func processFlowItems(_ items: [FlowItemDTO]) async {
        // TODO: 实现 SwiftData 合并逻辑
        print("[SyncService] Processing \(items.count) flowItems")
    }

    private func processDomains(_ domains: [DomainDTO]) async {
        // TODO: 实现 SwiftData 合并逻辑
        print("[SyncService] Processing \(domains.count) domains")
    }

    private func processTags(_ tags: [TagDTO]) async {
        // TODO: 实现 SwiftData 合并逻辑
        print("[SyncService] Processing \(tags.count) tags")
    }

    private func processEntities(_ entities: [EntityDTO]) async {
        // TODO: 实现 SwiftData 合并逻辑
        print("[SyncService] Processing \(entities.count) entities")
    }

    private func deleteFlows(_ ids: [Int64]) async {
        // TODO: 实现软删除逻辑
        print("[SyncService] Deleting \(ids.count) flows")
    }

    private func deleteFlowItems(_ ids: [Int64]) async {
        // TODO: 实现软删除逻辑
        print("[SyncService] Deleting \(ids.count) flowItems")
    }

    private func deleteDomains(_ ids: [Int64]) async {
        // TODO: 实现软删除逻辑
        print("[SyncService] Deleting \(ids.count) domains")
    }

    private func deleteTags(_ ids: [Int64]) async {
        // TODO: 实现软删除逻辑
        print("[SyncService] Deleting \(ids.count) tags")
    }

    private func deleteEntities(_ ids: [Int64]) async {
        // TODO: 实现软删除逻辑
        print("[SyncService] Deleting \(ids.count) entities")
    }

    // MARK: - 工具

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

// MARK: - Sync Error

enum SyncError: Error, LocalizedError {
    case notLoggedIn
    case syncInProgress

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "请先登录"
        case .syncInProgress:
            return "同步进行中"
        }
    }
}
