import Foundation

// MARK: - API Client

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // 重试配置
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.allowsCellularAccess = true
        config.waitsForConnectivity = true  // 等待网络连接
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - 通用请求方法（带重试）

    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true,
        retryCount: Int = 0
    ) async throws -> T {
        do {
            return try await performRequest(
                endpoint: endpoint,
                method: method,
                body: body,
                requiresAuth: requiresAuth
            )
        } catch {
            // 判断是否应该重试
            if retryCount < maxRetries, shouldRetry(error: error) {
                print("⚠️ 请求失败，\(retryCount + 1)/\(maxRetries) 次重试...")
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                return try await request(
                    endpoint: endpoint,
                    method: method,
                    body: body,
                    requiresAuth: requiresAuth,
                    retryCount: retryCount + 1
                )
            }
            throw error
        }
    }

    // MARK: - 执行实际请求

    private func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        requiresAuth: Bool
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 添加认证 Token
        if requiresAuth {
            if let token = TokenManager.shared.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw APIError.unauthorized
            }
        }

        // 添加请求体
        if let body = body {
            request.httpBody = try? encoder.encode(AnyEncodable(body))
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.noData
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    return decoded
                } catch {
                    throw APIError.decodingError(error)
                }

            case 401:
                // Token 过期，尝试刷新
                if try await refreshToken() {
                    return try await performRequest(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        requiresAuth: requiresAuth
                    )
                } else {
                    throw APIError.tokenExpired
                }

            default:
                let errorMessage = String(data: data, encoding: .utf8)
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - 判断是否应该重试

    private func shouldRetry(error: Error) -> Bool {
        let nsError = error as NSError

        // 网络相关错误码
        let retryableCodes = [
            -1009, // NSURLErrorNotConnectedToInternet
            -1001, // NSURLErrorTimedOut
            -1003, // NSURLErrorCannotFindHost
            -1004, // NSURLErrorCannotConnectToHost
            -1005, // NSURLErrorNetworkConnectionLost
            -1006  // NSURLErrorNotConnectedToInternet
        ]

        return retryableCodes.contains(nsError.code)
    }

    // MARK: - 测试网络连接（带诊断）

    func testNetworkConnection() async throws -> Bool {
        // 先检查网络状态
        let isConnected = await NetworkMonitor.shared.checkConnection()
        return isConnected
    }

    // MARK: - 认证接口

    func login(username: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(
            username: username,
            password: password,
            deviceId: DeviceInfo.deviceId,
            deviceName: DeviceInfo.deviceName
        )

        let response: APIResponse<AuthResponse> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/auth/login",
            method: .post,
            body: body,
            requiresAuth: false
        )

        guard let data = response.data else {
            throw APIError.serverError(response.status ?? 0, response.error)
        }

        // 保存 Token
        TokenManager.shared.saveTokens(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken
        )

        return data
    }

    func register(username: String, password: String, nickname: String?) async throws -> AuthResponse {
        let body = RegisterRequest(
            username: username,
            password: password,
            nickname: nickname
        )

        let response: APIResponse<AuthResponse> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/auth/register",
            method: .post,
            body: body,
            requiresAuth: false
        )

        guard let data = response.data else {
            throw APIError.serverError(response.status ?? 0, response.error)
        }

        // 保存 Token
        TokenManager.shared.saveTokens(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken
        )

        return data
    }

    func refreshToken() async throws -> Bool {
        guard let refreshToken = TokenManager.shared.refreshToken else {
            return false
        }

        let body = ["refreshToken": refreshToken]

        do {
            let response: APIResponse<AuthResponse> = try await request(
                endpoint: "\(APIConfig.apiBaseURL)/auth/refresh",
                method: .post,
                body: body,
                requiresAuth: false
            )

            if let data = response.data {
                TokenManager.shared.saveTokens(
                    accessToken: data.accessToken,
                    refreshToken: data.refreshToken
                )
                return true
            }
            return false
        } catch {
            return false
        }
    }

    func logout() {
        TokenManager.shared.clearTokens()
    }

    // MARK: - Apple 登录

    func appleLogin(
        identityToken: String?,
        authorizationCode: String?,
        userIdentifier: String,
        fullName: String?,
        email: String?
    ) async throws -> AuthResponse {
        let body = AppleLoginRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            userIdentifier: userIdentifier,
            fullName: fullName,
            email: email
        )

        let response: APIResponse<AuthResponse> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/auth/apple/login",
            method: .post,
            body: body,
            requiresAuth: false
        )

        guard let data = response.data else {
            throw APIError.serverError(response.status ?? 0, response.error)
        }

        // 保存 Token
        TokenManager.shared.saveTokens(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken
        )

        return data
    }

    // MARK: - Flow 接口

    func getFlows() async throws -> [FlowDTO] {
        let response: APIResponse<[FlowDTO]> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/flows"
        )
        return response.data ?? []
    }

    func createFlow(_ flow: FlowDTO) async throws -> FlowDTO {
        let response: APIResponse<FlowDTO> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/flows",
            method: .post,
            body: flow
        )
        guard let data = response.data else {
            throw APIError.serverError(response.status ?? 0, response.error)
        }
        return data
    }

    func updateFlow(_ flow: FlowDTO) async throws -> FlowDTO {
        guard let id = flow.id else {
            throw APIError.invalidURL
        }
        let response: APIResponse<FlowDTO> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/flows/\(id)",
            method: .put,
            body: flow
        )
        guard let data = response.data else {
            throw APIError.serverError(response.status ?? 0, response.error)
        }
        return data
    }

    func deleteFlow(id: Int64) async throws {
        let _: APIResponse<EmptyResponse> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/flows/\(id)",
            method: .delete
        )
    }

    // MARK: - FlowItem 接口

    func getFlowItems(flowId: String? = nil) async throws -> [FlowItemDTO] {
        var endpoint = "\(APIConfig.apiBaseURL)/flow-items"
        if let flowId = flowId {
            endpoint += "?flowId=\(flowId)"
        }
        let response: APIResponse<[FlowItemDTO]> = try await request(
            endpoint: endpoint
        )
        return response.data ?? []
    }

    func createFlowItem(_ item: FlowItemDTO) async throws -> FlowItemDTO {
        let response: APIResponse<FlowItemDTO> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/flow-items",
            method: .post,
            body: item
        )
        guard let data = response.data else {
            throw APIError.serverError(response.status ?? 0, response.error)
        }
        return data
    }

    func updateFlowItem(_ item: FlowItemDTO) async throws -> FlowItemDTO {
        guard let id = item.id else {
            throw APIError.invalidURL
        }
        let response: APIResponse<FlowItemDTO> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/flow-items/\(id)",
            method: .put,
            body: item
        )
        guard let data = response.data else {
            throw APIError.serverError(response.status ?? 0, response.error)
        }
        return data
    }

    func deleteFlowItem(id: Int64) async throws {
        let _: APIResponse<EmptyResponse> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/flow-items/\(id)",
            method: .delete
        )
    }

    // MARK: - Domain 接口

    func getDomains() async throws -> [DomainDTO] {
        let response: APIResponse<[DomainDTO]> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/domains"
        )
        return response.data ?? []
    }

    // MARK: - Tag 接口

    func getTags() async throws -> [TagDTO] {
        let response: APIResponse<[TagDTO]> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/tags"
        )
        return response.data ?? []
    }

    // MARK: - 同步接口

    func sync(lastSyncTime: String?) async throws -> SyncResponse {
        let body = SyncRequest(lastSyncTime: lastSyncTime, entityTypes: nil)
        let response: APIResponse<SyncResponse> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/sync",
            method: .post,
            body: body
        )
        guard let data = response.data else {
            throw APIError.serverError(response.status ?? 0, response.error)
        }
        return data
    }

    func fullSync() async throws -> SyncResponse {
        let response: APIResponse<SyncResponse> = try await request(
            endpoint: "\(APIConfig.apiBaseURL)/sync/full"
        )
        guard let data = response.data else {
            throw APIError.serverError(response.status ?? 0, response.error)
        }
        return data
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - 设备信息

enum DeviceInfo {
    #if canImport(UIKit)
    static var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    static var deviceName: String {
        UIDevice.current.name
    }
    #else
    static var deviceId: String {
        UUID().uuidString
    }

    static var deviceName: String {
        Host.current().localizedName ?? "Mac"
    }
    #endif
}

// MARK: - 支持任意 Encodable

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

#if canImport(UIKit)
import UIKit
#endif
