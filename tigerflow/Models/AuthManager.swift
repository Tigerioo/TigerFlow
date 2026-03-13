//
//  AuthManager.swift
//  TigerFlow
//
//  认证管理器 - 支持用户名密码登录和 Sign in with Apple
//

import Foundation
import AuthenticationServices
import SwiftUI
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let api = APIClient.shared
    private let tokenManager = TokenManager.shared

    init() {
        checkExistingLogin()
    }

    // MARK: - 检查登录状态

    private func checkExistingLogin() {
        isLoggedIn = tokenManager.isLoggedIn
    }

    // MARK: - 用户名密码登录

    func login(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "用户名和密码不能为空"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await api.login(username: username, password: password)
            isLoggedIn = true
            userName = response.user?.nickname ?? response.user?.username ?? "用户"
            userEmail = response.user?.email ?? ""
            errorMessage = nil

            // 登录成功后执行全量同步
            try? await SyncService.shared.fullSync()

        } catch {
            errorMessage = error.localizedDescription
            isLoggedIn = false
        }

        isLoading = false
    }

    // MARK: - 用户注册

    func register(username: String, password: String, nickname: String?) async {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "用户名和密码不能为空"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "密码长度至少6位"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await api.register(username: username, password: password, nickname: nickname)
            isLoggedIn = true
            userName = nickname ?? username
            errorMessage = nil

            // 注册成功后执行全量同步
            try? await SyncService.shared.fullSync()

        } catch {
            errorMessage = error.localizedDescription
            isLoggedIn = false
        }

        isLoading = false
    }

    // MARK: - Apple 登录

    private let userDefaultsKey = "appleUserIdentifier"

    func handleAppleLogin(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName?.givenName ?? "用户"
                let email = appleIDCredential.email ?? ""

                // 保存登录状态
                UserDefaults.standard.set(userIdentifier, forKey: userDefaultsKey)
                UserDefaults.standard.set(fullName, forKey: "appleUserName")
                if !email.isEmpty {
                    UserDefaults.standard.set(email, forKey: "appleUserEmail")
                }

                isLoggedIn = true
                userName = fullName
                userEmail = email
                errorMessage = nil
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            isLoggedIn = false
        }
    }

    // MARK: - 退出登录

    func logout() {
        // 清除 Token
        api.logout()
        tokenManager.clearTokens()

        // 清除 Apple 登录状态
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: "appleUserName")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")

        isLoggedIn = false
        userName = ""
        userEmail = ""
        errorMessage = nil
    }
}
