package com.tigerflow.controller;

import com.tigerflow.dto.request.SyncRequest;
import com.tigerflow.dto.response.*;
import com.tigerflow.entity.Flow;
import com.tigerflow.entity.FlowEntity;
import com.tigerflow.entity.FlowItem;
import com.tigerflow.entity.User;
import com.tigerflow.entity.Domain;
import com.tigerflow.repository.*;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 数据同步控制器
 */
@RestController
@RequestMapping("/api/v1/sync")
@RequiredArgsConstructor
@io.swagger.v3.oas.annotations.tags.Tag(name = "数据同步", description = "增量数据同步接口")
public class SyncController {

    private final FlowRepository flowRepository;
    private final FlowItemRepository flowItemRepository;
    private final DomainRepository domainRepository;
    private final TagRepository tagRepository;
    private final FlowEntityRepository entityRepository;

    @Operation(summary = "同步数据", description = "增量同步用户数据")
    @PostMapping
    public ApiResponse<SyncResponse> sync(
            @RequestBody(required = false) SyncRequest request,
            Authentication authentication) {
        Long userId = getUserId(authentication);

        LocalDateTime lastSyncTime = request != null && request.getLastSyncTime() != null
                ? request.getLastSyncTime()
                : LocalDateTime.of(1970, 1, 1, 0, 0);

        SyncResponse response = new SyncResponse();
        response.setSyncTime(LocalDateTime.now());

        // 同步 Flows
        List<Flow> flows = flowRepository.findByUserIdAndUpdatedAtAfter(userId, lastSyncTime);
        response.setFlows(flows.stream().map(FlowResponse::fromEntity).collect(Collectors.toList()));

        // 同步 FlowItems
        List<FlowItem> flowItems = flowItemRepository.findByUserIdAndUpdatedAtAfter(userId, lastSyncTime);
        response.setFlowItems(flowItems.stream().map(FlowItemResponse::fromEntity).collect(Collectors.toList()));

        // 同步 Domains
        List<Domain> domains = domainRepository.findByUserIdAndUpdatedAtAfter(userId, lastSyncTime);
        response.setDomains(domains.stream().map(DomainResponse::fromEntity).collect(Collectors.toList()));

        // 同步 Tags
        List<com.tigerflow.entity.Tag> tags = tagRepository.findByUserIdAndUpdatedAtAfter(userId, lastSyncTime);
        response.setTags(tags.stream().map(TagResponse::fromEntity).collect(Collectors.toList()));

        // 同步 Entities
        List<FlowEntity> entities = entityRepository.findByUserIdAndUpdatedAtAfter(userId, lastSyncTime);
        response.setEntities(entities.stream().map(EntityResponse::fromEntity).collect(Collectors.toList()));

        // 获取删除的记录
        response.setDeletedFlows(flowRepository.findDeletedByUserIdAndUpdatedAtAfter(userId, lastSyncTime)
                .stream().map(Flow::getId).collect(Collectors.toList()));
        response.setDeletedFlowItems(flowItemRepository.findDeletedByUserIdAndUpdatedAtAfter(userId, lastSyncTime)
                .stream().map(FlowItem::getId).collect(Collectors.toList()));
        response.setDeletedDomains(domainRepository.findDeletedByUserIdAndUpdatedAtAfter(userId, lastSyncTime)
                .stream().map(Domain::getId).collect(Collectors.toList()));
        response.setDeletedTags(tagRepository.findDeletedByUserIdAndUpdatedAtAfter(userId, lastSyncTime)
                .stream().map(com.tigerflow.entity.Tag::getId).collect(Collectors.toList()));
        response.setDeletedEntities(entityRepository.findDeletedByUserIdAndUpdatedAtAfter(userId, lastSyncTime)
                .stream().map(FlowEntity::getId).collect(Collectors.toList()));

        return ApiResponse.success(response);
    }

    @Operation(summary = "全量同步", description = "获取用户所有数据")
    @GetMapping("/full")
    public ApiResponse<SyncResponse> fullSync(Authentication authentication) {
        Long userId = getUserId(authentication);

        SyncResponse response = new SyncResponse();
        response.setSyncTime(LocalDateTime.now());

        // 全量 Flows
        List<Flow> flows = flowRepository.findByUserIdAndDeletedAtIsNull(userId);
        response.setFlows(flows.stream().map(FlowResponse::fromEntity).collect(Collectors.toList()));

        // 全量 FlowItems
        List<FlowItem> flowItems = flowItemRepository.findByUserIdAndDeletedAtIsNull(userId);
        response.setFlowItems(flowItems.stream().map(FlowItemResponse::fromEntity).collect(Collectors.toList()));

        // 全量 Domains
        List<Domain> domains = domainRepository.findByUserIdAndDeletedAtIsNull(userId);
        response.setDomains(domains.stream().map(DomainResponse::fromEntity).collect(Collectors.toList()));

        // 全量 Tags
        List<com.tigerflow.entity.Tag> tags = tagRepository.findByUserIdAndDeletedAtIsNull(userId);
        response.setTags(tags.stream().map(TagResponse::fromEntity).collect(Collectors.toList()));

        // 全量 Entities
        List<FlowEntity> entities = entityRepository.findByUserIdAndDeletedAtIsNull(userId);
        response.setEntities(entities.stream().map(EntityResponse::fromEntity).collect(Collectors.toList()));

        return ApiResponse.success(response);
    }

    private Long getUserId(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return user.getId();
    }
}
