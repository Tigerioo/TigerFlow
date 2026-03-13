package com.tigerflow.entity;

import javax.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 标签实体
 */
@Entity
@Table(name = "tf_tag")
@Getter
@Setter
@NoArgsConstructor
public class Tag extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 20)
    private String color = "#007AFF";

    @Column(name = "usage_count")
    private Integer usageCount = 0;
}
