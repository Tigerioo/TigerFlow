package com.tigerflow.dto.response;

import com.tigerflow.entity.Tag;
import lombok.Data;

/**
 * Tag 响应
 */
@Data
public class TagResponse {

    private Long id;
    private Long userId;
    private String name;
    private String color;
    private Integer usageCount;

    public static TagResponse fromEntity(Tag tag) {
        TagResponse response = new TagResponse();
        response.setId(tag.getId());
        response.setUserId(tag.getUserId());
        response.setName(tag.getName());
        response.setColor(tag.getColor());
        response.setUsageCount(tag.getUsageCount());
        return response;
    }
}
