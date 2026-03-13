package com.tigerflow.controller;

import com.tigerflow.dto.request.FlowRequest;
import com.tigerflow.dto.response.ApiResponse;
import com.tigerflow.dto.response.FlowResponse;
import com.tigerflow.entity.Flow;
import com.tigerflow.entity.User;
import com.tigerflow.repository.FlowRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Flow 流程控制器
 */
@RestController
@RequestMapping("/api/v1/flows")
@RequiredArgsConstructor
@Tag(name = "流程管理", description = "Flow 流程的 CRUD 接口")
public class FlowController {

    private final FlowRepository flowRepository;

    @Operation(summary = "获取用户的所有 Flow")
    @GetMapping
    public ApiResponse<List<FlowResponse>> getFlows(Authentication authentication) {
        Long userId = getUserId(authentication);
        List<Flow> flows = flowRepository.findByUserIdOrderBySortOrderAsc(userId);
        List<FlowResponse> responses = flows.stream()
                .map(FlowResponse::fromEntity)
                .collect(Collectors.toList());
        return ApiResponse.success(responses);
    }

    @Operation(summary = "获取单个 Flow")
    @GetMapping("/{id}")
    public ApiResponse<FlowResponse> getFlow(@PathVariable Long id, Authentication authentication) {
        Long userId = getUserId(authentication);
        Flow flow = flowRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (flow == null) {
            return ApiResponse.error(404, "Flow 不存在");
        }
        return ApiResponse.success(FlowResponse.fromEntity(flow));
    }

    @Operation(summary = "创建 Flow")
    @PostMapping
    public ApiResponse<FlowResponse> createFlow(
            @Valid @RequestBody FlowRequest request,
            Authentication authentication) {
        Long userId = getUserId(authentication);

        Flow flow = new Flow();
        flow.setUserId(userId);
        flow.setName(request.getName());
        flow.setType(request.getType());
        flow.setIcon(request.getIcon());
        flow.setColor(request.getColor());
        flow.setIsPinned(request.getIsPinned() != null ? request.getIsPinned() : false);
        flow.setSortOrder(request.getSortOrder() != null ? request.getSortOrder() : 0);

        flow = flowRepository.save(flow);
        return ApiResponse.success(FlowResponse.fromEntity(flow));
    }

    @Operation(summary = "更新 Flow")
    @PutMapping("/{id}")
    public ApiResponse<FlowResponse> updateFlow(
            @PathVariable Long id,
            @Valid @RequestBody FlowRequest request,
            Authentication authentication) {
        Long userId = getUserId(authentication);

        Flow flow = flowRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (flow == null) {
            return ApiResponse.error(404, "Flow 不存在");
        }

        flow.setName(request.getName());
        flow.setType(request.getType());
        if (request.getIcon() != null) flow.setIcon(request.getIcon());
        if (request.getColor() != null) flow.setColor(request.getColor());
        if (request.getIsPinned() != null) flow.setIsPinned(request.getIsPinned());
        if (request.getSortOrder() != null) flow.setSortOrder(request.getSortOrder());

        flow = flowRepository.save(flow);
        return ApiResponse.success(FlowResponse.fromEntity(flow));
    }

    @Operation(summary = "删除 Flow")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteFlow(@PathVariable Long id, Authentication authentication) {
        Long userId = getUserId(authentication);

        Flow flow = flowRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (flow == null) {
            return ApiResponse.error(404, "Flow 不存在");
        }

        flowRepository.delete(flow);
        return ApiResponse.success(null);
    }

    private Long getUserId(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return user.getId();
    }
}
