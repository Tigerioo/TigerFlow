//
//  SimpleNetworkService.swift
//  TigerFlow
//
//  从flowdemo01复制的网络测试服务，使用URLSession.shared
//

import Foundation
import Combine

/// 网络连接状态
enum SimpleNetworkStatus: Equatable {
    case idle
    case testing
    case success(responseTime: Int, message: String)
    case failure(error: String)
}

/// 简化版网络测试服务（与flowdemo01完全相同）
class SimpleNetworkService: ObservableObject {
    @Published var status: SimpleNetworkStatus = .idle
    @Published var isTesting: Bool = false

    /// 测试地址 - 使用登录接口
    private let testURL = URL(string: "https://flow.tsinro.cn/api/v1/auth/login")!
    private let timeout: TimeInterval = 10

    /// 执行网络可用性测试
    func testConnection() {
        guard !isTesting else { return }

        isTesting = true
        status = .testing

        var request = URLRequest(url: testURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout

        // 使用一个假的登录请求来测试网络连通性
        let body: [String: Any] = [
            "username": "test_connection",
            "password": "test_only"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            isTesting = false
            status = .failure(error: "请求体序列化失败")
            return
        }

        let startTime = Date()

        // 使用URLSession.shared，与flowdemo01完全相同
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isTesting = false

                if let error = error {
                    self?.status = .failure(error: error.localizedDescription)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.status = .failure(error: "无效响应")
                    return
                }

                let responseTime = Int(Date().timeIntervalSince(startTime) * 1000)

                // 解析响应数据
                var message = "HTTP \(httpResponse.statusCode)"
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["message"] as? String {
                    message = msg
                }

                if (200...299).contains(httpResponse.statusCode) {
                    self?.status = .success(responseTime: responseTime, message: message)
                } else {
                    self?.status = .failure(error: "\(message) (HTTP \(httpResponse.statusCode))")
                }
            }
        }

        task.resume()
    }

    /// 获取状态描述
    var statusDescription: String {
        switch status {
        case .idle:
            return "点击按钮测试网络连接"
        case .testing:
            return "请求中..."
        case .success(let responseTime, let message):
            return "连接成功: \(message) (响应: \(responseTime)ms)"
        case .failure(let error):
            return "连接失败: \(error)"
        }
    }

    /// 获取状态颜色
    var statusColor: Color {
        switch status {
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

#if canImport(SwiftUI)
import SwiftUI
#endif
