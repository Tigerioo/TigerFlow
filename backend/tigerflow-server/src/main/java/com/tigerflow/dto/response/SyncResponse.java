package com.tigerflow.dto.response;

import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 同步响应
 */
@Data
public class SyncResponse {

    private LocalDateTime syncTime;

    private List<FlowResponse> flows;
    private List<FlowItemResponse> flowItems;
    private List<DomainResponse> domains;
    private List<TagResponse> tags;
    private List<EntityResponse> entities;

    // 删除的记录ID
    private List<Long> deletedFlows;
    private List<Long> deletedFlowItems;
    private List<Long> deletedDomains;
    private List<Long> deletedTags;
    private List<Long> deletedEntities;
}
