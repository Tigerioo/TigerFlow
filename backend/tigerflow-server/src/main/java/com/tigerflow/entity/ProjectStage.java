package com.tigerflow.entity;

import javax.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 项目阶段实体
 */
@Entity
@Table(name = "tf_project_stage")
@Getter
@Setter
@NoArgsConstructor
public class ProjectStage extends BaseEntity {

    @Column(name = "project_id", nullable = false, length = 36)
    private String projectId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, length = 50)
    private String type;  // general, daily, weekly, milestone

    @Column(name = "sort_order")
    private Integer sortOrder = 0;

    @Column(name = "is_collapsed")
    private Boolean isCollapsed = false;
}
