package com.tigerflow.repository;

import com.tigerflow.entity.ProjectStage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProjectStageRepository extends JpaRepository<ProjectStage, Long> {

    List<ProjectStage> findByProjectIdAndDeletedAtIsNullOrderBySortOrderAsc(String projectId);
}
