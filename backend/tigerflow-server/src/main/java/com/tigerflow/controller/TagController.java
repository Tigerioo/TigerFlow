package com.tigerflow.controller;

import com.tigerflow.dto.request.TagRequest;
import com.tigerflow.dto.response.ApiResponse;
import com.tigerflow.dto.response.TagResponse;
import com.tigerflow.entity.User;
import com.tigerflow.repository.TagRepository;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.tigerflow.entity.Tag;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Tag 标签控制器
 */
@RestController
@RequestMapping("/api/v1/tags")
@RequiredArgsConstructor
@io.swagger.v3.oas.annotations.tags.Tag(name = "标签管理", description = "Tag 标签的 CRUD 接口")
public class TagController {

    private final TagRepository tagRepository;

    @Operation(summary = "获取当前用户的所有 Tag")
    @GetMapping
    public ApiResponse<List<TagResponse>> getTags(Authentication authentication) {
        Long userId = getUserId(authentication);
        List<Tag> tags = tagRepository.findByUserIdOrderByUsageCountDesc(userId);
        List<TagResponse> responses = tags.stream()
                .map(TagResponse::fromEntity)
                .collect(Collectors.toList());
        return ApiResponse.success(responses);
    }

    @Operation(summary = "获取单个 Tag")
    @GetMapping("/{id}")
    public ApiResponse<TagResponse> getTag(@PathVariable Long id, Authentication authentication) {
        Long userId = getUserId(authentication);
        Tag tag = tagRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (tag == null) {
            return ApiResponse.error(404, "Tag 不存在");
        }
        return ApiResponse.success(TagResponse.fromEntity(tag));
    }

    @Operation(summary = "创建 Tag")
    @PostMapping
    public ApiResponse<TagResponse> createTag(
            @RequestBody TagRequest request,
            Authentication authentication) {
        Long userId = getUserId(authentication);

        // 检查是否已存在
        List<Tag> existingTags = tagRepository.findByUserIdAndNameAndDeletedAtIsNull(userId, request.getName());
        if (!existingTags.isEmpty()) {
            return ApiResponse.error(400, "标签已存在");
        }

        Tag tag = new Tag();
        tag.setUserId(userId);
        tag.setName(request.getName());
        tag.setColor(request.getColor());
        tag.setUsageCount(0);

        tag = tagRepository.save(tag);
        return ApiResponse.success(TagResponse.fromEntity(tag));
    }

    @Operation(summary = "更新 Tag")
    @PutMapping("/{id}")
    public ApiResponse<TagResponse> updateTag(
            @PathVariable Long id,
            @RequestBody TagRequest request,
            Authentication authentication) {
        Long userId = getUserId(authentication);

        Tag tag = tagRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (tag == null) {
            return ApiResponse.error(404, "Tag 不存在");
        }

        if (request.getName() != null) tag.setName(request.getName());
        if (request.getColor() != null) tag.setColor(request.getColor());

        tag = tagRepository.save(tag);
        return ApiResponse.success(TagResponse.fromEntity(tag));
    }

    @Operation(summary = "删除 Tag")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteTag(@PathVariable Long id, Authentication authentication) {
        Long userId = getUserId(authentication);

        Tag tag = tagRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (tag == null) {
            return ApiResponse.error(404, "Tag 不存在");
        }

        tagRepository.delete(tag);
        return ApiResponse.success(null);
    }

    private Long getUserId(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return user.getId();
    }
}
