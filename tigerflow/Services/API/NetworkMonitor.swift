import Foundation
import Combine
import Network

enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverError(Int)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "网络连接不可用，请检查网络设置"
        case .timeout:
            return "请求超时，请稍后重试"
        case .serverError(let code):
            return "服务器错误 (\(code))"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout:
            return true
        case .serverError(let code) where (500...599).contains(code):
            return true
        default:
            return false
        }
    }

    // 从 URLSession 错误转换
    static func from(_ error: Error) -> NetworkError {
        let nsError = error as NSError

        switch nsError.code {
        case -1009: // NSURLErrorNotConnectedToInternet
            return .noConnection
        case -1001: // NSURLErrorTimedOut
            return .timeout
        case -1003, -1004, -1005, -1006:
            return .noConnection
        default:
            return .unknown(error)
        }
    }
}

// MARK: - 网络状态管理器

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private init() {
        // iOS 17+ 使用 NWPathMonitor
        if #available(iOS 17.0, macOS 14.0, *) {
            startMonitoring()
        }
    }

    @available(iOS 17.0, macOS 14.0, *)
    private func startMonitoring() {
        let monitor = NWPathMonitorWrapper()
        monitor.pathUpdateHandler = { [weak self] isConnected, connectionType in
            Task { @MainActor in
                self?.isConnected = isConnected
                self?.connectionType = connectionType
            }
        }
        monitor.start()
    }

    func checkConnection() async -> Bool {
        guard let url = URL(string: "https://www.baidu.com") else {
            return false
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
}

// MARK: - NWPathMonitor 封装

final class NWPathMonitorWrapper {
    var pathUpdateHandler: ((Bool, NetworkMonitor.ConnectionType) -> Void)?

    func start() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            let connectionType: NetworkMonitor.ConnectionType

            if path.usesInterfaceType(.wifi) {
                connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                connectionType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                connectionType = .ethernet
            } else {
                connectionType = .unknown
            }

            self?.pathUpdateHandler?(isConnected, connectionType)
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}
