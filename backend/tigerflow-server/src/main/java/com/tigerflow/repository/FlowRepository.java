package com.tigerflow.repository;

import com.tigerflow.entity.Flow;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FlowRepository extends JpaRepository<Flow, Long> {

    List<Flow> findByUserIdAndDeletedAtIsNull(Long userId);

    List<Flow> findByUserIdAndTypeAndDeletedAtIsNull(Long userId, String type);

    @Query("SELECT MAX(f.sortOrder) FROM Flow f WHERE f.userId = :userId")
    Integer findMaxSortOrderByUserId(Long userId);
}
