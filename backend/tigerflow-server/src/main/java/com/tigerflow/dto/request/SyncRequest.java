package com.tigerflow.dto.request;

import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 同步请求
 */
@Data
public class SyncRequest {

    private LocalDateTime lastSyncTime;

    private List<String> entityTypes;  // flow, flowItem, domain, tag, entity
}
