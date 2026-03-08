//
//  AuthManager.swift
//  TigerFlow
//
//  认证管理器 - 处理 Sign in with Apple
//

import Foundation
import AuthenticationServices
import SwiftUI
import Combine

@MainActor
class AuthManager: NSObject, ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var errorMessage: String?

    private let userDefaultsKey = "appleUserIdentifier"

    override init() {
        super.init()
        checkExistingLogin()
    }

    // 检查是否已有登录
    private func checkExistingLogin() {
        if let identifier = UserDefaults.standard.string(forKey: userDefaultsKey) {
            // 如果有保存的用户标识，视为已登录
            // 实际应用中应该向服务器验证 token
            isLoggedIn = !identifier.isEmpty
            if isLoggedIn {
                userName = UserDefaults.standard.string(forKey: "appleUserName") ?? "用户"
            }
        }
    }

    // 处理登录成功
    func handleLogin(result: Result<ASAuthorization, Error>) {
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

    // 退出登录
    func logout() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: "appleUserName")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")

        isLoggedIn = false
        userName = ""
        userEmail = ""
    }
}
