package com.tigerflow.dto.response;

import com.tigerflow.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 认证响应
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    private Long userId;

    private String token;

    private String refreshToken;

    private String expiresAt;

    /**
     * 用户信息
     */
    private UserInfo user;

    /**
     * 用户信息内部类
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserInfo {
        private Long id;
        private String username;
        private String nickname;
        private String email;
        private String phone;
        private String avatarUrl;
        private String status;

        public static UserInfo fromEntity(User user) {
            return UserInfo.builder()
                    .id(user.getId())
                    .username(user.getUsername())
                    .nickname(user.getNickname())
                    .email(user.getEmail())
                    .phone(user.getPhone())
                    .avatarUrl(user.getAvatarUrl())
                    .status(user.getStatus())
                    .build();
        }
    }
}
