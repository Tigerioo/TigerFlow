package com.tigerflow.entity;

import javax.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 实体（人物等）实体
 */
@Entity
@Table(name = "tf_entity")
@Getter
@Setter
@NoArgsConstructor
public class FlowEntity extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, length = 50)
    private String type;  // person, company, location

    @Column(length = 10)
    private String emoji;

    @Column(name = "usage_count")
    private Integer usageCount = 0;
}
