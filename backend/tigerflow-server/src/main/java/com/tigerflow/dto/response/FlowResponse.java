package com.tigerflow.dto.response;

import com.tigerflow.entity.Flow;
import java.time.LocalDateTime;
import lombok.Data;

/**
 * Flow 响应
 */
@Data
public class FlowResponse {

    private Long id;
    private Long userId;
    private String name;
    private String type;
    private String icon;
    private String color;
    private Boolean isPinned;
    private Integer sortOrder;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static FlowResponse fromEntity(Flow flow) {
        FlowResponse response = new FlowResponse();
        response.setId(flow.getId());
        response.setUserId(flow.getUserId());
        response.setName(flow.getName());
        response.setType(flow.getType());
        response.setIcon(flow.getIcon());
        response.setColor(flow.getColor());
        response.setIsPinned(flow.getIsPinned());
        response.setSortOrder(flow.getSortOrder());
        response.setCreatedAt(flow.getCreatedAt());
        response.setUpdatedAt(flow.getUpdatedAt());
        return response;
    }
}
