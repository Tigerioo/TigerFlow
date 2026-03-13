package com.tigerflow.controller;

import com.tigerflow.dto.request.LoginRequest;
import com.tigerflow.dto.request.RegisterRequest;
import com.tigerflow.dto.response.ApiResponse;
import com.tigerflow.dto.response.AuthResponse;
import com.tigerflow.entity.User;
import com.tigerflow.security.JwtTokenProvider;
import com.tigerflow.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@Tag(name = "认证管理", description = "用户注册、登录、Token 刷新等接口")
public class AuthController {

    private final AuthService authService;
    private final JwtTokenProvider jwtTokenProvider;

    @Operation(summary = "用户登录", description = "使用用户名密码登录系统")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "登录成功"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "请求参数错误", content = @Content),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "用户名或密码错误", content = @Content)
    })
    @PostMapping("/login")
    public ApiResponse<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ApiResponse.success(response);
    }

    @Operation(summary = "用户注册", description = "注册新用户账号")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "注册成功"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "请求参数错误或用户名已存在", content = @Content)
    })
    @PostMapping("/register")
    public ApiResponse<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(
                request.getUsername(),
                request.getPassword(),
                request.getNickname()
        );
        return ApiResponse.success(response);
    }

    @Operation(summary = "刷新 Token", description = "使用刷新令牌获取新的访问令牌")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "刷新成功"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "刷新令牌无效或已过期", content = @Content)
    })
    @PostMapping("/refresh")
    public ApiResponse<AuthResponse> refresh(@RequestBody RefreshRequest request) {
        AuthResponse response = authService.refresh(request.getRefreshToken());
        return ApiResponse.success(response);
    }

    @Operation(summary = "用户登出", description = "清除当前用户的登录状态")
    @PostMapping("/logout")
    public ApiResponse<Void> logout(Authentication authentication) {
        if (authentication != null) {
            User user = (User) authentication.getPrincipal();
            // 可以添加登出逻辑
        }
        return ApiResponse.success(null);
    }

    @Operation(summary = "获取当前用户", description = "获取已登录用户的信息")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "获取成功"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "未登录", content = @Content)
    })
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
    @Schema(description = "刷新 Token 请求")
    public static class RefreshRequest {
        @Schema(description = "刷新令牌", example = "eyJhbGciOiJIUzI1NiJ9...")
        private String refreshToken;

        public String getRefreshToken() {
            return refreshToken;
        }

        public void setRefreshToken(String refreshToken) {
            this.refreshToken = refreshToken;
        }
    }
}
