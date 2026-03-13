package com.tigerflow.dto.request;

import lombok.Data;
import java.time.LocalDateTime;

/**
 * FlowItem 创建/更新请求
 */
@Data
public class FlowItemRequest {

    private String flowId;

    private String flowType;  // task, schedule, event

    private String domainId;

    private String title;

    private String content;

    private String status;  // pending, completed

    private LocalDateTime occurredAt;

    private LocalDateTime startTime;

    private LocalDateTime endTime;
}
