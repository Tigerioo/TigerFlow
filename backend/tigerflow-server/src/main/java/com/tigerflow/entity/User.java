package com.tigerflow.entity;

import javax.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 用户实体
 */
@Entity
@Table(name = "tf_user")
@Getter
@Setter
@NoArgsConstructor
public class User extends BaseEntity {

    @Column(length = 50, unique = true)
    private String username;

    @Column(length = 255)
    private String password;

    @Column(length = 50)
    private String nickname;

    @Column(length = 100, unique = true)
    private String email;

    @Column(name = "avatar_url", length = 500)
    private String avatarUrl;

    @Column(length = 20, unique = true)
    private String phone;

    @Column(length = 20)
    private String status = "active";

    @Column(name = "apple_user_id", length = 100, unique = true)
    private String appleUserId;

    /**
     * 用户名密码登录
     */
    public static User createWithUsername(String username, String password) {
        User user = new User();
        user.setUsername(username);
        user.setPassword(password);
        return user;
    }

    /**
     * Apple 登录创建用户
     */
    public static User createWithApple(String appleUserId, String email, String nickname) {
        User user = new User();
        user.setAppleUserId(appleUserId);
        user.setEmail(email);
        user.setNickname(nickname);
        // Apple 登录不需要密码
        user.setPassword(null);
        return user;
    }
}
