package com.tigerflow.dto.response;

import com.tigerflow.entity.Domain;
import lombok.Data;

/**
 * Domain 响应
 */
@Data
public class DomainResponse {

    private Long id;
    private Long userId;
    private String name;
    private String icon;
    private String color;
    private Integer sortOrder;

    public static DomainResponse fromEntity(Domain domain) {
        DomainResponse response = new DomainResponse();
        response.setId(domain.getId());
        response.setUserId(domain.getUserId());
        response.setName(domain.getName());
        response.setIcon(domain.getIcon());
        response.setColor(domain.getColor());
        response.setSortOrder(domain.getSortOrder());
        return response;
    }
}
