package com.tigerflow.dto.request;

import lombok.Data;

/**
 * Domain 创建/更新请求
 */
@Data
public class DomainRequest {

    private String name;

    private String icon;

    private String color;

    private Integer sortOrder;
}
