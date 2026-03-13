package com.tigerflow.entity;

import javax.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * FlowItem 流程项实体
 */
@Entity
@Table(name = "tf_flow_item")
@Getter
@Setter
@NoArgsConstructor
public class FlowItem extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "flow_id", length = 36)
    private String flowId;

    @Column(name = "flow_type", nullable = false, length = 50)
    private String flowType;  // task, schedule, event

    @Column(name = "domain_id", length = 36)
    private String domainId;

    @Column(nullable = false, length = 500)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String content;

    @Column(length = 20)
    private String status = "pending";  // pending, completed

    @Column(name = "occurred_at", nullable = false)
    private LocalDateTime occurredAt;

    @Column(name = "start_time")
    private LocalDateTime startTime;

    @Column(name = "end_time")
    private LocalDateTime endTime;
}
