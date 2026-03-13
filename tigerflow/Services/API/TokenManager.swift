import Foundation

// MARK: - Token Manager

final class TokenManager {
    static let shared = TokenManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let accessToken = "com.tigerflow.accessToken"
        static let refreshToken = "com.tigerflow.refreshToken"
        static let lastSyncTime = "com.tigerflow.lastSyncTime"
        static let currentUserId = "com.tigerflow.currentUserId"
    }

    private init() {}

    // MARK: - Token 存取

    var accessToken: String? {
        get { defaults.string(forKey: Keys.accessToken) }
        set { defaults.set(newValue, forKey: Keys.accessToken) }
    }

    var refreshToken: String? {
        get { defaults.string(forKey: Keys.refreshToken) }
        set { defaults.set(newValue, forKey: Keys.refreshToken) }
    }

    var isLoggedIn: Bool {
        accessToken != nil
    }

    func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        currentUserId = nil
    }

    // MARK: - 同步时间

    var lastSyncTime: Date? {
        get {
            guard let string = defaults.string(forKey: Keys.lastSyncTime) else {
                return nil
            }
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: string)
        }
        set {
            if let date = newValue {
                let formatter = ISO8601DateFormatter()
                defaults.set(formatter.string(from: date), forKey: Keys.lastSyncTime)
            } else {
                defaults.removeObject(forKey: Keys.lastSyncTime)
            }
        }
    }

    var lastSyncTimeString: String? {
        guard let date = lastSyncTime else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }

    // MARK: - 用户信息

    var currentUserId: Int64? {
        get { Int64(defaults.string(forKey: Keys.currentUserId) ?? "0") }
        set { defaults.set(newValue.map { String($0) }, forKey: Keys.currentUserId) }
    }
}
