import Foundation

// MARK: - API 配置

enum APIConfig {
    // 生产环境：使用服务器地址
    // 开发/模拟器：使用 localhost
    #if DEBUG
    static let baseURL = "http://localhost:9998"
    #else
    static let baseURL = "http://47.103.28.227:9998"
    #endif

    static let apiVersion = "v1"

    static var apiBaseURL: String {
        "\(baseURL)/api/\(apiVersion)"
    }
}

// MARK: - API 错误

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(Int, String?)
    case unauthorized
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .noData:
            return "无返回数据"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message ?? "未知错误")"
        case .unauthorized:
            return "未授权，请重新登录"
        case .tokenExpired:
            return "登录已过期，请重新登录"
        }
    }
}

// MARK: - API 响应基类

struct APIResponse<T: Codable>: Codable {
    let timestamp: String?
    let status: Int?
    let error: String?
    let data: T?

    var isSuccess: Bool {
        status == 200 || status == 201
    }
}

// MARK: - 空响应

struct EmptyResponse: Codable {}

// MARK: - 认证相关 DTO

struct LoginRequest: Codable {
    let username: String
    let password: String
    let deviceId: String?
    let deviceName: String?
}

struct RegisterRequest: Codable {
    let username: String
    let password: String
    let nickname: String?
}

struct AppleLoginRequest: Codable {
    let identityToken: String?
    let authorizationCode: String?
    let userIdentifier: String
    let fullName: String?
    let email: String?
}

struct AuthResponse: Codable {
    let userId: Int64?
    let token: String?
    let refreshToken: String
    let expiresAt: String?
    let expiresIn: Int?
    let user: UserDTO?

    var accessToken: String {
        token ?? ""
    }
}

struct UserDTO: Codable {
    let id: Int64
    let username: String?
    let nickname: String?
    let email: String?
    let phone: String?
    let avatarUrl: String?
    let status: String?
}

// MARK: - Flow DTO

struct FlowDTO: Codable {
    let id: Int64?
    let userId: Int64?
    let name: String
    let type: String
    let icon: String?
    let color: String?
    let isPinned: Bool?
    let sortOrder: Int?
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - FlowItem DTO

struct FlowItemDTO: Codable {
    let id: Int64?
    let userId: Int64?
    let flowId: String?
    let flowType: String
    let domainId: String?
    let title: String
    let content: String?
    let status: String?
    let occurredAt: String
    let startTime: String?
    let endTime: String?
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - Domain DTO

struct DomainDTO: Codable {
    let id: Int64?
    let userId: Int64?
    let name: String
    let icon: String?
    let color: String?
    let sortOrder: Int?
}

// MARK: - Tag DTO

struct TagDTO: Codable {
    let id: Int64?
    let userId: Int64?
    let name: String
    let color: String?
    let usageCount: Int?
}

// MARK: - Entity DTO

struct EntityDTO: Codable {
    let id: Int64?
    let userId: Int64?
    let name: String
    let type: String
    let emoji: String?
    let usageCount: Int?
}

// MARK: - 同步相关 DTO

struct SyncRequest: Codable {
    let lastSyncTime: String?
    let entityTypes: [String]?
}

struct SyncResponse: Codable {
    let syncTime: String
    let flows: [FlowDTO]?
    let flowItems: [FlowItemDTO]?
    let domains: [DomainDTO]?
    let tags: [TagDTO]?
    let entities: [EntityDTO]?
    let deletedFlows: [Int64]?
    let deletedFlowItems: [Int64]?
    let deletedDomains: [Int64]?
    let deletedTags: [Int64]?
    let deletedEntities: [Int64]?
}
