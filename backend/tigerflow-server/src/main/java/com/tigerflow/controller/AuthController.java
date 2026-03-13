package com.tigerflow.controller;

import com.tigerflow.dto.request.LoginRequest;
import com.tigerflow.dto.response.ApiResponse;
import com.tigerflow.dto.response.AuthResponse;
import com.tigerflow.entity.User;
import com.tigerflow.security.JwtTokenProvider;
import com.tigerflow.service.AuthService;
import javax.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/**
 * 认证控制器
 */
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final JwtTokenProvider jwtTokenProvider;

    /**
     * 用户名密码登录
     */
    @PostMapping("/login")
    public ApiResponse<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ApiResponse.success(response);
    }

    /**
     * 用户注册
     */
    @PostMapping("/register")
    public ApiResponse<AuthResponse> register(
            @RequestParam String username,
            @RequestParam String password,
            @RequestParam(required = false) String nickname) {
        AuthResponse response = authService.register(username, password, nickname);
        return ApiResponse.success(response);
    }

    /**
     * 刷新 Token
     */
    @PostMapping("/refresh")
    public ApiResponse<AuthResponse> refresh(@RequestBody RefreshRequest request) {
        AuthResponse response = authService.refresh(request.getRefreshToken());
        return ApiResponse.success(response);
    }

    /**
     * 登出
     */
    @PostMapping("/logout")
    public ApiResponse<Void> logout(Authentication authentication) {
        if (authentication != null) {
            User user = (User) authentication.getPrincipal();
            // 可以添加登出逻辑
        }
        return ApiResponse.success(null);
    }

    /**
     * 获取当前用户信息
     */
    @GetMapping("/me")
    public ApiResponse<User> getCurrentUser(Authentication authentication) {
        if (authentication != null) {
            User user = (User) authentication.getPrincipal();
            return ApiResponse.success(user);
        }
        return ApiResponse.error(401, "未登录");
    }

    /**
     * 刷新 Token 请求
     */
    public static class RefreshRequest {
        private String refreshToken;

        public String getRefreshToken() {
            return refreshToken;
        }

        public void setRefreshToken(String refreshToken) {
            this.refreshToken = refreshToken;
        }
    }
}
