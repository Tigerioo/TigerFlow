package com.tigerflow.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * Apple 登录请求
 */
@Data
@Schema(description = "Apple 登录请求")
public class AppleLoginRequest {

    @Schema(description = "Apple identity token (JWT)", example = "eyJraWQi...")
    private String identityToken;

    @Schema(description = "Apple 授权码", example = "ctab5f2e1b...")
    private String authorizationCode;

    @Schema(description = "Apple 用户唯一标识", example = "001234.abc...")
    private String userIdentifier;

    @Schema(description = "用户全名", example = "John Doe")
    private String fullName;

    @Schema(description = "用户邮箱", example = "user@example.com")
    private String email;
}
