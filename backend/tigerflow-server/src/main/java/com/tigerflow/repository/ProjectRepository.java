package com.tigerflow.repository;

import com.tigerflow.entity.Project;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProjectRepository extends JpaRepository<Project, Long> {

    List<Project> findByUserIdAndDeletedAtIsNull(Long userId);

    List<Project> findByUserIdAndStatusAndDeletedAtIsNull(Long userId, String status);

    List<Project> findByUserIdAndIsInQueueTrueAndStatusAndDeletedAtIsNullOrderByQueueOrderAsc(Long userId, String status);
}
