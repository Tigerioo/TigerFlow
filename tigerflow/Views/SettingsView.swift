//
//  SettingsView.swift
//  TigerFlow
//
//  设置页面
//

import SwiftUI
import AuthenticationServices
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager = AuthManager()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Apple ID 登录状态
                Section {
                    if authManager.isLoggedIn {
                        // 已登录状态
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(authManager.userName)
                                    .font(.headline)
                                if !authManager.userEmail.isEmpty {
                                    Text(authManager.userEmail)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 8)
                    } else {
                        // 未登录 - Sign in with Apple 按钮
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            Task {
                                authManager.handleLogin(result: result)
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 44)
                    }
                } header: {
                    Text("账户")
                }

                // iCloud 同步状态
                Section {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                        Text("iCloud 同步")
                        Spacer()
                        Text("自动")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "checkmark.icloud.fill")
                            .foregroundColor(.green)
                        Text("数据同步")
                        Spacer()
                        Text("已启用")
                            .foregroundColor(.secondary)
                    }

                    Text("你的数据会自动同步到 iCloud，在所有设备上保持更新。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("同步")
                } footer: {
                    Text("使用 iCloud 可以确保你的数据安全，并在不同设备间同步。")
                }

                // 退出登录（仅已登录时显示）
                if authManager.isLoggedIn {
                    Section {
                        Button(role: .destructive) {
                            authManager.logout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("退出登录")
                            }
                        }
                    }
                }

                // 关于
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://tigerflow.app/privacy")!) {
                        HStack {
                            Text("隐私政策")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }

                    Link(destination: URL(string: "https://tigerflow.app/terms")!) {
                        HStack {
                            Text("服务条款")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
