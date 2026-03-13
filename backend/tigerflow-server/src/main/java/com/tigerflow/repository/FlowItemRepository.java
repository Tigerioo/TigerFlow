package com.tigerflow.repository;

import com.tigerflow.entity.FlowItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface FlowItemRepository extends JpaRepository<FlowItem, Long> {

    List<FlowItem> findByUserIdAndDeletedAtIsNull(Long userId);

    List<FlowItem> findByUserIdAndFlowTypeAndDeletedAtIsNull(Long userId, String flowType);

    List<FlowItem> findByUserIdAndFlowIdAndDeletedAtIsNull(Long userId, String flowId);

    @Query("SELECT f FROM FlowItem f WHERE f.userId = :userId AND f.updatedAt > :since AND f.deletedAt IS NULL")
    List<FlowItem> findByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);

    @Query("SELECT f FROM FlowItem f WHERE f.userId = :userId AND f.updatedAt > :since AND f.deletedAt IS NOT NULL")
    List<FlowItem> findDeletedByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);
}
