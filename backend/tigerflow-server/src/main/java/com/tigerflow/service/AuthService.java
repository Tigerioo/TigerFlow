package com.tigerflow.service;

import com.tigerflow.dto.request.LoginRequest;
import com.tigerflow.dto.response.AuthResponse;
import com.tigerflow.entity.Token;
import com.tigerflow.entity.User;
import com.tigerflow.repository.TokenRepository;
import com.tigerflow.repository.UserRepository;
import com.tigerflow.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final TokenRepository tokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    /**
     * 用户名密码登录
     */
    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new RuntimeException("用户名或密码错误"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("用户名或密码错误");
        }

        return createTokenAndResponse(user, request.getDeviceId(), request.getDeviceName());
    }

    /**
     * 用户注册
     */
    @Transactional
    public AuthResponse register(String username, String password, String nickname) {
        if (userRepository.existsByUsername(username)) {
            throw new RuntimeException("用户名已存在");
        }

        User user = User.createWithUsername(username, passwordEncoder.encode(password));
        if (nickname != null && !nickname.isEmpty()) {
            user.setNickname(nickname);
        }
        user = userRepository.save(user);

        return createTokenAndResponse(user, null, null);
    }

    /**
     * 刷新 Token
     */
    @Transactional
    public AuthResponse refresh(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw new RuntimeException("无效的刷新 Token");
        }

        Token token = tokenRepository.findByRefreshToken(refreshToken)
                .orElseThrow(() -> new RuntimeException("Token 不存在"));

        if (token.isExpired()) {
            throw new RuntimeException("Token 已过期");
        }

        User user = userRepository.findById(token.getUserId())
                .orElseThrow(() -> new RuntimeException("用户不存在"));

        return createTokenAndResponse(user, token.getDeviceId(), token.getDeviceName());
    }

    /**
     * 登出
     */
    @Transactional
    public void logout(String token) {
        tokenRepository.findByToken(token).ifPresent(tokenRepository::delete);
    }

    /**
     * 创建 Token 并返回响应
     */
    private AuthResponse createTokenAndResponse(User user, String deviceId, String deviceName) {
        // 删除旧 Token
        if (deviceId != null) {
            tokenRepository.findByUserIdAndDeviceId(user.getId(), deviceId)
                    .ifPresent(tokenRepository::delete);
        }

        // 生成新 Token
        String accessToken = jwtTokenProvider.generateAccessToken(user.getId());
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getId());

        // 保存 Token
        Token token = new Token();
        token.setUserId(user.getId());
        token.setToken(accessToken);
        token.setRefreshToken(refreshToken);
        token.setDeviceId(deviceId);
        token.setDeviceName(deviceName);
        token.setExpiresAt(LocalDateTime.now().plusSeconds(jwtTokenProvider.getAccessTokenValidityFromConfiguration()));
        tokenRepository.save(token);

        return AuthResponse.builder()
                .userId(user.getId())
                .token(accessToken)
                .refreshToken(refreshToken)
                .expiresAt(token.getExpiresAt().toString())
                .build();
    }
}
