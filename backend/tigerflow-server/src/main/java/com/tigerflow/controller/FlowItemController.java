package com.tigerflow.controller;

import com.tigerflow.dto.request.FlowItemRequest;
import com.tigerflow.dto.response.ApiResponse;
import com.tigerflow.dto.response.FlowItemResponse;
import com.tigerflow.entity.FlowItem;
import com.tigerflow.entity.User;
import com.tigerflow.repository.FlowItemRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * FlowItem 流程项控制器
 */
@RestController
@RequestMapping("/api/v1/flow-items")
@RequiredArgsConstructor
@Tag(name = "流程项管理", description = "FlowItem 流程项的 CRUD 接口")
public class FlowItemController {

    private final FlowItemRepository flowItemRepository;

    @Operation(summary = "获取当前用户的所有 FlowItem")
    @GetMapping
    public ApiResponse<List<FlowItemResponse>> getFlowItems(
            @RequestParam(required = false) String flowId,
            @RequestParam(required = false) String flowType,
            @RequestParam(required = false) String domainId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            Authentication authentication) {
        Long userId = getUserId(authentication);

        List<FlowItem> items;

        if (flowId != null) {
            items = flowItemRepository.findByUserIdAndFlowIdAndDeletedAtIsNull(userId, flowId);
        } else if (flowType != null) {
            items = flowItemRepository.findByUserIdAndFlowTypeAndDeletedAtIsNull(userId, flowType);
        } else if (startDate != null && endDate != null) {
            items = flowItemRepository.findByUserIdAndOccurredAtBetweenAndDeletedAtIsNull(userId, startDate, endDate);
        } else {
            items = flowItemRepository.findByUserIdAndDeletedAtIsNull(userId);
        }

        List<FlowItemResponse> responses = items.stream()
                .map(FlowItemResponse::fromEntity)
                .collect(Collectors.toList());
        return ApiResponse.success(responses);
    }

    @Operation(summary = "获取单个 FlowItem")
    @GetMapping("/{id}")
    public ApiResponse<FlowItemResponse> getFlowItem(@PathVariable Long id, Authentication authentication) {
        Long userId = getUserId(authentication);
        FlowItem item = flowItemRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (item == null) {
            return ApiResponse.error(404, "FlowItem 不存在");
        }
        return ApiResponse.success(FlowItemResponse.fromEntity(item));
    }

    @Operation(summary = "创建 FlowItem")
    @PostMapping
    public ApiResponse<FlowItemResponse> createFlowItem(
            @RequestBody FlowItemRequest request,
            Authentication authentication) {
        Long userId = getUserId(authentication);

        FlowItem item = new FlowItem();
        item.setUserId(userId);
        item.setFlowId(request.getFlowId());
        item.setFlowType(request.getFlowType());
        item.setDomainId(request.getDomainId());
        item.setTitle(request.getTitle());
        item.setContent(request.getContent());
        item.setStatus(request.getStatus() != null ? request.getStatus() : "pending");
        item.setOccurredAt(request.getOccurredAt() != null ? request.getOccurredAt() : LocalDateTime.now());
        item.setStartTime(request.getStartTime());
        item.setEndTime(request.getEndTime());

        item = flowItemRepository.save(item);
        return ApiResponse.success(FlowItemResponse.fromEntity(item));
    }

    @Operation(summary = "更新 FlowItem")
    @PutMapping("/{id}")
    public ApiResponse<FlowItemResponse> updateFlowItem(
            @PathVariable Long id,
            @RequestBody FlowItemRequest request,
            Authentication authentication) {
        Long userId = getUserId(authentication);

        FlowItem item = flowItemRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (item == null) {
            return ApiResponse.error(404, "FlowItem 不存在");
        }

        if (request.getFlowId() != null) item.setFlowId(request.getFlowId());
        if (request.getFlowType() != null) item.setFlowType(request.getFlowType());
        if (request.getDomainId() != null) item.setDomainId(request.getDomainId());
        if (request.getTitle() != null) item.setTitle(request.getTitle());
        if (request.getContent() != null) item.setContent(request.getContent());
        if (request.getStatus() != null) item.setStatus(request.getStatus());
        if (request.getOccurredAt() != null) item.setOccurredAt(request.getOccurredAt());
        if (request.getStartTime() != null) item.setStartTime(request.getStartTime());
        if (request.getEndTime() != null) item.setEndTime(request.getEndTime());

        item = flowItemRepository.save(item);
        return ApiResponse.success(FlowItemResponse.fromEntity(item));
    }

    @Operation(summary = "删除 FlowItem")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteFlowItem(@PathVariable Long id, Authentication authentication) {
        Long userId = getUserId(authentication);

        FlowItem item = flowItemRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (item == null) {
            return ApiResponse.error(404, "FlowItem 不存在");
        }

        flowItemRepository.delete(item);
        return ApiResponse.success(null);
    }

    private Long getUserId(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return user.getId();
    }
}
