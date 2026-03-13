package com.tigerflow.dto.request;

import lombok.Data;

/**
 * Tag 创建/更新请求
 */
@Data
public class TagRequest {

    private String name;

    private String color;
}
