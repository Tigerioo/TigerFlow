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
                let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                let email = appleIDCredential.email ?? ""

                // 保存到本地
                UserDefaults.standard.set(userIdentifier, forKey: userDefaultsKey)
                if !fullName.isEmpty {
                    UserDefaults.standard.set(fullName, forKey: "appleUserName")
                }
                if !email.isEmpty {
                    UserDefaults.standard.set(email, forKey: "appleUserEmail")
                }

                // 异步发送到后端
                Task { @MainActor in
                    let identityToken: String? = appleIDCredential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
                    let authCode: String? = appleIDCredential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }

                    await performAppleLoginToBackend(
                        userIdentifier: userIdentifier,
                        fullName: fullName.isEmpty ? nil : fullName,
                        email: email.isEmpty ? nil : email,
                        identityToken: identityToken,
                        authorizationCode: authCode
                    )
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            isLoggedIn = false
        }
    }

    // MARK: - Apple 登录发送到后端

    @MainActor
    private func performAppleLoginToBackend(
        userIdentifier: String,
        fullName: String?,
        email: String?,
        identityToken: String?,
        authorizationCode: String?
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await api.appleLogin(
                identityToken: identityToken,
                authorizationCode: authorizationCode,
                userIdentifier: userIdentifier,
                fullName: fullName,
                email: email
            )

            isLoggedIn = true
            userName = response.user?.nickname ?? fullName ?? "Apple 用户"
            userEmail = response.user?.email ?? email ?? ""
            errorMessage = nil

            // 登录成功后执行全量同步
            try? await SyncService.shared.fullSync()

        } catch {
            // 如果后端登录失败，仍保持本地登录状态（仅用于展示）
            // 生产环境应该处理这个错误
            print("Apple 登录后端失败: \(error)")
            isLoggedIn = true
            userName = fullName ?? "Apple 用户"
            userEmail = email ?? ""
        }

        isLoading = false
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
