package com.tigerflow.entity;

import javax.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

/**
 * 项目待办实体
 */
@Entity
@Table(name = "tf_project_todo")
@Getter
@Setter
@NoArgsConstructor
public class ProjectTodo extends BaseEntity {

    @Column(name = "project_id", length = 36)
    private String projectId;

    @Column(name = "stage_id", length = 36)
    private String stageId;

    @Column(nullable = false, length = 500)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String content;

    @Column(length = 20)
    private String status = "pending";  // pending, completed

    @Column(length = 20)
    private String priority = "medium";  // high, medium, low

    @Column(length = 20)
    private String recurrence;  // daily, weekly

    @Column(name = "due_date")
    private LocalDate dueDate;

    @Column(name = "sort_order")
    private Integer sortOrder = 0;
}
