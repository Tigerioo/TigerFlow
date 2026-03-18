//
//  SettingsView.swift
//  TigerFlow
//
//  设置页面 - 支持多种登录方式
//

import SwiftUI
import AuthenticationServices
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager = AuthManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingLoginSheet = false
    @State private var networkError: String?
    @State private var isTestingNetwork = false

    var body: some View {
        NavigationStack {
            List {
                // 账户状态
                accountSection

                // 登录方式
                if !authManager.isLoggedIn {
                    loginOptionsSection
                }

                // 网络状态
                networkStatusSection

                // 同步设置
                syncSection

                // 退出登录
                if authManager.isLoggedIn {
                    logoutSection
                }

                // 关于
                aboutSection
            }
            .navigationTitle("设置")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingLoginSheet) {
                LoginSheetView(authManager: authManager, isPresented: $showingLoginSheet)
            }
            .alert("网络错误", isPresented: .init(
                get: { networkError != nil },
                set: { if !$0 { networkError = nil } }
            )) {
                Button("重试") {
                    testNetwork()
                }
                Button("确定", role: .cancel) {}
            } message: {
                Text(networkError ?? "网络连接不可用")
            }
        }
    }

    // MARK: - 网络状态

    @ViewBuilder
    private var networkStatusSection: some View {
        Section {
            // 测试网络连接按钮
            Button {
                testNetwork()
            } label: {
                HStack {
                    Image(systemName: isTestingNetwork ? "wifi.exclamationmark" : "wifi")
                        .foregroundColor(isTestingNetwork ? .orange : .blue)

                    if isTestingNetwork {
                        Text("测试中...")
                    } else {
                        Text("测试网络连接")
                    }

                    Spacer()
                }
            }
            .disabled(isTestingNetwork)

            HStack {
                Image(systemName: "server.rack")
                    .foregroundColor(.orange)
                Text("服务器地址")
                Spacer()
                Text(APIConfig.baseURL)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("网络")
        }
    }

    private func testNetwork() {
        isTestingNetwork = true
        networkError = nil

        Task {
            do {
                let success = try await APIClient.shared.testNetworkConnection()
                if success {
                    print("✅ 网络连接正常")
                } else {
                    networkError = "无法连接到服务器，请检查网络设置"
                }
            } catch {
                // 转换错误为友好提示
                let nsError = error as NSError
                if nsError.code == -1009 {
                    networkError = "网络连接不可用，请检查网络设置"
                } else {
                    networkError = error.localizedDescription
                }
            }
            isTestingNetwork = false
        }
    }

    // MARK: - 账户状态

    @ViewBuilder
    private var accountSection: some View {
        Section {
            if authManager.isLoggedIn {
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
                HStack {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                    Text("未登录")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("账户")
        }
    }

    // MARK: - 登录方式

    @ViewBuilder
    private var loginOptionsSection: some View {
        Section {
            // 用户名密码登录
            Button {
                showingLoginSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Text("用户名密码登录")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Sign in with Apple
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task {
                    authManager.handleAppleLogin(result: result)
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
        } header: {
            Text("登录方式")
        } footer: {
            Text("选择一种方式登录你的账户")
        }
    }

    // MARK: - 同步设置

    @ViewBuilder
    private var syncSection: some View {
        Section {
            // 测试网络连接按钮
            Button {
                Task {
                    do {
                        let success = try await APIClient.shared.testNetworkConnection()
                        if success {
                            print("✅ 网络连接正常")
                        } else {
                            print("❌ 网络连接失败")
                        }
                    } catch {
                        print("❌ 网络错误: \(error)")
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "wifi")
                        .foregroundColor(.blue)
                    Text("测试网络连接")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Image(systemName: "server.rack")
                    .foregroundColor(.orange)
                Text("服务器地址")
                Spacer()
                Text(APIConfig.baseURL)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.green)
                Text("数据同步")
                Spacer()
                Text(authManager.isLoggedIn ? "已启用" : "未启用")
                    .foregroundColor(.secondary)
            }

            if authManager.isLoggedIn {
                Text("你的数据已同步到服务器，可以在其他设备上访问。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("登录后，你的数据将自动同步到服务器。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("同步")
        }
    }

    // MARK: - 退出登录

    @ViewBuilder
    private var logoutSection: some View {
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

    // MARK: - 关于

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            HStack {
                Text("版本")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "https://www.tsinro.cn/privacy")!) {
                    HStack {
                        Text("隐私政策")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }

            Link(destination: URL(string: "https://www.tsinro.cn/terms")!) {
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
}

// MARK: - 登录 Sheet

struct LoginSheetView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var isPresented: Bool
    @State private var isRegisterMode = false
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var nickname = ""
    @State private var localError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("用户名", text: $username)
                        .textContentType(.username)
                        #if !os(macOS)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        #endif

                    SecureField("密码", text: $password)
                        .textContentType(.password)

                    if isRegisterMode {
                        SecureField("确认密码", text: $confirmPassword)
                            .textContentType(.newPassword)

                        TextField("昵称（可选）", text: $nickname)
                    }
                }

                if let error = localError ?? authManager.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    if authManager.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(.circular)
                            Spacer()
                        }
                    } else {
                        Button {
                            performLogin()
                        } label: {
                            Text(isRegisterMode ? "注册" : "登录")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(username.isEmpty || password.isEmpty || authManager.isLoading)
                    }
                }

                Section {
                    Button {
                        isRegisterMode.toggle()
                        localError = nil
                    } label: {
                        Text(isRegisterMode ? "已有账号？登录" : "没有账号？注册")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isRegisterMode ? "注册" : "登录")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
            .onChange(of: authManager.isLoggedIn) { _, newValue in
                if newValue {
                    isPresented = false
                }
            }
        }
    }

    private func performLogin() {
        localError = nil

        if isRegisterMode {
            if password != confirmPassword {
                localError = "两次密码不一致"
                return
            }
            Task {
                await authManager.register(username: username, password: password, nickname: nickname.isEmpty ? nil : nickname)
            }
        } else {
            Task {
                await authManager.login(username: username, password: password)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
