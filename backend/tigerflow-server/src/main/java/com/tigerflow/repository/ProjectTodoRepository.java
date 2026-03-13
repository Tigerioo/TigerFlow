package com.tigerflow.repository;

import com.tigerflow.entity.ProjectTodo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProjectTodoRepository extends JpaRepository<ProjectTodo, Long> {

    List<ProjectTodo> findByProjectIdAndDeletedAtIsNull(String projectId);

    List<ProjectTodo> findByStageIdAndDeletedAtIsNull(String stageId);
}
