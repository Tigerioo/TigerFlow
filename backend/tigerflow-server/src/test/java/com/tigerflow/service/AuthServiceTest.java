package com.tigerflow.service;

import com.tigerflow.dto.request.AppleLoginRequest;
import com.tigerflow.dto.request.LoginRequest;
import com.tigerflow.dto.response.AuthResponse;
import com.tigerflow.entity.Token;
import com.tigerflow.entity.User;
import com.tigerflow.repository.TokenRepository;
import com.tigerflow.repository.UserRepository;
import com.tigerflow.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * AuthService 单元测试
 */
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private TokenRepository tokenRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @InjectMocks
    private AuthService authService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setUsername("testuser");
        testUser.setPassword("encodedPassword");
        testUser.setNickname("测试用户");
        testUser.setEmail("test@example.com");
        testUser.setStatus("active");
    }

    // ==================== 用户名密码登录测试 ====================

    @Test
    void testLogin_Success() {
        // Arrange
        LoginRequest request = new LoginRequest();
        request.setUsername("testuser");
        request.setPassword("password123");
        request.setDeviceId("device-001");
        request.setDeviceName("iPhone");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches("password123", "encodedPassword")).thenReturn(true);
        when(jwtTokenProvider.generateAccessToken(any())).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken(any())).thenReturn("refresh-token");
        when(jwtTokenProvider.getAccessTokenValidityFromConfiguration()).thenReturn(3600L);

        // Act
        AuthResponse response = authService.login(request);

        // Assert
        assertNotNull(response);
        assertEquals(1L, response.getUserId());
        assertNotNull(response.getToken());
        assertNotNull(response.getRefreshToken());
        verify(tokenRepository).save(any(Token.class));
    }

    @Test
    void testLogin_WrongPassword() {
        // Arrange
        LoginRequest request = new LoginRequest();
        request.setUsername("testuser");
        request.setPassword("wrongpassword");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches("wrongpassword", "encodedPassword")).thenReturn(false);

        // Act & Assert
        assertThrows(RuntimeException.class, () -> authService.login(request));
    }

    @Test
    void testLogin_UserNotFound() {
        // Arrange
        LoginRequest request = new LoginRequest();
        request.setUsername("nonexistent");
        request.setPassword("password");

        when(userRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(RuntimeException.class, () -> authService.login(request));
    }

    // ==================== 用户注册测试 ====================

    @Test
    void testRegister_Success() {
        // Arrange
        when(userRepository.existsByUsername("newuser")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encodedPassword");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(2L);
            return user;
        });
        when(jwtTokenProvider.generateAccessToken(any())).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken(any())).thenReturn("refresh-token");
        when(jwtTokenProvider.getAccessTokenValidityFromConfiguration()).thenReturn(3600L);

        // Act
        AuthResponse response = authService.register("newuser", "password123", "新用户");

        // Assert
        assertNotNull(response);
        assertEquals(2L, response.getUserId());
        verify(userRepository).save(any(User.class));
    }

    @Test
    void testRegister_UsernameExists() {
        // Arrange
        when(userRepository.existsByUsername("existinguser")).thenReturn(true);

        // Act & Assert
        assertThrows(RuntimeException.class,
            () -> authService.register("existinguser", "password123", null));
    }

    // ==================== Apple 登录测试 ====================

    @Test
    void testAppleLogin_NewUser() {
        // Arrange
        AppleLoginRequest request = new AppleLoginRequest();
        request.setUserIdentifier("apple.user.id.123");
        request.setFullName("Apple User");
        request.setEmail("apple@example.com");

        when(userRepository.findByAppleUserId("apple.user.id.123")).thenReturn(Optional.empty());
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(3L);
            return user;
        });
        when(jwtTokenProvider.generateAccessToken(any())).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken(any())).thenReturn("refresh-token");
        when(jwtTokenProvider.getAccessTokenValidityFromConfiguration()).thenReturn(3600L);

        // Act
        AuthResponse response = authService.appleLogin(request);

        // Assert
        assertNotNull(response);
        assertEquals(3L, response.getUserId());
        assertNotNull(response.getUser());
        assertEquals("Apple User", response.getUser().getNickname());
        verify(userRepository).save(any(User.class));
    }

    @Test
    void testAppleLogin_ExistingUser() {
        // Arrange
        testUser.setAppleUserId("apple.user.id.123");

        AppleLoginRequest request = new AppleLoginRequest();
        request.setUserIdentifier("apple.user.id.123");
        request.setEmail("updated@example.com");

        when(userRepository.findByAppleUserId("apple.user.id.123")).thenReturn(Optional.of(testUser));
        when(userRepository.save(any(User.class))).thenReturn(testUser);
        when(jwtTokenProvider.generateAccessToken(any())).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken(any())).thenReturn("refresh-token");
        when(jwtTokenProvider.getAccessTokenValidityFromConfiguration()).thenReturn(3600L);

        // Act
        AuthResponse response = authService.appleLogin(request);

        // Assert
        assertNotNull(response);
        assertEquals(1L, response.getUserId());
    }

    @Test
    void testAppleLogin_MissingUserIdentifier() {
        // Arrange
        AppleLoginRequest request = new AppleLoginRequest();
        request.setUserIdentifier(null);

        // Act & Assert
        assertThrows(RuntimeException.class, () -> authService.appleLogin(request));
    }

    // ==================== Token 刷新测试 ====================

    @Test
    void testRefresh_Success() {
        // Arrange
        Token token = new Token();
        token.setId(1L);
        token.setUserId(1L);
        token.setRefreshToken("valid-refresh-token");
        token.setExpiresAt(LocalDateTime.now().plusDays(7));

        when(jwtTokenProvider.validateToken("valid-refresh-token")).thenReturn(true);
        when(tokenRepository.findByRefreshToken("valid-refresh-token")).thenReturn(Optional.of(token));
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
        when(jwtTokenProvider.generateAccessToken(any())).thenReturn("new-access-token");
        when(jwtTokenProvider.generateRefreshToken(any())).thenReturn("new-refresh-token");
        when(jwtTokenProvider.getAccessTokenValidityFromConfiguration()).thenReturn(3600L);

        // Act
        AuthResponse response = authService.refresh("valid-refresh-token");

        // Assert
        assertNotNull(response);
        assertEquals(1L, response.getUserId());
    }

    @Test
    void testRefresh_InvalidToken() {
        // Arrange
        when(jwtTokenProvider.validateToken("invalid-token")).thenReturn(false);

        // Act & Assert
        assertThrows(RuntimeException.class, () -> authService.refresh("invalid-token"));
    }

    // ==================== 登出测试 ====================

    @Test
    void testLogout() {
        // Arrange
        Token token = new Token();
        token.setId(1L);
        token.setToken("access-token");

        when(tokenRepository.findByToken("access-token")).thenReturn(Optional.of(token));

        // Act
        authService.logout("access-token");

        // Assert
        verify(tokenRepository).delete(token);
    }
}
