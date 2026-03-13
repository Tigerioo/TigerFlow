package com.tigerflow.entity;

import javax.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Flow 流程类型实体
 */
@Entity
@Table(name = "tf_flow")
@Getter
@Setter
@NoArgsConstructor
public class Flow extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, length = 50)
    private String type;  // task, schedule, event, custom

    @Column(length = 50)
    private String icon;

    @Column(length = 20)
    private String color;

    @Column(name = "is_pinned")
    private Boolean isPinned = false;

    @Column(name = "sort_order")
    private Integer sortOrder = 0;
}
