//
//  NetworkTestView.swift
//  TigerFlow
//
//  从flowdemo01复制的网络测试页面
//

import SwiftUI

/// 网络测试页面（与flowdemo01完全相同的实现）
struct NetworkTestView: View {
    @StateObject private var networkService = SimpleNetworkService()

    var body: some View {
        VStack(spacing: 24) {
            // 标题
            Text("网络连接测试")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)

            // 状态显示
            VStack(spacing: 16) {
                Image(systemName: statusIcon)
                    .font(.system(size: 60))
                    .foregroundColor(statusColor)

                Text(networkService.statusDescription)
                    .font(.body)
                    .foregroundColor(statusColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)

            // 测试按钮
            Button(action: {
                networkService.testConnection()
            }) {
                HStack {
                    if networkService.isTesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                    Text(networkService.isTesting ? "测试中..." : "开始测试")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(networkService.isTesting)
            .padding(.horizontal, 40)

            Spacer()

            // 诊断信息
            VStack(alignment: .leading, spacing: 8) {
                Text("诊断信息")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Group {
                    HStack {
                        Text("测试地址:")
                            .foregroundColor(.secondary)
                        Text("flow.tsinro.cn")
                            .fontWeight(.medium)
                    }
                    HStack {
                        Text("接口路径:")
                            .foregroundColor(.secondary)
                        Text("/api/v1/auth/login")
                    }
                    HStack {
                        Text("请求方式:")
                            .foregroundColor(.secondary)
                        Text("POST (application/json)")
                    }
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle("网络测试")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 辅助属性

    private var statusIcon: String {
        switch networkService.status {
        case .idle:
            return "wifi"
        case .testing:
            return "wifi.exclamationmark"
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch networkService.status {
        case .idle:
            return .gray
        case .testing:
            return .blue
        case .success:
            return .green
        case .failure:
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        NetworkTestView()
    }
}
