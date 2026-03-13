package com.tigerflow.dto.response;

import com.tigerflow.entity.FlowItem;
import java.time.LocalDateTime;
import lombok.Data;

/**
 * FlowItem 响应
 */
@Data
public class FlowItemResponse {

    private Long id;
    private Long userId;
    private String flowId;
    private String flowType;
    private String domainId;
    private String title;
    private String content;
    private String status;
    private LocalDateTime occurredAt;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static FlowItemResponse fromEntity(FlowItem item) {
        FlowItemResponse response = new FlowItemResponse();
        response.setId(item.getId());
        response.setUserId(item.getUserId());
        response.setFlowId(item.getFlowId());
        response.setFlowType(item.getFlowType());
        response.setDomainId(item.getDomainId());
        response.setTitle(item.getTitle());
        response.setContent(item.getContent());
        response.setStatus(item.getStatus());
        response.setOccurredAt(item.getOccurredAt());
        response.setStartTime(item.getStartTime());
        response.setEndTime(item.getEndTime());
        response.setCreatedAt(item.getCreatedAt());
        response.setUpdatedAt(item.getUpdatedAt());
        return response;
    }
}
