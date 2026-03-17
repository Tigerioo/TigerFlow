package com.tigerflow.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tigerflow.dto.request.AppleLoginRequest;
import com.tigerflow.dto.request.RegisterRequest;
import com.tigerflow.entity.User;
import com.tigerflow.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * AuthController 接口测试
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        // 每个测试前清理数据库
        userRepository.deleteAll();
    }

    // ==================== 用户注册接口测试 ====================

    @Test
    void testRegister_Success() throws Exception {
        // Arrange
        RegisterRequest request = new RegisterRequest();
        request.setUsername("testuser");
        request.setPassword("password123");
        request.setNickname("测试用户");

        // Act & Assert
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.token").exists())
                .andExpect(jsonPath("$.data.refreshToken").exists());

        // 验证用户已创建
        assertTrue(userRepository.findByUsername("testuser").isPresent());
    }

    @Test
    void testRegister_MissingUsername() throws Exception {
        // Arrange
        RegisterRequest request = new RegisterRequest();
        request.setPassword("password123");

        // Act & Assert
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    // ==================== Apple 登录接口测试 ====================

    @Test
    void testAppleLogin_NewUser() throws Exception {
        // Arrange
        AppleLoginRequest request = new AppleLoginRequest();
        request.setUserIdentifier("apple.user.id.001");
        request.setFullName("Apple Test User");
        request.setEmail("apple@test.com");

        // Act & Assert
        mockMvc.perform(post("/api/v1/auth/apple/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.token").exists())
                .andExpect(jsonPath("$.data.refreshToken").exists())
                .andExpect(jsonPath("$.data.user.nickname").value("Apple Test User"));

        // 验证用户已创建
        assertTrue(userRepository.findByAppleUserId("apple.user.id.001").isPresent());
    }

    @Test
    void testAppleLogin_ExistingUser() throws Exception {
        // Arrange - 先创建 Apple 用户
        User existingUser = new User();
        existingUser.setAppleUserId("apple.user.id.002");
        existingUser.setNickname("Existing Apple User");
        existingUser.setEmail("existing@apple.com");
        existingUser.setStatus("active");
        userRepository.save(existingUser);

        AppleLoginRequest request = new AppleLoginRequest();
        request.setUserIdentifier("apple.user.id.002");
        request.setEmail("updated@apple.com");

        // Act & Assert
        mockMvc.perform(post("/api/v1/auth/apple/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.user.nickname").value("Existing Apple User"));
    }

    // ==================== 登出接口测试 ====================

    @Test
    void testLogout_NotAuthenticated() throws Exception {
        // Act & Assert
        mockMvc.perform(post("/api/v1/auth/logout"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
    }

    // ==================== Swagger 接口文档测试 ====================

    @Test
    void testApiDocs_Accessible() throws Exception {
        // Act & Assert - API 文档应该可以访问
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk());
    }
}
