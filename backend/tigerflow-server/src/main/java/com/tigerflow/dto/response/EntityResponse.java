package com.tigerflow.dto.response;

import com.tigerflow.entity.FlowEntity;
import lombok.Data;

/**
 * Entity 响应
 */
@Data
public class EntityResponse {

    private Long id;
    private Long userId;
    private String name;
    private String type;
    private String emoji;
    private Integer usageCount;

    public static EntityResponse fromEntity(FlowEntity entity) {
        EntityResponse response = new EntityResponse();
        response.setId(entity.getId());
        response.setUserId(entity.getUserId());
        response.setName(entity.getName());
        response.setType(entity.getType());
        response.setEmoji(entity.getEmoji());
        response.setUsageCount(entity.getUsageCount());
        return response;
    }
}
