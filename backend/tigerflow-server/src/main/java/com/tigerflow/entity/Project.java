package com.tigerflow.entity;

import javax.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * OneThing 项目实体
 */
@Entity
@Table(name = "tf_project")
@Getter
@Setter
@NoArgsConstructor
public class Project extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String name;

    @Column(length = 10)
    private String icon = "🎯";

    @Column(length = 20)
    private String color = "#007AFF";

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(length = 20)
    private String status = "active";  // active, completed, archived

    @Column(name = "is_in_queue")
    private Boolean isInQueue = false;

    @Column(name = "queue_order")
    private Integer queueOrder = 0;
}
