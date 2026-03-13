package com.tigerflow.dto.request;

import javax.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Flow 创建/更新请求
 */
@Data
public class FlowRequest {

    @NotBlank(message = "名称不能为空")
    private String name;

    @NotBlank(message = "类型不能为空")
    private String type;  // task, schedule, event, custom

    private String icon;

    private String color;

    private Boolean isPinned;

    private Integer sortOrder;
}
